# =====================================================================
# plots_review.R -- the panels on the "Known issues" tab.
#
# One panel per card that has something to show. Every number annotated on
# these panels comes from the review computations in review.R, which measure
# the RUNNING model through the same gate kernels the scorecard uses -- nothing
# here is a literal, because a tab about the model's defects is the last place
# that should quietly go stale.
#
# CONVENTION: a panel that cannot be computed returns rv_plot_unavailable(),
# which renders the reason. It never returns an empty plot and it never falls
# back to a stored number.
# =====================================================================

# ⚠ THE PALETTE IS LOOKED UP AT CALL TIME, NOT AT LOAD TIME. Shiny auto-sources
# app/R/*.R in an order that depends on locale collation ("plots.R" vs
# "plots_review.R" sort differently under C and en_US), so a top-level
# `RV_COL_MODEL <- PAL[["model"]]` here fails with "object 'PAL' not found" on
# some machines and works on others. One palette, resolved when a plot is drawn.
RV_COL_MODEL <- function() PAL[["model"]]
RV_COL_OBS   <- function() PAL[["obs"]]
RV_COL_ALT   <- function() PAL[["off"]]
RV_FAIR_BAND_ALPHA <- 0.25   # card 5a: the FaIR 5-95 % ribbon behind its dashed mean
RV_COL_BAD   <- function() PAL[["pulse"]]

rv_plot_unavailable <- function(msg) {
  ggplot() +
    annotate("text", x = 0, y = 0, hjust = 0.5, size = 4.2, colour = "grey30",
             label = paste(strwrap(paste("This measurement is unavailable:", msg),
                                   width = 60), collapse = "\n")) +
    theme_void()
}

rv_guard <- function(x, f) if (rv_failed(x)) rv_plot_unavailable(x$msg) else f(x)

# ⚠ ggplot CAPTIONS DO NOT WRAP, THEY CLIP. Every caption on this tab carries
# the card's measured numbers, so a clipped one silently deletes the evidence
# the card exists to show -- which is the worst failure mode available here.
# Wrap explicitly, at a width that fits the app's panel.
# ⚠ WRAP THE ASSEMBLED CAPTION, NOT THE EXTRA. app_provenance_caption() PREPENDS
# ~78 characters of provenance, so wrapping only the extra leaves a first line of
# prefix + full width that clips exactly where the numbers are.
# ⛔⛔ THIS WAS A CHARACTER COUNT (`RV_CAP_WIDTH <- 95`) AND BROKE SILENTLY on
# 2026-09-25 b, when app_provenance_caption() stopped taking `width` and started
# taking a panel CLASS. Nothing caught it: the review cards render only when
# their tab is opened, and `test-review-cards.R` reads ui.R as TEXT, so the whole
# file can fail to call and the suite stays green. The fix that would have caught
# it is in test-plot-text-fits.R, which now actually CALLS rv_cap().
# ⚠ The cards are 514 px, measured -- their own panel class, narrower than a
# full panel because the card has padding of its own.
RV_PANEL <- "card"
rv_cap <- function(extra) app_provenance_caption(extra, panel = RV_PANEL)

