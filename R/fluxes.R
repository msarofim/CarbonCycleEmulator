# =====================================================================
# fluxes.R -- the flux trace: the gross fluxes the model already computes,
# made readable.
#
# WHY THIS EXISTS. ccx_run() emitted stocks and ratios only. add_flux() computes
# every gross flux in the model and then discarded them, which had two costs:
#
#   [1] The central pedagogical quantity was not computable from model output.
#       The "CO2 only lasts 5 years" argument IS an argument about gross fluxes
#       -- turnover time tau_turn = M_atm / F_gross_out is ~4 yr, while the
#       ADJUSTMENT time of a mass perturbation is decades to centuries (measured
#       in calibration/diag_pedagogy.R: 4.32 yr against 26 % of a pulse still
#       airborne at 100 yr). Without a flux trace the model could demonstrate
#       the second but could not print the first, and the whole point is that
#       one model produces BOTH numbers.
#   [2] The app's box diagram had six unlabelled arrows. An unlabelled arrow
#       teaches nothing; ~120 GtC/yr of photosynthesis next to ~11 GtC/yr of
#       emissions teaches the entire fallacy at a glance.
#
# HOW IT AVOIDS BECOMING A SECOND MODEL. Nothing here re-derives a flux. The
# recorder is a tap INSIDE ccx_deriv()'s own add_flux/add_source, so the numbers
# reported are by construction the numbers integrated. test-fluxes.R asserts
# that the recorded per-box carbon sums equal dy[, "C"] EXACTLY -- which is both
# the completeness check on this file and a free extra conservation check on the
# model core.
#
# EDGES ARE CLASSIFIED BY THE RESERVOIR TYPE OF THEIR ENDPOINTS, not by a label
# at each call site. A flux added to the model in future is therefore captured
# automatically rather than silently dropped. Explicit labels exist only where
# one endpoint PAIR carries two physically distinct processes that must not be
# merged: seasonal NEP against GPP (both atm->leaf), the land-use transfer
# against autotrophic respiration (both wood->atm), and the ENSO anomaly against
# heterotrophic respiration (both soil->atm).
# =====================================================================

# Channel -> what it is, in the app's words. Labels derive from this table:
# nothing downstream may name a channel in prose without reading it from here.
CCX_FLUX_CHANNELS <- c(
  foss     = "Fossil emissions",
  gpp      = "Photosynthesis (gross)",
  ra       = "Plant respiration",
  litter   = "Litterfall to soil",
  rh       = "Soil respiration",
  seas     = "Seasonal growth cycle",
  # `enso` RETIRED 2026-09-02. The ENSO land anomaly was a signed flux
  # soil_fast -> atmosphere and had a channel of its own; it is now a ONE-WAY
  # MODULATION of the GPP limbs (R/model.R), so it no longer names an edge and
  # a channel for it could only ever report zero -- which is the silent-gate
  # shape, not a diagnostic. The anomaly is gamma_enso_land_<h> * forc$enso,
  # available directly to anyone who wants it, and it is INSIDE `gpp` here.
  luc      = "Land-use change",
  as_down  = "Air to sea (gross)",
  as_up    = "Sea to air (gross)",
  ml_int   = "Surface ocean to deep (net)",
  pump     = "Biological pump (export)",
  int_exch = "Interior ocean exchange (gross)",
  conv_ml  = "Conveyor surface limb",
  # THE EQUATORIAL CELL'S surface-divergence limb, cell -> mixed layer
  # (2026-09-13g), LABELLED at the call site: both boxes are class "ml", so
  # without the label it would land in conv_ml. Its two companion limbs
  # (layer k_eq -> cell, ML -> layer k_eq) classify into ml_int on their own,
  # which keeps "surface ocean to deep (net)" right under the cell.
  eq_ml    = "Equatorial cell to surface (gross)",
  # THE TROPICAL BOX's lateral exchange with the residual mixed layer, `q_tr`
  # (2026-09-14f; structural 0 under ruling R4, so this channel reads 0 until
  # that later test). Labelled at the call site for the same reason as eq_ml.
  # The cell -> tr limb keeps the eq_ml label ("to surface"); tr -> layer k_eq
  # and the tr / layer-1 diffusion classify into ml_int on their own.
  tr_ml    = "Tropical box to mixed layer (gross)",
  ihx_NS   = "Atmosphere NH to SH (gross)",
  ihx_SN   = "Atmosphere SH to NH (gross)"
)

