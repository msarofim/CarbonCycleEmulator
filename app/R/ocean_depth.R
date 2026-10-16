# =====================================================================
# ocean_depth.R -- THE OCEAN BY DEPTH in the pulse lab's partition panels (Marcus 2026-10-16)
#
# The two partition panels (the extra carbon; the pulse's tagged atoms) split "ocean" into an
# upper, an intermediate and a deep group built from the model's existing boxes. DISPLAY ONLY:
# no model, parameter or calibration change. Motivated by the 2026-10-15 analysis showing that
# the tagged atoms' long tail in the air is set by slow mixing into the ocean below ~900 m.
#
# MARCUS'S RULINGS (2026-10-16, this session):
#   * groups: UPPER = the mixed layer + the polar surface box HS + interior layers oc1-oc3;
#     INTERMEDIATE = oc4-oc6; DEEP = oc7-oc10. The mixed layer and oc1 share a group because the
#     seasonal mixed layer entrains from oc1, and a boundary there would move carbon across it
#     every season.
#   * the polar deep box HD is SPLIT BY DEPTH ("B: HD split by depth"). HD is one well-mixed box
#     under HS, spanning HS's bottom to the floor at constant area, so its carbon is uniform in
#     depth and its share of each group is the share of its thickness inside that group. That is
#     what makes "below 900 m" literally true of the model.
#     ⚠ HS's thickness is FITTED at the canonical (`h_hs` ~293.5 m at hilda31w, R/model.R
#     ccx_prepare()), NOT h_ml: HD therefore starts at ~293.5 m and splits ~0 / 18 / 82 %. The
#     numbers first put to Marcus assumed HD started at h_ml (6 / 17 / 77 %); corrected here.
#   * both panels get the split; colors are one sequential blue, light = upper (plots.R PAL).
#   * BUILT BY ANNUAL RESTARTS ("Annual restarts (Recommended)"). The model's monthly `$out`
#     carries only the ocean TOTAL, so the core is re-run in one-year segments from saved states,
#     continuing the ENSO history and T_deep exactly as app/global.R's APP_FLUX does, and every
#     band of both panels is drawn at those instants. No core output column is added.
#
# WHAT IS CHECKED, AND WHERE EACH BOUND COMES FROM (tests/testthat/test-pulse-ocean-depth.R):
#   * the weights PARTITION the ocean: every ocean box's weights sum to 1, no other box has one,
#     and a box the groups do not cover is refused by name -- identity, at float tolerance;
#   * the chained states reproduce the unsplit run: guarded HERE on every call (below), against
#     a bound from the integrator's own roundoff accumulation, so a broken continuation cannot
#     draw;
#   * the three groups sum to the panel's ocean total at every instant -- identity at summation
#     roundoff -- and to the CURRENT ocean band (ccx_tag_partition(), the `$out` difference) at
#     the chain bound.
# =====================================================================

# The three groups, top to bottom. ⚠ ORDER IS LOAD-BEARING: the legend, the stack and the
# colors (plots.R PAL ocean_upper / ocean_mid / ocean_deep) all follow it.
OCEAN_DEPTH_GROUPS <- c("upper", "intermediate", "deep")
# The LAST interior layer of each group but the deepest; the deep group is everything below.
# The boundaries are those layers' BOTTOMS on the run's own grid (R/model.R ccx_ocean_grid(),
# which derives every thickness from the fitted h_ml): 295 m and 914 m at hilda31w.
OCEAN_DEPTH_LAST_LAYER <- c(upper = 3L, intermediate = 6L)
# Instants are mid-year (`year + 0.5`), plus the pulse year's start, so the release shows as a
# ramp from zero. The 2026-10-15 reference numbers were read at the same instants.
OCEAN_DEPTH_INSTANT_OFFSET <- 0.5
# The legend rounds each boundary to this many meters ("~300 m", "~900 m"); the split itself
# uses the exact layer bottoms.
OCEAN_DEPTH_LABEL_ROUND_M <- 100
# THE CHAIN GUARD's per-step factor: a restarted run differs from the unsplit one by roundoff
# accumulated over the integrator's steps, at most ~ eps per step (linear, worst case). The bound
# is that law times the run's step count -- months x substeps -- RELATIVE to each total. Measured
# 2026-10-15 (scratch tagged_tail/02_runs.R): 4.3e-15, against ~1e-11 from this law.
OCEAN_DEPTH_CHAIN_EPS <- .Machine$double.eps
# The pulse lab releases its pulse within ONE calendar year (app/server.R adds it to one year's
# emissions). It sets the tagged panel's closure law, lambda^2 Delta^2 / 8 (R/c14_tag.R).
PULSE_RELEASE_WIDTH_YR <- 1