# ---------------------------------------------------------------------
# CARD 1 -- the residual against Mauna Loa, before and after the offset
#
# TWO residual series, because the whole point of the card is that they are
# different questions: "how far is the box from the station" and "how far was
# the model from what the likelihood scored it against".
# ---------------------------------------------------------------------
rv_plot_repdc <- function() rv_guard(rv_rep_dc(), function(x) {
  d <- rbind(
    data.frame(t = x$year, r = x$resid_box,
               who = "Model box − Mauna Loa"),
    data.frame(t = x$year, r = x$resid_scored,
               who = "What the calibration scored (box − offset − Mauna Loa)"))
  ggplot(d, aes(t, r, colour = who)) +
    geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.4) +
    geom_hline(yintercept = x$rep_dC, colour = RV_COL_BAD(),
               linetype = "dashed", linewidth = 0.5) +
    # ⭐ THE MEASURED OFFSET, as a second reference line (Marcus 2026-09-22,
    # K3/N3). The card's whole claim is that the fitted offset is much larger
    # than the one that exists; drawing both is what lets a reader see the gap
    # instead of being told about it. RV_REP_OBS_* are OBSERVATIONS and do not
    # move with a refit; everything model-dependent below is computed.
    geom_hline(yintercept = RV_REP_OBS_MEAN, colour = RV_COL_OBS(),
               linetype = "dotted", linewidth = 0.6) +
    geom_point(size = 0.45, alpha = 0.6) +
    # ⚠ TWO LABELS, TWO CORNERS. Both used to be anchored at the left: the
    # fitted one in the EMPTY BAND between the point clouds (y = rep_dC/2,
    # which is where that band happens to be) and the measured one on its own
    # line just below it -- and with the measured line added on 2026-09-22 they
    # overlapped and neither could be read. The fitted label keeps the band at
    # the left; the measured one goes to the RIGHT edge, on its own line. They
    # cannot collide because they share neither an x anchor nor a y.
    # geom_label, not annotate("text"): the measured line sits INSIDE the lower
    # point cloud, and only an opaque box is legible there.
    annotate("text", x = min(x$year), y = x$rep_dC / 2, hjust = 0, vjust = 0.5,
             size = 3.4, colour = RV_COL_BAD(),
             label = sprintf("fitted station offset %.2f ppm (prior sd %.1f ppm)",
                             x$rep_dC, x$prior_sd)) +
    annotate("label", x = max(x$year), y = RV_REP_OBS_MEAN, hjust = 1, vjust = 0.5,
             size = 3.1, colour = RV_COL_OBS(), fill = "white", alpha = 0.85,
             # linewidth, not label.size (2026-10-13): ggplot2 4.0 dropped label.size, so 4.0.2 IGNORED it
             # ("Ignoring unknown parameters") and drew a border round the box. linewidth = 0 is the 4.0 form.
             linewidth = 0, label.padding = unit(0.12, "lines"),
             label = sprintf("measured offset %.2f ppm", RV_REP_OBS_MEAN)) +
    scale_colour_manual(values = stats::setNames(
      c(RV_COL_ALT(), RV_COL_MODEL()),
      c("Model box − Mauna Loa",
        "What the calibration scored (box − offset − Mauna Loa)"))) +
    guides(colour = guide_legend(nrow = 2)) +
    labs(x = LAB_YEAR, y = "Difference from Mauna Loa (ppm)",
         caption = rv_cap(sprintf(paste(
           "Means over %d monthly observations: box %+.2f ppm, scored %+.2f ppm (RMS %.2f).",
           "The fitted offset is %.1fx the measured one, an excess of %+.2f ppm",
           "(about %.0f GtC of airborne carbon). The measured value is the NOAA",
           "marine-boundary-layer reference minus these stations; it excludes Mauna",
           "Loa, so the northern half of it is independent of this comparison."),
           x$n, x$mean_box, x$mean_scored, x$rmse_scored,
           x$rep_dC / RV_REP_OBS_MEAN, x$rep_dC - RV_REP_OBS_MEAN,
           (x$rep_dC - RV_REP_OBS_MEAN) * ccx_const("GtC_PER_PPM")))) +
    theme_ccx()
})

