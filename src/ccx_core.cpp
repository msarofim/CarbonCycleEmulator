// =====================================================================
// ccx_core.cpp — production core. Mirrors R/model.R operation for operation.
//
// R/model.R is the REFERENCE IMPLEMENTATION and stays authoritative for
// readability and for what the model means. This file exists only because the
// pure-R version runs a 1750-2024 monthly integration in ~500 s at the
// 2026-09 canonical (review B3, 2026-09-12; the "26 s" this line once quoted
// dated from the 2026-08 aseasonal model) against a 50 ms budget for MCMC. Any change to the physics must be made in BOTH, and
// test-parity.R gates them against each other.
//
// PARITY DISCIPLINE. Expressions here are written in the same order and the
// same associativity as the R, and use the same libm calls (exp, log, pow,
// sin, sqrt), because floating-point addition is not associative and reordering
// silently breaks agreement. Where R writes `a * b * c`, so does this. Resist
// "tidying" the arithmetic.
//
// The two are NOT bit-identical, and the design's "bit-parity" wording was
// optimistic. Measured agreement over an 81-year integration (15,552 derivative
// evaluations) is ~1e-13 absolute, ~1e-15 relative on CO2 -- pure roundoff
// accumulation. The irreducible source is catastrophic cancellation in deep-ocean
// 14C tendencies, where diffusion and decay nearly cancel; an ulp there is
// amplified without bound in RELATIVE terms while remaining ~1e-16 in absolute.
// test-parity.R therefore gates on a scale-relative tolerance, and is itself
// mutation-tested so that a real porting error (which shows at 1e-2 or worse)
// cannot slip through a tolerance chosen for roundoff.
//
// The two structural invariants carried over from R/model.R:
//   * every internal transfer is emitted once and applied with opposite sign
//     to two boxes, so conservation is exact at any step size;
//   * bidirectional interfaces (air-sea, interhemispheric) are emitted as two
//     one-way GROSS fluxes, because isotopes ride gross exchange and the net
//     vanishes at equilibrium.
// =====================================================================

#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

// Box layout, per hemisphere, in state order -- MUST match ccx_box_names():
//   0 atm | 1 leaf | 2 wood | 3 soil_fast | 4 soil_slow | 5 ml | 6..15 interior
//   16 hs | 17 hd                      <- ONLY when the HILDA structure is on
//   18 eq  (or 16 with HILDA off)      <- ONLY when the equatorial cell is on
//                                         (2026-09-13g); IEQ is set at runtime
//   19 tr  (after eq, or in its slot)   <- ONLY when the tropical surface box is
//                                         on (2026-09-14f); ITR is set at runtime
//
// ⚠ THE STRIDE IS RUNTIME, NOT COMPILE-TIME, SINCE 2026-09-05. The
// high-latitude boxes are ABSENT rather than empty when hs_frac = 0: carrying
// two zero-mass boxes would make ccx_spinup()'s Newton Jacobian and both
// isotope operators singular (all-zero rows and columns), and it would change
// the incumbent's state vector, which is what has to stay identical for
// hs_frac = 0 to be bit-exact. So NPH/NB are set by unpack_aux() from
// aux$hs_on, and EVERY entry point calls unpack_aux() before touching y.
// They are file statics, so this core is not re-entrant across threads with
// two different structures; it never was thread-safe and the calibration
// parallelises by FORKING, which gives each worker its own copy.
static int NPH = 16;               // boxes per hemisphere (the stride)
static int NB  = 32;               // boxes
static const int NL = 10;          // ocean interior layers
static const int IML = 5;          // mixed layer, relative to the hemisphere base
static const int IHS = IML + NL + 1;   // high-latitude surface (= 16), if present
static const int IHD = IHS + 1;        // high-latitude deep     (= 17), if present
static int IEQ = -1;                   // the equatorial cell, RUNTIME (2026-09-13g):
                                       // IHD + 1 with HILDA on, IHS's slot with it
                                       // off; -1 = absent. Set by unpack_aux().
static int ITR = -1;                   // the tropical surface box, RUNTIME
                                       // (2026-09-14f): the slot after eq (or eq's
                                       // slot with the cell off); -1 = absent.
static const int C = 0, C13 = 1, C14 = 2;

// Forcing columns, and the ceiling on the cleared fraction. BOTH are duplicated
// on the R side -- CCX_FORCING_COLS in R/cpp.R and CCX_LUC_CLEARED_MAX in
// R/model.R -- because the two implementations are independent by design. A
// disagreement in the column count is caught by ccx_cpp_forcing()'s name check;
// a disagreement in the ceiling is NOT caught by anything, so if one moves the
// other must move in the same commit.
static const int N_FORCING = 17;   // +sst_anom_NH, +sst_anom_SH (2026-08-18),
                                   // appended LAST; NaN = column absent, and
                                   // the deriv falls back to sst_scale * gmst
                                   // +sink_ocean (2026-08-23c), also LAST; its
                                   // "off" value is 0, not NaN
                                   // +aod_NH, +aod_SH (2026-08-29), also LAST;
                                   // "off" value 0 = a quiet stratosphere.
                                   // ⚠ FORGETTING THIS LINE IS EXACTLY THE
                                   // "silent garbage, not an error" the column
                                   // contract above warns about: f[15]/f[16]
                                   // read PAST the row buffer and returned
                                   // adjacent memory (~1e-4 ppm of effect
                                   // instead of ~4). R<->C++ parity caught it;
                                   // nothing else would have.
static const double LUC_CLEARED_MAX = 0.9;

// state is column-major [box + NB*tracer], matching R's matrix layout
inline int IX(int box, int tr) { return box + NB * tr; }

// Air-sea 13C fractionation at a given SST. Twin of R's ccx_alpha_as();
// `tdep == 0` returns the retired scalars so the pre-2026-09-02 model is
// reproduced bit for bit. Defined on the struct below, so declared after it.
struct Aux {
  double gtc_per_ppm_hemi, chi0, mol_per_GtC;
  double npp0[2], veg0[2], land0[2], ml_mass_kg[2], asx[2], sst[2];
  double dz[NL + 1], dz_mid[NL];
  // SEASONAL MIXED LAYER (round 6, 2026-09-09). Twin of R's aux$mld_coef.
  // `seas_ml` is the switch; mld_a/mld_b are the 6 Fourier harmonics of the
  // MEAN-PRESERVING depth shape, per hemisphere. Sent zero-filled when off, so
  // a stale draw cannot leave a live field behind (the pump_org precedent).
  // ⚠ THE INTERIOR GRID DOES NOT MOVE: only the ML/layer-1 boundary does, and
  // layer 1 absorbs the whole excursion, so dz[0] + dz[1] is conserved and
  // dz_mid[0] is invariant. kz_int stays at its annual-mean values.
  int seas_ml;
  double mld_a[2][6], mld_b[2][6];
  // Per-interface diffusivity (2026-09-06b): K at the base of layer k. Twin of
  // R's aux$kz_int; rep(kz, NL) at the default kz_deep_frac = 1, so P.kz below
  // is read but the operator uses THIS.
  double kz_int[NL];
  double alpha_photo, alpha_as_down, alpha_as_up;
  // AIR-SEA 13C, TEMPERATURE-DEPENDENT SINCE 2026-09-02 (Zhang et al. 1995).
  // alpha_as_down/up above are now the RETIRED SCALARS, used only when
  // alpha_as_tdep == 0, which reproduces the pre-09-02 model bit for bit.
  // Twin of the block in R/model.R's ccx_prepare(); ccx_alpha_as() below
  // mirrors R's ccx_alpha_as() and test-parity.R holds the two together.
  int    alpha_as_tdep;
  double alpha_as_zA, alpha_as_zB, alpha_as_zC, alpha_as_fco3;
  double alpha_as_kin_a, alpha_as_kin_b;
  // d13c_foss MOVED to the forcing (2026-08-12): the fossil source d13C is
  // time-varying, so it is no longer an invariant.
  // enso_share RETIRED 2026-09-01 -- the hemispheric split of the ENSO
  // anomaly is carried by the four fitted coefficients themselves. Removed
  // from BOTH sides in the same commit: a field the R side stops sending and
  // this one still reads unpacks as garbage, not as an error.
  double dic0[2], revelle0[2], pco2_0[2];   // preindustrial mixed-layer reference
  double bomb_share_NH, nuc_share_NH;
  double R13, R14STD, lambda, alk;
  // carbonate polynomial coefficients (degree 6 -> 7 coefficients each)
  double cK0[7], cK1[7], cK2[7], cKb[7], cKw[7];
  double t_centre, t_scale, boron;
  double a_oc[2];          // ocean area per hemisphere; the conveyor's
                           // interhemispheric limbs are the only fluxes where
                           // it does not cancel between source and sink
  int carb_iter;
  // THE BIOLOGICAL PUMP (task 9, 2026-08-16). Export field per hemisphere per
  // interior box, GtC/yr, SOLVED in R (ccx_pump_export) rather than here: it is
  // a property of the parameter draw, not of the timestep, so re-deriving it in
  // the inner loop would be pure waste. `pump_on` 0 emits nothing at all, so the
  // no-pump model is bit-reproduced -- the same contract w_up = 0 carries.
  // THE HIGH-LATITUDE BOXES (HILDA HS/HD, 2026-09-05). Sent UNCONDITIONALLY,
  // like the pump arrays and the T-dependent alphas: this struct is read into a
  // fixed layout, so a field the R side sometimes omits is whatever was in that
  // memory before. `hs_on` is what gates every flux, on both cores -- and it is
  // also what sets NPH/NB above.
  int    hs_on;
  double hs_frac, h_hs, dz_hd, sst_hs, dic0_hs, revelle0_hs;
  double alk_hs;   // the cold box's own alkalinity, mol/kg (2026-09-08g; = alk unless set)
  double a_ls[2], a_hs[2], hs_mass_kg[2], asx_hs[2];
  int pump_on;
  double pump_org[2][NL], pump_carb[2][NL];
  double ml_C0[2];                  // preindustrial ML carbon, DIC-limited mode
  double alpha_pump_org, alpha_pump_carb;   // 13C fractionation, per limb
  // THE HS PUMP (2026-09-07d): HS -> HD export per hemisphere, GtC/yr, SOLVED in
  // R (ccx_pump_export_hs) off the LS field; pump_hs_on = 0 emits nothing.
  int    pump_hs_on;
  double pump_hs_org[2], pump_hs_carb[2];
  double hs_C0[2];                  // preindustrial HS carbon, DIC-limited mode
  // O5b (2026-09-16 b): the HS pump's seasonal SHAPE, 6 Fourier harmonics per
  // hemisphere -- twin of R's aux$pump_hs_seas_coef (the mld_a/mld_b idiom),
  // zero-filled when the HS pump is off. pump_hs_seas_on is DATA PRESENCE
  // only; the switch that emits anything is P.pump_hs_seas_amp > 0.
  int    pump_hs_seas_on;
  double phs_a[2][6], phs_b[2][6];
  // THE EQUATORIAL UPWELLING CELL (2026-09-13g). Twin of the block in R's
  // ccx_prepare(); sent unconditionally, zero-filled when off. `eq_on` gates
  // every flux on both cores and, with hs_on, sets the stride. `a_ml` is the
  // mixed layer's OWN area (choice D1: a_ls - a_eq; == a_ls with the cell off).
  int    eq_on;
  double a_ml[2], a_eq[2], eq_mass_kg[2], asx_eq[2], eq_w_share[2];
  double h_eq, sst_eq, sst_eq_enso, alk_eq, dic0_eq, revelle0_eq;
  int    k_eq;                      // 1-BASED as in R
  // THE TROPICAL SURFACE BOX (2026-09-14f). Same contract: unconditional,
  // zero-filled when off; `tr_on` gates every flux and, with the other two
  // switches, sets the stride. `a_ml` above is now a_ls - a_eq - a_tr.
  int    tr_on;
  double a_tr[2], tr_mass_kg[2], asx_tr[2], tr_q_share[2];
  // D1 IS LIVE (audit 2026-09-15 d): eq_on || tr_on -- the one flag every
  // a_ls/a_ml correction reads (twin of R's aux$d1_on, derived here from the
  // two marshalled switches rather than sent, so the two cannot disagree).
  int    d1_on;
  // THE VENTILATION LOOP (option E, 2026-09-14 h): e_on gates it; k_e1..k_e2
  // 1-BASED as in R; e_w the thickness weights (annual-mean grid, 0 outside
  // the band); e_share the a_ls split of w_vent. Zero-filled when off.
  int    e_on, k_e1, k_e2;
  double e_w[NL], e_share[2];
  // THE LAYER-2 NINO3.4 LIMB (2026-09-17 k): l2_on gates it; k_l2 1-BASED as in
  // R; w0_l2 the floor's mean (Sv); l2_share the equal split. Zero-filled when off.
  int    l2_on, k_l2;
  double w0_l2, l2_share[2];
  // THE HS-ROUTE DEEP RETURN (option O1 arm THC, 2026-09-15 d): thc_on gates
  // it; k_thc the return layer, 1-BASED as in R; thc_share the a_hs split.
  int    thc_on, k_thc;
  double thc_share[2];
  // THE GLOBAL THERMOHALINE LOOP (2026-09-20 v): gthc_on gates it; k_gthc the
  // SH return layer, 1-BASED as in R (NL = the bottom).
  int    gthc_on, k_gthc;
  int    kn_gthc;          // T2 (2026-09-21 b): the NH subduction layer; 0 = the ML feeds HS_NH
  double u_hs_fac_SH;        // the SH cold box's own ventilation factor (2026-09-21 c); 1 = symmetric
  double tau_q_fac_SH;       // likewise on the SH HD <-> interior exchange (tau_q / fac)
  double k_w_fac[2], k_w_fac_hs;   // the hemispheres' and the cold boxes' gas-exchange factors (2026-09-21 c)
  double h_ml_fac[2];              // the hemispheres' mean-ML-thickness factors (2026-09-21 d); folded into mld_eval
  double h_tr, sst_tr, sst_tr_enso, alk_tr, dic0_tr, revelle0_tr;
  double ml_pump_share[2], tr_C0[2];   // choice D2: the ML's share of the LS export; tr's PI carbon
  double kz_tr;                        // the tr / layer-1 interface's K (R6); 0 = none
};

