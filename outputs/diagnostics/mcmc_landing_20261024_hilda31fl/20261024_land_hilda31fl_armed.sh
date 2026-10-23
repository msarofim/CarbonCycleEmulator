#!/bin/bash
# hilda31fl MCMC LANDING, armed 2026-10-23 (handoff 10-23 §4.1-4.3; CHANGELOG 2026-10-23 v). Marcus: "Read handoff ... and continue work".
# Frozen worktree ~/ccx_frozen/20261024_land_hilda31fl at d1e3c476, data-raw/downloads linked per file (79 links + 3 tracked = 82):
# without them the nuclear-14C source is zero (10-14 b). Nothing in that tree may be edited while this runs.
# Torch verdict, said out loud: Mac (the chains land here; the CCX R env and compiled core are verified here; 10 cores free
# once the chains exit; the hilda31w band took 216 min on 8).
#
# WAIT: on the four chain PIDs with kill -0, each also checked to still BE run_mcmc_check.R (PID reuse). Never a pgrep loop.
# PHASE 1 (reports only; the handoff's prescribed reads, no ruling needed):
#   every chain at iter == n (else STOP: a chain died; the MCMC launch script resumes it), snapshot into the frozen tree
#   (cp -p, cmp against the source, md5s; chain logs + launch script into logs/), read_mcmc_check.R --drop=0,
#   diag_mcmc_identifiability.R.
# PHASE 2 (ONLY if $RULED exists; it holds Marcus's verbatim ruling and DROP= / THIN= lines, read with grep, never sourced):
#   read_mcmc_check.R --drop=$DROP --pool-thin=$THIN, then in parallel
#     band: build_futures_ribbons.R (8 cores) -> diag_mcmc_band_by_chain.R --laplace=none -> diag_mcmc_drift.R (h_ml + four worst R-hats)
#     tie:  diag_cmap_posterior_spread.R, 100 draws, 1 core
#   NOTHING is promoted: promote_futures_ribbons.R, promote_cmap_stability.R and the ship call are Marcus's.
set -u
W=/Users/MarcusMarcus/ccx_frozen/20261024_land_hilda31fl
MCMC_W=/Users/MarcusMarcus/ccx_frozen/20261023_mcmc_hilda31fl
SRC=$MCMC_W/outputs/mcmc_check_20261023_hilda31fl
PIDS=/Users/MarcusMarcus/ccx_frozen/20261023_mcmc_hilda31fl.pids
LOGSRC=/Users/MarcusMarcus/ccx_frozen/20261023_mcmc_hilda31fl
RULED=/Users/MarcusMarcus/ccx_frozen/20261024_land_hilda31fl.RULED
N_ITER=200000
POLL=120
cd "$W" || exit 1
export OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OMP_NUM_THREADS=1
n=$(find data-raw/downloads -maxdepth 1 -type l | wc -l); [ -e data-raw/downloads/nuclear14c ] && [ "$n" -ge 79 ] || { echo "REFUSING: data-raw/downloads not linked per file ($n links)"; exit 3; }
[ -z "$(git -C "$W" status --porcelain --untracked-files=no)" ] || { echo "REFUSING: tracked files edited in the frozen tree"; exit 3; }
echo "=== armed $(date '+%Y-%m-%d %H:%M:%S') @$(git -C "$W" rev-parse --short HEAD); waiting on $(tr '\n' ' ' < "$PIDS")==="

# ---- WAIT --------------------------------------------------------------------
for p in $(cat "$PIDS"); do
  while kill -0 "$p" 2>/dev/null && ps -p "$p" -o command= | grep -q "run_mcmc_check.R"; do sleep "$POLL"; done
  echo "pid $p exited by $(date '+%H:%M:%S')"
done

# ---- PHASE 1 -------------------------------------------------------------------
echo "=== PHASE 1 $(date '+%Y-%m-%d %H:%M:%S') ==="
for c in 1 2 3 4; do
  it=$(Rscript -e "cat(readRDS('$SRC/chain_$c.rds')\$iter)" 2>/dev/null)
  echo "chain $c: iter $it; $(tail -1 "$LOGSRC"_chain$c.out)"
  [ "$it" = "$N_ITER" ] || { echo "STOP: chain $c at iter '$it', not $N_ITER (resume with ${LOGSRC}_launch.sh)"; exit 4; }
done
SNAP=outputs/mcmc_check_$(date +%Y%m%d)_hilda31fl_200k
mkdir -p "$SNAP/logs" || exit 5
for c in 1 2 3 4; do
  cp -p "$SRC/chain_$c.rds" "$SNAP/" && cmp "$SRC/chain_$c.rds" "$SNAP/chain_$c.rds" || { echo "STOP: snapshot of chain $c differs"; exit 5; }
  cp -p "$LOGSRC"_chain$c.out "$SNAP/logs/"
