# =====================================================================
# WHERE IN TIME DOES RULING 4's -92.7 ACCUMULATE?  (2026-09-09e)
#
# Marcus, after the rep sensitivity showed the penalty survives widening the
# bomb-window sigma: the SH carries -69.5 of the -92.7 and the de-biasing acts
# through the PRE-1963 dump. If that cost is charged in years where the SH bomb
# signal is near baseline -- where neither compilation has much to say -- it is
# being levied on the least-observed part of the record, and that bears on how
# much weight it deserves.
#
# ⛔ THIS DECIDES NOTHING. It localizes a cost in time. Nothing is adopted.
#
# METHOD. Per-YEAR loglik contributions to d14c_NH / d14c_SH under both forcing
# arms, reconstructed exactly as R/likelihood.R scores them (annual observation
# mean vs the model's OWN annual mean, sd = sqrt(o$sd^2 + sigma_d14c^2)), with a
# SELF-CHECK pinning the per-year sum to ccx_loglik()'s own by_stream total --
# without it this is a second copy of an estimator and could drift silently.
#
# ⚠ Forcing swapped per arm under tryCatch(finally=) + an md5 restore assertion
# [[rscript_top_level_on_exit]].
# Usage: CCX_PRE_BOMB=<pre-de-biasing product> CCX_LIVE_BACKUP=<backup> \
#        Rscript calibration/diag_debias_penalty_by_year.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

PY_LIVE  <- ccx_path("data", "forcing_bomb_c14.rds")
PY_PRE   <- Sys.getenv("CCX_PRE_BOMB", "")
PY_BACK  <- Sys.getenv("CCX_LIVE_BACKUP", "")
PY_ERAS  <- list("pre-1955"     = c(1900, 1954),
                 "1955-62 (pre-dump)" = c(1955, 1962),
                 "1963-65 (peak)"     = c(1963, 1965),
                 "1966-70"            = c(1966, 1970),
                 "post-1970"          = c(1971, 2100))
PY_TOPN  <- 8
PY_OUT   <- ccx_path("outputs", "diagnostics",
                     sprintf("debias_penalty_by_year_%s.rds", format(Sys.Date(), "%Y%m%d")))
stopifnot(nzchar(PY_PRE), file.exists(PY_PRE), nzchar(PY_BACK), file.exists(PY_BACK))

md5 <- function(p) as.character(tools::md5sum(p))
md0 <- md5(PY_LIVE)
v   <- dg_vector(CCX_MODE_CANONICAL)
err <- list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
            grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c)
obs <- ccx_prepare_obs()

#' Per-year loglik for one hemisphere, EXACTLY as R/likelihood.R scores it.
per_year <- function(out, hh) {
  o  <- if (hh == "NH") obs$d14_nh_ann else obs$d14_sh_ann
  m  <- ccx_model_stats(out, obs)$d14[[hh]]
  k  <- match(o$year, m$year); good <- !is.na(k)
  sd <- sqrt(o$sd[good]^2 + err$sigma_d14c^2)
  data.frame(year = o$year[good], obs = o$value[good], mod = m$mean[k[good]],
             sd = sd, z = (o$value[good] - m$mean[k[good]]) / sd,
             ll = stats::dnorm(o$value[good], m$mean[k[good]], sd, log = TRUE))
}

RUNS <- list()
tryCatch({
  RUNS$post <- dg_run(v)
  stopifnot(file.copy(PY_PRE, PY_LIVE, overwrite = TRUE))
  RUNS$pre  <- dg_run(v)
}, finally = {
  if (!identical(md5(PY_LIVE), md0)) file.copy(PY_BACK, PY_LIVE, overwrite = TRUE)
  stopifnot(identical(md5(PY_LIVE), md0))
  cat("restore verified (md5 matches the file this script started with)\n\n")
})

