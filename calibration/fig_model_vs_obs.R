# =====================================================================
# fig_model_vs_obs.R -- model against observations, all three species, with
# residual panels and a mid-century zoom.
#
# WHAT IT PLOTS THAT THE APP DOES NOT, and it is the whole point of the
# STATION line: the likelihood predicts the STATION as `box - rep_dC` (and the
# d13C analogue through mass balance at LIK_REP_SOURCE_D13C). `plot_keeling()`
# in the app draws the raw model BOX against MLO and SPO with no offset, so the
# calibrated model is EXPECTED to sit ~5.6 ppm above Mauna Loa there, by
# construction, and the app has no way to say so (diag_app_params.R).
# BOTH lines are drawn here and both are labelled. Which one belongs in the app
# is Marcus's presentation decision, not a bug to be silently resolved.
#
# THE ICE TERM GETS NO OFFSET -- R/likelihood.R scores the bare co2_SH box
# against Law Dome -- so the ice panel is drawn against the box, deliberately.
# That asymmetry is real and is what makes the era decomposition possible.
#
# Usage:  Rscript calibration/fig_model_vs_obs.R [N|D]
# Output: calibration/output/figures/*.png    Runtime ~30 s.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
suppressMessages({library(ggplot2); library(data.table); library(patchwork)})
ccx_load_cpp()

# ---- labels derive from named constants (project rule) --------------
FG_ARM      <- (function(a) if (length(a) && a[1] %in% c("N","D")) a[1] else "N")(commandArgs(TRUE))
FG_OUT      <- ccx_path("calibration", "output", "figures")
FG_YEARS    <- c(1750, 2024)
FG_PLATEAU  <- c(1940, 1955)     # Etheridge 1996 / Bastos 2016: 310-312 ppm
FG_ZOOM     <- c(1900, 1985)
FG_W        <- 13; FG_H <- 9; FG_DPI <- 150
FG_COL      <- c(model_box = "#B03060", model_stn = "#E08AA0",
                 ice = "#1F4E79", firn = "#4E9BD6", MLO = "#D95F02", SPO = "#7570B3")
dir.create(FG_OUT, recursive = TRUE, showWarnings = FALSE)

M  <- ccx_load_mode(FG_ARM)
sp <- ccx_spinup(M$p)
SF <- ccx_scaled_forcing(sp, luc_scale = M$luc_scale, bomb_total = M$bomb_total)
o  <- as.data.table(ccx_run_fast(sp, SF$F)$out)
obs <- ccx_prepare_obs()
REP <- M$err$rep_dC

# station prediction, exactly as R/likelihood.R forms it
stn_co2  <- function(box)        box - REP
stn_d13c <- function(box_d, box_c) box_d - REP * (LIK_REP_SOURCE_D13C - box_d) / box_c

o[, `:=`(co2_NH_stn = stn_co2(co2_NH), co2_SH_stn = stn_co2(co2_SH),
         d13c_NH_stn = stn_d13c(d13c_NH, co2_NH), d13c_SH_stn = stn_d13c(d13c_SH, co2_SH))]
ip <- function(col, yr) stats::approx(o$t, o[[col]], xout = yr, rule = 2)$y

# ---- observations ---------------------------------------------------
ic <- readRDS(ccx_path("data", "obs_icecore.rds"))
# RESTRICT EVERY OBSERVATION TO THE MODEL'S OWN DOMAIN. The Law Dome records
# start at 154 CE and the model at FG_YEARS[1] = 1750, so plotting the full
# record (a) compresses the industrial era to nothing and (b) draws "residuals"
# for pre-1750 samples that are really the approx(rule = 2) FLAT EXTRAPOLATION
# of the model's 1750 value -- an artefact of the interpolator, not a misfit.
ice <- as.data.table(ic$co2_samples)[, yr := as.numeric(age_CO2)][!is.na(yr)][yr >= FG_YEARS[1]]
ice[, kind := fifelse(age_ice == "firn", "Law Dome firn", "Law Dome ice")]
i13 <- as.data.table(ic$d13c_samples)[, yr := as.numeric(age_CO2)][!is.na(yr)][yr >= FG_YEARS[1]]
i13[, kind := fifelse(age_ice == "firn", "Law Dome firn", "Law Dome ice")]
stn <- rbindlist(lapply(c("MLO","SPO"), function(s)
  data.table(yr = obs$co2_ann[[s]]$year, v = obs$co2_ann[[s]]$level, station = s)))
s13 <- rbindlist(lapply(c("MLO","SPO"), function(s)
  data.table(yr = obs$d13_ann[[s]]$year, v = obs$d13_ann[[s]]$level, station = s)))
d14 <- rbindlist(list(
  data.table(yr = obs$d14_nh_ann$year, v = obs$d14_nh_ann$value, hemi = "NH"),
  data.table(yr = obs$d14_sh_ann$year, v = obs$d14_sh_ann$value, hemi = "SH")))

th <- theme_bw(base_size = 11) +
  theme(legend.position = "bottom", legend.title = element_blank(),
        legend.margin = margin(t = -4), panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 8.5, colour = "grey35"))
