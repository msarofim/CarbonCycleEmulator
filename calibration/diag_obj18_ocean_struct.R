#!/usr/bin/env Rscript
# =====================================================================
# diag_obj18_ocean_struct.R -- THE OCEAN's CLIMATE EFFECT at #18: is the move the STRUCTURE or the PARAMETERS?
# (CHANGELOG 2026-10-08 b; Marcus: "run the ocean structure-vs-parameter test".) At #18's landing the ten-protocol
# ensemble (diag_ocean_climate_gobm.R) read 2.16x / 2.12x GCB 2025's -0.20 GtC/yr, against 1.87-1.90x at #16, #17 and
# hilda29w. The two sides run under different labels (`...emw` vs `...emwt`), and the label's ENSO index reaches the
# FORWARD run (ccx_enso_index_of(V$p) builds the forcing), so the label alone can move the ocean.
#
# THIS SCRIPT BUILDS THE TWO MIDDLE ARMS of a four-arm walk, all on hilda29w's vector, and gates them:
#   A  hilda29w as registered: #17's label, #17's stage-1 module values (P0)        -> the registered file itself
#   B  hilda29w under #18's label, module at P0 (the pricing's B1: the index switch alone)   -> constructed here
#   C  hilda29w under #18's label, module at #18's stage 1 (S18; the pricing's B1s)        -> constructed here
#   D  #18's basin 1 (id 0): #18's label, S18, the free names REFIT                          -> the landed refit
# A->B = the structure; B->C = the module's pinned move; C->D = the refit. The ocean driver then runs each arm at ONE
# commit (CCX_OC_MODE=<name>=<path>), so the four numbers are like for like.
# ⛔ THE CONSTRUCTED FILES ARE NOT MODES. They are hilda29w's file with `struct` (B) and the four module pins (C)
# replaced, written under outputs/diagnostics/ -- never calibration/output/ -- with `constructed` saying so. Their
# stored logpost and streams are RE-EVALUATED in their own space, and the second-order block (fitted in #17's space) is
# DROPPED rather than carried stale.
# GATES (each against a number this script did not produce):
#   G1 the objective (ccx_mode_base + gate + pins, the ocean driver's own construction) at A reproduces A's stored
#      logpost; at B and C, the pricing's B1 / B1s (diag_obj18_price.R -> obj18_price_20261007.rds) -- tol OS_TOL.
#   G2 the dg path the ocean driver uses (dg_vector -> dg_run -> dg_streams), summed, reproduces the same likelihoods.
# OS_TOL = 1e-5: the objective's measured noise floor is ~1e-6 (memory objective_noise_floor_optimum_on_spike), and
# every reproduce-gate on it is >= 1e-5 since 10-07.
# Usage: Rscript calibration/diag_obj18_ocean_struct.R   (then the four ocean-driver runs; CHANGELOG 10-08 b)
# OUTPUTS: outputs/diagnostics/obj18_ocean_struct_<date>/{B_hilda29w_emwt_P0,C_hilda29w_emwt_S18}.rds and
#          outputs/diagnostics/obj18_ocean_struct_<date>.log. No RNG.
# ⛔ ADOPTS NOTHING AND REGISTERS NOTHING.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
OS_DRIVER   <- "calibration/diag_obj18_ocean_struct.R"
OS_INC      <- CCX_MODE_OBJ18_INCUMBENT            # "hilda29w": #17's basin B, #18's seed
OS_FROM     <- CCX_MODE_OBJ17_STRUCT               # the incumbent's own label
OS_TO       <- CCX_MODE_OBJ18_STRUCT               # #18's label
OS_MODULE   <- c("lag_enso_land", "gamma_enso_land_NH", "gamma_enso_land_SH", "w_enso_l2")
OS_S18      <- CCX_MODE_OBJ18_PINS[OS_MODULE]      # #18's stage-1 values (the pricing's S18)
OS_PRICE    <- ccx_path("outputs", "diagnostics", "obj18_price_20261007.rds")
OS_TOL      <- 1e-5
OS_DROP     <- c("hessian", "cov", "cor", "sd_unc", "pd", "eigen", "hess_eps", "hess_eps_unstable", "hess_diag_by_step",
                 "hess_eps_frac", "logdet_negH", "hess_recomputed")
