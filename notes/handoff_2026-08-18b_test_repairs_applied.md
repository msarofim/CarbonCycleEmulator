# Handoff — CarbonCycleEmulator, 2026-08-18b: THE 5 TEST REPAIRS ARE APPLIED, the suite is GREEN, and a mutation test moved one of the new bars before it shipped

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`. **Trunk `main`**, working tree clean.
**Commits this session:** `a12ecee` → `8ea8853` (+ a follow-up comment fix).

**Supersedes `handoff_2026-08-18_refit_landed_n_adopted_merged.md`** for its §6 and open item 1 —
both discharged. Everything else in it **stands**, including §2's refit results, §3's provisional
adoption of arm N, and every entry in its §8 "Still do NOT" list.

---

## 0. START HERE

1. **JOB B IS CLOSED.** All 5 repairs applied. **Suite `FAIL 4 | WARN 53 | SKIP 2 | PASS 857` →
   `FAIL 0 | WARN 53 | SKIP 2 | PASS 870`.** Baseline was MEASURED first and reproduced the diag exactly.
2. **THE GATES WERE MUTATION-TESTED, AND THAT IS THE PART THAT MATTERS.** A green suite is also what
   a gate that can never fire produces. **Two of three rewritten bars were weaker than their comments
   claimed**, and one shipped constant moved because of it. §2, `notes/diag_2026-08-18_gate_mutation_tests.md`.
3. **`JOOS_POINT_TOL` WAS DERIVED AT THE WRONG CONFIGURATION** — defaults (gap 0.287) rather than the
   **adopted arm-N mode** (0.325), leaving the shipping model 0.025 from a flaky failure. **0.35 → 0.40.** §2.3.
4. **A STANDING GAP IS NOW MEASURED, NOT FIXED:** the suite derives bars from `ccx_default_params()`
   while the project's adopted parameters live in `mode_fit_pumpN.rds`. **Every default-derived bar
   inherits it.** §4 item 1.
5. **AND A RESULT THAT IS NOT ABOUT TESTS:** the Joos point IRF is monotone in `kz`, and **the
   calibration pins `kz` in the direction that WORSENS the agreement** — −25 % at the bracket floor,
   **−33 % at the adopted mode**. This gives 18a's open item 5 a concrete cost. §3. **It is NOT an
   argument for lowering `kz`.**
6. **DESIGN GATE 12 STILL HAS NO TEST** — discovered while fixing a reference I had written to a
   `test-joos-gates.R` that does not exist. §4 item 2.

---

## 1. The five repairs, as applied

`a12ecee` (3, 4, 5) then `8ea8853` (1, 2). None was a code bug, exactly as diagnosed.

| # | file | what changed |
|---|---|---|
| 1 | `test-pulse.R` | **Re-protocoled onto PD100** (Marcus's choice): 100 GtC onto a background HELD at ~389 ppm, scored against the Joos Table 5 fit at 20/50/100 yr. The old bar quoted PD100 numbers but measured on ssp119. |
| 2 | `test-luc-permanence.R:88` | **Preindustrial band** (Marcus's choice) on the model's own PI-held IRF@100. `diag_joos_irf.R` part 4 says 0.152 by a separate code path; the test measures 0.151. |
| 3 | `test-mechanisms.R` | `max\|ΔCO₂\|` over the series vs a new derived `MECH_WIRED_MIN` = 1e-3 ppm. ENSO is the only **oscillatory** switch, so the 2100 endpoint read its *phase*. Also pins the time grid. |
| 4 | `test-luc-permanence.R:104` | `f_luc_wood = 1` alongside `f_luc_perm = 0`. Reproduces the recorded signature (−0.0032 @100). |
| 5 | `R/cpp.R` **and `R/model.R`** | The stale `f_luc_wood` comments. |

**REPAIR 5 WAS BIGGER THAN DIAGNOSED.** The diag caught `R/cpp.R:104-105`. **`R/model.R:442-443`
carried the identical defect**, tagging `1 = wood alone (shipped)` when `0` ships. Traced with
`git log -S`: `b3108d7` added the switch defaulting to 1, **`ea7c70b` adopted pro rata and flipped
the constant without updating either prose site.** Both corrected.

**REPAIR 1 FORCED A DEDUP WORTH HAVING ON ITS OWN.** Running Joos's protocol in a test needed
`ccx_hold_forcing`, `ccx_irf`, `ccx_pulse_state`, `ccx_set_emissions` — which existed as
**byte-identical copies in BOTH `diag_joos_irf.R` and `diag_joos_beta_scan.R`**. Verified identical
function-by-function *before* moving, then promoted to a new **`R/joos_irf.R`** with the protocol
years and Joos's Table 4/5 reference data (**−244 lines, +124**). **Both diagnostics re-run clean and
reproduce their recorded numbers exactly** (0.520/0.378/0.292 and 12.4/25.6/41.9), so the move
changed nothing. A third copy under `tests/` was the alternative and would have made drift worse.

---

## 2. THE MUTATION TEST — the real work of this session

`notes/diag_2026-08-18_gate_mutation_tests.md`. Script was throwaway; every number is transcribed there.

### 2.1 `MECH_WIRED_MIN` — SOUND
A switch wired to nothing trips it; the live ENSO switch clears it **537×** (max 0.5366 ppm). No change.

### 2.2 `LP_FOSS_PI_REF` 0.152 ± 30 % — constant KEPT, comment rewritten
Holds at **both modes** (N 0.1622, D 0.1646) and across a **13× `kz` range** (0.1852 → 0.1458), and
under `k_w` ×4 / ÷4 and `h_ml` ÷4 (0.1502–0.1560). **That is also its limit:** it is a sanity and
cross-check gate on the reference arm, **not** a sensitivity gate. The constant was not touched; the
comment now states the measured sensitivity so the gate cannot be cited for more than it does.

### 2.3 `JOOS_POINT_TOL` — THE BAR WAS DERIVED AT THE WRONG CONFIGURATION

| configuration | IRF 20/50/100 | worst \|rel\| gap |
|---|---|---|
| package defaults — **what the test runs** | 0.520 / 0.378 / 0.292 | 0.287 |
| ARM D mode | 0.507 / 0.370 / 0.288 | 0.297 |
| **ARM N mode — ADOPTED** | 0.494 / 0.357 / 0.277 | **0.325** |

0.35 (derived from defaults) leaves the **adopted** model **0.025 from firing** — flaky, not strict.
**Re-derived at the shipping configuration: 0.35 → 0.40.** This is still a *derivation*; what changed
is **which configuration the bar is derived at**, which does not violate the "never re-baseline" rule.

---

## 3. THE `kz` RESULT — a concrete cost for 18a's open item 5

Joos PD100 point IRF is **monotone decreasing in `kz`** (more diffusivity ⇒ faster uptake ⇒ lower
airborne fraction), and **the calibration pins `kz` in the direction that worsens the agreement**:

| `kz` | gap vs Joos T5 at 20/50/100 |
|---|---|
| 500 | +9 % / +5 % / **+0 %** |
| 1500 | +1 % / −6 % / −12 % |
| 3942.5 (bracket LOW) | −10 % / −19 % / **−25 %** |
| 5000 (package default) | −13 % / −22 % / −29 % |
| **6439.2 (ARM N, 96.6 % up bracket)** | −16 % / −26 % / **−33 %** |

**The pin costs ~8 percentage points of Joos agreement at 100 yr, bracket floor to adopted mode**, and
`kz` ≈ 500–800 would put the model essentially **on** Joos's multi-model mean — an **order of magnitude
below** the bracket. Memory: `ccx_kz_joos_cost`.

**⚠ READ THE CAVEAT BEFORE QUOTING ANY OF THIS.** One-at-a-time scan, other 19 parameters at package
defaults; the two mode rows are a **14-of-20 overlay** (`bomb_total`, `luc_scale`, both sigmas and both
gradient offsets have no field in `ccx_default_params()` — the 16g trap). **NOT a re-fit, and NOT an
argument for lowering `kz`.** The likelihood pins it high for reasons this scan does not evaluate, and
the isotope and sink streams are exactly what would pay for moving it.

---

## 4. Open decisions, in dependency order

**Renumbered from 18a §7. Its item 1 is discharged; everything below carries.**

1. **THE DEFAULTS-vs-MODE GAP IN THE TEST SUITE. NEW, and it is the direct successor to this
   session.** Bars are derived from `ccx_default_params()`; the project's adopted parameters are a
   calibration output. Measured for one gate (0.287 vs 0.325) and **unmeasured for every other**.
   Coupling tests to `mode_fit_pumpN.rds` is its own problem — **that is a decision, not a chore.**
2. **DESIGN GATE 12 HAS NO TEST.** Its only implementation is `calibration/diag_joos_irf.R` part 3,
   a diagnostic nobody runs — which is how its recorded status went stale across two β moves once
   already (memory `ccx_joos_gate` flagged this on 08-14 and it is still true). The new PD100 test
   scores the **point** IRF and does **not** cover the **integrated** one. Deliberately not bundled in.
3. **Re-derive `ARM_HESS_EPS` at 20 parameters** (was 18a item 2). Both Hessians PD, so not urgent.
4. **σ-INFLATION: implement or not** (18a item 3). `notes/spec_2026-08-17_sigma_inflation.md`. **Marcus's
   call.** Its missing input — the cost re-derived over all three rows, ALK's `σ_rep` now being
   available — still needs computing. **The machine is free.**
5. **THE PILOT MCMC**, and whether 16f §5.4's barrier is what breaks it. **The `h_ml` bound question
   RE-OPENS here.** Still **the single most consequential open question in the project.** (18a item 4)
6. **`kz` pinned near its bracket top** — blocker, or does the bracket need re-deriving? **§3 now gives
   this a measured cost for the first time.** (18a item 5)
7. **DESIGN §5.4's products still do not exist** — no ~100-draw ensemble, no central parameter set. (18a item 6)
8. Carried: **σ_Δ has NOT plateaued in block size**; **representation error still ZERO in the
   objective**; **point σ vs Student-t**; **does candidate A ship**. (18a item 7)

**The critical path is unchanged:** ~~`h_ml`~~ → ~~refit~~ → ~~N-vs-D~~ → **a pilot MCMC that actually
converges** → ensemble → app. Step 4 still has no precedent on this model.

---

## 5. Non-obvious state, and cautions

**Everything in 18a §8 still holds.** Additions:

- **`R/joos_irf.R` IS NEW AND IS SOURCED BY BOTH THE TESTS AND THE DIAGNOSTICS.** `tests/testthat/setup.R`
  sources all of `R/`, so a change there reaches the suite. **Do NOT re-inline these helpers into a
  diagnostic** — a local copy that drifts makes the two diag scripts disagree about the same protocol.
- **The PD100 test adds a real runtime cost** to `test-pulse.R` (the held background is ~13 `ccx_run_fast`
  calls on the C++ path). It is seconds, not minutes, but it is not free.
- **`JOOS_HORIZON` and `JOOS_MARKS` deliberately stayed in the diagnostics** — they are per-script
  presentation choices, not protocol. Only protocol and Joos's published values were promoted.
- **A METHOD TRAP WORTH KEEPING.** The first `kz` scan returned **bit-identical IRFs at all eight values
  over a 13× range** — the "suspicious uniformity ≈ bug signal" pattern, and it was a bug in the scan:
  **`within(p0, kz <- kz)` self-assigns**, the list's own `kz` shadowing the loop variable, so every row
  ran the default. `within()` is an attractive idiom for one-at-a-time scans and **fails silently into a
  flat, plausible-looking table.**
- **I wrote a reference to a `test-joos-gates.R` that does not exist** and caught it before it shipped;
  that is how §4 item 2 was found. Corrected to point at `diag_joos_irf.R` part 3.

**Still do NOT:** anything in 18a §8's list, unchanged — and additionally **do not quote the `kz` scan as
an argument for lowering `kz`** (§3), and **do not cite the `LP_FOSS_PI_REF` band as evidence about
parameter sensitivity** (§2.2).

---

## 6. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-18b_test_repairs_applied.md`. **Job B is CLOSED** — all 5 repairs applied,
> suite **`FAIL 0 | PASS 870`**. The mutation test is the part to read: **two of three rewritten bars were
> weaker than their comments claimed**, and **`JOOS_POINT_TOL` had been derived at package defaults rather
> than the adopted mode** (0.287 vs 0.325), so it moved 0.35 → 0.40. That exposed a standing gap — **the
> suite derives bars from `ccx_default_params()` while the project runs `mode_fit_pumpN.rds`** — which is
> §4 item 1 and is a *decision*, not a chore. Separately, **the `kz` pin has a measured cost in the Joos
> benchmark for the first time** (−25 % at the bracket floor vs −33 % at the adopted mode), which is §3 and
> is **NOT** an argument for lowering `kz`. **DESIGN gate 12 still has no test** (§4 item 2).