band <- annotate("rect", xmin = FG_PLATEAU[1], xmax = FG_PLATEAU[2], ymin = -Inf, ymax = Inf,
                 fill = "grey70", alpha = 0.30)

# ---- PANEL A: CO2 ---------------------------------------------------
pA <- ggplot() + band +
  geom_point(data = ice, aes(yr, CO2ppm, colour = kind), size = 0.9, alpha = 0.75) +
  geom_point(data = stn, aes(yr, v, colour = station), size = 0.5) +
  geom_line(data = o, aes(t, co2_SH, colour = "model SH box"), linewidth = 0.5) +
  geom_line(data = o, aes(t, co2_SH_stn, colour = "model SH station"),
            linewidth = 0.5, linetype = "22") +
  scale_colour_manual(values = c("Law Dome ice" = FG_COL[["ice"]], "Law Dome firn" = FG_COL[["firn"]],
    MLO = FG_COL[["MLO"]], SPO = FG_COL[["SPO"]], "model SH box" = FG_COL[["model_box"]],
    "model SH station" = FG_COL[["model_stn"]])) +
  coord_cartesian(xlim = FG_YEARS) +
  labs(title = "A. Atmospheric CO2", y = "ppm", x = NULL,
       subtitle = sprintf("solid = model box (what the ice term scores); dashed = box - rep_dC = %.2f ppm (what the station terms score). Shading = the %d-%d plateau.",
                          REP, FG_PLATEAU[1], FG_PLATEAU[2])) + th

# ---- PANEL B: CO2 residuals ----------------------------------------
rice <- ice[, .(yr, r = ip("co2_SH", yr) - CO2ppm, src = kind)]
rstn <- stn[, .(yr, r = ip(ifelse(station[1]=="MLO","co2_NH_stn","co2_SH_stn"), yr) - v,
                src = station), by = station][, .(yr, r, src)]
pB <- ggplot(rbind(rice, rstn), aes(yr, r, colour = src)) + band +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_point(size = 0.7, alpha = 0.8) +
  scale_colour_manual(values = FG_COL[c("ice","firn","MLO","SPO")] |>
    setNames(c("Law Dome ice","Law Dome firn","MLO","SPO"))) +
  coord_cartesian(xlim = FG_YEARS) +
  labs(title = "B. CO2 residual (model - observed)", y = "ppm", x = NULL,
       subtitle = "ice vs the BOX (no offset, as scored); stations vs the OFFSET prediction. The ice residual is negative pre-1958 and the station residual ~0 after.") + th

# ---- PANEL C/D: d13C ------------------------------------------------
pC <- ggplot() + band +
  geom_point(data = i13, aes(yr, d13CO2, colour = kind), size = 0.9, alpha = 0.75) +
  geom_point(data = s13, aes(yr, v, colour = station), size = 0.5) +
  geom_line(data = o, aes(t, d13c_SH, colour = "model SH box"), linewidth = 0.5) +
  geom_line(data = o, aes(t, d13c_SH_stn, colour = "model SH station"),
            linewidth = 0.5, linetype = "22") +
  scale_colour_manual(values = c("Law Dome ice" = FG_COL[["ice"]], "Law Dome firn" = FG_COL[["firn"]],
    MLO = FG_COL[["MLO"]], SPO = FG_COL[["SPO"]], "model SH box" = FG_COL[["model_box"]],
    "model SH station" = FG_COL[["model_stn"]])) +
  coord_cartesian(xlim = FG_YEARS) +
  labs(title = "C. d13C-CO2 (the Suess decline)", y = "per mil", x = NULL,
       subtitle = "the d13C station offset follows rep_dC through mass balance at LIK_REP_SOURCE_D13C") + th
r13 <- rbind(i13[, .(yr, r = ip("d13c_SH", yr) - d13CO2, src = kind)],
             s13[, .(yr, r = ip(ifelse(station[1]=="MLO","d13c_NH_stn","d13c_SH_stn"), yr) - v,
                     src = station), by = station][, .(yr, r, src)])
pD <- ggplot(r13, aes(yr, r, colour = src)) + band +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_point(size = 0.7, alpha = 0.8) +
  scale_colour_manual(values = FG_COL[c("ice","firn","MLO","SPO")] |>
    setNames(c("Law Dome ice","Law Dome firn","MLO","SPO"))) +
  coord_cartesian(xlim = FG_YEARS) +
  labs(title = "D. d13C residual (model - observed)", y = "per mil", x = "year",
       subtitle = "MONOTONE where the CO2 residual changes sign -- the decoupling that GATE 1 of diag_d13c_midcentury.R rests on") + th

# ---- PANEL E/F: D14C ------------------------------------------------
mlt <- melt(o[, .(t, NH = d14c_NH, SH = d14c_SH)], id.vars = "t",
            variable.name = "hemi", value.name = "v")
