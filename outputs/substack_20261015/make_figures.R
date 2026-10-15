# =====================================================================
# Substack figures for the CarboTope launch post (Marcus 2026-10-15: "Can you provide nicely formatted figures as
# replacements for the screenshots I made, and also select a good hero figure?").
#
# The three figures are the app's own plots, drawn by the app's own functions on the same runs the app makes
# (plot_keeling, plot_pulse_decay, plot_pulse_warming), rendered at Substack size: 1456 px wide = 2x the ~728 px
# post column. The app's in-plot footer (its provenance caption) is replaced by a short source credit; the post
# captions explain the rest. The hero is the pulse figure redrawn alone: the extra CO2 against the pulse's own
# tagged carbon atoms, direct-labeled, at the 1.91:1 link-preview ratio.
#
# Runs: the canonical mode the app runs (CCX_MODE_CANONICAL), history = APP_HIST; the pulse is the pulse lab's
# default (Medium background vvM, 100 GtC released in 2050), built exactly as server.R's pulse_runs().
# Usage (repo root):  Rscript outputs/substack_20261015/make_figures.R
# =====================================================================
OUT_DIR <- normalizePath(file.path("outputs", "substack_20261015"))
FIG_W_PX <- 1456L; FIG_RES <- 200L                    # 7.28 in at 200 dpi
FIG_H_PX <- c(keeling = 760L, pulse = 760L, warming = 800L)   # warming: its long y title met the credit at 700
HERO_W_PX <- 1456L; HERO_H_PX <- 762L                 # 1.91:1
PULSE_BG <- "vvM"; PULSE_YEAR <- 2050L; PULSE_GTC <- 100
KEELING_YEARS <- c(2009, 2024)                        # the window of Marcus's screenshot
CREDIT <- "Source: CarboTope (beta v1.0)."

# Shiny sources app/R/*.R itself; a script must do it (alphabetical, as Shiny does)
suppressMessages({ library(shiny); old <- setwd("app"); source("global.R")
  for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) source(f); setwd(old) })
stopifnot(requireNamespace("ragg", quietly = TRUE))
save_png <- function(p, file, h, w = FIG_W_PX) {
  ragg::agg_png(file.path(OUT_DIR, file), width = w, height = h, res = FIG_RES, background = "white")
  print(p); invisible(dev.off())
}
credit <- ggplot2::labs(caption = CREDIT)

# ---- Figure 1: the Keeling curve, both stations, 2009-2024 ----
p1 <- plot_keeling(APP_HIST$out, APP_OBS, KEELING_YEARS, "both", TRUE) + credit
save_png(p1, "fig1_keeling.png", FIG_H_PX[["keeling"]])

# ---- the pulse pair + the tagged run, as server.R's pulse_runs() ----
yrs <- APP_PULSE_YEARS
bg <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == PULSE_BG, ]
y <- seq(yrs[1], yrs[2])
base_em <- data.frame(year = y,
                      fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
                      luc_GtC    = stats::approx(bg$year, bg$luc_GtC,    xout = y, rule = 2)$y)
pulse_em <- base_em
pulse_em$fossil_GtC[pulse_em$year == PULSE_YEAR] <- pulse_em$fossil_GtC[pulse_em$year == PULSE_YEAR] + PULSE_GTC
run <- function(em, ...) app_run_coupled(APP_SPIN, PULSE_BG, yrs, PULSE_BG, emissions = em,
                                         interp_method = APP_PULSE_EMIS_METHOD, ...)
base <- run(base_em); pulse <- run(pulse_em); tagged <- run(pulse_em, c14_tag_base = base_em)
fair <- app_fair_pulse(PULSE_BG, PULSE_YEAR, PULSE_GTC)
stopifnot(!is.null(fair), nrow(fair) > 0)

# ---- Figure 2: share of the pulse still in the air, with the tagged atoms and FaIR ----
p2 <- plot_pulse_decay(base$climate, pulse$climate, PULSE_YEAR, PULSE_GTC,
                       tag = list(out = tagged$out, tag = tagged$tag), pulse_out = pulse$out, fair = fair) + credit
save_png(p2, "fig2_pulse_airborne.png", FIG_H_PX[["pulse"]])

# ---- Figure 3: the pulse's warming, with FaIR ----
p3 <- plot_pulse_warming(base$climate, pulse$climate, PULSE_YEAR, PULSE_GTC, fair = fair) + credit
save_png(p3, "fig3_pulse_warming.png", FIG_H_PX[["warming"]])