static inline void ccx_alpha_as(double sst, const Aux &A,
                                double *a_down, double *a_up) {
  if (A.alpha_as_tdep == 0) { *a_down = A.alpha_as_down; *a_up = A.alpha_as_up; return; }
  const double eps_k    = A.alpha_as_kin_a + A.alpha_as_kin_b * (sst - 5.0);
  const double eps_dicg = A.alpha_as_zA * sst * A.alpha_as_fco3
                        + A.alpha_as_zB * sst + A.alpha_as_zC;
  *a_down = 1.0 + eps_k / 1000.0;
  *a_up   = 1.0 + (eps_k - eps_dicg) / 1000.0;
}

// FERTILISATION FORM. Mirrors CCX_FERT_LOG / CCX_FERT_MM in R/model.R; the two
// must agree exactly or test-parity.R fails, which is the point.
#define FERT_LOG 0
#define FERT_MM  1

struct Par {
  double beta, q10, k_w, kz, w_up, w_out[2], tau_ex;
  double u_hs, tau_q;        // HILDA HS<->HD and HD<->interior (2026-09-05)
  double w_eq, gamma_eq;     // the equatorial cell's whole-band Sv and its
                             // Nino3.4 modulation (2026-09-13g)
  double w_vent, gamma_vent;       // the ventilation loop's whole-LS Sv and its
                             // Nino3.4 modulation (option E, 2026-09-14 h)
  double w_thc;              // the HS-route deep return, Sv both hemispheres
                             // (option O1 arm THC, 2026-09-15 d)
  double w_gthc;             // the global thermohaline loop, ONE Sv volume
                             // (NH sinks, SH upwells; 2026-09-20 v)
  double w_enso_l2;          // the layer-2 Nino3.4 limb, Sv per index unit
                             // (review avenue 1, 2026-09-17 k)
  double pump_seas_amp, pump_seas_lag;   // the seasonal export factor (option O5,
                             // 2026-09-15 f): amp in [0, 1], lag in months
  double pump_hs_seas_amp, pump_hs_seas_lag;   // O5b (2026-09-16 b): the HS pump on
                             // the data's rectified shape; amp in [0, 1], lag in
                             // months. > 0 REPLACES the O5 sine on the HS pump.
  double q_tr;               // the tropical box's lateral exchange, Sv
                             // (2026-09-14f; structural 0 under ruling R4)
  double q_attach_from;      // shallowest interior layer HD attaches to,
                             // 1-BASED as in R. 1 = every layer = HILDA's
                             // depth-independent q (2026-09-05f)
  double tau_ex_seas_amp, tau_ex_seas_phase;   // diagnostic, 2026-08-31; 0 = OFF
  // CO2 fertilisation form and the saturating pair. `fert_form` selects which
  // of beta / (beta_max, fert_k) is live; the other is inert. See the long note
  // above CCX_FERT_FORM_DEFAULT in R/model.R for why a second form exists.
  int fert_form;
  double beta_max, fert_k;
  // THE CONVEYOR (2026-08-13). q_conv in Sv; 0 emits nothing, so the
  // pure-diffusion column is bit-reproduced. conv_sink is the interior layer
  // the sinking limb feeds (1..NL), conv_descent 0 = non-local plume / 1 =
  // distributed, conv_reverse 1 = run the cell backwards (wiring gate only).
  // Mirrors R/model.R's ccx_conveyor_geom(); the two must agree exactly.
  double q_conv;
  int conv_sink, conv_descent, conv_reverse;
  // Pump export law: 0 = nutrient-limited (mass fixed), 1 = DIC-limited (export
  // scales with the mixed layer's carbon). Mirrors R/model.R's `pump_mode`.
  int pump_mode;
  double npp_leaf_frac, tau_leaf, tau_wood;
  double litter_slow_frac, tau_soil_fast, tau_soil_slow;
  double npp_veg_frac, ra_ratio;
  // Land-use permanence (2026-08-13). Scales the cleared fraction; see the
  // "converted land" block in ccx_deriv() (R/model.R) for the mechanism and
  // CCX_F_LUC_PERM_DEFAULT for why 1 rather than 0 is the default.
  double f_luc_perm;
  // WHERE the land-use debit comes from (2026-08-13). 1 = wood alone, the
  // shipped behaviour; below 1 the remainder is split pro rata across the four
  // land pools by their preindustrial equilibrium shares. Must reproduce
  // ccx_luc_pool_shares() in R/model.R exactly -- the weights are derived from
  // the same six land parameters in both, deliberately, so neither side can
  // carry a stale vector.
  double f_luc_wood;
  double sst_scale, gamma_diff;
  // ENSO, FOUR COEFFICIENTS SINCE 2026-09-01 (Marcus's design). GtC/yr per unit
  // Nino3.4 index; [0] = NH, [1] = SH. The land pair drives soil_fast -> atm,
  // the ocean pair an air-sea anomaly carrying the air-sea fractionation of its
  // own direction. ccx_cpp_par() guarantees all four are present, resolving
  // absence through ccx_gamma_enso() -- the SAME function the R core uses. Do
  // not add a fallback here: a second opinion about absence is the defect that
  // cost 0.647 GtC/yr on 2026-08-30. See R/model.R for the measurement.
  double gamma_enso_land[2], gamma_enso_ocn[2];
  double seas_amp[2], seas_phase[2];
  // Seasonal-cycle DRIVERS (2026-08-18): insolation-driven NPP + Q10 on a
  // climatological seasonal land temperature. seas_drivers = 0 is the escape
  // hatch reproducing the sine above bit-for-bit; see the CCX_SEAS_PHI_EFF
  // block in R/model.R for the physics and the offline provenance. The norms
  // are PRECOMPUTED here on the 12 month midpoints -- exactly the definition
  // ccx_seas_norms() uses in R; a continuous-integral norm would break parity.
  int    seas_drivers;
  // ⛔ THE SEASONAL MIXED LAYER'S GATE, RESOLVED IN R (2026-09-09t). Until
  // today this core gated it on A.seas_ml -- i.e. on whether `aux` carried
  // harmonics -- while R gated on ccx_seas_ml_on(p). ccx_spinup() builds
  // `aux` from the un-zeroed `p` and only THEN sets seas_drivers = 0, so the
  // zeroing was honoured by R and IGNORED here, and the "aseasonal"
  // preindustrial equilibrium carried ~1940 GtC less ocean carbon. The gate
  // is now computed ONCE, by the same function the R core uses, and shipped.
  // A.seas_ml survives only as a DATA-PRESENCE conjunct.
  int    seas_ml_on;
  double seas_T_amp[2], seas_lag_p[2];   // lag per hemisphere since 2026-08-31
  double sst_seas_amp[2];
  // Southern-Ocean entrainment channel (2026-08-27g, version 4a). SH only --
  // a scalar, not a [2] array, because the NH control measures 0.30 months
  // between NH-mean pCO2 and NH-mean SST and so gets no such channel. See
  // CCX_ENT_SEAS_PEAK_MO in R/model.R for the measurement and the physics.
  double ent_seas_amp_SH;
  // DIAGNOSTIC CHANNEL SWITCH (2026-08-20f), not a fitted parameter and not in
  // CCX_PARAM_TABLE. Scales the seasonal NEP term only. 1 = the shipped model,
  // bit for bit; 0 = that channel off with the ANNUAL BUDGET UNTOUCHED, because
  // the term it multiplies is zero-annual-mean by construction. It exists
  // because the other two seasonal channels can already be switched exactly by
  // parameters (seas_T_amp = 0, sst_seas_amp = 0) and this one could not --
  // SEAS_PHI_EFF is a compile-time constant, so there was no way to isolate the
  // NEP channel in a single session. See calibration/diag_seas_channel_decomp.R.
  double seas_npp_amp[2];
  int    sst_obs;
  double seas_n_norm[2], seas_r_norm[2];
  double revelle_frozen;                    // mechanism switch, 0 or 1
};

// Effective latitudes and the seasonal-T lag: MUST equal R/model.R's
// CCX_SEAS_PHI_EFF and CCX_SEAS_T_LAG bit for bit (same discipline as
// SV_TO_M3YR below).
static const double SEAS_PHI_EFF[2] = { 75.0, -30.0 };
// Twins of CCX_SEAS_T_LAG / CCX_SST_SEAS_LAG -- see the long note at those
// constants in R/model.R before touching either. In short: the 3.5 in
// (3.5 + LAG)/12 already places the zero-lag NH peak at mid-July, SEAS_T_LAG
// scales SOIL respiration rather than air temperature so its mid-September peak
// is correct (measured: a clean interior optimum, 18,944 log-units above LAG = 0),
// SST_SEAS_LAG is no longer unidentified: it is measured from ERSSTv5's own
// NH seasonal peak month, because sst_seas_amp modulates SST itself.
static const double SEAS_T_LAG = 2.0;
static const double SST_SEAS_LAG = 1.32;   // MEASURED 2026-08-20g from ERSSTv5
                                           // (was 2.5, a stated prior belief). MUST
                                           // track CCX_SST_SEAS_LAG in R/model.R.
// Twin of CCX_ENT_SEAS_PEAK_MO in R/model.R -- MUST track it. The month at
// which the Southern-Ocean entrainment channel's surface-DIC anomaly peaks,
// MEASURED from the ocean-area-weighted 40-90 S pCO2 first harmonic. NOT a lag
// off a mid-July reference like the two above: it is an absolute peak month
// measured in the Southern Hemisphere, and it carries no hemispheric sign flip.
static const double ENT_SEAS_PEAK_MO = 7.50;

// Daily-mean TOA insolation, flat-sun formula, S0 omitted (all uses divide by
// an annual-mean norm, so it cancels). Twin of R's ccx_insol(); periodic in t
// with period exactly 1.
static double seas_insol(double phi_deg, double tt) {
  const double phi = phi_deg * M_PI / 180.0;
  const double dec = -23.44 * M_PI / 180.0
                     * std::cos(2.0 * M_PI * (tt * 365.25 + 10.0) / 365.25);
  double x = -std::tan(phi) * std::tan(dec);
  if (x > 1.0) x = 1.0; if (x < -1.0) x = -1.0;
  const double h0 = std::acos(x);
  return (h0 * std::sin(phi) * std::sin(dec)
          + std::cos(phi) * std::cos(dec) * std::sin(h0)) / M_PI;
}

// 1 Sv = 1e6 m3/s. Must equal R/model.R's CCX_SV_TO_M3YR bit for bit.
static const double SV_TO_M3YR = 1e6 * 365.25 * 86400.0;

// ---- carbonate: mirrors R/carbonate.R -------------------------------
inline double eval_lnK(const double* co, double x) {
  // Incremental xp *= x rather than std::pow(x, i). Both were tried: switching
  // to std::pow to match R's `x^i` did NOT change the R/C++ difference at all
  // (2.842e-13 either way), so the ulp-level disagreement is elsewhere -- it
  // originates in near-zero deep-ocean 14C tendencies, where the diffusive flux
  // and decay terms nearly cancel and any last-bit difference is amplified.
  // The incremental form is kept because it is ~15 % faster and buys nothing
  // to abandon. See test-parity.R for what agreement IS guaranteed.
  double out = co[0];
  double xp = 1.0;
  for (int i = 1; i <= 6; ++i) { xp *= x; out += co[i] * xp; }
  return std::exp(out);
}

// Solubility alone. The frozen-Revelle path still needs K0 for the gas-transfer
// prefactor -- the switch freezes the BUFFER chemistry, not the temperature
// dependence of solubility -- but must not run the Newton solve, whose whole
// point is the buffering it is meant to bypass.
inline double K0_only(double T, const Aux& A) {
  return eval_lnK(A.cK0, (T - A.t_centre) / A.t_scale);
}

