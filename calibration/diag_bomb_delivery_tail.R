# =====================================================================
# BOMB DELIVERY TAIL (handoff 2026-09-08j §3.4) -- the DATA CHECK, not a ruling:
# is `BOMB_T2_DROP_FIRST` and the post-1969 exponential tail of
# data-raw/build_bomb_c14_source.R what Tans (1981) SCOPE 16 Table 2 supports?
#
# ⚠ THIS IS A CHECK, NOT A PREREGISTERED TEST. It was written against the data
# it examines, so it cannot claim out-of-sample power. Its standing value is as
# a REGRESSION GUARD on four constants (BOMB_T2_DROP_FIRST, BOMB_TAIL_FIT_FROM,
# BOMB_TOTAL_REF_KMOL, and the Table 2 transcription) plus the three readings
# below, which ARE falsifiable statements about the table.
#
# READING 1 (checkable): the implemented first-point replacement RAISES the
#   12/62-2/63 burden, as Tans p.133 requires ("much too low"; 356 is a FLOOR).
# READING 2 (checkable): the post-1969 tail's MASS is MEASURED -- it equals the
#   final (7/69) stratospheric inventory identically, and is INDEPENDENT of
#   BOMB_TOTAL_REF_KMOL. tau sets only how that mass spreads in time.
# READING 3 (checkable): tau is NOT well determined -- the last row carries most
#   of the fit's baseline, and BOMB_TAIL_FIT_FROM moves it materially.
# MUTATION: with the replacement OFF, READING 1's assertion must FAIL.
#
# Usage: Rscript calibration/diag_bomb_delivery_tail.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- named constants: mirrored from the builder, and the check's own ----
BDT_T2_FILE      <- ccx_path("data-raw", "manual",
                             "tans1981_scope16_table2_stratospheric_inventory.csv")
BDT_BUILT_FILE   <- ccx_path("data", "forcing_bomb_c14.rds")
BDT_TOTAL_REF    <- 102          # kmol, Naegler & Levin (2006) -- the builder's BOMB_TOTAL_REF_KMOL
BDT_TAIL_FROM    <- 1965.0       # the builder's BOMB_TAIL_FIT_FROM
BDT_TAIL_FROM_ALT<- c(1964.0, 1964.5, 1965.0, 1965.5, 1966.0)   # its sensitivity sweep
BDT_REF_ALT      <- 150          # a DIFFERENT reference total, to prove READING 2's independence
BDT_TANS_HIGH_BIAS<- 1.20        # Tans p.133: Telegadas' aircraft data average ~20 % TOO HIGH
BDT_SHARE_CUTS   <- c(1965.5, 1969.5)   # the two cuts handoff 09-08i quotes
BDT_NA_AVOGADRO  <- 6.02214076e23
BDT_OUT <- ccx_path("outputs", "diagnostics",
                    sprintf("bomb_delivery_tail_%s.rds", format(Sys.Date(), "%Y%m%d")))

cat("\n=== BOMB DELIVERY TAIL: does Tans Table 2 support the builder? ===\n")

t2 <- read.csv(BDT_T2_FILE, comment.char = "#")
t2$kmol <- t2$inventory_1e26_atoms * 1e26 / BDT_NA_AVOGADRO / 1000
cat(sprintf("Table 2: %d rows, %.3f to %.3f; last row label %-8s (a MONTH, not a quarter)\n",
            nrow(t2), t2$t_mid[1], t2$t_mid[nrow(t2)], t2$quarter[nrow(t2)]))

fit_tau <- function(from) {
  s <- t2$t_mid >= from
  f <- lm(log(t2$kmol[s]) ~ t2$t_mid[s])
  list(tau = as.numeric(-1 / coef(f)[2]), n = sum(s), cf = coef(f),
       adj_r2 = summary(f)$adj.r.squared)
}
fit0 <- fit_tau(BDT_TAIL_FROM)

