#!/bin/bash
# MUTATION TEST for diag_rep_dc_prior_profile.R -- a gate that passes is not a
# gate that works. Each mutation BREAKS exactly what one gate guards; the gate
# must FAIL. Writes only into the scratchpad.
set -u
SP="$1"; cd /Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator
run () { # $1 = name, $2 = expected-failing gate, $3 = R mutation body
  d="$SP/mut_$1"; rm -rf "$d"; mkdir -p "$d/lad" "$d/out"
  cp outputs/diagnostics/rep_dc_product_ladder_20260923/*.rds "$d/lad/"
  Rscript -e "d<-'$d/lad'; $3" >/dev/null 2>&1
  out=$(RPP_LADDER_DIR="$d/lad" RPP_OUTDIR="$d/out" \
        Rscript calibration/diag_rep_dc_prior_profile.R 2>&1)
  # the ONLY unambiguous signal is the driver's own stop(); a header line is not
  if grep -q "^Error: $2 failed" <<<"$out"; then
    echo "  PASS  $1 -> $2 stopped the run, as required"
    grep -m3 "⛔\|differs\|conv !=\|FAIL" <<<"$out" | sed 's/^/          /'
  else
    echo "  *** BROKEN GATE ***  $1 -> $2 did NOT stop the run"
    grep -m3 "GATE\|Error" <<<"$out" | sed 's/^/          /'
  fi
}
echo "== MUTATION TEST: diag_rep_dc_prior_profile.R =="
run objective  "GATE PROV"  "f<-file.path(d,'job05_rung_3.000.rds'); x<-readRDS(f); x\$provenance\$objective<-'#12'; saveRDS(x,f)"
run nonconv    "GATE PROV"  "f<-file.path(d,'job07_rung_2.000.rds'); x<-readRDS(f); x\$conv<-1L; saveRDS(x,f)"
run kink       "GATE SHAPE"   "f<-file.path(d,'job08_rung_1.500.rds'); x<-readRDS(f); x\$products\$scalar[['logpost']]<-x\$products\$scalar[['logpost']]-20; saveRDS(x,f)"
run dominance  "GATE DOMINANCE" "for (f in list.files(d,full.names=TRUE)) { x<-readRDS(f); x\$products\$scalar[['loglik']]<-x\$products\$scalar[['loglik']]-3; x\$products\$scalar[['logpost']]<-x\$products\$scalar[['logpost']]-3; saveRDS(x,f) }"
