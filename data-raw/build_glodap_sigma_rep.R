
# =====================================================================
# build_glodap_sigma_rep.R -- THE OCEAN-GRADIENT REPRESENTATION ERROR,
# sigma_rep(h_ml), FOR ALL THREE SCORED ROWS.
#
# Written 2026-08-28 when Marcus ADOPTED option 5 (sigma-inflation). Until then
# the three ocean-gradient rows were SKIPPED outside LIK_OCEAN_GRAD_HML_OK =
# [85, 120]; that skip was measured to bear a FREE LUNCH of +7.39 log-units
# (notes/collect_2026-08-28_hml_unbound_profile.md) which inflation removes to
# +0.033 (notes/collect_2026-08-28b_sigma_inflation_pricing.md).
#
# WHAT IT MEASURES. The shipped targets are read on FIXED depths -- surface
# [0, 100] m, deep [2627.2, inf) -- which are like-for-like with the model's
# boxes only while h_ml is near 100. The mismatch is a REPRESENTATION ERROR:
#
#     sigma_rep(h)^2 = (shipped_target - the SAME quantity read on the model's
#                       own box edges at h_ml = h)^2
#
# and the honest way to carry one is in quadrature, sigma_eff^2 = sigma_obs^2 +
# sigma_rep^2, with dnorm's normalization RETAINED so inflating is charged for.
# It is NOT a tuning knob: every number here is measured off GLODAP.
#
# THIS SHIPS THE **SIGNED** like-for-like TARGET, NOT |sigma_rep|, because the
# signed value is the quantity actually measured and folding it discards the sign
# for no gain. All three fields CROSS the shipped target -- DIC and ALK at h =
# 100, d13C at 106, i.e. inside the old band and beside the mode at 96.47 m.
# ⚠ AN EARLIER DRAFT OF THIS COMMENT CLAIMED folding would "plant a KINK in the
# posterior's softest direction". THAT WAS WRONG AND IS WITHDRAWN. sigma_eff uses
# the SQUARE of the difference, so folding is very nearly a no-op: MEASURED
# 2026-08-28, sigma_eff from the signed value and from |sigma_rep| differ by at
# most 0.0002 sigma_obs, and their second differences agree to six decimals. The
# choice is faithfulness to the measured quantity, NOT a smoothness fix.
# [[sigma_inflation_prices_the_band]]
#
# ⚠ NO SMOOTHING. Bottle selection steps discretely as a box edge crosses bottle
# depths, so like-for-like is slightly rough in h. MEASURED 2026-08-28: with the
# model gradient held at the mode, that roughness moves the three rows' summed
# logL by a median of 0.0055 and AT MOST 0.0734 log-units -- against a 0.70
# restart noise floor. A moving average was tried and REJECTED: at every width it
# deviated from the raw curve by MORE than the jumps it removed (0.131 vs 0.090
# at w = 11 m), because the curve has a narrow V-bottom at the crossing that
# averaging lifts. A smoother wider than the feature relocates it.
#
# Usage:  Rscript data-raw/build_glodap_sigma_rep.R [depth] [out]    (~3 min, 19 MB CSV read)
#
# THE COLUMN DEPTH IS AN ARGUMENT (2026-10-12; OCEAN_DEPTH 3700 -> 3682.2 m under label
# hilda_csl3v0kaidgbemwtc). sigma_rep is measured on the model's OWN box edges, which scale with
# the column, and against the deep product of the same column, so it is built once per depth:
# no argument = 3700 -> data/obs_glodap_sigma_rep.rds (NOT rebuilt; the record),
# `3682.2` -> data/obs_glodap_sigma_rep_3682.2m.rds, stamped `column_depth`.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- the recipe, COPIED from build_glodap_deep_targets.R via ----------
# calibration/diag_alk_sigma_rep.R. It is NOT re-chosen here, and G1/G2 below
# assert the copy still reproduces the shipped targets, so what this file calls a
# representation error is measured against the shipped target's own recipe.
SR_ISO_FILE  <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
SR_TALK_FILE <- ccx_path("data-raw", "downloads", "glodap_dic_talk_subset.csv")
SR_FLAG_OK   <- 2                        # GLODAP: 2 = acceptable measurement
SR_DLAT      <- 5; SR_DLON <- 10; SR_DZ <- 250
SR_MIN_CELLS <- 20
SR_SHIP_SURF <- c(0, 100)                # build_glodap_deep_targets.R
SR_DEPTH_LEGACY <- 3700
sr_args      <- commandArgs(trailingOnly = TRUE)
SR_DEPTH     <- if (length(sr_args) < 1) SR_DEPTH_LEGACY else as.numeric(sr_args[1])
SR_SHIP_DEEP <- c(readRDS(ccx_glodap_file("obs_glodap_deep", SR_DEPTH))$model_layer[["top"]], 1e5)  # GD_MODEL_DEEP_TOP; note the 1e5
stopifnot(SR_DEPTH != SR_DEPTH_LEGACY || SR_SHIP_DEEP[1] == 2627.2)
SR_GATE_TOL  <- 1e-3                     # absolute, each field's own units
SR_H_IN      <- 100                      # where the model's surface box IS [0, 100]
# The FULL shipped support of h_ml, at 1 m. Not the old band: the whole point of
# the adoption is that the rows are now scored everywhere h_ml can go.
# ⚠ PINNED 2026-10-12 to the 08-28 support, 30-200 m: the box has since moved to [CCX_HML_FLOOR_M,
# 200] = [42.5, 200], and deriving the grid from the live box no longer reproduced the shipped
# record (158 points from 42.5, against its 171 from 30). The pinned grid is a SUPERSET of the
# live box (asserted), so the interpolant never clamps inside the support, and both column-depth
# products share one grid.
SR_H_GRID    <- seq(30, 200, by = 1)
stopifnot(min(SR_H_GRID) <= CCX_PARAM_TABLE$h_ml$lo, max(SR_H_GRID) >= CCX_PARAM_TABLE$h_ml$hi)
SR_OUT       <- if (length(sr_args) >= 2) sr_args[2] else ccx_glodap_file("obs_glodap_sigma_rep", SR_DEPTH)

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