# ---------------------------------------------------------------------
# CARD 2 -- the two interhemispheric gradients side by side
#
# The CO2 gradient is drawn BESIDE the d13C one deliberately: "the isotopic
# gradient is twice observed" means something quite different when the CO2
# gradient between the same two stations is right, and a panel showing only the
# d13C half invites the wrong diagnosis (transport) over the right one
# (isotopic loading).
# ---------------------------------------------------------------------
rv_plot_gradient <- function() rv_guard(rv_gradients(), function(x) {
  g <- x$g; ho <- x$ho
  d <- data.frame(
    what  = factor(rep(c("CO₂ gradient (ppm)", "δ¹³C gradient (‰)"), each = 2),
                   levels = c("CO₂ gradient (ppm)", "δ¹³C gradient (‰)")),
    who   = factor(rep(c("Measured", "Model"), 2), levels = c("Measured", "Model")),
    value = c(ho$co2$mean, g$co2, ho$d13c$mean, g$d13c),
    se    = c(ho$co2$se, NA, ho$d13c$se, NA))
  ratio <- c(g$co2 / ho$co2$mean, g$d13c / ho$d13c$mean)
  ggplot(d, aes(who, value, fill = who)) +
    geom_col(width = 0.6) +
    geom_errorbar(aes(ymin = value - se, ymax = value + se), width = 0.18,
                  colour = "grey25", na.rm = TRUE) +
    facet_wrap(~what, scales = "free_y") +
    scale_fill_manual(values = stats::setNames(c(RV_COL_OBS(), RV_COL_MODEL()),
                                               c("Measured", "Model"))) +
    labs(x = NULL, y = "Mauna Loa minus South Pole",
         caption = rv_cap(sprintf(
           "Model/measured: CO₂ %.2f×, δ¹³C %.2f×. Error bars are the observed standard error.",
           ratio[1], ratio[2]))) +
    theme_ccx() + theme(legend.position = "none")
})

# ---------------------------------------------------------------------
# CARD 3 -- the hemispheric air-sea disequilibrium, model vs GLODAP bottles
# ---------------------------------------------------------------------
# ⭐ 2026-10-15 (Marcus: "The chart makes it look like the problem is mostly in the two cold boxes, and it isn't
# obvious from the chart that this is a symmetry problem"). The issue is the AREA-WEIGHTED hemisphere averages and
# their difference (gate D's own quantity), so that panel now comes FIRST, with the measured difference's standard
# error; the four boxes follow. The cold boxes are the largest misfits box by box, but they cover little area.
RV_DISEQ_PANEL_HEMI <- "Hemisphere averages"
RV_DISEQ_PANEL_BOX  <- "The four boxes"
rv_plot_diseq <- function() rv_guard(rv_gateD(), function(x) {
  reg <- c("NH_ml", "NH_hs", "SH_ml", "SH_hs")
  reg <- reg[reg %in% names(x$region) & reg %in% names(x$obs_region)]
  pretty <- c(NH_ml = "North,\nmixed layer", NH_hs = "North,\ncold box",
              SH_ml = "South,\nmixed layer", SH_hs = "South,\ncold box")
  hemi <- c("North", "South", "North\nminus south")
  lab_obs <- "GLODAP bottles"; lab_mod <- "Model"
  d <- rbind(
    data.frame(panel = RV_DISEQ_PANEL_HEMI, region = hemi, who = lab_obs, se = c(NA, NA, x$se),
               value = c(x$obs_hemi[["NH"]], x$obs_hemi[["SH"]], x$obs_asym)),
    data.frame(panel = RV_DISEQ_PANEL_HEMI, region = hemi, who = lab_mod, se = NA,
               value = c(x$hemi[["NH"]], x$hemi[["SH"]], x$asym)),
    data.frame(panel = RV_DISEQ_PANEL_BOX, region = pretty[reg], who = lab_obs, se = NA,
               value = as.numeric(x$obs_region[reg])),
    data.frame(panel = RV_DISEQ_PANEL_BOX, region = pretty[reg], who = lab_mod, se = NA,
               value = as.numeric(x$region[reg])))
  d$panel  <- factor(d$panel, levels = c(RV_DISEQ_PANEL_HEMI, RV_DISEQ_PANEL_BOX))
  d$region <- factor(d$region, levels = c(hemi, unname(pretty[reg])))
  d$who    <- factor(d$who, levels = c(lab_obs, lab_mod))
  dodge <- position_dodge(width = 0.72)
  ggplot(d, aes(region, value, fill = who)) +
    geom_col(position = dodge, width = 0.66) +
    geom_errorbar(aes(ymin = value - se, ymax = value + se), position = dodge, width = 0.25,
                  colour = "grey25", na.rm = TRUE) +
    geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.4) +
    facet_grid(~ panel, scales = "free_x", space = "free_x") +
    scale_fill_manual(values = stats::setNames(c(RV_COL_OBS(), RV_COL_MODEL()),
                                               c(lab_obs, lab_mod))) +
    labs(x = NULL, y = "Air–sea δ¹³C disequilibrium (‰)",
         caption = rv_cap(sprintf(
           paste("North-minus-south asymmetry (area-weighted hemisphere averages): model",
                 "%+.3f‰ against %+.3f ± %.3f‰ measured. The model has the right overall size",
                 "and too little of the difference."),
           x$asym, x$obs_asym, x$se))) +
    theme_ccx()
})