// Returns pCO2 (uatm) and, via K0out, the effective K0 the caller needs.
inline double pco2_from_dic_cpp(double dic, double alk, double T,
                                const Aux& A, double* K0out) {
  const double x  = (T - A.t_centre) / A.t_scale;
  const double K0 = eval_lnK(A.cK0, x);
  const double K1 = eval_lnK(A.cK1, x);
  const double K2 = eval_lnK(A.cK2, x);
  const double Kb = eval_lnK(A.cKb, x);
  const double Kw = eval_lnK(A.cKw, x);
  *K0out = K0;

  // exact carbonate-only quadratic seed
  const double a  = alk;
  const double b  = K1 * (alk - dic);
  const double cc = K1 * K2 * (alk - 2.0 * dic);
  double disc = b * b - 4.0 * a * cc;
  if (disc < 0.0) disc = 0.0;
  double h = (-b + std::sqrt(disc)) / (2.0 * a);
  if (h < 1e-12) h = 1e-12;

  // Newton refinement including borate and water (both matter -- see
  // R/carbonate.R: dropping OH- costs 4.5 % in pCO2)
  for (int i = 0; i < A.carb_iter; ++i) {
    const double denom = h * h + K1 * h + K1 * K2;
    const double hco3  = dic * K1 * h / denom;
    const double co3   = dic * K1 * K2 / denom;
    const double boh4  = A.boron * Kb / (Kb + h);
    const double oh    = Kw / h;
    const double f     = hco3 + 2.0 * co3 + boh4 + oh - h - alk;

    const double dden  = 2.0 * h + K1;
    const double dhco3 = dic * K1 * (denom - h * dden) / (denom * denom);
    const double dco3  = -dic * K1 * K2 * dden / (denom * denom);
    const double dboh4 = -A.boron * Kb / ((Kb + h) * (Kb + h));
    const double doh   = -Kw / (h * h);
    const double fp    = dhco3 + 2.0 * dco3 + dboh4 + doh - 1.0;

    h = h - f / fp;
    if (h < 1e-12) h = 1e-12;
  }
  const double co2 = dic * h * h / (h * h + K1 * h + K1 * K2);
  return co2 / K0 * 1e6;
}

