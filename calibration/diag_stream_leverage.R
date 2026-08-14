# =====================================================================
# probe_stream_leverage.R -- how many log-units can each observational
# stream actually move, per parameter?
#
# The review question (13-step-back sec.2a): "a stream that cannot outvote
# noise in another stream is not a constraint." That is a statement about
# LEVERAGE (d logL / d theta), not about a stream's logL LEVEL, which is
# what the inventory table lists. This measures leverage.
#
# METHOD, and it is a choice that must be stated: each parameter is
# perturbed by +/- ONE PRIOR SD (log-scale for lognormal priors, 10 % of
# range for uniform ones, since a uniform prior has no sd worth using).
# The metric is then "log-units a stream moves when a parameter moves by
# one prior sd" -- i.e. leverage measured in the units the sampler
# actually proposes in. It is NOT a Hessian; it is a symmetric finite
# difference of the LEVEL, so a stream sitting at its own optimum shows
# small numbers by construction. Both signed halves are reported.
#
# The GCB land-sink term is scored BOTH as shipped and CORRECTED
# (mod_ld + E_LUC), because the shipped one compares net to gross.
# =====================================================================


for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PL_YEARS    <- c(1750, 2024)
PL_BOMB_REF <- 102

obs <- ccx_prepare_obs()
base_forcing <- ccx_build_forcing("historical", PL_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = PL_BOMB_REF)

pd <- ccx_default_params()

pl_run <- function(p) {
  s <- ccx_spinup(p)
  F <- base_forcing
  F$c14_cosmo <- s$prod_c14
  if (!is.null(p$bomb_total))
    F$c14_bomb <- F$c14_bomb * (p$bomb_total / PL_BOMB_REF)
  ccx_run_fast(s, F)$out
}

# E_LUC, annual, to build the corrected gross land sink
PL_ELUC <- local({
  em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  stats::setNames(em$luc_GtC, em$year)
})

# the corrected gcb_land_sink term, recomputed outside ccx_loglik
pl_land_term <- function(out) {
  yr  <- floor(out$t + 1e-9)
  ann <- stats::aggregate(cbind(land_C) ~ yr, data = out, FUN = mean)
  ann <- ann[order(ann$yr), ]
  g   <- merge(as.data.frame(obs$gcb)[, c("year", "land_sink")], ann,
               by.x = "year", by.y = "yr")
  g   <- g[order(g$year), ]
  net <- c(NA, diff(g$land_C))
  el  <- PL_ELUC[as.character(g$year)]
  k   <- !is.na(net) & !is.na(el)
  sdv <- LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE
  c(shipped   = sum(stats::dnorm(g$land_sink[k], net[k], sdv, log = TRUE)),
    corrected = sum(stats::dnorm(g$land_sink[k], net[k] + el[k], sdv, log = TRUE)))
}

pl_score <- function(p) {
  out <- pl_run(p)
  err <- list(sigma_co2 = p$sigma_co2, sigma_d13c = p$sigma_d13c,
              sigma_d14c = p$sigma_d14c)
  s <- ccx_loglik(out, obs, err, by_stream = TRUE)
  lt <- pl_land_term(out)
  s[["gcb_land_sink_CORRECTED"]] <- lt[["corrected"]]
  s
}

# ---- error-model defaults: the table's init, since ccx_default_params()
# may not carry them ---------------------------------------------------
for (nm in c("sigma_co2", "sigma_d13c", "sigma_d14c", "bomb_total", "gamma_enso"))
  if (is.null(pd[[nm]])) pd[[nm]] <- CCX_PARAM_TABLE[[nm]]$init

# ---- perturbation set: one prior sd, or 10 % of a uniform range ------
PL_PERT <- list(
  beta          = list(kind = "abs", d = 0.15),
  q10           = list(kind = "rel", d = 0.25),
  k_w           = list(kind = "rel", d = 0.40),
  h_ml          = list(kind = "abs", d = 17),
  kz            = list(kind = "abs", d = 237),
  tau_ex        = list(kind = "rel", d = 0.25),
  npp_frac_NH   = list(kind = "abs", d = 0.04),
  seas_amp_NH   = list(kind = "rel", d = 0.60),
  seas_amp_SH   = list(kind = "rel", d = 0.80),
  seas_phase_NH = list(kind = "abs", d = 1.2),
  seas_phase_SH = list(kind = "abs", d = 1.2),
  gamma_enso    = list(kind = "abs", d = 2.0),
  bomb_total    = list(kind = "rel", d = 0.10),
  sigma_co2     = list(kind = "rel", d = 0.70),
  sigma_d13c    = list(kind = "rel", d = 0.70),
  sigma_d14c    = list(kind = "rel", d = 0.70)
)

base <- pl_score(pd)
cat("\n== base logL by stream, at ccx_default_params() ==\n")
print(round(base, 1))
cat(sprintf("\nTOTAL (as shipped, excl. the CORRECTED duplicate) = %.1f\n",
            sum(base[names(base) != "gcb_land_sink_CORRECTED"])))

res <- list()
for (nm in names(PL_PERT)) {
  if (is.null(pd[[nm]])) { cat(sprintf("SKIP %s -- not in default params\n", nm)); next }
  s <- PL_PERT[[nm]]
  v0 <- pd[[nm]]
  vhi <- if (s$kind == "rel") v0 * exp(s$d) else v0 + s$d
  vlo <- if (s$kind == "rel") v0 * exp(-s$d) else v0 - s$d
  phi <- pd; phi[[nm]] <- vhi
  plo <- pd; plo[[nm]] <- vlo
  shi <- tryCatch(pl_score(phi), error = function(e) {cat("ERR hi", nm, conditionMessage(e), "\n"); NULL})
  slo <- tryCatch(pl_score(plo), error = function(e) {cat("ERR lo", nm, conditionMessage(e), "\n"); NULL})
  if (is.null(shi) || is.null(slo)) next
  res[[nm]] <- list(v0 = v0, lo = vlo, hi = vhi,
                    dhi = shi - base, dlo = slo - base)
  cat(sprintf("done %-14s %.4g -> [%.4g, %.4g]\n", nm, v0, vlo, vhi))
}

# ---- the leverage matrix: max |delta| over the two half-steps --------
streams <- names(base)
M <- sapply(res, function(r) pmax(abs(r$dhi), abs(r$dlo))[streams])
rownames(M) <- streams
cat("\n\n== LEVERAGE: max |delta logL| per stream per one-prior-sd step ==\n")
print(round(M, 1))

cat("\n\n== the same, as a PERCENT of the column total (who decides each parameter) ==\n")
P <- sweep(M, 2, colSums(M), "/") * 100
print(round(P, 1))

cat("\n\n== signed, high side only (positive = stream PREFERS the higher value) ==\n")
S <- sapply(res, function(r) r$dhi[streams]); rownames(S) <- streams
print(round(S, 1))

saveRDS(list(base = base, res = res, M = M, pert = PL_PERT,
             params = pd[names(PL_PERT)]),
        ccx_path("calibration", "output", "stream_leverage.rds"))
cat("\nsaved\n")
