# =====================================================================
# build_luc_gross_split.R -- UN-NET the prescribed land-use input into a gross
# source and a forest-regrowth removal.  ->  data/forcing_luc_gross_split.rds
#
# REGROWTH TIER 1 (Marcus 2026-09-24). CCX already contains forest regrowth: the
# prescribed land-use series is GCB's NET bookkeeping flux, which the three
# bookkeeping models compute as gross clearing MINUS gross regrowth before CCX
# sees a number. This script splits that column back apart so regrowth can be
# REPORTED. It changes no forcing the model integrates -- the two halves sum to
# the prescribed net in every year, which is gated here and again in
# calibration/diag_luc_gross_split.R and tests/testthat/test-luc-gross-split.R.
#
# THREE RULINGS, ALL MARCUS's (2026-09-24), each a flagged methodological choice:
#
#  R1  CONVENTION = GCB 2025's own "forest regrowth (total)" column.
#      ⛔⛔ NOT OSCAR v3.1's E_negative, which over the SAME years and the SAME
#      model is 3.15x larger (-3.122 vs -0.992 GtC/yr, 1959-2018). The two are
#      different quantities, not vintages: GCB reports "wood harvest & other
#      forest management" NET of its own post-harvest regrowth, so regrowth
#      inside the harvest rotation never reaches GCB's regrowth column, while
#      E_negative counts every negative flux in the bookkeeping. Every label
#      this script writes names the convention.
#
#  R2  PRE-1959 = back-extended with OSCAR's RATIO, rescaled to GCB's level.
#      GCB publishes the split only from 1959, which is 39 % of the land-use
#      carbon the model burns. OSCAR v3.1's workbook covers 1701-2018 and is
#      already the source of this model's pre-1850 LUC segment, so it supplies
#      the SHAPE of the regrowth share; the LEVEL comes from GCB over a window
#      ADJACENT to the join, exactly as the pre-1850 LUC splice does
#      (build_calibration_data.R [5a]). ⚠ This is an ASSUMPTION, not an
#      observation, and the product labels those years so.
#
#  R3  FUTURE = the observed regrowth DECAYS EXPONENTIALLY TO ZERO.
#      ⛔⛔ It does NOT fall out of the scenarios for free, which handoff
#      09-24 (e) assumed: the prescribed NET land-use flux goes NEGATIVE at 2100
#      in four of five SSPs, and in bookkeeping accounting that means gross
#      regrowth OVERTAKING gross clearing -- the opposite of decay. So the future
#      path is prescribed here and is labeled a prescription.
#
# ⚠⚠ THE WHOLE PRODUCT IS ASSERTED FROM GCB's BOOKKEEPING MODELS, NOT MEASURED
# BY CCX. 09-24 (h) showed this record cannot see the split. Tier 1 imports it.
#
# Inputs:  data-raw/downloads/gcb2025_luc_components_gcb.csv  (key gcb_luc_components)
#          data-raw/downloads/oscar_gcb2020_eluc.xlsx          (key oscar_eluc)
#          data/forcing_emissions_historical.rds               (the prescribed net)
#          data/ssp_emissions.rds                              (the future nets)
# Run from the repo root:  Rscript data-raw/build_luc_gross_split.R
# =====================================================================

suppressWarnings(suppressMessages({
  for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
}))

