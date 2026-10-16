# =====================================================================
# Substack figures for post 2, "CarboTope II: CarboTope vs. Bad Science" (Marcus 2026-10-16: "Review the next
# substack post (attached), and make suggestions for improvements, as well as making the appropriate figures (and
# suggesting new figures if appropriate)").
#
# Rendered at Substack size, 1456 px wide = 2x the ~728 px post column, as post 1 (outputs/substack_20261015/).
#   fig1  the Pulse lab's partition panels with the ocean split by depth: the app's own plot_pulse_partition(), on
#         the runs server.R's pulse_runs() makes (Medium background vvM, 100 GtC in 2050).
#   fig2  the buffer chemistry, as a diagram; its two numbers are the model's (carbonate ion and Revelle factor in
#         the northern mixed layer, 1750 and 2024) from outputs/diagnostics/revelle_buffer_20261016_hilda31w.rds.
#   fig3  "Reason the first": Law Dome ice core (Rubino et al. 2019; data/obs_icecore.rds) and Mauna Loa annual
#         means (Scripps + NOAA GML; the app's station record), the last two millennia and 1900 on.
#   fig4  "Reason the second": Global Carbon Budget 2025, human emissions (fossil + land use) vs the atmospheric
#         increase, 1959-2024 (the app's GCB table).
#   fig5  SUGGESTED, "Reason the third": CarboTope with and without human emissions against the CO2 and d13C records
#         (the What-if tab's own counterfactual, app_run_mechanisms(off = "emissions")).
#   fig6  SUGGESTED, the Schwartz test: share left 20-270 yr after CO2 emissions stop in 2030 vs share of a 100 GtC
#         pulse left, CarboTope and FaIR 2.2.4 (calib 1.6.0), from outputs/diagnostics/zec_vs_pulse_20261015/.
# Every chart's caption is a short data credit; the post's captions are Marcus's. No RNG.
# Usage (repo root):  Rscript outputs/substack_20261016/make_figures.R
# =====================================================================
OUT_DIR  <- normalizePath(file.path("outputs", "substack_20261016"))
FIG_W_PX <- 1456L; FIG_RES <- 200L
FIG_H_PX <- c(fig1 = 900L, fig2 = 980L, fig3 = 760L, fig4 = 760L, fig5 = 820L, fig6 = 760L)
PULSE_BG <- "vvM"; PULSE_YEAR <- 2050L; PULSE_GTC <- 100
REVELLE_RDS <- file.path("outputs", "diagnostics", "revelle_buffer_20261016_hilda31w.rds")
ZEC_DIR  <- file.path("outputs", "diagnostics", "zec_vs_pulse_20261015")
ZEC_SCEN <- "vvM"                                      # the Medium background, as the pulse figures
ZOOM_FROM <- 1900L                                    # fig3: the zoomed panel's start
GCB_RATIO_YEARS <- c(2015L, 2024L)                     # fig4: the decade the ratio annotation averages
CF_YEARS <- c(1850L, 2024L)                            # fig5 window
CREDIT <- c(
  fig1 = "Source: CarboTope (beta v1.0).",
  fig2 = "Numbers: CarboTope (beta v1.0), northern warm surface water, annual means.",
  fig3 = "Data: Law Dome ice core (Rubino et al. 2019); Mauna Loa (Scripps and NOAA GML).",
  fig4 = "Data: Global Carbon Budget 2025 (Friedlingstein et al.).",
  fig5 = "Model: CarboTope (beta v1.0). Data: Mauna Loa (Scripps and NOAA GML); Law Dome (Rubino et al. 2019).",
  fig6 = "Models: CarboTope (beta v1.0); FaIR 2.2.4 (calib 1.6.0), median and 5-95 % of 841 configurations.")

suppressMessages({ library(shiny); old <- setwd("app"); source("global.R")
  for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) source(f); setwd(old) })
