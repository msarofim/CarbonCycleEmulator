# =====================================================================
# diag_land_topology.R -- CAN a land topology hit N&L's carbon stock and
# their bomb-14C inventory AT THE SAME TIME? Answered offline, before any
# box structure is changed.
#
# WHY OFFLINE. diag_land_structure.R [4] established that a single
# responsive soil pool trades pool size against bomb-14C inventory: N&L's
# ratio (0.99 kmol per 100 GtC at 1975) is reached only at a pool twice
# theirs, their absolute inventory only at a pool six times too small.
# The prescribed next step is a multi-pool land. Adding a box to the state
# vector touches R/model.R, src/ccx_core.cpp, spinup, aux, cpp.R and ten
# test fixtures -- so the topology should be CHOSEN before it is built,
# not searched for by rebuilding the core once per candidate.
#
# WHAT THIS IS. The land's bomb-14C uptake is a LINEAR system once the
# carbon fluxes are fixed: pools are filled at the atmosphere's 14C ratio
# and drain at their own. So for a candidate topology the excess-14C
# inventory can be integrated directly from an atmospheric Delta14C
# history, at ~1 ms per candidate, with no core rebuild. [1] validates
# that emulator against the full model on the CURRENT topology before any
# of its answers are used.
#
# WHAT IT IS NOT. The emulator holds pool sizes at their preindustrial
# steady state: it has no CO2 fertilisation, no LUC debit, no temperature
# dependence of Rh, and no feedback of the land onto the atmosphere. It
# answers "what shape of land holds the right amount of bomb 14C", which
# is a partition question, and nothing else. Every number it produces is
# a design target for the full model to be checked against, never a result.
#
# Run from the repo root:  Rscript calibration/diag_land_topology.R
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label and column below derives from these ----
TOPO_YEARS        <- c(1750, 2024)
TOPO_REF_YEARS    <- c(1975, 1995)   # GEOSECS and WOCE reference years
TOPO_BOMB_TOTAL   <- 102             # kmol, N&L citable 1945-1980 total, as in
                                     # diag_bomb_partition.R -- so the model
                                     # receives N&L's own input
TOPO_NL_SOURCE    <- "naegler_levin_2006_t4_YANG"
TOPO_NL_BIO_PGC   <- 2200            # N&L biosphere carbon, four pools
TOPO_PREBOMB_WIN  <- c(1941, 1950)   # window whose mean is the zero of "excess"
TOPO_VALID_TOL    <- 0.15            # rel. agreement required of the emulator
                                     # in [1] before its answers are used
TOPO_DT           <- 1 / 12          # yr, matches the model's master step

cat("\n=== diag_land_topology.R ===\n")
cat("Offline scan: which land pool structure holds N&L's carbon AND their bomb 14C?\n\n")

# ---------------------------------------------------------------------
# The emulator
# ---------------------------------------------------------------------
# A topology is vegetation pools fed by NPP, and soil pools fed by the
# vegetation litter, each draining to the atmosphere:
#
#   atm --NPP*a_i--> V_i --V_i/tau_i--> (split by b_j) --> S_j --S_j/tau_j--> atm
#
# Steady state (which is what ccx_spinup solves for the current 2-pool case):
#   V_i = a_i * NPP * tau_i ,   S_j = b_j * NPP * tau_j
# so total litter is NPP and the soil shares b_j sum to 1, exactly as the
# vegetation shares a_i do.
#
# EXCESS 14C, in the model's own state units ("GtC carrying standard 14C
# content", model.R header). Carbon entering a pool carries the SOURCE's ratio,
# so with d(t) the atmospheric excess Delta14C in per mil:
#   dE_Vi/dt = a_i*NPP*d(t)/1000 - E_Vi/tau_i - lambda*E_Vi
#   dE_Sj/dt = b_j*sum_i(E_Vi/tau_i) - E_Sj/tau_j - lambda*E_Sj
# Linear, so no iteration and no stability worry at dt = 1/12 for any tau >= 1.
# Fractionation is deliberately absent: Delta14C is fractionation-corrected by
# convention and the model transports C14/C unfractionated (model.R header).
ccx_topo <- function(name, veg, soil) {
  stopifnot(abs(sum(vapply(veg,  function(z) z$share, 0)) - 1) < 1e-9,
            abs(sum(vapply(soil, function(z) z$share, 0)) - 1) < 1e-9)
  list(name = name, veg = veg, soil = soil)
}