# ---------------------------------------------------------------------
# CARD 4a -- the interannual growth anomaly, model vs observed
# ---------------------------------------------------------------------
rv_plot_variance <- function() rv_guard(rv_variability(), function(x) {
  n <- min(length(x$years), length(x$obs_anom), length(x$model_anom))
  d <- rbind(
    data.frame(year = x$years[seq_len(n)], v = as.numeric(x$obs_anom)[seq_len(n)],
               who = "Measured"),
    data.frame(year = x$years[seq_len(n)], v = as.numeric(x$model_anom)[seq_len(n)],
               who = "Model"))
  v <- x$verdict
  ggplot(d, aes(year, v, colour = who)) +
    geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.4) +
    geom_line(linewidth = 0.7) +
    scale_colour_manual(values = stats::setNames(c(RV_COL_OBS(), RV_COL_MODEL()),
                                                 c("Measured", "Model"))) +
    labs(x = LAB_YEAR, y = "Growth-rate anomaly (GtC/yr)",
         caption = rv_cap(paste(sprintf(
           paste("Standard deviation: model %.3f against %.3f ± %.3f measured",
                 "— %.2f×. Same detrending applied to both."),
           v$sd_model, v$sd_obs, v$se_obs, v$ratio),
           # N7 (Marcus 2026-09-22): "commonalities between the years it over-
           # and undershoots?" The answer that matters is this one -- the model
           # is MORE ENSO-correlated than the record is, so the variance it is
           # missing is not ENSO-shaped. Computed, so it cannot go stale.
           if (is.null(x$enso)) "" else sprintf(
             paste("These anomalies track the ENSO index at r %+.2f for the model",
                   "and %+.2f for the measurements (n = %d) — the model is if anything",
                   "more El Niño-driven than the record, so what is missing from its",
                   "variance is not El Niño-shaped."),
             x$enso$r_model, x$enso$r_obs, x$enso$n)))) +
    theme_ccx()
})

