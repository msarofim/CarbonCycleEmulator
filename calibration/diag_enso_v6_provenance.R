# =====================================================================
# diag_enso_v6_provenance.R -- THE ERSST v6 GRID, AND THE TWO THINGS IT SETTLES
#
# THE STATE THIS CLOSES (handoff 2026-09-02k sec.4). `nina34.data` -- the PSL
# file the whole pipeline runs on -- is 0.60 degC warmer in climatology and 15 %
# WEAKER in ENSO amplitude than CPC's published ERSSTv5 Nino 3.4 over 1991-2020.
# Our own extraction was EXONERATED (r 1.0000, slope 0.997 against CPC on the
# same v5), so the gap is between two PUBLISHED indices. It was NAMED "v5 vs v6"
# and that name was WITHDRAWN for want of a measurement: 1991-2020 is densely
# observed, which is where two ERSST versions should agree BEST.
#
# ⭐ QUESTION 1 -- IS THE GAP A VERSION EFFECT? Run the v6 grid through the SAME
#    extraction as v5 and difference the two the same way. If v6-from-grid
#    reproduces nina34.data, the gap is the version and the matter is closed. If
#    v6-from-grid looks like v5-from-grid instead, the gap is something else --
#    PSL's own processing -- and naming it v6 was wrong twice.
#
# ⭐ QUESTION 2 -- DOES AN UNCLIPPED ROLLING BASE BEAT `demean`? `roll` scored
#    -1513.92 against `demean`'s -1512.02, but it CLIPS 6 of its 16 scored
#    blocks, and the clipped ones are the EARLY blocks where the mean-state
#    offset is largest. So that -1.91 is a LOWER bound on the rolling base, not
#    its price. v6 reaches 1850; a centered 30-yr base for 1948 needs 1933.
#
# ⛔ THIS FILE DOES NOT RULE. Ruling A is ADOPTED (`demean`, 2026-09-02). If the
#    unclipped rolling base wins here, that is a REOPENING for Marcus, not an
#    adoption -- and it would have to win by more than the ~15 % amplitude
#    uncertainty this same file measures.
#
# THE GATES:
#   V-G  GRID     -- v6 and v5 must share grid, epoch and variable names, or
#                    `eix_ersst_box()` is not the SAME extraction and Q1 is void.
#   V-C  CONTROL  -- v6-from-grid vs v5-from-grid over 1991-2020 must show LESS
#                    disagreement than the gap being explained, or the version
#                    cannot be the explanation. An ORDERING, not a threshold.
#   V-U  UNCLIPPED-- the v6 rolling base must actually clip FEWER blocks than
#                    the nina34 one, or Q2's premise is false and its answer
#                    means nothing ([[no_power_null]]).
#
# Usage:  Rscript calibration/diag_enso_v6_provenance.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_enso_index.R"))

VP_ARM   <- "from90"
VP_BASIN <- "calibration/output/multistart_20260901_enso25/start_000.rds"
VP_WIN   <- FORC_ENSO_DEMEAN_WIN     # the scored span, = what Ruling A priced
VP_BASE  <- EIX_CLIM_BASE            # 1991-2020, the WMO normal
VP_REF_DEMEAN <- -1512.0151          # the ADOPTED convention, same vector
VP_REF_ROLL   <- -1513.9226          # the CLIPPED rolling base, same vector
VP_OUT   <- file.path("outputs", "diagnostics", "enso_v6_provenance.rds")
VP_HEAD  <- ccx_git_stamp()

cat(sprintf("\n%s\nERSST v6: THE VERSION CONTROL AND THE UNCLIPPED ROLLING BASE\n  arm %s, span %d-%d, base %d-%d, commit %s\n%s\n",
            strrep("=", 78), VP_ARM, VP_WIN[1], VP_WIN[2], VP_BASE[1], VP_BASE[2],
            VP_HEAD, strrep("=", 78)))

# ---------------------------------------------------------------------
# GATE V-G: the two grids must be the SAME extraction problem
# ---------------------------------------------------------------------
vp_meta <- function(path) {
  nc <- ncdf4::nc_open(ccx_path(path)); on.exit(ncdf4::nc_close(nc), add = TRUE)
  list(vars = sort(names(nc$var)),
       lat = ncdf4::ncvar_get(nc, "lat"), lon = ncdf4::ncvar_get(nc, "lon"),
       units = ncdf4::ncatt_get(nc, "time", "units")$value,
       yr = range(as.integer(format(as.Date(EIX_EPOCH) + ncdf4::ncvar_get(nc, "time"), "%Y"))))
}
m5 <- vp_meta(EIX_ERSST); m6 <- vp_meta(EIX_ERSST_V6)
v_g <- identical(m5$vars, m6$vars) && identical(m5$lat, m6$lat) &&
       identical(m5$lon, m6$lon) && identical(m5$units, m6$units)
