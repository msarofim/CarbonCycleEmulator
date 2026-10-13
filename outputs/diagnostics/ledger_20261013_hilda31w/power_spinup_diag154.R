# Read-only: spinup-diagnostics:154's quantities at hilda29e and hilda31w, plus the seasonal d13C
# cycle of the orbit, to see where the orbit's start (the 'instant') sits on it.
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
for (m in c("hilda29e", "hilda31w")) {
  lm <- ccx_load_mode(m); p <- lm$p
  sp <- ccx_periodic_spinup(p, verbose = FALSE)
  aux <- sp$aux; gpph <- aux$gtc_per_ppm_hemi; R13 <- ccx_const("R13_VPDB")
  o <- ps_phi(sp$y, p, aux, sp$grid, ps_year_forcing(sp$prod_c14))$out
  w <- function(d, c) 1000 * (mean((1 + d / 1000) * R13 * c * gpph) / (mean(c) * gpph * R13) - 1)
  nh <- w(o$d13c_NH, o$co2_NH); sh <- w(o$d13c_SH, o$co2_SH)
  inst <- ccx_atm_delta_instant(sp$y, aux)
  # global monthly d13C (mass-weighted), its range, and month 1's departure from the annual mean
  g <- 1000 * (((1 + o$d13c_NH / 1000) * o$co2_NH + (1 + o$d13c_SH / 1000) * o$co2_SH) / (o$co2_NH + o$co2_SH) - 1)
  cat(sprintf("%s: |inst-pin| %.5f  |sh-nh| %.6f  ratio %.1f (test wants > 100)  global d13C seasonal range %.4f  month1-mean %+.5f  inst d14c-pin %+.4f\n",
              m, abs(inst[["d13c"]] - ccx_const("D13C_PI")), abs(sh - nh), abs(inst[["d13c"]] - ccx_const("D13C_PI")) / abs(sh - nh),
              diff(range(g)), g[1] - mean(g), inst[["d14c"]] - ccx_const("D14C_PI")))
  cat("  monthly global d13C - annual mean:", sprintf("%+.4f", g[1:12] - mean(g[1:12])), "\n")
}