# ---- named constants; every label, column and filename derives from these ----
LGS_DL          <- "data-raw/downloads"
LGS_GCB_FILE    <- "gcb2025_luc_components_gcb.csv"
LGS_OSCAR_FILE  <- "oscar_gcb2020_eluc.xlsx"
LGS_OUT         <- ccx_path("data", "forcing_luc_gross_split.rds")
LGS_REGROW_COL  <- "forest regrowth (total)"   # GCB's own column name, never retyped
LGS_NET_COL     <- "Net"
LGS_CONVENTION  <- "GCB 2025 'forest regrowth (total)' (R1)"
LGS_JOIN_WIN    <- 1959:1988   # ADJACENT to the splice; the level ratio is taken here
LGS_ALT_WIN     <- 1959:2018   # reported alongside, as the honest measure of the choice
LGS_OBS_LABEL   <- "GCB 2025 observed split"
LGS_EXT_LABEL   <- "OSCAR-ratio back-extension (ASSUMED)"
LGS_FUT_LABEL   <- "prescribed exponential decay (ASSUMED)"
LGS_TAU_GRID    <- seq(1, 60, by = 0.25)  # yr; the kernel timescale fitted below
LGS_TAU_BRACKET <- c(20, 40, 60)          # yr; reported sensitivity on the FUTURE decay
LGS_CLOSE_TOL   <- 1e-12   # GtC/yr; the split is arithmetic and must close to machine
LGS_SHARE_MAX   <- 0.90    # a share this high would make gross = net/(1-s) explode;
                           # refuse rather than emit a number nobody chose
LGS_FUT_END     <- 2300    # standing project end year (MEMORY.md: end_year_2300)

cat(sprintf("\n%s\nUN-NETTING THE PRESCRIBED LUC INPUT\nconvention: %s\n%s\n",
            strrep("=", 74), LGS_CONVENTION, strrep("=", 74)))

gcb <- utils::read.csv(file.path(LGS_DL, LGS_GCB_FILE), comment.char = "#", check.names = FALSE)
osx <- as.data.frame(readxl::read_excel(file.path(LGS_DL, LGS_OSCAR_FILE), sheet = "Global"))
eh  <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))

# ---- the regrowth SHARE of the gross source, on GCB's convention -----
gcb$gross <- gcb[[LGS_NET_COL]] - gcb[[LGS_REGROW_COL]]
gcb$share <- -gcb[[LGS_REGROW_COL]] / gcb$gross
osx$share <- -osx$E_negative / osx$E_positive

# ---- R2: the level ratio, on the window ADJACENT to the join ---------
k_join <- mean(gcb$share[gcb$Year %in% LGS_JOIN_WIN]) / mean(osx$share[osx$year %in% LGS_JOIN_WIN])
k_alt  <- mean(gcb$share[gcb$Year %in% LGS_ALT_WIN])  / mean(osx$share[osx$year %in% LGS_ALT_WIN])
cat(sprintf("\n[R2] OSCAR->GCB share ratio  k = %.4f over %d-%d (the join window)\n",
            k_join, min(LGS_JOIN_WIN), max(LGS_JOIN_WIN)))
cat(sprintf("     alternative              k = %.4f over %d-%d  -> %.1f%% apart; that spread IS\n",
            k_alt, min(LGS_ALT_WIN), max(LGS_ALT_WIN), 100 * abs(k_alt - k_join) / k_join))
cat("     how much this construction is worth arguing about.\n")
step <- gcb$share[gcb$Year == min(gcb$Year)] - k_join * osx$share[osx$year == min(gcb$Year) - 1L]
cat(sprintf("     continuity at the splice: GCB share(%d) %.4f vs scaled OSCAR share(%d) %.4f -> step %+.4f\n",
            min(gcb$Year), gcb$share[gcb$Year == min(gcb$Year)], min(gcb$Year) - 1L,
            k_join * osx$share[osx$year == min(gcb$Year) - 1L], step))

# ---- assemble the share over every year the model burns LUC ----------
out <- data.frame(year = eh$year, net_GtC = eh$luc_GtC)
out$share  <- NA_real_
out$source <- NA_character_
i_obs <- match(out$year, gcb$Year)
out$share[!is.na(i_obs)]  <- gcb$share[i_obs[!is.na(i_obs)]]
out$source[!is.na(i_obs)] <- LGS_OBS_LABEL
i_ext <- match(out$year, osx$year)
need  <- is.na(out$share) & !is.na(i_ext)
out$share[need]  <- k_join * osx$share[i_ext[need]]
out$source[need] <- LGS_EXT_LABEL
if (anyNA(out$share))
  stop("no regrowth share for year(s) ", paste(out$year[is.na(out$share)], collapse = ", "),
       " -- neither GCB nor OSCAR covers them; do not let a flat hold choose")