library(ggplot2)
stopifnot(requireNamespace("ragg", quietly = TRUE), requireNamespace("patchwork", quietly = TRUE))
save_png <- function(p, file, h, w = FIG_W_PX) {
  ragg::agg_png(file.path(OUT_DIR, file), width = w, height = h, res = FIG_RES, background = "white")
  print(p); invisible(dev.off())
}
pm <- function(s) app_plotmath_str(s)               # unicode sub/superscripts -> plotmath, one font
ann_years <- function(d, val) {                       # complete calendar years only
  a <- stats::aggregate(d[[val]], list(year = d$year), function(v) c(m = mean(v), n = length(v)))
  data.frame(year = a$year, v = a$x[, "m"])[a$x[, "n"] == 12, ]
}

# ---- fig1: the partition panels, ocean by depth (as server.R pulse_runs / pulse_depth / f_partition) ----------
yrs <- APP_PULSE_YEARS; y <- seq(yrs[1], yrs[2])
bg <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == PULSE_BG, ]
base_em <- data.frame(year = y, fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
                      luc_GtC = stats::approx(bg$year, bg$luc_GtC, xout = y, rule = 2)$y)
pulse_em <- base_em
pulse_em$fossil_GtC[pulse_em$year == PULSE_YEAR] <- pulse_em$fossil_GtC[pulse_em$year == PULSE_YEAR] + PULSE_GTC
run <- function(em, ...) app_run_coupled(APP_SPIN, PULSE_BG, yrs, PULSE_BG, emissions = em,
                                         interp_method = APP_PULSE_EMIS_METHOD, keep_forcing = TRUE, ...)
runs <- list(base = run(base_em), pulse = run(pulse_em), tagged = run(pulse_em, c14_tag_base = base_em))
depth <- app_pulse_depth_runs(APP_SPIN, runs[c("base", "pulse", "tagged")], PULSE_YEAR)
p1 <- plot_pulse_partition(app_pulse_partition_table(depth, PULSE_GTC), PULSE_GTC, PULSE_YEAR) +
  labs(caption = CREDIT[["fig1"]])
save_png(p1, "fig1_pulse_ocean_depth.png", FIG_H_PX[["fig1"]])

# ---- fig2: the buffer mechanism -------------------------------------------------------------------------------
rb <- readRDS(REVELLE_RDS); A <- rb$partA
stopifnot(identical(rb$provenance$mode, CCX_MODE_CANONICAL))
cc <- ccx_carb_coefs_for(APP_PARAMS$carb_salinity)
co3 <- function(r) { k <- carb_constants(r$T_C, cc); h <- 10^(-r$pH_total); d <- r$dic_umol_kg
  d * k$K1 * k$K2 / (h^2 + k$K1 * h + k$K1 * k$K2) }
ml <- A[A$box == "NH mixed layer", ]; ml <- ml[order(ml$year), ]
c3 <- vapply(seq_len(nrow(ml)), function(i) co3(ml[i, ]), numeric(1))
pct <- sub("-", "−", sprintf("%+.0f%%", 100 * (c3[2] / c3[1] - 1)), fixed = TRUE)
nums <- c("In CarboTope's warm surface water, 1750 → 2024:",
          sprintf("carbonate ion %.0f → %.0f µmol/kg (%s); Revelle factor %.1f → %.1f",
                  c3[1], c3[2], pct, ml$revelle[1], ml$revelle[2]))
ink <- PAL[["obs"]]; sea <- "#e8f1f8"; air <- "#f4f6f7"; accent <- PAL[["pulse"]]
txt <- function(x, y, s, size = 4.6, hjust = 0.5, colour = ink, parse = TRUE, fontface = "plain")
  annotate("text", x = x, y = y, label = if (parse) pm(s) else s, parse = parse, size = size, hjust = hjust,
           colour = colour, fontface = fontface)