# ---------------------------------------------------------------------
# CARD 4b -- the ENSO sensitivity: full model, knockout, and the budget
#
# The knockout line is the argument. Without it a reader cannot tell that the
# solubility path alone has the WRONG SIGN and that the mechanism is what
# carries the response -- which is the reason the mechanism was adopted over
# the fitted coefficients it replaced.
# ---------------------------------------------------------------------
rv_plot_enso <- function() rv_guard(rv_enso_slope(), function(x) {
  mk <- function(f, who) data.frame(index = f$index, anom = as.numeric(f$anom), who = who)
  lab_obs  <- "Global Carbon Budget"
  lab_full <- "Model, full"
  lab_sol  <- "Model, ocean ENSO mechanisms off"
  d <- rbind(mk(x$obs, lab_obs), mk(x$full, lab_full), mk(x$sol, lab_sol))
  d$who <- factor(d$who, levels = c(lab_obs, lab_full, lab_sol))
  # ⭐ 2026-10-15 (Marcus: the lines did not show what the card says). The budget's fitted line was drawn FIRST,
  # dark, and lay under the model's (slopes 1.05x apart), so only the model and the knockout were visible. It is
  # now drawn LAST and dashed, so agreement shows as two lines that coincide.
  lty <- stats::setNames(c("22", "solid", "solid"), c(lab_obs, lab_full, lab_sol))
  ggplot(d, aes(index, anom, colour = who, linetype = who)) +
    geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.3) +
    geom_point(size = 0.9, alpha = 0.5) +
    geom_smooth(data = d[d$who != lab_obs, ], method = "lm", formula = y ~ x, se = FALSE, linewidth = 0.8) +
    geom_smooth(data = d[d$who == lab_obs, ], method = "lm", formula = y ~ x, se = FALSE, linewidth = 1.1) +
    scale_colour_manual(values = stats::setNames(
      c(RV_COL_OBS(), RV_COL_MODEL(), RV_COL_BAD()), c(lab_obs, lab_full, lab_sol))) +
    scale_linetype_manual(values = lty) +
    guides(colour = guide_legend(nrow = 2), linetype = guide_legend(nrow = 2)) +
    labs(x = "ENSO index (Niño 3.4, annual mean)",
         y = "Ocean uptake anomaly (GtC/yr)",
         caption = rv_cap(paste(sprintf(
           paste("Slope per index unit: budget %+.3f ± %.3f, model %+.3f ± %.3f",
                 "(%.2f×). With the ocean's ENSO mechanisms off the model gives",
                 "%+.3f — the wrong sign, which is why the mechanism matters."),
           x$obs$slope, x$obs$se, x$full$slope, x$full$se, x$ratio, x$sol$slope),
           # A4 (2026-10-01): the numbers behind card 4's "a little below the
           # range observed" -- live, from the mode file and the data product
           if (is.null(x$w_obs) || !x$w_enso_l2 > 0) "" else sprintf(
             paste("The upwelling limb's fitted strength is %.1f Sv per index unit;",
                   "the observed range is %g–%g (Meinen et al. 2001)."),
             x$w_enso_l2, x$w_obs[1], x$w_obs[2])))) +
    theme_ccx()
})

# ---------------------------------------------------------------------
# CARD 5a -- the impulse response against the Joos et al. 2013 curve
# ---------------------------------------------------------------------
rv_plot_irf <- function() rv_guard(rv_pulse(), function(x) {
  lab_m <- "This model"; lab_j <- "Joos et al. 2013 multi-model mean"
  # FaIR on the same PD100 protocol (2026-10-12): dashed, as standard FaIR is on the Futures tab
  lab_f <- x$fair_label
  d <- rbind(
    data.frame(t = x$t, f = x$irf, who = lab_m),
    data.frame(t = x$t, f = joos_irf(x$t), who = lab_j),
    data.frame(t = x$fair$t, f = x$fair$irf, who = lab_f))
  labs3 <- c(lab_m, lab_j, lab_f)
  d$who <- factor(d$who, levels = labs3)
  # the FaIR band (Marcus 2026-10-12, "Draw the band"), drawn FIRST so every line sits on top of it
  band <- data.frame(t = x$fair$t, lo = x$fair$lo, hi = x$fair$hi, who = x$fair_band_label)
  ggplot(d, aes(t, f, colour = who, linetype = who)) +
    geom_ribbon(data = band, aes(x = t, ymin = lo, ymax = hi, fill = who), inherit.aes = FALSE,
                alpha = RV_FAIR_BAND_ALPHA) +
    scale_fill_manual(values = stats::setNames(RV_COL_ALT(), x$fair_band_label), name = NULL) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = stats::setNames(c(RV_COL_MODEL(), RV_COL_OBS(), RV_COL_ALT()), labs3)) +
    scale_linetype_manual(values = stats::setNames(c("solid", "solid", "22"), labs3)) +
    # two rows: on one, the FaIR label is clipped at card width (rendered 2026-10-12)
    guides(colour = guide_legend(nrow = 2, byrow = TRUE), linetype = guide_legend(nrow = 2, byrow = TRUE)) +
    labs(x = "Years after the pulse",
         y = "Fraction of the pulse still in the air",
         caption = rv_cap(paste0(
           paste(sprintf("At %d yr: %.3f vs %.3f.", x$horizons, x$read, x$joos),
                 collapse = "  "),
           "  A comparison, not a test — nothing from this source scores the model."))) +
    expand_limits(y = c(0, 1)) +   # Marcus 2026-10-02 (carbotopecomment): "the y axis should run zero to 1"
    theme_ccx() +
    # the band's key on a row of its own: beside the two-row line legend it clipped both (rendered 2026-10-12)
    theme(legend.box = "vertical")
})

