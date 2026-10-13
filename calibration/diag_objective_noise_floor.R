#!/usr/bin/env Rscript
# =====================================================================
# diag_objective_noise_floor.R -- THE OBJECTIVE's NUMERICAL NOISE FLOOR at objective #17's two basin optima
# (CHANGELOG 2026-10-07 a). Found at #17's landing: promote's GATE 4 re-evaluated id 10 (basin A) 1.78e-6 off its
# stored logpost, although the driver's own end-of-run check had reproduced it exactly; and fit_iav_module.R's
# base-reproduction gate (then a literal 1e-6) stopped the one-pass check at 1.7e-6. Neither was a defect of the point.
#   1. THE ROUND TRIP. The objective (promote's construction, verbatim) at the optimiser's own u_mode and at
#      ccx_par_to_unc(par_mode), the point promote's GATE 4 evaluates; and at u_mode twice (determinism).
#   2. THE FLOOR, and WHERE THE OPTIMUM SITS ON IT. 1e-12 single-name nudges of u at u_mode, and at NF_N_OFFSETS
#      nearby points the optimiser did not choose (u_mode + N(0, NF_OFFSET_SD^2), seeded). A floor the optimum merely
#      sits in scatters on BOTH sides; an optimum on the floor's upper tail moves DOWN under every nudge.
#   3. THE dg PATH (fit_iav_module.R's GATE 0): the base's stored rows through dg_vector() / dg_run() / dg_streams(),
#      and the same under 1e-12 nudges of h_ml.
#   4. THE 1e-5 GATE's POWER (IAV_REPRO_TOL, ruled 2026-10-07): the largest row move under relative moves of one name.
# The SOURCE of the floor (which iterative solve's stopping rule) is NOT identified here.
# Usage: Rscript calibration/diag_objective_noise_floor.R
# OUTPUTS: outputs/diagnostics/objective_noise_floor_<date>.{log,rds}; the RNG seed and where it is applied are in both.
# ⛔ ADOPTS NOTHING.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
NF_DRIVER     <- "calibration/diag_objective_noise_floor.R"
NF_WAVE       <- file.path("calibration", "output", "multistart_20261006o_hilda_csl3v0kaidgbemw_seasml1_pin_obj17_sd1.0452")
NF_IDS        <- c(A = 10L, B = 1L)            # A = the landing's promoted start; B = the dry run's (the incumbent seed)
NF_MODES      <- c(A = file.path("calibration", "output", "refit_20261007_obj17_hilda_csl3v0kaidgbemw", "mode_fit_pumpN.rds"),
                   B = file.path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds"))
NF_REL        <- 1e-12                         # the nudge: u_i -> u_i (1 + NF_REL) + NF_ABS
NF_ABS        <- 1e-14
NF_NAMES      <- c("tau_ex", "hs_asx_frac", "h_hs", "kz", "u_hs", "h_ml", "beta_max", "q10")
NF_OFFSET_SD  <- 1e-7                          # the nearby points' offset, in u
NF_N_OFFSETS  <- 3L
NF_SEED       <- 20261007L                     # set IMMEDIATELY before the offsets' rnorm() calls, section 2
NF_HML_NUDGES <- 1:3                           # section 3: h_ml x (1 + k NF_REL)
NF_GATE_TOL   <- 1e-5                          # = fit_iav_module.R IAV_REPRO_TOL (ruled 2026-10-07)
NF_POW_NAMES  <- c("kz", "h_ml", "beta_max", "pump_grad", "q10")
NF_POW_REL    <- c(1e-8, 1e-7, 1e-6)
# ENV OVERRIDES (2026-10-13, the WTC landing's GATE 0 stop; CHANGELOG 2026-10-13 b): the same four sections at another wave.
# Unset, every constant above is #17's, so the 2026-10-07 log reproduces. CCX_NF_IDS = "A=<id>,B=<id>" (the start files,
# sections 1-2); CCX_NF_MODE_A / _B = the promoted files of those starts (section 3; A also section 4); CCX_NF_TAG names
# the outputs.
local({
  w <- Sys.getenv("CCX_NF_WAVE", ""); if (nzchar(w)) NF_WAVE <<- w
  ids <- Sys.getenv("CCX_NF_IDS", "")
  if (nzchar(ids)) { kv <- strsplit(strsplit(ids, ",")[[1]], "=")
    if (!all(lengths(kv) == 2L) || !setequal(vapply(kv, `[`, "", 1L), c("A", "B")))
      stop("CCX_NF_IDS must be \"A=<id>,B=<id>\", not '", ids, "'")
    NF_IDS <<- stats::setNames(as.integer(vapply(kv, `[`, "", 2L)), vapply(kv, `[`, "", 1L))[c("A", "B")] }
  for (k in c("A", "B")) { m <- Sys.getenv(paste0("CCX_NF_MODE_", k), ""); if (nzchar(m)) NF_MODES[[k]] <<- m }
  if (nzchar(paste0(w, ids)) && !nzchar(Sys.getenv("CCX_NF_MODE_A", ""))) stop("an overridden wave or ids needs CCX_NF_MODE_A / _B too")
})
NF_TAG <- Sys.getenv("CCX_NF_TAG", "")
NF_OUT <- file.path("outputs", "diagnostics", sprintf("objective_noise_floor_%s%s", format(Sys.Date(), "%Y%m%d"), NF_TAG))
COMMIT <- ccx_git_stamp()
sink(paste0(NF_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s | RNG: set.seed(%d) immediately before section 2's offsets (the only draws)\n", NF_DRIVER, COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M"), NF_SEED))
S <- lapply(NF_IDS, function(i) readRDS(file.path(NF_WAVE, sprintf("start_%03d.rds", i))))
for (k in names(S)) cat(sprintf("  basin %s: %s/start_%03d.rds (md5 %s), logpost %.9f\n", k, NF_WAVE, NF_IDS[[k]],
                                unname(tools::md5sum(file.path(NF_WAVE, sprintf("start_%03d.rds", NF_IDS[[k]])))), S[[k]]$logpost))
# THE OBJECTIVE, built as promote_multistart_mode.R builds it (the starts' gate, pins, structure, seas_ml, pump field)
stopifnot(length(unique(vapply(S, function(s) s$struct, ""))) == 1L, identical(S$A$pins, S$B$pins))
invisible(ccx_apply_gate(S$A$struct)); invisible(ccx_apply_pins(S$A$pins))
stopifnot(identical(S$A$param_names, CCX_PARAM_NAMES))
bp <- ccx_apply_structure(ccx_default_params(), S$A$struct, seas_ml = ccx_parse_seas_ml(S$A$seas_ml),
                          pump_field = ccx_parse_pump_field(S$A$pump_field))
for (n in names(S$A$pins)) bp[[n]] <- S$A$pins[[n]]
attr(bp, "pins") <- S$A$pins; bp$pump_mode <- S$A$pump_mode
lpf <- ccx_make_logpost(base_params = bp)
nudge <- function(u, n, k = 1) { u[[n]] <- u[[n]] * (1 + k * NF_REL) + NF_ABS; u }

cat("\n=== 1. THE ROUND TRIP: the objective at the optimiser's u_mode vs at ccx_par_to_unc(par_mode) ===\n")
R1 <- lapply(S, function(s) { u0 <- s$u_mode; u1 <- ccx_par_to_unc(s$par_mode)[names(u0)]; du <- u1 - u0
  a <- lpf(u0); b <- lpf(u1); a2 <- lpf(u0)
  c(n_diff = sum(du != 0), max_du = max(abs(du)), at_u_mode = a - s$logpost, at_encoded = b - s$logpost, again = a2 - a) })
for (k in names(R1)) cat(sprintf("  basin %s: %d of %d names re-encode differently (max |du| %.1e); objective - stored at u_mode %+.3e, at the re-encoded point %+.3e; u_mode twice %+.1e\n",
                                 k, R1[[k]][["n_diff"]], length(S[[k]]$u_mode), R1[[k]][["max_du"]], R1[[k]][["at_u_mode"]],
                                 R1[[k]][["at_encoded"]], R1[[k]][["again"]]))

cat(sprintf("\n=== 2. THE FLOOR: 1e-12 single-name nudges of u (%s) ===\n", paste(NF_NAMES, collapse = ", ")))
probe <- function(u0, lab) { b <- lpf(u0); d <- vapply(NF_NAMES, function(n) lpf(nudge(u0, n)) - b, 0)
  cat(sprintf("  %-28s base %.9f | d: %s | %d+ / %d- / %d zero\n", lab, b, paste(sprintf("%+.1e", d), collapse = " "),
              sum(d > 0), sum(d < 0), sum(d == 0)))
  list(base = b, d = d) }
R2 <- list(A_mode = probe(S$A$u_mode, "basin A at u_mode"), B_mode = probe(S$B$u_mode, "basin B at u_mode"))
set.seed(NF_SEED)                              # ⇐ the seed, immediately before the only RNG draws
OFFS <- lapply(seq_len(NF_N_OFFSETS), function(j) stats::rnorm(length(S$A$u_mode), 0, NF_OFFSET_SD))
for (j in seq_len(NF_N_OFFSETS)) R2[[sprintf("A_off%d", j)]] <- probe(S$A$u_mode + OFFS[[j]], sprintf("basin A + offset %d", j))

cat("\n=== 3. THE dg PATH: the base's stored rows (fit_iav_module.R's GATE 0), and under h_ml nudges ===\n")
OBS <- ccx_prepare_obs()
rows_of <- function(v) unlist(dg_streams(dg_run(v), v, obs = OBS))
R3 <- lapply(NF_MODES, function(F) { V <- dg_vector(F); ms0 <- unlist(V$md$streams); d0 <- rows_of(V)[names(ms0)] - ms0
  dk <- vapply(NF_HML_NUDGES, function(k) { v <- V; x <- v$pm$h_ml * (1 + k * NF_REL); v$p$h_ml <- x; v$pm$h_ml <- x
    max(abs(rows_of(v)[names(ms0)] - ms0)) }, 0)
  list(d0 = d0, nudged = dk) })
for (k in names(R3)) { d0 <- R3[[k]]$d0; o <- order(-abs(d0))[1:3]
  cat(sprintf("  basin %s: max |row - stored| %.2e (%s); h_ml x (1 + k 1e-12), k = %s: max %s\n", k, max(abs(d0)),
              paste(sprintf("%s %+.2e", names(d0)[o], d0[o]), collapse = ", "), paste(NF_HML_NUDGES, collapse = "/"),
              paste(sprintf("%.1e", R3[[k]]$nudged), collapse = " / "))) }

cat(sprintf("\n=== 4. THE GATE's POWER at basin A: max |row - stored| under a relative move of one name (gate %g) ===\n", NF_GATE_TOL))
VA <- dg_vector(NF_MODES[["A"]]); msA <- unlist(VA$md$streams)
R4 <- t(vapply(NF_POW_NAMES, function(n) vapply(NF_POW_REL, function(rel) { v <- VA; x <- v$pm[[n]] * (1 + rel)
  if (n %in% names(v$p)) v$p[[n]] <- x; v$pm[[n]] <- x; max(abs(rows_of(v)[names(msA)] - msA)) }, 0), numeric(length(NF_POW_REL))))
colnames(R4) <- sprintf("%g", NF_POW_REL)
for (n in rownames(R4)) cat(sprintf("  %-10s %s\n", n, paste(sprintf("%s: %.1e%s", colnames(R4), R4[n, ],
                                                                   ifelse(R4[n, ] > NF_GATE_TOL, " FAILS", "")), collapse = " | ")))
saveRDS(list(round_trip = R1, floor = R2, dg_path = R3, power = R4,
             provenance = list(driver = NF_DRIVER, commit = COMMIT, wave = NF_WAVE, ids = NF_IDS, modes = NF_MODES,
                               seed = NF_SEED, seed_applied = "set.seed() immediately before section 2's offsets (rnorm)",
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"))), paste0(NF_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", NF_OUT))
sink()
