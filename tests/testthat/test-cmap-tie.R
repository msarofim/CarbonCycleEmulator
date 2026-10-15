# =====================================================================
# Gate: the constraint map's takeaway must report a TIE as a tie.
#
# ⛔ WHY. `cm_takeaway` named one holder per row -- "mostly influenced by X" --
# for the top three rows by total. Measured at three arms (09-26), TWO of those
# three were coin flips whose winner CHANGED with the arm. Computing the sentence
# makes it MOVE, not makes it TRUE.
#
# ⭐⭐ RE-EXPRESSED 2026-10-14 (Marcus, verbatim: "Posterior winner stability (Recommended)"; gate change
# approved by that ruling; CHANGELOG 2026-10-14 c, d). A winner is named only if it holds its row in at
# least 1 - APP_CMAP_TIE_LOST_MAX of the MCMC posterior draws. The margin cuts (09-26 geometric mean;
# 10-12 basin spread, 1.923 pp) are RETIRED. At hilda31w, 100 posterior draws showed the mode's margin
# does not predict whether the winner holds: Δ¹⁴C ocean has a 70.7 pp margin and loses in 6 % of draws,
# Δ¹⁴C bomb has 10.4 pp and holds in 98 %.
# These tests RECOMPUTE the shipped shares from the posterior run they cite, so the carried numbers stay
# a measurement ([[gate_reads_its_own_output]]). They exercise the CALLER too, not only the helper
# ([[gate_tested_the_helper_not_the_caller]]).
# ⚠ A rebuilt map refuses the old stability file (ccx_cmap_stab_problems). That failure is the trigger
# to re-run calibration/diag_cmap_posterior_spread.R and promote_cmap_stability.R, not to re-pin.
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
.app <- file.path(.root, "app")
.glb <- ccx_code_lines(readLines(file.path(.app, "global.R"), warn = FALSE))
.srv <- ccx_code_lines(readLines(file.path(.app, "server.R"), warn = FALSE))

.env <- new.env(parent = globalenv())
.want <- c("app_cmap_holder_phrase", "APP_CMAP_TIE_LOST_MAX", "APP_CMAP_TIE_SRC")
for (e in parse(file.path(.app, "global.R")))
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in% .want) eval(e, .env)
.map_f  <- file.path(.root, "data", "constraint_map.rds")
.stab_f <- file.path(.root, "data", "constraint_map_stability.rds")
# the definitions, as promote_cmap_stability.R computes them: the map's winner per row, and the share of
# draws in which that winner is not the row's largest component
.cm_winner <- function(r) names(which.max(r))
.cm_lost <- function(MC, winners) {
  w0 <- apply(MC, 1, .cm_winner)
  vapply(rownames(MC), function(f) mean(winners[f, ] != w0[[f]]), numeric(1))
}

test_that("the rule is posterior stability at the band's 5 %, and the margin cuts are gone", {
  for (w in .want) expect_false(is.null(get0(w, envir = .env)), info = w)
  # 5 % = the app's own 5-95 % convention, not a fitted number
  expect_identical(.env$APP_CMAP_TIE_LOST_MAX, 0.05)
  expect_match(.env$APP_CMAP_TIE_SRC, "posterior draws", fixed = TRUE)
  expect_match(.env$APP_CMAP_TIE_SRC, "diag_cmap_posterior_spread.R", fixed = TRUE)
  # a half-revert (the old constants back, read by something) must fail here
  for (old in c("APP_CMAP_TIE_PP", "APP_CMAP_TIE_SHIFT_MAX", "APP_CMAP_TIE_ARM"))
    expect_false(any(grepl(old, c(.glb, .srv), fixed = TRUE)), info = old)
})

test_that("the phrase reports a tie as a tie and a winner as a winner, by STABILITY not margin", {
  # 2026-10-15 (Marcus: "Apply all", pins follow the changed sentence): the tie marker was "about equally"; the phrase
  # now reads "led by X (a%, though not in every posterior draw) ahead of Y (b%)" -- the logic tested is unchanged.
  f <- .env$app_cmap_holder_phrase
  close <- c(A = 21.6, B = 21.5, C = 10)      # 0.1 pp apart
  wide  <- c(A = 60, B = 10, C = 5)           # ~67 pp apart
  # stable winner -> named, however close the margin
  expect_match(f(close, 0), "mostly influenced by A", fixed = TRUE)
  expect_false(grepl("not in every posterior draw", f(close, 0), fixed = TRUE))
  # unstable winner -> a tie, however wide the margin
  expect_match(f(wide, 0.20), "not in every posterior draw", fixed = TRUE)
  expect_match(f(wide, 0.20), "A", fixed = TRUE); expect_match(f(wide, 0.20), "B", fixed = TRUE)
  # the boundary: "more than" 5 % is a tie; exactly 5 % is not
  expect_match(f(wide, 0.05), "mostly influenced by A", fixed = TRUE)
  expect_match(f(wide, 0.0500001), "not in every posterior draw", fixed = TRUE)
  # ⭐ the RUNNER-UP's share must APPEAR in the tie case. Computed from the input, not typed: the phrase
  # reports shares OF THE ROW, so c(60, 10, 5) prints 80% / 13%.
  want <- sprintf("%.0f%%", 100 * sort(wide, decreasing = TRUE)[1:2] / sum(wide))
  for (w in want) expect_match(f(wide, 0.20), w, fixed = TRUE)
  # a share that is not a share is refused, never read as "no tie"
  for (bad in list(NA_real_, -0.1, 1.5, c(0.1, 0.2))) expect_error(f(wide, bad))
})