arrow_dn <- function(x, y0, y1) annotate("segment", x = x, xend = x, y = y0, yend = y1, colour = ink, linewidth = 0.6,
                                         arrow = grid::arrow(length = grid::unit(2.2, "mm"), type = "closed"))
p2 <- ggplot() + xlim(0, 100) + ylim(0, 70) + theme_void() +
  annotate("rect", xmin = 0, xmax = 100, ymin = 60, ymax = 70, fill = air) +
  annotate("rect", xmin = 0, xmax = 100, ymin = 0, ymax = 60, fill = sea) +
  txt(2, 66.5, "Air", 4.4, 0, parse = FALSE, fontface = "bold") +
  txt(2, 57.0, "Surface ocean", 4.4, 0, parse = FALSE, fontface = "bold") +
  txt(28, 65, "CO₂") + arrow_dn(28, 62.5, 55.5) + txt(30, 59, "dissolves", 3.6, 0, parse = FALSE) +
  txt(28, 52, "CO₂ + H₂O → H₂CO₃ → H⁺ + HCO₃⁻", 4.4) +
  txt(28, 47.5, "carbonic acid gives up a hydrogen ion", 3.4, colour = "grey30", parse = FALSE) +
  txt(28, 40, "H⁺ + CO₃²⁻ → HCO₃⁻", 4.4) +
  txt(28, 35.5, "a carbonate ion takes it up", 3.4, colour = "grey30", parse = FALSE) +
  annotate("rect", xmin = 5, xmax = 51, ymin = 21.5, ymax = 31, fill = "white", colour = ink, linewidth = 0.5) +
  txt(28, 28.4, "Net:", 3.6, parse = FALSE, fontface = "bold") +
  txt(28, 24.4, "CO₂ + CO₃²⁻ + H₂O → 2 HCO₃⁻", 4.8) +
  txt(57, 53, "Each CO₂ taken up uses up", 3.7, 0) +
  txt(57, 49.2, "one carbonate ion. So:", 3.7, 0, parse = FALSE) +
  txt(57, 43.5, "• the next CO₂ finds fewer carbonate", 3.5, 0) +
  txt(59.2, 40, "ions, and the ocean takes up less of", 3.5, 0, parse = FALSE) +
  txt(59.2, 36.5, "each extra tonne (the Revelle factor rises)", 3.5, 0, parse = FALSE) +
  txt(57, 30.5, "• shells and corals find less carbonate:", 3.5, 0, parse = FALSE) +
  txt(59.2, 26.5, "Ca²⁺ + CO₃²⁻ ⇌ CaCO₃ (aragonite)", 3.5, 0) +
  txt(59.2, 22.8, "is pushed toward dissolving", 3.5, 0, parse = FALSE) +
  txt(50, 14.5, "Over thousands of years, seafloor CaCO₃ dissolves and returns carbonate.", 3.5, colour = "grey30") +
  txt(50, 8, nums[1], 3.5, colour = accent, parse = FALSE) +
  txt(50, 4.3, nums[2], 3.5, colour = accent, parse = FALSE) +
  labs(caption = CREDIT[["fig2"]]) +
  theme(plot.caption = element_text(size = 8, colour = "grey40", hjust = 1), plot.margin = margin(4, 8, 4, 8))
save_png(p2, "fig2_buffer_chemistry.png", FIG_H_PX[["fig2"]])

# ---- fig3: the CO2 record -------------------------------------------------------------------------------------
ice <- readRDS(file.path("data", "obs_icecore.rds"))
spl <- as.data.frame(ice$co2_spline); smp <- as.data.frame(ice$co2_samples)
mlo <- ann_years(APP_OBS$co2[APP_OBS$co2$station == "MLO", ], "co2_ppm")
WIN <- c(ice = sprintf("Since %d CE (the ice record's start)", as.integer(min(spl$year))), zoom = sprintf("Since %d", ZOOM_FROM))
d3 <- rbind(data.frame(win = WIN[["ice"]], src = "Law Dome ice core", year = spl$year, co2 = spl$co2_ppm),
            data.frame(win = WIN[["ice"]], src = "Mauna Loa", year = mlo$year, co2 = mlo$v),
            data.frame(win = WIN[["zoom"]], src = "Law Dome ice core", year = spl$year, co2 = spl$co2_ppm),
            data.frame(win = WIN[["zoom"]], src = "Mauna Loa", year = mlo$year, co2 = mlo$v))
