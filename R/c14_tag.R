# =====================================================================
# c14_tag.R -- TAG A PULSE'S OWN CARBON AND FOLLOW IT (Marcus 2026-10-12)
#
# Marcus, 2026-10-12: "Add a button on the Futures panel which is a pulse but for a
# tracer to show how quickly the original carbon moves into different reservoirs (as
# versus the pulse)"; ruled the form "Side by side in pulse lab (Recommended)".
#
# THE TWO QUESTIONS ARE DIFFERENT, AND BY A LOT ([[pulse_label_vs_perturb]], 08-21):
#   PERTURBATION  how much EXTRA carbon each reservoir holds: pulse run minus no-pulse run.
#   TAG           where the pulse's OWN atoms are. Atoms mix: the air swaps carbon with
#                 land and ocean at ~200 GtC/yr each way, so the tagged atoms leave the
#                 air in years, while the EXTRA amount stays for centuries, because how
#                 much extra the ocean can hold is set by carbonate buffering, not by size.
#
# ⭐ NO FOURTH ISOTOPE IS NEEDED. The model's 14C is already an exact passive tag:
#   * transport is LINEAR in C14: every flux is F_C x (C14/C of its source box), factor 1
#     (R/model.R add_flux; src/ccx_core.cpp "no fractionation, by convention");
#   * no 14C fractionation is applied anywhere. Δ14C observations are fractionation-
#     corrected, and alpha14 = alpha13^2 is the REASON no factor is needed;
#   * decay is first-order and IDENTICAL in every box (lambda = ln 2 / 5700 yr, the true
#     half-life, NOT Libby's 5568 -- an age-reporting convention);
#   * nothing reads C13 or C14 back into a carbon flux, and the climate iteration reads CO2
#     only, so a tagged run's carbon and climate are IDENTICAL to the untagged run's.
# So with two runs that differ only by extra 14C, D = C14_tagged - C14_untagged obeys
# dD/dt = A(t) D + S - lambda D, and exp(+lambda (t - s)) D is the decay-free tag.
#
# ⚠ WHICH ATOMS. The tag is the carbon by which THIS run's emissions exceed `tag_base`'s,
# month by month and hemisphere by hemisphere (the forcing DIFFERENCE, so whatever the
# seasonalisation and interpolation do to the pulse, the tag does exactly the same).
# It is injected through the core's two existing 14C source columns, c14_bomb and
# c14_nuclear, whose NH shares differ (legacy: FORC_BOMB_NH_SHARE 0.90, FORC_NUC_NH_SHARE 0.95):
# a 2x2 solve per month puts EXACTLY the pulse's NH and SH amounts into each hemisphere.
# ⚠ PER MONTH since 2026-10-12 (label hilda_csl3v0kaidgbemwtc): the bomb share is FITTED (prior
# U[0.77, 0.98]) and the nuclear share is the forcing's PER-YEAR column (0.942-1.0), so the two can
# approach; the solve reads each month's own nuclear share and refuses any TAGGED month where they
# coincide (CCX_TAG_MIN_SHARE_GAP).
# A negative rate in one column is exact too -- the tag is linear. No core change, so no
# C++ parity entry is needed.
# =====================================================================

CCX_TAG_COLS <- c("c14_bomb", "c14_nuclear")   # the core's 14C source columns the tag rides on
CCX_TAG_MIN_SHARE_GAP <- 1e-6                  # |bomb - nuclear NH share| below which the 2x2 is singular

