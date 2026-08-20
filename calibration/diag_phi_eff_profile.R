# =====================================================================
# diag_phi_eff_profile.R -- PROFILE CCX_SEAS_PHI_EFF, WITH THE SEASONAL
#                           BLOCK RE-OPTIMISED AT EVERY CANDIDATE
#
# THE SUSPECT, from handoff 2026-08-20d section 6. CCX_SEAS_PHI_EFF["NH"] = 75
# deg is documented as a "flux-weighted effective" latitude but was fitted
# OFFLINE against MLO under the pre-08-18 sine respiration -- against a model
# that no longer exists. diag_npp_eff_latitude.R has now MEASURED the quantity
# it claims to be, from MOD17: 38.35 N for the NH, -15.75 for the SH, and the
# shipped values over-drive the NEP seasonal SHAPE by 2.81x (NH) and 2.03x (SH)
# in peak-to-peak. That is the size of the over-driving hypothesis; this script
# asks what the DATA say about it.
#
# WHY THE BLOCK IS RE-OPTIMISED, AND WHY A FROZEN PROFILE WOULD BE WORTHLESS
# HERE. The channel budget found NEP and soil respiration each about 2x the net
# seasonal cycle and 6.6 months ANTIPHASE: they cancel, and seas_T_amp_NH = 48 K
# is what buys the cancellation. Moving phi_eff while holding seas_T_amp_NH
# fixed therefore breaks the cancellation by construction and would lose
# whatever the truth is -- the incumbent's home ground in its purest form
# (match_incumbents_optim). So at every candidate phi the seven parameters the
# seasonal cycle actually identifies are RE-OPTIMISED on the full log-posterior:
#     seas_T_amp_{NH,SH}  the respiration channel -- the cancellation partner
#     seas_lag_p          phenology lag; absorbs any phase shift phi implies
#     sst_seas_amp_{NH,SH} the ocean channel
#     npp_frac_NH         multiplies the NEP amplitude directly
#     q10                 the nonlinear part of the respiration response
# Both tiers are reported: FROZEN (mode, one evaluation) and REOPT. The gap
# between them at the SHIPPED phi is the size of the home-ground advantage, and
# it is printed rather than assumed.
#
# THE OBJECTIVE IS THE POST-08-20g ONE -- the re-anchored seasonal priors from
# handoff 20d section 4b. So the arm-N mode is NOT at its optimum here either:
# it scores -2811.2 under these priors against a stored -2682.6 under the old
# ones, and re-optimising the block at the SHIPPED phi already gains ~+229.
# Every number below is therefore internally comparable and NOT comparable with
# anything from before 08-20g. This is a piece of the refit that section 4 owes,
# restricted to one block -- it is NOT that refit.
#
# h_ml IS DECODED UNDER THE DEFAULT [30, 200] BAND, not the [85, 120] the refit
# overrode in-process (ccx_hml_band_provenance). par_mode is band-independent so
# the PARAMETER is right; only h_ml's prior term differs, it is held fixed in
# every case, and it therefore cancels out of every difference reported here.
# Do not compare these absolute logposts with the arm files'.
#
# phi_eff IS COMPILE-TIME with a hardcoded twin SEAS_PHI_EFF in
# src/ccx_core.cpp, so each candidate is patched + rebuilt + run in its OWN
# tempdir() copy, never the working tree. The worker gates the patch THREE ways:
# the R constant, a grep of the C++ source, and -- the only one that can see
# what was actually COMPILED -- the R-vs-C++ derivative parity check, which
# disagrees at O(1) if the two cores are carrying different latitudes.
#
# THE FIRST PASS PROFILED NH AT THE SHIPPED SH AND FOUND AN INTERACTION, so the
# script takes an explicit case list for follow-up passes:
#   Rscript calibration/diag_phi_eff_profile.R "45,-15.75;50,-15.75" 2d
# A case may carry two more numbers, the per-hemisphere NEP amplitude factors
# `seas_npp_amp_{NH,SH}` (default 1 = the shipped model):
#   "75,-15.75,0.49,1"  -- the shipped SHAPE with its amplitude halved, which is
# what diag_seas_rectification.R measures the observed shape to want. Those two
# are NOT re-optimised: the point of the case is to score a MEASURED pair.
# writes calibration/output/phi_eff_profile_2d.rds. With no arguments it runs
# the default grid and writes phi_eff_profile.rds. Both are read and merged by
# the report at the end of this file, so passes accumulate rather than replace.
#
# Usage:  Rscript calibration/diag_phi_eff_profile.R [cases] [tag]
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

