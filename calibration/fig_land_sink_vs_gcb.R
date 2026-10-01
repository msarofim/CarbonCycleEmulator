# =====================================================================
# fig_land_sink_vs_gcb.R -- the model's land uptake against GCB's, smoothed.
#
# ⛔⛔ TWO QUANTITIES ARE PLOTTED AND THEY ARE NOT INTERCHANGEABLE. "Land
# uptake" is ambiguous, and conflating the two readings is this project's own
# 32 % bug ([[ccx_app_luc_budget_convention]]), so BOTH are drawn and each is
# named on its own panel rather than one being chosen silently:
#   A. RESIDUAL SINK -- land-use emissions OUTSIDE the sink. Model = land_C
#      change PLUS eluc; measured = GCB's published `land_sink`. THIS is what
#      GCB calls "the land sink" and what GATE 7 scores.
#   B. NET LAND FLUX -- land-use emissions INSIDE it. Model = the raw land_C
#      change; measured = GCB `land_sink - luc`. This is the one that crosses
#      zero, because early on clearing outweighs uptake.
#
# ⭐ PANEL A CARRIES GCB's OWN UNCLOSED IMBALANCE as a band, because the
# 2026-09-24 (i) result is that the model-minus-GCB gap IS that imbalance and
# the band is the only honest way to show a difference against a budget that
# does not close. ⚠ The band is an EXTREME attribution -- it asks where the
# land sink would sit if ALL the unplaced carbon were land, and the same carbon
# could equally be an emissions, ocean or growth error. Labelled as such.
#
# ⚠ THE SMOOTH IS 5-YEAR CENTRED, at Marcus's request. The project's own
# APP_LUC_SMOOTH_YR convention is 11; this is deliberately shorter and is named
# in FG_SMOOTH_YR so the label and the window cannot drift apart. An incomplete
# window yields NA rather than a short mean, so each smoothed line stops
# (FG_SMOOTH_YR - 1)/2 years short at both ends -- the RAW series is drawn
# underneath so those years are still visible.
#
# Usage:  Rscript calibration/fig_land_sink_vs_gcb.R
# Output: calibration/output/figures/fig_land_sink_vs_gcb.png
# =====================================================================
suppressWarnings(suppressMessages({
  for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
  library(ggplot2); library(patchwork)
}))
ccx_load_cpp()
source(file.path("calibration", "lib_design_gates.R"))

# ---- labels derive from named constants (project rule) --------------
FG_OUT        <- ccx_path("calibration", "output", "figures")
FG_FILE       <- "fig_land_sink_vs_gcb.png"
FG_COMMIT     <- ccx_git_stamp(exclude = file.path(FG_OUT, FG_FILE))   # the figure is its product, not an input
FG_SMOOTH_YR  <- 5L                      # centred; NOT the app's 11-yr convention
FG_G7_RECORD  <- 3.09                    # gate 7's recorded land sink -- the anchor
FG_G7_TOL     <- 0.02
FG_W <- 11; FG_H <- 9; FG_DPI <- 160
# ⭐ COLOURS ARE COMPUTED, NOT CHOSEN -- AND THE TOOL IS NAMED, WHICH IS THE
# POINT OF THE 2026-09-25 RE-STEP. The 09-24 (k) pair #C2185B / #12395C was
# recorded here as "protan 13.5", from a throwaway dichromat implementation that
# was never committed. `tools/palette_check.py` (committed 09-24 n; sRGB ->
# linear -> LMS, Vienot-Brettel-Mollon projection, OKLab dE) reproduces that
# pair's NORMAL dE exactly (31.3) and scores its protan at **7.4** -- BELOW the
# 8 target. Two defensible implementations disagreeing by ~2x is the whole width
# of the pass/fail decision, so the pair is re-stepped to clear the target under
# the STRICTER of them rather than left resting on a number nothing can
# reproduce ([[palette_check_unreproduced]]).
#
# MINIMAL CHANGE subject to a worst-case floor of 12 (1.5x the target): the new
# pair sits dE 2.8 and 1.5 from its predecessor under normal vision, i.e. the
# figure looks the same, and keeps the warm-model / cool-observation semantic.
# ⚠ NEITHER COLOUR COULD BE KEPT FIXED -- a search holding one of them exactly
# found no partner clearing the floor. The protan gap is a JOINT property of the
# pair, not a defect in one of them.
#
# Reproduce:  python3 tools/palette_check.py '#C4315F' '#16345A'
# ⛔ FG_COL_SCORES is not decoration: test-figure-palette.R re-runs that command,
# parses these two colours out of THIS file, and fails if the numbers below stop
# matching -- so a colour cannot be changed without the receipt moving with it.
FG_COL        <- c(model = "#C4315F", gcb = "#16345A")
FG_COL_SCORES <- c(normal = 32.1, protan = 12.6, deutan = 26.6, tritan = 40.8)
FG_COL_TARGET <- 8      # the dataviz skill's OKLab dE floor
# The band is FG_COL[["gcb"]] at alpha 0.16 over white = #DADFE5, which scores
# 9.7 against the paper and 57.1 / 31.4 against the two lines -- checked, because
# an alpha-composited fill is not covered by scoring the pair it came from.
FG_LAB_MODEL  <- "CCX"
FG_LAB_GCB    <- "Global Carbon Budget"
FG_LAB_BAND   <- "GCB land sink + its unclosed imbalance"
FG_UNITS      <- "GtC/yr"
FG_TITLE_A    <- "Residual land sink — land-use emissions OUTSIDE the sink"
FG_TITLE_B    <- "Net land flux — land-use emissions INSIDE it"
FG_SUB_A      <- sprintf(
  "What GCB publishes as “the land sink”, and what gate 7 scores. %d-yr centred mean; thin line = annual.",
  FG_SMOOTH_YR)
