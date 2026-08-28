# =====================================================================
# ALKALINITY'S REPRESENTATION ERROR -- the one input sigma-inflation was
# missing (handoff 2026-08-16g sec.2.4 / open item 4)
# =====================================================================
# 16g measured sigma_rep(h_ml) for the DIC and d13C gradient rows and used it to
# price sigma-inflation against the shipped hard skip. It could not do the third
# row, and said so:
#
#   "Alkalinity's sigma_rep is UNQUANTIFIED -- the GLODAP subset carries no
#    `talk` column, so it would need a new download or a stated assumption."
#
# THE SECOND HALF OF THAT IS WRONG, AND THIS FILE IS THE CORRECTION. The subset
# 16g's part 4 reads (HB_GLODAP_FILE = glodap_c13c14_subset.csv) indeed has no
# talk column. But the ALK TARGET IT SCORES AGAINST WAS NEVER BUILT FROM THAT
# FILE: data-raw/build_glodap_deep_targets.R line 324 reads a DIFFERENT local
# extract, glodap_dic_talk_subset.csv (464,590 QC-passed bottles), precisely
# because -- as its own comment says -- "alkalinity is measured on far more
# bottles" than the isotope cruises. That file is on disk. So sigma_rep for the
# alkalinity row is measurable with NO new download and NO stated assumption,
# and the only thing that was ever missing is that part 4 pointed at one file
# while the target came from another.
#
# WHY IT MATTERS RATHER THAN BEING A TIDY-UP. 16g sec.2.4 offers sigma-inflation
# as "the standing alternative if sec.5.3 goes badly" and as the only candidate
# that fixes both the barrier and the incentive with h_ml free. But an inflation
# has to be applied to ALL THREE rows or it is not a formulation -- and one of
# the three had no measured sigma_rep. This file supplies it, so that decision
# can be taken on three measured numbers instead of two and a shrug.
#
# WHAT THIS FILE DOES NOT DO. It does not run the model, does not touch the
# objective, and does not price inflation against the skip -- that needs the
# model's own gradient at each h_ml (16g part 4b) and the refit is running.
# It measures the OBSERVATION-side quantity only, which is the blocked input.
#
# PRE-REGISTERED PREDICTIONS (written before the run; scored at the end):
#   Q1. ALK's sigma_rep/sigma_obs stays below 1 across h_ml's whole prior
#       support, as DIC's (0.04-0.87) and d13C's (0.01-1.11) essentially do.
#       Bar: max ratio < 1.2.
#   Q2. IN BAND it is small -- bar: max in-band ratio < 0.40, i.e. the same
#       "sub-half-sigma" regime as DIC's in-band 0.04-0.34.
#   Q3. ALK's sigma_rep tracks DIC's in SHAPE across the h_ml grid, because both
#       are gradients of a carbon-like tracer read on the same box edges.
#       Bar: Pearson r > 0.9 between the two sigma_rep(h) curves.
#
# RUNTIME ~30 s, dominated by reading a 19 MB CSV. Deliberately light: a refit
# is running on this machine (16 GB) and nothing here may compete with it.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- named constants: every label, window and threshold below derives ----
# The observation-side recipe is COPIED from diag_hml_band_discontinuity.R part
# 4, which in turn copied it from diag_gradient_target_and_neff.R. It is not
# re-chosen here, and G1/G2 assert the copy still reproduces the shipped
# targets -- the same discipline as 16g's GATE D.
AS_TALK_FILE     <- ccx_path("data-raw", "downloads", "glodap_dic_talk_subset.csv")
AS_ISO_FILE      <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
AS_FLAG_OK       <- 2                    # GLODAP: 2 = acceptable
AS_DLAT          <- 5; AS_DLON <- 10; AS_DZ <- 250      # the build script's cells
AS_SHIPPED_SURF  <- c(0, 100)            # build_glodap_deep_targets.R
AS_SHIPPED_DEEP  <- c(2627.2, 1e5)       # ditto -- note the 1e5
AS_MIN_CELLS     <- 20                   # part 4's minimum, unchanged
AS_GATE_TOL      <- 1e-3                 # absolute, in each field's own units
AS_BAND          <- LIK_OCEAN_GRAD_HML_OK_RETIRED               # [85, 120]
AS_H_IN          <- 100                  # the pump's own h_ml, the in-band ref
AS_H_FIT         <- 184                  # the quarantined mode's h_ml
# The same h_ml grid 16g part 4 scanned, so the ALK column is directly
# comparable with the DIC and d13C columns in that run's log.
AS_EPS           <- 0.01
AS_H_SCAN        <- sort(unique(c(
  32, 35, seq(40, 80, by = 10), 84, AS_BAND[1] - AS_EPS, AS_BAND[1] + AS_EPS,
  seq(86, 118, by = 4), AS_BAND[2] - AS_EPS, AS_BAND[2] + AS_EPS,
  seq(122, 200, by = 10), AS_H_FIT)))