PE_MODE_FILE <- file.path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
PE_ARGS      <- commandArgs(TRUE)
PE_TAG       <- if (length(PE_ARGS) >= 2) PE_ARGS[2] else ""
PE_OUT       <- file.path("calibration", "output",
                          sprintf("phi_eff_profile%s.rds",
                                  if (nzchar(PE_TAG)) paste0("_", PE_TAG) else ""))
PE_NPP       <- file.path("data", "obs_npp_hemispheric.rds")
# MEASURED, by calibration/diag_npp_eff_latitude.R. Typed here because that
# script writes no product; if it is re-run and moves, these move with it.
PE_PHI_MEAS  <- c(NH = 38.35, SH = -15.75)
PE_PHI_SHIP  <- c(NH = CCX_SEAS_PHI_EFF[["NH"]], SH = CCX_SEAS_PHI_EFF[["SH"]])
# NH profile at the shipped SH, then the SH corners. The grid brackets both the
# measured and the shipped value with room on each side, so an optimum at an
# endpoint is visible as one.
PE_GRID_NH   <- c(25, 32, PE_PHI_MEAS[["NH"]], 45, 55, 65, PE_PHI_SHIP[["NH"]], 85)
PE_EXTRA     <- list(c(PE_PHI_SHIP[["NH"]], PE_PHI_MEAS[["SH"]]),
                     c(PE_PHI_MEAS[["NH"]], PE_PHI_MEAS[["SH"]]))
PE_BLOCK     <- c("seas_T_amp_NH", "seas_T_amp_SH", "seas_lag_p",
                  "sst_seas_amp_NH", "sst_seas_amp_SH", "npp_frac_NH", "q10")
PE_NM_MAXIT  <- 1200      # per restart
PE_NM_TRIES  <- 3         # restarts; stops early when a restart gains < PE_NM_TOL
PE_NM_TOL    <- 2.0       # log-units; the phi differences of interest are ~1e2
PE_WORKERS   <- 4         # = performance cores on this machine

# The observed seasonal amplitudes the re-optimised block is COMPARED against
# (never fitted to directly -- they enter only through the priors re-anchored in
# 08-20g). Read from the climatology product, not typed.
sc <- readRDS(ccx_path("data", "obs_seasonal_clim.rds"))
wk <- sprintf("%%s_%d-%d", sc$sst_window[1], sc$sst_window[2])
PE_OBS <- c(seas_T_amp_NH   = sc$land[["NH_all"]]$half_amp,
            seas_T_amp_SH   = sc$land[["SH_all"]]$half_amp,
            sst_seas_amp_NH = sc$ocean[[sprintf(wk, "NH")]]$half_amp,
            sst_seas_amp_SH = sc$ocean[[sprintf(wk, "SH")]]$half_amp,
            npp_frac_NH     = readRDS(ccx_path(PE_NPP))$nh_share_mean)