#' Each box's top and bottom, in meters, for the ocean boxes the depth split knows
#'
#' The low-latitude column is the mixed layer over N_INTERIOR interior layers (grid$dz). The
#' polar column is HS over HD at the SAME floor: HS spans [0, h_hs] and HD [h_hs, floor], which
#' is how ccx_prepare() sizes them (`dz_hd = sum(grid$dz) - h_hs`).
app_ocean_box_extents <- function(aux, grid) {
  bot <- cumsum(grid$dz); top <- c(0, utils::head(bot, -1L))
  ext <- data.frame(box = c("ml", paste0("oc", seq_len(grid$nl))), top = top, bottom = bot)
  if (isTRUE(aux$hs_on == 1L)) {
    floor_m <- sum(grid$dz)
    stopifnot(is.finite(aux$h_hs), aux$h_hs > 0, isTRUE(all.equal(aux$dz_hd, floor_m - aux$h_hs)))
    ext <- rbind(ext, data.frame(box = c("hs", "hd"), top = c(0, aux$h_hs),
                                 bottom = c(aux$h_hs, floor_m)))
  }
  ext
}

#' The depth boundaries of the groups: c(0, bottom of the upper group, of the intermediate, floor)
app_ocean_depth_bounds <- function(grid, last = OCEAN_DEPTH_LAST_LAYER) {
  stopifnot(identical(names(last), utils::head(OCEAN_DEPTH_GROUPS, -1L)),
            all(diff(c(0L, last)) > 0), max(last) < grid$nl)
  bot <- cumsum(grid$dz)
  c(0, bot[1L + last], sum(grid$dz))       # bot[1] is the mixed layer's bottom, bot[1 + k] oc_k's
}

#' The weight matrix that splits each box's carbon among the depth groups
#'
#' @param spin a spinup (aux, grid, params)
#' @param last OCEAN_DEPTH_LAST_LAYER (an argument so the test can mutate it)
#' @param drop box suffixes to leave OUT (the mutation test's "drop one box"); never in the app
#' @param validate refuse a matrix that does not partition the ocean. FALSE only in the mutation
#'   test, which must show that the sum test fails without this guard as well as with it.
#' @return matrix [state box x group]; rows are rownames(spin$y), zero for land and air
app_ocean_depth_weights <- function(spin, last = OCEAN_DEPTH_LAST_LAYER, drop = character(0),
                                    validate = TRUE) {
  aux <- spin$aux; grid <- spin$grid
  # ⛔ A MOVING HS/HD BOUNDARY HAS NO FIXED SPLIT. Under seas_ml = 2 HS deepens and shoals and
  # entrains HD, so HD's thickness inside each group changes month by month; a static split
  # would mislabel what it moves. The canonical is seas_ml = 1 (the LOW-latitude layer, which
  # stays inside oc1 by the P8 guard and so inside the upper group). Refused, not approximated.
  if (ccx_seas_ml_hs_on(spin$params))
    stop("app_ocean_depth_weights(): the seasonal mixed layer is on the HS box (seas_ml = 2), so the ",
         "HS/HD boundary moves every month and HD has no fixed depth split.")
  ext <- app_ocean_box_extents(aux, grid)
  ext <- ext[!ext$box %in% drop, ]
  b <- app_ocean_depth_bounds(grid, last)
  W <- matrix(0, nrow(spin$y), length(OCEAN_DEPTH_GROUPS),
              dimnames = list(rownames(spin$y), OCEAN_DEPTH_GROUPS))
  for (h in HEMIS) for (i in seq_len(nrow(ext))) {
    nm <- paste0(h, "_", ext$box[i])
    ov <- pmax(0, pmin(ext$bottom[i], b[-1]) - pmax(ext$top[i], utils::head(b, -1L)))
    W[nm, ] <- ov / (ext$bottom[i] - ext$top[i])
  }
  if (validate) app_ocean_depth_validate(W, spin)
  W
}