d3 <- d3[!(d3$win == WIN[["zoom"]] & d3$year < ZOOM_FROM), ]
d3$win <- factor(d3$win, levels = WIN)
smp3 <- data.frame(win = factor(WIN[["zoom"]], levels = WIN), year = smp$age_CO2, co2 = smp$CO2ppm)
smp3 <- smp3[smp3$year >= ZOOM_FROM, ]
COL3 <- c("Law Dome ice core" = PAL[["luc_gross"]], "Mauna Loa" = PAL[["obs"]])
last <- mlo[which.max(mlo$year), ]
lab3 <- data.frame(win = factor(WIN[["zoom"]], levels = WIN), year = last$year, co2 = last$v,
                   lab = sprintf("%d: %.0f ppm", last$year, last$v))
p3 <- ggplot(d3, aes(year, co2, colour = src)) +
  geom_line(linewidth = 0.8) +
  geom_point(data = smp3, aes(year, co2), inherit.aes = FALSE, colour = COL3[["Law Dome ice core"]],
             size = 1.1, alpha = 0.7) +
  geom_text(data = lab3, aes(year, co2, label = lab), inherit.aes = FALSE, hjust = 1.1, vjust = 0.2,
            size = 3.4, colour = PAL[["obs"]]) +
  facet_wrap(~win, scales = "free_x") +
  scale_colour_manual(values = COL3, name = NULL) +
  labs(x = LAB_YEAR, y = app_plotmath(LAB_CO2), caption = CREDIT[["fig3"]]) +
  theme_ccx() + theme(legend.position = "top")
save_png(p3, "fig3_co2_record.png", FIG_H_PX[["fig3"]])

# ---- fig4: emissions vs the atmospheric increase ---------------------------------------------------------------
g <- as.data.frame(APP_OBS$gcb)
g$emis <- g$fossil + g$luc
k <- g$year >= GCB_RATIO_YEARS[1] & g$year <= GCB_RATIO_YEARS[2]
ratio <- sum(g$emis[k]) / sum(g$atm_growth[k])
SER4 <- c(emis = "Human emissions (fossil fuels + land use)", atm = "Increase in the atmosphere")
COL4 <- stats::setNames(c(PAL[["pulse"]], PAL[["atm"]]), SER4)
d4 <- rbind(data.frame(year = g$year, v = g$emis, s = SER4[["emis"]]),
            data.frame(year = g$year, v = g$atm_growth, s = SER4[["atm"]]))
SINK_LAB_AT <- c(year = 1991.5, gtc = 6.85)          # an open band: 1985-1997 increase <= 5.6, emissions >= 7.4
p4 <- ggplot() +
  geom_ribbon(data = g, aes(year, ymin = atm_growth, ymax = emis), fill = PAL[["ocean"]], alpha = 0.15) +
  geom_line(data = d4, aes(year, v, colour = s), linewidth = 0.9) +
  annotate("text", x = SINK_LAB_AT[["year"]], y = SINK_LAB_AT[["gtc"]], size = 3.6, colour = "grey25", lineheight = 0.9,
           label = "Taken up by\nland and ocean") +
  annotate("text", x = min(g$year), y = max(g$emis) * 1.02, hjust = 0, size = 3.5, colour = "grey25",
           label = sprintf("%d–%d: emissions %.1f× the increase", GCB_RATIO_YEARS[1], GCB_RATIO_YEARS[2], ratio)) +
  scale_colour_manual(values = COL4, name = NULL) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  labs(x = LAB_YEAR, y = "Carbon (GtC per year)", caption = CREDIT[["fig4"]]) +
  theme_ccx() + theme(legend.position = "top")