# ---------------------------------------------------------------------
# The worker
# ---------------------------------------------------------------------
WORKER <- c(
'for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)',
'ccx_load_cpp()',
'a <- commandArgs(TRUE)',
'phiN <- as.numeric(a[1]); phiS <- as.numeric(a[2])',
'maxit <- as.integer(a[3]); tries <- as.integer(a[4]); tol <- as.numeric(a[5])',
'BLK <- strsplit(a[6], ",")[[1]]',
'ampN <- as.numeric(a[7]); ampS <- as.numeric(a[8])',
'# GATE 1: the R constant.',
'stopifnot(abs(CCX_SEAS_PHI_EFF[["NH"]] - phiN) < 1e-9,',
'          abs(CCX_SEAS_PHI_EFF[["SH"]] - phiS) < 1e-9)',
'# GATE 2: the C++ SOURCE carries the same pair.',
'cc <- readLines(file.path("src", "ccx_core.cpp"))',
'stopifnot(any(grepl(sprintf("SEAS_PHI_EFF[2] = { %s, %s };", phiN, phiS), cc, fixed = TRUE)))',
'md <- readRDS(file.path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds"))',
'bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode',
'p <- bp; for (n in names(md$par_mode)) p[[n]] <- md$par_mode[[n]]',
'# The NEP amplitude factors are NOT fitted parameters, so they ride in',
'# base_params, which ccx_make_logpost() copies and the fitted names overwrite.',
'bp$seas_npp_amp_NH <- ampN; bp$seas_npp_amp_SH <- ampS',
'p$seas_npp_amp_NH  <- ampN; p$seas_npp_amp_SH  <- ampS',
'# GATE 3: R vs C++ derivative parity. This is the ONLY gate that sees the',
'# COMPILED object -- the R core reads CCX_SEAS_PHI_EFF, the C++ core its own',
'# literal, so a patch that took on one side only shows up here at O(1).',
'sp <- ccx_spinup(p)',
'fc <- list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),',
'           cum_luc = list(NH = 120, SH = 80), gmst = 1.1, enso = 0.7,',
'           c14_bomb = 1200, c14_nuclear = 40, c14_cosmo = sp$prod_c14, d13c_foss = -27.6)',
'dR <- ccx_deriv(sp$y, 1980.5, p, fc, sp$grid, sp$aux)',
'dC <- ccx_deriv_fast(sp$y, 1980.5, p, fc, sp$grid, sp$aux)',
'stopifnot(max(abs(dR - dC)) / max(abs(dR)) < 1e-12)',
'',
'lp <- ccx_make_logpost(base_params = bp)',
'u0 <- ccx_par_to_unc(md$par_mode)',
'i  <- match(BLK, CCX_PARAM_NAMES)',
'frozen <- lp(u0)',
'f <- function(x) { u <- u0; u[i] <- x; v <- -lp(u); if (!is.finite(v)) 1e12 else v }',
'x <- u0[i]; best <- frozen; nev <- 0; gains <- numeric(0); conv <- NA',
'# Nelder-Mead RESTARTED from its own optimum: a simplex that has collapsed',
'# stops making progress long before the point is stationary, and one run of it',
'# reports convergence = 1 (maxit) here. The per-restart GAINS are recorded so',
'# the reader can see how converged each case actually is rather than trust it.',
'for (k in seq_len(tries)) {',
'  o <- optim(x, f, method = "Nelder-Mead", control = list(maxit = maxit, reltol = 1e-9))',
'  nev <- nev + o$counts[1]; gain <- (-o$value) - best; conv <- o$convergence',
'  x <- o$par; best <- -o$value; gains <- c(gains, gain)',
'  if (gain < tol) break',
'}',
'u1 <- u0; u1[i] <- x; p1 <- ccx_unc_to_par(u1)',
'# Diagnostics at the re-optimised point: seasonal amplitudes and the d13C-per-',
'# ppm signature, because amplitude alone has misled twice in this arc.',
'q <- bp; for (n in CCX_PARAM_NAMES) q[[n]] <- p1[[n]]',
'stopifnot(identical(q$seas_npp_amp_NH, ampN), identical(q$seas_npp_amp_SH, ampS))',
'sp1 <- ccx_spinup(q)',
'F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)',
'F$c14_cosmo <- sp1$prod_c14; F$c14_bomb <- F$c14_bomb * (p1$bomb_total / 102)',
'for (z in c("e_luc_NH","e_luc_SH","cum_luc_NH","cum_luc_SH")) F[[z]] <- F[[z]] * p1$luc_scale',
'attr(F, "luc_scale") <- p1$luc_scale',
'el <- ccx_forcing_eluc_annual(F); el$eluc <- el$eluc * p1$luc_scale',
'r <- ccx_run_fast(sp1, F)',
'bs <- ccx_loglik(r$out, ccx_prepare_obs(),',
'      list(sigma_d14c = p1$sigma_d14c, rep_dC = p1$rep_dC,',
'           grad_off_co2 = p1$grad_off_co2, grad_off_d13c = p1$grad_off_d13c),',
'      luc = el, deep = sp1$diagnostics$d14c_bottom_box,',
'      ocean_grad = ccx_ocean_grad_scored(r$out, sp1), by_stream = TRUE)',
'ms <- ccx_model_stats(r$out, ccx_prepare_obs())',
'amp <- function(z) 2 * sqrt(mean(z$a)^2 + mean(z$b)^2)',
'sq <- c("co2_seasonal_MLO","co2_seasonal_SPO","d13c_seasonal_MLO","d13c_seasonal_SPO")',
'saveRDS(list(phi = c(NH = phiN, SH = phiS), amp = c(NH = ampN, SH = ampS),',
'             frozen = frozen, reopt = best,',
'             n_eval = nev, gains = gains, conv = conv,',
'             par = p1[BLK], by_stream = bs, seas = sum(unlist(bs[sq])),',
'             p2p = c(MLO = amp(ms$co2_seas$MLO), SPO = amp(ms$co2_seas$SPO)),',
'             sig = c(MLO = amp(ms$d13_seas$MLO) / amp(ms$co2_seas$MLO),',
'                     SPO = amp(ms$d13_seas$SPO) / amp(ms$co2_seas$SPO))),',
'        "case.rds")',
'cat("DONE\\n")')

