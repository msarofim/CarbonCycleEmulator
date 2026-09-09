# ---------------------------------------------------------------------------
# diag_seasonal_ml_geometry.R -- the GEOMETRY pre-check for round 6 (option A,
# a true seasonal mixed layer). Generates every model number in
# `notes/prereg_2026-09-09g_round6_seasonal_ml.md` sections 3b and 3c.
#
# THE TWO QUESTIONS IT ANSWERS
#   3b. Under the MEAN-PRESERVING ruling (Marcus 2026-09-09g) -- h_ml(t) is the
#       MLD climatology scaled so its ANNUAL MEAN is the fitted h_ml -- does the
#       winter mixed layer stay inside interior layer 1 at the canonical? If it
#       does, single-layer entrainment suffices and no multi-layer entrainment
#       code is needed.
#   3c. At what fitted h_ml does it STOP staying inside layer 1? That is a hard
#       stopping condition on the refit (prereg P8), not a footnote: `ent26`'s
#       h_ml was 134.15 m, well past it.
#
# ⚠ NOTHING IS BUILT. This reads the shipped grid and the shipped MLD product
# and does arithmetic on them. It changes no objective and moves no logpost.
#
# ⛔ The bound is found by uniroot, NOT by the closed form. Hand algebra on this
# gave 82 m against the true 76 m, because dz_1 depends on h_ml too -- the kind
# of 8 % error that would have put `hilda31` a comfortable distance inside a
# bound it is actually 27 m from.
# ---------------------------------------------------------------------------

## ---- named constants: every label below derives from these ----------------
TAG          <- "20260909"
OUT_RDS      <- file.path("outputs", "diagnostics",
                          paste0("seasonal_ml_geometry_", TAG, ".rds"))
OUT_LOG      <- sub("[.]rds$", ".log", OUT_RDS)
MLD_PRODUCT  <- file.path("data", "obs_mld.rds")
HEMIS_USED   <- c("NH", "SH")
LAYER_TESTED <- 1L          # the interior layer the excursion must stay inside
HML_SEARCH   <- c(20, 400)  # m, bracket for the punch-through root
ENT26_HML    <- 134.15      # m, for the "this is not hypothetical" line

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

con <- file(OUT_LOG, open = "wt")
say <- function(...) { msg <- sprintf(...); cat(msg, "\n"); cat(msg, "\n", file = con) }

## ---- the canonical, resolved the one legal way ----------------------------
md <- readRDS(ccx_mode_file())
p  <- ccx_overlay_par(ccx_mode_base(md), ccx_mode_params(md))

say("SEASONAL MIXED LAYER -- GEOMETRY PRE-CHECK (round 6, option A)")
say("mode file : %s", ccx_mode_file())
say("fitted h_ml = %.3f m | h_hs = %.3f m | N_INTERIOR = %d",
    p$h_ml, p$h_hs, N_INTERIOR)

## ---- 3d. does the high-latitude box get dragged along? --------------------
# h_hs follows grid$h_ml ONLY when p$h_hs <= 0 (R/model.R). A pinned h_hs means
# a seasonal ML leaves the HILDA surface box alone. This is a PROPERTY OF THE
# MODE FILE, so it is re-tested rather than assumed for every future canonical.
hs_follows <- is.null(p$h_hs) || !is.finite(p$h_hs) || p$h_hs <= 0
say("HS box follows h_ml? %s%s", if (hs_follows) "YES" else "no",
    if (hs_follows) "  <-- the seasonal ML WOULD drag the HILDA surface box" else
                    "  (h_hs is pinned; the seasonal ML leaves it alone)")

## ---- the shipped grid at the annual mean ----------------------------------
grid  <- ccx_ocean_grid(p$h_ml)
zbase <- cumsum(grid$dz)
layer1_base <- zbase[LAYER_TESTED + 1L]
say("layer-%d base = %.1f m (ML base %.1f m, dz_1 %.1f m)",
    LAYER_TESTED, layer1_base, grid$h_ml, grid$dz[LAYER_TESTED + 1L])

## ---- 3b. the mean-preserving excursion at the canonical -------------------
seas <- readRDS(MLD_PRODUCT)$seasonal
rows <- lapply(HEMIS_USED, function(h) {
  h_m    <- seas[[h]]$h_m
  scaled <- h_m / mean(h_m) * p$h_ml           # THE MEAN-PRESERVING RULING
  data.frame(hemi = h, ratio_max_mean = max(h_m) / mean(h_m),
             ml_min = min(scaled), ml_max = max(scaled),
             month_max = which.max(scaled), layer1_base = layer1_base,
             punches = max(scaled) > layer1_base)
})
tab <- do.call(rbind, rows)

say("")
say("3b. MEAN-PRESERVING excursion at the canonical")
for (i in seq_len(nrow(tab))) with(tab[i, ], say(
  "  %s: ML %.1f -> %.1f m (max month %d) vs layer-%d base %.1f m | punches layer %d? %s",
  hemi, ml_min, ml_max, month_max, LAYER_TESTED, layer1_base, LAYER_TESTED,
  if (punches) "YES" else "no"))

## ---- 3c. the bound, by uniroot ---------------------------------------------
# Positive when the winter ML has punched through layer 1. dz_1 shrinks as h_ml
# grows, so both sides move -- hence a root find, not a rearrangement.
gap <- function(hml, ratio) ratio * hml - cumsum(ccx_ocean_grid(hml)$dz)[LAYER_TESTED + 1L]
tab$hml_bound <- vapply(seq_len(nrow(tab)), function(i)
  uniroot(gap, HML_SEARCH, ratio = tab$ratio_max_mean[i])$root, numeric(1))

say("")
say("3c. STOPPING CONDITION (prereg P8) -- fitted h_ml above which the winter ML")
say("    punches layer %d, so single-layer entrainment becomes INVALID:", LAYER_TESTED)
for (i in seq_len(nrow(tab))) with(tab[i, ], say(
  "  %s: max/mean %.4f -> bound %.1f m | margin from the canonical %.1f m",
  hemi, ratio_max_mean, hml_bound, hml_bound - p$h_ml))
say("  ent26's h_ml was %.2f m -- %s the tightest bound. The bound is not hypothetical.",
    ENT26_HML, if (ENT26_HML > min(tab$hml_bound)) "ABOVE" else "below")

dir.create(dirname(OUT_RDS), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(mode_file = ccx_mode_file(), h_ml = p$h_ml, h_hs = p$h_hs,
             hs_follows_h_ml = hs_follows, grid_dz = grid$dz, table = tab,
             layer_tested = LAYER_TESTED, built = Sys.time()), OUT_RDS)
say("")
say("wrote %s", OUT_RDS)
close(con)
