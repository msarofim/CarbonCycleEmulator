# Scratch probe (2026-10-13): how far do real defects move fit_iav_module.R GATE 0's rows at the WTC landing's base?
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R")); ccx_load_cpp()
MF <- "calibration/output/refit_20261013_wtc_hilda_csl3v0kaidgbemwtc/mode_fit_pumpN.rds"
OBS <- ccx_prepare_obs(); V <- dg_vector(MF); ms0 <- unlist(V$md$streams)
rows_of <- function(v) unlist(dg_streams(dg_run(v), v, obs = OBS))[names(ms0)]
dmax <- function(v) { d <- rows_of(v) - ms0; o <- which.max(abs(d)); sprintf("%.2e (%s)", abs(d[o]), names(d)[o]) }
setp <- function(v, n, x) { if (n %in% names(v$p)) v$p[[n]] <- x; v$pm[[n]] <- x; v$p <- ccx_set_enso(v$p, v$pm); v }
cat("base as stored:", dmax(V), "\n")
v <- V; for (n in c("gamma_enso_land_NH", "gamma_enso_land_SH")) v <- setp(v, n, 0); cat("land ENSO pins dropped (gamma 0):", dmax(v), "\n")
v <- setp(V, "lag_enso_land", V$pm$lag_enso_land + 1); cat("land ENSO lag +1 month:", dmax(v), "\n")
v <- setp(V, "bomb_share_NH", 0.90); cat("bomb_share_NH at the legacy 0.90:", dmax(v), "\n")
v <- setp(V, "seas_T_lag", 2.0); cat("seas_T_lag at the legacy 2.0:", dmax(v), "\n")