PYR <- list()
for (a in names(RUNS)) {
  r  <- RUNS[[a]]
  st <- unlist(ccx_loglik(r$out, obs, err, luc = ccx_forcing_eluc_annual(r$F),
                          deep = r$sp$diagnostics$d14c_bottom_box,
                          ocean_grad = ccx_ocean_grad_scored(r$out, r$sp),
                          by_stream = TRUE, d14c_mid = ccx_model_d14c_slabs(r$sp)))
  PYR[[a]] <- lapply(c(NH = "NH", SH = "SH"), function(h) per_year(r$out, h))
  # ⭐ SELF-CHECK: the per-year sum MUST equal the objective's own stream total.
  for (h in c("NH", "SH"))
    stopifnot(isTRUE(all.equal(sum(PYR[[a]][[h]]$ll),
                               unname(st[[paste0("d14c_", h)]]), tolerance = 1e-8)))
}
cat("self-check PASSED: per-year sums reproduce ccx_loglik()'s d14c_NH / d14c_SH exactly\n\n")

cat(sprintf("mode %s; sigma_d14c %.2f; LIK_D14C_REP_BOMB %g over %d-%d\n\n",
            CCX_MODE_CANONICAL, v$sigma_d14c, LIK_D14C_REP_BOMB,
            LIK_D14C_BOMB_WIN[1], LIK_D14C_BOMB_WIN[2]))
D <- lapply(c(NH = "NH", SH = "SH"), function(h) {
  a <- PYR$post[[h]]; b <- PYR$pre[[h]]
  stopifnot(identical(a$year, b$year))
  data.frame(year = a$year, d = a$ll - b$ll, sd = a$sd,
             obs = a$obs, z_pre = b$z, z_post = a$z)
})

cat("=== WHERE THE COST FALLS, by era (post - pre, log-units) ===\n")
cat(sprintf("%-20s %10s %10s %10s   %s\n", "era", "NH", "SH", "both", "obs SH D14C range (permil)"))
ERA <- list()
for (nm in names(PY_ERAS)) {
  w <- PY_ERAS[[nm]]
  kn <- D$NH$year >= w[1] & D$NH$year <= w[2]
  ks <- D$SH$year >= w[1] & D$SH$year <= w[2]
  if (!any(ks)) next
  ERA[[nm]] <- c(NH = sum(D$NH$d[kn]), SH = sum(D$SH$d[ks]))
  cat(sprintf("%-20s %10.2f %10.2f %10.2f   %+.0f to %+.0f\n", nm,
              sum(D$NH$d[kn]), sum(D$SH$d[ks]), sum(D$NH$d[kn]) + sum(D$SH$d[ks]),
              min(D$SH$obs[ks]), max(D$SH$obs[ks])))
}
cat(sprintf("%-20s %10.2f %10.2f %10.2f\n", "TOTAL",
            sum(D$NH$d), sum(D$SH$d), sum(D$NH$d) + sum(D$SH$d)))

for (h in c("NH", "SH")) {
  cat(sprintf("\n=== %s: the %d worst individual years ===\n", h, PY_TOPN))
  x <- D[[h]][order(D[[h]]$d), ][seq_len(PY_TOPN), ]
  cat(sprintf("%6s %9s %8s %9s %9s   %s\n", "year", "delta", "obs", "z pre", "z post", "in bomb window?"))
  for (i in seq_len(nrow(x)))
    cat(sprintf("%6d %9.2f %8.0f %+9.2f %+9.2f   %s\n", x$year[i], x$d[i], x$obs[i],
                x$z_pre[i], x$z_post[i],
                if (x$year[i] >= LIK_D14C_BOMB_WIN[1] & x$year[i] <= LIK_D14C_BOMB_WIN[2])
                  sprintf("YES (sd %.1f)", x$sd[i]) else sprintf("no  (sd %.1f)", x$sd[i])))
}
saveRDS(list(by_year = D, per_arm = PYR, era = ERA, eras = PY_ERAS,
             mode = CCX_MODE_CANONICAL, date = Sys.time()), PY_OUT)
cat(sprintf("\nsaved %s\n⛔ Nothing adopted; this localises a cost, it does not judge one.\n", PY_OUT))
