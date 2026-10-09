#!/bin/bash
# 2026-10-09 (b): the MCMC band at hilda29e, the 200k LANDING (Marcus 10-09: "Extend to 200k (Recommended)", "Thin x2
# within chain (Recommended)"). It REPORTS; whether a band ships is Marcus's.
#   1. wait for the four chains (R PIDs in ~/ccx_frozen/20261009a_mcmc_extend.pids) with kill -0, never pgrep -f
#   2. every chain's log must say "COMPLETE: 200000 iterations", or stop
#   3. snapshot the chain files into the repo; everything after reads the SNAPSHOT, never the live dir
#   4. read_mcmc_check.R (drop 0; window (30000, 200000]; --pool-thin=2) -> pooled_u_thin2.rds
#   5. build_futures_ribbons.R --draws (thinned x2 within chain, chain-by-chain order kept; 8 cores)
#   6. diag_mcmc_band_by_chain.R --laplace=none (no Laplace band exists at hilda29e); 7. diag_mcmc_drift.R
# Runs from the main checkout; nothing it runs may be edited while it runs (bash and Rscript both read
# their scripts as they go). Torch verdict (said out loud): Mac -- ~2.6 h on 8 free cores after the chains.
set -u
ROOT="/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator"
PIDS="$HOME/ccx_frozen/20261009a_mcmc_extend.pids"
CHAIN_OUT="$HOME/ccx_frozen/20261008j_mcmc_chain"
LIVE="$HOME/ccx_frozen/20261008j_mcmc/outputs/mcmc_check_20261008j_hilda29e"
N_ITER=200000
POOL_THIN=2
SNAP="outputs/mcmc_check_20261009_hilda29e_200k"
POOLED="$SNAP/pooled_u_thin2.rds"
RIB="outputs/diagnostics/futures_ribbons_mcmc_20261009_hilda29e_200k.rds"
TAG="hilda29e_200k"
CORES=8
DIR="outputs/diagnostics/mcmc_200k_landing_20261009"
cd "$ROOT" || exit 1
exec >> "$DIR/land.log" 2>&1
echo "=== land.sh start $(date '+%Y-%m-%d %H:%M:%S') @$(git -C "$ROOT" rev-parse --short HEAD) ==="

for p in $(cat "$PIDS"); do while kill -0 "$p" 2>/dev/null; do sleep 60; done; done
echo "chains exited $(date '+%H:%M:%S')"
for c in 1 2 3 4; do
  grep -q "chain $c COMPLETE: $N_ITER iterations" "$CHAIN_OUT$c.out" || { echo "STOP: chain $c did not complete"; tail -3 "$CHAIN_OUT$c.out"; exit 2; }
  grep "chain $c COMPLETE" "$CHAIN_OUT$c.out"
done

if [ -e "$SNAP" ]; then echo "STOP: $SNAP already exists"; exit 3; fi
mkdir -p "$SNAP" && cp -p "$LIVE"/chain_1.rds "$LIVE"/chain_2.rds "$LIVE"/chain_3.rds "$LIVE"/chain_4.rds "$SNAP"/ || exit 3
for c in 1 2 3 4; do
  a=$(md5 -q "$LIVE/chain_$c.rds"); b=$(md5 -q "$SNAP/chain_$c.rds")
  echo "chain_$c.rds md5 live $a snapshot $b"; [ "$a" = "$b" ] || { echo "STOP: snapshot differs"; exit 3; }
done

export VECLIB_MAXIMUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
echo "--- read $(date '+%H:%M:%S')"
caffeinate -i -s Rscript calibration/read_mcmc_check.R --dir="$SNAP" --pool-thin=$POOL_THIN > "$DIR/read.out" 2>&1 || { echo "STOP: read rc $?"; exit 4; }
echo "--- build $(date '+%H:%M:%S')"
caffeinate -i -s Rscript calibration/build_futures_ribbons.R --draws="$POOLED" --cores=$CORES --out="$RIB" > "$DIR/build.out" 2>&1 || { echo "STOP: build rc $?"; exit 5; }
echo "--- by chain $(date '+%H:%M:%S')"
caffeinate -i -s Rscript calibration/diag_mcmc_band_by_chain.R --ribbons="$RIB" --draws="$POOLED" --laplace=none --tag=$TAG > "$DIR/bychain.out" 2>&1 || { echo "STOP: by-chain rc $?"; exit 6; }
echo "--- drift $(date '+%H:%M:%S')"
caffeinate -i -s Rscript calibration/diag_mcmc_drift.R --dir="$SNAP" --pooled="$POOLED" --ribbons="$RIB" --tag=$TAG > "$DIR/drift.out" 2>&1 || { echo "STOP: drift rc $?"; exit 7; }
echo "=== land.sh done $(date '+%Y-%m-%d %H:%M:%S') ==="