OS_DATE     <- format(Sys.Date(), "%Y%m%d")
OS_DIR      <- ccx_path("outputs", "diagnostics", sprintf("obj18_ocean_struct_%s", OS_DATE))
OS_ARMS     <- c(B = "B_hilda29w_emwt_P0", C = "C_hilda29w_emwt_S18")
COMMIT <- ccx_git_stamp()
dir.create(OS_DIR, showWarnings = FALSE, recursive = TRUE)
sink(paste0(OS_DIR, ".log"), split = TRUE)
INC_FILE <- ccx_mode_file(OS_INC); INC_MD5 <- unname(tools::md5sum(INC_FILE))
cat(sprintf("%s @%s, %s | no RNG\n  incumbent %s = %s (md5 %s)\n  pricing   %s (md5 %s)\n", OS_DRIVER, COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M"), OS_INC, INC_FILE, INC_MD5, OS_PRICE, unname(tools::md5sum(OS_PRICE))))
MD <- readRDS(INC_FILE); PX <- readRDS(OS_PRICE)
stopifnot(identical(ccx_mode_struct(MD), OS_FROM), identical(ccx_pin_label(MD$pins), ccx_pin_label(CCX_MODE_OBJ17_PINS)),
          all(OS_MODULE %in% names(MD$pins)), !any(OS_MODULE %in% names(MD$par_mode)))

# ---- build the two constructed files ------------------------------------------------
build <- function(arm) {
  m <- MD; m$struct <- OS_TO
  if (arm == "C") m$pins[OS_MODULE] <- OS_S18[OS_MODULE]
  for (n in OS_DROP) m[[n]] <- NULL
  m$constructed <- list(from = INC_FILE, from_md5 = INC_MD5, by = OS_DRIVER, commit = COMMIT,
                        what = if (arm == "B") sprintf("%s's vector and pins under %s (the pricing's B1)", OS_INC, OS_TO)
                               else sprintf("%s's vector under %s, the module pinned at #18's stage 1 (the pricing's B1s)", OS_INC, OS_TO),
                        struct_from = OS_FROM, struct_to = OS_TO,
                        module = if (arm == "C") OS_S18 else MD$pins[OS_MODULE], dropped = OS_DROP,
                        note = "NOT A MODE: a construction for diag_ocean_climate_gobm.R; logpost/streams re-evaluated in this space")
  m
}
# ---- the objective in a file's own space (the ocean driver's section-R construction) --
score <- function(m) {
  bp <- ccx_mode_base(m); if (!is.null(m$pump_mode)) bp$pump_mode <- m$pump_mode
  g <- ccx_apply_gate(ccx_mode_struct(m)); rp <- ccx_apply_pins(ccx_mode_pins(m))
  on.exit({ ccx_unpin_params(rp); ccx_unapply_gate(g) }, add = TRUE)
  u <- ccx_par_to_unc(ccx_mode_par_with_pins(m))
  v <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(m)))(u)
  list(logpost = as.numeric(v), lik = attr(v, "loglik"), streams = unlist(attr(v, "streams")))
}
dg_lik <- function(path) { v <- dg_vector(path); sum(unlist(dg_streams(dg_run(v), v))) }

cat("\n=== G1 / G2: each arm reproduces a number this script did not produce (tol ", OS_TOL, ") ===\n", sep = "")
TGT <- list(A = list(logpost = MD$logpost, lik = NA_real_, src = sprintf("%s's stored logpost", OS_INC)),
            B = list(logpost = PX$b1$logpost, lik = PX$b1$lik, src = "the pricing's B1"),
            C = list(logpost = PX$b1s$logpost, lik = PX$b1s$lik, src = "the pricing's B1s"))
PATHS <- c(A = INC_FILE); G <- list(); ok <- TRUE
for (arm in c("A", "B", "C")) {
  if (arm == "A") { m <- MD } else {
    m <- build(arm); s <- score(m); m$logpost <- s$logpost; m$streams <- s$streams
    PATHS[[arm]] <- file.path(OS_DIR, paste0(OS_ARMS[[arm]], ".rds")); saveRDS(m, PATHS[[arm]])
  }
  s <- score(m); dl <- dg_lik(PATHS[[arm]])
  d1 <- s$logpost - TGT[[arm]]$logpost
  d2 <- if (is.na(TGT[[arm]]$lik)) dl - s$lik else dl - TGT[[arm]]$lik
  pass <- abs(d1) <= OS_TOL && abs(d2) <= OS_TOL; ok <- ok && pass
  G[[arm]] <- list(path = PATHS[[arm]], logpost = s$logpost, lik = s$lik, dg_lik = dl, d_logpost = d1, d_lik = d2, pass = pass)
  cat(sprintf("  %s %-22s G1 logpost %.6f vs %s %+.1e | G2 dg likelihood %.6f vs %s %+.1e  -> %s\n", arm,
              if (arm == "A") OS_INC else OS_ARMS[[arm]], s$logpost, TGT[[arm]]$src, d1, dl,
              if (is.na(TGT[[arm]]$lik)) "its own objective" else "the pricing", d2, if (pass) "PASS" else "FAIL"))
}
cat(sprintf("\n  the ocean-driver calls (one commit, like for like):\n"))
for (arm in names(PATHS)) cat(sprintf("    CCX_OC_MODE=\"os%s_%s=%s\" Rscript calibration/diag_ocean_climate_gobm.R\n", arm,
                                      if (arm == "A") paste0(OS_INC, "_emw") else OS_ARMS[[arm]], PATHS[[arm]]))
saveRDS(list(driver = OS_DRIVER, commit = COMMIT, incumbent = INC_FILE, incumbent_md5 = INC_MD5, price = OS_PRICE,
             from = OS_FROM, to = OS_TO, s18 = OS_S18, tol = OS_TOL, gates = G, paths = PATHS), file.path(OS_DIR, "gates.rds"))
sink()
if (!ok) stop("a gate FAILED: the constructed arms do not reproduce the pricing; do NOT run the ocean driver on them")