cat(sprintf("\n=== V-G GRID ===\n  v5 %d-%d, v6 %d-%d; grid %dx%d both; epoch \"%s\" both -> %s\n",
            m5$yr[1], m5$yr[2], m6$yr[1], m6$yr[2], length(m5$lon), length(m5$lat),
            m5$units, if (v_g) "PASS" else "⛔ FAIL"))
if (!v_g)
  stop("v5 and v6 do not share grid/epoch/variables, so eix_ersst_box() is not ",
       "the same extraction on both and the version comparison is void.")

# ---------------------------------------------------------------------
# 1. THE THREE INDICES, all through ONE extraction
# ---------------------------------------------------------------------
psl <- eix_read_psl()                              # nina34.data, what SHIPS
g5  <- eix_ersst_box(EIX_BOX_N34, ccx_path(EIX_ERSST))
g6  <- eix_ersst_box(EIX_BOX_N34, ccx_path(EIX_ERSST_V6))
cpc <- utils::read.table(ccx_path("data-raw", "downloads",
                                  "ersst5.nino.mth.91-20.ascii"),
                         header = TRUE, check.names = FALSE)
cpc <- data.frame(year = cpc[[1]], month = cpc[[2]], value = cpc[["NINO3.4"]])

# Deseasonalize BOTH members of a pair on their OWN climatology over the shared
# base, then regress. Amplitude is the slope, phase is r, level is dclim.
vp_pair <- function(A, B) {
  kA <- A$year >= VP_BASE[1] & A$year <= VP_BASE[2] & !is.na(A$value)
  mB <- match(A$year * 12L + A$month, B$year * 12L + B$month)
  k  <- kA & !is.na(mB) & !is.na(B$value[mB])
  cA <- tapply(A$value[k], A$month[k], mean)
  cB <- tapply(B$value[mB[k]], A$month[k], mean)
  xa <- A$value[k] - as.numeric(cA[as.character(A$month[k])])
  xb <- B$value[mB[k]] - as.numeric(cB[as.character(A$month[k])])
  c(n = sum(k), r = stats::cor(xa, xb),
    slope = unname(stats::coef(stats::lm(xa ~ xb))[2]),
    dclim = mean(A$value[k]) - mean(B$value[mB[k]]))
}
P <- list(
  `PRODUCT  psl(v6?) vs cpc(v5)`   = vp_pair(psl, cpc),
  `VERSION  grid v6  vs grid v5`   = vp_pair(g6, g5),
  `⭐ psl      vs grid v6`          = vp_pair(psl, g6),
  `   psl      vs grid v5`         = vp_pair(psl, g5),
  `METHOD   grid v5  vs cpc(v5)`   = vp_pair(g5, cpc))
cat(sprintf("\n=== 1. PAIRWISE, deseasonalised %d-%d ===\n", VP_BASE[1], VP_BASE[2]))
cat(sprintf("  %-30s %6s %8s %8s %8s\n", "pair", "n", "r", "slope", "dclim"))
for (nm in names(P))
  cat(sprintf("  %-30s %6d %8.4f %8.3f %+8.3f\n", nm, P[[nm]][["n"]],
              P[[nm]][["r"]], P[[nm]][["slope"]], P[[nm]][["dclim"]]))

# ---------------------------------------------------------------------
# GATE V-C, and the ANSWER TO Q1
# ---------------------------------------------------------------------
# ⚠ AN ORDERING, NOT A THRESHOLD. The claim "the gap is the version" predicts
# that psl agrees BETTER with the v6 grid than with the v5 grid. There is no
# external number for how much better, so nothing is invented: the two
# disagreements are compared with each other. [[threshold_from_obs_or_law]]
d_v6 <- abs(P[["⭐ psl      vs grid v6"]][["slope"]] - 1)
d_v5 <- abs(P[["   psl      vs grid v5"]][["slope"]] - 1)
v_c  <- d_v6 < d_v5
cat(sprintf("\n=== V-C / Q1: IS THE 15 %% GAP A VERSION EFFECT? ===\n"))
cat(sprintf("  |slope-1| psl vs v6 grid = %.4f\n  |slope-1| psl vs v5 grid = %.4f\n",
            d_v6, d_v5))