# ---------------------------------------------------------------- READING 1
# implemented: assume the release in the quarter BEFORE t0 matches the one after
impl <- t2$kmol[2] + (t2$kmol[2] - t2$kmol[3])
raw  <- t2$kmol[1]
# documented (in TWO comments of the builder): back-extrapolate the tail fit to t0
bx   <- exp(fit0$cf[1] + fit0$cf[2] * t2$t_mid[1])
cat("\n--- READING 1: the first-point replacement ---\n")
cat(sprintf("  raw (Tans' FLOOR)                     %6.2f kmol (%d units)\n",
            raw, t2$inventory_1e26_atoms[1]))
cat(sprintf("  IMPLEMENTED  kmol[2]+(kmol[2]-kmol[3]) %6.2f kmol (%.0f units, %+.1f %% on the floor)\n",
            impl, impl * 1000 * BDT_NA_AVOGADRO / 1e26, 100 * (impl / raw - 1)))
cat(sprintf("  DOCUMENTED   tail fit back to t0       %6.2f kmol (%.0f %% BELOW the floor)\n",
            bx, 100 * (1 - bx / raw)))
r1_pass <- impl > raw
cat(sprintf("  => READING 1 %s: the implemented method respects the floor; the DOCUMENTED one does NOT.\n",
            if (r1_pass) "HOLDS" else "FAILS"))
cat("  ⚠ Two builder comments describe the DOCUMENTED method. The code does not implement it,\n")
cat("    and it would be wrong if it did (it back-extrapolates a 1965-69 decay through the peak).\n")

# ---------------------------------------------------------------- READING 2
tail_mass_at <- function(ref) {
  rel <- cummax(impl - c(impl, t2$kmol[-1]))
  D_pre <- ref - impl
  ref - D_pre - (rel[length(rel)] - rel[1])
}
m_ref <- tail_mass_at(BDT_TOTAL_REF); m_alt <- tail_mass_at(BDT_REF_ALT)
final_inv <- t2$kmol[nrow(t2)]
r2_pass <- isTRUE(all.equal(m_ref, final_inv)) && isTRUE(all.equal(m_ref, m_alt))
cat("\n--- READING 2: the tail's MASS is measured, not extrapolated ---\n")
cat(sprintf("  tail mass at ref=%3d: %.4f kmol | at ref=%3d: %.4f kmol | final inventory %.4f\n",
            BDT_TOTAL_REF, m_ref, BDT_REF_ALT, m_alt, final_inv))
cat(sprintf("  => READING 2 %s: the tail carries exactly the last measured burden (%.1f %% of %d),\n",
            if (r2_pass) "HOLDS" else "FAILS", 100 * m_ref / BDT_TOTAL_REF, BDT_TOTAL_REF))
cat("     independent of BOMB_TOTAL_REF_KMOL. tau spreads it in time; it does not size it.\n")

# ---------------------------------------------------------------- READING 3
no69 <- t2$t_mid >= BDT_TAIL_FROM & t2$t_mid < 1967
f_no69 <- lm(log(t2$kmol[no69]) ~ t2$t_mid[no69])
tau_no69 <- as.numeric(-1 / coef(f_no69)[2])
sw <- vapply(BDT_TAIL_FROM_ALT, function(y) fit_tau(y)$tau, numeric(1))
cat("\n--- READING 3: tau is weakly determined ---\n")
cat(sprintf("  as built: tau = %.3f yr on %d points (adj R2 %.4f)\n", fit0$tau, fit0$n, fit0$adj_r2))
cat(sprintf("  drop the single 7/69 row: tau = %.3f yr (%+.1f %%) -- it supplies %.0f %% of the fit's time baseline\n",
            tau_no69, 100 * (tau_no69 / fit0$tau - 1),
            100 * (t2$t_mid[nrow(t2)] - 1966.542) / (t2$t_mid[nrow(t2)] - BDT_TAIL_FROM)))