// ---- derivative -----------------------------------------------------
// `pco2_rec` (2026-09-13g): OPTIONAL, may be nullptr. When given, the surface
// pCO2 of each surface box at THIS evaluation is written to it in the order
// [ml_NH, hs_NH, eq_NH, tr_NH, ml_SH, hs_SH, eq_SH, tr_SH] (CCX_SURFACE_BOXES
// per hemisphere, 4 since 2026-09-14f), NA_REAL where the box does not exist. ccx_run_cpp() reads it
// off the FIRST RK4 stage of each month -- the same (y, t, f) the `out` row
// records -- so the exported columns are the derivative's own numbers, not a
// second estimator (twin of ccx_deriv(record = TRUE)'s pco2_* in R).
static void deriv(const double* y, double t, const Par& P, const double* f,
                  const Aux& A, double* dy, double* pco2_rec = nullptr) {
  for (int i = 0; i < NB * 3; ++i) dy[i] = 0.0;
  if (pco2_rec) for (int i = 0; i < 8; ++i) pco2_rec[i] = NA_REAL;

  // flux helper: source-ratio transport, applied antisymmetrically
  // SEASONAL MIXED-LAYER SHAPE -- twin of ccx_mld_eval() in R/model.R, written
  // in the same order and associativity so the two cores agree to roundoff.
  // Periodic with period 1, so `t` is used directly: no modulo, which would put
  // a kink at the new year.
  auto mld_eval = [&](int hi, double tt, double *f, double *dfdt) {
    double sf = 1.0, sd = 0.0;                       // a0 = 1 by construction; the mean factor A.h_ml_fac is applied at the USE sites, R's association
    for (int k = 1; k <= 6; ++k) {
      const double ang = 2.0 * M_PI * k * tt;
      const double ca = std::cos(ang), sa = std::sin(ang);
      sf += A.mld_a[hi][k - 1] * ca + A.mld_b[hi][k - 1] * sa;
      sd += 2.0 * M_PI * k * (-A.mld_a[hi][k - 1] * sa + A.mld_b[hi][k - 1] * ca);
    }
    *f = sf; *dfdt = sd;
  };
  // O5b (2026-09-16 b): the HS pump's seasonal shape at time tt -- twin of
  // ccx_mld_eval(aux$pump_hs_seas_coef[[h]], tt)$f, the SAME order and
  // associativity as mld_eval above so the cores agree to roundoff.
  auto phs_eval = [&](int hi, double tt) {
    double sf = 1.0;                                 // a0 = 1 by construction
    for (int k = 1; k <= 6; ++k) {
      const double ang = 2.0 * M_PI * k * tt;
      sf += A.phs_a[hi][k - 1] * std::cos(ang) + A.phs_b[hi][k - 1] * std::sin(ang);
    }
    return sf;
  };

  auto add_flux = [&](int from, int to, double F, double alpha13,
                      bool alpha13_signed = false) {
    if (F == 0.0) return;
    // A signed flux may not carry a fractionation -- the reverse limb is a
    // different process with a different alpha. Mirrors the R core's guard;
    // see R/model.R add_flux() for why no test could catch this class.
    // alpha13_signed is the one reviewed opt-out (the biological pump).
    if (F < 0.0 && alpha13 != 1.0 && !alpha13_signed)
      Rcpp::stop("add_flux: a negative flux may not carry alpha13 != 1 "
                 "(from %d to %d). Resolve alpha13 at the call site.", from, to);
    const int src = (F > 0.0) ? from : to;
    const double cs = y[IX(src, C)];
    const double r13 = (cs > 0.0) ? y[IX(src, C13)] / cs : 0.0;
    const double r14 = (cs > 0.0) ? y[IX(src, C14)] / cs : 0.0;
    const double f13 = F * r13 * alpha13;
    const double f14 = F * r14;             // no fractionation, by convention
    dy[IX(from, C)]   -= F;   dy[IX(to, C)]   += F;
    dy[IX(from, C13)] -= f13; dy[IX(to, C13)] += f13;
    dy[IX(from, C14)] -= f14; dy[IX(to, C14)] += f14;
  };

  auto add_source = [&](int box, double F, double d13c, double d14c) {
    dy[IX(box, C)]   += F;
    dy[IX(box, C13)] += F * A.R13 * (1.0 + d13c / 1000.0);
    dy[IX(box, C14)] += F * (1.0 + d14c / 1000.0);
  };

  // forcing layout: e_foss_NH, e_foss_SH, e_luc_NH, e_luc_SH, gmst, enso,
  //                 c14_bomb, c14_nuclear, c14_cosmo, d13c_foss,
  //                 cum_luc_NH, cum_luc_SH, sst_anom_NH, sst_anom_SH,
  //                 sink_ocean, aod_NH, aod_SH
  // Must stay in step with CCX_FORCING_COLS in R/cpp.R -- indexed by position,
  // so a mismatch is silent garbage. test-parity.R is the gate.
  const double gmst = f[4], enso = f[5], d13c_foss = f[9];

  // ARTIFICIAL MID-CENTURY OCEAN SINK (2026-08-23c). Mirrors the block of the
  // same name in R/model.R -- read the reasoning there; this is the port, and
  // test-parity.R is what holds the two together. GLOBAL GtC/yr, split below on
  // the ocean-area shares. Non-finite (an absent column) reads as OFF, and 0
  // emits nothing at all, so the no-sink model is bit-reproduced.
  const double sink_ocean = std::isfinite(f[14]) ? f[14] : 0.0;
  // VOLCANIC stratospheric AOD, hemispheric (2026-08-29). Absence = 0 = a quiet
  // stratosphere, the same contract the sst columns carry.
  const double aod_h_[2] = { std::isfinite(f[15]) ? f[15] : 0.0,
                             std::isfinite(f[16]) ? f[16] : 0.0 };
  const double sink_asx_tot = A.asx[0] + A.asx[1];

  for (int hi = 0; hi < 2; ++hi) {
    const int base = hi * NPH;
    const int iatm = base, ilef = base + 1, iwod = base + 2;
    const int isf = base + 3, iss = base + 4, iml = base + IML;

    // ---- SEASONAL MIXED LAYER: this hemisphere's geometry NOW -------
    // Twin of the block in R/model.R. `dzl`/`dzml` are rebuilt from A every
    // iteration, never assigned over A: the hemispheres are in ANTIPHASE (NH
    // deepest Feb, SH Aug), so state leaking across iterations would give the
    // SH the NH's winter. With the mechanism off these ARE A's own values and
    // every number below is bit-identical to the pre-round-6 core.
    double dzl[NL + 1], dzml[NL], ml_mass, h_ml_t, dh_ml_dt;
    for (int i = 0; i <= NL; ++i) dzl[i] = A.dz[i];
    for (int i = 0; i < NL; ++i)  dzml[i] = A.dz_mid[i];
    ml_mass = A.ml_mass_kg[hi]; h_ml_t = A.dz[0]; dh_ml_dt = 0.0;
    if (A.seas_ml != 0 && P.seas_ml_on != 0) {
      double f, dfdt;
      mld_eval(hi, t, &f, &dfdt);
      h_ml_t   = A.dz[0] * A.h_ml_fac[hi] * f;      // m, mean-preserving by construction (about h_ml x factor; 2026-09-21 d)
      dh_ml_dt = A.dz[0] * A.h_ml_fac[hi] * dfdt;   // m/yr, > 0 deepening
      // layer 1 absorbs the excursion -- as a VOLUME under the equatorial
      // cell (D1, 2026-09-13g): share = a_ml / a_ls; twin of R's
      // ccx_grid_at_h_ml(share), which carries why this is a correctness term
      if (A.d1_on) dzl[1] = dzl[1] + (dzl[0] - h_ml_t) * (A.a_ml[hi] / A.a_ls[hi]);
      else         dzl[1] = dzl[1] + (dzl[0] - h_ml_t);
      dzl[0]   = h_ml_t;
      // dz[0] + dz[1] is conserved, so dz_mid[0] is INVARIANT; only dz_mid[1]
      // moves. Recomputed in full rather than patched, so it cannot drift.
      for (int i = 0; i < NL; ++i) dzml[i] = (dzl[i] + dzl[i + 1]) / 2.0;
      ml_mass = A.ml_mass_kg[hi] * A.h_ml_fac[hi] * f;    // mass tracks thickness (x the mean factor, R's association)
    }

    const double chi = y[IX(iatm, C)] / A.gtc_per_ppm_hemi;

    // land, four pools -- see R/model.R for the structure and for what
    // npp_veg_frac and ra_ratio mean, including why the decoupled phi < 1/f
    // stability bound does NOT hold (the CO2 feedback stabilises it).
    // Association order mirrors the R exactly (parity).
    const double chi_safe = (chi > 1e-6) ? chi : 1e-6;

    // CONVERTED LAND (2026-08-13). Cumulative land-use carbon shrinks the
    // land's equilibrium, so the debit stops being regrown. Mirrors the
    // "converted land" block in R/model.R exactly -- including that the
    // denominator is land0 (all four pools) and not veg0, and that the
    // seasonal term below keeps the UNCLEARED npp0. CCX_LUC_CLEARED_MAX.
    const double cleared_raw = P.f_luc_perm * f[10 + hi] / A.land0[hi];
    const double cleared = (cleared_raw < LUC_CLEARED_MAX) ? cleared_raw
                                                          : LUC_CLEARED_MAX;
    const double npp0_h = A.npp0[hi] * (1.0 - cleared);
    const double veg0_h = A.veg0[hi] * (1.0 - cleared);

    const double veg_C = y[IX(ilef, C)] + y[IX(iwod, C)];
    const double capacity = (1.0 - P.npp_veg_frac)
                            + P.npp_veg_frac * veg_C / veg0_h;
    // The ONLY other copy of ccx_fert_factor(); test-parity.R gates them.
    double fert;
    if (P.fert_form == FERT_LOG) {
      fert = 1.0 + P.beta * std::log(chi_safe / A.chi0);
    } else {
      const double d = chi - A.chi0;
      const double kk = (P.fert_k > 1e-6) ? P.fert_k : 1e-6;
      const double den = (kk + d > 1e-6) ? (kk + d) : 1e-6;
      fert = 1.0 + P.beta_max * d / den;
      if (fert < 0.0) fert = 0.0;
    }
    // VOLCANIC DIFFUSE-LIGHT FERTILISATION (2026-08-29). Stratospheric aerosol
    // scatters sunlight, raising the DIFFUSE fraction, and a canopy uses diffuse
    // light more efficiently because shaded leaves receive more of it -- so NPP
    // RISES after a large eruption (Gu et al. 2003 Science 299:2035; Mercado et
    // al. 2009 Nature 458:1014). This is the mechanism the model was missing:
    // the THERMAL path through observed gmst can supply at most ~7 % of the
    // Pinatubo CO2 anomaly and measures ~0 % (2026-08-29e).
    // ⚠ LINEAR IN AOD, and that is only defensible over the OBSERVED range
    // (max 0.11 in the whole record). At large AOD the total-shortwave DIMMING
    // wins and the true response TURNS OVER; that turnover is NOT represented,
    // so do not drive this with a supervolcano.
    // ⚠ gamma_diff DEFAULTS TO 0 -- the mechanism is OFF unless asked for, so
    // every pre-2026-08-29 result is unchanged and remains comparable.
    const double npp = npp0_h * capacity * fert
                       * (1.0 + P.gamma_diff * aod_h_[hi]);

    const double npp_leaf = npp * P.npp_leaf_frac;
    const double npp_wood = npp * (1.0 - P.npp_leaf_frac);
    const double ra_leaf = npp_leaf * P.ra_ratio;
    const double ra_wood = npp_wood * P.ra_ratio;

    // ENSO land anomaly as a ONE-WAY GPP MODULATION (2026-09-02, Marcus).
    // Twin of the block in R/model.R, which carries the full rationale: the
    // old signed flux out of soil_fast ran atmosphere -> soil_fast in reverse,
    // which was the MAJORITY direction for the SH (61 % of active months,
    // 44.5 GtC vs 21.7), and add_flux's guard is structurally blind to it.
    // The two channels are NOT isotopically separable (0.32-0.48 permil apart
    // because soil_fast IS old photosynthate), so this is a physics choice:
    // the model already has a respiration path (q10 on gmst) and NO moisture
    // path at all. Sign: P.gamma_enso_land[hi] * enso is the atmosphere-ward
    // anomaly, so the GPP modulation is its negative. Split by npp_leaf_frac
    // to keep each limb's FRACTIONAL perturbation equal. No new parameter.
    const double enso_gpp = -P.gamma_enso_land[hi] * enso;
    // alpha13_signed reason (a): one-way by construction (see R/model.R).
    // Since 2026-09-02 reason (a) also covers "gamma large enough to shut
    // photosynthesis off" -- a rejected state of the same class as npp < 0.
    add_flux(iatm, ilef, npp_leaf + ra_leaf + enso_gpp * P.npp_leaf_frac,
             A.alpha_photo, true);                             // GPP, leaf
    add_flux(ilef, iatm, ra_leaf, 1.0);                        // Ra, at leaf's ratio
    add_flux(iatm, iwod, npp_wood + ra_wood + enso_gpp * (1.0 - P.npp_leaf_frac),
             A.alpha_photo, true);                             // GPP, wood
    add_flux(iwod, iatm, ra_wood, 1.0);                        // Ra, at wood's ratio

    // litter, split per SOURCE pool (the two carry different 14C ratios, so
    // pooling before the split would average them -- see R/model.R)
    const double lit_leaf = y[IX(ilef, C)] / P.tau_leaf;
    const double lit_wood = y[IX(iwod, C)] / P.tau_wood;
    add_flux(ilef, isf, lit_leaf * (1.0 - P.litter_slow_frac), 1.0);
    add_flux(ilef, iss, lit_leaf * P.litter_slow_frac, 1.0);
    add_flux(iwod, isf, lit_wood * (1.0 - P.litter_slow_frac), 1.0);
    add_flux(iwod, iss, lit_wood * P.litter_slow_frac, 1.0);

    double q10f = std::pow(P.q10, gmst / 10.0);
    // Driver path: respiration breathes with the seasonal land temperature,
    // through the SAME q10, unit-annual-mean (twin of the block in R/model.R).
    // Hemisphere sign: austral summer is January -- see the twin block in
    // R/model.R for why the log-transformed amplitude cannot repair a wrong
    // phase. The norm is sign-invariant by symmetry.
    if (P.seas_drivers > 0)
      q10f *= std::pow(P.q10, (hi == 0 ? 1.0 : -1.0) * P.seas_T_amp[hi]
                * std::sin(2.0 * M_PI * (t - (3.5 + SEAS_T_LAG) / 12.0)) / 10.0)
              / P.seas_r_norm[hi];
    add_flux(isf, iatm, (y[IX(isf, C)] / P.tau_soil_fast) * q10f, 1.0);
    add_flux(iss, iatm, (y[IX(iss, C)] / P.tau_soil_slow) * q10f, 1.0);

    // seasonal NEP through the leaf pool (ENSO now rides the GPP limbs above)
    const double seas = (P.seas_drivers > 0)
      ? P.seas_npp_amp[hi] * npp * (seas_insol(SEAS_PHI_EFF[hi], t - P.seas_lag_p[hi] / 12.0)
                                / P.seas_n_norm[hi] - 1.0)
      : P.seas_amp[hi] * std::sin(2.0 * M_PI * (t - P.seas_phase[hi] / 12.0))
        * (npp / A.npp0[hi]);
    // Photosynthesis discriminates; respiration does not. `seas` is zero-mean,
    // so the autumn limb is carbon leaving the leaf pool at the leaf's own
    // ratio and must NOT be discriminated again. Fixed 2026-08-25e; mirrors
    // R/model.R, which carries the full note.
    add_flux(iatm, ilef, seas, (seas > 0.0) ? A.alpha_photo : 1.0);

    // ENSO land: MOVED 2026-09-02 to the GPP limbs above, as a one-way
    // modulation. It used to be add_flux(isf, iatm, gamma_enso_land[hi]*enso)
    // -- one signed flux at alpha13 = 1 whose reverse limb ran
    // atmosphere -> soil_fast. Twin of the note in R/model.R.

    // air-sea, gross both ways
    // Seasonal SST under seas_drivers, hemisphere-signed -- twin of the block
    // in R/model.R, which carries the rationale (zero-mean driver; the pCO2
    // rectification is accepted as physics).
    // Annual-mean part: observed HadSST4 anomaly (f[12+hi]) when the switch is
    // on and the column exists (NaN = absent -> legacy fallback). Twin of the
    // block in R/model.R.
    const double sst_an = f[12 + hi];
    const double sst = A.sst[hi]
      + ((P.sst_obs > 0 && !std::isnan(sst_an)) ? sst_an : P.sst_scale * gmst)
      + (P.seas_drivers > 0
         ? (hi == 0 ? 1.0 : -1.0) * P.sst_seas_amp[hi]
           * std::sin(2.0 * M_PI * (t - (3.5 + SST_SEAS_LAG) / 12.0))
         : 0.0);
    // Southern-Ocean entrainment channel -- twin of the block in R/model.R,
    // which carries the rationale (SH only; zero-mean driver, the pCO2
    // rectification accepted as physics; no state touched, so this is 4a and
    // not a second ocean column; reaches the atmosphere through the existing
    // evasion limb and is therefore ocean-signatured). A sine peaks a quarter
    // cycle after its zero crossing, so peak month M is phase M/12 - 1/4.
    const double dic_ml = y[IX(iml, C)] * A.mol_per_GtC / ml_mass
      + ((P.seas_drivers > 0 && hi == 1 && P.ent_seas_amp_SH != 0.0)
         ? P.ent_seas_amp_SH * 1e-6
           * std::sin(2.0 * M_PI * (t - (ENT_SEAS_PEAK_MO / 12.0 - 0.25)))
         : 0.0);
    double K0, pco2_ml;
    if (P.revelle_frozen > 0.0) {
      K0 = K0_only(sst, A);
      pco2_ml = A.pco2_0[hi] * (1.0 + A.revelle0[hi]
                                * (dic_ml - A.dic0[hi]) / A.dic0[hi]);
    } else {
      pco2_ml = pco2_from_dic_cpp(dic_ml, A.alk, sst, A, &K0);
    }
    if (pco2_rec) pco2_rec[4 * hi + 0] = pco2_ml;
    const double gx = A.asx[hi] * P.k_w * A.k_w_fac[hi] * K0;   // k_w_fac (2026-09-21 c); 1 = bit-exact
    // alpha13_signed reason (a): one-way by construction -- gx > 0 always, so
    // these go negative only when pCO2 does, i.e. in a diverging intermediate
    // state the caller is about to reject. See R/model.R for the contract.
    // `sst` here is the SEASONAL one, not A.sst[hi] -- that is the mechanism.
    double a_as_dn, a_as_up;
    ccx_alpha_as(sst, A, &a_as_dn, &a_as_up);
    add_flux(iatm, iml, gx * chi,     a_as_dn, true);
    add_flux(iml, iatm, gx * pco2_ml, a_as_up, true);

    // ENSO ocean anomaly -- twin of the block in R/model.R, which carries the
    // rationale (positive coefficient x positive index = MORE uptake, the
    // observed sign; the model's only ENSO path to the ocean is SST solubility
    // and it has the wrong sign; the conveyor was refuted as the fix). TWO
    // EXPLICIT LIMBS, resolving alpha PER DIRECTION: La Nina reverses the term,
    // and the reverse limb of a fractionating exchange is a different process.
    // Unlabelled on both sides, so the flux trace counts it in ocean_net.
    const double ge_ocn = P.gamma_enso_ocn[hi] * enso;
    if (ge_ocn > 0.0)      add_flux(iatm, iml,  ge_ocn, a_as_dn);
    else if (ge_ocn < 0.0) add_flux(iml, iatm, -ge_ocn, a_as_up);

    // the artificial sink rides the SAME downward fractionation as the invasion
    // limb above and carries 14C unfractionated at the atmosphere's own ratio
    if (sink_ocean != 0.0)
      add_flux(iatm, iml, sink_ocean * A.asx[hi] / sink_asx_tot, a_as_dn, true);

    // interior diffusion, per tracer on its own gradient, at the interface's
    // own K (A.kz_int, 2026-09-06b; == P.kz everywhere at the default)
    // THE ML / LAYER-1 INTERFACE UNDER THE EQUATORIAL CELL (2026-09-13g, D1):
    // layer 1 enters with the EFFECTIVE thickness dz_1 * a_ls/a_ml -- twin of
    // the R block, which carries the derivation. Not formed with the cell off.
    const double r1 = A.d1_on ? A.a_ls[hi] / A.a_ml[hi] : 1.0;
    const double dz1_eff = A.d1_on ? dzl[1] * r1 : dzl[1];
    for (int kk = 0; kk < NL; ++kk) {
      const int a = base + IML + kk;
      const int b = base + IML + kk + 1;
      const double dzb = (kk == 0) ? dz1_eff : dzl[kk + 1];
      for (int tr = 0; tr < 3; ++tr) {
        const double Ft = A.kz_int[kk] * (y[IX(a, tr)] / dzl[kk] - y[IX(b, tr)] / dzb)
                          / dzml[kk];
        dy[IX(a, tr)] -= Ft;
        dy[IX(b, tr)] += Ft;
      }
    }

    // ---- SEASONAL ENTRAINMENT / DETRAINMENT -- twin of R/model.R -----
    // A deepening mixed layer swallows layer-1 water AT LAYER-1
    // CONCENTRATIONS; a shoaling one leaves its own water behind at ML
    // concentrations. Same form as the w_up limbs below: a thickness rate over
    // the SOURCE box's thickness.
    // ⛔ TWO EXPLICIT LIMBS, NOT ONE SIGNED FLUX -- the reverse limb draws from
    // a DIFFERENT box, so a signed flux would take its isotopic ratio from the
    // wrong source half the year, and add_flux's antisymmetry hides that from
    // every conservation gate (the 2026-08-25e seasonal-NEP bug).
    // ⭐ alpha13 = 1 DELIBERATELY: entrainment is physical transport, not a
    // fractionating exchange, so add_flux takes 13C AND 14C from the source box
    // for free. Adding a 14C fractionation here would double-count ~17 permil.
    // (the same effective layer-1 thickness under the equatorial cell, D1)
    if (dh_ml_dt > 0.0) {
      add_flux(base + IML + 1, iml,
               y[IX(base + IML + 1, C)] * dh_ml_dt / dz1_eff, 1.0);  // entrainment
    } else if (dh_ml_dt < 0.0) {
      add_flux(iml, base + IML + 1,
               y[IX(iml, C)] * (-dh_ml_dt) / dzl[0], 1.0);           // detrainment
    }

    // the biological pump: mixed layer -> every interior box, TWO LIMBS that
    // differ only in their 13C signature. Soft tissue is ~20 permil DEPLETED
    // relative to the DIC it is fixed from, biogenic CaCO3 slightly ENRICHED,
    // and the carbonate share is pinned by GLODAP's alkalinity gradient rather
    // than fitted (DESIGN sec.5.2d). 14C rides both limbs UNFRACTIONATED, by the
    // Stuiver-Polach convention -- which is what add_flux already does.
    // pump_on = 0 emits nothing, so the no-pump model is bit-reproduced.
    // the seasonal export factor (option O5, 2026-09-15 f): twin of the R
    // block; exactly 1.0 at pump_seas_amp = 0 (bit-exact). Multiplies every
    // pump limb, LS and HS.
    const double s_pump = (P.pump_seas_amp > 0.0 && P.seas_drivers > 0)
      ? 1.0 + P.pump_seas_amp * (hi == 0 ? 1.0 : -1.0)
          * std::sin(2.0 * M_PI * (t - (3.5 + P.pump_seas_lag) / 12.0))
      : 1.0;
    if (A.pump_on) {
      const double sc = ((P.pump_mode == 1)
        ? y[IX(iml, C)] / A.ml_C0[hi] : 1.0) * s_pump;
      if (A.tr_on) {
        // the tropical box carries its AREA SHARE of the export (2026-09-14f,
        // choice D2) -- twin of the R branch, which carries the measurement
        const int itr = base + ITR;
        const double f_ml = A.ml_pump_share[hi], f_tr = 1.0 - f_ml;
        const double sc_t = ((P.pump_mode == 1) ? y[IX(itr, C)] / A.tr_C0[hi] : 1.0) * s_pump;
        for (int kk = 0; kk < NL; ++kk) {
          const int b = base + IML + 1 + kk;
          add_flux(iml, b, A.pump_org[hi][kk] * sc * f_ml, A.alpha_pump_org, true);
          add_flux(iml, b, A.pump_carb[hi][kk] * sc * f_ml, A.alpha_pump_carb, true);
          add_flux(itr, b, A.pump_org[hi][kk] * sc_t * f_tr, A.alpha_pump_org, true);
          add_flux(itr, b, A.pump_carb[hi][kk] * sc_t * f_tr, A.alpha_pump_carb, true);
        }
      } else {
        for (int kk = 0; kk < NL; ++kk) {
          const int b = base + IML + 1 + kk;
          // alpha13_signed: grandfathered 2026-08-25e, behaviour unchanged and
          // OPEN -- pump_org/pump_carb are a flux DIVERGENCE and are negative by
          // construction in some layers. See R/model.R for the full note.
          add_flux(iml, b, A.pump_org[hi][kk] * sc, A.alpha_pump_org, true);
          add_flux(iml, b, A.pump_carb[hi][kk] * sc, A.alpha_pump_carb, true);
        }
      }
    }

    // overturning: uniform upwelling through every interface plus a polar
    // sinking limb from the mixed layer straight to the bottom box. Bulk water
    // transport, so it goes through add_flux at the source box's ratio -- see
    // R/model.R for why this is not a second diffusivity. w_up = 0 emits
    // nothing, reproducing the pure-diffusion column exactly.
    if (P.w_up > 0.0) {
      for (int kk = 0; kk < NL; ++kk) {
        const int a = base + IML + kk;
        const int b = base + IML + kk + 1;
        add_flux(b, a, P.w_up * y[IX(b, C)] / dzl[kk + 1], 1.0);
      }
      add_flux(iml, base + IML + NL, P.w_up * y[IX(iml, C)] / dzl[0], 1.0);
    }

    // outcropping: the non-local limb runs UPWARD -- deep box to mixed layer in
    // one step, with a distributed descending return. NOT a relabelling of
    // w_up; see R/model.R for why which limb is non-local decides both what
    // arrives at the surface and what happens to the deep 14C age.
    if (P.w_out[hi] > 0.0) {
      const int ideep = base + IML + NL;
      add_flux(ideep, iml, P.w_out[hi] * y[IX(ideep, C)] / dzl[NL], 1.0);
      for (int kk = 0; kk < NL; ++kk) {
        const int a = base + IML + kk;
        const int b = base + IML + kk + 1;
        add_flux(a, b, P.w_out[hi] * y[IX(a, C)] / dzl[kk], 1.0);
      }
    }

    // THE CONVEYOR, within-column limb. The two interhemispheric limbs are
    // emitted after this loop, next to tau_ex -- see there and R/model.R.
    if (P.q_conv > 0.0) {
      const int  s_sink = P.conv_sink;
      const int  h_down = (P.conv_reverse == 1) ? 1 : 0;
      const double w    = P.q_conv * SV_TO_M3YR / A.a_oc[hi];
      if (hi == h_down) {
        if (P.conv_descent == 1) {
          for (int kk = 0; kk < s_sink; ++kk)
            add_flux(base + IML + kk, base + IML + kk + 1,
                     w * y[IX(base + IML + kk, C)] / dzl[kk], 1.0);
        } else {
          add_flux(iml, base + IML + s_sink,
                   w * y[IX(iml, C)] / dzl[0], 1.0);
        }
      } else {
        for (int kk = 0; kk < s_sink; ++kk)
          add_flux(base + IML + kk + 1, base + IML + kk,
                   w * y[IX(base + IML + kk + 1, C)] / dzl[kk + 1], 1.0);
      }
    }

    // ---- THE HIGH-LATITUDE COLUMN (HILDA HS/HD) -- twin of the block in
    // R/model.R, which carries the full reasoning: a cold surface box over its
    // own well-mixed deep box, BESIDE the low-latitude column rather than under
    // it (Siegenthaler & Joos 1992, Fig. 1). hs_on = 0 emits nothing and the
    // boxes do not exist, so the 32-box model is bit-reproduced.
    if (A.hs_on) {
      const int ihs = base + IHS;
      const int ihd = base + IHD;

      // (a) air-sea, on the mixed layer's own law. HILDA assumes the per-area
      //     gas exchange coefficient is the same in high and low latitudes
      //     (their Table 1, g_l = g_h); that is THEIR assumption, inherited.
      //     No seasonal cycle on this box -- see the R twin.
      const double sst_h = A.sst_hs
        + ((P.sst_obs > 0 && !std::isnan(sst_an)) ? sst_an : P.sst_scale * gmst);
      const double dic_hs = y[IX(ihs, C)] * A.mol_per_GtC / A.hs_mass_kg[hi];
      double K0h, pco2_hs;
      if (P.revelle_frozen > 0.0) {
        K0h = K0_only(sst_h, A);
        pco2_hs = A.chi0 * (1.0 + A.revelle0_hs
                            * (dic_hs - A.dic0_hs) / A.dic0_hs);
      } else {
        pco2_hs = pco2_from_dic_cpp(dic_hs, A.alk_hs, sst_h, A, &K0h);
      }
      if (pco2_rec) pco2_rec[4 * hi + 1] = pco2_hs;
      const double gx_hs = A.asx_hs[hi] * P.k_w * A.k_w_fac[hi] * A.k_w_fac_hs * K0h;
      double a_dn_h, a_up_h;
      ccx_alpha_as(sst_h, A, &a_dn_h, &a_up_h);
      add_flux(iatm, ihs, gx_hs * chi,     a_dn_h, true);
      add_flux(ihs, iatm, gx_hs * pco2_hs, a_up_h, true);

      // (b) HS <-> HD, two-way GROSS at u_hs m/yr over the HS area; the area
      //     cancels within the column exactly as it does for w_up.
      if (P.u_hs != 0.0) {
        const double u_h = P.u_hs * (hi == 1 ? A.u_hs_fac_SH : 1.0);   // the SH cold box's own ventilation (2026-09-21 c)
        add_flux(ihs, ihd, u_h * y[IX(ihs, C)] / A.h_hs, 1.0);
        add_flux(ihd, ihs, u_h * y[IX(ihd, C)] / A.dz_hd, 1.0);
      }

      // (b') THE HS PUMP (2026-09-07d): HS -> HD, two limbs, the LS pump's
      //      fractionation, DIC-limited scaling against HS's own preindustrial
      //      carbon in mode D. pump_hs_on = 0 emits nothing. See the R twin.
      if (A.pump_hs_on) {
        // O5b (2026-09-16 b): the HS pump's OWN factor -- the data's rectified
        // shape -- replaces the LS sine when pump_hs_seas_amp > 0; at 0 it is
        // s_pump exactly (O5 as built, bit-exact). Gated on P, not on A.
        const double s_hs = (P.pump_hs_seas_amp > 0.0 && P.seas_drivers > 0)
          ? 1.0 + P.pump_hs_seas_amp * (phs_eval(hi, t - P.pump_hs_seas_lag / 12.0) - 1.0)
          : s_pump;
        const double sch = ((P.pump_mode == 1)
          ? y[IX(ihs, C)] / A.hs_C0[hi] : 1.0) * s_hs;     // x the seasonal export factor (O5 / O5b)
        add_flux(ihs, ihd, A.pump_hs_org[hi] * sch, A.alpha_pump_org, true);
        add_flux(ihs, ihd, A.pump_hs_carb[hi] * sch, A.alpha_pump_carb, true);
      }

      // (c) HD <-> interior, volume-proportional: Q_k = a_ls * dz_k / tau_q,
      //     so the layer -> HD limb is exactly y_k / tau_q. The areas do NOT
      //     cancel on the other limb -- this and the conveyor's
      //     interhemispheric limbs are the only cross-column fluxes.
      //     `q_attach_from` (2026-09-05f) subsets this loop; it is 1-BASED
      //     to match R, so the 0-based start is kfrom - 1. Conservation is
      //     unaffected -- each layer's two limbs are volume-symmetric on
      //     their own, so dropping layers drops matched pairs.
      if (P.tau_q > 0.0) {
        const int kfrom = (int) P.q_attach_from;
        if (kfrom < 1 || kfrom > NL)
          Rcpp::stop("q_attach_from must be in 1..%d; got %d", NL, kfrom);
        const double conc_hd = y[IX(ihd, C)] / (A.a_hs[hi] * A.dz_hd);
        const double tq = P.tau_q / (hi == 1 ? A.tau_q_fac_SH : 1.0);   // the SH deep box's own interior exchange (2026-09-21 c)
        for (int kk = kfrom - 1; kk < NL; ++kk) {
          const int ik = base + IML + 1 + kk;
          add_flux(ihd, ik, A.a_ls[hi] * dzl[kk + 1] / tq * conc_hd, 1.0);
          add_flux(ik, ihd, y[IX(ik, C)] / tq, 1.0);
        }
      }
    }

    // ---- THE EQUATORIAL UPWELLING CELL (2026-09-13g) -- twin of the block
    // in R/model.R, which carries the reasoning (prereg 09-13g §2). eq_on = 0
    // emits nothing and the box does not exist.
    if (A.eq_on) {
      const int ieq = base + IEQ;
      const int keq = A.k_eq;                       // 1-based, as in R
      const int iup = base + IML + keq;             // interior layer keq
      // (a) the three-limb loop, one volume flux W round it, each limb W x
      //     the SOURCE box's per-volume concentration (three different areas,
      //     nothing cancels). Association order mirrors the R exactly.
      const double fac = 1.0 - P.gamma_eq * enso;
      const double W = P.w_eq * SV_TO_M3YR * A.eq_w_share[hi] * ((fac > 0.0) ? fac : 0.0);
      if (W > 0.0) {
        add_flux(iup, ieq, W * y[IX(iup, C)] / (A.a_ls[hi] * dzl[keq]), 1.0);      // upwelling
        if (A.tr_on) {
          // the loop closes THROUGH the tropical box (2026-09-14f, ruling R1)
          const int itr = base + ITR;
          add_flux(ieq, itr, W * y[IX(ieq, C)] / (A.a_eq[hi] * A.h_eq), 1.0);       // surface divergence
          add_flux(itr, iup, W * y[IX(itr, C)] / (A.a_tr[hi] * A.h_tr), 1.0);       // subduction
        } else {
          add_flux(ieq, iml, W * y[IX(ieq, C)] / (A.a_eq[hi] * A.h_eq), 1.0);       // surface divergence
          add_flux(iml, iup, W * y[IX(iml, C)] / (A.a_ml[hi] * dzl[0]), 1.0);       // subduction
        }
      }
      // (b) air-sea on the cell at its own SST (+ the hemisphere's anomaly +
      //     its own Nino3.4 slope) and alkalinity; the HS idiom.
      const double sst_e = A.sst_eq
        + ((P.sst_obs > 0 && !std::isnan(sst_an)) ? sst_an : P.sst_scale * gmst)
        + A.sst_eq_enso * enso;
      const double dic_eq = y[IX(ieq, C)] * A.mol_per_GtC / A.eq_mass_kg[hi];
      double K0e, pco2_eq;
      if (P.revelle_frozen > 0.0) {
        K0e = K0_only(sst_e, A);
        pco2_eq = A.chi0 * (1.0 + A.revelle0_eq
                            * (dic_eq - A.dic0_eq) / A.dic0_eq);
      } else {
        pco2_eq = pco2_from_dic_cpp(dic_eq, A.alk_eq, sst_e, A, &K0e);
      }
      if (pco2_rec) pco2_rec[4 * hi + 2] = pco2_eq;
      const double gx_eq = A.asx_eq[hi] * P.k_w * A.k_w_fac[hi] * K0e;
      double a_dn_e, a_up_e;
      ccx_alpha_as(sst_e, A, &a_dn_e, &a_up_e);
      add_flux(iatm, ieq, gx_eq * chi,     a_dn_e, true);
      add_flux(ieq, iatm, gx_eq * pco2_eq, a_up_e, true);
    }

    // ---- THE TROPICAL SURFACE BOX (2026-09-14f) -- twin of the block in
    // R/model.R, which carries the reasoning (prereg 09-14f §2). tr_on = 0
    // emits nothing and the box does not exist.
    if (A.tr_on) {
      const int itr = base + ITR;
      // (a) air-sea at its own SST (+ the hemisphere's anomaly + its own
      //     Nino3.4 slope, R5) and alkalinity; the cell's idiom
      const double sst_t = A.sst_tr
        + ((P.sst_obs > 0 && !std::isnan(sst_an)) ? sst_an : P.sst_scale * gmst)
        + A.sst_tr_enso * enso;
      const double dic_tr = y[IX(itr, C)] * A.mol_per_GtC / A.tr_mass_kg[hi];
      double K0t, pco2_tr;
      if (P.revelle_frozen > 0.0) {
        K0t = K0_only(sst_t, A);
        pco2_tr = A.chi0 * (1.0 + A.revelle0_tr
                            * (dic_tr - A.dic0_tr) / A.dic0_tr);
      } else {
        pco2_tr = pco2_from_dic_cpp(dic_tr, A.alk_tr, sst_t, A, &K0t);
      }
      if (pco2_rec) pco2_rec[4 * hi + 3] = pco2_tr;
      const double gx_tr = A.asx_tr[hi] * P.k_w * A.k_w_fac[hi] * K0t;
      double a_dn_t, a_up_t;
      ccx_alpha_as(sst_t, A, &a_dn_t, &a_up_t);
      add_flux(iatm, itr, gx_tr * chi,     a_dn_t, true);
      add_flux(itr, iatm, gx_tr * pco2_tr, a_up_t, true);
      // (b) the diffusive interface with layer 1 over a_tr at the ML base's
      //     K: layer 1 enters with the effective thickness dz_1 * a_ls/a_tr,
      //     centre distance (h_tr + dz_1)/2 -- twin of R's add_diffusion call,
      //     same association order. dzl[1] is layer 1's thickness NOW.
      //     at kz_tr = kz_tr_frac x kz_int[0] (R6); 0 = no interface
      if (A.kz_tr > 0.0) {
        const int i1 = base + IML + 1;
        const double rt = A.a_ls[hi] / A.a_tr[hi];
        const double dz1_t = dzl[1] * rt;
        const double dzm_t = (A.h_tr + dzl[1]) / 2.0;
        for (int tr = 0; tr < 3; ++tr) {
          const double Ft = A.kz_tr * (y[IX(itr, tr)] / A.h_tr - y[IX(i1, tr)] / dz1_t)
                            / dzm_t;
          dy[IX(itr, tr)] -= Ft;
          dy[IX(i1, tr)]  += Ft;
        }
      }
      // (c) lateral exchange with the residual mixed layer, q_tr (R4: 0 first)
      if (P.q_tr > 0.0) {
        const double Q = P.q_tr * SV_TO_M3YR * A.tr_q_share[hi];
        add_flux(itr, iml, Q * y[IX(itr, C)] / (A.a_tr[hi] * A.h_tr), 1.0);
        add_flux(iml, itr, Q * y[IX(iml, C)] / (A.a_ml[hi] * dzl[0]), 1.0);
      }
    }

    // ---- THE MODE-WATER VENTILATION LOOP (option E, 2026-09-14 h) -- twin
    // of the block in R/model.R, which carries the reasoning (prereg 09-14h
    // §1). e_on = 0 emits nothing. Association order mirrors the R exactly.
    if (A.e_on) {
      const double fac = 1.0 - P.gamma_vent * enso;
      const double W = P.w_vent * SV_TO_M3YR * A.e_share[hi] * ((fac > 0.0) ? fac : 0.0);
      if (W > 0.0) {
        for (int kk = A.k_e1; kk <= A.k_e2; ++kk) {          // 1-based, as in R
          const double Wk = W * A.e_w[kk - 1];
          const int ik = base + IML + kk;                     // interior layer kk
          add_flux(iml, ik, Wk * y[IX(iml, C)] / (A.a_ml[hi] * dzl[0]), 1.0);    // subduction
          add_flux(ik, iml, Wk * y[IX(ik, C)] / (A.a_ls[hi] * dzl[kk]), 1.0);    // return
        }
      }
    }

    // ---- THE LAYER-2 NINO3.4 LIMB (review avenue 1, 2026-09-17 k) -- twin of
    // the block in R/model.R, which carries the reasoning (prereg 09-17k §2).
    // l2_on = 0 emits nothing. Per tracer on its own gradient, NOT add_flux
    // (a negative add_flux takes the ratio from the receiving box). Association
    // order mirrors the R exactly.
    if (A.l2_on) {
      const double fac0 = 1.0 - (P.w_enso_l2 / A.w0_l2) * enso;
      const double fac  = (fac0 > 0.0) ? fac0 : 0.0;
      const double dV   = A.w0_l2 * SV_TO_M3YR * A.l2_share[hi] * (fac - 1.0);
      if (dV != 0.0) {
        const int ik = base + IML + A.k_l2;                  // interior layer k_l2 (1-based)
        const double Vk = A.a_ls[hi] * dzl[A.k_l2];
        const double Vm = A.a_ml[hi] * dzl[0];
        for (int tr = 0; tr < 3; ++tr) {
          const double Ft = dV * (y[IX(ik, tr)] / Vk - y[IX(iml, tr)] / Vm);
          dy[IX(ik, tr)]  -= Ft;
          dy[IX(iml, tr)] += Ft;
        }
      }
    }

    // ---- THE HS-ROUTE DEEP RETURN (option O1 arm THC, 2026-09-15 d) -- twin
    // of the block in R/model.R, which carries the reasoning (prereg 09-15d
    // §1). thc_on = 0 emits nothing. Five legs, each W x the source box's
    // per-volume concentration; association order mirrors the R exactly.
    // HS / HD thicknesses are the fixed A.h_hs / A.dz_hd (option B, the
    // seasonal HS, is R-only and refused on this path).
    if (A.thc_on) {
      const double W = P.w_thc * SV_TO_M3YR * A.thc_share[hi];
      if (W > 0.0) {
        const int ihs = base + IHS, ihd = base + IHD, kt = A.k_thc;
        add_flux(iml, ihs, W * y[IX(iml, C)] / (A.a_ml[hi] * dzl[0]), 1.0);              // (1) poleward
        add_flux(ihs, ihd, W * y[IX(ihs, C)] / (A.a_hs[hi] * A.h_hs), 1.0);              // (2) sinking
        add_flux(ihd, base + IML + NL, W * y[IX(ihd, C)] / (A.a_hs[hi] * A.dz_hd), 1.0); // (3) the abyss
        for (int jj = NL - 1; jj >= kt; --jj) {                                          // (4) upwelling below k (1-based jj)
          const int ifrom = base + IML + jj + 1, ito = base + IML + jj;
          add_flux(ifrom, ito, W * y[IX(ifrom, C)] / (A.a_ls[hi] * dzl[jj + 1]), 1.0);
        }
        add_flux(base + IML + kt, iml, W * y[IX(base + IML + kt, C)] / (A.a_ls[hi] * dzl[kt]), 1.0);  // (5) the return
      }
    }

    // ---- THE GLOBAL THERMOHALINE LOOP, the within-column legs (2026-09-20 v)
    // -- twin of the block in R/model.R, which carries the reasoning (prereg
    // 09-20v §1). gthc_on = 0 emits nothing. The NH (hi 0) SINKS: ml -> hs ->
    // hd -> the bottom layer; the SH (hi 1) UPWELLS: bottom -> up to layer
    // k_gthc -> hd -> hs -> ml. Each leg W x the source box's per-volume
    // concentration; association order mirrors the R exactly. HS / HD
    // thicknesses are the fixed A.h_hs / A.dz_hd (option B is R-only). The two
    // interhemispheric legs are emitted after the loop.
    if (A.gthc_on) {
      const double W = P.w_gthc * SV_TO_M3YR;
      if (W > 0.0) {
        const int ihs = base + IHS, ihd = base + IHD, kg = A.k_gthc;
        if (hi == 0) {
          const int kn = A.kn_gthc;
          if (kn == 0) {
            add_flux(iml, ihs, W * y[IX(iml, C)] / (A.a_ml[hi] * dzl[0]), 1.0);            // (1) poleward, from the ML
          } else {                                                                         // T2: via aged interior water
            const int ik = base + IML + kn;
            add_flux(iml, ik, W * y[IX(iml, C)] / (A.a_ml[hi] * dzl[0]), 1.0);             // (1a) subduction into layer k
            add_flux(ik, ihs, W * y[IX(ik, C)] / (A.a_ls[hi] * dzl[kn]), 1.0);             // (1b) layer k -> the cold box
          }
          add_flux(ihs, ihd, W * y[IX(ihs, C)] / (A.a_hs[hi] * A.h_hs), 1.0);              // (2) NADW formation
          add_flux(ihd, base + IML + NL, W * y[IX(ihd, C)] / (A.a_hs[hi] * A.dz_hd), 1.0); // (3) the abyss
        } else {
          for (int jj = NL - 1; jj >= kg; --jj) {                                          // (5a) upwelling below k (1-based jj)
            const int ifrom = base + IML + jj + 1, ito = base + IML + jj;
            add_flux(ifrom, ito, W * y[IX(ifrom, C)] / (A.a_ls[hi] * dzl[jj + 1]), 1.0);
          }
          add_flux(base + IML + kg, ihd, W * y[IX(base + IML + kg, C)] / (A.a_ls[hi] * dzl[kg]), 1.0);  // (5b) CDW into the SO deep box
          add_flux(ihd, ihs, W * y[IX(ihd, C)] / (A.a_hs[hi] * A.dz_hd), 1.0);             // (5c) outcrop into the cold box
          add_flux(ihs, iml, W * y[IX(ihs, C)] / (A.a_hs[hi] * A.h_hs), 1.0);              // (6) equatorward
        }
      }
    }

    // prescribed emissions -- see R/model.R for the reasoning. Fossil carbon is
    // external to the modelled system; land-use change is not, so it is a
    // TRANSFER out of the WOOD box (which carries wood's own 13C/14C ratios)
    // rather than an external source that created 14C ex nihilo.
    add_source(iatm, f[hi], d13c_foss, -1000.0);
    if (P.f_luc_wood >= 1.0) {
      add_flux(iwod, iatm, f[2 + hi], 1.0);
    } else {
      // pro-rata weights = the four terms A.land0 sums, normalised
      double w4[4] = {P.npp_leaf_frac * P.tau_leaf,
                      (1.0 - P.npp_leaf_frac) * P.tau_wood,
                      (1.0 - P.litter_slow_frac) * P.tau_soil_fast,
                      P.litter_slow_frac * P.tau_soil_slow};
      const double wsum = w4[0] + w4[1] + w4[2] + w4[3];
      const int pool[4] = {ilef, iwod, isf, iss};
      for (int k = 0; k < 4; ++k) {
        double wk = (1.0 - P.f_luc_wood) * w4[k] / wsum;
        if (k == 1) wk += P.f_luc_wood;
        add_flux(pool[k], iatm, f[2 + hi] * wk, 1.0);
      }
    }
  }

  // interhemispheric, gross both ways
  // Twin of ccx_tau_ex_rate() in R/model.R, which carries the full note: the
  // modulation is on the RATE with a zero-mean sinusoid, so the ANNUAL MEAN
  // rate -- and hence the steady gradient -- is preserved while the transient
  // is not. Amplitude 0 is EXACTLY 1/tau_ex, bit for bit.
  const double k_ex = (P.tau_ex_seas_amp == 0.0)
    ? 1.0 / P.tau_ex
    : (1.0 / P.tau_ex) * (1.0 + P.tau_ex_seas_amp
        * std::sin(2.0 * M_PI * (t - P.tau_ex_seas_phase / 12.0)));
  add_flux(0, NPH, y[IX(0, C)] * k_ex, 1.0);
  add_flux(NPH, 0, y[IX(NPH, C)] * k_ex, 1.0);

  // THE CONVEYOR, interhemispheric limbs: the deep limb from the sinking
  // hemisphere's sink layer to the other's, and the surface return. Emitted
  // here because the per-hemisphere loop above can only see one column.
  if (P.q_conv > 0.0) {
    const int s_sink = P.conv_sink;
    const int h_down = (P.conv_reverse == 1) ? 1 : 0;
    const int h_up   = 1 - h_down;
    const double Q   = P.q_conv * SV_TO_M3YR;
    const int deep_dn = h_down * NPH + IML + s_sink;
    const int deep_up = h_up   * NPH + IML + s_sink;
    // ⚠ OUTSIDE the hemisphere loop, so `dzl` is not available and would be the
    // WRONG hemisphere's anyway: this needs the UP hemisphere's own mixed-layer
    // thickness at time t. Twin of the .h_up branch in R/model.R.
    double h_up_ml = A.dz[0];
    if (A.seas_ml != 0 && P.seas_ml_on != 0) { double f, d_; mld_eval(h_up, t, &f, &d_); h_up_ml = A.dz[0] * A.h_ml_fac[h_up] * f; }
    add_flux(deep_dn, deep_up,
             Q * y[IX(deep_dn, C)] / (A.a_oc[h_down] * A.dz[s_sink]), 1.0);
    const int ml_dn = h_down * NPH + IML;
    const int ml_up = h_up   * NPH + IML;
    add_flux(ml_up, ml_dn,
             Q * y[IX(ml_up, C)] / (A.a_oc[h_up] * h_up_ml), 1.0);
  }

  // THE GLOBAL THERMOHALINE LOOP, the two INTERHEMISPHERIC legs (2026-09-20 v):
  // (4) the NH bottom layer -> the SH bottom layer over the NH's a_ls and the
  // bottom dz (fixed under seas_ml); (7) the SH mixed layer -> the NH mixed
  // layer over the SH's a_ml and the SH ML's thickness at t (the conveyor's
  // h_up_ml idiom). Twin of the block in R/model.R.
  if (A.gthc_on) {
    const double W = P.w_gthc * SV_TO_M3YR;
    if (W > 0.0) {
      const int ibN = IML + NL, ibS = NPH + IML + NL;
      add_flux(ibN, ibS, W * y[IX(ibN, C)] / (A.a_ls[0] * A.dz[NL]), 1.0);            // (4) the deep limb
      double h_S = A.dz[0];
      if (A.seas_ml != 0 && P.seas_ml_on != 0) { double f, d_; mld_eval(1, t, &f, &d_); h_S = A.dz[0] * A.h_ml_fac[1] * f; }
      const int imS = NPH + IML, imN = IML;
      add_flux(imS, imN, W * y[IX(imS, C)] / (A.a_ml[1] * h_S), 1.0);                 // (7) the surface limb
    }
  }

  // 14C sources and decay
  const double c14_to_state = 1.0 / (A.mol_per_GtC * A.R14STD);
  dy[IX(0, C14)]   += (f[6] * A.bomb_share_NH + f[7] * A.nuc_share_NH
                      + f[8] * 0.5) * c14_to_state;
  dy[IX(NPH, C14)] += (f[6] * (1.0 - A.bomb_share_NH) + f[7] * (1.0 - A.nuc_share_NH)
                      + f[8] * 0.5) * c14_to_state;
  for (int i = 0; i < NB; ++i) dy[IX(i, C14)] -= A.lambda * y[IX(i, C14)];
}

