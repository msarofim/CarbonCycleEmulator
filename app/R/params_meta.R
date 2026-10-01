# =====================================================================
# params_meta.R -- the plain-English name and unit for every fitted parameter,
# and THE GATE THAT KEEPS THE TABLE FROM DRIFTING AWAY FROM THE MODEL.
#
# ⚠ WHY THIS FILE EXISTS (Marcus 2026-09-22, review item U1: "Why are many of
# the parameters NA in name and units?"). The table used to live inline in
# `output$h_params` and had been written in the ~22-name era. It still carried
# retired names (`beta`, `sigma_co2`) and had NONE of the names added since --
# the HILDA cold boxes, the pump, the seasonal mixed layer, the ENSO limb -- so
# `unname(desc[nm])` returned NA for most of the 38 rows and the public
# "Parameters" table printed a column of NAs under a heading that said these are
# the numbers the calibration fits. A hand-maintained label table against a
# moving parameter set: the same decoupling class as the constants ledger, and
# exactly the failure the project's "labels derive from named constants" rule is
# about.
#
# The table is still hand-written -- a plain-English gloss cannot be derived
# from CCX_PARAM_TABLE, which carries transforms, boxes and priors and no prose.
# What is new is that IT CANNOT SILENTLY GO SHORT: app_validate_param_meta()
# fails on any fitted name without an entry, and on any entry for a name that is
# neither fitted nor declared retired. tests/testthat/test-app-params-table.R
# runs it against the shipped table and MUTATION-TESTS it.
#
# ⚠ SOURCING ORDER. Shiny auto-sources app/R/*.R BEFORE global.R, so nothing
# here may evaluate a CCX_* or APP_* object at load time. Everything below is
# either a literal or a function body.
# =====================================================================

