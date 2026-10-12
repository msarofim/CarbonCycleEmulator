source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/lib_ed.R")
OUT <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/out"
FIT_SPAN <- 1000                    # yr, Joos Eq. 11's own span
cat("commit:", ccx_git_stamp(), " mode:", CCX_MODE_CANONICAL, "\n")
v <- dg_vector(CCX_MODE_CANONICAL); spin <- dg_spinup(v)
o <- ed_pd100(v, spin, end_year = JOOS_PULSE_YR + FIT_SPAN + 10)
ann <- 0:FIT_SPAN
pick <- function(x) x[match(ann, round(o$t, 6))]
irf <- pick(o$irf); oc <- pick(o$d$ocean); ld <- pick(o$d$land)
stopifnot(!anyNA(irf), !anyNA(oc), !anyNA(ld))

# ---- WINDOWED DRAWDOWN: where the excess removal happens ----
W <- c(0, 1, 2, 5, 20, 100, 300)
cat("\n=== drawdown of the airborne fraction per window (start minus end) ===\n")
for (i in seq_len(length(W) - 1)) {
  a <- W[i]; b <- W[i + 1]
  dc <- ed_irf_at(o, a) - ed_irf_at(o, b); if (a == 0) dc <- 1 - ed_irf_at(o, b)
  dj <- joos_irf(a) - joos_irf(b)
  cat(sprintf("  %3g-%3g yr: CarboTope %.4f  Joos T5 %.4f  excess %+.4f | ocean gain CCX %.2f vs Joos %.2f, land gain CCX %.2f vs Joos %.2f GtC\n",
              a, b, dc, dj, dc - dj,
              ed_at(o, b, "ocean") - (if (a == 0) 0 else ed_at(o, a, "ocean")), ed_joos_fit("ocean", b) - ed_joos_fit("ocean", a),
              ed_at(o, b, "land") - (if (a == 0) 0 else ed_at(o, a, "land")), ed_joos_fit("land", b) - ed_joos_fit("land", a)))
}

# ---- TEST F: fit CarboTope's own series with Joos's Eq. 11 form (3 exponentials, 0-1000 yr) ----
# IRF: a0 + sum a_i = 1 ; ocean / land: a0 + sum a_i = 0 (Joos p. 2801). Objective: Joos's own error
# measure, the mean relative error over ANNUAL values (Table 5 caption), here on t = 1..1000.
fit3 <- function(y, sum_to, start_tau = c(400, 40, 4)) {
  t <- ann; k <- t >= 1
  model <- function(th) { tau <- exp(th[1:3]); a <- th[4:6]; a0 <- sum_to - sum(a)
    a0 + colSums(a * exp(-outer(1 / tau, t))) }
  obj <- function(th) mean(abs((y[k] - model(th)[k]) / y[k]))
  best <- NULL
  for (s in list(start_tau, c(300, 30, 1), c(500, 60, 0.5), c(200, 20, 2))) {
    a_start <- if (sum_to == 1) c(0.2, 0.25, 0.3) else -0.3 * rep(y[length(y)], 3)
    r <- optim(c(log(s), a_start), obj, method = "Nelder-Mead", control = list(maxit = 20000, reltol = 1e-12))
    r <- optim(r$par, obj, method = "BFGS", control = list(maxit = 2000))
    if (is.null(best) || r$value < best$value) best <- r
  }
  th <- best$par; tau <- exp(th[1:3]); a <- th[4:6]
  list(a0 = sum_to - sum(a), a = a, tau = tau, relerr = 100 * best$value, fitted = model(th))
}
show <- function(nm, f, raw, ref) {
  ordr <- order(-f$tau)
  cat(sprintf("\n  %s: a0 %.4g | a %s | tau %s | mean rel. error %.2f %%\n", nm, f$a0,
              paste(sprintf("%.4g", f$a[ordr]), collapse = " "), paste(sprintf("%.4g", f$tau[ordr]), collapse = " "), f$relerr))
  for (h in c(1, 2, 5, 20, 100)) { k <- which(ann == h)
    cat(sprintf("     t=%3d raw %.4f  own-fit %.4f  (fit-raw %+.4f)   Joos T5 fit %.4f\n", h, raw[k], f$fitted[k], f$fitted[k] - raw[k], ref(h))) }
}
cat("\n=== TEST F: Joos's Eq. 11 fit applied to CarboTope's own response ===\n")
fI <- fit3(irf, 1); show("IRF", fI, irf, joos_irf)
fO <- fit3(oc, 0);  show("Ocean (GtC)", fO, oc, function(h) ed_joos_fit("ocean", h))
fL <- fit3(ld, 0);  show("Land (GtC)", fL, ld, function(h) ed_joos_fit("land", h))
cat(sprintf("\n  Joos T5 for comparison: IRF tau %s; ocean tau %s; land tau %s\n",
            paste(JOOS_T5$tau, collapse = "/"), paste(ED_JOOS_T5$ocean$tau, collapse = "/"), paste(ED_JOOS_T5$land$tau, collapse = "/")))
cat(sprintf("  IRF at 1000 yr: CarboTope %.4f, Joos T5 %.4f ; ocean %.2f vs %.2f ; land %.2f vs %.2f\n",
            irf[ann == 1000], joos_irf(1000), oc[ann == 1000], ed_joos_fit("ocean", 1000), ld[ann == 1000], ed_joos_fit("land", 1000)))
saveRDS(list(fI = fI, fO = fO, fL = fL, irf = irf, oc = oc, ld = ld), file.path(OUT, "s5_fitform.rds"))
