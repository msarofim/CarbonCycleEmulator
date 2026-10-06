#!/bin/bash
# Mutations of the eval-rate fix (9b05553): each applied in a scratch worktree, test-ms-deadline.R run under a
# 120-s alarm, the file restored from HEAD. A mutation must make at least one test FAIL (an ERROR is read, not counted).
cd "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/ec70f71f-7c3d-4944-b7ff-1d869ce951b8/scratchpad/mut_tree" || exit 1
run_mut() { # name file from to
  python3 /private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/ec70f71f-7c3d-4944-b7ff-1d869ce951b8/scratchpad/mutate.py "$2" "$3" "$4" || { echo "$1: SKIPPED (not applied)"; return; }
  res=$(OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 perl -e 'alarm shift; exec @ARGV' 120 Rscript --vanilla -e 'suppressMessages(library(testthat)); r <- as.data.frame(test_file("tests/testthat/test-ms-deadline.R", reporter = "silent")); f <- r$test[r$failed > 0]; e <- r$test[r$error]; cat(if (length(f)) paste("CAUGHT (failure) by:", paste(sub(":.*", "", f), collapse = ", ")) else "*** NOT CAUGHT ***", if (length(e)) paste(" | ERROR in:", paste(sub(":.*", "", e), collapse = ", ")) else "")' 2>&1 | tail -1)
  echo "$1: ${res:-*** NO RESULT (alarm or crash) ***}"
  git checkout -q -- "$2"
}
L=calibration/lib_ms_deadline.R; D=calibration/run_dispersed_multistart.R
echo "baseline: $(OMP_NUM_THREADS=1 Rscript --vanilla -e 'suppressMessages(library(testthat)); r <- as.data.frame(test_file("tests/testthat/test-ms-deadline.R", reporter = "silent")); cat(sum(r$passed), "passed", sum(r$failed), "failed", sum(r$error), "errors")' 2>&1 | tail -1)"
run_mut ME1_mean_not_max   $L 'c(slowest = 60 * max(restart_min) / maxit_full' 'c(slowest = 60 * mean(restart_min) / maxit_full'
run_mut ME2_minutes_not_s  $L 'c(slowest = 60 * max(restart_min) / maxit_full' 'c(slowest = max(restart_min) / maxit_full'
run_mut ME3_fixed_maxit    $L 'c(slowest = 60 * max(restart_min) / maxit_full' 'c(slowest = 60 * max(restart_min) / 6000'
run_mut ME4_driver_old     $D '.rate <- ms_eval_rate_sec(restart_min, MS_MAXIT)' '.rate <- c(slowest = 60 * sum(restart_min) / n_eval, fastest = NA)'
run_mut ME5_polish_own_sum $L 'ms_eval_rate_sec(restart_min, maxit_full)[["slowest"]] else sec_per_eval' '60 * mean(restart_min) / maxit_full else sec_per_eval'
run_mut ME6_no_null_guard  $L 'if (!length(restart_min) || !(max(restart_min) > 0)) return(NULL)' 'if (FALSE) return(NULL)'
echo "tree after: [$(git status --porcelain | tr '\n' ' ')] (empty = every mutation restored)"