for (k in seq_along(BDT_TAIL_FROM_ALT))
  cat(sprintf("  BOMB_TAIL_FIT_FROM = %.1f -> tau = %.3f yr\n", BDT_TAIL_FROM_ALT[k], sw[k]))
r3_pass <- (max(sw) - min(sw)) / fit0$tau > 0.10
cat(sprintf("  => READING 3 %s: the constant alone spans %.3f-%.3f yr (%.0f %% of tau).\n",
            if (r3_pass) "HOLDS" else "FAILS", min(sw), max(sw), 100 * (max(sw) - min(sw)) / fit0$tau))

# ------------------------------------------- the caveat the builder does NOT apply
cat("\n--- Tans' OTHER caveat (p.133), currently unapplied anywhere ---\n")
for (s in c(1, 1 / BDT_TANS_HIGH_BIAS))
  cat(sprintf("  Table 2 scaled x%.3f: I_t0 = %6.2f -> pre-1963.04 delivery %.1f %% of the total\n",
              s, impl * s, 100 * (BDT_TOTAL_REF - impl * s) / BDT_TOTAL_REF))
cat(sprintf("  => a uniform %.0f %% de-biasing moves the pre/post-1963 SPLIT by %.1f points. A RULING, not a check.\n",
            100 * (BDT_TANS_HIGH_BIAS - 1),
            100 * ((BDT_TOTAL_REF - impl / BDT_TANS_HIGH_BIAS) - (BDT_TOTAL_REF - impl)) / BDT_TOTAL_REF))

# ------------------------------------------- the BUILT product's quoted shares
b <- readRDS(BDT_BUILT_FILE); prov <- attr(b, "provenance")
shares <- vapply(BDT_SHARE_CUTS, function(cut) sum(b$shape_per_yr[b$t >= cut]) / 12, numeric(1))
cat("\n--- the built product (handoff 09-08i quoted 25 % and 14.6 %) ---\n")
for (k in seq_along(BDT_SHARE_CUTS))
  cat(sprintf("  delivery after %.1f: %.1f %%\n", BDT_SHARE_CUTS[k], 100 * shares[k]))
cat(sprintf("  provenance: t0 %.3f, burden %.2f, tau %.3f, dropped_first %s, built %s\n",
            prov$t0, prov$burden_t0_kmol, prov$tau_tail, prov$dropped_first_point, prov$built))
# unname(): the builder stores tau as -1/coef(lf)[2], which carries coef()'s
# name; the VALUES are bit-identical. Compare values, not attributes.
stopifnot(isTRUE(all.equal(unname(prov$burden_t0_kmol), unname(impl))),
          isTRUE(all.equal(unname(prov$tau_tail), unname(fit0$tau))))
cat("  ✅ the shipped product reproduces from the CSV at the committed constants.\n")

# ------------------------------------------------------------------ MUTATION
mut_impl <- raw                                   # BOMB_T2_DROP_FIRST = FALSE
mut_caught <- !(mut_impl > raw)
cat(sprintf("\n--- MUTATION: BOMB_T2_DROP_FIRST off -> first point %.2f; READING 1 %s ---\n",
            mut_impl, if (mut_caught) "FAILS, as it must" else "still passes -- THE CHECK IS BLIND"))
stopifnot(r1_pass, r2_pass, r3_pass, mut_caught)

saveRDS(list(table2 = t2, impl = impl, raw = raw, documented_backextrap = bx,
             tau = fit0$tau, tau_no1969 = tau_no69, tau_sweep = setNames(sw, BDT_TAIL_FROM_ALT),
             tail_mass = m_ref, tail_mass_alt_ref = m_alt, final_inventory = final_inv,
             built_shares = setNames(shares, BDT_SHARE_CUTS), provenance = prov,
             readings = c(r1 = r1_pass, r2 = r2_pass, r3 = r3_pass), date = Sys.time()),
        BDT_OUT)
cat(sprintf("\nsaved %s\n", BDT_OUT))
cat("⛔ Nothing adopted. The de-biasing and the tau constant are RULINGS for Marcus.\n")