# Derived quantities. Kept here, not in the app, so the app cannot invent its
# own definition of "the land sink".
#   land_net  = atmosphere -> land, net, ALL land channels including LUC
#   ocean_net = atmosphere -> ocean, net
#   tau_turn  = atmospheric carbon / gross flux OUT of the atmosphere = the
#               TURNOVER TIME, i.e. the number the "5-year residence time"
#               argument quotes. Correct, and not the adjustment time.
CCX_FLUX_DERIVED <- c(
  land_net  = "Net land uptake",
  ocean_net = "Net ocean uptake",
  atm_out   = "Total gross flux out of the atmosphere",
  tau_turn  = "Atmospheric turnover time (yr)"
)

# The cold boxes' OWN flows (2026-09-08g), derived from the per-edge sums the
# recorder keeps beside the channels. NOT channels: the channels fold HS into
# "ml" and HD into "int" so the derived net ocean uptake stays right (see
# ccx_flux_boxclass()); these exist so the app's diagram can draw the two cold
# boxes with numbers from the model's own tap. Zero, not NA, with the structure
# off, so annual means and the completeness test need no special case.
#   hs_as_down / hs_as_up  gross air-sea into / out of the HS boxes (inside as_down/as_up)
#   hs_pump                the HS biological export HS -> HD (inside `pump`)
#   hs_hd_net              NET HS -> HD carbon, flush + pump. ⛔ CORRECTED 2026-10-12: this said
#                          "(inside ml_int)". Only the FLUSH part (hs_hd_net - hs_pump) is inside
#                          ml_int; the pump part is inside `pump` (a labelled edge goes to its label's
#                          channel, but every edge, labelled or not, is in `edges`). See
#                          ccx_flux_warm_route().
#   hd_int_net             NET HD -> low-latitude interior, the conduit (inside int_exch)
CCX_FLUX_HS <- c(
  hs_as_down = "Air to cold surface (gross)",
  hs_as_up   = "Cold surface to air (gross)",
  hs_pump    = "Cold-box biological export",
  hs_hd_net  = "Cold surface to cold deep (net)",
  hd_int_net = "Cold deep to interior (net)"
)

ccx_flux_hs_derive <- function(edges, pump_edges, aux) {
  z <- stats::setNames(numeric(length(CCX_FLUX_HS)), names(CCX_FLUX_HS))
  if (is.null(edges)) return(z)
  ix <- lapply(HEMIS, function(h) aux$idx[[h]])
  if (is.null(ix[[1]]$hs)) return(z)
  hs <- vapply(ix, `[[`, integer(1), "hs") + 1L
  hd <- vapply(ix, `[[`, integer(1), "hd") + 1L
  at <- vapply(ix, `[[`, integer(1), "atm") + 1L
  oc <- unlist(lapply(ix, `[[`, "oc")) + 1L
  z[["hs_as_down"]] <- sum(edges[at, hs])
  z[["hs_as_up"]]   <- sum(edges[hs, at])
  z[["hs_pump"]]    <- sum(pump_edges[hs, hd])
  z[["hs_hd_net"]]  <- sum(edges[hs, hd]) - sum(edges[hd, hs])
  z[["hd_int_net"]] <- sum(edges[hd, oc]) - sum(edges[oc, hd])
  z
}

