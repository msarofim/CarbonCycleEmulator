// =====================================================================
// ccx_core.cpp — production core. Mirrors R/model.R operation for operation.
//
// R/model.R is the REFERENCE IMPLEMENTATION and stays authoritative for
// readability and for what the model means. This file exists only because the
// pure-R version runs a 350-year monthly integration in ~26 s against a 50 ms
// budget for MCMC. Any change to the physics must be made in BOTH, and
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
static const int NPH = 16;         // boxes per hemisphere (the stride)
static const int NB = 2 * NPH;     // boxes
static const int NL = 10;          // ocean interior layers
static const int IML = 5;          // mixed layer, relative to the hemisphere base
static const int C = 0, C13 = 1, C14 = 2;

// Forcing columns, and the ceiling on the cleared fraction. BOTH are duplicated
// on the R side -- CCX_FORCING_COLS in R/cpp.R and CCX_LUC_CLEARED_MAX in
// R/model.R -- because the two implementations are independent by design. A
// disagreement in the column count is caught by ccx_cpp_forcing()'s name check;
// a disagreement in the ceiling is NOT caught by anything, so if one moves the
// other must move in the same commit.
static const int N_FORCING = 12;
static const double LUC_CLEARED_MAX = 0.9;

// state is column-major [box + NB*tracer], matching R's matrix layout
inline int IX(int box, int tr) { return box + NB * tr; }

struct Aux {
  double gtc_per_ppm_hemi, chi0, mol_per_GtC;
  double npp0[2], veg0[2], land0[2], ml_mass_kg[2], asx[2], sst[2];
  double dz[NL + 1], dz_mid[NL];
  double alpha_photo, alpha_as_down, alpha_as_up;
  // d13c_foss MOVED to the forcing (2026-08-12): the fossil source d13C is
  // time-varying, so it is no longer an invariant.
  double enso_share[2];
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
  int pump_on;
  double pump_org[2][NL], pump_carb[2][NL];
  double ml_C0[2];                  // preindustrial ML carbon, DIC-limited mode
  double alpha_pump_org, alpha_pump_carb;   // 13C fractionation, per limb
};

// FERTILISATION FORM. Mirrors CCX_FERT_LOG / CCX_FERT_MM in R/model.R; the two
// must agree exactly or test-parity.R fails, which is the point.
#define FERT_LOG 0
#define FERT_MM  1