save_png(p4, "fig4_emissions_vs_increase.png", FIG_H_PX[["fig4"]])

# ---- fig5 (suggested): with and without human emissions --------------------------------------------------------
alt <- app_run_mechanisms(off = "emissions")
ann_model <- function(o, col) { a <- tapply(o[[col]], floor(o$t), mean); data.frame(year = as.integer(names(a)), v = as.numeric(a)) }
glob <- function(o, a, b) (o[[a]] + o[[b]]) / 2
full <- APP_HIST$out; full$co2_g <- glob(full, "co2_NH", "co2_SH"); full$d13_g <- glob(full, "d13c_NH", "d13c_SH")
alt$out$co2_g <- glob(alt$out, "co2_NH", "co2_SH"); alt$out$d13_g <- glob(alt$out, "d13c_NH", "d13c_SH")
MOD5 <- c(full = "CarboTope", none = "CarboTope without human emissions")
OBS5 <- c(ice = "Law Dome ice core", mlo = "Mauna Loa")
mk <- function(o, col, who, var) { a <- ann_model(o, col); a <- a[a$year >= CF_YEARS[1] & a$year <= CF_YEARS[2], ]
  data.frame(year = a$year, v = a$v, who = who, var = var) }
VAR5 <- c(co2 = app_plotmath_str("CO₂ (ppm)"), d13 = app_plotmath_str("δ¹³C of CO₂ (‰)"))
mlo13 <- ann_years(APP_OBS$d13[APP_OBS$d13$station == "MLO", ], "d13c")
spl13 <- as.data.frame(ice$d13c_spline)
d5m <- rbind(mk(full, "co2_g", MOD5[["full"]], VAR5[["co2"]]), mk(alt$out, "co2_g", MOD5[["none"]], VAR5[["co2"]]),
             mk(full, "d13_g", MOD5[["full"]], VAR5[["d13"]]), mk(alt$out, "d13_g", MOD5[["none"]], VAR5[["d13"]]))
inwin <- function(d) d[d$year >= CF_YEARS[1] & d$year <= CF_YEARS[2], ]
d5o <- rbind(inwin(data.frame(year = spl$year, v = spl$co2_ppm, who = OBS5[["ice"]], var = VAR5[["co2"]])),
             inwin(data.frame(year = mlo$year, v = mlo$v, who = OBS5[["mlo"]], var = VAR5[["co2"]])),
             inwin(data.frame(year = spl13$year, v = spl13$d13c, who = OBS5[["ice"]], var = VAR5[["d13"]])),
             inwin(data.frame(year = mlo13$year, v = mlo13$v, who = OBS5[["mlo"]], var = VAR5[["d13"]])))
d5m$var <- factor(d5m$var, levels = VAR5); d5o$var <- factor(d5o$var, levels = VAR5)
COL5 <- c(stats::setNames(c(PAL[["model"]], PAL[["off"]]), MOD5), stats::setNames(c(PAL[["luc_gross"]], PAL[["obs"]]), OBS5))
p5 <- ggplot() +
  geom_line(data = d5o, aes(year, v, colour = who), linewidth = 0.7, linetype = "22") +
  geom_line(data = d5m, aes(year, v, colour = who), linewidth = 1.0) +
  facet_wrap(~var, scales = "free_y", labeller = label_parsed) +
  scale_colour_manual(values = COL5, breaks = unname(c(MOD5, OBS5)), name = NULL) +
  guides(colour = guide_legend(nrow = 2, override.aes = list(linetype = c("solid", "solid", "22", "22")))) +
  labs(x = LAB_YEAR, y = NULL, caption = CREDIT[["fig5"]]) +
  theme_ccx() + theme(legend.position = "top")
save_png(p5, "fig5_with_without_emissions.png", FIG_H_PX[["fig5"]])

