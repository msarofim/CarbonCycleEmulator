# start_harness.R -- evaluate a multistart DRIVER's own top-level code up to and including
# `st <- ms_start(MS_ID)` (and the duplicate refusal right after it, when the driver has one), then save
# the start. NO optimisation runs. Used to compare the pre-fix driver (HEAD 3c0bfd8) with the fixed one
# bit for bit under a real arm's environment (CCX_MS_* set by the caller).
# Usage: Rscript start_harness.R <driver.R> <out.rds>
args <- commandArgs(TRUE); drv <- args[1]; out <- args[2]
ex <- parse(drv, keep.source = FALSE)
dep <- vapply(ex, function(e) paste(deparse(e, width.cutoff = 500L), collapse = " "), "")
k <- which(dep == "st <- ms_start(MS_ID)")
stopifnot(length(k) == 1L)
for (i in seq_len(k)) eval(ex[[i]], globalenv())
res <- list(driver = drv, id = MS_ID, u = st$u, kind = st$kind, draws = st$draws,
            class = if (is.null(st$class)) NA_character_ else st$class,
            free = CCX_PARAM_NAMES, pins = MS_PINS, assert = NA_character_)
if (grepl("ms_assert_distinct_start", dep[k + 1L], fixed = TRUE))
  res$assert <- tryCatch({ eval(ex[[k + 1L]], globalenv()); "pass" }, error = function(e) conditionMessage(e))
saveRDS(res, out)
cat(sprintf("HARNESS id %d class %s draws %d assert %s\n  kind: %s\n", MS_ID, res$class, st$draws, res$assert, st$kind))