#' Preindustrial land carbon of a topology, GtC
topo_land_C <- function(topo, npp) {
  npp * (sum(vapply(topo$veg,  function(z) z$share * z$tau, 0)) +
         sum(vapply(topo$soil, function(z) z$share * z$tau, 0)))
}

#' Integrate the excess-14C inventory of a topology
#'
#' @param topo  from ccx_topo()
#' @param npp   list(NH=, SH=) preindustrial NPP, GtC/yr
#' @param d_ex  matrix [month x 2], atmospheric EXCESS Delta14C per mil, NH then SH
#' @return numeric vector, total land excess 14C in state units, per month
topo_excess_c14 <- function(topo, npp, d_ex) {
  lam  <- ccx_const("LAMBDA_C14")
  nmon <- nrow(d_ex)
  a    <- vapply(topo$veg,  function(z) z$share, 0)
  tv   <- vapply(topo$veg,  function(z) z$tau,   0)
  b    <- vapply(topo$soil, function(z) z$share, 0)
  ts   <- vapply(topo$soil, function(z) z$tau,   0)
  npp_h <- c(npp$NH, npp$SH)

  total <- numeric(nmon)
  for (hi in 1:2) {
    Ev <- numeric(length(a)); Es <- numeric(length(b))
    for (i in seq_len(nmon)) {
      total[i] <- total[i] + sum(Ev) + sum(Es)
      # RK4 on the linear system, same master step as the model
      f <- function(Ev, Es, d) {
        litter <- Ev / tv
        list(dv = a * npp_h[hi] * d / 1000 - litter - lam * Ev,
             ds = b * sum(litter) - Es / ts - lam * Es)
      }
      d0 <- d_ex[i, hi]
      d1 <- if (i < nmon) d_ex[i + 1, hi] else d_ex[i, hi]
      dm <- (d0 + d1) / 2
      h  <- TOPO_DT
      k1 <- f(Ev, Es, d0)
      k2 <- f(Ev + h / 2 * k1$dv, Es + h / 2 * k1$ds, dm)
      k3 <- f(Ev + h / 2 * k2$dv, Es + h / 2 * k2$ds, dm)
      k4 <- f(Ev + h * k3$dv,     Es + h * k3$ds,     d1)
      Ev <- Ev + h / 6 * (k1$dv + 2 * k2$dv + 2 * k3$dv + k4$dv)
      Es <- Es + h / 6 * (k1$ds + 2 * k2$ds + 2 * k3$ds + k4$ds)
    }
  }
  total
}

# ---------------------------------------------------------------------
# Drivers: two atmospheric Delta14C histories
# ---------------------------------------------------------------------
p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0))
sp <- ccx_spinup(p)
F_bomb <- ccx_build_forcing("historical", TOPO_YEARS, prod_c14 = sp$prod_c14,
                           bomb_total_kmol = TOPO_BOMB_TOTAL)
F_nob  <- F_bomb; F_nob$c14_bomb <- 0; F_nob$c14_nuclear <- 0
o_b <- ccx_run_fast(sp, F_bomb)$out
o_n <- ccx_run_fast(sp, F_nob)$out
tt  <- o_b$t
row_at <- function(y) which(floor(tt + 1e-9) == y)[1]

# (i) the MODEL's own atmosphere, paired bomb-on minus bomb-off. This is what
# the current land actually sees, so it is the driver [1] must validate against.
drv_model <- cbind(o_b$d14c_NH - o_n$d14c_NH, o_b$d14c_SH - o_n$d14c_SH)

