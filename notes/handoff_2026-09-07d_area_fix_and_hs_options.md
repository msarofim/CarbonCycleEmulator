# Handoff — 2026-09-07d. A bookkeeping bug in the gradient rows FIXED and round 2 re-scored (verdicts unchanged; ALK is the second loss, not DIC); the HS end-member PROBED against GLODAP — its DIC is right, the deep under it lacks +116–185 µmol/kg; option (b) REFUTED, option (a) pre-checks at the observed magnitude.
# **⛔ NOTHING ADOPTED. Canonical `ent26`. Torch idle. ⇒ NEXT IS MARCUS'S RULING on `notes/options_2026-09-07d_hs_biology.md` (recommendation: an HS pump, (a), with the operator-consistency fix (e)).**

Read: CHANGELOG 2026-09-07d, `notes/options_2026-09-07d_hs_biology.md`, then `handoff_2026-09-07c_round2_result.md` (+ its addendum).

## 1. What was done
- **Memory:** `INDEX_ccx_ocean_struct` split (17.3 → 13.4 KB) — circulation limbs / Fix B / ocean ENSO / older
  candidates → `INDEX_ccx_ocean_circ.md`; 40 links before and after, no orphans; registered in `MEMORY.md` and
  FaIRtoFrEDI `CLAUDE.md`. Live-state header rewritten to 09-07c/d.
- **Bug:** `ccx_model_ocean_gradient()`, the ALK steady solve and `dg_gateG()` divided by `a_oc`; the boxes span
  `a_ls`. `ccx_column_area()` fixes all four sites; `tests/testthat/test-ocean-grad-area.R` (3 tests) is
  mutation-tested on a scratch copy. Pre-fix scoring quarantined (`outputs/quarantine/20260907_grad_area_a_oc/`),
  re-scored to canonical names: DIC −6.05 → −3.96, ALK −7.06 → **−13.80**, rest −43.1 → **−47.8**.
- **Probe:** `calibration/diag_hs_endmember_probe.R` → `outputs/diagnostics/hs_endmember_probe_20260907.{log,rds}`.
  HS DIC 2169 = cold equilibrium = observed SH high-lat surface 2163; bottom − HS +12 vs observed deep − HI
  +116 (SH) / +185; δ¹³C HS +1.96 vs +1.31 observed, bottom − HS 0.00 vs −0.87.
- Retraction propagated: CHANGELOG 09-07c, handoff 09-07c (addendum), prereg 09-07b (re-scored line), memory
  `ccx_hilda_round2_result` and the struct index all carry the corrected numbers.

## 2. State
Torch: nothing running. Objective #10 ON, 29 parameters, `hs_asx_frac` floor 0.02. Test suite: see the
commit message for the failing set (two mode-file tests and `kz$hi <= 7000` fail on purpose from earlier
sessions). The round-2 start files are NOT moved. `MEMORY.md` root content 13.3 KB (soft 12, hard 18).

## 3. Open
The ruling. If (a): build `pump_hs_rel` in both cores (bit-exact at 0), run the one-spinup probe at the winner
first (predictions P1–P6 in the options note), then a pre-registered round 3 under the CORRECTED rows with the
HS-surface rows added to the objective. Source the Southern-Ocean export magnitude before it becomes a prior.