# ---- the split itself ------------------------------------------------
# net = gross + regrowth and regrowth = -share * gross  =>  gross = net / (1 - share)
if (max(out$share) > LGS_SHARE_MAX)
  stop(sprintf("regrowth share reaches %.3f (> %.2f); gross = net/(1-share) would explode",
               max(out$share), LGS_SHARE_MAX))
if (any(out$net_GtC <= 0))
  stop("the prescribed net LUC is <= 0 in ", sum(out$net_GtC <= 0), " historical year(s); ",
       "the share construction assumes a positive net and must be revisited")
out$gross_GtC    <- out$net_GtC / (1 - out$share)
out$regrowth_GtC <- -out$share * out$gross_GtC

# ---- GATE: the two halves sum to the prescribed net, every year ------
resid <- max(abs(out$gross_GtC + out$regrowth_GtC - out$net_GtC))
cat(sprintf("\n[GATE] gross + regrowth vs the prescribed net, %d-%d: max |resid| = %.1e GtC/yr\n",
            min(out$year), max(out$year), resid))
if (resid > LGS_CLOSE_TOL)
  stop("the split does not reconstruct the prescribed net; the no-refit claim is void")
cat("       closes to machine precision -> the model's forcing is untouched.\n")

# ---- R3: the FUTURE decay timescale, measured before it is prescribed ----
# ⭐ The decay is a PRESCRIPTION, but its timescale need not be invented. Fitted
# here as the first-order kernel that best maps the gross source onto GCB's
# OBSERVED regrowth: regrowth(t) ~ -a * sum_k (1/tau) exp(-k/tau) gross(t-k).
# The back-extension supplies the pre-1959 history the kernel needs.
# ⚠ NOT INDEPENDENT of R2: the history it convolves came from OSCAR's share. It
# is the best the record allows and is labeled as such, not as an observation.
# ⚠ AND THE DETRENDED CROSS-CORRELATION IS WHAT GIVES IT POWER, not the raw one:
# regrowth and clearing both trend hard (regrowth's own trend is +0.0079
# GtC/yr/yr, p = 1e-31), so a raw correlation mostly reads the trend.
# ⚠ RECURSIVE, not an FIR convolution. A truncated kernel long enough for
# tau = 60 yr is longer than the 275-year series, and the FIR form then returns
# NA over the entire fit window. The one-pole recursion is the same exponential
# response with no history requirement: initialized at its own equilibrium for
# the first year's input, so the initialization error decays as exp(-t/tau) and
# is gone many tau before the 1959 fit window opens.
conv1 <- function(x, tau) {
  phi <- exp(-1 / tau)
  as.numeric(stats::filter(x * (1 - phi), filter = phi, method = "recursive", init = x[1]))
}
fit_win <- gcb$Year
obs_reg <- -gcb[[LGS_REGROW_COL]]
sse <- sapply(LGS_TAU_GRID, function(tau) {
  p <- conv1(out$gross_GtC, tau)[match(fit_win, out$year)]
  if (anyNA(p)) return(NA_real_)
  sum(resid(stats::lm(obs_reg ~ p))^2)
})
tau_hat <- LGS_TAU_GRID[which.min(sse)]
# ⛔⛔ THE BRACKET NEEDS AN EFFECTIVE-SAMPLE CORRECTION AND IT IS A FACTOR OF 4.
# The residuals of this fit are almost perfectly red (lag-1 rho ~ 0.9), so the
# naive SSE x (1 + 1/n) interval with n = 66 gives 19.0-20.25 yr -- a spurious
# 1.25-yr precision on a 66-point record. Corrected to n_eff = n(1-rho)/(1+rho)
# it is 17.3-23.8 yr, and THAT is what is stored and quoted.
n_fit   <- length(fit_win)
p_hat   <- conv1(out$gross_GtC, tau_hat)[match(fit_win, out$year)]
res_hat <- resid(stats::lm(obs_reg ~ p_hat))
rho_hat <- cor(res_hat[-1], res_hat[-length(res_hat)])
n_eff   <- n_fit * (1 - rho_hat) / (1 + rho_hat)
in_brk  <- which(sse <= min(sse, na.rm = TRUE) * (1 + 1 / n_eff))
tau_lo  <- min(LGS_TAU_GRID[in_brk]); tau_hi <- max(LGS_TAU_GRID[in_brk])
in_nai  <- which(sse <= min(sse, na.rm = TRUE) * (1 + 1 / n_fit))
cat(sprintf("\n[R3] fitted first-order kernel on the OBSERVED regrowth (%d-%d, n = %d):\n",
            min(fit_win), max(fit_win), n_fit))