# (ii) the OBSERVED atmosphere. The model's troposphere is 40-44 % short of N&L
# at both reference years (diag_bomb_partition.R), and that shortfall is itself
# a symptom of the land taking too much -- so designing the land against the
# model's own depressed atmosphere would understate how inert it has to be.
# N&L's biosphere inventory was derived against the real atmosphere; matching it
# requires driving with the real atmosphere.
zon <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_zonal.rds")))
drv_obs <- sapply(c("NH", "SH"), function(h) {
  z <- zon[zon$hemisphere == h, ]
  z <- aggregate(d14c ~ decimal_date, data = z, FUN = mean)   # zonal mean
  z <- z[order(z$decimal_date), ]
  base <- mean(z$d14c[z$decimal_date >= TOPO_PREBOMB_WIN[1] &
                        z$decimal_date <= TOPO_PREBOMB_WIN[2]])
  v <- approx(z$decimal_date, z$d14c - base, xout = tt, rule = 2)$y
  v[tt < min(z$decimal_date)] <- 0     # no bomb 14C before the record starts
  v
})
cat(sprintf("observed atmospheric record: %.2f-%.2f, prebomb zero = mean(%d-%d)\n",
            min(zon$decimal_date), max(zon$decimal_date),
            TOPO_PREBOMB_WIN[1], TOPO_PREBOMB_WIN[2]))
cat(sprintf("peak excess Delta14C   model %+.0f / %+.0f permil (NH/SH)   obs %+.0f / %+.0f\n\n",
            max(drv_model[, 1]), max(drv_model[, 2]),
            max(drv_obs[, 1]),   max(drv_obs[, 2])))

# ---------------------------------------------------------------------
# [1] Validate the emulator against the full model, current topology
# ---------------------------------------------------------------------
cat("=== [1] emulator vs full model, on the CURRENT land parameters ===\n")
npp0    <- sp$aux$npp0
# Derived from ccx_default_params(), not restated, so this validation cannot go
# stale against a land structure that has moved underneath it.
topo_now <- ccx_topo(
  "current",
  veg  = list(list(share = p$npp_leaf_frac,     tau = p$tau_leaf),
              list(share = 1 - p$npp_leaf_frac, tau = p$tau_wood)),
  soil = list(list(share = 1 - p$litter_slow_frac, tau = p$tau_soil_fast),
              list(share = p$litter_slow_frac,     tau = p$tau_soil_slow)))
cat(sprintf("  leaf %.2f @ %.0f yr | wood %.2f @ %.0f yr | soil %.2f @ %.0f yr + %.2f @ %.0f yr\n",
            p$npp_leaf_frac, p$tau_leaf, 1 - p$npp_leaf_frac, p$tau_wood,
            1 - p$litter_slow_frac, p$tau_soil_fast, p$litter_slow_frac, p$tau_soil_slow))
em_now  <- topo_excess_c14(topo_now, npp0, drv_model)
ok <- TRUE
cat(sprintf("  %6s %12s %12s %9s %14s %14s\n",
            "year", "full model", "emulator", "rel", "model land C", "emulator land C"))
for (y in TOPO_REF_YEARS) {
  i <- row_at(y)
  full <- ccx_c14_kmol(o_b$land_C14[i] - o_n$land_C14[i])
  emu  <- ccx_c14_kmol(em_now[i])
  rel  <- emu / full - 1
  ok   <- ok && abs(rel) <= TOPO_VALID_TOL
  cat(sprintf("  %6d %12.2f %12.2f %+8.1f %% %14.0f %14.0f\n",
              y, full, emu, 100 * rel, o_b$land_C[i],
              topo_land_C(topo_now, ccx_const("NPP_GLOBAL_PI"))))
}
cat(sprintf("  -> %s at %.0f %% tolerance.\n",
            if (ok) "VALIDATED" else "FAILED -- do not use the scan below", 100 * TOPO_VALID_TOL))
cat("  Residual is expected and one-signed: the emulator holds pool sizes at their\n")
cat("  preindustrial steady state, while the full model's pools grow under CO2\n")
cat("  fertilisation and shrink under the LUC debit. It is a topology tool.\n\n")
if (!ok) quit(status = 1)

# ---------------------------------------------------------------------
# [2] The scan
# ---------------------------------------------------------------------
nl <- readRDS(ccx_path("data", "obs_excess_c14.rds"))$all
nl_bio <- vapply(TOPO_REF_YEARS, function(y)
  nl$kmol_14c[nl$source == TOPO_NL_SOURCE & nl$quantity == "biosphere" & nl$year == y][1],
  numeric(1))