# `closed` distinguishes the two conventions and is NOT cosmetic: the shipped
# target was read with the upper edge CLOSED, while adjacent model boxes must not
# both claim the shared interface depth, so the like-for-like read is half-open.
# At h_ml = 100 that convention is the ONLY difference left, which is the floor
# the curve returns to (G3).
sr_cells <- function(d, val, flag, zmin, zmax, closed) {
  v <- d[[val]]; f <- d[[flag]]
  ok <- is.finite(v) & v > -900 & is.finite(f) & f == SR_FLAG_OK &
        d$depth >= zmin & (if (closed) d$depth <= zmax else d$depth < zmax)
  if (sum(ok) < SR_MIN_CELLS) return(NA_real_)
  x  <- d[ok, ]
  id <- paste(floor(x$lat / SR_DLAT), floor(x$lon / SR_DLON), floor(x$depth / SR_DZ))
  m  <- as.numeric(tapply(x[[val]], id, mean))
  la <- as.numeric(tapply(x$lat,    id, mean))
  w  <- cos(la * pi / 180)
  sum(w * m) / sum(w)
}
sr_grad <- function(d, val, flag, surf, deep, closed)
  sr_cells(d, val, flag, deep[1], deep[2], closed) -
  sr_cells(d, val, flag, surf[1], surf[2], closed)

cat("OCEAN-GRADIENT REPRESENTATION ERROR sigma_rep(h_ml), all three rows.\n")
cat(sprintf("h grid: %g to %g m by 1 m (%d points) -- h_ml's FULL shipped support\n",
            min(SR_H_GRID), max(SR_H_GRID), length(SR_H_GRID)))
iso <- utils::read.csv(SR_ISO_FILE);  tlk <- utils::read.csv(SR_TALK_FILE)
cat(sprintf("isotope pop : %s (%d rows)\n", basename(SR_ISO_FILE), nrow(iso)))
cat(sprintf("ALK pop     : %s (%d rows)\n", basename(SR_TALK_FILE), nrow(tlk)))

tg  <- ccx_ocean_gradient_target(SR_DEPTH)
raw <- readRDS(ccx_glodap_file("obs_glodap_deep", SR_DEPTH))
stopifnot(!is.null(tg$dic), !is.null(tg$d13c), !is.null(tg$alk))
# The three rows and the population each is measured on. ⚠ ALK and DIC come from
# DIFFERENT GLODAP subsets; the DIC row is the ISOTOPE population's, which is why
# `tco2_alkpop` exists in the rds and is NOT this row.
SR_ROWS <- list(
  dic  = list(d = iso, val = "tco2", flag = "tco2f", tgt = tg$dic),
  d13c = list(d = iso, val = "c13",  flag = "c13f",  tgt = tg$d13c),
  alk  = list(d = tlk, val = "talk", flag = "talkf", tgt = tg$alk))

# ---------------------------------------------------------------------
sep("GATE G1 -- reproduce each SHIPPED target from this file's own cells")
cat("On the shipped fixed depths, upper edge CLOSED, before any h_ml is varied.\n")
cat(sprintf("%-6s %14s %14s %12s\n", "row", "from cells", "shipped rds", "|gap|"))
for (n in names(SR_ROWS)) {
  s <- SR_ROWS[[n]]
  v <- sr_grad(s$d, s$val, s$flag, SR_SHIP_SURF, SR_SHIP_DEEP, TRUE)
  cat(sprintf("%-6s %14.4f %14.4f %12.2e\n", n, v, s$tgt$target, abs(v - s$tgt$target)))
  if (!isTRUE(abs(v - s$tgt$target) < SR_GATE_TOL))
    stop(sprintf("G1 FAILED for %s: the recipe no longer reproduces the shipped target ",
                 n), "-- sigma_rep would then be measured against a DIFFERENT quantity.")
}
cat("PASS -- the recipe is the build script's, so sigma_rep below is the\n")
cat("shipped target's OWN representation error.\n")

