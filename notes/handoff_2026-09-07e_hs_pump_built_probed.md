# Handoff — 2026-09-07e. The HS pump is BUILT (both cores) and PROBED at the round-2 winner: right magnitude, +17 unrefitted, but its pre-registered gate FAILS by one log-unit and the HS SURFACE δ¹³C moves the wrong way. Registered as the 30th parameter; round 3 DRAFTED, NOT launched.
# **⛔ NOTHING ADOPTED. Canonical `ent26`. Torch idle. ⇒ NEXT IS MARCUS'S RULING on `notes/prereg_2026-09-07e_hs_pump_round3_DRAFT.md`: the prior, objective #11 (HS-surface rows), launch or not.**

Read: CHANGELOG 2026-09-07e (the scan table), `prereg_2026-09-07d_hs_pump_probe.md` (+ amendment), the round-3 DRAFT,
then `handoff_2026-09-07d_area_fix_and_hs_options.md`.

## 1. What was done
- `pump_hs_gcm2` in `ccx_default_params()` (0 = off, bit-exact), `ccx_pump_export_hs()`, emission in both cores beside
  the `u_hs` limb; `tests/testthat/test-pump-hs.R` (5 tests incl. mutation and parity). Pump/HILDA/parity/likelihood
  test files all pass; the pre-existing failing set is unchanged (mode-file, mode-decode, seas-lag-split, enso-demean,
  enso-split — all verified failing at HEAD in 09-07d).
- Probe `calibration/diag_hs_pump_probe.R` → `outputs/diagnostics/hs_pump_probe_20260907.{log,rds}`; the first,
  over-sized run is `diag_hs_pump_probe_20260907_run1_rel.log` (kept; see the prereg amendment for why the sizing
  convention changed from relative-to-LS to absolute gC m⁻² yr⁻¹).
- `CCX_PARAM_TABLE$pump_hs_gcm2` [0.5, 200], uniform, init 60; migration absent → 0 → seeded 60 (verified on start 44).

## 2. The verdict, stated plainly
At 60 gC m⁻² yr⁻¹ (3.47 GtC/yr from 16 % of the ocean): HD − HS +127 (obs +116–185), bottom − HS δ¹³C −0.70 (obs
−0.87), profile inside 2σ (level −1.70), sink/bomb unmoved, Δlik **+17.2**, δ¹³C row +18.9 of the −27.6 it had lost.
P3 needed 20; P6 needed HS surface δ¹³C to fall toward +1.31 and it rose to +2.08. **Gate FAIL by the letter; the
mechanism is doing exactly what the end-member probe said was missing.** The launch is a judgement call ⇒ Marcus.

## 3. State / open
Torch idle. 30 parameters in the table; two mode-file tests fail on purpose (no 30-name canonical). Owed regardless:
the pump and ALK solves' operator (conduit + HS limb); a SOURCED Southern-Ocean export number before any prior;
`ent26`'s own 19 GtC/yr export (73.6 at the winner) is ~2–4× real and unpriced. ⚠ LS pump OFF + HS pump ON =
singular spinup Jacobian (not a supported state).