// ---- unpack helpers -------------------------------------------------
static Aux unpack_aux(const List& a) {
  Aux A;
  // FIRST, because it sets the stride every index below depends on.
  A.hs_on = a["hs_on"];
  // SECOND, for the same reason: the equatorial cell (2026-09-13g) appends
  // one box per hemisphere after hs/hd (or after the interior when HILDA is
  // off), so IEQ and the stride depend on both switches.
  A.eq_on = a["eq_on"];
  IEQ = A.eq_on ? (A.hs_on ? IHD + 1 : IML + NL + 1) : -1;
  // THIRD: the tropical box (2026-09-14f) takes the slot after eq, or eq's
  // slot when the cell is off.
  A.tr_on = a["tr_on"];
  {
    const int after_eq = (A.hs_on ? (IHD + 1) : (IML + NL + 1)) + (A.eq_on ? 1 : 0);
    ITR = A.tr_on ? after_eq : -1;
    NPH = after_eq + (A.tr_on ? 1 : 0);
  }
  A.d1_on = (A.eq_on || A.tr_on) ? 1 : 0;
  NB  = 2 * NPH;
  A.gtc_per_ppm_hemi = a["gtc_per_ppm_hemi"];
  A.chi0 = a["chi0"]; A.mol_per_GtC = a["mol_per_GtC"];
  NumericVector v;
  v = a["npp0"];       A.npp0[0] = v[0];       A.npp0[1] = v[1];
  v = a["veg0"];       A.veg0[0] = v[0];       A.veg0[1] = v[1];
  v = a["land0"];      A.land0[0] = v[0];      A.land0[1] = v[1];
  v = a["ml_mass_kg"]; A.ml_mass_kg[0] = v[0]; A.ml_mass_kg[1] = v[1];
  v = a["asx"];        A.asx[0] = v[0];        A.asx[1] = v[1];
  v = a["sst"];        A.sst[0] = v[0];        A.sst[1] = v[1];
  v = a["dz"];         for (int i = 0; i <= NL; ++i) A.dz[i] = v[i];
  v = a["dz_mid"];     for (int i = 0; i < NL; ++i)  A.dz_mid[i] = v[i];
  v = a["kz_int"];     for (int i = 0; i < NL; ++i)  A.kz_int[i] = v[i];
  A.seas_ml = a["seas_ml"];
  v = a["mld_a"];
  for (int h = 0; h < 2; ++h) for (int k = 0; k < 6; ++k) A.mld_a[h][k] = v[h * 6 + k];
  v = a["mld_b"];
  for (int h = 0; h < 2; ++h) for (int k = 0; k < 6; ++k) A.mld_b[h][k] = v[h * 6 + k];
  v = a["dic0"];       A.dic0[0] = v[0];       A.dic0[1] = v[1];
  v = a["revelle0"];   A.revelle0[0] = v[0];   A.revelle0[1] = v[1];
  v = a["pco2_0"];     A.pco2_0[0] = v[0];     A.pco2_0[1] = v[1];
  A.alpha_photo = a["alpha_photo"];
  A.alpha_as_down = a["alpha_as_down"]; A.alpha_as_up = a["alpha_as_up"];
  A.alpha_as_tdep = a["alpha_as_tdep"];
  A.alpha_as_zA = a["alpha_as_zA"]; A.alpha_as_zB = a["alpha_as_zB"];
  A.alpha_as_zC = a["alpha_as_zC"]; A.alpha_as_fco3 = a["alpha_as_fco3"];
  A.alpha_as_kin_a = a["alpha_as_kin_a"]; A.alpha_as_kin_b = a["alpha_as_kin_b"];
  A.bomb_share_NH = a["bomb_share_NH"]; A.nuc_share_NH = a["nuc_share_NH"];
  A.R13 = a["R13"]; A.R14STD = a["R14STD"]; A.lambda = a["lambda"]; A.alk = a["alk"];
  v = a["cK0"]; for (int i = 0; i < 7; ++i) A.cK0[i] = v[i];
  v = a["cK1"]; for (int i = 0; i < 7; ++i) A.cK1[i] = v[i];
  v = a["cK2"]; for (int i = 0; i < 7; ++i) A.cK2[i] = v[i];
  v = a["cKb"]; for (int i = 0; i < 7; ++i) A.cKb[i] = v[i];
  v = a["cKw"]; for (int i = 0; i < 7; ++i) A.cKw[i] = v[i];
  v = a["a_oc"];       A.a_oc[0] = v[0];       A.a_oc[1] = v[1];
  A.t_centre = a["t_centre"]; A.t_scale = a["t_scale"]; A.boron = a["boron"];
  A.carb_iter = a["carb_iter"];
  A.pump_on = a["pump_on"];
  A.alpha_pump_org = a["alpha_pump_org"]; A.alpha_pump_carb = a["alpha_pump_carb"];
  v = a["ml_C0"]; A.ml_C0[0] = v[0]; A.ml_C0[1] = v[1];
  // Sent FLAT, 2 x NL in hemisphere-major order, and zero-filled when the pump
  // is off so a stale draw cannot leave a live field behind.
  v = a["pump_org"];
  for (int h = 0; h < 2; ++h) for (int k = 0; k < NL; ++k) A.pump_org[h][k] = v[h * NL + k];
  v = a["pump_carb"];
  for (int h = 0; h < 2; ++h) for (int k = 0; k < NL; ++k) A.pump_carb[h][k] = v[h * NL + k];
  A.hs_frac = a["hs_frac"]; A.h_hs = a["h_hs"];
  A.dz_hd = a["dz_hd"]; A.sst_hs = a["sst_hs"];
  A.dic0_hs = a["dic0_hs"]; A.revelle0_hs = a["revelle0_hs"];
  A.alk_hs = a["alk_hs"];
  v = a["a_ls"];       A.a_ls[0] = v[0];       A.a_ls[1] = v[1];
  v = a["a_hs"];       A.a_hs[0] = v[0];       A.a_hs[1] = v[1];
  v = a["hs_mass_kg"]; A.hs_mass_kg[0] = v[0]; A.hs_mass_kg[1] = v[1];
  v = a["asx_hs"];     A.asx_hs[0] = v[0];     A.asx_hs[1] = v[1];
  A.pump_hs_on = a["pump_hs_on"];
  v = a["pump_hs_org"];  A.pump_hs_org[0] = v[0];  A.pump_hs_org[1] = v[1];
  v = a["pump_hs_carb"]; A.pump_hs_carb[0] = v[0]; A.pump_hs_carb[1] = v[1];
  v = a["hs_C0"];        A.hs_C0[0] = v[0];        A.hs_C0[1] = v[1];
  A.pump_hs_seas_on = a["pump_hs_seas_on"];                                        // O5b (2026-09-16 b)
  v = a["phs_a"]; for (int h = 0; h < 2; ++h) for (int k = 0; k < 6; ++k) A.phs_a[h][k] = v[h * 6 + k];
  v = a["phs_b"]; for (int h = 0; h < 2; ++h) for (int k = 0; k < 6; ++k) A.phs_b[h][k] = v[h * 6 + k];
  // the equatorial cell (2026-09-13g); eq_on was read at the top
  v = a["a_ml"];        A.a_ml[0] = v[0];        A.a_ml[1] = v[1];
  v = a["a_eq"];        A.a_eq[0] = v[0];        A.a_eq[1] = v[1];
  v = a["eq_mass_kg"];  A.eq_mass_kg[0] = v[0];  A.eq_mass_kg[1] = v[1];
  v = a["asx_eq"];      A.asx_eq[0] = v[0];      A.asx_eq[1] = v[1];
  v = a["eq_w_share"];  A.eq_w_share[0] = v[0];  A.eq_w_share[1] = v[1];
  A.h_eq = a["h_eq"]; A.sst_eq = a["sst_eq"]; A.sst_eq_enso = a["sst_eq_enso"];
  A.alk_eq = a["alk_eq"]; A.k_eq = a["k_eq"];
  A.dic0_eq = a["dic0_eq"]; A.revelle0_eq = a["revelle0_eq"];
  // the tropical box (2026-09-14f); tr_on was read at the top
  v = a["a_tr"];        A.a_tr[0] = v[0];        A.a_tr[1] = v[1];
  v = a["tr_mass_kg"];  A.tr_mass_kg[0] = v[0];  A.tr_mass_kg[1] = v[1];
  v = a["asx_tr"];      A.asx_tr[0] = v[0];      A.asx_tr[1] = v[1];
  v = a["tr_q_share"];  A.tr_q_share[0] = v[0];  A.tr_q_share[1] = v[1];
  A.h_tr = a["h_tr"]; A.sst_tr = a["sst_tr"]; A.sst_tr_enso = a["sst_tr_enso"];
  A.alk_tr = a["alk_tr"];
  A.dic0_tr = a["dic0_tr"]; A.revelle0_tr = a["revelle0_tr"];
  v = a["ml_pump_share"]; A.ml_pump_share[0] = v[0]; A.ml_pump_share[1] = v[1];
  v = a["tr_C0"];         A.tr_C0[0] = v[0];         A.tr_C0[1] = v[1];
  A.kz_tr = a["kz_tr"];
  // the ventilation loop (option E, 2026-09-14 h)
  A.e_on = a["e_on"]; A.k_e1 = a["k_e1"]; A.k_e2 = a["k_e2"];
  v = a["e_w"];       for (int k = 0; k < NL; ++k) A.e_w[k] = v[k];
  v = a["e_share"];   A.e_share[0] = v[0];   A.e_share[1] = v[1];
  A.thc_on = a["thc_on"]; A.k_thc = a["k_thc"];                    // the HS-route deep return (2026-09-15 d)
  v = a["thc_share"]; A.thc_share[0] = v[0]; A.thc_share[1] = v[1];
  A.gthc_on = a["gthc_on"]; A.k_gthc = a["k_gthc"];                // the global thermohaline loop (2026-09-20 v)
  A.kn_gthc = a["kn_gthc"];                                    // T2 (2026-09-21 b)
  A.u_hs_fac_SH = a["u_hs_fac_SH"];                            // 2026-09-21 c
  A.tau_q_fac_SH = a["tau_q_fac_SH"];
  v = a["k_w_fac"]; A.k_w_fac[0] = v[0]; A.k_w_fac[1] = v[1]; A.k_w_fac_hs = a["k_w_fac_hs"];
  v = a["h_ml_fac"]; A.h_ml_fac[0] = v[0]; A.h_ml_fac[1] = v[1];                                   // 2026-09-21 d
  A.l2_on = a["l2_on"]; A.k_l2 = a["k_l2"]; A.w0_l2 = a["w0_l2"];   // the layer-2 Nino3.4 limb (2026-09-17 k)
  v = a["l2_share"];  A.l2_share[0] = v[0];  A.l2_share[1] = v[1];
  return A;
}