#' Reservoir class of every box, in state-vector order
#'
#' Computed from aux$idx rather than from box names, so it cannot drift out of
#' step with the indexing the model actually uses.
ccx_flux_boxclass <- function(aux, nb) {
  cls <- rep(NA_character_, nb)
  for (h in HEMIS) {
    ix <- aux$idx[[h]]
    cls[ix$atm]       <- "atm"
    cls[ix$leaf]      <- "veg"
    cls[ix$wood]      <- "veg"
    cls[ix$soil_fast] <- "soil"
    cls[ix$soil_slow] <- "soil"
    cls[ix$ml]        <- "ml"
    cls[ix$oc]        <- "int"
    # HS is a SURFACE box and HD a deep one, so they take the existing classes
    # rather than new ones: atm<->HS is genuinely air-sea and belongs in
    # as_down/as_up, HS<->HD is a surface-to-interior exchange like ml_int, and
    # HD<->interior is interior exchange. Adding private channels would leave
    # the derived net ocean uptake wrong by exactly the HS air-sea flux -- the
    # same call, and the same reason, as the artificial sink and the ENSO limbs.
    if (!is.null(ix$hs)) cls[ix$hs] <- "ml"
    if (!is.null(ix$hd)) cls[ix$hd] <- "int"
    # The equatorial cell (2026-09-13g) is a SURFACE box on the same reasoning
    # as HS: atm<->eq is genuinely air-sea and belongs in as_down/as_up.
    if (!is.null(ix$eq)) cls[ix$eq] <- "ml"
    # ... and the tropical surface box (2026-09-14f), likewise a SURFACE box.
    if (!is.null(ix$tr)) cls[ix$tr] <- "ml"
    # The INERT soil box (2026-09-30) is soil. It has no fluxes, so it never
    # appears on an edge; classifying it keeps the guard below meaningful.
    if (!is.null(ix[[CCX_LAND_INERT]])) cls[ix[[CCX_LAND_INERT]]] <- "soil"
  }
  if (anyNA(cls)) stop("ccx_flux_boxclass: unclassified box(es) at ",
                       paste(which(is.na(cls)), collapse = ", "))
  cls
}

ccx_flux_zero <- function() stats::setNames(numeric(length(CCX_FLUX_CHANNELS)),
                                            names(CCX_FLUX_CHANNELS))

#' Which channel does an edge belong to, and with what sign?
#'
#' Returns NULL for an edge that carries no carbon between two DIFFERENT
#' reservoir classes and has no channel (there are none today; the NULL branch
#' exists so a future same-class flux fails the test-fluxes.R completeness
#' assertion loudly instead of being absorbed into a neighbouring channel).
#'
#' @param from,to box indices; `from = 0L` marks an external source
#' @param lab explicit label, or NULL
#' @param cls reservoir class vector from ccx_flux_boxclass()
#' @param atmN index of the NH atmosphere box
ccx_flux_channel <- function(from, to, lab, cls, atmN) {
  if (!is.null(lab)) return(list(ch = lab, sign = 1))
  if (from == 0L) return(list(ch = "foss", sign = 1))
  a <- cls[from]; b <- cls[to]
  key <- paste0(a, ">", b)
  switch(key,
    "atm>veg"  = list(ch = "gpp",     sign =  1),
    "veg>atm"  = list(ch = "ra",      sign =  1),
    "veg>soil" = list(ch = "litter",  sign =  1),
    "soil>atm" = list(ch = "rh",      sign =  1),
    "atm>ml"   = list(ch = "as_down", sign =  1),
    "ml>atm"   = list(ch = "as_up",   sign =  1),
    "ml>int"   = list(ch = "ml_int",  sign =  1),
    "int>ml"   = list(ch = "ml_int",  sign = -1),
    "int>int"  = list(ch = "int_exch", sign = 1),   # GROSS magnitude, see below
    "ml>ml"    = list(ch = "conv_ml", sign =  1),
    "atm>atm"  = if (from == atmN) list(ch = "ihx_NS", sign = 1)
                 else              list(ch = "ihx_SN", sign = 1),
    NULL)
}

#' Snapshot of every flux in the model at one state, as a channel vector
#'
#' Thin wrapper on ccx_deriv(record = TRUE) -- it does not compute anything
#' itself, which is the point.
ccx_flux_snapshot <- function(y, t, p, forc, grid, aux) {
  dy <- ccx_deriv(y, t, p, forc, grid, aux, record = TRUE)
  fl <- attr(dy, "fluxes")
  c(ccx_flux_derive(fl$channels, y, aux), ccx_flux_hs_derive(fl$edges, fl$pump_edges, aux))
}

