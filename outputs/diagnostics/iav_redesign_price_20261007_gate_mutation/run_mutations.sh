#!/usr/bin/env bash
# Mutation harness for calibration/diag_iav_redesign_price.R's gates (CHANGELOG 2026-10-07 d). Each mutation breaks
# what ONE gate guards, on a copy of the frozen driver; the run (smoke budgets) must STOP at that gate with its own
# message. M0, the driver as committed, passes (the smoke run). Usage: bash run_mutations.sh <frozen driver> <outdir>
set -u
DRV="$1"; OUT="$2"; SCR="${TMPDIR:-/tmp}/ccx_rp_mut_$$"; mkdir -p "$SCR"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 CCX_RP_SMOKE=1 CCX_RP_WORKERS=2 CCX_RP_OUTDIR="$SCR"
run_one() {  # id, sed expression, expected stop message (fixed string)
  local id="$1" expr="$2" want="$3" m="$SCR/$1.R"
  sed "$expr" "$DRV" > "$m"
  local nd; nd=$(diff "$DRV" "$m" | grep -c '^<')
  if [ "$nd" != "1" ]; then echo "$id: the mutation changed $nd lines, not 1 -- NOT RUN" | tee -a "$OUT/summary.txt"; return; fi
  diff "$DRV" "$m" > "$OUT/$id.diff"
  nice -n 10 Rscript "$m" > "$OUT/$id.log" 2>&1; local rc=$?
  if [ $rc -ne 0 ] && grep -qF "$want" "$OUT/$id.log"; then v="FAILS AS IT SHOULD (rc $rc, stopped at: $want)"
  else v="⚠ DID NOT STOP AT ITS GATE (rc $rc)"; fi
  echo "$id: $v" | tee -a "$OUT/summary.txt"
}
: > "$OUT/summary.txt"
echo "driver $DRV (md5 $(md5 -q "$DRV")), $(date '+%Y-%m-%d %H:%M')" | tee -a "$OUT/summary.txt"
run_one M1_wrapper_adds_nothing   's/st\[\[RP_OCEAN_ROW\]\] <- full + hc$/st[[RP_OCEAN_ROW]] <- full + 0 * hc/' \
  "the emulated low-pass ocean row is not the priced one"
run_one M2_objective_ignores_index 's/if (index != RP_SHIPPED) bp\$enso_index <- CCX_ENSO_INDEX_CODES\[\[index\]\]/if (index != RP_SHIPPED) bp$enso_index <- NULL; if (FALSE)/' \
  "the objective path and the dg path disagree under the switched index"
run_one M3_trend_reads_wrong_index 's/TR <- rbind(shipped = tr_of(RP_SHIPPED)/TR <- rbind(shipped = tr_of(RP_INDEX)/' \
  "the shipped index's trend is not the recorded one"
run_one M4_stage1_never_switches   's/VS <- with_index(VB, index)/VS <- VB/' \
  "does not carry the 'detrend' index"
run_one M5_resistance_wrong_pins   's/P1 = score(P1, RP_SHIPPED)/P1 = score(P1d, RP_SHIPPED)/' \
  "the resistance does not reproduce the stored prices"
run_one M6_slope_ignores_pins      's/V <- set_names(with_index(VB_B, index), pins\[CCX_IAV_MODULE_NAMES\])/V <- set_names(with_index(VB_B, index), P0[CCX_IAV_MODULE_NAMES])/' \
  "the ENSO ocean slope does not reproduce the iterate price's"
rm -rf "$SCR"
