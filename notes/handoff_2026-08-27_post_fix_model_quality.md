# Handoff — CarbonCycleEmulator, 2026-08-27: the bug is fixed, the ridge flipped, and the
# NEXT PHASE IS A WHOLE-MODEL QUALITY ASSESSMENT

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `ea920e1`.
**Nothing is running.** Machine rebooted 2026-08-26 ~22:42.
**Supersedes** `notes/handoff_2026-08-26_seas_isotope_fix_and_refit.md` (still accurate; this one
adds the landed refit, the reparametrization null, and the next phase).

---

## 0. STATE IN EIGHT LINES

1. A **double discrimination** on the seasonal NEP flux was found and **FIXED in both cores**
   (`6bda464`). §2.
2. **THE OBJECTIVE CHANGED.** Every pre-fix vector, arm N included, is **quarantined**. §3.
3. A pre-registered 3-arm refit **FALSIFIED P3**: a free arm seeded at `fert_k` = 90 landed at
   **154.85** and beats the reference by **+15.43**. **There is a second basin.** §4.
4. **The canonical mode is now `from90`**, not `ref`, and `ref` was abandoned mid-run. §4, §6.
5. **Gate 4 and gate 12 move the right way at the posterior's OWN preferred free mode**, for the
   first time. §4.
6. `rep_dC` fell **5.566 → 3.378**; **P4 falsified** too. §4.
7. The ridge **reparametrization is a NULL** with power (n = 8, p = 0.81). §5.
8. **NEXT PHASE: assess the whole model post-fix.** 15 diagnostics + `ccx_load_mode()` still point
   at the quarantined path, and DESIGN §6's status blocks assert PRE-FIX verdicts as current. §7.

## 1. How the arc got here (one paragraph)

Handoff 08-25b inherited "should two CO₂ station-level streams outvote the pulse response?" on a
frozen-scan decomposition giving them 93 % of an 86.7-log-unit veto. Measured at the landed modes
they carried **−0.1 %**. The veto was `d13c_seasonal_SPO` + `d13c_seasonal_MLO` + `gcb_land_sink`,
and an effective-n audit of all 15 annual streams showed **all of it was BIAS on white residuals**,
immune to reweighting (15 % haircut, not two orders of magnitude). So the objection was physical —
and it was a bug. `notes/collect_2026-08-25c_the_veto_is_not_a_weighting.md`.

## 2. The bug and the guard

`R/model.R` emitted `add_flux(iatm, ilef, seas, alpha13 = aux$alpha_photo)`. **`seas` is zero-mean
by construction**, so it is negative half of every year, and `add_flux` swaps the SOURCE box for a
negative flux **while still applying `alpha13`** — autumn respiration was discriminated twice.

**Receipt, parameter-free:** a closed two-box system, one zero-mean sinusoid — carbon returns to
9e−13 GtC and δ¹³C drifts **−0.124 ‰ PER CYCLE**. Nothing caught it because ¹³C conservation is
antisymmetric (blind to a mis-partition), R↔C++ parity shares the rule, and
`test-conservation.R:82` + `test-parity.R:72/151` all set `seas_drivers <- 0`.

**The guard is the durable half.** `add_flux` now REFUSES a negative flux carrying `alpha13 != 1`;
reviewed sites declare `alpha13_signed = TRUE` **with a stated reason** — (a) one-way by
construction, or (b) **genuinely signed and OPEN**. There is exactly one (b): **the biological
pump**, whose `S[k]` is a flux DIVERGENCE, negative in 2 of 10 layers carrying 0.4 % of gross.
**Grandfathered bit-exactly, NOT fixed.** `notes/collect_2026-08-25d_...md`.

## 3. QUARANTINE

`calibration/output/quarantine/20260825_seas_isotope_rectification/` — every pre-fix fitted vector,
arm N included, with a README. **Nothing fitted before `6bda464` is comparable.**

## 4. The refit — `prereg_2026-08-25f`, `collect_2026-08-25g`