#' Append the derived quantities to a channel vector
#'
#' TURNOVER TIME is defined here and nowhere else. It is atmospheric carbon
#' divided by the GROSS flux leaving the atmosphere -- photosynthesis plus
#' air-sea invasion. Interhemispheric exchange is EXCLUDED: it moves carbon from
#' one atmosphere box to the other, so it is not a loss from "the atmosphere"
#' and including it would inflate the gross outflux by ~2x and halve the
#' reported turnover time. Seasonal NEP is excluded for a different reason --
#' it integrates to zero over a year and is signed, so it belongs to neither
#' direction.
ccx_flux_derive <- function(ch, y, aux, m_atm = NULL) {
  # `m_atm` given = the month-mean atmospheric carbon of the RK4-weighted trace (ccx_flux_trace());
  # absent = read off the state, as a single snapshot does.
  if (is.null(m_atm)) {
    atm <- unlist(lapply(HEMIS, function(h) aux$idx[[h]]$atm))
    m_atm <- sum(y[atm, "C"])
  }
  atm_out <- ch[["gpp"]] + ch[["as_down"]]
  c(ch,
    # `- ch[["enso"]]` DROPPED 2026-09-02 with the channel: the ENSO land
    # anomaly is now folded into `gpp`, so subtracting it here would remove it
    # twice. The identity is otherwise unchanged.
    land_net  = unname(ch[["gpp"]] + ch[["seas"]] -
                       ch[["ra"]] - ch[["rh"]] - ch[["luc"]]),
    ocean_net = unname(ch[["as_down"]] - ch[["as_up"]]),
    atm_out   = unname(atm_out),
    tau_turn  = unname(if (atm_out > 0) m_atm / atm_out else NA_real_))
}

#' What one derivative evaluation contributes to the trace
#'
#' Everything LINEAR in the fluxes -- the channels and the cold-box flows -- plus
#' the atmospheric carbon the turnover time divides by. Being linear is what lets
#' ccx_step_rk4_traced() average them with the integrator's own weights.
ccx_flux_stage_vec <- function(fl, y, aux) {
  atm <- unlist(lapply(HEMIS, function(h) aux$idx[[h]]$atm))
  c(fl$channels, ccx_flux_hs_derive(fl$edges, fl$pump_edges, aux), .m_atm = sum(y[atm, "C"]))
}

#' One month of RK4, ALSO returning the month-mean of every traced flux
#'
#' ⭐ THE TRACE AS THE INTEGRAL THE INTEGRATOR TOOK (2026-10-12, pre-beta code
#' review; ccx_run(flux_method = "rk4")). The default trace is ONE snapshot per
#' month, at the month's opening state, on the claim that the substep mean "would
#' differ only by within-month curvature". Measured at the canonical it does not:
#' the SH seasonal mixed layer entrains hard within a month, and the snapshot's
#' mixed-layer budget read 1.208 GtC/yr in 2024 against an integrated 0.431 -- the
#' error landing in "surface ocean to deep", which the app's box diagram prints.
#' Here every stage's recorded fluxes are weighted exactly as RK4 weights its
#' derivatives (h/6 x 1, 2, 2, 1), so, the derivative being the sum of its recorded
#' edges, a month's integrated fluxes reproduce its state change to roundoff
#' (test-flux-trace-exact.R). The snapshot stays the default because the NPP
#' record (both cores) is a snapshot and test-npp-record.R holds the two together;
#' whether to move the default is Marcus's (CHANGELOG 2026-10-12 (t)).
#' The STATE path is ccx_step_rk4()'s, expression for expression: recording does
#' not change a derivative (test-fluxes.R), and `fluxes = TRUE` leaves `out`
#' identical.
#' @param k1,v1 the first stage's derivative (attribute stripped) and stage vector,
#'   already computed by the caller at the month's opening state
#' @return list(y = the month-end state, v = the month-mean stage vector)
ccx_step_rk4_traced <- function(y, t, dt, p, forc, grid, aux, substeps, k1, v1) {
  h <- dt / substeps
  stage <- function(yy, tt) {
    d <- ccx_deriv(yy, tt, p, forc, grid, aux, record = TRUE)
    v <- ccx_flux_stage_vec(attr(d, "fluxes"), yy, aux)
    attr(d, "fluxes") <- NULL
    list(d = d, v = v)
  }
  acc <- 0
  for (s in seq_len(substeps)) {
    a1 <- if (s == 1L) list(d = k1, v = v1) else stage(y, t)
    a2 <- stage(y + h / 2 * a1$d, t + h / 2)
    a3 <- stage(y + h / 2 * a2$d, t + h / 2)
    a4 <- stage(y + h * a3$d,     t + h)
    y <- y + h / 6 * (a1$d + 2 * a2$d + 2 * a3$d + a4$d)
    acc <- acc + h / 6 * (a1$v + 2 * a2$v + 2 * a3$v + a4$v)
    t <- t + h
  }
  list(y = y, v = acc / dt)
}