#' Plain-English description and unit for each fitted parameter
#'
#' One row per name in `CCX_PARAM_NAMES`. `unit` is "—" for dimensionless
#' quantities, which is what the table prints.
APP_PARAM_META <- list(
  # ---- land -----------------------------------------------------------
  beta_max      = list(desc = "CO₂ fertilisation, maximum boost", unit = "—"),
  fert_k        = list(desc = "CO₂ needed for half that boost",
                       unit = "ppm above preindustrial"),
  q10           = list(desc = "Soil respiration's response to warming", unit = "—"),
  npp_frac_NH   = list(desc = "Northern share of plant growth", unit = "—"),
  luc_scale     = list(desc = "Scale on the historical land-use emissions", unit = "—"),

  # ---- air-sea exchange and the upper ocean ---------------------------
  k_w           = list(desc = "Air-sea gas transfer speed", unit = "m/yr"),
  h_ml          = list(desc = "Ocean mixed-layer depth", unit = "m"),
  kz            = list(desc = "Deep-ocean mixing rate, below the mixed layer",
                       unit = "m²/yr"),
  kz_deep_frac  = list(desc = "Mixing in the deepest layers, as a fraction of that rate",
                       unit = "—"),
  tau_ex        = list(desc = "Time for air to mix between the hemispheres", unit = "yr"),

  # ---- the HILDA cold high-latitude boxes ------------------------------
  h_hs          = list(desc = "Depth of the cold high-latitude surface box", unit = "m"),
  u_hs          = list(desc = "Exchange speed between that cold box and the deep ocean",
                       unit = "m/yr"),
  hs_asx_frac   = list(desc = "Gas exchange in the cold box, relative to the open ocean",
                       unit = "—"),

  # ---- the biological pump ---------------------------------------------
  pump_export   = list(desc = "Biological pump: carbon sinking out of the surface ocean",
                       unit = "GtC/yr"),
  pump_hs_gcm2  = list(desc = "The same export in the cold high-latitude box, per unit area",
                       unit = "gC/m²/yr"),
  pump_grad     = list(desc = "Preindustrial deep-minus-surface carbon gradient the pump holds up",
                       unit = "µmol/kg"),

  # ---- circulation limbs ------------------------------------------------
  w_eq          = list(desc = "Equatorial upwelling cell strength", unit = "Sv"),
  gamma_eq      = list(desc = "How strongly El Niño modulates that cell",
                       unit = "per index unit"),
  w_vent        = list(desc = "Ventilation loop strength", unit = "Sv"),
  gamma_vent    = list(desc = "How strongly El Niño modulates the ventilation loop",
                       unit = "per index unit"),
  w_thc         = list(desc = "Overturning (deep return) strength", unit = "Sv"),
  w_enso_l2     = list(desc = "El Niño upwelling limb, third ocean layer",
                       unit = "Sv per index unit"),

  # ---- the seasonal cycle ------------------------------------------------
  seas_T_amp_NH = list(desc = "Northern land seasonal temperature swing",
                       unit = "K, half-amplitude"),
  seas_T_amp_SH = list(desc = "Southern land seasonal temperature swing",
                       unit = "K, half-amplitude"),
  seas_lag_p_NH = list(desc = "Northern lag between sunlight and peak plant growth",
                       unit = "month"),
  seas_lag_p_SH = list(desc = "Southern lag between sunlight and peak plant growth",
                       unit = "month"),
  sst_seas_amp_NH = list(desc = "Northern sea-surface seasonal temperature swing",
                         unit = "K, half-amplitude"),
  sst_seas_amp_SH = list(desc = "Southern sea-surface seasonal temperature swing",
                         unit = "K, half-amplitude"),
  ent_seas_amp_SH = list(desc = "Southern seasonal entrainment of carbon-rich water",
                         unit = "µmol/kg, half-amplitude"),

  # ---- ENSO -------------------------------------------------------------
  gamma_enso_land_NH = list(desc = "ENSO land sensitivity, north",
                            unit = "GtC/yr per index unit"),
  gamma_enso_land_SH = list(desc = "ENSO land sensitivity, south",
                            unit = "GtC/yr per index unit"),
  gamma_enso_ocn_NH  = list(desc = "ENSO ocean sensitivity, north",
                            unit = "GtC/yr per index unit"),
  gamma_enso_ocn_SH  = list(desc = "ENSO ocean sensitivity, south",
                            unit = "GtC/yr per index unit"),

  # ---- radiocarbon and the likelihood ------------------------------------
  bomb_total    = list(desc = "Total bomb ¹⁴C released by weapons testing", unit = "kmol"),
  sigma_d14c    = list(desc = "Δ¹⁴C mismatch allowance", unit = "‰"),
  rep_dC        = list(desc = "Station-versus-box CO₂ offset (see Known issues, card 1)",
                       unit = "ppm"),
  grad_off_co2  = list(desc = "Station-versus-box offset on the north-south CO₂ gradient",
                       unit = "ppm"),
  grad_off_d13c = list(desc = "Station-versus-box offset on the north-south δ¹³C gradient",
                       unit = "‰"),

  # ---- the GATED names (2026-10-01): fitted only under a structure that opens the gate
  # (R/calibrate.R CCX_PARAM_GATED; the D2 / D3 label, the canonical from hilda33d). Labels
  # drafted 2026-10-01 for Marcus's review (app text is his).
  ndep_ret             = list(desc = "Carbon stored per unit of nitrogen deposited on land",
                              unit = "kg C per kg N"),
  npp_tsens            = list(desc = "Plant growth's response to warming", unit = "per °C"),
  imb_share_land       = list(desc = "Share of the carbon budget's unexplained gap assigned to the land",
                              unit = "—"),
  imb_share_ocean_rest = list(desc = "Ocean's share of the gap the land does not take", unit = "—"),

  # ---- RETIRED, label kept ------------------------------------------------
  # These left CCX_PARAM_NAMES but their labels stay so that a run against a
  # pre-retirement posterior still renders prose instead of NA. Any name here
  # must ALSO be in APP_PARAM_META_RETIRED, or the gate rejects the table --
  # which is what stops a live name quietly becoming a dead one.
  beta          = list(desc = "CO₂ fertilisation strength (log form, retired 2026-08-14)",
                       unit = "—"),
  sigma_co2     = list(desc = "CO₂ mismatch allowance (retired 2026-08-15)", unit = "ppm"),
  sigma_d13c    = list(desc = "δ¹³C mismatch allowance (retired 2026-08-18)", unit = "‰"),
  tau_soil_fast = list(desc = "Responsive soil turnover time (retired with the four-pool land)",
                       unit = "yr")
)