# ---- Hero: the two CarboTope lines of Figure 2, direct-labeled ----
d_extra <- pulse_from_release(base$climate$year,
                              (pulse$climate$co2_ppm - base$climate$co2_ppm) / (PULSE_GTC / ccx_const("GtC_PER_PPM")),
                              PULSE_YEAR)
names(d_extra)[2] <- "frac"
tp <- ccx_tag_partition(tagged$out, pulse$out, tagged$tag)
ya <- tapply(tp$air, floor(tp$t), mean)
d_atoms <- pulse_from_release(as.integer(names(ya)), as.numeric(ya), PULSE_YEAR); names(d_atoms)[2] <- "frac"
at <- function(d, yr) d$frac[which.min(abs(d$year - yr))]
end_yr <- max(d_extra$year)
# labels sit ABOVE their lines at the right end, as plotmath (app_plotmath_str: the CO2 subscript set in one font)
hero_lab <- data.frame(
  x = end_yr, y = c(at(d_extra, end_yr), at(d_atoms, end_yr)) + 0.075,
  lab = vapply(c(sprintf("Extra CO₂ in the air: %.0f%%", 100 * at(d_extra, end_yr)),
                 sprintf("The pulse’s carbon atoms: %.0f%%", 100 * at(d_atoms, end_yr))), app_plotmath_str, ""),
  col = c(PAL[["pulse"]], PAL[["obs"]]))
hero <- ggplot2::ggplot() +
  ggplot2::geom_hline(yintercept = 0, colour = "grey75", linewidth = 0.3) +
  ggplot2::geom_line(data = d_extra, ggplot2::aes(year, frac), colour = PAL[["pulse"]], linewidth = 1.6) +
  ggplot2::geom_line(data = d_atoms, ggplot2::aes(year, frac), colour = PAL[["obs"]], linewidth = 1.6) +
  ggplot2::geom_text(data = hero_lab, ggplot2::aes(x, y, label = lab, colour = I(col)), hjust = 1, vjust = 0,
                     size = 6.2, fontface = "bold", parse = TRUE) +
  ggplot2::scale_y_continuous(labels = function(x) paste0(round(100 * x), "%"), limits = c(0, 1),
                              breaks = seq(0, 1, 0.25)) +
  ggplot2::scale_x_continuous(breaks = seq(PULSE_YEAR, end_yr, 50)) +
  ggplot2::labs(x = NULL, y = "Share still in the air",
                subtitle = app_plotmath(sprintf("%g GtC of CO₂ emitted in %d, medium background scenario",
                                                PULSE_GTC, PULSE_YEAR)),
                caption = CREDIT) +
  theme_ccx(base_size = 17) + ggplot2::theme(plot.margin = ggplot2::margin(14, 22, 10, 12))
save_png(hero, "hero_pulse_atoms_vs_excess.png", HERO_H_PX, HERO_W_PX)

# ---- provenance, stamped into the output folder ----
writeLines(c(
  sprintf("driver: outputs/substack_20261015/make_figures.R @ %s", ccx_git_stamp()),
  sprintf("mode: %s (the app's canonical); app release: %s", CCX_MODE_CANONICAL, APP_RELEASE_NAME),
  sprintf("pulse: %g GtC in %d on %s (pulse-lab default), runs %g-%g, emissions interp %s",
          PULSE_GTC, PULSE_YEAR, PULSE_BG, yrs[1], yrs[2], APP_PULSE_EMIS_METHOD),
  sprintf("FaIR: %s", attr(fair, "label") %||% "FaIR 2.2.4 (calib 1.6.0)"),
  sprintf("keeling window: %g-%g", KEELING_YEARS[1], KEELING_YEARS[2]),
  sprintf("hero values at %g: extra CO2 %.1f%%, tagged atoms %.1f%%", end_yr, 100 * at(d_extra, end_yr),
          100 * at(d_atoms, end_yr)),
  sprintf("size: %d px wide at %d dpi; hero %dx%d", FIG_W_PX, FIG_RES, HERO_W_PX, HERO_H_PX),
  "deterministic: no RNG"), file.path(OUT_DIR, "provenance.txt"))
cat(readLines(file.path(OUT_DIR, "provenance.txt")), sep = "\n")