# ---------------------------------------------------------------------
# Set up one tempdir per case, patch both cores, run
# ---------------------------------------------------------------------
root  <- ccx_root()
cases <- if (length(PE_ARGS) >= 1 && nzchar(PE_ARGS[1])) {
  lapply(strsplit(strsplit(PE_ARGS[1], ";")[[1]], ","), as.numeric)
} else {
  c(lapply(PE_GRID_NH, function(x) c(x, PE_PHI_SHIP[["SH"]])), PE_EXTRA)
}
# A case is (phiNH, phiSH) or (phiNH, phiSH, ampNH, ampSH); pad the short form.
cases <- lapply(cases, function(z) if (length(z) == 2L) c(z, 1, 1) else z)
stopifnot(all(vapply(cases, length, integer(1)) == 4L),
          !any(vapply(cases, anyNA, logical(1))))
cases <- cases[!duplicated(vapply(cases, paste, character(1), collapse = "_"))]

setup <- function(idx, phi) {
  work <- file.path(tempdir(), sprintf("phi_%02d", idx))
  unlink(work, recursive = TRUE)
  dir.create(file.path(work, dirname(PE_MODE_FILE)), recursive = TRUE, showWarnings = FALSE)
  for (d in c("R", "src", "data")) file.copy(file.path(root, d), work, recursive = TRUE)
  file.copy(file.path(root, "DESIGN.md"), work)
  file.copy(file.path(root, PE_MODE_FILE), file.path(work, PE_MODE_FILE))
  m <- readLines(file.path(work, "R", "model.R"))
  m <- sub("^CCX_SEAS_PHI_EFF <- c\\(NH = [-0-9.]+, SH = [-0-9.]+\\)",
           sprintf("CCX_SEAS_PHI_EFF <- c(NH = %s, SH = %s)", phi[1], phi[2]), m)
  writeLines(m, file.path(work, "R", "model.R"))
  cc <- readLines(file.path(work, "src", "ccx_core.cpp"))
  cc <- sub("^static const double SEAS_PHI_EFF\\[2\\] = \\{ [-0-9.]+, [-0-9.]+ \\};",
            sprintf("static const double SEAS_PHI_EFF[2] = { %s, %s };", phi[1], phi[2]), cc)
  writeLines(cc, file.path(work, "src", "ccx_core.cpp"))
  # Fail HERE, in the parent, if either substitution missed -- a worker that
  # silently ran the incumbent's constants under a challenger's label is the
  # worst failure available (diag_seas_obs_drivers.R's lesson).
  stopifnot(any(grepl(sprintf("CCX_SEAS_PHI_EFF <- c(NH = %s, SH = %s)", phi[1], phi[2]),
                      m, fixed = TRUE)),
            any(grepl(sprintf("SEAS_PHI_EFF[2] = { %s, %s };", phi[1], phi[2]),
                      cc, fixed = TRUE)))
  writeLines(WORKER, file.path(work, "one_case.R"))
  work
}

run_one <- function(idx) {
  phi  <- cases[[idx]]
  work <- setup(idx, phi)
  owd  <- setwd(work); on.exit(setwd(owd))
  o <- suppressWarnings(system2("Rscript",
        c("one_case.R", phi[1], phi[2], PE_NM_MAXIT, PE_NM_TRIES, PE_NM_TOL,
          paste(PE_BLOCK, collapse = ","), phi[3], phi[4]),
        stdout = TRUE, stderr = TRUE,
        env = c("OMP_NUM_THREADS=1", "OPENBLAS_NUM_THREADS=1", "VECLIB_MAXIMUM_THREADS=1")))
  if (!file.exists("case.rds")) {
    cat(sprintf("\n*** phi (%s, %s) FAILED:\n%s\n", phi[1], phi[2],
                paste0("    ", utils::tail(o, 12), collapse = "\n")))
    return(NULL)
  }
  readRDS("case.rds")
}

cat(sprintf("phi_eff profile: %d cases, %d workers, block = %s\n",
            length(cases), PE_WORKERS, paste(PE_BLOCK, collapse = " ")))
cat(sprintf("shipped (%.2f, %.2f) | measured from MOD17 (%.2f, %.2f)\n",
            PE_PHI_SHIP[["NH"]], PE_PHI_SHIP[["SH"]], PE_PHI_MEAS[["NH"]], PE_PHI_MEAS[["SH"]]))
cat("each case: patch both cores, rebuild, 3 gates, then Nelder-Mead restarts\n\n")

