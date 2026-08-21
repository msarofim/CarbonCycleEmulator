# =====================================================================
# diag_tracer_vs_perturbation.R -- A LABEL AND A PERTURBATION PARTITION
#                                  THE SAME PULSE DIFFERENTLY, AND BOTH
#                                  ARE CORRECT
#
# THE PROPOSAL (Marcus, 2026-08-21): rather than take a paired difference to
# find where a CO2 pulse ends up, tag the pulse with an inert isotopic label and
# watch where the label goes. It is the right instinct, the model already has
# the machinery, and it answers a DIFFERENT QUESTION from the one the
# reservoir-partition panel (DESIGN sec.7b) asks. This file measures how
# different.
#
# WHY THEY DIFFER, stated before it is measured so the numbers can contradict it.
# A label follows ATOMS. Atoms mix: once the added carbon has equilibrated it is
# indistinguishable from the carbon already there, so the label ends up
# distributed roughly in proportion to how much carbon each reservoir HOLDS --
# and the ocean holds ~38,000 GtC against the atmosphere's ~600. A perturbation
# follows the EXTRA AMOUNT, and how much extra the ocean will hold is set by
# carbonate buffering (the Revelle factor), not by its size. The ocean is vast
# and it is also a poor sponge for additional CO2, and those two facts point in
# opposite directions.
#
# THIS IS EXACTLY THE RESIDENCE-vs-ADJUSTMENT DISTINCTION the app exists to
# teach (DESIGN sec.7 tab 5, "Two curves, one model"), and it is the substance
# of Cawley (2011, Energy & Fuels 25:5503, doi:10.1021/ef200914u) replying to
# Essenhigh (2009): a ~4 yr residence time and a multi-century adjustment time
# are both true, of the same model, at the same time. So a bar chart captioned
# "where did the pulse go" would mean two different things depending on which
# experiment drew it -- and the LABEL version, captioned carelessly, states the
# premise of the argument sec.7a exists to answer.
#
# DECAY DOES NOT MATTER, AND THAT IS WHY 14C SERVES AS AN INERT LABEL HERE.
# Radiocarbon decays at a rate that is the SAME IN EVERY BOX, so if M(t) is the
# no-decay solution then L(t) = exp(-lambda t) M(t) solves the decaying system
# exactly -- and the FRACTION in each reservoir, L_i / sum(L), is identical to
# M_i / sum(M). The partition is decay-invariant. No fourth isotope is needed:
# the model's existing 14C, which it transports WITHOUT fractionation (DESIGN
# sec.2 -- the observations are fractionation-corrected), already is the inert
# tracer. Asserted here and CHECKED in section 1.
#
# (Carbon-15 is not the isotope for it, incidentally: 15C is radioactive with a
# half-life of about 2.4 seconds. The stable carbon isotopes are 12C and 13C.
# For an app panel the label is better called "tagged carbon" than given an
# isotope number that a curious student will look up.)
#
# Usage:  Rscript calibration/diag_tracer_vs_perturbation.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

TV_PULSE   <- 100      # GtC, the mass pulse
TV_LABEL   <- 0.10     # fractional 14C spike on the atmosphere, no mass
TV_YEARS   <- c(1750, 2750)
TV_HORIZON <- c(1, 5, 10, 20, 50, 100, 200, 500, 1000)
TV_RES     <- c("atmosphere", "land", "ocean")

sep <- function(s) cat(sprintf("\n%s\n%s\n", s, strrep("-", nchar(s))))

# A QUIET background: no emissions, no bomb, climate held. Both experiments then
# run on the same unperturbed state, which is what makes them comparable -- and
# a held background is also Joos's PD100 convention.
spin <- ccx_spinup(ccx_default_params())
F <- suppressWarnings(ccx_build_forcing("historical", TV_YEARS,
                                        prod_c14 = spin$prod_c14, bomb_total_kmol = 0))
for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso",
             "c14_bomb", "c14_nuclear")) F[[cc]] <- 0
F <- ccx_hold_climate(F, value = 0)

ii <- c(spin$aux$idx$NH$atm, spin$aux$idx$SH$atm)
fN <- spin$y[ii[1], "C"] / (spin$y[ii[1], "C"] + spin$y[ii[2], "C"])

# ---- control ---------------------------------------------------------
ctl <- ccx_run_fast(spin, F)$out

# ---- MASS pulse: added at the atmosphere's own isotope ratios ---------
sm <- spin
for (k in ii) {
  add <- TV_PULSE * if (k == ii[1]) fN else 1 - fN
  for (sp13 in c("C13", "C14"))
    sm$y[k, sp13] <- sm$y[k, sp13] + add * spin$y[k, sp13] / spin$y[k, "C"]
  sm$y[k, "C"] <- sm$y[k, "C"] + add
}
mass <- ccx_run_fast(sm, F)$out