static Par unpack_par(const List& p) {
  Par P;
  P.beta = p["beta"]; P.q10 = p["q10"];
  P.fert_form = p["fert_form"];
  P.beta_max = p["beta_max"]; P.fert_k = p["fert_k"];
  P.npp_leaf_frac = p["npp_leaf_frac"];
  P.tau_leaf = p["tau_leaf"]; P.tau_wood = p["tau_wood"];
  P.litter_slow_frac = p["litter_slow_frac"];
  P.tau_soil_fast = p["tau_soil_fast"]; P.tau_soil_slow = p["tau_soil_slow"];
  P.npp_veg_frac = p["npp_veg_frac"]; P.ra_ratio = p["ra_ratio"];
  P.f_luc_perm = p["f_luc_perm"]; P.f_luc_wood = p["f_luc_wood"];
  P.k_w = p["k_w"]; P.kz = p["kz"]; P.w_up = p["w_up"]; P.tau_ex = p["tau_ex"];
  P.tau_ex_seas_amp = p["tau_ex_seas_amp"];
  P.tau_ex_seas_phase = p["tau_ex_seas_phase"];
  P.w_out[0] = p["w_out_NH"]; P.w_out[1] = p["w_out_SH"];
  // Defaulted on the R side by ccx_cpp_par(), which is where every other
  // "a pre-dated parameter list must still reach the core as a model"
  // fallback lives; read unconditionally here, as every field is.
  P.u_hs = p["u_hs"]; P.tau_q = p["tau_q"];
  P.w_eq = p["w_eq"]; P.gamma_eq = p["gamma_eq"];   // the equatorial cell (2026-09-13g)
  P.q_tr = p["q_tr"];                                // the tropical box (2026-09-14f)
  P.w_vent = p["w_vent"]; P.gamma_vent = p["gamma_vent"];        // the ventilation loop (2026-09-14 h)
  P.w_thc = p["w_thc"];                                          // the HS-route deep return (2026-09-15 d)
  P.w_gthc = p["w_gthc"];                                        // the global thermohaline loop (2026-09-20 v)
  P.w_enso_l2 = p["w_enso_l2"];                                  // the layer-2 Nino3.4 limb (2026-09-17 k)
  P.pump_seas_amp = p["pump_seas_amp"]; P.pump_seas_lag = p["pump_seas_lag"];   // the seasonal export (2026-09-15 f)
  P.pump_hs_seas_amp = p["pump_hs_seas_amp"]; P.pump_hs_seas_lag = p["pump_hs_seas_lag"];   // O5b (2026-09-16 b)
  P.q_attach_from = p["q_attach_from"];
  P.q_conv = p["q_conv"];
  P.conv_sink = p["conv_sink"]; P.conv_descent = p["conv_descent"];
  P.conv_reverse = p["conv_reverse"];
  P.pump_mode = p["pump_mode"];
  P.sst_scale = p["sst_scale"];
  P.gamma_enso_land[0] = p["gamma_enso_land_NH"];
  P.gamma_enso_land[1] = p["gamma_enso_land_SH"];
  P.gamma_enso_ocn[0]  = p["gamma_enso_ocn_NH"];
  P.gamma_enso_ocn[1]  = p["gamma_enso_ocn_SH"];
  P.gamma_diff = p["gamma_diff"];
  P.seas_amp[0] = p["seas_amp_NH"]; P.seas_amp[1] = p["seas_amp_SH"];
  P.seas_phase[0] = p["seas_phase_NH"]; P.seas_phase[1] = p["seas_phase_SH"];
  P.seas_drivers = (int) p["seas_drivers"];
  P.seas_ml_on   = (int) p["seas_ml_on"];   // resolved by ccx_cpp_par()
  P.seas_T_amp[0] = p["seas_T_amp_NH"]; P.seas_T_amp[1] = p["seas_T_amp_SH"];
  // ccx_cpp_par() guarantees both fields are present, resolving absence through
  // ccx_seas_lag_p() -- the SAME function the R core uses. Do not add a
  // fallback here: a second opinion about absence is exactly the defect that
  // cost 0.647 GtC/yr on 2026-08-30.
  P.seas_lag_p[0] = p["seas_lag_p_NH"];
  P.seas_lag_p[1] = p["seas_lag_p_SH"];
  P.sst_seas_amp[0] = p["sst_seas_amp_NH"]; P.sst_seas_amp[1] = p["sst_seas_amp_SH"];
  P.ent_seas_amp_SH = p["ent_seas_amp_SH"];
  P.seas_npp_amp[0] = p["seas_npp_amp_NH"]; P.seas_npp_amp[1] = p["seas_npp_amp_SH"];
  P.sst_obs = (int) p["sst_obs"];
  // 720-point norm grid, NOT 12 -- twin of ccx_seas_norms() in R/model.R,
  // which documents why (the polar-night kink leaks +0.22 ppm / 275 yr at 12).
  for (int h = 0; h < 2; ++h) {
    double sn = 0.0, sr = 0.0;
    for (int m = 1; m <= 720; ++m) {
      const double mid = (m - 0.5) / 720.0;
      sn += seas_insol(SEAS_PHI_EFF[h], mid - P.seas_lag_p[h] / 12.0);
      sr += std::pow(P.q10, P.seas_T_amp[h]
                     * std::sin(2.0 * M_PI * (mid - (3.5 + SEAS_T_LAG) / 12.0)) / 10.0);
    }
    P.seas_n_norm[h] = sn / 720.0; P.seas_r_norm[h] = sr / 720.0;
  }
  P.revelle_frozen = p["revelle_frozen"];
  return P;
}