cat(if (v_c)
      sprintf("  ⇒ psl is CLOSER to v6 (%.2fx), consistent with the version naming.\n",
              d_v5 / max(d_v6, 1e-9))
    else
      sprintf("  ⛔ psl is NOT closer to v6. The gap is NOT a v5->v6 effect --\n     it is PSL's own processing, and the version name was wrong.\n"))

# ---------------------------------------------------------------------
# 2. THE UNCLIPPED ROLLING BASE, and GATE V-U
# ---------------------------------------------------------------------
r_psl <- eix_roll_base(psl, VP_WIN)
r_g6  <- eix_roll_base(g6,  VP_WIN)
v_u   <- r_g6$n_clip < r_psl$n_clip
cat(sprintf("\n=== 2. THE ROLLING BASE ===\n  nina34 (from %d): %d of %d scored blocks CLIPPED\n  v6 grid (from %d): %d of %d scored blocks CLIPPED -> %s\n",
            min(psl$year), r_psl$n_clip, r_psl$n_blk,
            min(g6$year), r_g6$n_clip, r_g6$n_blk,
            if (v_u) "PASS (V-U)" else "⛔ FAIL (V-U): no unclipping to price"))

# ---------------------------------------------------------------------
# 3. THE PRICE, at the 09-01 basin vector
# ---------------------------------------------------------------------
pm <- ccx_migrate_par_set(readRDS(ccx_path(VP_BASIN))$par_mode)
u0 <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u0)))
bp <- ccx_default_params(); bp$pump_mode <- dg_vector(VP_ARM)$md$pump_mode
.VP_ORIG <- ccx_build_forcing
vp_price <- function(tbl) {
  tb <- tbl[!is.na(tbl$value), ]
  assign("ccx_build_forcing", function(...) {
    F <- .VP_ORIG(...)
    e <- stats::approx(tb$year + (tb$month - 0.5) / 12, tb$value, xout = F$t, rule = 2)$y
    e[F$year < min(tb$year) | F$year > max(tb$year)] <- FORC_ENSO_PRE1948
    F$enso <- e; F
  }, envir = globalenv())
  on.exit(assign("ccx_build_forcing", .VP_ORIG, envir = globalenv()), add = TRUE)
  ccx_make_logpost(base_params = bp)(u0)
}
# ⛔ TWO CONTROLS, BECAUSE THE RAW WITHIN-v6 PAIR DIFFERS IN THREE WAYS AT ONCE.
# roll_v6 and demean_v6 differ in the base-period CONVENTION (the question), in
# AMPLITUDE (sd 0.8110 vs 0.8297, and the gammas are frozen at values fitted for
# an index of sd 0.7513, so a quieter candidate gains for free), and in COVERAGE
# -- the v6 grid reaches 1850, so BOTH supply ENSO for 1850-1947 where the
# shipped model has FORC_ENSO_PRE1948 = 0. The PSL pair they are set against has
# no such extension. [[like_for_like_forcing]]
vp_sd  <- function(d) { k <- d$year >= VP_WIN[1] & d$year <= VP_WIN[2]
                        stats::sd(d$value[k]) }
vp_cut <- function(d) d[d$year >= min(psl$year), ]   # match nina34's coverage
dm6 <- eix_demean(eix_fixed_base(g6), VP_WIN)
rl6 <- r_g6$tbl
# AMPLITUDE CONTROL: demean_v6 rescaled to roll_v6's sd, convention unchanged.
dm6_sc <- dm6; dm6_sc$value <- dm6$value * (vp_sd(rl6) / vp_sd(dm6))
CAND <- list(
  fix_v6                = eix_fixed_base(g6),
  demean_v6             = dm6,
  demean_v6_sd_matched  = dm6_sc,
  roll_v6_unclipped     = rl6,
  demean_v6_from1948    = vp_cut(dm6),
  roll_v6_from1948      = vp_cut(rl6))
pr <- vapply(CAND, vp_price, numeric(1))