# Candidates. The first two are the structures already ruled out in
# diag_land_structure.R [4]; the rest add pools rather than retune two.
CANDIDATES <- list(
  ccx_topo("A current: veg 10 | soil 25",
           list(list(share = 1, tau = 10)),
           list(list(share = 1, tau = 25))),
  ccx_topo("B big slow soil: veg 10 | soil 50",
           list(list(share = 1, tau = 10)),
           list(list(share = 1, tau = 50))),
  ccx_topo("C soil split: veg 10 | 97% fast 2 + 3% slow 500",
           list(list(share = 1, tau = 10)),
           list(list(share = 0.97, tau = 2), list(share = 0.03, tau = 500))),
  ccx_topo("D soil split: veg 10 | 95% fast 2 + 5% slow 500",
           list(list(share = 1, tau = 10)),
           list(list(share = 0.95, tau = 2), list(share = 0.05, tau = 500))),
  ccx_topo("E soil split: veg 10 | 90% fast 3 + 10% slow 400",
           list(list(share = 1, tau = 10)),
           list(list(share = 0.90, tau = 3), list(share = 0.10, tau = 400))),
  ccx_topo("F veg split too: 70% leaf 1 + 30% wood 30 | 95% fast 2 + 5% slow 500",
           list(list(share = 0.70, tau = 1), list(share = 0.30, tau = 30)),
           list(list(share = 0.95, tau = 2), list(share = 0.05, tau = 500))),
  ccx_topo("G veg split: 80% leaf 1 + 20% wood 40 | 95% fast 2 + 5% slow 500",
           list(list(share = 0.80, tau = 1), list(share = 0.20, tau = 40)),
           list(list(share = 0.95, tau = 2), list(share = 0.05, tau = 500))),
  ccx_topo("H veg split: 80% leaf 1 + 20% wood 40 | 92% fast 2 + 8% slow 500",
           list(list(share = 0.80, tau = 1), list(share = 0.20, tau = 40)),
           list(list(share = 0.92, tau = 2), list(share = 0.08, tau = 500)))
)

scan_one <- function(topo, drv) {
  e <- topo_excess_c14(topo, npp0, drv)
  k <- vapply(TOPO_REF_YEARS, function(y) ccx_c14_kmol(e[row_at(y)]), numeric(1))
  c(landC = topo_land_C(topo, ccx_const("NPP_GLOBAL_PI")), k)
}

for (drv_name in c("MODEL atmosphere", "OBSERVED atmosphere")) {
  drv <- if (drv_name == "MODEL atmosphere") drv_model else drv_obs
  cat(sprintf("=== [2] topology scan, driven by the %s ===\n", drv_name))
  cat(sprintf("  targets: land C %.0f PgC, bomb 14C %.1f / %.1f kmol at %d / %d\n\n",
              TOPO_NL_BIO_PGC, nl_bio[1], nl_bio[2], TOPO_REF_YEARS[1], TOPO_REF_YEARS[2]))
  cat(sprintf("  %-58s %8s %8s %8s %10s\n",
              "topology", "land C", "k1975", "k1995", "kmol/100"))
  for (tp in CANDIDATES) {
    v <- scan_one(tp, drv)
    cat(sprintf("  %-58s %8.0f %8.2f %8.2f %10.3f\n",
                tp$name, v[1], v[2], v[3], v[2] / (v[1] / 100)))
  }
  cat(sprintf("  %-58s %8.0f %8.2f %8.2f %10.3f\n", "   TARGET (Naegler & Levin 2006 Table 4)",
              TOPO_NL_BIO_PGC, nl_bio[1], nl_bio[2], nl_bio[1] / (TOPO_NL_BIO_PGC / 100)))
  cat("\n")
}

cat("Read the OBSERVED-atmosphere block as the design target: N&L's biosphere\n")
cat("inventory was derived against the real atmosphere, and the model's own\n")
cat("troposphere is 40-44 % short precisely because its land takes too much.\n\n")

