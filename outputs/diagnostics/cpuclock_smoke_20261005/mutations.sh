#!/bin/bash
# Mutation tests for the CPU-clock build: each mutation is applied, test-ms-clock.R is run under a 120-s alarm,
# and the file is restored from the branch commit. A mutation must make at least one test FAIL.
cd "$HOME/ccx_frozen/20261005h_cpuclock" || exit 1
MU=/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/1b62e59e-b583-47e7-ba32-c67737f959b0/scratchpad/mutate.py
run_mut() { # name file from to
  python3 $MU "$2" "$3" "$4" || { echo "$1: SKIPPED (not applied)"; return; }
  res=$(OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 perl -e 'alarm shift; exec @ARGV' 120 Rscript --vanilla -e 'suppressMessages(library(testthat)); r <- as.data.frame(test_file("tests/testthat/test-ms-clock.R", reporter = "silent")); f <- r$test[r$failed > 0 | r$error]; cat(if (length(f)) paste("CAUGHT by:", paste(sub(":.*", "", f), collapse = ", ")) else "*** NOT CAUGHT ***")' 2>&1 | tail -1)
  echo "$1: ${res:-*** NO RESULT (alarm or crash) ***}"
  git checkout -q -- "$2"
}
L=calibration/lib_ms_deadline.R; D=calibration/run_dispersed_multistart.R
run_mut MC1_fallback  $L 'if (!v %in% MS_CLOCK_KINDS)' 'if (!v %in% MS_CLOCK_KINDS) return("wall"); if (FALSE)'
run_mut MC2_check_reads_wall $L 'if (ms_clock(state$clock) > state$deadline)' 'if (as.numeric(Sys.time()) > state$deadline)'
run_mut MC3_cpu_is_elapsed $L 'unname(pt[["user.self"]] + pt[["sys.self"]])' 'unname(pt[["elapsed"]])'
run_mut MC4_cpu_is_children $L 'unname(pt[["user.self"]] + pt[["sys.self"]])' 'unname(pt[["user.child"]] + pt[["sys.child"]])'
run_mut MC5_step_default_clock $D 'MS_STEP <- ms_step_state(MS_CLOCK)' 'MS_STEP <- ms_step_state()'
run_mut MC6_sys_time_in_driver $D '.r0 <- ms_now(); .n0 <- n_eval' '.r0 <- as.numeric(Sys.time()); .n0 <- n_eval'
run_mut MC7_absent_clock_NA $L 'if (is.null(r$clock)) "wall" else r$clock' 'if (is.null(r$clock)) NA_character_ else r$clock'
run_mut MC8_no_mix_warning calibration/collect_dispersed_multistart.R '.mix <- ms_clock_mix_note(clk, ids)' '.mix <- NULL'
run_mut MC9_torch_cpu calibration/torch/multistart.sbatch 'export CCX_MS_CLOCK=wall' 'export CCX_MS_CLOCK=cpu'
run_mut MC10_mac_wall calibration/mac/run_multistart_mac.sh '${CCX_MS_CLOCK:-cpu}' '${CCX_MS_CLOCK:-wall}'
run_mut MC11_no_wall_warned_record $D '            wall_warned = wall_warned,' ''
run_mut MC12_state_ignores_clock $L 's$clock <- ms_clock_kind(clock)' 's$clock <- "wall"'
run_mut MC13_origin_on_wall $D 't0 <- ms_now(); t0_wall <- ms_clock("wall")' 't0 <- ms_clock("wall"); t0_wall <- ms_clock("wall")'
echo "tree after: [$(git status --porcelain | tr '\n' ' ')] (empty = every mutation restored)"
