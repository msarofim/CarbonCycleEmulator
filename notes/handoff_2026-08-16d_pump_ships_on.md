# Handoff — CarbonCycleEmulator, 2026-08-16d: Marcus decided the pump SHIPS ON with `pump_grad` FITTED; the wiring is written but UNCOMMITTED because it takes the suite 4 → 19 failing expectations

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`, still
**not merged**. **HEAD = `c21dc7d`. The working tree is NOT clean, deliberately** — three modified
R files carry the pump-ON wiring and are held back (§4).

**Supersedes `handoff_2026-08-16c_pump_ported.md` for §7 items 1–2 (both now decided).** Its §1–§5
stand unchanged; its §8 cautions all still hold, and two more are added here (§7).

**Commits this session:** `9618282` (the `pump_grad` profile) → `c21dc7d` (the `kz` degeneracy
check + the test attribution).

---

## 0. START HERE

1. **MARCUS DECIDED (2026-08-16d): the pump SHIPS ON, and `pump_grad` is a FITTED parameter**
   with its prior anchored on the **observed 233.109**, not on the fitted optimum. §2.
2. **THE WIRING IS WRITTEN AND UNCOMMITTED.** `git status` shows `R/constants.R`, `R/model.R`,
   `R/calibrate.R` modified. That is not an unfinished edit — it is the change being held out of
   the commits until the tests below are re-derived. `git checkout -- R/` reverts it cleanly. §4.
3. **THE BLOCKER: pump-ON takes the suite from 4 failing expectations to 19** (11 tests). The 4 are
   pre-existing and unchanged; **7 tests are new**. **NO TEST WAS EDITED.** §5.
4. **I RETRACTED MY OWN PRIORITY CALL ON THOSE TESTS, ON MEASUREMENT.** I flagged the two
   `test-parity.R` failures as a possible real R↔C++ parity break. They are **not**: the relative
   difference is **8e-15** against a `1e-15` tolerance — machine precision, on a tolerance sized to
   a pump-OFF derivative. **The one that actually needs thought is `test-ocean-advection.R`.** §5.
5. **The four-row objective wants `pump_grad` ≈ 274.5 ± 13.1 (1.178× observed), and at that size
   ALL THREE ocean rows close simultaneously** with zero fitted parameters in the export field. §3.
6. **`pump_grad` and `kz` are NOT degenerate** — ρ = −0.167, marginal σ 1.01× conditional. That was
   the prerequisite for fitting it and it passed. §3.2.
7. **The refit (task 8) is still the only thing left in the round**, now behind §5.

---

## 1. What was asked and what was done

The 16c handoff left §7 item 1 — "what should `pump_grad` be, and is it fitted?" — as a decision
nobody had taken. Rather than ask cold, I measured the profile the decision needs (§3), put the
decision to Marcus with the numbers in hand, then ran the degeneracy check I had made a condition
of my own recommendation (§3.2), and wired the answer (§4). The wiring then hit the test suite (§5).

---

## 2. THE DECISION (Marcus, 2026-08-16d)

| question | decision |
|---|---|
| Does the pump ship ON? | **Yes, ON.** |
| Is `pump_grad` fixed or fitted? | **FITTED**, 20th parameter, **prior anchored on the observed 233.109**. |
| N vs D export law? | **Still deferred to the refit** (16c §7 item 3). Not re-opened, not scanned. |

**Why the OBSERVED 233.109 and not the fitted 274.5.** The export field is solved against the
model's *own* diffusion, so the optimum is conditional on `kz`, which the refit will move. Pinning
the default at 274.5 would freeze a fit at a stale `kz` and launder it as a structural constant.
233.109 is an observation and survives a refit; the fitted parameter is what moves.

---

## 3. §5.2g — THE PROFILE (`calibration/diag_pump_grad_profile.R`, ~9 min)

At the quarantined pre-gradient mode, `h_ml` forced to 100, mode `"N"`, carbonate share at the
pinned 0.23 — **the same operating point as `diag_pump_vs_gradient_terms.R`**, which is what makes
the two comparable.

| `pump_grad` | scale | z_DIC | z_δ¹³C | z_ALK | Δ logL from OFF |
|---|---|---|---|---|---|
| 0 | — | −11.10 | +16.84 | −4.09 | 0 |
| 233.109 (observed) | 1.000 | −1.87 | +2.16 | +0.21 | +254.3 |
| **280** | **1.201** | **−0.01** | **−0.42** | **+1.08** | **+259.4** |
| 400 | 1.716 | +4.74 | −6.57 | +3.30 | +215.6 |

- **Full objective: 274.5 ± 13.1 µmol/kg (1.178 ± 0.056×).** Three ocean rows alone: 271.3 ± 14.3.
  Identifiable to ~4.8 %. **This σ is a MODE-SLICE σ, not a posterior.**
- **All three rows close at once** at the best arm; deep Δ¹⁴C sits at +1.04.
- **The carbonate limb closed 16b §2's fractionation gap.** The shim's DIC and δ¹³C rows wanted
  export scales **1.37× apart** (= 20/14.55). With two limbs at 23 % the effective ε is −15.2 ‰ and
  the gap is **1.03×** — DIC demands 1.202×, δ¹³C 1.168×. **ALK is now the dissenting row at
  0.951×**, and it dissents inside its own σ (54.1 in `pump_grad`, the loosest of the three;
  δ¹³C's 18.4 is the sharpest).
- **+48.2 of the +259.4 is rows the pump was never built against**: `d14c_NH` +25.0, `d14c_SH`
  +13.9, `d13c_level_MLO` +4.4, `d13c_level_SPO` +3.5. Gradient rows are +211.2.
- **The pinned carbonate share survives an independent check**: scanning `pump_carb_frac` at fixed
  `pump_grad` = 280 gives a quadratic vertex **0.214 ± 0.026** against the **0.23** GLODAP's
  alkalinity gradient pinned — **0.61 σ**. Not a licence to fit the share.

**READ THE OFF-TO-OPTIMUM MARGIN AS AN UPPER BOUND.** Every arm including OFF sits at the same
unrefitted mode; the no-pump incumbent never gets the refit `beta_max`/`kz`/`h_ml` would give it.

### 3.1 Two gates of mine were wrong, and both are fixed in the file rather than around it

- **The zero-uptake gate was on logL at 1e-6 log-units — TIGHTER THAN THE SPINUP'S OWN
  CONVERGENCE** — and duly reported FAIL at 2.16e-6. Loosening the threshold until it passed would
  have been the explaining-away move. It now gates the **physical** quantity: max |ΔCO₂(2024)|
  across the whole scan = **2.24e-08 ppm**, PASS, with the logL footprint printed as context.
- **The δ¹³C row's demand was read off a line through the endpoint arms.** It is a *ratio* and
  departs 4.6 % from linear, so that put its demand at 287.8 against the bracketing pair's
  **272.3** — a 6 % error, larger than the row-to-row disagreement the part exists to measure. Now
  a local secant. DIC and ALK are exactly linear (3.2e-11, 2.0e-16) and unaffected.

### 3.2 §5.2h — THE DEGENERACY CHECK (`calibration/diag_pump_kz_degeneracy.R`, ~15 min)

The prerequisite I attached to my own recommendation: §5.2g held all 19 parameters, which is the
condition under which a new parameter always looks best.

- **ρ(`pump_grad`, `kz`) = −0.167**; marginal σ of `pump_grad` is **1.01×** its conditional
  (13.0 vs 12.8). **NOT near-degenerate.** Consistent with the structural result that transport
  cannot move the DIC/δ¹³C gradients.
- **At `kz` = 6200 — where the posterior sits — the optimum is 270.7**, 1.4 % from §5.2g's 274.5.
- **Two internal checks fell out free.** `ocean_grad_alk` is *exactly* `kz`-independent across every
  column (it reads the export field alone); the ocean sink is identical down every pump column at
  fixed `kz`. Verified separately at DEFAULT parameters: pump ON vs OFF gives CO₂(2024) identical to
  **2.0e-08 ppm** and 1750–2024 uptake identical to **1.2e-07 GtC**, while adding **+3,457 GtC** of
  preindustrial interior inventory.
- **P3 came back UNRESOLVED, not false, and the file says so.** Three of four `kz` columns peaked at
  the **top of my pump grid**, so the first run's "20.2 % — FAIL" was a property of the grid. Part 5
  measures the mechanism instead: at `kz` = 3830, `pump_grad` 290 → 335 gains **+34.1 on atmospheric
  radiocarbon** while the three gradient rows **lose** 5.2 — an under-ventilated column uses the
  constant-mass pump as a **bomb-¹⁴C sink**. Real, and **off the posterior's support**: at
  `kz` = 6200 the same channel changes sign.
- **`kz` pins to the bracket's TOP with the pump both OFF and ON**, and the pump makes deep water
  **older** at every `kz` (at 6200 it moves that row +1.60 → +1.15, *toward* target). **The bracket
  [3830, 6200] was bisected at default parameters on a NO-PUMP model, on the very row the pump
  moves — re-derive it at the refit rather than inherit it.** `calibrate.R`'s own comment asks for
  exactly that.

---

## 4. THE WIRING — written, UNCOMMITTED, three files

```
 M R/calibrate.R      the 20th CCX_PARAM_TABLE entry
 M R/constants.R      PUMP_GRAD_OBS
 M R/model.R          the default