#' Monthly flux trace over a run, as a data.frame -- the SNAPSHOT trace
#'
#' Called by ccx_run(fluxes = TRUE) with the default flux_method = "snapshot".
#' Evaluated ONCE PER MONTH, at the month's opening state -- the same instant the
#' NPP record (both cores) and the edge hook read, which test-npp-record.R holds
#' together. ⚠ It is NOT the month's integral: at the canonical the SH seasonal
#' mixed layer entrains hard within a month, and the snapshot's mixed-layer budget
#' read 1.208 GtC/yr in 2024 against an integrated 0.431 (2026-10-12 pre-beta code
#' review). Anything that splits ocean carbon between surface and deep, or must
#' integrate to a state change, uses flux_method = "rk4" (ccx_flux_trace_rk4()).
ccx_flux_trace <- function(y_list, F, p, grid, aux) {
  n <- length(y_list)
  nm <- c(names(CCX_FLUX_CHANNELS), names(CCX_FLUX_DERIVED), names(CCX_FLUX_HS))
  m <- matrix(NA_real_, n, length(nm), dimnames = list(NULL, nm))
  for (i in seq_len(n))
    m[i, ] <- ccx_flux_snapshot(y_list[[i]], F$t[i], p, ccx_forcing_at(F, i),
                                grid, aux)[nm]
  cbind(data.frame(t = F$t[seq_len(n)]), as.data.frame(m))
}

#' Monthly flux trace over a run, as a data.frame -- the EXACT (RK4-weighted) trace
#'
#' Called by ccx_run(fluxes = TRUE, flux_method = "rk4") with the month-mean
#' stage vectors from ccx_step_rk4_traced(), one row per month. The derived
#' quantities are computed from the month means (they are linear in the channels,
#' except the turnover time, which divides the month-mean atmospheric carbon by
#' the month-mean gross outflux).
#' @param vmat matrix, one row per month, columns = ccx_flux_stage_vec()'s names
#' @param t the months' times
ccx_flux_trace_rk4 <- function(vmat, t, aux) {
  nm <- c(names(CCX_FLUX_CHANNELS), names(CCX_FLUX_DERIVED), names(CCX_FLUX_HS))
  ch_nm <- names(CCX_FLUX_CHANNELS); hs_nm <- names(CCX_FLUX_HS)
  m <- matrix(NA_real_, nrow(vmat), length(nm), dimnames = list(NULL, nm))
  for (i in seq_len(nrow(vmat))) {
    v <- vmat[i, ]
    m[i, ] <- c(ccx_flux_derive(v[ch_nm], NULL, aux, m_atm = v[[".m_atm"]]), v[hs_nm])[nm]
  }
  cbind(data.frame(t = t), as.data.frame(m))
}

#' The LOW-LATITUDE ("warm") surface-to-deep route, for a diagram that draws the
#' cold boxes separately
#'
#' ⛔ `ml_int` and `pump` are channels over EVERY surface box, the cold one
#' included (ccx_flux_boxclass() folds HS into "ml" and HD into "int"): the cold
#' box's export is inside `pump` (`hs_pump`) and its mixing flush inside `ml_int`
#' (`hs_hd_net - hs_pump`). The app's warm "to the deep" arrow drew both totals
#' while its cold arrow drew the cold route again (2026-10-12 pre-beta code
#' review). The hs_* flows are zero with the structure off, so this is the
#' identity there.
#' @param fx a row of the trace (or a named vector) carrying pump, ml_int, hs_pump, hs_hd_net
ccx_flux_warm_route <- function(fx) {
  flush <- fx[["hs_hd_net"]] - fx[["hs_pump"]]
  c(pump = fx[["pump"]] - fx[["hs_pump"]], ml_int = fx[["ml_int"]] - flush)
}

#' Annual means of a monthly flux trace
#'
#' The app and every figure use this. Monthly is kept available because the
#' seasonal channel is only legible at monthly resolution.
ccx_flux_annual <- function(fl) {
  ch <- setdiff(names(fl), c("t", "year"))
  a <- stats::aggregate(fl[ch], by = list(year = floor(fl$t)), FUN = mean)
  a[order(a$year), ]
}