cat(sprintf("     tau = %.2f yr  (bracket %.2f-%.2f yr),  r = %+.3f\n",
            tau_hat, tau_lo, tau_hi, cor(obs_reg, p_hat)))
cat(sprintf("     residual lag-1 rho = %.3f  ->  n_eff = %.1f of n = %d; the UNCORRECTED\n",
            rho_hat, n_eff, n_fit))
cat(sprintf("     bracket would have been %.2f-%.2f yr, i.e. %.1fx too tight.\n",
            min(LGS_TAU_GRID[in_nai]), max(LGS_TAU_GRID[in_nai]),
            (tau_hi - tau_lo) / (max(LGS_TAU_GRID[in_nai]) - min(LGS_TAU_GRID[in_nai]))))
cat(sprintf("     detrended r at that tau = %+.3f (2/sqrt(n) = %.3f); tau IS identified --\n",
            cor(resid(lm(obs_reg ~ fit_win)), resid(lm(p_hat ~ fit_win))), 2 / sqrt(n_fit)))
cat(sprintf("     SSE is %.1fx the minimum at tau = %g yr and %.1fx at %g yr, so the profile\n",
            sse[which.min(abs(LGS_TAU_GRID - 5))] / min(sse, na.rm = TRUE), 5,
            sse[which.min(abs(LGS_TAU_GRID - 60))] / min(sse, na.rm = TRUE), 60))
cat("     is not flat. ⚠ The detrended r alone peaks SHORTER (~10 yr) than the SSE does;\n")
cat("     the level information pulls longer, which is why the bracket is ~17-24, not 19-20.\n")
cat(sprintf("     ⚠ COINCIDENCE, NOT A VALIDATION: the model's own `tau_wood` is %g yr. This\n",
            ccx_default_params()$tau_wood))
cat("     tau is fitted to GCB's BOOKKEEPING MODELS and says nothing about CCX's wood pool.\n")

# ---- the future arms, one per scenario -------------------------------
ssp    <- as.data.frame(readRDS(ccx_path("data", "ssp_emissions.rds")))
y0     <- max(out$year)
reg0   <- out$regrowth_GtC[out$year == y0]
futures <- do.call(rbind, lapply(sort(unique(ssp$scenario)), function(sc) {
  d <- ssp[ssp$scenario == sc & ssp$year > y0 & ssp$year <= LGS_FUT_END, ]
  d <- d[order(d$year), ]
  r <- reg0 * exp(-(d$year - y0) / tau_hat)
  data.frame(scenario = sc, year = d$year, net_GtC = d$luc_GtC,
             regrowth_GtC = r, gross_GtC = d$luc_GtC - r,
             source = LGS_FUT_LABEL, stringsAsFactors = FALSE)
}))
fres <- max(abs(futures$gross_GtC + futures$regrowth_GtC - futures$net_GtC))
cat(sprintf("\n[GATE] futures: gross + regrowth vs the scenario net: max |resid| = %.1e GtC/yr\n", fres))
if (fres > LGS_CLOSE_TOL) stop("the future split does not reconstruct the scenario net")