test_that("the SERVER calls the phrase helper with the row's stability share, not which.max", {
  call <- grep("app_cmap_holder_phrase", .srv, value = TRUE)
  expect_gt(length(call), 0L)
  expect_true(all(grepl("APP_CMAP_STAB$lost_share", call, fixed = TRUE)))
  tk <- grep("cm_takeaway", .srv)
  expect_gt(length(tk), 0L)
  # no stability for THIS map -> no takeaway, rather than a margin fallback
  expect_true(any(grepl("is.null(APP_CMAP_STAB)", .srv, fixed = TRUE)))
  expect_false(any(grepl("mostly influenced by %s", .srv, fixed = TRUE)),
               info = "server re-typed the phrase instead of calling the helper")
})

test_that("ON THE REAL PRODUCT: the stability is this map's, and the top three read by it", {
  skip_if(!file.exists(.map_f), "constraint map not built")
  cm <- readRDS(.map_f)
  skip_if(length(ccx_cmap_problems(cm)) > 0L, "the map is not the canonical's (test-constraint-map 7 fails)")
  # wherever the canonical's map is, its stability must be: a missing file is a FAIL, not a skip
  expect_true(file.exists(.stab_f), info = .stab_f)
  if (!file.exists(.stab_f)) return(invisible())
  st <- readRDS(.stab_f)
  expect_identical(ccx_cmap_stab_problems(st, cm), character(0))
  environment(.env$app_cmap_holder_phrase) <- .env
  tot <- sort(rowSums(cm$MC), decreasing = TRUE)
  top <- names(tot)[1:3]
  ph  <- vapply(top, function(r) .env$app_cmap_holder_phrase(cm$MC[r, ], st$lost_share[[r]]), character(1))
  for (r in top) {
    if (st$lost_share[[r]] > .env$APP_CMAP_TIE_LOST_MAX)
      expect_match(ph[[r]], "not in every posterior draw", fixed = TRUE, info = r)
    else
      expect_match(ph[[r]], "mostly influenced", fixed = TRUE, info = r)
  }
  # as measured 2026-10-14 at hilda31w: δ¹³C level & gradient (8 %) and CO₂ level (12 %) are ties,
  # CO₂ seasonal cycle (0 %) is not. A change here is a re-measurement, re-pinned only on Marcus's word.
  expect_equal(sum(st$lost_share[top] > .env$APP_CMAP_TIE_LOST_MAX), 2L)
})

test_that("THE SHARES ARE THE MEASUREMENT: recomputed from the posterior run they cite", {
  skip_if(!file.exists(.map_f) || !file.exists(.stab_f), "map or stability not built")
  cm <- readRDS(.map_f); st <- readRDS(.stab_f); pv <- st$provenance
  src_f <- file.path(.root, pv$source)
  expect_true(file.exists(src_f), info = pv$source)
  if (!file.exists(src_f)) return(invisible())
  expect_identical(unname(tools::md5sum(src_f)), pv$source_md5)
  src <- readRDS(src_f)
  # the run was LIKE-FOR-LIKE with the shipped map, and passed its own gates
  expect_identical(src$MC_mode$MC, cm$MC)
  expect_identical(src$provenance$mode, cm$provenance$mode)
  expect_identical(unname(src$provenance$gates[c("step", "map")]), c(0, 0))
  expect_lt(src$provenance$gates[["lp"]], CCX_REPRO_TOL)
  expect_identical(ncol(src$winners), as.integer(pv$n_draws))
  # the carried shares ARE the recomputation
  expect_identical(.cm_lost(cm$MC, src$winners)[names(st$lost_share)], st$lost_share)
})

test_that("MUTATION: the gates catch a moved map, a lost row, a doctored draw and a wrong mode", {
  skip_if(!file.exists(.map_f) || !file.exists(.stab_f), "map or stability not built")
  cm <- readRDS(.map_f); st <- readRDS(.stab_f)
  src_f <- file.path(.root, st$provenance$source); skip_if(!file.exists(src_f), "source run not present")
  src <- readRDS(src_f)
  # the real pair passes
  expect_length(ccx_cmap_stab_problems(st, cm), 0L)
  # a rebuilt map (one cell moved by 1e-9 relative) refuses the stability
  cm2 <- cm; cm2$MC[1, 1] <- cm2$MC[1, 1] * (1 + 1e-9)
  expect_match(paste(ccx_cmap_stab_problems(st, cm2), collapse = " "), "different constraint map", fixed = TRUE)
  # a row dropped from the stability is caught
  st2 <- st; st2$lost_share <- st2$lost_share[-1]
  expect_match(paste(ccx_cmap_stab_problems(st2, cm), collapse = " "), "rows", fixed = TRUE)
  # a stability from another mode is caught
  st3 <- st; st3$provenance$mode <- "hilda29e"
  expect_match(paste(ccx_cmap_stab_problems(st3, cm), collapse = " "), "mode", fixed = TRUE)
  # ONE draw's winner changed for ONE row moves the recomputed share by 1 / n and fails the identity
  W <- src$winners; f <- rownames(W)[1]; w0 <- .cm_winner(cm$MC[f, ])
  j <- which(W[f, ] == w0)[1]; W[f, j] <- setdiff(colnames(cm$MC), w0)[1]
  moved <- .cm_lost(cm$MC, W)
  expect_equal(moved[[f]] - st$lost_share[[f]], 1 / ncol(W))
  expect_false(identical(moved[names(st$lost_share)], st$lost_share))
})
