# =====================================================================
# diag_p12_streams.R -- WHERE the compensator buys its likelihood, and
# where the seasonal mixed layer buys and pays its own.
#
# Reads the committed artifact of diag_p12_compensator_redundant.R (which
# already stored per-stream contributions on every grid point) and does
# arithmetic on it. ⭐ No model is run here, so this cannot drift from the
# profile it describes; and it reads a COMMITTED artifact, never its own
# output ([[gate_reads_its_own_output]]).
#
# THE TWO CONTRASTS, both differences of measured stream vectors:
#   SHIM  = arm(seas_ml=0) at its argmax ent, MINUS the same arm at ent = 0
#           -> what the fitted compensator is worth, and IN WHICH STREAMS.
#   MECH  = arm(seas_ml=1) at ent = 0, MINUS arm(seas_ml=0) at ent = 0
#           -> what the seasonal mixed layer is worth ALONE, with the
#              compensator OFF ON BOTH SIDES, so the two are not confounded.
#
# ⚠ Both are CONDITIONAL on the canonical's other 30 parameters. They say
# where the value sits, not what a refit would do.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

TAG     <- "20260909"
IN_RDS  <- file.path("outputs", "diagnostics", paste0("p12_compensator_", TAG, ".rds"))
OUT_LOG <- file.path("outputs", "diagnostics", paste0("p12_streams_", TAG, ".log"))
TOP_N   <- 12

x  <- readRDS(IN_RDS)
g  <- x$grid
at <- function(arm, e) x$profile[[which(g == e)]][[arm]]$streams

con <- file(OUT_LOG, open = "wt")
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = con) }

e_star <- g[which.max(x$total_off)]
shim <- at("off", e_star) - at("off", 0)
mech <- at("on", 0)       - at("off", 0)

say("P12 -- WHERE THE LIKELIHOOD SITS, BY STREAM")
say("source: %s (no model run here)", IN_RDS)
say("SHIM = seas_ml 0 at ent %.1f minus ent 0   |   MECH = seas_ml 1 minus 0, BOTH at ent 0",
    e_star)
say("")
say("  %-26s %12s %12s", "stream", "SHIM", "MECH")
for (n in names(shim)[order(-abs(shim))][seq_len(TOP_N)])
  say("  %-26s %12.2f %12.2f", n, shim[[n]], mech[[n]])
say("  %-26s %12.2f %12.2f", "TOTAL", sum(shim), sum(mech))

seas <- grep("seasonal", names(shim), value = TRUE)
lev  <- grep("^co2_level", names(shim), value = TRUE)
say("")
say("⭐ THE SHIM IS A SEASONAL-SPO COMPENSATOR, NOT A GENERAL FUDGE:")
say("   seasonal rows carry %.2f of its %.2f = %.1f %%, and `co2_seasonal_SPO` alone %.2f (%.1f %%)",
    sum(shim[seas]), sum(shim), 100 * sum(shim[seas]) / sum(shim),
    shim[["co2_seasonal_SPO"]], 100 * shim[["co2_seasonal_SPO"]] / sum(shim))
say("   ⇒ option A is the RIGHT CLASS of replacement: the thing being replaced really is")
say("     a Southern-Ocean seasonal channel.")
say("")
say("⭐⭐ AND THE MECHANISM'S NET HIDES AN ENORMOUS INTERNAL SPLIT:")
say("   it BUYS %.2f on `co2_seasonal_SPO` -- %.0f %% of what the FITTED shim buys there --",
    mech[["co2_seasonal_SPO"]],
    100 * mech[["co2_seasonal_SPO"]] / shim[["co2_seasonal_SPO"]])
say("   with NO FITTED AMPLITUDE, which is the out-of-sample criterion;")
say("   and it PAYS %.2f on the CO2 LEVEL rows (%s).",
    sum(mech[lev]), paste(lev, collapse = ", "))
say("   NET %.2f.", sum(mech))
say("")
say("⇒ THE MECHANISM IS NOT FAILING AT THE SEASONAL CYCLE. It is SUCCEEDING there and")
say("  paying on the MEAN CO2 LEVEL -- which is the signature of the anthropogenic-uptake")
say("  change P10 measured (industrial-window NH drift 7.72 %% of amplitude, quiet window")
say("  settled). ⭐ A LEVEL offset is the most REFITTABLE kind of error: it is controlled by")
say("  k_w, kz, the pump and fert_k, all currently pinned at values tuned for the")
say("  no-mechanism configuration. Had it failed ON the seasonal stream, no refit would help.")
say("")
say("⚠ CONDITIONAL on the canonical's other 30 parameters. This says WHERE the value sits,")
say("  not what a refit will do -- and it is what the refit must be judged on.")
close(con)
cat("wrote", OUT_LOG, "\n")
