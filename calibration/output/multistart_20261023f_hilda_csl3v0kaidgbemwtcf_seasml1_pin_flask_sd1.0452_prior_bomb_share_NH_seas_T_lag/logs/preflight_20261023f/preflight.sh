#!/bin/bash
# THE FLASK REFIT (Marcus 2026-10-22, verbatim: "Local refit from T8c's point (Recommended)", "Add it as a third
# (Recommended)", "Carry module, then check (Recommended)"; CHANGELOG 2026-10-23 f). Label hilda_csl3v0kaidgbemwtcf (every
# Mauna Loa CO2 row on Scripps flask, CHANGELOG 10-22 g), seas_ml 1, PINS = the canonical's (R/paths.R CCX_MODE_FLASK_PINS =
# CCX_MODE_OBJ18P2_PINS: #16's ten + the interannual module's four), so 31 free names.
# THREE starts, all fixed (no dispersed draw):
#   id 1  hilda31w scored under the flask label: the incumbent of ccx_ms_reference_set()'s flask branch, a START
#         (port target -1067.5979272958);
#   id 6  T8c's block point (-1052.232908) and id 7  T8f's Newton point (-1050.185317): FILE starts from
#         calibration/torch/file_starts_<LAB>.rds, each gated on T8f's value before any budget is spent.
# From the frozen worktree at 7bd37b94, the git-ignored downloads APFS-cloned (diff -rq identical); port targets committed
# at 7bd37b94 (made in the repo at 6d00fcd8; logs/port_targets_<TAG>.log). Preflight 3/3 LAUNCHABLE (logs/preflight_<TAG>/).
# The WTC recipe on the CPU clock: BUDGET 300 CPU-min, 3 restarts x 6 cycles x 6000 maxit; spread 1.0452 (it disperses
# nothing here; set because the outdir and the driver's dispersion label carry it). The outdir is NAMED (the driver's
# default carries the 14 pins, over macOS's 255-byte limit) and says the prior draw (the driver requires it).
# Torch verdict, said out loud: the Mac. It is ~2x faster per evaluation, and three tasks are far below the width at which
# Torch's parallelism pays. Launched under nohup; the Mac launcher holds caffeinate -i -s itself.
set -u
T="$HOME/ccx_frozen/20261023_flask"; LAB=hilda_csl3v0kaidgbemwtcf; TAG=20261023f
PINS="$(cat "$T/logs/pins_$TAG.txt")"
cd "$T" || exit 1
unset CCX_MS_ID; export CCX_MS_PREFLIGHT=1
export CCX_MS_STRUCT="$LAB" CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452 CCX_MS_PIN="$PINS" CCX_MS_TAG=$TAG
export CCX_MS_FILE_STARTS="calibration/torch/file_starts_${LAB}.rds" CCX_MAC_IDS="1 6 7" CCX_MAC_NPAR=3
export CCX_MS_BUDGET_MIN=300 CCX_MS_CLOCK=cpu CCX_MS_RESTARTS=3 CCX_MS_CYCLES=6 CCX_MS_MAXIT=6000
export CCX_MS_OUTDIR="$T/calibration/output/multistart_${TAG}_${LAB}_seasml1_pin_flask_sd1.0452_prior_bomb_share_NH_seas_T_lag"
echo "flask refit PREFLIGHT start $(date '+%Y-%m-%dT%H:%M:%S%z') at $(git -C "$T" rev-parse --short HEAD)"
bash calibration/mac/run_multistart_mac.sh > "logs/preflight_$TAG.log" 2>&1
rc=$?
echo "flask refit PREFLIGHT end $(date '+%Y-%m-%dT%H:%M:%S%z') rc $rc"