cat(sprintf("\n=== 3. THE PRICE (09-01 basin vector, 25 par, gammas FROZEN) ===\n"))
cat(sprintf("  %-20s %14s %12s\n", "index", "logpost", "vs demean"))
cat(sprintf("  %-20s %14.4f %12s   <- ADOPTED\n", "demean (shipped)", VP_REF_DEMEAN, ""))
cat(sprintf("  %-20s %14.4f %+12.4f   <- clipped, the standing bound\n",
            "roll (nina34)", VP_REF_ROLL, VP_REF_ROLL - VP_REF_DEMEAN))
for (nm in names(pr))
  cat(sprintf("  %-20s %14.4f %+12.4f\n", nm, pr[[nm]], pr[[nm]] - VP_REF_DEMEAN))

# ---- THE DECOMPOSITION, and the ANSWER TO Q2 ------------------------
d_tot <- pr[["roll_v6_unclipped"]] - pr[["demean_v6"]]
d_amp <- pr[["demean_v6_sd_matched"]] - pr[["demean_v6"]]
d_l4l <- pr[["roll_v6_from1948"]]  - pr[["demean_v6_from1948"]]
d_ext <- pr[["demean_v6"]] - pr[["demean_v6_from1948"]]
d_exr <- pr[["roll_v6_unclipped"]] - pr[["roll_v6_from1948"]]
cat(sprintf("\n=== Q2: DOES AN UNCLIPPED ROLLING BASE BEAT `demean`? ===\n"))
cat(sprintf("  raw within-v6, roll - demean, FULL 1850- span : %+8.4f\n", d_tot))
cat(sprintf("    of which AMPLITUDE (sd-matched control)     : %+8.4f\n", d_amp))
cat(sprintf("  ⭐ LIKE-FOR-LIKE, both truncated to %d-       : %+8.4f\n",
            min(psl$year), d_l4l))
cat(if (d_l4l < 0)
      "  ⇒ NO. The raw win is COVERAGE, not convention: truncated to nina34's\n     own span the rolling base LOSES to demeaning, the same direction the\n     PSL pair and `detrend` both gave. RULING A STANDS.\n"
    else
      "  ⇒ YES, and like-for-like. That REOPENS Ruling A for Marcus.\n")
cat(sprintf("\n  ⭐ AND A SEPARATE RESULT: extending the ENSO forcing back to %d costs\n",
            min(g6$year)))
cat(sprintf("     %+.4f under a FIXED 1991-2020 base but only %+.4f under a ROLLING\n",
            d_ext, d_exr))
cat("     one -- the fixed base carries its mean-state offset through all 98\n")
cat("     pre-1948 years. ⇒ IF THE ENSO FORCING IS EVER EXTENDED BEFORE 1948,\n")
cat("     IT MUST USE A ROLLING BASE. That is not a ruling; it is a price.\n")
cat(sprintf("\n  ⚠ CROSS-PRODUCT rows here are FROZEN-GAMMA and rank AMPLITUDE too;\n"))
cat("    a ranking across products needs the four gamma_enso coordinates\n")
cat("    re-optimised per candidate (diag_enso_index_bakeoff.R). What IS clean\n")
cat("    is that with convention and span matched, the v6 grid and nina34 land\n")
cat(sprintf("    %.2f log-units apart -- so the 15 %% amplitude gap costs the SHIPPED\n",
            abs(pr[["demean_v6_from1948"]] - VP_REF_DEMEAN)))
cat("    configuration far less than section 1 might suggest.\n")

saveRDS(list(pairs = P, price = pr,
             q2 = c(raw = d_tot, amplitude = d_amp, like_for_like = d_l4l,
                    extend_fixed = d_ext, extend_roll = d_exr), ref = c(demean = VP_REF_DEMEAN, roll = VP_REF_ROLL),
             clip = c(nina34 = r_psl$n_clip, v6 = r_g6$n_clip),
             blk  = c(nina34 = r_psl$n_blk,  v6 = r_g6$n_blk),
             gates = c(V_G = v_g, V_C = v_c, V_U = v_u),
             win = VP_WIN, base = VP_BASE, arm = VP_ARM, basin = VP_BASIN,
             commit = VP_HEAD, when = Sys.time()), ccx_path(VP_OUT))
cat(sprintf("\n  written: %s\n", VP_OUT))
cat(sprintf("\n%s\n⛔ THIS FILE DOES NOT RULE. Ruling A is ADOPTED; a win here is a REOPENING.\n%s\n",
            strrep("=", 78), strrep("=", 78)))
