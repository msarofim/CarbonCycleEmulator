#!/bin/bash
# THE WTC REFIT (Marcus 2026-10-12, verbatim: "Carry module, then check (Recommended)"; "Mac overnight, #18's recipe
# (Recommended)"; citation rulings ledger D; CHANGELOG 2026-10-12 ff). Label hilda_csl3v0kaidgbemwtc (the citation batch:
# every changed value + the two new fitted names, bomb_share_NH U[0.77, 0.98] and seas_T_lag U[0, 6] months), seas_ml 1,
# PINS = hilda29e's (#18 pass 2's set: #16's ten + the interannual module's four; R/paths.R CCX_MODE_WTC_PINS), so 31 free
# names. INCUMBENT hilda29e at its own model (bomb_share_NH 0.90, seas_T_lag 2.0: ccx_migrate_par_set()'s WTC contract),
# a START; new basin the seas_ml-0 control hilda31pe. Dispersed starts draw the two new names FROM THEIR PRIORS.
# From the frozen worktree at 1e66077, the git-ignored downloads APFS-cloned (diff -rq identical; 14/14 inputs), port
# targets regenerated there under this pin set (logs/port_targets_20261012ff.log; incumbent -1062.9494406 = hilda29e's
# stored -1166.9497 + the pricing's +106.95 likelihood + the two names' prior/Jacobian -2.949). Preflight 24/24
# LAUNCHABLE, every port VERIFIED (incumbent rel 2.1e-14), 0.325 CPU-s/eval at id 1 (logs/preflight_20261012ff/).
# 24 starts, 8 at a time, #18's recipe on the CPU clock: BUDGET 300 CPU-min, 3 restarts x 6 cycles x 6000 maxit, spread
# 1.0452. The outdir is NAMED (the driver's default carries the 14 pins, over macOS's 255-byte limit) and says the prior
# draw (the driver requires it). Torch verdict, said out loud: Mac, overnight, as ruled (the Mac is ~2x faster per
# evaluation; Torch wins only 24-wide). Launched under nohup; the Mac launcher holds caffeinate -i -s itself.
set -u
T="$HOME/ccx_frozen/20261012ff_wtc"; LAB=hilda_csl3v0kaidgbemwtc; TAG=20261012ff
PINS="$(cat "$T/logs/pins_$TAG.txt")"
cd "$T" || exit 1
unset CCX_MS_PREFLIGHT CCX_MS_ID
export CCX_MS_STRUCT="$LAB" CCX_MS_SEAS_ML=1 CCX_MS_SPREAD=1.0452 CCX_MS_PIN="$PINS" CCX_MS_TAG=$TAG CCX_MAC_NPAR=8
export CCX_MS_BUDGET_MIN=300 CCX_MS_CLOCK=cpu CCX_MS_RESTARTS=3 CCX_MS_CYCLES=6 CCX_MS_MAXIT=6000
export CCX_MS_OUTDIR="$T/calibration/output/multistart_${TAG}_${LAB}_seasml1_pin_wtc_sd1.0452_prior_bomb_share_NH_seas_T_lag"
echo "WTC refit start $(date '+%Y-%m-%dT%H:%M:%S%z') at $(git -C "$T" rev-parse --short HEAD)"
bash calibration/mac/run_multistart_mac.sh > "logs/wave_$TAG.log" 2>&1
rc=$?
echo "WTC refit end $(date '+%Y-%m-%dT%H:%M:%S%z') rc $rc"