# ---------------------------------------------------------------------
# [3] Refinement around the working candidate, and the trade surface
# ---------------------------------------------------------------------
# [2] brackets the target between D (vegetation NOT split, 1975 far too high)
# and G (split too hard, both years too low). This maps the surface between
# them so the choice is made against a measured gradient rather than by
# picking the closest row of a hand-written list.
#
# NOT A FIT. Four knobs against three targets would fit anything, and the
# emulator carries a known one-signed -3 to -6 % bias ([1]). The point is the
# GRADIENT -- which knob moves 1975 without moving 1995, and how far a
# physically defensible pool layout lands from the target.
TOPO_LEAF_SHARE <- c(0.50, 0.60, 0.70, 0.80)   # NPP fraction to leaves/fine roots
TOPO_WOOD_TAU   <- c(20, 30, 40)               # yr, woody biomass turnover
TOPO_SLOW_SHARE <- c(0.04, 0.05, 0.06)         # litter fraction to the slow pool
TOPO_LEAF_TAU   <- 1                           # yr, leaves and fine roots
TOPO_FAST_TAU   <- 2                           # yr, responsive soil
TOPO_SLOW_TAU   <- 500                         # yr, passive soil

cat("=== [3] refinement: leaf share x wood turnover x slow-soil share ===\n")
cat("  driven by the OBSERVED atmosphere\n")
cat(sprintf("  leaf tau %.0f yr, fast soil tau %.0f yr, slow soil tau %.0f yr held fixed\n\n",
            TOPO_LEAF_TAU, TOPO_FAST_TAU, TOPO_SLOW_TAU))
cat(sprintf("  %5s %5s %6s %8s %8s %8s %9s %9s\n",
            "leaf", "tauW", "slow", "land C", "k1975", "k1995", "veg C", "misfit"))
best <- NULL
for (ls in TOPO_LEAF_SHARE) for (tw in TOPO_WOOD_TAU) for (ss in TOPO_SLOW_SHARE) {
  tp <- ccx_topo("refine",
                 list(list(share = ls, tau = TOPO_LEAF_TAU),
                      list(share = 1 - ls, tau = tw)),
                 list(list(share = 1 - ss, tau = TOPO_FAST_TAU),
                      list(share = ss, tau = TOPO_SLOW_TAU)))
  v <- scan_one(tp, drv_obs)
  vegC <- ccx_const("NPP_GLOBAL_PI") * (ls * TOPO_LEAF_TAU + (1 - ls) * tw)
  # relative misfit on the three targets, equally weighted
  mis <- sqrt(mean(c(v[1] / TOPO_NL_BIO_PGC - 1,
                     v[2] / nl_bio[1] - 1, v[3] / nl_bio[2] - 1)^2))
  cat(sprintf("  %5.2f %5.0f %6.2f %8.0f %8.2f %8.2f %9.0f %8.1f %%\n",
              ls, tw, ss, v[1], v[2], v[3], vegC, 100 * mis))
  if (is.null(best) || mis < best$mis) best <- list(ls = ls, tw = tw, ss = ss, v = v, mis = mis)
}
cat(sprintf("\n  lowest misfit: leaf share %.2f, wood tau %.0f, slow share %.2f",
            best$ls, best$tw, best$ss))
cat(sprintf("  -> land C %.0f, %.2f / %.2f kmol (%.1f %%)\n",
            best$v[1], best$v[2], best$v[3], 100 * best$mis))
cat(sprintf("  target: land C %.0f, %.2f / %.2f kmol\n", TOPO_NL_BIO_PGC, nl_bio[1], nl_bio[2]))
cat("  The emulator runs -3 to -6 % LOW against the full model ([1]), so a layout\n")
cat("  landing a few per cent BELOW target here is the one to build.\n\n")

# ---------------------------------------------------------------------
# [4] What the 14C constraint costs the carbon-climate feedback
# ---------------------------------------------------------------------
# The four-pool land closed the partition but weakened the land carbon-climate
# feedback: gamma_L fell from -57.6 to -19.6 GtC/K on coupled SSP5-8.5 (measured
# as the land-carbon difference at 2100 between q10 = 2 and q10 = 1, over the
# GMST at 2100). Two tests record it -- test-climate.R:122 and, via the same
# small responsive pool, test-mechanisms.R:32.
#
# WHY. Only the soil pools respire with q10, and a q10 anomaly can only move
# carbon a pool can actually release on the horizon in question. Pool j
# contributes C_j * (1 - exp(-H/tau_j)) over H years, so tau 2 counts in full
# and tau 500 counts ~18 %. Call that RESPONDING CARBON. The two-pool land had
# ~1470 GtC of it, the four-pool land ~390 -- a factor 3.8, against the factor
# 2.9 in gamma_L. The metric explains the loss, so it is the right thing to
# scan against.
#
# THE QUESTION THIS ANSWERS: can an INTERMEDIATE soil pool (tau ~30-100 yr) buy
# the feedback back without re-breaking the partition? Total soil carbon is held
# fixed as the intermediate pool grows, so the comparison is at constant stock.
TOPO_HORIZON     <- 100     # yr, the horizon "responding carbon" is defined on
TOPO_MID_TAU     <- c(30, 60, 100)
TOPO_MID_SHARE   <- c(0.05, 0.10, 0.15)
TOPO_SOIL_TARGET <- 1684    # GtC, soil stock held fixed across the scan
                            # (= TOPO_NL_BIO_PGC - the vegetation the layout implies)