#' The 14C source rates that tag the carbon by which `F` exceeds `F_base`
#'
#' @param F,F_base forcing tables from ccx_build_forcing() on the same months
#' @param aux the spinup's aux (bomb_share_NH, nuc_share_NH, mol_per_GtC)
#' @return list(bomb, nuclear) mol/yr per month to ADD to F's columns; d_NH, d_SH (GtC/yr
#'   tagged per month); gtc (total tagged GtC); s_mid (injection-weighted mean time, yr)
ccx_c14_tag_rates <- function(F, F_base, aux) {
  stopifnot(nrow(F) == nrow(F_base), isTRUE(all.equal(F$t, F_base$t, tolerance = 0)))
  sb <- aux$bomb_share_NH; sn <- aux$nuc_share_NH; mpg <- aux$mol_per_GtC
  if (is.null(sb) || is.null(sn) || is.null(mpg))
    stop("ccx_c14_tag_rates(): the spinup's aux lacks bomb_share_NH / nuc_share_NH / mol_per_GtC")
  d_NH <- (F$e_foss_NH + F$e_luc_NH) - (F_base$e_foss_NH + F_base$e_luc_NH)   # GtC/yr
  d_SH <- (F$e_foss_SH + F$e_luc_SH) - (F_base$e_foss_SH + F_base$e_luc_SH)
  # the nuclear share PER MONTH: the forcing's column where finite (label ...wtc), else the aux
  # scalar -- exactly the value each core splits c14_nuclear with that month
  sn <- rep_len(sn, nrow(F))           # one share per month (the same number each month when scalar)
  if (!is.null(F[["nuc_share_NH"]])) sn <- ifelse(is.finite(F[["nuc_share_NH"]]), F[["nuc_share_NH"]], sn)
  tagged <- d_NH != 0 | d_SH != 0
  if (any(abs(sb - sn)[tagged] < CCX_TAG_MIN_SHARE_GAP))
    stop("ccx_c14_tag_rates(): the two 14C source columns share one NH split in a tagged month; ",
         "the tag cannot be placed")
  k <- mpg * ccx_const("R14_STD")      # GtC/yr of standard-ratio carbon -> mol/yr of 14C
  # b sb + n sn = d_NH k ;  b (1 - sb) + n (1 - sn) = d_SH k
  bomb    <- (d_NH * (1 - sn) - sn * d_SH) / (sb - sn) * k
  nuclear <- (sb * d_SH - (1 - sb) * d_NH) / (sb - sn) * k
  # untagged months carry nothing -- and with the two shares free to meet there, 0/0 would be NaN
  bomb[!tagged] <- 0; nuclear[!tagged] <- 0
  # F$t is MID-MONTH (ccx_build_forcing: year + (m - 0.5)/12), so a month's injection is centred ON F$t
  dt <- diff(F$t[1:2])
  w  <- d_NH + d_SH
  gtc <- sum(w) * dt
  s_mid <- if (gtc != 0) sum(w * F$t) * dt / gtc else NA_real_
  list(bomb = bomb, nuclear = nuclear, d_NH = d_NH, d_SH = d_SH, gtc = gtc, s_mid = s_mid, dt = dt)
}

#' Add the tag to a forcing table
ccx_c14_tag_apply <- function(F, rates) {
  F$c14_bomb    <- F$c14_bomb    + rates$bomb
  F$c14_nuclear <- F$c14_nuclear + rates$nuclear
  F
}

#' Where the tagged atoms are: share of the tag in air / land / ocean, decay undone
#'
#' @param tagged,untagged `$out` of the tagged and untagged runs (same carbon, by construction)
#' @param tag the run's `$tag` (ccx_run_coupled with `c14_tag_base`): gtc and s_mid
#' @return data.frame(t, air, land, ocean, total), each a FRACTION of the tagged GtC. The
#'   decay is undone at the injection-weighted mean time s_mid; for a one-year release the
#'   residual of that undo is ~ lambda^2 var(s) / 2 ~ 1e-9, so `total` is a CONSERVATION
#'   check, not a normalisation.
ccx_tag_partition <- function(tagged, untagged, tag) {
  stopifnot(is.finite(tag$gtc), tag$gtc != 0)
  # each `$out` row is the month's OPENING state (ccx_run: recorded before the step), labelled with
  # the mid-month t, so the state's own time is t - dt/2
  undo <- exp(ccx_const("LAMBDA_C14") * (tagged$t - tag$dt / 2 - tag$s_mid))
  f <- function(col) (tagged[[col]] - untagged[[col]]) * undo / tag$gtc
  d <- data.frame(t = tagged$t, air = f("atm_C14"), land = f("land_C14"), ocean = f("ocean_C14"))
  d$total <- d$air + d$land + d$ocean
  d
}