| arm | logpost | `fert_k` | `enh(420)` | `rep_dC` | AF trend | TH20/50/100 |
|---|---|---|---|---|---|---|
| pre-fix ref (old obj.) | −1859.32 | 554.5 | 0.207 | +5.566 | −0.0007 | ✗✗✗ |
| `ref` cycle 2, **ABANDONED** | −1559.6 | 483.1 | 0.212 | +3.834 | −0.0006 | ✗✗✗ |
| **`from90` FINAL = CANONICAL** | **−1544.61** | **154.85** | 0.245 | +3.378 | **+0.0080** | ✗✓✓ |
| `pin90` FINAL, pin off (+11.6698) | −1556.17 | 90 | 0.288 | +3.093 | +0.0137 | ✓✓✓ |

**P3 FALSIFIED** (predicted > 400, falsifier < 200). **P4 FALSIFIED** — `rep_dC` is the largest
mover at 1.73 prior sd, nothing else above 0.58; the d13C LEVEL streams had been propping it up.
**P2 not supported as stated** (it failed to name `rep_dC`). **P5 holds** — SPO partition
1.47–1.50×, improved from 2.45× but not closed. **P1 settled on the evidence**, `ref` not converged.

`from90`'s +15.43 = `co2_icecore` +7.82, `co2_seasonal_SPO` +5.13, `co2_level_MLO` +3.94 … against
**`gcb_land_sink` −7.94** — the exact inverse of the pre-fix decomposition. **The land sink is the
objection that survives, outvoted rather than decisive.**

## 5. The reparametrization is a NULL, and it corrects earlier advice

8 paired races over two campaigns: combined mean **+0.059 ± 0.673, t(7) = 0.25, p = 0.812**, sign
split 4:4, 95 % CI **[−0.50, +0.62]**. Campaign A was blind (all runs stopped 1.0–2.3 short of the
mode); campaign B ran in the crawl regime and **7 of 8 finished within 0.35**. Same null. The
step-scale confound was removed by an offset making both arms start at numerically identical
vectors. **⇒ the per-arm evaluation count is NOT reducible this way**, so Torch's arm-parallelism
and the MCMC are back to being the main throughput lever — with `cpu_short`'s 4 h wall meaning MCMC
needs `cs` or checkpointing.

## 6. NON-OBVIOUS STATE — read before touching anything

- **CANONICAL MODE = `calibration/output/refit_20260825f_from90/mode_fit_pumpN.rds`** (−1544.61,
  `fert_k` 154.85). Highest free arm wins regardless of name.
- **⚠ `refit_20260825f_ref/mode_fit_pumpN.rds` IS THE PRE-FIX SEED**, not a result (mtime 08-25
  20:41, logpost −1909 under the new objective). Cycle 1's real result is in
  `mode_fit_pumpN_progress.rds` (−1560.05). The driver warm-starts from the FORMER and has **no
  resume-from-progress path** — copy the progress file over it before ever relaunching, or lose
  16 h. `ref` was abandoned deliberately: a worse local optimum, gaining 0.01–0.20/restart.
- **`h_ml` is bounded to [85, 120] by the driver** and must be restored before recomputing any
  logpost, or every arm is off by ~1.1 and `u_mode` does not decode (max |u − u(par_mode)| = 1.7).
  `par_mode` is the authority. [[ccx_hml_band_provenance]]
- **Pin offset = +11.6698** at `fert_k` = 90, computed from the transform. Not the old 11.33–12.21.
- **A progress file carries no `param_names`** — assert on `names(par_mode)`.
- **Eval cost, measured three ways:** 0.162 s by the driver's counter (includes cheap −Inf
  rejections), **0.221 s for valid evaluations on a clean machine**, 0.422 s under 3-way load.
  ~332k evals per arm in cycle 1. `optim(maxit = N)` for Nelder-Mead is a FUNCTION-EVALUATION cap
  (verified: 8000 → 8002, 20000 → 20002).
- **`kz` still rails** at 6140–6431 against a bracket top of 6528. Untouched by any of this.
- **STILL NO POSTERIOR.** All of this is mode-finding; the sampler has never converged.

## 7. ⇒ THE NEXT PHASE: WHOLE-MODEL QUALITY, POST-FIX

The fix changed the objective and moved the mode a long way. **Nothing about overall model quality
has been re-established** — only gates 4/7/12/12b were re-measured, at three arms.

### 7a. FIRST, and it is blocking: repoint the mode resolution (mechanical)