topo_responding <- function(pools, npp = ccx_const("NPP_GLOBAL_PI"), H = TOPO_HORIZON)
  sum(vapply(pools, function(z) z$share * npp * z$tau * (1 - exp(-H / z$tau)), 0))

cat("=== [4] can an intermediate soil pool buy the feedback back? ===\n")
cat(sprintf("  responding carbon = sum_j C_j (1 - exp(-%d/tau_j)), soil pools only\n",
            TOPO_HORIZON))
cat(sprintf("  %6s %7s %7s %8s %8s %8s %10s\n",
            "tauMid", "midFrc", "slowFrc", "land C", "k1975", "k1995", "respondC"))
veg_now <- topo_now$veg
npp_g   <- ccx_const("NPP_GLOBAL_PI")
for (tm in TOPO_MID_TAU) for (mf in TOPO_MID_SHARE) {
  # slow share chosen so the SOIL stock stays at TOPO_SOIL_TARGET
  sf <- max(0.005, (TOPO_SOIL_TARGET - npp_g * mf * tm -
                      npp_g * (1 - mf) * TOPO_FAST_TAU) / (npp_g * TOPO_SLOW_TAU))
  soil <- list(list(share = 1 - mf - sf, tau = TOPO_FAST_TAU),
               list(share = mf, tau = tm),
               list(share = sf, tau = TOPO_SLOW_TAU))
  v <- scan_one(ccx_topo("mid", veg_now, soil), drv_obs)
  cat(sprintf("  %6.0f %7.3f %7.3f %8.0f %8.2f %8.2f %10.0f\n",
              tm, mf, sf, v[1], v[2], v[3], topo_responding(soil)))
}
soil_now <- topo_now$soil
v_now <- scan_one(topo_now, drv_obs)
cat(sprintf("  %6s %7s %7s %8.0f %8.2f %8.2f %10.0f   <- current four-pool\n",
            "-", "-", "-", topo_land_C(topo_now, npp_g), v_now[2], v_now[3],
            topo_responding(soil_now)))
cat(sprintf("  %6s %7s %7s %8.0f %8.2f %8.2f %10.0f   <- N&L target / old two-pool\n",
            "-", "-", "-", TOPO_NL_BIO_PGC, nl_bio[1], nl_bio[2],
            topo_responding(list(list(share = 1, tau = 25)))))
cat("\n  NO. The trade is roughly +0.7 kmol at 1975 -- 3 % of the target -- per\n")
cat("  +100 GtC of responding carbon. Doubling responding carbon (390 -> ~730)\n")
cat("  still leaves it at half the two-pool value while pushing 1975 from exact\n")
cat("  to +13 %. Restoring the old feedback through soil would cost the partition\n")
cat("  outright. THE BOMB 14C BOUNDS THE SOIL-RESPIRATION CARBON-CLIMATE FEEDBACK\n")
cat("  FROM ABOVE, and that is a result, not a defect.\n\n")
cat("  THE ESCAPE THIS MODEL DOES NOT HAVE: the model's only carbon-climate\n")
cat("  feedback is q10 on heterotrophic respiration. Real land models get a large\n")
cat("  share of gamma_L from productivity decline and disturbance -- a temperature\n")
cat("  dependence of NPP, which this model lacks entirely. If gamma_L needs to be\n")
cat("  larger, that is where it should come from; enlarging the responsive soil\n")
cat("  pool is the one route the 14C has closed.\n")