# ---- fig6 (suggested): the Schwartz test ------------------------------------------------------------------------
cz <- utils::read.csv(file.path(ZEC_DIR, "ccx_hilda31w_zec2030_vs_pulse100_h100.csv"))
fz <- utils::read.csv(file.path(ZEC_DIR, "fair_v160_zec2030_vs_pulse100_h100.csv"))
cz <- cz[cz$scenario == ZEC_SCEN, ]; fz <- fz[fz$scenario == ZEC_SCEN, ]
CASE6 <- c(zec = "Excess left after CO₂ emissions stop in 2030", pulse = "A 100 GtC pulse released in 2030")
d6 <- rbind(
  data.frame(model = "CarboTope", case = CASE6[["zec"]],   h = cz$horizon_yr, v = cz$excess_remaining, lo = NA, hi = NA),
  data.frame(model = "CarboTope", case = CASE6[["pulse"]], h = cz$horizon_yr, v = cz$pulse_remaining_zero_bg, lo = NA, hi = NA),
  data.frame(model = "FaIR", case = CASE6[["zec"]],   h = fz$horizon_yr, v = fz$excess_remaining_median,
             lo = fz$excess_remaining_p05, hi = fz$excess_remaining_p95),
  data.frame(model = "FaIR", case = CASE6[["pulse"]], h = fz$horizon_yr, v = fz$pulse_remaining_zero_bg_median,
             lo = fz$pulse_remaining_zero_bg_p05, hi = fz$pulse_remaining_zero_bg_p95))
d6 <- d6[order(d6$model, d6$case, d6$h), ]
COL6 <- stats::setNames(c(PAL[["obs"]], PAL[["pulse"]]), CASE6)
p6 <- ggplot(d6, aes(h, 100 * v, colour = case, linetype = model, shape = model)) +
  geom_errorbar(data = d6[!is.na(d6$lo), ], aes(ymin = 100 * lo, ymax = 100 * hi), width = 4, linewidth = 0.4,
                linetype = "solid", show.legend = FALSE) +
  geom_line(linewidth = 0.8) + geom_point(size = 2.4) +
  scale_colour_manual(values = COL6, breaks = unname(CASE6), labels = app_plotmath_labels(CASE6), name = NULL) +
  scale_x_continuous(breaks = sort(unique(d6$h))) +
  scale_linetype_manual(values = c(CarboTope = "solid", FaIR = "22"), name = NULL) +
  scale_shape_manual(values = c(CarboTope = 16, FaIR = 17), name = NULL) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(x = "Years after 2030", y = "Share still in the air (%)", caption = CREDIT[["fig6"]]) +
  guides(colour = guide_legend(nrow = 2, order = 1), linetype = guide_legend(order = 2), shape = guide_legend(order = 2)) +
  theme_ccx() + theme(legend.position = "top")
save_png(p6, "fig6_stop_vs_pulse.png", FIG_H_PX[["fig6"]])

cat(sprintf("fig2 numbers: %s\nfig3: Mauna Loa %d = %.2f ppm\nfig4: %d-%d emissions / increase = %.3f\n",
            paste(nums, collapse = " "), last$year, last$v, GCB_RATIO_YEARS[1], GCB_RATIO_YEARS[2], ratio))
cat(sprintf("fig5: CarboTope %d CO2 %.1f ppm (without human emissions %.1f); d13C %.2f (%.2f)\n", CF_YEARS[2],
            tail(d5m$v[d5m$who == MOD5[["full"]] & d5m$var == VAR5[["co2"]]], 1),
            tail(d5m$v[d5m$who == MOD5[["none"]] & d5m$var == VAR5[["co2"]]], 1),
            tail(d5m$v[d5m$who == MOD5[["full"]] & d5m$var == VAR5[["d13"]]], 1),
            tail(d5m$v[d5m$who == MOD5[["none"]] & d5m$var == VAR5[["d13"]]], 1)))