sep("GATE G2 -- at h_ml = 100 the model's surface box IS the shipped 0-100 m layer")
g100 <- ccx_ocean_grid(SR_H_IN, total_depth = SR_DEPTH); zb <- c(0, cumsum(g100$dz))
cat(sprintf("ccx_ocean_grid(%g): surface box [%.4f, %.4f]; shipped [%g, %g]\n",
            SR_H_IN, zb[1], zb[2], SR_SHIP_SURF[1], SR_SHIP_SURF[2]))
stopifnot(abs(zb[1] - SR_SHIP_SURF[1]) < 1e-9, abs(zb[2] - SR_SHIP_SURF[2]) < 1e-9)
cat("PASS -- any residual at h_ml = 100 is the closed-vs-open edge convention ONLY.\n")

# ---------------------------------------------------------------------
sep("THE MEASUREMENT -- the like-for-like target on the model's own box edges")
t0 <- Sys.time()
lfl <- list()
for (n in names(SR_ROWS)) {
  s <- SR_ROWS[[n]]
  lfl[[n]] <- vapply(SR_H_GRID, function(h) {
    gr <- ccx_ocean_grid(h, total_depth = SR_DEPTH); zb <- c(0, cumsum(gr$dz)); k <- length(gr$dz)
    sr_grad(s$d, s$val, s$flag, c(0, zb[2]), c(zb[k], zb[k + 1]), FALSE)
  }, numeric(1))
  if (anyNA(lfl[[n]]))
    stop(sprintf("%s: %d of %d h points had fewer than %d cells -- the grid reaches ",
                 n, sum(is.na(lfl[[n]])), length(SR_H_GRID), SR_MIN_CELLS),
         "depths GLODAP does not populate; narrow SR_H_GRID or lower SR_MIN_CELLS ",
         "DELIBERATELY, never silently.")
  sr <- abs(lfl[[n]] - s$tgt$target)
  cat(sprintf("%-6s sigma_rep: min %.4f at h=%g | max %.4f at h=%g | /sigma_obs %.3f-%.3f\n",
              n, min(sr), SR_H_GRID[which.min(sr)], max(sr), SR_H_GRID[which.max(sr)],
              min(sr) / s$tgt$sd, max(sr) / s$tgt$sd))
  fl <- which(diff(sign(lfl[[n]] - s$tgt$target)) != 0)
  cat(sprintf("       crosses the shipped target at h = %s  <- why the SIGNED value ships\n",
              if (length(fl)) paste(SR_H_GRID[fl], collapse = ", ") else "NEVER"))
}
cat(sprintf("(%.0f s)\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))

sep("GATE G3 -- sigma_eff must never fall below sigma_obs, and must be finite")
for (n in names(SR_ROWS)) {
  s <- SR_ROWS[[n]]
  se <- sqrt(s$tgt$sd^2 + (lfl[[n]] - s$tgt$target)^2)
  stopifnot(all(is.finite(se)), all(se >= s$tgt$sd - 1e-12))
  cat(sprintf("%-6s sigma_eff/sigma_obs  %.4f - %.4f\n", n, min(se) / s$tgt$sd,
              max(se) / s$tgt$sd))
}
cat("PASS.\n")

out <- list(
  h          = SR_H_GRID,
  like_for_like = lfl,                 # ⚠ SIGNED, on the model's own box edges
  target     = lapply(SR_ROWS, function(s) s$tgt$target),
  sd_obs     = lapply(SR_ROWS, function(s) s$tgt$sd),
  recipe     = list(flag_ok = SR_FLAG_OK, dlat = SR_DLAT, dlon = SR_DLON, dz = SR_DZ,
                    min_cells = SR_MIN_CELLS, shipped_surf = SR_SHIP_SURF,
                    shipped_deep = SR_SHIP_DEEP, closed_shipped = TRUE,
                    closed_like_for_like = FALSE),
  provenance = list(iso = basename(SR_ISO_FILE), talk = basename(SR_TALK_FILE),
                    built = "2026-08-28", built_by = "data-raw/build_glodap_sigma_rep.R",
                    note = paste("SIGNED like-for-like; sigma_eff^2 = sd_obs^2 +",
                                 "(target - like_for_like)^2. No smoothing --",
                                 "measured roughness median 0.0055, max 0.0734 logL.")))
if (SR_DEPTH != SR_DEPTH_LEGACY) {                 # absent = 3700 (the shipped record)
  out$column_depth <- SR_DEPTH
  out$provenance$built <- format(Sys.Date())
}
saveRDS(out, SR_OUT)
cat(sprintf("\nwrote %s\n", SR_OUT))
