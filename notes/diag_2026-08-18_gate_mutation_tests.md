# MUTATION TEST of the three gates rewritten by the test repairs, 2026-08-18

**Why this exists.** `notes/diag_2026-08-18_test_failures.md` diagnosed four failures and
specified five repairs. Applying them took the suite to `FAIL 0 | WARN 53 | SKIP 2 | PASS 870`.
**A green suite is not evidence that a rewritten gate works** — it is evidence that the model
passes it, which is also what a gate that can never fire would produce. So each rewritten
numeric gate was mutation-tested: break the thing the gate claims to watch, and check it notices.

Script: `scratchpad/mutate_gates.R` (throwaway; the numbers are transcribed below).
**Two of the three gates came back weaker than their comments claimed, and fixing that changed
one shipped constant.**

---

## 1. `MECH_WIRED_MIN` = 1e-3 ppm (test-mechanisms.R) — SOUND

| mutation | result |
|---|---|
| a switch wired to nothing (base vs base, max\|Δ\| = 0) | **trips** — correct |
| the live ENSO switch | max\|ΔCO₂\| = 0.5366 ppm, **537× the floor** — passes |

The gate does what it says: it separates connected from disconnected, with three orders of
margin on the weakest real mechanism. No change.

---

## 2. `LP_FOSS_PI_REF` 0.152 ± 30 % (test-luc-permanence.R) — SOUND BUT NARROWER IN SCOPE THAN CLAIMED

Band = 0.1064 – 0.1976. Measured `af_foss`:

| configuration | af_foss | in band |
|---|---|---|
| package defaults | 0.1513 | yes |
| **ARM N mode (ADOPTED)** | **0.1622** | yes |
| ARM D mode | 0.1646 | yes |
| `kz` = 500 → 6528 (13×, spanning and far below the bracket) | 0.1852 → 0.1458 | yes throughout |
| `k_w` ×4, `k_w` /4, `h_ml` /4 | 0.1502 – 0.1560 | yes throughout |

**It holds at both modes with room to spare — but it is insensitive to ocean-parameter drift.**
A 13× change in `kz` moves it ~12 %, well inside a ±30 % band. That is acceptable for what this
gate is *for* (a denominator guard on the reference arm, plus a cross-check against an
independent code path) and unacceptable as a claim about parameter sensitivity. **The constant
was not changed; the comment was rewritten to state the measured sensitivity** so the gate cannot
be cited for more than it does.

---

## 3. `JOOS_POINT_TOL` (test-pulse.R) — **THE BAR WAS DERIVED AT THE WRONG CONFIGURATION**

Originally set to **0.35**, from the largest of the three gaps at **package defaults** (0.287).
Then measured at the configuration the project actually adopted:

| configuration | IRF 20/50/100 | worst \|rel\| gap vs Joos T5 |
|---|---|---|
| package defaults — **what the test runs** | 0.520 / 0.378 / 0.292 | 0.287 |
| ARM D mode | 0.507 / 0.370 / 0.288 | 0.297 |
| **ARM N mode — ADOPTED, the shipping configuration** | **0.494 / 0.357 / 0.277** | **0.325** |

**A tolerance of 0.35 leaves the adopted model 0.025 from firing.** That is a flaky gate, not a
strict one: it would go red on ordinary re-fitting rather than on a regression. **`JOOS_POINT_TOL`
re-derived at the adopted mode: 0.35 → 0.40**, with the derivation basis recorded in the test.

This is still a derivation, not a re-baseline — the change is *which configuration the bar is
derived at*, and the answer is "the one that ships", not "the one the test happens to run".

**NOTE THE STANDING GAP THIS EXPOSES:** the test runs on `ccx_default_params()`, but the project's
adopted parameters are in `calibration/output/pump_arms/mode_fit_pumpN.rds`. Every bar in the suite
derived from defaults inherits this. Making tests depend on a calibration output is its own
coupling problem and was NOT done here — but the discrepancy is now measured for this gate, and
is worth checking before trusting any other default-derived bar.

---

## 4. WHAT THE MUTATION TEST TURNED UP THAT IS NOT ABOUT TESTS AT ALL

`kz` is the one parameter the Joos point IRF is strongly sensitive to, and **the direction the
calibration pins it is the direction that makes the Joos agreement worse.**

| `kz` | IRF 20/50/100 | gap vs Joos T5 |
|---|---|---|
| 500 | 0.652 / 0.511 / 0.410 | +9 % / +5 % / **+0 %** |
| 805 | 0.633 / 0.490 / 0.391 | +6 % / +1 % / −4 % |
| 1500 | 0.602 / 0.458 / 0.362 | +1 % / −6 % / −12 % |
| 3000 | 0.558 / 0.414 / 0.323 | −6 % / −15 % / −21 % |
| 5000 (package default) | 0.520 / 0.378 / 0.292 | −13 % / −22 % / −29 % |
| 3942.5 (bracket LOW) | 0.538 / 0.395 / 0.307 | −10 % / −19 % / −25 % |
| **6439.2 (ARM N, 96.6 % up bracket)** | 0.499 / 0.358 / 0.276 | −16 % / −26 % / **−33 %** |
| 6528 (bracket HIGH) | 0.497 / 0.357 / 0.275 | −17 % / −27 % / −33 % |

Monotone decreasing in `kz`, as the physics says it must (more interior diffusivity ⇒ faster
uptake ⇒ lower airborne fraction). **`kz` ≈ 500–800 would put the model essentially on Joos's
multi-model mean — an order of magnitude below the calibrated bracket.**

**This gives the standing "`kz` is pinned near its bracket top" question (handoff §7 item 5) a
concrete cost for the first time:** the historical-record likelihood pulls `kz` up, the Joos pulse
benchmark pulls it down, and the pin currently costs ~8 percentage points of Joos agreement at
100 yr relative to the bracket floor (−25 % → −33 %).

**⚠ WHAT THIS IS NOT.** It is a one-at-a-time scan with the other 19 parameters at package
defaults, plus a 14-of-20 overlay for the two mode rows (`bomb_total`, `luc_scale`, both sigmas
and both gradient offsets have no field in `ccx_default_params()` and were not overlaid — the
same trap the 08-16g handoff records). It is **not** a re-fit, and it does **not** show that a
low-`kz` model would score better overall: the likelihood pins `kz` high for reasons this scan
does not evaluate, and the isotope and sink streams are exactly what would pay for moving it.
**Do not read this as "lower `kz`".** Read it as: the pin has a measurable cost in a benchmark
the project cares about, and that cost is now quantified rather than suspected.

---

## 5. METHOD NOTE — a bug this scan caught in itself

The first `kz` scan returned **bit-identical IRFs at all eight values across a 13× range**. That
is the `~/.claude/CLAUDE.md` "suspicious uniformity ≈ bug signal" pattern, and it was a bug in the
scan, not a finding: `within(p0, kz <- kz)` **self-assigns** — the list's own `kz` shadows the loop
variable, so every row ran the default. Fixed to an explicit `pk <- p0; pk$kz <- kz`. Recorded
because `within()` is an attractive idiom for exactly this kind of one-at-a-time scan and it fails
silently, producing a flat, plausible-looking table.