t0 <- Sys.time()
res <- parallel::mclapply(seq_along(cases), run_one, mc.cores = PE_WORKERS)
cat(sprintf("%.1f minutes\n\n", as.numeric(Sys.time() - t0, units = "mins")))
ok <- !vapply(res, is.null, logical(1))
res <- res[ok]
saveRDS(list(cases = cases[ok], res = res, block = PE_BLOCK, obs = PE_OBS,
             phi_measured = PE_PHI_MEAS, phi_shipped = PE_PHI_SHIP),
        ccx_path(PE_OUT))

# ---------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------
# MERGE EVERY PASS. A follow-up pass fills in part of the (NH, SH) plane and
# would otherwise be read on its own, which is how a 1D slice of a surface with
# an interaction gets mistaken for the surface.
for (f in list.files(ccx_path("calibration", "output"), pattern = "^phi_eff_profile.*\\.rds$",
                     full.names = TRUE)) {
  if (normalizePath(f) == normalizePath(ccx_path(PE_OUT))) next
  prev <- readRDS(f)
  have <- vapply(res, function(x) paste(x$phi, collapse = "_"), character(1))
  for (x in prev$res) if (!paste(x$phi, collapse = "_") %in% have) res <- c(res, list(x))
}
ord  <- order(vapply(res, function(x) x$phi[["SH"]], numeric(1)),
              vapply(res, function(x) x$phi[["NH"]], numeric(1)))
res  <- res[ord]
best <- max(vapply(res, function(x) x$reopt, numeric(1)))
cat(sprintf("%-8s %-8s %6s %6s %11s %11s %11s %9s %9s %9s %9s\n",
            "phi NH", "phi SH", "ampNH", "ampSH", "frozen", "REOPT", "d(reopt)",
            "seas", "MLO p2p", "sig MLO", "sig SPO"))
for (x in res) {
  amp1 <- is.null(x$amp) || isTRUE(all.equal(unname(x$amp), c(1, 1)))
  tag <- if (amp1 && isTRUE(all.equal(unname(x$phi), unname(PE_PHI_SHIP)))) "  <- SHIPPED"
         else if (amp1 && isTRUE(all.equal(unname(x$phi), unname(PE_PHI_MEAS)))) "  <- MEASURED"
         else ""
  am <- if (is.null(x$amp)) c(NH = 1, SH = 1) else x$amp
  cat(sprintf("%-8.2f %-8.2f %6.2f %6.2f %11.1f %11.1f %11.2f %9.1f %9.3f %9.5f %9.5f%s\n",
              x$phi[["NH"]], x$phi[["SH"]], am[["NH"]], am[["SH"]],
              x$frozen, x$reopt, x$reopt - best,
              x$seas, x$p2p[["MLO"]], x$sig[["MLO"]], x$sig[["SPO"]], tag))
}
cat("\nobserved: MLO p2p 6.754, SPO 1.170; signatures 0.0528 (MLO) / 0.0288 (SPO)\n")
cat("\noptimiser convergence, per case (last restart's gain should be small):\n")
for (x in res)
  cat(sprintf("  phi (%6.2f,%7.2f) amp (%.2f,%.2f)  %5d evals, %d restarts, gains %s\n",
              x$phi[["NH"]], x$phi[["SH"]],
              if (is.null(x$amp)) 1 else x$amp[["NH"]], if (is.null(x$amp)) 1 else x$amp[["SH"]],
              x$n_eval, length(x$gains), paste(sprintf("%+.1f", x$gains), collapse = " ")))

cat("\n=== THE RE-OPTIMISED BLOCK, against what was MEASURED ===\n")
cat(sprintf("%-8s %-8s %s\n", "phi NH", "phi SH",
            paste(sprintf("%16s", PE_BLOCK), collapse = "")))
cat(sprintf("%-8s %-8s %s\n", "observed", "",
            paste(sprintf("%16s", vapply(PE_BLOCK, function(n)
              if (n %in% names(PE_OBS)) sprintf("%.4f", PE_OBS[[n]]) else "--",
              character(1))), collapse = "")))
for (x in res)
  cat(sprintf("%-8.2f %-8.2f %s\n", x$phi[["NH"]], x$phi[["SH"]],
              paste(sprintf("%16.4f", unlist(x$par[PE_BLOCK])), collapse = "")))
cat("\n(rows with a non-unit amp factor carry it in the table above; the block\n")
cat(" columns are the RE-OPTIMISED values in every row.)\n")
cat("\nThe question this table answers: does a LOWER phi_eff let the respiration\n")
cat("channel come back down toward its observed amplitude? seas_T_amp_NH at the\n")
cat("shipped phi is 48 K against an observed 11.45.\n")
cat(sprintf("\nwrote %s\n", PE_OUT))