#' Refuse a weight matrix that is not a partition of the ocean
#'
#' The ocean is the index set the cores sum for `ocean_C` (R/forcing.R ccx_run(): ml, oc, hs, hd,
#' eq, tr per hemisphere), read here from the same aux$idx, so a box the depth split does not
#' know about (the equatorial cell or the tropical box, off at the canonical) is named, not lost.
app_ocean_depth_validate <- function(W, spin, tol = 64 * .Machine$double.eps) {
  aux <- spin$aux
  ocean <- unlist(lapply(HEMIS, function(h)
    c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd, aux$idx[[h]]$eq,
      aux$idx[[h]]$tr)))
  rs <- rowSums(W)
  bad <- rownames(W)[ocean][abs(rs[ocean] - 1) > tol]
  if (length(bad))
    stop("app_ocean_depth_weights(): these ocean boxes are not fully assigned to a depth group: ",
         paste(bad, collapse = ", "))
  stray <- setdiff(which(rs != 0), ocean)
  if (length(stray))
    stop("app_ocean_depth_weights(): weight on boxes that are not ocean: ",
         paste(rownames(W)[stray], collapse = ", "))
  if (any(W < 0)) stop("app_ocean_depth_weights(): a negative weight")
  invisible(TRUE)
}

#' The legend keys for the three groups, from the run's own boundaries
app_ocean_depth_keys <- function(grid, last = OCEAN_DEPTH_LAST_LAYER) {
  b <- app_ocean_depth_bounds(grid, last)
  r <- function(z) format(round(z / OCEAN_DEPTH_LABEL_ROUND_M) * OCEAN_DEPTH_LABEL_ROUND_M,
                          big.mark = ",", trim = TRUE)
  stats::setNames(c(sprintf(KEY_OCEAN_UPPER_FMT, r(b[2])),
                    sprintf(KEY_OCEAN_MID_FMT, r(b[2]), r(b[3])),
                    sprintf(KEY_OCEAN_DEEP_FMT, r(b[3]))), OCEAN_DEPTH_GROUPS)
}

#' The instants of a pulse's depth split: the pulse year's start, then every mid-year to the end
app_ocean_depth_instants <- function(F, pulse_year) {
  dt <- diff(F$t[1:2])
  t_last <- max(F$t) - dt / 2            # the last row's opening state, the latest one `$out` holds
  c(pulse_year, seq(pulse_year + OCEAN_DEPTH_INSTANT_OFFSET, t_last, by = 1))
}