FG_SUB_B      <- sprintf(
  "The quantity that crosses zero from source to sink. %d-yr centred mean; thin line = annual.",
  FG_SMOOTH_YR)
dir.create(FG_OUT, recursive = TRUE, showWarnings = FALSE)

# ---- the mode, built the way app/global.R builds it -----------------
md   <- readRDS(ccx_mode_file())
pins <- ccx_mode_pins(md)
rmp  <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rmp), add = TRUE)
bp   <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
pm   <- ccx_mode_par_with_pins(md)
if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)
for (n in intersect(names(bp), names(pm))) bp[[n]] <- pm[[n]]
bp   <- ccx_set_enso(bp, pm)
for (n in names(pins)) bp[[n]] <- pins[[n]]
spin <- ccx_spinup_from_label(ccx_mode_spinup(md))(bp)
F    <- suppressWarnings(ccx_build_forcing("historical", DG_YEARS,
                                           prod_c14 = spin$prod_c14,
                                           luc_scale = pm$luc_scale,
                                           bomb_total_kmol = pm$bomb_total))
r    <- ccx_run_fast(spin, F); r$F <- F

# ---- ANCHOR: gate 7, before anything is drawn -----------------------
# ⚠ A FIGURE IS AN ASSERTION. If the parameter build is wrong the picture is
# wrong and looks fine, so the anchor runs here exactly as in the diagnostics.
a  <- dg_annual_sinks(r)
g7 <- dg_gate7(r)
cat(sprintf("[ANCHOR] gate 7 land %.2f (recorded %.2f)\n", g7$land, FG_G7_RECORD))
if (abs(g7$land - FG_G7_RECORD) > FG_G7_TOL)
  stop("ANCHOR FAILED: the parameter build is wrong; the figure would be wrong and look fine.")

gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
el  <- ccx_forcing_eluc_annual(r$F)
d <- merge(data.frame(year = a$year, m_resid = a$land,
                      m_net = a$land - el$eluc[match(a$year, el$year)]),
           data.frame(year = gcb$year, o_resid = gcb$land_sink,
                      o_net = gcb$land_sink - gcb$luc, imbal = gcb$imbalance),
           by = "year")

smooth <- function(v, n = FG_SMOOTH_YR) {   # centred; NA on an incomplete window
  h <- (n - 1L) %/% 2L
  vapply(seq_along(v), function(i) {
    j <- max(1, i - h):min(length(v), i + h)
    if (length(j) < n) NA_real_ else mean(v[j])
  }, numeric(1))
}
for (v in c("m_resid", "m_net", "o_resid", "o_net", "imbal"))
  d[[paste0("s_", v)]] <- smooth(d[[v]])

# ---- GATE: the smooth must lose exactly the edge years it claims to ---
lost <- (FG_SMOOTH_YR - 1L) %/% 2L
if (sum(is.na(d$s_m_resid)) != 2L * lost)
  stop("the smoother drops a different number of years than its window implies; ",
       "the caption would misdescribe the line.")