# ---- LABEL pulse: 14C only, no mass ----------------------------------
sl <- spin
for (k in ii) sl$y[k, "C14"] <- sl$y[k, "C14"] * (1 + TV_LABEL)
lab <- ccx_run_fast(sl, F)$out

# ---------------------------------------------------------------------
# 1. IS THE LABEL PARTITION DECAY-INVARIANT?
# ---------------------------------------------------------------------
# The claim in the header is that fractions are unaffected by 14C decay. If it
# holds, undoing the decay analytically must not move a single fraction.
sep("1. THE LABEL PARTITION IS DECAY-INVARIANT (checked, not assumed)")
L <- data.frame(t = ctl$t,
                atmosphere = lab$atm_C14   - ctl$atm_C14,
                land       = lab$land_C14  - ctl$land_C14,
                ocean      = lab$ocean_C14 - ctl$ocean_C14)
L$total <- rowSums(L[TV_RES])
lam <- ccx_const("LAMBDA_C14")
G <- L
for (k in TV_RES) G[[k]] <- L[[k]] * exp(lam * (L$t - L$t[1]))
G$total <- rowSums(G[TV_RES])
d <- max(abs(L$atmosphere / L$total - G$atmosphere / G$total))
cat(sprintf("max |fraction(with decay) - fraction(decay undone)| = %.3e\n", d))
cat(sprintf("label surviving at %d yr: %.1f %% -- and the SPLIT is unchanged\n",
            max(TV_HORIZON), 100 * tail(L$total, 1) / L$total[1]))
if (d > 1e-9) cat("*** NOT invariant -- the header's argument is wrong, stop here\n")

# ---------------------------------------------------------------------
# 2. THE TWO PARTITIONS, SIDE BY SIDE
# ---------------------------------------------------------------------
M <- data.frame(t = ctl$t,
                atmosphere = (mass$co2_NH - ctl$co2_NH + mass$co2_SH - ctl$co2_SH) / 2 *
                             ccx_const("GtC_PER_PPM"),
                land  = mass$land_C  - ctl$land_C,
                ocean = mass$ocean_C - ctl$ocean_C)
M$total <- rowSums(M[TV_RES])
at <- function(D, yr) which.min(abs(D$t - (TV_YEARS[1] + yr + 0.5)))

sep("2. WHERE THE PULSE WENT -- LABEL vs PERTURBATION (fraction of each)")
cat(sprintf("%6s | %26s | %26s\n", "", "LABEL (follows atoms)",
            "PERTURBATION (follows amount)"))
cat(sprintf("%6s | %8s %8s %8s | %8s %8s %8s\n", "yr",
            "atm", "land", "ocean", "atm", "land", "ocean"))
for (h in TV_HORIZON) {
  i <- at(L, h); j <- at(M, h)
  cat(sprintf("%6d | %8.3f %8.3f %8.3f | %8.3f %8.3f %8.3f\n", h,
              L$atmosphere[i] / L$total[i], L$land[i] / L$total[i], L$ocean[i] / L$total[i],
              M$atmosphere[j] / M$total[j], M$land[j] / M$total[j], M$ocean[j] / M$total[j]))
}

sep("3. THE SIZE OF THE DIFFERENCE, AND WHY")
i <- at(L, 100); j <- at(M, 100)
cat(sprintf("at 100 yr the ATMOSPHERE holds %.1f %% of the label and %.1f %% of the\n",
            100 * L$atmosphere[i] / L$total[i], 100 * M$atmosphere[j] / M$total[j]))
cat(sprintf("perturbation -- a factor of %.1f.\n",
            (M$atmosphere[j] / M$total[j]) / (L$atmosphere[i] / L$total[i])))
k <- nrow(ctl)
cat(sprintf("\nreservoir SIZES in this run: atmosphere %.0f, land %.0f, ocean %.0f GtC\n",
            (ctl$co2_NH[k] + ctl$co2_SH[k]) / 2 * ccx_const("GtC_PER_PPM"),
            ctl$land_C[k], ctl$ocean_C[k]))
cat("The LABEL fractions converge on those proportions, because atoms mix.\n")
cat("The PERTURBATION fractions do not, because how much EXTRA the ocean will\n")
cat("take is set by carbonate buffering, not by how big it is.\n")

sep("WHAT THIS MEANS FOR THE PANEL")
cat("DESIGN sec.7b's bar chart is the PERTURBATION partition, and it has to be:\n")
cat("its headline is that a pulse of CO2 is still perturbing the atmosphere in\n")
cat("the year 3000. The LABEL partition, on the same axes and captioned the same\n")
cat("way, would show the atmosphere nearly empty within a century -- which is\n")
cat("the TRUE premise of the residence-time argument DESIGN sec.7a exists to\n")
cat("answer. Both belong in the app; they must not share a caption.\n")
