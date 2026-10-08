#!/bin/bash
# #18 PASS 2's landing chain (CHANGELOG 2026-10-08 d): land, collect, the basin decomposition, promote BOTH refits (id 1 =
# basin 1, RULED; id 2 = basin 2, the re-rank), each one's Hessian and ONE-PASS CHECK against the pass-2 module file (the
# ruled stopping rule, 0.1 sigma), basin 1's ocean driver, ONE scorecard, then the #18 read as an informational step.
# Stops at its first failure (the read excepted). Adopts nothing, commits nothing.
set -u
R="$HOME/Documents/2026/CodeProjects/CarbonCycleEmulator"; cd "$R" || exit 1
TAG=20261008d; LAB=hilda_csl3v0kaidgbemwt; DAY=$(date +%Y%m%d)
WAVE="$R/calibration/output/multistart_${TAG}_${LAB}_seasml1_pin_obj18p2_sd1.0452"
L="$R/outputs/diagnostics/obj18p2_landing_$DAY"; mkdir -p "$L"
P2MOD=$(Rscript -e 'for (f in list.files("R", pattern="[.]R$", full.names=TRUE)) source(f); cat(ccx_path(CCX_MODE_OBJ18P2_MODULE_FILE))' 2>/dev/null)
[ -f "$P2MOD" ] || { echo "no pass-2 module file"; exit 1; }
git diff --quiet -- R calibration tests || { echo "REFUSED: uncommitted changes under R/, calibration/ or tests/"; exit 1; }
step() { local name="$1"; shift; echo "== $name  $(date '+%H:%M:%S')"; if "$@" > "$L/$name.log" 2>&1; then echo "   rc 0";
  else local rc=$?; echo "   FAILED (rc $rc): see $L/$name.log"; tail -15 "$L/$name.log"; exit 1; fi; }
echo "#18 pass 2 landing chain at $(git rev-parse --short HEAD), $(date '+%Y-%m-%dT%H:%M:%S%z')"
step land bash "$HOME/ccx_frozen/20261008d_obj18p2_land.sh"
step collect env CCX_MS_OUTDIR="$WAVE" Rscript calibration/collect_dispersed_multistart.R
cp -p "$L/collect.log" "$WAVE/collect_$DAY.log"
step basins env CCX_O18_WAVE="$WAVE" CCX_O18_TAG="_p2" Rscript calibration/diag_obj18_basins.R
RULE="Marcus 2026-10-08: 'Basin 1, run the second pass, adopt if it passes'"
D1="$R/calibration/output/refit_${DAY}_obj18p2_${LAB}_basin1"; D2="$R/calibration/output/refit_${DAY}_obj18p2_${LAB}_basin2"
step promote_id001 Rscript calibration/promote_multistart_mode.R --name="obj18p2_${LAB}_basin1" --outdir="$WAVE" --dest="$D1" --id=1 \
  --why="basin 1, RULED ($RULE): the warm refit from hilda29a0 at the pass-2 pins"
step promote_id002 Rscript calibration/promote_multistart_mode.R --name="obj18p2_${LAB}_basin2" --outdir="$WAVE" --dest="$D2" --id=2 \
  --why="basin 2, refit beside basin 1 so the two are re-ranked at the pass-2 pins ($RULE)"
for B in 1 2; do D=$([ $B = 1 ] && echo "$D1" || echo "$D2"); M="$D/mode_fit_pumpN.rds"
  step "hessian_b$B" nice -n 10 Rscript calibration/recompute_hessian.R "$M" --update
  step "check_b$B" Rscript calibration/fit_iav_module.R --base="$M" --check="$P2MOD"
done
step ocean_b1 env CCX_OC_MODE="obj18p2b1=$D1/mode_fit_pumpN.rds" Rscript calibration/diag_ocean_climate_gobm.R
step scorecard env CCX_SC_EXTRA_MODE="hilda29w,hilda29a0,obj18p2b1=$D1/mode_fit_pumpN.rds,obj18p2b2=$D2/mode_fit_pumpN.rds" \
  CCX_SC_TAG_SUFFIX="_obj18p2" Rscript calibration/diag_whole_model_scorecard.R
for B in 1 2; do D=$([ $B = 1 ] && echo "$D1" || echo "$D2")
  echo "== read_b$B (informational: the #18 read, built for pass 1's references)  $(date '+%H:%M:%S')"
  env CCX_O18_MODE="$D/mode_fit_pumpN.rds" CCX_O18_WAVE="$WAVE" CCX_O18_TAG="_p2b$B" Rscript calibration/diag_obj18_refit_read.R > "$L/read_b$B.log" 2>&1; echo "   rc $?"
done
echo "== CHAIN DONE $(date '+%H:%M:%S'). Logs: $L"
