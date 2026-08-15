# Handoff — CarbonCycleEmulator, 2026-08-15c: item 6b is taken, and the h_ml prerequisite makes the pump case STRONGER

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit` at
**`078609c`**, still **not merged**. Working tree clean. Suite **4 failing**, unchanged, none of
them flagged for Marcus.

**Supersedes `handoff_2026-08-15b_gradient_terms_and_shares.md`** for items 6b and 9 and for the
parameter count; everything else in that note still stands. **15b §7's ordering is now materially
in question** — see §5.

---

## 0. START HERE

1. **Item 6b is TAKEN. `sigma_co2` is RETIRED; 20 → 19 parameters.** The CO₂ level sd is
   `LIK_CO2_REP_ERR` = 1.0 ppm alone. §2.
2. **The reason it was retired is NOT the reason 15 and 15b gave.** Three of their four grounds
   were measured and failed. Do not re-derive the old rationale from those notes. §2.1.
3. **Item 9's prerequisite is DONE and it points the other way from what §4.2 expected.**
   `h_ml` = 184 m is a **capacity-side workaround for an export deficit**. The pump case is
   **stronger** after this, not weaker, and its pre-registered test is amended. §3.
4. **The refit (item 8) is still HELD — but it is no longer held on anything.** 6b discharged
   the stated blocker. What holds it now is a *choice*, not a dependency: building the pump is
   structural and would invalidate a mode found first. **Marcus chose to decide this cold.** §5.
5. **My first h_ml design was INVALID and is quarantined.** If you find yourself reaching for
   "drive `ml_mass_kg` and `dz[0]` at different depths", read §3.1 first. §3.1.

---

## 1. What Marcus decided today

| | decision | taken on |
|---|---|---|
| 1 | `sigma_co2`: **fix at 0** (retire it), not "fix at the MAP value" and not "leave free" | the measurement in §2, after the stated grounds failed |
| 2 | do the **cheap h_ml test BEFORE** the 5.4 h refit — a deliberate departure from 15b §7's ordering | a pump would be structural and would throw the mode away |
| 3 | after the h_ml result: **handoff and decide the pump-vs-refit fork cold** | the fork now rests on a result that did not exist when the ordering was set |

---

## 2. Item 6b — `sigma_co2` retired (`bb254f3` measurement, `10d6780` implementation)

`calibration/diag_sigma_co2.R` (new, ~1 min, output `calibration/output/sigma_co2/`) measured it
**before** acting, because the standing call rested on a single number.

### 2.1 The stated grounds were measured and THREE OF FOUR FAILED

The analytic frame reorganises the question. The level sd was √(σ² + c²) with c fixed at 1.0, so
σ\* = √(R² − c²) — **no interior optimum whenever the pooled residual RMS R < c**. That is a
statement about **R**, not about the parameter, and the repo straddles the threshold:

| point | R_pool | interior optimum? |
|---|---|---|
| `ccx_default_params()` | **1.454** | YES, σ\* = 1.056 |
| pre-gradient MAP mode | **0.614** | NO |

That is also why `test-likelihood.R`'s interior-maximum assertions still pass — its fixture is on
the other side. The margin at the mode is **0.789 ppm**.

- **"pinned at a boundary"** — not on the scale the sampler uses. `sigma_co2` was
  log-transformed, so σ → 0 is u → −∞ and the lognormal prior closes it smoothly; the posterior
  mode is **interior and unimodal** at both points. The edge was an artefact of natural units.
- **"will hurt covariance conditioning"** — **max |r| = 0.043** (with `luc_scale`), against
  **0.907** for the worst pair in the same Laplace matrix. Very nearly orthogonal to everything.
- **"unidentified"** — tightened **2.08×** vs prior at the mode, **5.79×** at defaults; **4th of
  18** by posterior width, behind `npp_frac_NH` (1.318), `h_ml` (0.984), `kz` (0.978), none of
  which is proposed for removal.

### 2.2 What actually retired it

**A free error scale on the stream that already outvotes the partition terms 40:1 is
SELF-WEIGHTING.** As R fell 1.454 → 0.614, the effective sd fell 1.4659 → 1.0251 — the CO₂ level
stream got **2.04× louder**. Positive feedback on the dominant constraint, in the direction that
worsens the imbalance the whole review is about. Fixing it costs **1.05×** of weight at the
current fit and stops the weight tracking the residual thereafter.

### 2.3 The contract, and the one thing that will bite

`ccx_loglik()` now has **two branches** on the CO₂ level sd:

```
err$sigma_co2 ABSENT  -> sd = LIK_CO2_REP_ERR        <- the objective
err$sigma_co2 PRESENT -> sd = sqrt(s^2 + REP^2)      <- legacy parity
```

**The absence is the NEW behaviour, which inverts this repo's usual absence-skips-a-stream
idiom.** Deliberate: an updated caller says so by dropping the field; a stale one keeps its old
weight instead of being silently re-weighted. **Every pre-today diagnostic passes `sigma_co2` and
therefore still runs on the OLD, softer sd** — verified, `diag_sigma_co2.R` reproduces
bit-for-bit across the change. So a legacy diagnostic's CO₂ numbers are *not* on the objective's
weighting. Check which branch a number took before quoting it.

`ccx_make_logpost()` omits the field **explicitly** rather than passing 0 — identical arithmetic
today, but a zero would silently reacquire the old branch if the contract ever moved.

### 2.4 What was given up, and the tell to watch for

The free σ was **the only adaptive valve on the CO₂ level stream**, and the margin at the mode is
0.789 ppm, so chains **will** cross into R > 1.0 where a fixed sd prices a bad CO₂ fit at full
volume with no give. **If the refit shows CO₂ level dominating the trace, or a chain unable to
leave a bad-CO₂ region, this is the first thing to look at.** Recorded in `R/calibrate.R` beside
the retirement.

### 2.5 Knock-ons, all discharged

- `LIK_GRAD_*`'s standing "re-measure if σ_co2 or `LIK_CO2_REP_ERR` move" — **done**. Implied
  gradient sd 1.449 → 1.414 ppm, double-count ratio **17.1× → 16.3×**. **ADD-a-term still beats
  ROTATE.** `test-gradient.R` case 6 now gates it as a pure constants check.
- **DESIGN.md §5.2 corrected** — it still described *both* the AR(1) model retired on 2026-08-11
  *and* a free σ_add for CO₂. Both corrections dated in place; §5.1's draft table marked
  unmaintained; `R/likelihood.R` / `CCX_PARAM_TABLE` named authoritative.
- `LIK_CO2_REP_ERR` now carries its receipt (co-located MLO programmes disagree 0.39–0.59 ppm
  RMS, n = 702) **and** the note that it is **conservative, not tight** — χ²/dof ≈ 0.38 at the
  last mode. **Lowering it is a stream-weight change, flagged and NOT taken.**

### 2.6 Tests

+4 blocks, **all three mutations caught**: loosening the absence branch to 1.5× → 4 failures;
dropping the legacy quadrature → 5; `LIK_CO2_REP_ERR` 1.0 → 0.4 → 2 in `test-gradient.R`. The
parameter-ledger test fired on the count as designed and was **recorded, not merely bumped**.

---

## 3. Item 9's prerequisite (`078609c`) — the answer inverts

`calibration/diag_h_ml_roles.R` (new, ~3 min, output `calibration/output/h_ml_roles/`).
**No model code changed.**

### 3.1 THE FIRST DESIGN WAS INVALID — read this before redesigning anything here

15 §4.2 proposed "hold the mixed-layer carbon inventory fixed while varying its depth". I first
implemented that by driving `aux$ml_mass_kg` (capacity) and `grid$dz[0]` (geometry) at
**different** depths. **That is not a decomposition.** The core reads the chemistry's
concentration as `y_ml/ml_mass_kg` and the diffusion's as `y_ml/dz[0]` — two encodings of *one*
quantity. Disagreeing makes "mixed-layer concentration" mean two different things inside one
timestep.

It announced itself: at h = 184 m, BOTH **+425.9**, CAPACITY **−26,203.8**, EXPORT **−29,035.3**
— an **interaction of +55,665 against an effect of +426**. The sign pattern confirms the artefact
in both arms. Post-mortem:
`calibration/output/quarantine/20260815_h_ml_inconsistent_grid_arms/README.md`.

Two consequences worth carrying forward:

- **A `ccx_spinup(grid = )` argument was added for that design and then REVERTED.** Leaving API
  surface whose only known use is refuted invites its reuse. `ccx_spinup()` is back to its
  4-argument signature — if you find a note claiming otherwise, this is why.
- **A second, silent defect in the same file:** the deep-Δ¹⁴C confound control filtered on
  `d14c_deep`; the stream is **`d14c_deep_ocean`**. It was a no-op, caught only because the
  diagnostic printed both columns and they were identical in every row. *Print the control and
  the uncontrolled number side by side; that is what caught it.*

### 3.2 The valid replacement, and the two pre-registered tests DISAGREEING

Consistent grids only — `h_ml` goes through `p`, so capacity and geometry always move together.

| step | result | signature |
|---|---|---|
| signs, off the grid alone | 75 → 184 m: capacity **×2.45**, ML→interior conductance **×0.54** | channels have *opposite* signs |
| where the carbon goes | **+32 GtC into the mixed layer**, **−19 GtC out of the interior**; sink 2.87 → 3.06 | **CAPACITY** |
| `kz`, the pure export knob | preferred depth over a 6× kz range: 220, 220, **184**, 50, 50, 50 m — at kz ×1.4 it wants **50 m** | **EXPORT** |

**Both hold, at different levels, and the reconciliation is the finding: what the objective is
short of is UPTAKE. `h_ml` = 184 m is a CAPACITY-SIDE WORKAROUND FOR AN EXPORT DEFICIT, reached
for because `kz` is bracket-limited (96.6 % up).** r(h_ml, kz) = **−0.211** fits that — they
substitute, weakly, in exactly this way. So `h_ml` is **not evidence against the pump**; it is a
symptom of the same shortage.

### 3.3 Why `kz` cannot simply be freed — which IS the pump's case

Diffusion ventilates ¹⁴C in proportion to the carbon it moves. Buying uptake with `kz` drives the
deep-Δ¹⁴C term **z +1.70 → +4.47**, away from a target (−175.3 ± 10.3 ‰) the model already misses
on the **under-depleted** side; at kz ×1.4 the two CO₂ level streams lose **712 log-units**
between them (over-absorption, sink 3.37).

**A biological pump exports carbon as sinking particles and remineralises it at depth — adding
uptake WITHOUT mixing surface water down.** Nothing currently in the model can do that. This is
the mechanism argument 15 §4.2 gestured at, now measured.

### 3.4 ITEM 9'S PRE-REGISTERED TEST IS AMENDED

15 §4.2 set it as: *does `h_ml` relax below ~163 m and `kz` off the top of its bracket, while the
ocean sink holds near 3.1?* Part 4 makes the `h_ml` clause **measured-plausible** rather than
speculative — but it is **not sufficient**.

> **THIRD CLAUSE: does deep Δ¹⁴C move TOWARD −175.3 ‰ rather than away?**

That is the clause the `kz` route **fails**, and therefore the one the pump must beat to be an
improvement rather than a re-arrangement. Recorded in the diagnostic's own output, not only here.

**Reading 2 of 15 §4.2 is NOT closed.** "A single global column has no horizontal transport, so
h_ml = 184 m may be emulating high-latitude deep winter mixing and subduction" survives this
diagnostic untouched — nothing here distinguishes a pump from that, and if it is the explanation
the honest move is still to document `h_ml` as an effective parameter. **The pump's third clause
is what would separate them.**

---

## 4. Non-obvious state

- **19 parameters.** `beta_max, fert_k, q10, k_w, h_ml, kz, tau_ex, npp_frac_NH, seas_amp_NH,
  seas_amp_SH, seas_phase_NH, seas_phase_SH, gamma_enso, bomb_total, luc_scale, sigma_d13c,
  sigma_d14c, grad_off_co2, grad_off_d13c`.
- **`calibration/output/mode_fit.rds` is still EMPTY.** The app has no mode. `app/global.R`'s
  name guard rejects the quarantined 18-parameter one — that is the guard working.
- **One eval measured at 0.0665 s → ~5.4 h** for a mode-find at the last one's 291,832 evals.
  15b quoted 0.083 s / 6–7 h. **I did not attribute the difference and neither should you.**
- **`sigma_d13c` and `sigma_d14c` are deliberately still FREE.** The self-weighting argument is
  specific to the dominant stream; a free scale on a minor one is a robustness valve, not a
  feedback loop. `sigma_d13c`'s freedom was its own decision (15 §1, decision 3).
- **The absence contract now has TWO opposite conventions in `err`,** and this is the live
  footgun: **gradient offsets absent → streams SKIPPED**; **`sigma_co2` absent → new behaviour,
  tighter sd.** Name your arguments and check `by_stream` for ABSENT streams before quoting
  anything.
- Everything from 15b §6 that is not superseded still stands: three switches reproduce history
  (`FORC_USE_LUC_NH_SHARE_TS`, `FORC_USE_EMIS_SEASONALITY`, `CCX_FERT_LOG`); `FORC_FOSS_NH_SHARE`
  has **no switch** (set 0.9201 back to 0.95 by hand); every "at default parameters" number is at
  `gamma_enso` = 0 while `app/global.R` overrides to 0.5.
- **`luc-veg-debit` has never been merged** and is now a long way from `main`.

---

## 5. The ordering, amended again

| # | task | status |
|---|---|---|
| ~~1–5c, 7~~ | objective, β, `luc_scale`, GLODAPv2, gradient, shares, seasonality, MM fertilisation | **DONE** |
| **6** | `LIK_EXCESS_C14_TARGET` | **NOT a blocker** — 15 §9 |
| ~~6b~~ | **`sigma_co2`** | **DONE** `10d6780` — retired |
| **8** | **THE REFIT**, 19 parameters, ~5.4 h | **structurally UNBLOCKED.** Held only by the fork below |
| **9** | **the pump** | **prerequisite DONE and it argues FOR building it** (§3). Test amended (§3.4) |

**THE FORK, which is what a fresh session should open on.** The pump is a **structural** change,
so a mode found before it is thrown away. But every "at the mode" number in the repo is stale,
the app has no mode, and the pump work itself would be better done at a current mode than at
defaults or a four-change-old quarantined one. **Marcus deferred this deliberately to decide
cold — do not pick one and start.**

If the pump goes first it needs its own design decisions signed off before any code:
export-production formulation, remineralisation depth profile, and whether the particle flux
carries ¹³C/¹⁴C fractionation (it must carry the isotopes; the question is the fractionation).

**Still do NOT:** hand-tune stream weights; delete `excess_c14_ocean` or `d14c_intcal`; free any
land turnover parameter; **delete the `kz` bracket** (§3.3 is further evidence it is
load-bearing — without it the fit buys uptake by wrecking deep Δ¹⁴C); build the conveyor
(falsified twice in-repo); splice any pre-2026-08-15 posterior into a new chain; quote a
log-likelihood from a diagnostic that has not been given the gradient offsets; **or lower
`LIK_CO2_REP_ERR` as housekeeping** — it is now the whole CO₂ level sd and a stream weight.

---

## 6. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-15c_sigma_co2_and_h_ml.md`. Items 1–7 and 6b are done; the
> objective is **19 parameters** and `sigma_co2` is retired. The h_ml prerequisite is done and
> **argues FOR building the pump** — `h_ml` = 184 m is a capacity-side workaround for an export
> deficit that `kz` cannot supply without wrecking deep Δ¹⁴C. **Open on the fork in §5: pump
> (structural, invalidates a mode) vs refit (~5.4 h, unblocks everything stale). Marcus deferred
> it deliberately — ask, do not pick.** Suite is 4 failing, none flagged. Note the two OPPOSITE
> absence conventions in `err` (§4).