#' The full state at chosen instants, by restarting the core from saved states
#'
#' Runs the C++ core over F in segments that end at each instant, carrying the state, the ENSO
#' history and T_deep from one segment to the next -- the continuation app/global.R's APP_FLUX
#' uses and test-enso-lag.R's SEGMENT test proves equal to the unsplit run. The state at instant
#' `te` is `$out`'s opening state of the row whose t is te + dt/2, so the chain can be (and is)
#' checked against the unsplit run's own totals.
#'
#' @param spin the spinup the run started from (APP_SPIN)
#' @param F the forcing table the run integrated (ccx_run_coupled(keep_forcing = TRUE)$forcing)
#' @param t_inst instants, each a month boundary (app_ocean_depth_instants())
#' @return list(t, states = list of box x tracer matrices, row = the `$out` row of each instant,
#'   nsteps = months x substeps, the chain bound's step count)
app_run_states_at <- function(spin, F, t_inst) {
  F <- ccx_fill_prod_c14(F, spin)                    # what ccx_run_fast() does before every run
  prep <- ccx_run_prepare(spin)                      # marshal ONCE; same bytes as ccx_run_fast()
  dt <- diff(F$t[1:2])
  k_end <- vapply(t_inst, function(te) {
    k <- which(abs(F$t + dt / 2 - te) < dt / 100)
    if (length(k) != 1L) stop("app_run_states_at(): instant ", te, " is not a month boundary of F")
    k
  }, integer(1))
  if (is.unsorted(k_end, strictly = TRUE)) stop("app_run_states_at(): instants must increase")
  # a row subset of a data.frame drops its attributes, and the core's forcing-variant guards
  # (ENSO index, AOD mode, nuclear share, N deposition) read them: carry them onto every segment
  keep <- attributes(F)[setdiff(names(attributes(F)), c("names", "row.names", "class"))]
  seg <- function(rows) { Fs <- F[rows, ]; attributes(Fs)[names(keep)] <- keep; Fs }
  y <- spin$y; hist <- spin$enso_hist; tdeep <- spin$tdeep0
  mix <- ccx_mix_on(spin$params)
  prev <- 0L; states <- vector("list", length(k_end))
  for (j in seq_along(k_end)) {
    rows <- (prev + 1L):k_end[j]
    Fs <- seg(rows)
    r <- ccx_run_prepared(y, prep, Fs, enso_hist = hist, tdeep0 = tdeep)
    if (isTRUE(r$retried))
      stop("app_run_states_at(): a segment needed more substeps than the run's own resolution; ",
           "its state would not be the unsplit run's")
    y <- states[[j]] <- r$state
    hist <- ccx_enso_hist_after(Fs$enso, hist)
    if (mix) tdeep <- ccx_mix_tdeep_after(Fs$gmst, Fs$t, spin$params, tdeep)
    prev <- k_end[j]
  }
  list(t = t_inst, states = states, row = k_end + 1L, nsteps = nrow(F) * prep$ss)
}

#' Reservoir totals and the depth groups, from each chained state
#'
#' @return data.frame(t, atm_C, land_C, ocean_C, <group>_C ..., atm_C14, land_C14, ocean_C14,
#'   <group>_C14 ...), in state units (GtC; GtC of standard-ratio carbon for C14)
app_reservoir_series <- function(chain, spin, W) {
  aux <- spin$aux
  idx <- function(f) unlist(lapply(HEMIS, f), use.names = FALSE)
  atm   <- idx(function(h) aux$idx[[h]]$atm)
  land  <- idx(function(h) aux$idx[[h]]$land)
  ocean <- idx(function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd,
                             aux$idx[[h]]$eq, aux$idx[[h]]$tr))
  one <- function(y, tr) {
    g <- colSums(W * y[, tr])
    c(atm = sum(y[atm, tr]), land = sum(y[land, tr]), ocean = sum(y[ocean, tr]), g)
  }
  m <- t(vapply(chain$states, function(y) c(one(y, "C"), one(y, "C14")),
                numeric(2L * (3L + ncol(W)))))
  nm <- c("atm", "land", "ocean", colnames(W))
  colnames(m) <- c(paste0(nm, "_C"), paste0(nm, "_C14"))
  data.frame(t = chain$t, row = chain$row, m)
}

#' The chain guard: the largest RELATIVE difference between the chained states' totals and the
#' unsplit run's own `$out` at the matching rows, and the bound it must stay under
app_chain_mismatch <- function(series, out, nsteps) {
  cols <- c(ocean_C = "ocean_C", land_C = "land_C", ocean_C14 = "ocean_C14",
            land_C14 = "land_C14", atm_C14 = "atm_C14")
  d <- vapply(names(cols), function(s) {
    ref <- out[[cols[[s]]]][series$row]
    max(abs(series[[s]] - ref) / abs(ref))
  }, numeric(1))
  list(max = max(d), by = d, bound = nsteps * OCEAN_DEPTH_CHAIN_EPS)
}