# ---------------------------------------------------------------------
# CARD 5b -- where the pulse ends up after a thousand years
# ---------------------------------------------------------------------
rv_plot_partition <- function() rv_guard(rv_pulse(), function(x) {
  cmp <- x$partition; res <- names(cmp$share)
  pretty <- c(land = "Land", ocean = "Ocean", air = "Air")
  d <- rbind(
    data.frame(where = pretty[res], who = "This model",
               value = as.numeric(cmp$share), lo = NA, hi = NA),
    data.frame(where = pretty[res], who = "Joos et al. 2013",
               value = vapply(res, function(k) cmp$joos[[k]][["mean"]], numeric(1)),
               # 2026-10-02: Joos's PUBLISHED range, +-2 s.d. (it was drawn as "+-1 sd"; DG_L_JOOS)
               lo = vapply(res, function(k) cmp$joos[[k]][["mean"]] - 2 * cmp$joos[[k]][["sd"]], numeric(1)),
               hi = vapply(res, function(k) cmp$joos[[k]][["mean"]] + 2 * cmp$joos[[k]][["sd"]], numeric(1))))
  d$where <- factor(d$where, levels = unname(pretty[res]))
  d$who <- factor(d$who, levels = c("Joos et al. 2013", "This model"))
  ggplot(d, aes(where, value, fill = who)) +
    geom_col(position = position_dodge(width = 0.72), width = 0.66) +
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.16, colour = "grey25",
                  position = position_dodge(width = 0.72), na.rm = TRUE) +
    scale_fill_manual(values = stats::setNames(c(RV_COL_OBS(), RV_COL_MODEL()),
                                               c("Joos et al. 2013", "This model"))) +
    labs(x = NULL, y = sprintf("Share of the pulse at %d years (%%)", RV_IRF_HORIZON),
         caption = rv_cap(sprintf(
           paste("In the multi-model spread's own standard deviations: %s.",
                 "Bars are Joos et al.'s published \u00b12 sd range."),
           paste(sprintf("%s %+.2f", pretty[res], cmp$z), collapse = ", ")))) +
    theme_ccx()
})