cat(sprintf("\n     future decay from regrowth(%d) = %.3f GtC/yr, e-folding %.2f yr:\n", y0, reg0, tau_hat))
for (tau in LGS_TAU_BRACKET)
  cat(sprintf("       tau %2d yr -> regrowth %+.3f at 2050, %+.3f at 2100; cumulative %.1f GtC to %d\n",
              tau, reg0 * exp(-(2050 - y0) / tau), reg0 * exp(-(2100 - y0) / tau),
              sum(reg0 * exp(-(seq(y0 + 1, LGS_FUT_END) - y0) / tau)), LGS_FUT_END))

# ---- what the product says -------------------------------------------
cat(sprintf("\n     historical, %s:\n", LGS_CONVENTION))
for (w in list(c(1750, 1849), c(1850, 1958), c(1959, 2024), c(2015, 2024))) {
  s <- out[out$year >= w[1] & out$year <= w[2], ]
  cat(sprintf("       %d-%d  net %+6.3f  gross %+6.3f  REGROWTH %+6.3f  share %.3f  (%s)\n",
              w[1], w[2], mean(s$net_GtC), mean(s$gross_GtC), mean(s$regrowth_GtC),
              mean(s$share), unique(s$source)[1]))
}
obs <- out$source == LGS_OBS_LABEL
cat(sprintf("\n     cumulative %d-%d: gross %+.1f, REGROWTH %+.1f, net %+.1f GtC\n",
            min(out$year), max(out$year), sum(out$gross_GtC), sum(out$regrowth_GtC),
            sum(out$net_GtC)))
cat(sprintf("       of that regrowth, %.1f GtC (%.0f%%) is OBSERVED and %.1f GtC (%.0f%%) is the R2 ASSUMPTION\n",
            sum(out$regrowth_GtC[obs]), 100 * sum(out$regrowth_GtC[obs]) / sum(out$regrowth_GtC),
            sum(out$regrowth_GtC[!obs]), 100 * sum(out$regrowth_GtC[!obs]) / sum(out$regrowth_GtC)))

# ---- save, with the provenance the standing rules require ------------
prod <- list(
  historical  = out[, c("year", "net_GtC", "gross_GtC", "regrowth_GtC", "share", "source")],
  futures     = futures,
  convention  = LGS_CONVENTION,
  rulings     = c(R1 = "convention = GCB 2025 'forest regrowth (total)', NOT OSCAR E_negative (3.15x)",
                  R2 = sprintf("pre-%d = OSCAR v3.1 share shape x %.4f (GCB level over %d-%d)",
                               min(gcb$Year), k_join, min(LGS_JOIN_WIN), max(LGS_JOIN_WIN)),
                  R3 = sprintf("future = observed regrowth decaying exponentially, tau = %.2f yr", tau_hat)),
  k_join      = k_join, k_alt = k_alt,
  join_window = range(LGS_JOIN_WIN), alt_window = range(LGS_ALT_WIN),
  tau_yr      = tau_hat, tau_bracket = c(tau_lo, tau_hi), tau_sensitivity = LGS_TAU_BRACKET,
  tau_resid_rho = rho_hat, tau_n_eff = n_eff, tau_n_fit = n_fit,
  obs_window  = range(gcb$Year),
  units       = "GtC/yr; regrowth is NEGATIVE (a removal); luc_scale is NOT applied",
  luc_scale   = "NOT APPLIED -- consumers multiply BOTH halves by the fitted luc_scale",
  asserted    = paste("The split is ASSERTED from GCB's bookkeeping models, not measured by CCX.",
                      "See CHANGELOG 2026-09-24 (h) and (m)."),
  sources     = c(gcb = LGS_GCB_FILE, oscar = LGS_OSCAR_FILE,
                  net = "data/forcing_emissions_historical.rds",
                  ssp = "data/ssp_emissions.rds"),
  builder     = "data-raw/build_luc_gross_split.R",
  built       = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
saveRDS(prod, LGS_OUT)
cat(sprintf("\n=== wrote %s (%d historical yr, %d future rows) ===\n",
            LGS_OUT, nrow(out), nrow(futures)))