done
cp -p "$LOGSRC"_launch.sh "$SNAP/logs/"
(cd "$SNAP" && md5 -r chain_*.rds > MD5SUMS); cat "$SNAP/MD5SUMS"
echo "snapshot $SNAP: 4 chains cmp-identical to $SRC"
echo "--- read drop 0 $(date '+%H:%M:%S')"
Rscript calibration/read_mcmc_check.R --dir="$SNAP" --drop=0 > "$SNAP/read_drop0.out" 2>&1 || { echo "STOP: read rc $?"; exit 6; }
grep -E "^R-hat|^ESS|^window" "$SNAP/read_drop0.out"
echo "--- identifiability $(date '+%H:%M:%S')"
Rscript calibration/diag_mcmc_identifiability.R --draws="$SNAP/pooled_u.rds" --out-dir="$SNAP" > "$SNAP/identifiability.out" 2>&1 || { echo "STOP: identifiability rc $?"; exit 7; }
grep -E "^GATE" "$SNAP/identifiability.out"
echo "=== PHASE 1 done $(date '+%Y-%m-%d %H:%M:%S') ==="

# ---- PHASE 2 (ruled only) ------------------------------------------------------------
if [ ! -f "$RULED" ]; then echo "=== no $RULED: PHASE 2 not run; the band and tie runs wait for Marcus ==="; exit 0; fi
echo "=== PHASE 2 $(date '+%Y-%m-%d %H:%M:%S'); ruling file:"; cat "$RULED"; echo "==="
DROP=$(grep -E '^DROP=[0-9]+$' "$RULED" | head -1 | cut -d= -f2)
THIN=$(grep -E '^THIN=[0-9]+$' "$RULED" | head -1 | cut -d= -f2)
[ -n "$DROP" ] && [ -n "$THIN" ] || { echo "STOP: $RULED lacks a DROP=<int> or THIN=<int> line"; exit 8; }
if [ "$DROP" = "0" ]; then POOLED=$SNAP/pooled_u_thin$THIN.rds; else POOLED=$SNAP/pooled_u_drop${DROP}_thin$THIN.rds; fi
[ "$DROP" = "0" ] && [ "$THIN" = "1" ] && POOLED=$SNAP/pooled_u.rds
echo "--- read drop $DROP thin $THIN $(date '+%H:%M:%S')"
Rscript calibration/read_mcmc_check.R --dir="$SNAP" --drop="$DROP" --pool-thin="$THIN" --out="$POOLED" > "$SNAP/read_drop${DROP}_thin$THIN.out" 2>&1 || { echo "STOP: read rc $?"; exit 9; }
tail -1 "$SNAP/read_drop${DROP}_thin$THIN.out"
CSV=$(ls "$SNAP"/diag_*_drop"$DROP".csv | head -1)
# diag_mcmc_drift.R requires h_ml (its floor share reads it): h_ml plus the four worst other R-hats (hilda31w's five held it at 5th)
NAMES=$(Rscript -e "d <- read.csv('$CSV'); u <- colnames(readRDS('$POOLED')); d <- d[d\$name %in% setdiff(u, 'h_ml'), ]; cat(paste(c(head(d\$name[order(-d\$rhat)], 4), 'h_ml'), collapse = ','))")
TAG=hilda31fl_200k
RIB=outputs/diagnostics/futures_ribbons_mcmc_$(date +%Y%m%d)_hilda31fl_200k.rds
echo "pooled $POOLED (md5 $(md5 -q "$POOLED")); drift names $NAMES; ribbons -> $RIB"
uptime
(
  echo "--- band build $(date '+%H:%M:%S')"
  caffeinate -i -s Rscript calibration/build_futures_ribbons.R --draws="$POOLED" --cores=8 --out="$RIB" > "$SNAP/band_build.out" 2>&1 || { echo "STOP: build rc $?"; exit 10; }
  echo "--- band by chain $(date '+%H:%M:%S')"
  caffeinate -i -s Rscript calibration/diag_mcmc_band_by_chain.R --ribbons="$RIB" --draws="$POOLED" --laplace=none --tag=$TAG > "$SNAP/band_bychain.out" 2>&1 || { echo "STOP: by-chain rc $?"; exit 11; }
  echo "--- band drift $(date '+%H:%M:%S')"
  caffeinate -i -s Rscript calibration/diag_mcmc_drift.R --dir="$SNAP" --pooled="$POOLED" --ribbons="$RIB" --tag=$TAG --names="$NAMES" > "$SNAP/band_drift.out" 2>&1 || { echo "STOP: drift rc $?"; exit 12; }
  echo "--- band done $(date '+%H:%M:%S')"
) &
BAND=$!
(
  echo "--- tie spread $(date '+%H:%M:%S')"
  caffeinate -i -s Rscript calibration/diag_cmap_posterior_spread.R --draws="$POOLED" --chains="$SNAP" --n=100 --cores=1 > "$SNAP/cmap_spread.out" 2>&1 || { echo "STOP: tie spread rc $?"; exit 13; }
  echo "--- tie done $(date '+%H:%M:%S')"
) &
TIE=$!
wait $TIE; echo "tie rc $?"
wait $BAND; echo "band rc $?"
echo "=== PHASE 2 done $(date '+%Y-%m-%d %H:%M:%S'); nothing promoted ==="