# ---------------------------------------------------------------------
# CARD 6 -- RETIRED 2026-10-01 (Marcus: "Retire card 6"). Its panel,
# rv_plot_control(), drew the canonical's and the seas_ml-0 control's northern
# seasonal cycles and captioned the AIC difference "in the simpler version's
# favour" whatever its sign. See the note in review.R; id 6 is the bands card since the renumbering.
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# CARD 8 -- the ocean's climate effect, year by year, against the GCB 2025 ocean models (2026-10-08 j)
#
# Both series are GCB's "A - C" (each ocean model's climate as observed minus its own "normal year", CO2
# prescribed): for this model, the mean over the ten GOBM protocols it emulates. Read from the card's product
# (rv_ocean_climate()); every number in the captions is the product's. Annual values thin, an RV_OCLIM_RUN-year
# centred mean thick (the H2 driver's own window, so the line the eye follows is the one the emergence is read on).
# ---------------------------------------------------------------------
rv_plot_oclim <- function() rv_guard(rv_ocean_climate(), function(x) {
  s <- x$shape; e <- x$effect
  lab_m <- "This model"; lab_g <- "Global Carbon Budget 2025 ocean models"
  run <- function(v) as.numeric(stats::filter(v, rep(1 / RV_OCLIM_RUN, RV_OCLIM_RUN), sides = 2))
  d <- rbind(data.frame(year = s$years, v = s$ccx, r = run(s$ccx), who = lab_m),
             data.frame(year = s$years, v = s$gcb, r = run(s$gcb), who = lab_g))
  d$who <- factor(d$who, levels = c(lab_g, lab_m))
  ggplot(d, aes(year, colour = who)) +
    geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
    geom_line(aes(y = v), linewidth = 0.35, alpha = 0.55) +
    geom_line(aes(y = r), linewidth = 1.0, na.rm = TRUE) +
    scale_colour_manual(values = stats::setNames(c(RV_COL_OBS(), RV_COL_MODEL()), c(lab_g, lab_m))) +
    labs(x = NULL, y = "Ocean uptake change (GtC/yr)",
         caption = rv_cap(sprintf(paste(
           "%d–%d: %.2f GtC/yr here (%.2f to %.2f across the ten ocean-model setups), %.2f ± %.2f in",
           "the ocean models; per degree of sea-surface warming %.1f ± %.1f times as strong. Below %.1f",
           "GtC/yr from %d here, from %d in the ocean models. Thick lines: %d-year means. A comparison, not a test."),
           e$window[1], e$window[2], e$ccx[["mean"]], e$ccx[["max"]], e$ccx[["min"]], e$gcb[["mean"]], e$gcb[["sd"]],
           s$per_K_ratio[["ratio"]], s$per_K_ratio[["se"]], s$emergence[["threshold"]],
           as.integer(s$emergence[["ccx"]]), as.integer(s$emergence[["gcb"]]), RV_OCLIM_RUN))) +
    theme_ccx()
})

# CARD 8b -- what it is worth: CO2 in 2300, lower by this much if this ocean's warming response were the ocean
# models' size (its sea-surface warming response scaled by f, unrefitted; bars = the ocean models' +-1 sigma).
RV_OCLIM_SCEN <- c(vvH = "High", vvM = "Medium")   # SSP5-8.5 removed (Marcus 2026-10-15)
rv_plot_oclim_stake <- function() rv_guard(rv_ocean_climate(), function(x) {
  t <- x$stake$table
  t <- t[match(names(RV_OCLIM_SCEN), t$scenario), ]
  d <- data.frame(scen = factor(RV_OCLIM_SCEN[t$scenario], levels = RV_OCLIM_SCEN),
                  v = -t$d_2300, lo = -pmax(t$d_2300_gcb_lo_sd, t$d_2300_gcb_hi_sd),
                  hi = -pmin(t$d_2300_gcb_lo_sd, t$d_2300_gcb_hi_sd))
  ggplot(d, aes(scen, v)) +
    geom_col(fill = RV_COL_MODEL(), width = 0.6) +
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.16, colour = "grey25") +
    labs(x = NULL, y = "Lower CO₂ in 2300 (ppm)",
         caption = rv_cap(sprintf(paste(
           "Of %s ppm. The model's response to sea-surface warming scaled by %.2f (%.2f to %.2f for the",
           "ocean models' ±1 sd, the bars), nothing refitted: the fit to the past would move too."),
           paste(sprintf("%.0f", t$base_2300), collapse = " / "), x$stake$f[["f_T"]],
           x$stake$f[["f_T_lo"]], x$stake$f[["f_T_hi"]]))) +
    theme_ccx()
})