// ---- exported: single derivative (for parity testing) ---------------
// [[Rcpp::export]]
NumericMatrix ccx_deriv_cpp(NumericMatrix y, double t, List p, NumericVector f, List aux) {
  Aux A = unpack_aux(aux); Par P = unpack_par(p);
  NumericMatrix dy(NB, 3);
  deriv(y.begin(), t, P, f.begin(), A, dy.begin());
  return dy;
}

// ---- exported: full integration -------------------------------------
// forcing is an n x 10 matrix, one row per month, columns in the order given in
// deriv() above.
// [[Rcpp::export]]
List ccx_run_cpp(NumericMatrix y0, List p, NumericMatrix forcing,
                 NumericVector times, List aux, int substeps) {
  Aux A = unpack_aux(aux); Par P = unpack_par(p);
  const int n = forcing.nrow();
  const int NS = NB * 3;

  std::vector<double> y(NS), k1(NS), k2(NS), k3(NS), k4(NS), tmp(NS);
  for (int i = 0; i < NS; ++i) y[i] = y0[i];

  // co2 NH/SH, d13c NH/SH, d14c NH/SH, ocean C, land C, then the three 14C
  // reservoir inventories in STATE units ("GtC carrying standard 14C content").
  // They are emitted raw rather than in kmol because the core has no business
  // knowing an inventory convention; likelihood.R converts with a named
  // constant. Needed by the ocean excess-14C constraint, which is an inventory
  // at two reference years and so cannot be reconstructed from D14C alone.
  // ... then, for each hemisphere, the MIXED-LAYER and BOTTOM-BOX carbon and
  // 13C, in STATE units (GtC), for the ocean DIC / d13C GRADIENT terms. Emitted
  // RAW for the same reason the 14C inventories are: turning them into umol/kg
  // needs the box volume, i.e. an observational convention the core has no
  // business owning. R/likelihood.R converts. They are a TIME SERIES rather
  // than a final state because the gradient terms are scored at the
  // OBSERVATIONS' epoch (~2000, not the run's end year) -- Marcus 2026-08-16.
  NumericMatrix out(n, 39);   // 11 + 14 per hemisphere (CCX_OCEAN_BOX_COLS)
  double pco2_rec[8];
  const double gpp = A.gtc_per_ppm_hemi;

  std::vector<double> f(N_FORCING);
  for (int i = 0; i < n; ++i) {
    out(i, 0) = y[IX(0, C)] / gpp;
    out(i, 1) = y[IX(NPH, C)] / gpp;
    out(i, 2) = 1000.0 * (y[IX(0, C13)] / (y[IX(0, C)] * A.R13) - 1.0);
    out(i, 3) = 1000.0 * (y[IX(NPH, C13)] / (y[IX(NPH, C)] * A.R13) - 1.0);
    out(i, 4) = 1000.0 * (y[IX(0, C14)] / y[IX(0, C)] - 1.0);
    out(i, 5) = 1000.0 * (y[IX(NPH, C14)] / y[IX(NPH, C)] - 1.0);
    double oc = 0.0, ld = 0.0, oc14 = 0.0, ld14 = 0.0, at14 = 0.0;
    for (int hi = 0; hi < 2; ++hi) {
      const int base = hi * NPH;
      at14 += y[IX(base, C14)];
      for (int kk = 1; kk < IML; ++kk) {          // the four land pools
        ld   += y[IX(base + kk, C)];
        ld14 += y[IX(base + kk, C14)];
      }
      for (int kk = IML; kk < NPH; ++kk) {        // mixed layer + interior
        oc   += y[IX(base + kk, C)];
        oc14 += y[IX(base + kk, C14)];
      }
    }
    out(i, 6) = oc; out(i, 7) = ld;
    out(i, 8) = oc14; out(i, 9) = ld14; out(i, 10) = at14;
    for (int hi = 0; hi < 2; ++hi) {
      const int base = hi * NPH;
      const int iml = base + IML, idp = base + IML + NL;
      const int o = 11 + 14 * hi;            // this hemisphere's block (CCX_OCEAN_BOX_COLS)
      out(i, o + 0) = y[IX(iml, C)];
      out(i, o + 1) = y[IX(iml, C13)];
      out(i, o + 2) = y[IX(idp, C)];
      out(i, o + 3) = y[IX(idp, C13)];
      // the HS box (2026-09-07f): exists only with the structure on -- with it
      // off IHS is past the state vector, so write NA rather than read it.
      if (A.hs_on) {
        out(i, o + 4) = y[IX(base + IHS, C)];
        out(i, o + 5) = y[IX(base + IHS, C13)];
      } else {
        out(i, o + 4) = NA_REAL;
        out(i, o + 5) = NA_REAL;
      }
      // the equatorial cell (2026-09-13g), likewise
      if (A.eq_on) {
        out(i, o + 6) = y[IX(base + IEQ, C)];
        out(i, o + 7) = y[IX(base + IEQ, C13)];
      } else {
        out(i, o + 6) = NA_REAL;
        out(i, o + 7) = NA_REAL;
      }
      // the tropical box (2026-09-14f), likewise
      if (A.tr_on) {
        out(i, o + 8) = y[IX(base + ITR, C)];
        out(i, o + 9) = y[IX(base + ITR, C13)];
      } else {
        out(i, o + 8) = NA_REAL;
        out(i, o + 9) = NA_REAL;
      }
      // columns o + 10..13 -- ml_pco2 / hs_pco2 / eq_pco2 / tr_pco2 -- are
      // filled below off the month's FIRST RK4 stage, which is the derivative
      // at exactly this (y, t, forcing row).
    }

    for (int j = 0; j < N_FORCING; ++j) f[j] = forcing(i, j);

    // RK4 with substeps, ordered exactly as ccx_step_rk4() in R
    double tt = times[i];
    const double h = (1.0 / 12.0) / substeps;
    for (int s = 0; s < substeps; ++s) {
      deriv(y.data(), tt, P, f.data(), A, k1.data(), (s == 0) ? pco2_rec : nullptr);
      if (s == 0)
        for (int hi = 0; hi < 2; ++hi)
          for (int b = 0; b < 4; ++b) out(i, 11 + 14 * hi + 10 + b) = pco2_rec[4 * hi + b];
      for (int q = 0; q < NS; ++q) tmp[q] = y[q] + h / 2.0 * k1[q];
      deriv(tmp.data(), tt + h / 2.0, P, f.data(), A, k2.data());
      for (int q = 0; q < NS; ++q) tmp[q] = y[q] + h / 2.0 * k2[q];
      deriv(tmp.data(), tt + h / 2.0, P, f.data(), A, k3.data());
      for (int q = 0; q < NS; ++q) tmp[q] = y[q] + h * k3[q];
      deriv(tmp.data(), tt + h, P, f.data(), A, k4.data());
      for (int q = 0; q < NS; ++q)
        y[q] = y[q] + h / 6.0 * (k1[q] + 2.0 * k2[q] + 2.0 * k3[q] + k4[q]);
      tt = tt + h;
    }
  }

  NumericMatrix yend(NB, 3);
  for (int i = 0; i < NS; ++i) yend[i] = y[i];
  return List::create(_["state"] = yend, _["out"] = out);
}