**`ccx_load_mode()` (`R/calibrate.R:618`) hardcodes
`calibration/output/pump_arms/mode_fit_pump<arm>.rds`**, which is quarantined. It is the app's
resolution point (`app/global.R:76`). Separately, **15 diagnostics hardcode the same path
themselves** rather than going through it:

```
diag_af_trend_levers  diag_app_params  diag_design_gates_at_mode  diag_fert_ridge_{gates,repdc,
residual,streams}  diag_joos_irf  diag_luc_arm_ridge_confound  diag_rep_dC_gates
diag_seas_isotope_rectification  diag_seas_reanchor_arithmetic  diag_station_representation
diag_stream_neff  seed_fert_ridge_arms
```

**Recommended:** give `ccx_load_mode()` a single named constant for the canonical mode, point it at
`from90`, and convert the 15 to use it. That is one decision and one edit, not sixteen. The failures
are currently LOUD (file-not-found), which is the intended quarantine behavior — do not "fix" them
by pointing at the quarantine.

### 7b. THE CENTREPIECE: `diag_design_gates_at_mode.R` over DESIGN §6

DESIGN §6 is 13 numbered gates ("all must pass before headline claims"), and that script runs them.
**It is currently broken by 7a.** Run it at `from90` and at `pin90`.

**AND ITS STATUS BLOCKS IN `DESIGN.md` ARE NOW STALE AND ASSERT PRE-FIX VERDICTS AS CURRENT** —
e.g. gate 4 reads *"STATUS AT THE SHIPPED MODE (2026-08-22) … decadal spread sd 0.019 against the
observations' 0.051 — 2.7× too smooth"*, where `from90` gives **sd 0.0259 and trend +0.0080**. Every
§6 status block is owed a re-measurement and a re-write. **This is the single most misleading
artifact in the repo right now**: a reader takes those blocks as the model's current standing.

### 7c. Then the assessment proper

1. **`diag_fit_at_mode.R`** at `from90` — per-stream fit, and specifically whether
   [[ccx_fit_at_mode]]'s finding still holds ("d13C levels are pure BIAS, the misfit is rank-one,
   both isotope sigmas are FITTED"). The fix acted directly on d13C, so this is the most likely
   thing to have changed.
2. **Is `rep_dC` still anomalous?** 5.566 → 3.378 prior sd. It was a standing flag
   ([[ccx_rep_dc_co2_bias]], [[ccx_rep_dc_prior]]). At 3.4 it is smaller but not resolved — and
   §4 shows the d13C LEVEL streams were part of what set it.
3. **The seasonal partition, still open at ~1.5×** (was 2.45×). Marcus's named structural
   candidates — **latitude bands within each hemisphere**, stratosphere, high-latitude mixing —
   remain live on a much smaller target. Of these the SH residual is the larger, and a single SH
   land box at an effective latitude is the obvious suspect. **Untested.**
4. **The d13C Suess overshoot** ([[ccx_d13c_suess]]) was called STRUCTURAL pre-fix. Re-check.
5. **`gcb_land_sink`** is now the surviving objection (−7.94, and +2.46 σ at `from90`). It is also
   the stream carrying `LIK_LAND_SINK_INFLATE` = 3.0 and a known GCB closure error
   ([[ccx_gcb_land]], [[gcb_imbalance_not_a_drift]]). Worth asking whether it should be decisive.
6. **`kz` railing** — unchanged and untouched by the fix; still an open structural flag.

### 7d. Owed regardless

- **The pump's `alpha13_signed` (b) case** — 0.4 % of gross, and `PUMP_EPS13_ORG` is
  "provisional, recollected, NEEDS a cited source".
- **`alpha_as_up` / `alpha_as_down`** — hardcoded, provisional, uncited, and
  **temperature-independent under a seasonal SST cycle**. Exonerated as the seasonal culprit
  (zeroing the ocean seasonal driver moves SPO δ¹³C by 2 % while moving CO₂ by 29 %) but not
  verified.
- **The Hessian condition number in both parametrizations** — the measurement that would EXPLAIN
  §5's null. ~5 min, but [[ccx_hess_step_sd]] warns this plane needs per-direction step sizing.
- **The sampler.** Still the project's oldest open item, and the post-fix posterior may be
  differently conditioned.