pE <- ggplot() + band +
  geom_point(data = d14, aes(yr, v, colour = hemi), size = 0.6, alpha = 0.7) +
  geom_line(data = mlt, aes(t, v, colour = hemi), linewidth = 0.5) +
  coord_cartesian(xlim = c(1940, 2024)) +
  scale_colour_manual(values = c(NH = FG_COL[["MLO"]], SH = FG_COL[["SPO"]])) +
  labs(title = "E. Delta14C -- the bomb spike", y = "per mil", x = NULL,
       subtitle = "no representation offset applies to D14C; points are the zonal-weighted hemispheric aggregate") + th
d14[, r := ip(paste0("d14c_", hemi), yr) - v, by = hemi]
pF <- ggplot(d14, aes(yr, r, colour = hemi)) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_point(size = 0.6, alpha = 0.8) + coord_cartesian(xlim = c(1940, 2024)) +
  scale_colour_manual(values = c(NH = FG_COL[["MLO"]], SH = FG_COL[["SPO"]])) +
  labs(title = "F. Delta14C residual (model - observed)", y = "per mil", x = "year") + th

cap <- sprintf("CarbonCycleEmulator arm %s, mode_fit_pump%s.rds, logpost %.2f | rep_dC %.2f ppm, luc_scale %.4f, bomb_total %.2f kmol | objective post-d6adb58 (ice scores co2_SH)",
               FG_ARM, FG_ARM, M$md$logpost, REP, M$luc_scale, M$bomb_total)
fig1 <- (pA / pB / pC / pD) + plot_annotation(caption = cap,
          theme = theme(plot.caption = element_text(size = 7, colour = "grey40", hjust = 0)))
ggsave(file.path(FG_OUT, "fig1_co2_d13c.png"), fig1, width = FG_W, height = FG_H*1.35, dpi = FG_DPI)
fig2 <- (pE / pF) + plot_annotation(caption = cap,
          theme = theme(plot.caption = element_text(size = 7, colour = "grey40", hjust = 0)))
ggsave(file.path(FG_OUT, "fig2_d14c.png"), fig2, width = FG_W, height = FG_H*0.75, dpi = FG_DPI)

# ---- FIG 3: the mid-century zoom, with growth rates -----------------
zo <- o[t >= FG_ZOOM[1] & t <= FG_ZOOM[2]]
pG <- ggplot() + band +
  geom_point(data = ice[yr %between% FG_ZOOM], aes(yr, CO2ppm, colour = kind), size = 1.6) +
  geom_point(data = stn[yr %between% FG_ZOOM], aes(yr, v, colour = station), size = 0.8) +
  geom_line(data = zo, aes(t, co2_SH, colour = "model SH box"), linewidth = 0.6) +
  scale_colour_manual(values = c("Law Dome ice" = FG_COL[["ice"]], "Law Dome firn" = FG_COL[["firn"]],
    MLO = FG_COL[["MLO"]], SPO = FG_COL[["SPO"]], "model SH box" = FG_COL[["model_box"]])) +
  labs(title = sprintf("G. The %d-%d plateau: observations stall at 310-312 ppm, the model does not",
                       FG_PLATEAU[1], FG_PLATEAU[2]),
       y = "ppm", x = NULL,
       subtitle = "Bastos et al. 2016: reconstructions 'greatly overestimate atmospheric CO2 growth rate during the plateau period'. No model reproduces it.") + th
# ANNUAL MEANS BEFORE DIFFERENCING. Sampling the MONTHLY series at integer
# years and differencing that aliases the ~1 ppm SH seasonal cycle straight into
# the "growth rate" -- it produced a saw-toothed model curve of +/-0.3 ppm/yr,
# comparable to the plateau signal itself, which would have made this panel
# unreadable and the comparison unfair (the observed side is a LOESS through
# sparse ice samples and carries no seasonal cycle at all).
oa <- o[, .(v = mean(co2_SH)), by = .(yr = floor(t + 1e-9))]
gr <- data.table(yr = seq(FG_ZOOM[1], FG_ZOOM[2]))
gr[, model := c(NA, diff(oa$v[match(yr, oa$yr)]))]
sm <- ice[yr %between% c(FG_ZOOM[1]-10, FG_ZOOM[2]+10)][order(yr)]
lo <- stats::loess(CO2ppm ~ yr, sm, span = 0.35)
gr[, observed := c(NA, diff(stats::predict(lo, newdata = data.frame(yr = yr))))]
pH <- ggplot(melt(gr, id.vars = "yr", na.rm = TRUE), aes(yr, value, colour = variable)) + band +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_line(linewidth = 0.7) +
  scale_colour_manual(values = c(model = FG_COL[["model_box"]], observed = FG_COL[["ice"]])) +
  labs(title = "H. CO2 growth rate", y = "ppm/yr", x = "year",
       subtitle = "the observed growth rate collapses through the plateau; the model's does not. This gap is the mid-century residual.") + th
ggsave(file.path(FG_OUT, "fig3_plateau_zoom.png"), (pG / pH) +
       plot_annotation(caption = cap, theme = theme(plot.caption = element_text(size = 7, colour = "grey40", hjust = 0))),
       width = FG_W, height = FG_H*0.85, dpi = FG_DPI)
cat(sprintf("wrote 3 figures to %s\n", FG_OUT))
