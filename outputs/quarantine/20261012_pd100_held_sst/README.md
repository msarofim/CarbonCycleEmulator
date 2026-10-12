# QUARANTINE 2026-10-12 — every scorecard's PD100 section ran the HELD builder with observed SST left running

Ruled by Marcus, 2026-10-12: "Re-run + quarantine (Recommended)".

## 1. The bugs, and what they touch

The scorecard's PD100 comparisons (§4: the gate-12 IRF and the gate-L split; the "THE JOOS IRF"
section in the 09-08 logs) were built by the HELD-climate builder, `ccx_pulse_forcings()` in
`R/joos_irf.R`. That builder was consolidated on 2026-10-01 (`1d754e8`) and was bit-identical at
`hilda29l` to the builders before it. It had two bugs, both fixed on 2026-10-12 (CHANGELOG 10-12 (b) §3):

1. **GMST was held by hand, and observed SST was left running.** NH SST went 0.72 → 1.29 K over
   2010–2024, and the ocean reads SST (`sst_obs` = 1, since 2026-08-18 `98fd871`, which is before
   every scorecard here). Effect measured at `hilda29e`: IRF **+0.20 %** at 100 yr and **+0.30 %** at 300 yr.
2. **T_deep restarted at 0** at each seam (2010, 2015), against the history's 0.148 K. Effect: **−0.01 %**.

All of these files also use the HELD protocol (temperature held at 2010). Since 2026-10-12, by
Marcus's ruling ("free everywhere"), the protocol is climate FREE, as in Joos 2013.

⚠ **Only the PD100 sections are affected.** Every other section of these files (the gates,
streams, ENSO slope, strained priors) is VALID and is the historical record of its arm. They are
moved here so that a held-builder IRF or partition is never read from a canonical path again.
The 10-11 (c) audit had read card 5's split from `whole_model_scorecard_20261008_hilda33p_obj18p2.rds`.

## 2. Files (52, moved with `git mv`, so the history follows them)

- `whole_model_scorecard_*.log` (25) and `.rds` (26): every scorecard from 2026-09-08 to 2026-10-08.
  The 09-08 logs print the IRF under "=== 4. THE JOOS IRF"; the later ones print "12 IRF" / "L split".
  Every `.rds` carries an `irf` element, and every `.rds` from 09-11 on also carries `partition`.
- `tl_land_share_gate_20260908.{log,rds}`: gate L's land share at `hilda31`, on the held builder.

**Left in place, by choice:** three scorecard `.rds` files inside dry-run bundles
(`outputs/diagnostics/obj16_landing_dryrun_20261005_ocgobm_tree/…`,
`outputs/diagnostics/obj18_dryrun_20261007/run{1,2}_*/…`). Each belongs to a self-contained
bundle, and moving one would break its bundle.

**Readers updated:** `calibration/diag_ta1_enso_thermocline_limb.R` (`TA1_P0_REF`) reads the 09-13
`hilda30c` scorecard's ENSO section, which is valid, and now points here. Two comments name a
moved file and were left alone: `tests/testthat/test-gate-bounds.R:499` and `calibration/diag_phi0_futures.R:8`.

## 3. The canonical replacements

- `outputs/diagnostics/whole_model_scorecard_20261012_hilda29e.{log,rds}`: `@6dadf00`, the first
  scorecard at `hilda29e`, PD100 climate FREE. Every arm reproduces its stored streams (`hilda29e`
  +5.2e-06, `hilda31pe` −6.7e-07). It reproduces card 5 (`rv_pulse()`) exactly: IRF 20/100/300
  0.522 / 0.379 / 0.295; 1000-yr split land 17 / ocean 58 / air 25 %, z +0.20 / −0.23 / −0.01.
- `outputs/diagnostics/tl_land_share_gate_20261012.{log,rds}` (10-12 (b)).

There is no free-protocol replacement for the retired arms' scorecards. Their PD100 numbers are
records of the held protocol, measured with the ≤ 0.3 % defect above.
