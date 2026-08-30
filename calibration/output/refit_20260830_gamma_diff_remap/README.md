# refit_20260830_gamma_diff_remap — the 21-parameter refit ONTO THE POST-ADOPTION objective

**Launched 2026-08-30** by the session continuing `notes/handoff_2026-08-30b_the_seven_ruled.md` §4.
This is the refit handoff 08-30 declared **OWED AND NOT RUN**. Nothing here is a result until both
`*/mode_fit_pumpN.rds` carry a completion timestamp and both `_run.log`s end with the comparison write.

## WHY THIS DIRECTORY EXISTS

The objective changed AGAIN on **2026-08-29k (`a2298dc`)**: `CCX_GAMMA_DIFF_DEFAULT = 0.25` (diffuse
light ON by default, explicitly **not** behaviour-preserving) and `ccx_pump_shape()` replaced by a C1
cumulative remap. **Every pre-adoption fitted vector is non-comparable**, including the incumbent
canonical mode. Measured: the incumbent's own logpost falls **40.49** across the adoption
(`calibration/diag_attribute_the_seven.R` part 5).

⚠ It ALSO carries the **2026-08-30 fix** to `ccx_deriv()`'s absent-`gamma_diff` fallback (commit
`6639e3f`): before it, the R reference resolved an absent `gamma_diff` to 0 while `ccx_cpp_par()`
gave 0.25 — a 0.647 GtC/yr R↔C++ split, and `ccx_mode_params()` is exactly such a list. **This refit
is the first fitted under both cores agreeing.**

## SETUP — Marcus's calls, 2026-08-30

- **BOTH ARMS.** `from90` (free) and `pin90` (`fert_k` pinned at 90 via `CCX_PIN_PARAMS`). The pinned
  arm is what re-measures `PIN_PRIOR_CREDIT` and closes the one deliberately-failing test
  (`test-mode-file.R`), whose recomputed gap moved **−11.49 → −19.86** across gamma — a LIKELIHOOD
  differential, not provenance drift.
- **`h_ml` UNBOUNDED over its shipped support [30, 200]**, prior NOT renormalised. This is already
  the tracked driver's behaviour since the 08-28 inversion, and both original reasons for the bound
  are now discharged: the sigma-inflation adoption retired the skip, and the C1 remap removed the
  26 kinks. Startup gates H1/H2/H3 confirm it each run.

## PROVENANCE OF THE INPUTS

- **Warm start:** each arm's `mode_fit_pumpN.rds` was SEEDED as a byte copy of its incumbent —
  `refit_20260825f_from90` (md5 `1551d000c166beabe43b87717ed3c6f0`) and `refit_20260825f_pin90`
  (md5 `c40e346bb53e6c1ce41ed36d0cf87600`) — so `ARM_WARM` picks it up and the driver overwrites in
  place. Warm-starting across an objective change is safe because `par_mode` is band-INDEPENDENT and
  is re-encoded under this run's table; `u_mode` is NOT (memory `ccx_hml_band_provenance`).
  ⚠ **NOT** warm-started from `refit_20260828_sigma_eff` — that one is RATIFIED "do not adopt".
- **Driver:** `run_modefind_pump_arms_FROZEN.R` is a byte copy of
  `calibration/run_modefind_pump_arms.R` at commit **`6639e3f`**, taken BEFORE launch. The run
  executes the FROZEN copy, not the tracked file, because Rscript parses incrementally and editing a
  live script shifts byte offsets under the running process (memory `never_edit_a_running_script`).
  **The tracked driver may be edited during this run; this copy may not.**
- **Code state:** commit `6639e3f`, suite 1243 pass / 1 fail (deliberate) / 2 skip.

## THE SMOKE THAT PRECEDED IT (both arms, `RESTARTS=1 CYCLES=1 MAXIT=60`)

Ran end-to-end, exit 0 on both. Warm start → one BFGS polish:

| arm | warm start | after polish | gain |
|---|---|---|---|
| `from90` | −1585.1 | −1547.2 | **37.95** |
| `pin90`  | −1593.4 | −1556.1 | **37.30** |

The free arm recovering ~38 of the 40.49 the adoption cost the frozen vector, in a single
unconverged polish, is the right order for the recorded CONDITIONAL price of diffuse light
(−7.42, memory `ccx_diffuse_light`).

⚠ **DO NOT READ PARAMETER VALUES OFF THE SMOKE.** `handoff_2026-08-28c` §3 makes this point against
its own smoke's alarming `h_ml` = 35.38 m, whose entire gain was prior credit bought with a worse
fit. This smoke lands `h_ml` at 35.25 / 36.99 — the SAME behaviour, and it is a MAXIT=60 artefact
until the converged run says otherwise. `kz` still rails (95.1 % / 97.7 %), as it has every time.

## ⚠ A GATE IN THIS DRIVER THAT CAN NO LONGER FAIL

The kink scan now prints `0 kink(s) in [30, 200]` — correct, the remap removed all 26 — and then
fires `*** the kink count has CHANGED since diag_hess_eps_21par.R -- re-run it` on **every** run,
because the check is `!= 3`. A message that always fires is noise. **The substantive half is real
and OWED**: `diag_hess_eps_21par.R` chose its Hessian step against a KINKED objective, so the step
study must be re-run against the C1 objective before any covariance off this refit is trusted.
Left unmodified pending a ruling.