panel <- function(ycol_m, ycol_o, title, sub, band = FALSE) {
  p <- ggplot(d, aes(x = year))
  if (band)
    p <- p + geom_ribbon(aes(ymin = .data[[paste0("s_", ycol_o)]],
                             ymax = .data[[paste0("s_", ycol_o)]] + s_imbal,
                             fill = FG_LAB_BAND), alpha = 0.16, colour = NA)
  if (band)
    p <- p + scale_fill_manual(values = setNames(FG_COL[["gcb"]], FG_LAB_BAND))
  p +
    geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.3) +
    geom_line(aes(y = .data[[ycol_o]], colour = FG_LAB_GCB), linewidth = 0.3, alpha = 0.40) +
    geom_line(aes(y = .data[[ycol_m]], colour = FG_LAB_MODEL), linewidth = 0.3, alpha = 0.40) +
    geom_line(aes(y = .data[[paste0("s_", ycol_o)]], colour = FG_LAB_GCB), linewidth = 1.1) +
    geom_line(aes(y = .data[[paste0("s_", ycol_m)]], colour = FG_LAB_MODEL), linewidth = 1.1) +
    scale_colour_manual(values = setNames(c(FG_COL[["model"]], FG_COL[["gcb"]]),
                                          c(FG_LAB_MODEL, FG_LAB_GCB))) +
    scale_x_continuous(breaks = seq(1960, 2020, 10)) +
    labs(title = title, subtitle = sub, x = NULL, y = FG_UNITS) +
    theme_minimal(base_size = 12) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major = element_line(colour = "grey92", linewidth = 0.35),
          plot.title    = element_text(face = "bold", size = 13),
          plot.subtitle = element_text(colour = "grey35", size = 10),
          legend.position = "top", legend.title = element_blank(),
          legend.margin = margin(0, 0, 0, 0))
}

pa <- panel("m_resid", "o_resid", FG_TITLE_A, FG_SUB_A, band = TRUE)
pb <- panel("m_net",   "o_net",   FG_TITLE_B, FG_SUB_B, band = FALSE)

cap <- paste(
  strwrap(sprintf(
    paste("CCX mode %s (logpost %.2f, %s spinup, luc_scale %.4f); FaIR-independent carbon module;",
          "commit %s; drawn %s. Observations: Global Carbon Budget, data/gcb_budget.rds.",
          "Units %s. Smooth: %d-yr centred mean, NA on an incomplete window (so each bold line",
          "stops %d yr short at each end; the thin annual line does not).",
          "The band asks where the land sink would sit if ALL of GCB's unclosed imbalance were land",
          "-- an EXTREME attribution: the same carbon could be an emissions, ocean or growth error."),
    CCX_MODE_CANONICAL, md$logpost, ccx_mode_spinup(md), pm$luc_scale, FG_COMMIT,
    format(Sys.Date()), FG_UNITS, FG_SMOOTH_YR, lost), width = 118),
  collapse = "\n")

fig <- (pa / pb) + plot_annotation(
  title = "Land carbon uptake: CCX against the Global Carbon Budget",
  caption = cap,
  theme = theme(plot.title = element_text(face = "bold", size = 15),
                plot.caption = element_text(colour = "grey40", size = 7.5, hjust = 0)))

ggsave(file.path(FG_OUT, FG_FILE), fig, width = FG_W, height = FG_H, dpi = FG_DPI)
cat(sprintf("wrote %s\n", file.path(FG_OUT, FG_FILE)))

# ---- the numbers the picture asserts, printed so they can be checked -
cat(sprintf("\n%-13s %9s %9s %8s | %9s %9s %8s\n", "window",
            "resid mdl", "resid GCB", "diff", "net mdl", "net GCB", "diff"))
for (w in list(c(1959, 2024), c(1959, 1989), c(2015, 2023))) {
  k <- d$year >= w[1] & d$year <= w[2]
  cat(sprintf("%-13s %9.2f %9.2f %+8.2f | %9.2f %9.2f %+8.2f\n", sprintf("%d-%d", w[1], w[2]),
              mean(d$m_resid[k]), mean(d$o_resid[k]), mean(d$m_resid[k] - d$o_resid[k]),
              mean(d$m_net[k]),   mean(d$o_net[k]),   mean(d$m_net[k] - d$o_net[k])))
}

# ---- the band claim, as a NUMBER rather than something the eye does --
# ⭐ The picture's headline is "CCX sits inside GCB's imbalance band for most of
# the record and above it in the last decade". A reader should not have to
# squint to check that, and nor should the author.
cat(sprintf("\n%-11s %9s %9s %9s   %s\n", "decade", "CCX", "band lo", "band hi", "inside?"))
for (y0 in seq(1960, 2020, by = 10)) {
  k <- d$year >= y0 & d$year <= y0 + 9
  if (!any(k)) next
  m  <- mean(d$m_resid[k]); lo <- mean(d$o_resid[k])
  hi <- lo + mean(d$imbal[k])
  cat(sprintf("%d-%-6d %9.2f %9.2f %9.2f   %s\n", y0, min(y0 + 9, max(d$year)), m,
              min(lo, hi), max(lo, hi),
              if (m >= min(lo, hi) && m <= max(lo, hi)) "yes" else "NO"))
}
