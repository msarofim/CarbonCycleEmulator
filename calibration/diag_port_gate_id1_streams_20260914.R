for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
PINS <- ccx_parse_pins(Sys.getenv("CCX_MS_PIN", "")); invisible(ccx_apply_pins(PINS))
source(ccx_path("calibration", "lib_run_inputs.R")); ccx_require_run_inputs()
bp <- ccx_default_params(); bp$pump_mode <- "N"
bp <- ccx_apply_structure(bp, Sys.getenv("CCX_MS_STRUCT"), Sys.getenv("CCX_MS_SEAS_ML"), pump_field = Sys.getenv("CCX_MS_PUMP_FIELD", "solved"))
for (n in names(PINS)) bp[[n]] <- PINS[[n]]
lps <- ccx_make_logpost(base_params = bp, by_stream = TRUE)
md <- readRDS(ccx_path(CCX_MODE_FILES[[CCX_MODE_CANONICAL]]))
u <- ccx_par_to_unc(ccx_seed_unencodable(ccx_migrate_par_set(ccx_mode_par_with_pins(md)), "diag"))
s0 <- lps(u); str(s0, max.level = 1)
v0 <- unlist(s0)
set.seed(1); D <- NULL
for (k in 1:8) { du <- u; j <- sample(length(u), 1); du[j] <- du[j] * (1 + sample(c(-1,1),1) * 1e-12); D <- rbind(D, unlist(lps(du)) - v0) }
mx <- apply(abs(D), 2, max); print(round(sort(mx, decreasing = TRUE)[1:10], 7))
cat("total |sum| max:", max(abs(rowSums(D))), "\n")
st <- function(u) { r <- lps(u); c(attr(r, "streams"), logprior = attr(r, "logprior")) }
s0 <- st(u); set.seed(1); D <- NULL
for (k in 1:8) { du <- u; j <- sample(length(u), 1); du[j] <- du[j] * (1 + sample(c(-1,1),1) * 1e-12); D <- rbind(D, st(du) - s0) }
mx <- apply(abs(D), 2, max); print(signif(sort(mx, decreasing = TRUE)[1:8], 3))
cat("stream values at u:\n"); print(round(s0[names(sort(mx, decreasing = TRUE))[1:4]], 3))