# Prediction bars, named so the scoring below cannot quietly move them.
AS_Q1_MAX_RATIO  <- 1.20
AS_Q2_MAX_INBAND <- 0.40
AS_Q3_MIN_R      <- 0.90
AS_OUTDIR        <- ccx_path("calibration", "output", "alk_sigma_rep")
# 16g part 4's saved DIC/d13C sigma_rep, read for the comparison table so the
# comparators are the run's own numbers and not a transcription of its handoff.
AS_PRIOR_RDS     <- ccx_path("calibration", "output", "hml_band_discontinuity",
                             "hml_band_discontinuity.rds")

dir.create(AS_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

cat("ALKALINITY sigma_rep -- the missing third input to 16g sec.2.4's\n")
cat("sigma-inflation decision (open item 4).\n")
cat(sprintf("talk population : %s\n", basename(AS_TALK_FILE)))
cat(sprintf("isotope pop     : %s  (what 16g part 4 read, and why ALK was missed)\n",
            basename(AS_ISO_FILE)))

tg <- ccx_ocean_gradient_target()
stopifnot(!is.null(tg), !is.null(tg$dic), !is.null(tg$d13c), !is.null(tg$alk))

# ---------------------------------------------------------------------
# THE RECIPE. One function, used for every field and both files, so a gate that
# passes on one field is evidence about the same code the other field uses.
# ---------------------------------------------------------------------
as_cells <- function(d, val, flag, zmin, zmax, closed) {
  v <- d[[val]]; f <- d[[flag]]
  ok <- is.finite(v) & v > -900 & is.finite(f) & f == AS_FLAG_OK &
        d$depth >= zmin & (if (closed) d$depth <= zmax else d$depth < zmax)
  if (sum(ok) < AS_MIN_CELLS) return(NULL)
  x  <- d[ok, ]
  id <- paste(floor(x$lat / AS_DLAT), floor(x$lon / AS_DLON),
              floor(x$depth / AS_DZ))
  cl <- data.frame(v   = as.numeric(tapply(x[[val]], id, mean)),
                   lat = as.numeric(tapply(x$lat,    id, mean)))
  cl$w <- cos(cl$lat * pi / 180)
  cl
}
as_vw   <- function(cl) if (is.null(cl)) NA_real_ else sum(cl$w * cl$v) / sum(cl$w)
as_grad <- function(d, val, flag, surf, deep, closed)
  as_vw(as_cells(d, val, flag, deep[1], deep[2], closed)) -
  as_vw(as_cells(d, val, flag, surf[1], surf[2], closed))

sep("READING THE ALKALINITY POPULATION")
stopifnot(file.exists(AS_TALK_FILE))
dt <- utils::read.csv(AS_TALK_FILE)
cat(sprintf("%s: %d rows, columns %s\n", basename(AS_TALK_FILE), nrow(dt),
            paste(names(dt), collapse = "/")))
stopifnot(all(c("lat", "lon", "depth", "talk", "talkf", "tco2", "tco2f") %in% names(dt)))

# ---------------------------------------------------------------------
# GATES. Same logic as 16g's GATE D: a drifted recipe must not be able to pass
# itself off as a representation error. Two fields are gated, not one, because a
# recipe that reproduced only `talk` could be right by luck about the cells and
# wrong about the weighting.
# ---------------------------------------------------------------------
sep("GATE G1/G2: reproduce the SHIPPED targets from this file's own cells")
cat("On the shipped fixed depths (0-100 m / >2627.2 m, upper edge CLOSED),\n")
cat("before any h_ml is varied.\n")
cat(sprintf("%-24s %14s %14s %12s\n", "target", "from cells", "shipped rds", "|gap|"))
gate_fields <- list(
  list(nm = "talk (ALK row)",        val = "talk", flag = "talkf", shp = tg$alk$target),
  list(nm = "tco2 on the ALK pop",   val = "tco2", flag = "tco2f",
       shp = ccx_ocean_gradient_target()$dic$target))
# NOTE: the SECOND row's shipped comparator is NOT tg$dic -- tg$dic is the
# isotope population's DIC gradient, and the build script measured a DIFFERENT
# number on the ALK population (`tco2_alkpop`, reported for the carbonate ratio
# and explicitly NOT a term). Read it from the raw rds, because
# ccx_ocean_gradient_target() exposes only the three scored rows.
raw <- readRDS(ccx_path("data", "obs_glodap_deep.rds"))
stopifnot(!is.null(raw$gradient$talk), !is.null(raw$gradient$tco2_alkpop))
gate_fields[[1]]$shp <- raw$gradient$talk$target
gate_fields[[2]]$shp <- raw$gradient$tco2_alkpop$target

gaps <- vapply(gate_fields, function(g) {
  v <- as_grad(dt, g$val, g$flag, AS_SHIPPED_SURF, AS_SHIPPED_DEEP, TRUE)
  cat(sprintf("%-24s %14.4f %14.4f %12.2e\n", g$nm, v, g$shp, abs(v - g$shp)))
  abs(v - g$shp)
}, numeric(1))
stopifnot(all(gaps < AS_GATE_TOL))
cat(sprintf("Both reproduced to < %g. The recipe is the build script's, on the\n",
            AS_GATE_TOL))
cat("ALK population -- so sigma_rep measured below is the shipped target's own.\n")

sep("GATE G3: at h_ml = 100 the model's surface box IS the shipped 0-100 m layer")
gr100 <- ccx_ocean_grid(AS_H_IN); zb100 <- c(0, cumsum(gr100$dz))
cat(sprintf("ccx_ocean_grid(%g): surface box [%.4f, %.4f] m; shipped surf layer [%g, %g]\n",
            AS_H_IN, zb100[1], zb100[2], AS_SHIPPED_SURF[1], AS_SHIPPED_SURF[2]))
stopifnot(abs(zb100[1] - AS_SHIPPED_SURF[1]) < 1e-9,
          abs(zb100[2] - AS_SHIPPED_SURF[2]) < 1e-9)
cat("OK -- so any sigma_rep at h_ml = 100 is the closed-vs-open edge convention\n")
cat("ONLY, not a depth mismatch. That is the floor the curve must return to.\n")

# ---------------------------------------------------------------------
# THE MEASUREMENT. sigma_rep(h) = |shipped fixed-depth target - the SAME
# quantity read on the model's own box edges at h_ml = h|. `closed = FALSE`
# throughout, matching part 4: adjacent boxes must not both claim the shared
# interface depth.
# ---------------------------------------------------------------------
sep("ALKALINITY sigma_rep ACROSS h_ml")
as_sigrep <- function(d, val, flag, shipped, sd_obs) {
  v <- vapply(AS_H_SCAN, function(h) {
    gr <- ccx_ocean_grid(h); zb <- c(0, cumsum(gr$dz)); n <- length(gr$dz)
    as_grad(d, val, flag, c(0, zb[2]), c(zb[n], zb[n + 1]), FALSE)
  }, numeric(1))
  data.frame(h = AS_H_SCAN, like_for_like = v, shipped = shipped, sd_obs = sd_obs,
             sigma_rep = abs(shipped - v), ratio = abs(shipped - v) / sd_obs)
}
alk <- as_sigrep(dt, "talk", "talkf", raw$gradient$talk$target, tg$alk$sd)
# DIC on the SAME file, purely as the shape comparator for Q3. It is NOT the
# shipped DIC row (different population) and must not be quoted as one.
dic_alkpop <- as_sigrep(dt, "tco2", "tco2f", raw$gradient$tco2_alkpop$target,
                        raw$gradient$tco2_alkpop$sd)

cat(sprintf("shipped ALK target %+.4f umol/kg, sigma_obs %.4f (the row's own)\n",
            raw$gradient$talk$target, tg$alk$sd))
cat(sprintf("\n%8s %14s %12s %8s %s\n", "h_ml", "like-for-like", "sigma_rep",
            "/sigma", "note"))
for (i in seq_len(nrow(alk))) {
  h <- alk$h[i]
  note <- if (abs(h - AS_H_IN) < 1e-9) "  <- pump's own h_ml"
          else if (abs(h - AS_H_FIT) < 1e-9) "  <- quarantined mode"
          else if (h >= AS_BAND[1] && h <= AS_BAND[2]) "  in band" else ""
  cat(sprintf("%8.2f %14.4f %12.4f %8.2f %s\n", h, alk$like_for_like[i],
              alk$sigma_rep[i], alk$ratio[i], note))
}

inb  <- alk$h >= AS_BAND[1] & alk$h <= AS_BAND[2]
sep("SUMMARY -- the third column 16g sec.2.4 could not fill")
# The DIC and d13C comparators are READ FROM 16g's own saved output rather than
# transcribed from its handoff, so this table cannot drift from the run it cites
# and cannot inherit a typo from prose. Its h_ml grid is AS_H_SCAN by
# construction (that is why AS_H_SCAN was copied), so the ranges are like-for-
# like with the ALK row measured above.
rng <- function(df) {
  rt <- df$sigma_rep / df$sd_obs; i <- df$h >= AS_BAND[1] & df$h <= AS_BAND[2]
  c(inband = sprintf("%.2f-%.2f", min(rt[i]), max(rt[i])),
    all    = sprintf("%.2f-%.2f", min(rt),    max(rt)))
}
cat(sprintf("%-34s %10s %10s\n", "row", "in band", "all h_ml"))
if (file.exists(AS_PRIOR_RDS)) {
  pr <- readRDS(AS_PRIOR_RDS)$sigma_rep
  stopifnot(!is.null(pr$dic), !is.null(pr$d13c))
  for (nm in c(dic = "DIC ", d13c = "d13C")) {
    r <- rng(pr[[if (nm == "DIC ") "dic" else "d13c"]])
    cat(sprintf("%-34s %10s %10s   <- 16g part 4\n",
                sprintf("%s sigma_rep/sigma_obs", nm), r[["inband"]], r[["all"]]))
  }
} else {
  cat(sprintf("(%s absent -- DIC/d13C comparators omitted rather than\n",
              basename(AS_PRIOR_RDS)))
  cat(" transcribed from prose.)\n")
}
ralk <- rng(alk)
cat(sprintf("%-34s %10s %10s   <- THIS FILE\n", "ALK  sigma_rep/sigma_obs",
            ralk[["inband"]], ralk[["all"]]))

sep("PREDICTIONS SCORED")
q1 <- max(alk$ratio)
q2 <- max(alk$ratio[inb])
q3 <- stats::cor(alk$sigma_rep, dic_alkpop$sigma_rep)
score <- function(tag, val, bar, ok, what)
  cat(sprintf("%-4s %-46s %8.3f  bar %-8.2f %s\n", tag, what, val, bar,
              if (ok) "PASS" else "FAIL"))
score("Q1", q1, AS_Q1_MAX_RATIO, q1 < AS_Q1_MAX_RATIO,
      "max sigma_rep/sigma_obs over all h_ml")
score("Q2", q2, AS_Q2_MAX_INBAND, q2 < AS_Q2_MAX_INBAND,
      "max sigma_rep/sigma_obs in band")
score("Q3", q3, AS_Q3_MIN_R, q3 > AS_Q3_MIN_R,
      "r(ALK sigma_rep, DIC-on-ALK-pop sigma_rep)")

saveRDS(list(alk = alk, dic_alkpop = dic_alkpop, band = AS_BAND,
             h_scan = AS_H_SCAN, gate_gaps = gaps,
             shipped_alk = raw$gradient$talk,
             predictions = list(Q1 = c(val = q1, bar = AS_Q1_MAX_RATIO),
                                Q2 = c(val = q2, bar = AS_Q2_MAX_INBAND),
                                Q3 = c(val = q3, bar = AS_Q3_MIN_R))),
        file.path(AS_OUTDIR, "alk_sigma_rep.rds"))
cat(sprintf("\nwritten: %s\n", file.path(AS_OUTDIR, "alk_sigma_rep.rds")))