#' Names this table may carry that the build no longer fits
APP_PARAM_META_RETIRED <- c("beta", "sigma_co2", "sigma_d13c", "tau_soil_fast")

#' GATE: does the label table cover exactly the parameter set, and no more?
#'
#' A function rather than inline test expectations so that
#' tests/testthat/test-app-params-table.R can MUTATION-TEST it -- break a table
#' and confirm this rejects it. A gate that has only ever passed has not been
#' shown to be a gate (project rule).
#'
#' @param names the fitted parameter names, i.e. `CCX_PARAM_NAMES`
#' @param meta a table in `APP_PARAM_META`'s shape
#' @param retired names allowed to appear in `meta` but not in `names`
#' @return character(0) if valid, else one string per problem
app_validate_param_meta <- function(names, meta = APP_PARAM_META,
                                    retired = APP_PARAM_META_RETIRED) {
  bad <- character(0)
  if (!is.character(names) || !length(names))
    return("the parameter-name vector is empty")
  missing <- setdiff(names, base::names(meta))
  if (length(missing))
    bad <- c(bad, sprintf("fitted parameter(s) with no label: %s",
                          paste(missing, collapse = ", ")))
  # the GATED names (2026-10-01) are this build's too, fitted only under a structure that opens
  # the gate: their labels are not "extra" when `names` is a holding structure's set. Read at CALL
  # time (this file is sourced before R/ in the app; see SOURCING ORDER above).
  gated <- if (exists("CCX_PARAM_GATED")) base::names(get("CCX_PARAM_GATED")) else character(0)
  extra <- setdiff(setdiff(base::names(meta), names), c(retired, gated))
  if (length(extra))
    bad <- c(bad, sprintf("label(s) for name(s) this build does not fit, and not declared retired: %s",
                          paste(extra, collapse = ", ")))
  for (n in intersect(names, base::names(meta))) {
    e <- meta[[n]]
    for (f in c("desc", "unit"))
      if (!is.character(e[[f]]) || length(e[[f]]) != 1L || !nzchar(e[[f]]))
        bad <- c(bad, sprintf("%s: %s is missing or empty", n, f))
  }
  if (anyDuplicated(base::names(meta)))
    bad <- c(bad, "duplicate names in the label table")
  bad
}

#' The parameters table the "Under the hood" tab prints
#'
#' Values come from the running parameter vector; a name the vector does not
#' carry prints "—" in the value column rather than being dropped, because a
#' likelihood-only parameter is still one of the numbers the calibration fits.
#' ⚠ When the gate fails, the table says so IN PLACE OF the rows: a label table
#' that has gone short is a defect the page should report, not paper over.
app_param_table <- function(names, values, meta = APP_PARAM_META, extra = character(0)) {
  # `extra` (2026-10-01): the GATED names a mode fits on top of the table (R/calibrate.R
  # CCX_PARAM_GATED; the D2/D3 canonical from hilda33d). The base set stays CCX_PARAM_NAMES --
  # Marcus's U1 (09-22): every parameter the build carries has a row, the held ones included.
  names <- c(names, setdiff(extra, names))
  problems <- app_validate_param_meta(names, meta)
  if (length(problems))
    return(data.frame(
      Problem = c(paste("The parameter label table does not match this build,",
                        "so the table below is not shown. This is a bug —",
                        "please report it."),
                  problems),
      check.names = FALSE))
  v <- vapply(names, function(n) {
    x <- values[[n]]
    if (is.null(x)) NA_real_ else as.numeric(x)[1]
  }, numeric(1))
  data.frame(
    Parameter = vapply(names, function(n) meta[[n]]$desc, ""),
    Value = ifelse(is.na(v), "—", formatC(v, digits = 3, format = "g")),
    Units = vapply(names, function(n) meta[[n]]$unit, ""),
    row.names = NULL, check.names = FALSE)
}
