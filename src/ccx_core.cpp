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

static const int NB = 28;          // boxes
static const int NL = 10;          // ocean interior layers
static const int C = 0, C13 = 1, C14 = 2;

// state is column-major [box + NB*tracer], matching R's matrix layout
inline int IX(int box, int tr) { return box + NB * tr; }

struct Aux {
  double gtc_per_ppm_hemi, chi0, mol_per_GtC;
  double npp0[2], ml_mass_kg[2], asx[2], sst[2];
  double dz[NL + 1], dz_mid[NL];
  double alpha_photo, alpha_as_down, alpha_as_up;
  double d13c_foss, d13c_bio, enso_share[2];
  double dic0[2], revelle0[2], pco2_0[2];   // preindustrial mixed-layer reference
  double bomb_share_NH, nuc_share_NH;
  double R13, R14STD, lambda, alk;
  // carbonate polynomial coefficients (degree 6 -> 7 coefficients each)
  double cK0[7], cK1[7], cK2[7], cKb[7], cKw[7];
  double t_centre, t_scale, boron;
  int carb_iter;
};

struct Par {
  double beta, q10, tau_veg, tau_soil, k_w, kz, tau_ex;
  double sst_scale, gamma_enso;
  double seas_amp[2], seas_phase[2];
  double revelle_frozen;                    // mechanism switch, 0 or 1
};

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
  //                 c14_bomb, c14_nuclear, c14_cosmo
  const double gmst = f[4], enso = f[5];

  for (int hi = 0; hi < 2; ++hi) {
    const int base = hi * 14;
    const int iatm = base, iveg = base + 1, isol = base + 2, iml = base + 3;

    const double chi = y[IX(iatm, C)] / A.gtc_per_ppm_hemi;

    // land
    const double chi_safe = (chi > 1e-6) ? chi : 1e-6;
    const double npp = A.npp0[hi] * (1.0 + P.beta * std::log(chi_safe / A.chi0));
    add_flux(iatm, iveg, npp, A.alpha_photo);

    const double litter = y[IX(iveg, C)] / P.tau_veg;
    add_flux(iveg, isol, litter, 1.0);

    const double rh = (y[IX(isol, C)] / P.tau_soil) * std::pow(P.q10, gmst / 10.0);
    add_flux(isol, iatm, rh, 1.0);

    const double seas = P.seas_amp[hi] * std::sin(2.0 * M_PI * (t - P.seas_phase[hi] / 12.0))
                        * (npp / A.npp0[hi]);
    add_flux(iatm, iveg, seas, A.alpha_photo);

    if (A.enso_share[hi] != 0.0)
      add_flux(isol, iatm, P.gamma_enso * enso * A.enso_share[hi], 1.0);

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
      const int a = (kk == 0) ? iml : (base + 3 + kk);
      const int b = base + 4 + kk;
      for (int tr = 0; tr < 3; ++tr) {
        const double Ft = P.kz * (y[IX(a, tr)] / A.dz[kk] - y[IX(b, tr)] / A.dz[kk + 1])
                          / A.dz_mid[kk];
        dy[IX(a, tr)] -= Ft;
        dy[IX(b, tr)] += Ft;
      }
    }

    // prescribed emissions
    const double cveg = y[IX(iveg, C)] > 1e-30 ? y[IX(iveg, C)] : 1e-30;
    add_source(iatm, f[hi], A.d13c_foss, -1000.0);
    add_source(iatm, f[2 + hi], A.d13c_bio,
               1000.0 * (y[IX(iveg, C14)] / cveg - 1.0));
  }

  // interhemispheric, gross both ways
  add_flux(0, 14, y[IX(0, C)] / P.tau_ex, 1.0);
  add_flux(14, 0, y[IX(14, C)] / P.tau_ex, 1.0);

  // 14C sources and decay
  const double c14_to_state = 1.0 / (A.mol_per_GtC * A.R14STD);
  dy[IX(0, C14)]  += (f[6] * A.bomb_share_NH + f[7] * A.nuc_share_NH
                      + f[8] * 0.5) * c14_to_state;
  dy[IX(14, C14)] += (f[6] * (1.0 - A.bomb_share_NH) + f[7] * (1.0 - A.nuc_share_NH)
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
  A.d13c_foss = a["d13c_foss"]; A.d13c_bio = a["d13c_bio"];
  A.bomb_share_NH = a["bomb_share_NH"]; A.nuc_share_NH = a["nuc_share_NH"];
  A.R13 = a["R13"]; A.R14STD = a["R14STD"]; A.lambda = a["lambda"]; A.alk = a["alk"];
  v = a["cK0"]; for (int i = 0; i < 7; ++i) A.cK0[i] = v[i];
  v = a["cK1"]; for (int i = 0; i < 7; ++i) A.cK1[i] = v[i];
  v = a["cK2"]; for (int i = 0; i < 7; ++i) A.cK2[i] = v[i];
  v = a["cKb"]; for (int i = 0; i < 7; ++i) A.cKb[i] = v[i];
  v = a["cKw"]; for (int i = 0; i < 7; ++i) A.cKw[i] = v[i];
  A.t_centre = a["t_centre"]; A.t_scale = a["t_scale"]; A.boron = a["boron"];
  A.carb_iter = a["carb_iter"];
  return A;
}

static Par unpack_par(const List& p) {
  Par P;
  P.beta = p["beta"]; P.q10 = p["q10"];
  P.tau_veg = p["tau_veg"]; P.tau_soil = p["tau_soil"];
  P.k_w = p["k_w"]; P.kz = p["kz"]; P.tau_ex = p["tau_ex"];
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
// forcing is an n x 9 matrix, one row per month, columns in the order given in
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
  NumericMatrix out(n, 11);
  const double gpp = A.gtc_per_ppm_hemi;

  std::vector<double> f(9);
  for (int i = 0; i < n; ++i) {
    out(i, 0) = y[IX(0, C)] / gpp;
    out(i, 1) = y[IX(14, C)] / gpp;
    out(i, 2) = 1000.0 * (y[IX(0, C13)] / (y[IX(0, C)] * A.R13) - 1.0);
    out(i, 3) = 1000.0 * (y[IX(14, C13)] / (y[IX(14, C)] * A.R13) - 1.0);
    out(i, 4) = 1000.0 * (y[IX(0, C14)] / y[IX(0, C)] - 1.0);
    out(i, 5) = 1000.0 * (y[IX(14, C14)] / y[IX(14, C)] - 1.0);
    double oc = 0.0, ld = 0.0, oc14 = 0.0, ld14 = 0.0, at14 = 0.0;
    for (int hi = 0; hi < 2; ++hi) {
      const int base = hi * 14;
      ld += y[IX(base + 1, C)] + y[IX(base + 2, C)];
      for (int kk = 3; kk < 14; ++kk) oc += y[IX(base + kk, C)];
      at14 += y[IX(base, C14)];
      ld14 += y[IX(base + 1, C14)] + y[IX(base + 2, C14)];
      for (int kk = 3; kk < 14; ++kk) oc14 += y[IX(base + kk, C14)];
    }
    out(i, 6) = oc; out(i, 7) = ld;
    out(i, 8) = oc14; out(i, 9) = ld14; out(i, 10) = at14;

    for (int j = 0; j < 9; ++j) f[j] = forcing(i, j);

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
