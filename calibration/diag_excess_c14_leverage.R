# =====================================================================
# diag_excess_c14_leverage.R -- what would the ocean constraint have to be
# to actually move bomb_total?
#
# WHY THIS EXISTS. The ocean excess-14C term was added on 2026-08-11 and moved
# the mode's bomb_total by 1 % (151.2 -> 149.8). Before concluding that the
# constraint is powerless, establish whether that is a property of the model or
# of two choices made when the term was specified: WHICH observational target
# set (LIK_EXCESS_C14_TARGET) and HOW LARGE the shared method error
# (LIK_EXCESS_C14_REP_FRAC).
#
# METHOD. profile_bomb_total.R already re-optimised every other parameter at
# each fixed bomb_total, under both target sets. Two facts from that run make
# this cheap and safe:
#   * the modelled ocean excess is a function of bomb_total essentially alone
#     (52.7/64.4 vs 52.7/64.7 kmol at bt = 102 under the two target sets), so
#     the term can be re-scored on the stored excesses without re-optimising;
#   * the profile's own logpost minus its own excess term gives what the REST of
#     the likelihood prefers, which is the bar the constraint has to clear.
#
# READ IT AS: "the ocean term prefers the citable bomb total over the fitted one
# by N log-units; it only relocates the mode if N exceeds the bar." It is a
# leverage calculation on a fixed fit surface, NOT a re-fit, and it is not a
# marginal likelihood.
#
# Usage: Rscript calibration/diag_excess_c14_leverage.R
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

LEV_PROFILE   <- file.path("calibration", "output", "profile_bomb_total.rds")
LEV_REF_TARGET <- "table4_obs_range"   # the profile column the bar is read from
LEV_BT_FIT     <- 150                  # grid point nearest the fitted mode
LEV_BT_CITABLE <- 102                  # Naegler & Levin's total
LEV_REP_GRID   <- c(0, 0.02, 0.05, 0.10, 0.15, 0.20)

if (!file.exists(LEV_PROFILE))
  stop("run calibration/profile_bomb_total.R first -- ", LEV_PROFILE, " is missing")
tab <- readRDS(LEV_PROFILE)$table
exc <- readRDS(ccx_path("data", "obs_excess_c14.rds"))

term <- function(model_excess, target, rep_frac) {
  e <- ccx_excess_c14_target(exc, which = target, rep_frac = rep_frac)
  r <- model_excess - e$centre
  -0.5 * (drop(crossprod(r, e$prec %*% r)) + e$logdet + length(r) * log(2 * pi))
}

lp <- tab[tab$target == LEV_REF_TARGET, ]
row <- function(bt) lp[lp$bomb_total == bt, ]
excess_at <- function(bt) c(row(bt)$ocean_exc_1975, row(bt)$ocean_exc_1995)

# the bar: what everything EXCEPT this term prefers
bar <- (row(LEV_BT_FIT)$logpost - row(LEV_BT_FIT)$excess_term) -
       (row(LEV_BT_CITABLE)$logpost - row(LEV_BT_CITABLE)$excess_term)

cat(sprintf("bar: the likelihood WITHOUT the ocean term prefers bomb_total %d over %d\n",
            LEV_BT_FIT, LEV_BT_CITABLE))
cat(sprintf("     by %.1f log-units (chiefly the bomb-window D14C fit: rms %.1f vs %.1f permil)\n\n",
            bar, row(LEV_BT_FIT)$d14c_bomb_rms, row(LEV_BT_CITABLE)$d14c_bomb_rms))
cat(sprintf("model ocean excess: bt=%d -> %.1f / %.1f kmol ;  bt=%d -> %.1f / %.1f kmol\n\n",
            LEV_BT_FIT, excess_at(LEV_BT_FIT)[1], excess_at(LEV_BT_FIT)[2],
            LEV_BT_CITABLE, excess_at(LEV_BT_CITABLE)[1], excess_at(LEV_BT_CITABLE)[2]))

cat("ocean-term preference for the citable total, by target set and shared method error:\n")
cat(sprintf("  %-10s%s\n", "rep_frac",
            paste(sprintf("%22s", names(exc$targets)), collapse = "")))
for (rf in LEV_REP_GRID) {
  v <- vapply(names(exc$targets), function(tg)
    term(excess_at(LEV_BT_CITABLE), tg, rf) - term(excess_at(LEV_BT_FIT), tg, rf),
    numeric(1))
  cat(sprintf("  %-10.2f%s   %s\n", rf, paste(sprintf("%22.1f", v), collapse = ""),
              if (any(v > bar)) "<- clears the bar" else ""))
}
cat(sprintf("\nin use: LIK_EXCESS_C14_TARGET = '%s', LIK_EXCESS_C14_REP_FRAC = %.2f\n",
            LIK_EXCESS_C14_TARGET, LIK_EXCESS_C14_REP_FRAC))
cat("\nThe rank-one shared error is what collapses the difference between the two\n")
cat("target sets: the model overshoots BOTH years in the same direction, which is\n")
cat("exactly the direction a common method bias is allowed to explain. Only with\n")
cat("the tight set AND essentially no method error does the constraint outvote the\n")
cat("rest of the likelihood -- and what it would buy there is the ocean inventory\n")
cat("at the price of the atmospheric bomb window, not a model that fits both.\n")