#' The pulse lab's three runs, restarted at the depth split's instants and checked
#'
#' @param runs list(base, pulse, tagged) from app_run_coupled(..., keep_forcing = TRUE)
#' @return list(base, pulse, tagged = reservoir series, tag = the tagged run's $tag, keys, mismatch)
app_pulse_depth_runs <- function(spin, runs, pulse_year) {
  W <- app_ocean_depth_weights(spin)
  one <- function(r) {
    if (is.null(r$forcing)) stop("app_pulse_depth_runs(): run without keep_forcing = TRUE")
    ch <- app_run_states_at(spin, r$forcing, app_ocean_depth_instants(r$forcing, pulse_year))
    s <- app_reservoir_series(ch, spin, W)
    mm <- app_chain_mismatch(s, r$out, ch$nsteps)
    # ⛔ A CHAIN THAT DOES NOT REPRODUCE THE RUN DOES NOT DRAW. Each panel's other bands are this
    # run's numbers; an ocean split that came from a different integration would not add up to
    # them, and nothing on the chart would say so.
    if (!(mm$max <= mm$bound))
      stop(sprintf(paste("app_pulse_depth_runs(): the restarted run differs from the unsplit one by",
                         "%.3g (relative), above the roundoff bound %.3g"), mm$max, mm$bound))
    attr(s, "mismatch") <- mm
    s
  }
  list(base = one(runs$base), pulse = one(runs$pulse), tagged = one(runs$tagged),
       tag = runs$tagged$tag, keys = app_ocean_depth_keys(spin$grid))
}

#' The two partition panels as one long table: each reservoir's share of the pulse, by instant
#'
#' EXTRA carbon: (pulse - base) / pulse_gtc. TAGGED atoms: (tagged - pulse) 14C with decay undone
#' at the injection-weighted mean time, / the tagged GtC -- ccx_tag_partition()'s arithmetic
#' (R/c14_tag.R) at these instants. A state at instant t carries its own time t, so the undo is
#' exp(lambda (t - s_mid)) with no half-month shift.
#' @return data.frame(t, panel, where, frac); `where` has the keys in stack order. Its attribute
#'   `closure_bound` is each panel's LAW bound on |sum of shares - 1| after the release, which
#'   plot_pulse_partition() enforces: the restart chain's roundoff (2 runs x nsteps x eps x the
#'   inventory, in units of the pulse) and, for the tagged panel, the decay undo's second-order
#'   term lambda^2 Delta^2 / 8 (R/c14_tag.R).
app_pulse_partition_table <- function(dr, pulse_gtc) {
  b <- dr$base; p <- dr$pulse; g <- dr$tagged
  stopifnot(identical(b$t, p$t), identical(b$t, g$t))
  where <- c(KEY_PULSE_AIR, KEY_PULSE_LAND, unname(dr$keys[OCEAN_DEPTH_GROUPS]))
  cols  <- c("atm", "land", OCEAN_DEPTH_GROUPS)
  extra <- vapply(cols, function(cc) (p[[paste0(cc, "_C")]] - b[[paste0(cc, "_C")]]) / pulse_gtc,
                  numeric(nrow(b)))
  undo <- exp(ccx_const("LAMBDA_C14") * (g$t - dr$tag$s_mid))
  tagd <- vapply(cols, function(cc) (g[[paste0(cc, "_C14")]] - p[[paste0(cc, "_C14")]]) * undo /
                   dr$tag$gtc, numeric(nrow(b)))
  long <- function(m, panel) data.frame(t = rep(b$t, length(cols)), panel = panel,
                                        where = rep(where, each = nrow(b)), frac = as.vector(m))
  d <- rbind(long(extra, PANEL_PULSE_EXTRA), long(tagd, PANEL_PULSE_TAGGED))
  d$where <- factor(d$where, levels = where)
  d$panel <- factor(d$panel, levels = c(PANEL_PULSE_EXTRA, PANEL_PULSE_TAGGED))
  rel <- max(vapply(dr[c("base", "pulse", "tagged")], function(x) attr(x, "mismatch")$bound, numeric(1)))
  inv_C   <- max(p$atm_C + p$land_C + p$ocean_C)
  inv_C14 <- max(g$atm_C14 + g$land_C14 + g$ocean_C14)
  attr(d, "closure_bound") <- stats::setNames(c(
    2 * rel * inv_C / pulse_gtc,
    ccx_const("LAMBDA_C14")^2 * PULSE_RELEASE_WIDTH_YR^2 / 8 + 2 * rel * inv_C14 * max(undo) / dr$tag$gtc),
    c(PANEL_PULSE_EXTRA, PANEL_PULSE_TAGGED))
  d
}
