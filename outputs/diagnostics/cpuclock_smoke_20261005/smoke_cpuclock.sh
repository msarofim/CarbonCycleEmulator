#!/bin/bash
# The CPU-clock build's END-TO-END smokes (handoff 10-05d §5.6), on objective #16's config, id 1.
#   T0 THE MAC RUNNER, a one-task PREFLIGHT on the CPU clock: its banner, the clock it exports, and the driver's
#      preflight labels ("CPU-s/eval", "CPU-min budget"). Exit 0.
#   T1 BEHAVIOUR-PRESERVING: the OLD driver (2ed310a), the NEW one (0038262; its driver = 8691199), and the NEW one
#      read through the legacy name CCX_MS_WALL_MIN, all on the WALL clock with a budget big enough that the NM
#      restart is not shortened. Its log line (log-post, gain, evals) must be IDENTICAL in all three. The polish is
#      sized from a measured rate in every build, so it is not compared.
#   T1c both budget names set and DIFFERENT: the driver stops at start-up.
#   T3 A REAL SUSPEND: the NEW driver, 3-min budget, MAXIT 6000 (the budget binds), one arm per clock. Each R
#      process is SIGSTOPped 60 s after its rate line, for 180 s, then CONTinued.
#      Pre-registered: the CPU arm's restart is NOT stopped by the suspension (it reaches its sized maxit, or a
#      deadline well after the CONT); its `minutes` stay near its 3-min budget while `minutes_wall` exceed them by
#      >= 2.9. The WALL arm's budget is spent INSIDE the stop: its restart STOPS AT THE DEADLINE at the first check
#      after the CONT, with fewer evals than the CPU arm's.
# ⛔ Run only after #16's landing step 1: the landing helper counts every run_dispersed_multistart.R process.
set -u
OLD=$HOME/ccx_frozen/20261005h_cpuclock_old      # detached at 2ed310a (pre-build)
NEW=$HOME/ccx_frozen/20261005h_cpuclock_smoke    # detached at 0038262 (the build; its driver = 8691199)
LOG=$HOME/ccx_frozen/20261005h_cpuclock_smoke_logs; mkdir -p "$LOG"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
export CCX_MS_STRUCT=hilda_csl3v0kaidgbem CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452
export CCX_MS_PIN="ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,npp_tsens=0"
unset CCX_MS_WALL_MIN CCX_MS_BUDGET_MIN CCX_MS_CLOCK CCX_MS_PREFLIGHT CCX_MS_ID CCX_MS_OUTDIR
echo "smokes start $(date '+%H:%M:%S')"

# ---- T0: the runner's preflight, one task, the CPU clock (the runner's default)
( cd "$NEW" && CCX_MS_PREFLIGHT=1 CCX_MAC_IDS=1 CCX_MAC_NPAR=1 CCX_MS_TAG=SMOKEpre \
    bash calibration/mac/run_multistart_mac.sh > "$LOG/T0_runner_preflight.log" 2>&1; echo "T0 runner rc $?" )
cp -p "$NEW/logs/ccx_multistart_mac_SMOKEpre_001.out" "$LOG/T0_task_001.log" 2>/dev/null

export CCX_MS_ID=1 CCX_MS_RESTARTS=1 CCX_MS_CYCLES=1
launch() {  # tree outname logname extra-env...
  local tree=$1 name=$2 lg=$3; shift 3
  ( cd "$tree" && env CCX_MS_OUTDIR="$tree/calibration/output/$name" "$@" \
      Rscript --vanilla calibration/run_dispersed_multistart.R > "$LOG/$lg" 2>&1; echo "$lg rc $?" ) &
}
# ---- T1c: both names, different -> a stop at start-up
( cd "$NEW" && CCX_MS_OUTDIR="$NEW/calibration/output/SMOKE_T1c" CCX_MS_BUDGET_MIN=12 CCX_MS_WALL_MIN=11 \
    Rscript --vanilla calibration/run_dispersed_multistart.R > "$LOG/T1c_conflict.log" 2>&1; echo "T1c rc $? (expect non-zero)" )
# ---- T1: old vs new vs new-through-the-legacy-name, wall clock, MAXIT 200, budget 12 min
launch "$OLD" SMOKE_T1_old   T1_old.log   CCX_MS_WALL_MIN=12   CCX_MS_MAXIT=200
launch "$NEW" SMOKE_T1_new   T1_new.log   CCX_MS_BUDGET_MIN=12 CCX_MS_MAXIT=200
launch "$NEW" SMOKE_T1_alias T1_alias.log CCX_MS_WALL_MIN=12   CCX_MS_MAXIT=200
# ---- T3: new driver, both clocks, 3-min budget
launch "$NEW" SMOKE_T3_cpu  T3_cpu.log  CCX_MS_BUDGET_MIN=3 CCX_MS_MAXIT=6000 CCX_MS_CLOCK=cpu
launch "$NEW" SMOKE_T3_wall T3_wall.log CCX_MS_BUDGET_MIN=3 CCX_MS_MAXIT=6000 CCX_MS_CLOCK=wall
sleep 5
# the T3 R processes, found by the log each holds open (lsof), never by a pgrep pattern this script's text carries
pid_of() { lsof -t "$LOG/$1" 2>/dev/null | while read -r p; do ps -o comm= -p "$p" | grep -q '/R$' && echo "$p"; done | head -1; }
suspend_after_rate() {  # log
  local lg=$1 p=""
  for i in $(seq 1 900); do grep -q '^measured ' "$LOG/$lg" 2>/dev/null && break; sleep 1; done
  sleep 60
  p=$(pid_of "$lg"); [ -n "$p" ] || { echo "$lg: NO R PROCESS FOUND"; return; }
  echo "$lg: SIGSTOP pid $p at $(date '+%H:%M:%S')"; kill -STOP "$p"
  sleep 180
  echo "$lg: SIGCONT pid $p at $(date '+%H:%M:%S')"; kill -CONT "$p"
}
suspend_after_rate T3_cpu.log &
suspend_after_rate T3_wall.log &
wait
echo "smokes end $(date '+%H:%M:%S')"