```

66 insertions, of which ~56 are comment. The functional change is three edits:

| file | change |
|---|---|
| `R/constants.R` | `PUMP_GRAD_OBS` = **233.109** µmol/kg, `status = "data"` — GLODAPv2's gradient, **= the `ocean_grad_dic` target**. It is the *prior centre*, not the pump's magnitude. |
| `R/model.R` | `pump_grad = ccx_const("PUMP_GRAD_OBS")` (was `0`). **`pump_grad = 0` still turns the pump fully off and bit-reproduces every pre-2026-08-16 result** — the `is.null(aux$pump)` guard is untouched. |
| `R/calibrate.R` | `pump_grad = list(tr = "log", init = 233.109, prior = dlnorm(log(PUMP_GRAD_OBS), 0.25))` |

**THE PRIOR MILDLY DOUBLE-COUNTS GLODAP, DELIBERATELY AND IN WRITING.** Its centre is the same
observation `ocean_grad_dic` scores. The ±25 % width is ~4.5× the likelihood's own 13.1 µmol/kg, so
the data dominate and the prior only excludes absurd magnitudes. **Check the posterior against the
prior before quoting a pump magnitude as "constrained."** A `dunif` on a generous bracket is the
alternative if it ever looks like it is doing work.

**NOT DONE:** `PUMP_GRAD_OBS` should be asserted equal to `obs_glodap_deep.rds`'s `ocean_grad_dic`
target by a test in `test-constants.R`, so the two cannot drift if the target is re-derived. The
constant's comment promises that test; **the test is not written**.

---

## 5. THE BLOCKER — 4 → 19 failing expectations, attributed by running the suite BOTH WAYS

| | tests failing | expectations |
|---|---|---|
| `HEAD` (`c21dc7d`), pump OFF | 4 | **4** / 802 pass |
| with the wiring applied, pump ON | 11 | **19** / 793 pass |

**The 4 at HEAD are the pre-existing ones the 16c handoff records**, all still failing identically
with the pump on — `test-luc-permanence.R` ×2, `test-mechanisms.R` "every switch is wired up",
`test-pulse.R` "the airborne fraction is in the right ballpark" (`at(100)` = 0.213 vs > 0.3).

**The 7 new ones, with the assertion values measured** (the summary reporter truncates its detail at
10 failures, so the last three files were re-run individually to get these):

| file | test | × | measured | reading |
|---|---|---|---|---|
| `test-likelihood.R:617,620` | "the PREINDUSTRIAL gradient is zero for every parameter — **the property the pump breaks**" | 6 | `pi_grad` = **233.109** vs < 1e-9 | **A PRE-DECLARED TRIPWIRE.** Its own comment: *"if this test ever fails, either a pump has landed (expected) or something is leaking carbon into the interior (not)."* It fails at exactly the gradient the pump names — i.e. it is **confirming** the pump, not catching a bug. |
| `test-ocean-advection.R:165,170` | "reversing the circulation leaves the ATMOSPHERE invariant, not the deep ocean" | 3 | **9.2e-06 / 1.1e-05** vs < 1e-8 | **THE ONE THAT NEEDS THOUGHT.** ~1000× the tolerance. Plausible reading: the export field is solved **per hemisphere** (different areas and SSTs), so reversing which hemisphere sinks is no longer a symmetry. **That is a hypothesis, NOT measured** — test it before believing it. |
| `test-parity.R:35,53` | "single derivative agrees to roundoff" / "the pro-rata land-use debit agrees to roundoff" | 2 | rel. diff **8e-15** vs < 1e-15 | **NOT A PARITY BREAK** — 8e-15 relative is ~36 ulps, still machine precision, on a tolerance sized to a pump-OFF derivative. I flagged these as the top priority and that was **wrong**; measured, they are the least interesting of the seven. |
| `test-pump.R:16,18` | "`pump_grad` = 0 emits NOTHING — the no-pump model is bit-reproduced" | 2 | `p$pump_grad` ≠ 0; `aux$pump` not NULL | The test builds `p <- ccx_default_params()` and asserts the **default** is pump-off. The **property** it names is still true — it just needs `p$pump_grad <- 0` set explicitly to test it. |
| `test-likelihood.R:644` | "the TRANSIENT gradient's parameter leverage stays far below its miss" | 1 | miss **1.8 σ** vs > 5 | The `expect_gt(miss, 5)` guard exists so the leverage bound cannot pass "for the wrong reason". The pump closes the miss, so the guard fires. The **bound itself** is not what failed. |
| `test-likelihood.R:356` | "rho is gone and the parameter vector is self-consistent" | 1 | `CCX_PARAM_NAMES` length **20**, expected 19 | The 20th parameter. A one-line count. |

**NO TEST WAS EDITED, AND THAT IS THE POINT.** Re-expressing a test so a model change passes is the
move that hides regressions. Every one of the seven needs a deliberate re-derivation, and three of
them (the tripwire, the parity tolerance, the ocean-advection invariance) are **claims about the
model** that a re-write would quietly discard.

---

## 6. Files

| file | what |
|---|---|
| `calibration/diag_pump_grad_profile.R` | **NEW**, ~9 min. §3 |
| `calibration/diag_pump_kz_degeneracy.R` | **NEW**, ~15 min. §3.2 |
| `calibration/output/pump_grad_profile/`, `pump_kz_degeneracy/` + their `_run.log`s | committed |
| `DESIGN.md` | **§5.2g** (the profile), **§5.2h** (the degeneracy check + the decision + the blocker) |
| `CHANGELOG.md` | two entries, 2026-08-16d and 2026-08-16e |
| `R/constants.R`, `R/model.R`, `R/calibrate.R` | **the wiring — MODIFIED, UNCOMMITTED.** §4 |

Memory: `project_ccx_pump_ships_on_decision` (new), and the pump entries were **consolidated** into
`project_ccx_pump_ported.md` by the memory-consolidation pass that ran this session — the separate
`project_ccx_pump_grad_profile` file no longer exists; its numbers are inside the consolidated one.

---

## 7. Open decisions, in dependency order

1. **THE SEVEN TESTS.** Re-derive each deliberately. Suggested order, revised on the measurements:
   **(a)** `test-ocean-advection.R` — is the hemispheric asymmetry real, and is ~1e-5 ppm the right
   size for it? **(b)** the two `test-likelihood.R` gradient tests and `test-pump.R`, which need
   re-expressing for a pump-ON default without losing what they assert — the tripwire in particular
   should probably become "the interior gradient equals `pump_grad` exactly" plus a pump-OFF
   uniformity arm, which is *stronger* than what it asserts today. **(c)** the `test-parity.R`
   tolerance and the `CCX_PARAM_NAMES` count, both mechanical.
2. **COMMIT THE WIRING** once (1) is resolved. Not before — a red suite on the trunk of this branch
   would make every later failure unattributable.
3. **Write the `PUMP_GRAD_OBS` ↔ `ocean_grad_dic` consistency test** promised in §4.
4. **N or D?** Still deferred to the refit. The gradient rows cannot tell them apart; D's +195 is
   entirely the CO₂ record and a refit can reallocate it.
5. **THE REFIT (task 8)** — 20 parameters now.
6. **Re-derive the `kz` bracket at the refit** rather than inherit it (§3.2).
7. **Where does the refit's `h_ml` land?** If it leaves [85, 120] all three gradient rows go absent.
   (carried)
8. **σ_Δ has NOT plateaued in block size**; **representation error still ZERO**; **point σ vs
   Student-t**; **is A's `kz` = 6404 a blocker or a re-derivation**; **does candidate A ship**.
   (all carried unchanged from 16c)

---

## 8. Non-obvious state, and cautions

- **THE WORKING TREE IS DIRTY ON PURPOSE.** Three modified R files = the pump-ON wiring. Do not
  "clean up" by committing them, and do not assume an interrupted edit. `git checkout -- R/` reverts.
- **`calibration/output/mode_fit.rds` is still EMPTY.** Every "at the mode" number in this note comes
  from `calibration/output/quarantine/20260815_pre_gradient_terms/mode_fit.rds`. (carried)
- **The mode's own `h_ml` is 183.95 and is FORCED to 100** in both new diagnostics, because all
  three gradient rows SKIP outside `LIK_OCEAN_GRAD_HML_OK` = [85, 120]. Any arm run outside the band
  scores a *different objective*, silently.
- **The full suite takes ~10–12 min** and its summary reporter **prints only the first 10 failures**
  even under `set_max_fails(Inf)` — the totals are complete but the detail is truncated. Re-run
  individual files for assertion values.
- **Three claims of mine were measured FALSE or UNRESOLVED this session and all three are kept
  visible in the files rather than edited away**: the logL-based zero-uptake gate (§3.1), the
  endpoint-line δ¹³C demand (§3.1), and P3's "< 15 %" (§3.2). **Weight the tables over the prose,
  including the prose here.**
- **A MIS-ATTRIBUTION OF MINE, worth knowing because it nearly sent a session chasing a ghost.** I
  first read the `test-luc-permanence.R` failures as caused by the pump, reasoning that a
  constant-mass pump should not move a fossil pulse's airborne fraction. Measured at
  `pump_grad = 0`: af = **0.1513** at lag 100, **identical to the pump-ON arm at every lag** (1, 10,
  50, 100, 150, 250 yr). They were already red at HEAD. The property was never in question; my
  attribution was. **Run the baseline before attributing a failure to your own change.**
- **Name collision, unchanged:** `grad_off_co2` / `grad_off_d13c` in `err` are the **MLO−SPO
  ATMOSPHERIC** offsets. The ocean rows are `LIK_OCEAN_GRAD_*` / `ocean_grad_*`.
- **`luc-veg-debit` has never been merged** and is a long way from `main`.

**Still do NOT:** hand-tune stream weights; delete `excess_c14_ocean` or `d14c_intcal`; free any
land turnover parameter; delete the `kz` bracket bare; build the conveyor; splice any pre-2026-08-15
posterior; **compare any logL across the 2026-08-16 boundary**; quote §4.2's ~384 log-units or its
1996.2555 baseline; **quote the SHIM's export figures or the "3.6×" POC ratio** (16c §5); quote the
alkalinity row as evidence about anything from before the port; **quote §5.2g's +259.4 as the pump's
value without the upper-bound caveat**; or **quote 274.5 as `pump_grad`'s value** — it is a fit at a
`kz` the refit will move, which is exactly why the default is the observed 233.109.

---

## 9. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-16d_pump_ships_on.md`. **Marcus decided the pump SHIPS ON with
> `pump_grad` FITTED on the observed 233.109; the wiring is written but UNCOMMITTED (three modified
> R files) because pump-ON takes the suite from 4 to 19 failing expectations across 11 tests — 4
> pre-existing, 7 new, none edited.** The next task is §7 item 1: re-derive those seven
> deliberately, starting with `test-ocean-advection.R` (reversing the conveyor now moves the
> atmosphere ~1e-5 vs a 1e-8 tolerance — the hemispheric-asymmetry explanation is a HYPOTHESIS, not
> a measurement). The two `test-parity.R` failures are **not** a parity break — 8e-15 relative on a
> 1e-15 tolerance sized to a pump-OFF derivative. Do not commit the wiring until the suite is green.