struct Par {
  double beta, q10, k_w, kz, w_up, w_out[2], tau_ex;
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
  double sst_scale, gamma_enso;
  double seas_amp[2], seas_phase[2];
  double revelle_frozen;                    // mechanism switch, 0 or 1
};

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
static void deriv(const double* y, double t, const Par& P, const double* f,
                  const Aux& A, double* dy) {
  for (int i = 0; i < NB * 3; ++i) dy[i] = 0.0;

  // flux helper: source-ratio transport, applied antisymmetrically
  auto add_flux = [&](int from, int to, double F, double alpha13) {
    if (F == 0.0) return;
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
  //                 cum_luc_NH, cum_luc_SH
  // Must stay in step with CCX_FORCING_COLS in R/cpp.R -- indexed by position,
  // so a mismatch is silent garbage. test-parity.R is the gate.
  const double gmst = f[4], enso = f[5], d13c_foss = f[9];

  for (int hi = 0; hi < 2; ++hi) {
    const int base = hi * NPH;
    const int iatm = base, ilef = base + 1, iwod = base + 2;
    const int isf = base + 3, iss = base + 4, iml = base + IML;

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
    const double npp = npp0_h * capacity * fert;

    const double npp_leaf = npp * P.npp_leaf_frac;
    const double npp_wood = npp * (1.0 - P.npp_leaf_frac);
    const double ra_leaf = npp_leaf * P.ra_ratio;
    const double ra_wood = npp_wood * P.ra_ratio;
    add_flux(iatm, ilef, npp_leaf + ra_leaf, A.alpha_photo);   // GPP, leaf
    add_flux(ilef, iatm, ra_leaf, 1.0);                        // Ra, at leaf's ratio
    add_flux(iatm, iwod, npp_wood + ra_wood, A.alpha_photo);   // GPP, wood
    add_flux(iwod, iatm, ra_wood, 1.0);                        // Ra, at wood's ratio

    // litter, split per SOURCE pool (the two carry different 14C ratios, so
    // pooling before the split would average them -- see R/model.R)
    const double lit_leaf = y[IX(ilef, C)] / P.tau_leaf;
    const double lit_wood = y[IX(iwod, C)] / P.tau_wood;
    add_flux(ilef, isf, lit_leaf * (1.0 - P.litter_slow_frac), 1.0);
    add_flux(ilef, iss, lit_leaf * P.litter_slow_frac, 1.0);
    add_flux(iwod, isf, lit_wood * (1.0 - P.litter_slow_frac), 1.0);
    add_flux(iwod, iss, lit_wood * P.litter_slow_frac, 1.0);

    const double q10f = std::pow(P.q10, gmst / 10.0);
    add_flux(isf, iatm, (y[IX(isf, C)] / P.tau_soil_fast) * q10f, 1.0);
    add_flux(iss, iatm, (y[IX(iss, C)] / P.tau_soil_slow) * q10f, 1.0);

    // seasonal NEP through the leaf pool; ENSO out of the responsive soil pool
    const double seas = P.seas_amp[hi] * std::sin(2.0 * M_PI * (t - P.seas_phase[hi] / 12.0))
                        * (npp / A.npp0[hi]);
    add_flux(iatm, ilef, seas, A.alpha_photo);

    if (A.enso_share[hi] != 0.0)
      add_flux(isf, iatm, P.gamma_enso * enso * A.enso_share[hi], 1.0);

    // air-sea, gross both ways
    const double sst = A.sst[hi] + P.sst_scale * gmst;
    const double dic_ml = y[IX(iml, C)] * A.mol_per_GtC / A.ml_mass_kg[hi];
    double K0, pco2_ml;
    if (P.revelle_frozen > 0.0) {
      K0 = K0_only(sst, A);
      pco2_ml = A.pco2_0[hi] * (1.0 + A.revelle0[hi]
                                * (dic_ml - A.dic0[hi]) / A.dic0[hi]);
    } else {
      pco2_ml = pco2_from_dic_cpp(dic_ml, A.alk, sst, A, &K0);
    }
    const double gx = A.asx[hi] * P.k_w * K0;
    add_flux(iatm, iml, gx * chi,     A.alpha_as_down);
    add_flux(iml, iatm, gx * pco2_ml, A.alpha_as_up);

    // interior diffusion, per tracer on its own gradient
    for (int kk = 0; kk < NL; ++kk) {
      const int a = base + IML + kk;
      const int b = base + IML + kk + 1;
      for (int tr = 0; tr < 3; ++tr) {
        const double Ft = P.kz * (y[IX(a, tr)] / A.dz[kk] - y[IX(b, tr)] / A.dz[kk + 1])
                          / A.dz_mid[kk];
        dy[IX(a, tr)] -= Ft;
        dy[IX(b, tr)] += Ft;
      }
    }

    // the biological pump: mixed layer -> every interior box, TWO LIMBS that
    // differ only in their 13C signature. Soft tissue is ~20 permil DEPLETED
    // relative to the DIC it is fixed from, biogenic CaCO3 slightly ENRICHED,
    // and the carbonate share is pinned by GLODAP's alkalinity gradient rather
    // than fitted (DESIGN sec.5.2d). 14C rides both limbs UNFRACTIONATED, by the
    // Stuiver-Polach convention -- which is what add_flux already does.
    // pump_on = 0 emits nothing, so the no-pump model is bit-reproduced.
    if (A.pump_on) {
      const double sc = (P.pump_mode == 1)
        ? y[IX(iml, C)] / A.ml_C0[hi] : 1.0;
      for (int kk = 0; kk < NL; ++kk) {
        const int b = base + IML + 1 + kk;
        add_flux(iml, b, A.pump_org[hi][kk] * sc, A.alpha_pump_org);
        add_flux(iml, b, A.pump_carb[hi][kk] * sc, A.alpha_pump_carb);
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
        add_flux(b, a, P.w_up * y[IX(b, C)] / A.dz[kk + 1], 1.0);
      }
      add_flux(iml, base + IML + NL, P.w_up * y[IX(iml, C)] / A.dz[0], 1.0);
    }

    // outcropping: the non-local limb runs UPWARD -- deep box to mixed layer in
    // one step, with a distributed descending return. NOT a relabelling of
    // w_up; see R/model.R for why which limb is non-local decides both what
    // arrives at the surface and what happens to the deep 14C age.
    if (P.w_out[hi] > 0.0) {
      const int ideep = base + IML + NL;
      add_flux(ideep, iml, P.w_out[hi] * y[IX(ideep, C)] / A.dz[NL], 1.0);
      for (int kk = 0; kk < NL; ++kk) {
        const int a = base + IML + kk;
        const int b = base + IML + kk + 1;
        add_flux(a, b, P.w_out[hi] * y[IX(a, C)] / A.dz[kk], 1.0);
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
                     w * y[IX(base + IML + kk, C)] / A.dz[kk], 1.0);
        } else {
          add_flux(iml, base + IML + s_sink,
                   w * y[IX(iml, C)] / A.dz[0], 1.0);
        }
      } else {
        for (int kk = 0; kk < s_sink; ++kk)
          add_flux(base + IML + kk + 1, base + IML + kk,
                   w * y[IX(base + IML + kk + 1, C)] / A.dz[kk + 1], 1.0);
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
  add_flux(0, NPH, y[IX(0, C)] / P.tau_ex, 1.0);
  add_flux(NPH, 0, y[IX(NPH, C)] / P.tau_ex, 1.0);

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
    add_flux(deep_dn, deep_up,
             Q * y[IX(deep_dn, C)] / (A.a_oc[h_down] * A.dz[s_sink]), 1.0);
    const int ml_dn = h_down * NPH + IML;
    const int ml_up = h_up   * NPH + IML;
    add_flux(ml_up, ml_dn,
             Q * y[IX(ml_up, C)] / (A.a_oc[h_up] * A.dz[0]), 1.0);
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
  v = a["enso_share"]; A.enso_share[0] = v[0]; A.enso_share[1] = v[1];
  v = a["dic0"];       A.dic0[0] = v[0];       A.dic0[1] = v[1];
  v = a["revelle0"];   A.revelle0[0] = v[0];   A.revelle0[1] = v[1];
  v = a["pco2_0"];     A.pco2_0[0] = v[0];     A.pco2_0[1] = v[1];
  A.alpha_photo = a["alpha_photo"];
  A.alpha_as_down = a["alpha_as_down"]; A.alpha_as_up = a["alpha_as_up"];
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
  P.w_out[0] = p["w_out_NH"]; P.w_out[1] = p["w_out_SH"];
  P.q_conv = p["q_conv"];
  P.conv_sink = p["conv_sink"]; P.conv_descent = p["conv_descent"];
  P.conv_reverse = p["conv_reverse"];
  P.pump_mode = p["pump_mode"];
  P.sst_scale = p["sst_scale"]; P.gamma_enso = p["gamma_enso"];
  P.seas_amp[0] = p["seas_amp_NH"]; P.seas_amp[1] = p["seas_amp_SH"];
  P.seas_phase[0] = p["seas_phase_NH"]; P.seas_phase[1] = p["seas_phase_SH"];
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
  NumericMatrix out(n, 19);
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
      out(i, 11 + 4 * hi) = y[IX(iml, C)];
      out(i, 12 + 4 * hi) = y[IX(iml, C13)];
      out(i, 13 + 4 * hi) = y[IX(idp, C)];
      out(i, 14 + 4 * hi) = y[IX(idp, C13)];
    }

    for (int j = 0; j < N_FORCING; ++j) f[j] = forcing(i, j);

    // RK4 with substeps, ordered exactly as ccx_step_rk4() in R
    double tt = times[i];
    const double h = (1.0 / 12.0) / substeps;
    for (int s = 0; s < substeps; ++s) {
      deriv(y.data(), tt, P, f.data(), A, k1.data());
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
