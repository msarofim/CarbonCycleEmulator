# Handoff — CarbonCycleEmulator, 2026-08-16g: the `h_ml` CLIFF DECOMPOSED, the taper RETIRED as a fix, `h_ml` BOUNDED on Marcus's decision — and THE TWO-ARM REFIT IS RUNNING

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`,
**93 commits ahead of `main` and still not merged**. **HEAD = `56ebce6`**, working tree clean.

**Supersedes `handoff_2026-08-16f_pump_shipped_refit_blocked.md` for its §5 and §9 item 1
(both discharged).** Its §2, §3, §4 and §6 stand. Its §10 cautions all still hold, plus two new ones
(§8 below).

**Commits this session:** `ffd7726` (the decomposition) → `02d062d` (part 7, the attribution) →
`56ebce6` (the bound + 3 gates).

---

## 0. START HERE

1. **THE REFIT IS RUNNING.** Launched detached at the end of this session,
   `calibration/output/pump_arms/_run.log`. **~11–13 h for both arms, sequential.** §5 is how to read
   it and §5.3 is the one thing to check before anything else.
2. **16f's BLOCKER IS DISCHARGED.** Marcus took §5.5 **option 1 — bound `h_ml` to [85, 120]** — on
   the decomposition below. Implemented in-process only; `R/calibrate.R` untouched. Three gates, all
   passing. §4.
3. **THE CLIFF IS EXACTLY "THE ROWS APPEARED", TO 1e-12.** `h_ml` = 85 does not *fit worse* than
   84.99 — **it is scored on more data.** §2.1.
4. **THE TAPER (16f §5.5 option 3) IS RETIRED AS A FIX FOR THE PART THAT MATTERS.** It removes the
   barrier and **not** the incentive, and that is an identity, not a measurement. §2.2.
5. **AND THE ROWS ARE NOT WHY `h_ml` LEAVES THE BAND AT ALL** — a 236-log-unit pull against a
   10.0-log-unit cliff, and deleting the rows moves the argmax 32 → 32 m. **No formulation of those
   rows was ever going to fix this.** §2.3.
6. **BUT THE 236 DISCOUNTS ITSELF**, and this is why the bound is worth trying rather than obviously
   ruinous: 96 % of it sits on three streams that `kz`, `k_w` and `beta_max` serve directly. §3.
7. **`R/likelihood.R`'s own "1.61 σ at 184" is ~2× overstated** — the gate's own quantity is
   **0.80 σ**. Not a code defect; but the band's severity was argued from 1.61 in three handoffs. §2.5.
8. **THE MODEL HAS STILL NEVER BEEN CALIBRATED.** Unchanged from 16f §8, and this run is the first
   serious attempt. Read 16f §8 before promising anything.

---

## 1. What was asked and what was done

16f left two decisions and said nothing else should happen until they landed. This session
decomposed the first one instead of choosing among its options — because the decomposition turned out
to change which options were even live — put the result to Marcus, implemented his decision behind
three gates, and launched the refit.

---

## 2. THE DECOMPOSITION — `calibration/diag_hml_band_discontinuity.R`

~4 min, **4 gates, 5 pre-registered predictions**. DESIGN **§5.2k**. Nothing was proposed and
**`R/likelihood.R` is unchanged**.

**GATE B FIRST, because the rest is worthless without it.** The by-stream split needs a replica of
`ccx_make_logpost()`, and a drifted replica answers a different question silently. The replica's total
is asserted equal to the **real** objective's at an in-band and an out-of-band point: **gap
0.000e+00 at both.** GATE C: the out-of-band counterfactual row values reproduce the gated ones
in-band to **0.000e+00** over 11 points. GATE D: part 4's GLODAP cell recipe reproduces **both**
shipped targets to **0.00e+00** before any `h_ml` moves.

### 2.1 The cliff is exactly "the rows appeared"

The identity `Δ total = (rows that appeared) + (continuous drift)` closes to machine precision:

| edge | Δ total | rows | drift | residual |
|---|---|---|---|---|
| floor, `h_ml` 84.99 → 85.01 | −10.1308 | **−10.0136** | −0.1172 | **−6.4e-13** |
| ceiling, 119.99 → 120.01 | +9.5197 | **+9.6819** | −0.1622 | **−2.4e-12** |

Only the three `ocean_grad_*` streams jump; all 16 others plus the prior are continuous, and the jump
is **85×** / **60×** the drift the same 0.02 m step produces. Rows just inside: `ocean_grad_dic`
**−5.75** (z −1.79), `ocean_grad_d13c` **−0.37** (z +1.81), `ocean_grad_alk` **−3.90** (z +0.21).

**So `h_ml` = 85 is not a worse FIT than 84.99 — it is SCORED ON MORE DATA.** That splits 16f's one
number into two separable defects: **(A) a barrier** (the discontinuity — 16f §5.4's MCMC hazard) and
**(B) an incentive** (a skipped Gaussian contributes 0 where a live one contributes a negative
number, so leaving is a free gain).

### 2.2 A taper fixes (A) and NOT (B) — an identity

For any weight `w(h) ∈ [0,1]` on a **negative** row sum, `d/dw < 0`: the objective is still
monotonically rewarded for `w → 0`. **A taper converts a cliff into a ramp and leaves the summit
where it was.** Measured at ramp half-widths 15 / 30 / 60 m, the argmax over `h_ml` is **32 m in
every case** — identical to the shipped hard skip, to the rows deleted entirely, and to the rows
always live. **16f §5.5's option 3 is a continuity fix only, and 16f's "the only sampler-safe fix"
framing overstated it.**

### 2.3 THE HEADLINE — the rows are not why `h_ml` leaves the band

| quantity | value |
|---|---|
| objective's argmax over `h_ml` | **32 m** (30 is the prior bound, where `qlogis(0)` = −Inf) |
| best in-band `h_ml` | 85.01 m |
| **the pull** | **236 log-units** |
| **the cliff** | **10.0 log-units** |

**24×**, and **deleting the three rows moves the argmax not at all (32 → 32 m).** No formulation of
those rows can pull `h_ml` back into the band, because they are not what pushes it out. **Bounding
`h_ml` is therefore not a tie-breaker between formulations — it OVERRIDES a real preference**, and
that is what Marcus decided to do (§4), with §3 as the reason it is worth trying.

### 2.4 A fifth option that was not on 16f's list: σ-INFLATION

The band exists because a fixed-depth target is like-for-like with the model's boxes only near 100 m.
That is a **representation error**, and the honest way to carry one is **in quadrature** —
`σ_eff(h)² = σ_obs² + σ_rep(h)²` **with dnorm's normalisation term retained**, so inflating is
*charged for* rather than free and the gain is bounded (best case `σ_eff = |miss|`). **Not a tuning
knob:** `σ_rep(h)` is *measured* as the shipped-minus-like-for-like target gap.

Measured over `h_ml` 32 → 192: **DIC `σ_rep/σ_obs` 0.04–0.87, δ¹³C 0.01–1.11** (in-band DIC
0.04–0.34, out-of-band 0.22–0.87). **The mismatch the band exists to prevent never exceeds ~1 σ
anywhere in `h_ml`'s prior support** — a 10-log-unit switch is enforcing a sub-1σ mismatch. Priced at
the measured misses, inflation's best case gives away **21 %** of what the skip gives away (2.14 of
10.01). **Alkalinity's `σ_rep` is UNQUANTIFIED** — the GLODAP subset carries no `talk` column, so it
would need a new download or a stated assumption.

**This is the standing alternative if §5.3 goes badly**, and it is the only option that fixes (A) and
(B) together while leaving `h_ml` free. It is **not** implemented and **not** proposed for the
objective — it is a likelihood redesign and remains Marcus's call.

### 2.5 RECEIPT CHECK — `R/likelihood.R`'s own justification is ~2× overstated

The gate's comment reads "the mismatch is 0.09 sigma at `h_ml` = 100 but 1.61 sigma at the fitted
184". **The first half reproduces (0.07). The second does not.**

| candidate quantity | σ |
|---|---|
| (shipped − like-for-like@184) / shipped sd — **what the gate guards** | **0.80** |
| (frozen@75 − like-for-like@184) / shipped sd (25.25) | 1.26 |
| (frozen@75 − like-for-like@184) / **blk30** sd (20.16) | **1.58** |

The shipped rds carries `sd_by_block = c(blk30 = 20.16, blk60 = 25.25)` and ships the **conservative**
25.25; `diag_gradient_target_and_neff.R` called `part2b()` with `min(...)` over the valid blocks, i.e.
the **tighter** blk30. **So 1.61 is part 2b's frozen-at-75 contrast on part 2b's σ — a different
contrast on a different σ from the one the gate's own term uses.** NOT a code defect: the band still
guards a real mismatch. But **the band's severity has been argued from 1.61 in three handoffs, and
against the gate's own quantity it is 0.80 σ.**

### 2.6 Predictions: 3 PASS, 2 FAIL, and no bar was loosened

- **P4 FAILED in the direction that STRENGTHENS inflation, and the reasoning was wrong rather than
  the bar.** I predicted inflation would recover > 50 % of the skip's gain; measured **21 %**. I
  expected `z²/2` to dominate each row's logL — at ~1.8 σ misses `z²/2 ≈ 1.6` while `−log(σ√2π)`
  carries the bulk.
- **P5 FAILED, and it is the one that reframes the band**: `σ_rep` barely reaches `σ_obs` anywhere.
- **P1's first bar was measuring the objective's ~8 log-units/m slope in `h_ml`** — an absolute
  0.05-log-unit bar on "nothing else moves discontinuously" collided with 0.16 of *legitimate* drift
  over a 0.02 m straddle. **Re-derived as a ratio** (85×/60× against a 20× bar), not loosened. **P2
  became an exact identity** (bar 1e-6, residual 1e-12) rather than a 0.10 tolerance.

---

## 3. PART 7 — WHO PAYS THE 236, AND WHY IT DISCOUNTS ITSELF

Between `h_ml` = 100 and 32, with the gradient rows excluded:

| stream | Δ logL (32 − 100) |
|---|---|
| `co2_level_SPO` | **+144.5** |
| `co2_level_MLO` | **+98.0** |
| `d14c_SH` | **+68.0** |
| … | … |
| `gcb_ocean_sink` | −10.8 |
| `d13c_level_SPO` | −18.5 |
| `d13c_level_MLO` | −26.4 |
| **sum** | **+324.5** |

**Three streams carry 96 %, and the δ¹³C LEVELS and the ocean sink pull the OTHER way** — this is the
CO₂-level record against the δ¹³C-level record, not a consensus. The mechanism is plain: a thinner
mixed layer absorbs less carbon, so airborne CO₂ rises, i.e. **the model at init OVER-ABSORBS**. And
their absolute size says how bad init is: **`co2_level_SPO` alone is −256 log-units at `h_ml` = 100.**

**SO THE 236 DISCOUNTS ITSELF.** `kz`, `k_w` and `beta_max` all move ocean and land uptake directly —
they serve *exactly* the three streams carrying the pull — so with 19 parameters frozen at init,
`h_ml` is merely the cheapest available patch for a CO₂-level misfit. **236 is an upper bound and
probably a large overstatement of what bounding `h_ml` costs a refit.** Same caveat class as §5.2g's
pump margin.

**What survives unconditionally is the NEGATIVE result** (§2.3): the rows are irrelevant to where
`h_ml` goes. Whether the *pull* survives a refit is the refit's question, and the diagnostic cannot
answer it — **§5.3 is where it gets answered.**

---

## 4. THE DECISION AND HOW IT IS IMPLEMENTED

**Marcus 2026-08-16g: bound `h_ml` to [85, 120] for this refit** (16f §5.5 option 1).

| question | decision |
|---|---|
| `h_ml` band / gradient-row switch | **BOUND `h_ml` to [85, 120]** for this refit. §4. |
| the taper (16f option 3) | **retired as a fix for the incentive** — §2.2. Not discarded as a continuity fix. |
| σ-inflation (the fifth option) | **NOT implemented**, standing alternative if §5.3 goes badly. §2.4. |
| N vs D | unchanged from 16f: **fit both and compare**. Now running. |

**How.** By overriding `CCX_PARAM_TABLE$h_ml` **in this process only** — `R/calibrate.R` is
**untouched**, because the bound is a property of this refit and every diagnostic that runs tomorrow
must still see [30, 200].

- **`init` moves 75 → 100 out of NECESSITY, not taste.** 75 is outside the new bound and
  `.to_unc()` returns NaN, so the mode-find would have started from a non-finite point. 100 is the
  pump's own `h_ml` and the depth every pump diagnostic scores at.
- **The prior is narrowed WITH the bounds.** Leaving `dunif(30, 200)` would keep a density normalised
  over a support the sampler can no longer reach. That is a **constant +1.58**, identical in both
  arms, so it **cancels from the evidence contrast** — stated because a constant that was *not*
  identical between arms would not.
- **Three gates, all passing.** **H1** only `h_ml` changed, and only in lo/hi/init/prior — against a
  snapshot of the **whole** table (the first draft compared each entry against *itself* for every name
  but `h_ml`, a tautology that could never have caught a change to a second parameter). **H2** the new
  init round-trips finitely **and the shipped 75 is asserted to be REJECTED** by the new bound.
  **H3** all three rows are LIVE at init, asserted on `ccx_ocean_grad_scored()`'s **own return** rather
  than on the band arithmetic, so a change to the gate's internals cannot pass it silently — DIC
  +187.89, δ¹³C −0.6545, ALK +82.68.

**⚠️ THIS OBJECTIVE IS A DIFFERENT FUNCTION FROM THE UNBOUNDED ONE.** Its logpost is **not**
comparable with any earlier run's, on either side of the 2026-08-16 boundary. **Only the N-vs-D
contrast WITHIN this run means anything.**

---

## 5. THE RUNNING REFIT — how to read it

`calibration/run_modefind_pump_arms.R`, launched detached, log at
`calibration/output/pump_arms/_run.log`. **~11–13 h, both arms, sequential.** Each arm writes its own
`mode_fit_pump{N,D}.rds` as it finishes, so a kill after the first loses only the second.

```bash
tail -f ~/Documents/2026/CodeProjects/CarbonCycleEmulator/calibration/output/pump_arms/_run.log
```

### 5.1 Confirmed at launch

Gates H1–H3 and the arms-differ-only-in-`pump_mode` gate all pass. Start log-post at the bounded init
is **−4291.2**, which reproduces the diagnostic's `h_ml` = 100 value (−4291.1659) — the two paths
agree.

### 5.2 The early signal is GOOD

The truncated smoke arm gained **1067 log-units in 60 Nelder-Mead iterations** from `h_ml` = 100.
That is consistent with §3's reading that the other 19 parameters can absorb most of the CO₂-level
misfit `h_ml` was patching. **It is 60 iterations of a 20-parameter search and is NOT a result** — do
not quote it.

### 5.3 THE ONE THING TO CHECK FIRST, AND IT DECIDES WHETHER THE REST IS READABLE

**Read the per-stream table at (b3) BEFORE the Laplace evidence.**

- **If `co2_level_SPO` / `co2_level_MLO` RECOVER** (much smaller than the −256 / −183 they sit at at
  `h_ml` = 100 with everything else at init) — the bound was cheap, `kz`/`k_w`/`beta_max` absorbed the
  pull, and the refit is clean. Proceed to N-vs-D.
- **IF THEY STAY LARGE IN BOTH ARMS** — `h_ml` was absorbing a CO₂-level misfit that no other
  parameter can take, **both modes are bad, and N-vs-D is uninformative AGAIN** (for a different
  reason than 16f's). In that case the live options are §2.4's σ-inflation with `h_ml` free, or
  finding out what else in the model cannot fit the CO₂ level. **Do not read the evidence contrast in
  that case** — it would be comparing two bad modes.

### 5.4 Carried live risks from 16f §6

- **The Laplace evidence degrades to `NA` rather than being patched** when an arm's Hessian is not PD.
  N's was not, at a non-converged smoke point. `calibration/recompute_hessian.R` is the remedy.
- **`ARM_HESS_EPS` = 3e-4 is inherited from an 18-parameter run** and has not been re-derived at 20.
  (16f §9 item 5, still open.)
- **The per-stream N-vs-D reading is NOT pre-decided.** 16f's truncated table hinted D gains on
  `co2_seasonal_MLO`, `d14c_NH` and `d13c_level_SPO` — i.e. *not* "entirely the CO₂ record". Neither
  arm was converged. Read the real table fresh.

---

## 6. Files

| file | what |
|---|---|
| `calibration/diag_hml_band_discontinuity.R` | **NEW**, ~4 min, 4 gates + 5 predictions + 7 parts. §2, §3 |
| `calibration/output/hml_band_discontinuity/` | `_run.log`, the `.rds`, and a README marking it a diagnostic and listing its cautions |
| `calibration/run_modefind_pump_arms.R` | **the bound + gates H1–H3.** **RUNNING.** §4, §5 |
| `calibration/output/pump_arms/_run.log` | **the live run** |
| `DESIGN.md` | **§5.2k** — the decomposition, the taper identity, σ-inflation, the receipt check, part 7 |
| `CHANGELOG.md` | 2026-08-16g + the part-7 addendum |

Memory: `project_ccx_hml_band_discontinuity` rewritten (decomposition + decision + what to watch);
`MEMORY.md` index line updated.

---

## 7. Open decisions, in dependency order

1. **§5.3 — did the CO₂-level streams recover?** Blocks everything below. This is the first thing to
   do when the run lands.
2. **N or D**, from the evidence + the per-stream table — **only if 1 says the modes are readable.**
3. **`recompute_hessian.R`** if either Hessian is non-PD, and **re-derive `ARM_HESS_EPS` at 20
   parameters** rather than inheriting 3e-4. (was 16f item 5)
4. **σ-INFLATION: implement or not.** §2.4. Now the standing alternative rather than a "later" item,
   and the only candidate that fixes both defects with `h_ml` free. **Marcus's call** — it is a
   likelihood redesign. Needs a decision on alkalinity's unquantified `σ_rep`.
5. **Correct or annotate `R/likelihood.R`'s "1.61 σ at 184"** to the gate's own 0.80 σ. §2.5. Small,
   but it is load-bearing prose.
6. **The pilot MCMC**, and whether 16f §5.4's barrier is what has been breaking it. **NOTE:** with
   `h_ml` bounded the barrier is gone *for this refit*, but a **posterior** run has to decide the same
   question again — a hard bound is defensible for a mode-find and is a stronger claim for a sampler.
7. **The frozen-Revelle parity tolerance** (16f §3.3) — only when something makes it fire.
8. **σ_Δ has NOT plateaued in block size**; **representation error still ZERO in the objective**
   (§2.4 measures it but does not ship it); **point σ vs Student-t**; **is A's `kz` = 6404 a blocker
   or a re-derivation**; **does candidate A ship**. (carried from 16c/16d/16f)
9. **Merge `luc-veg-debit`** — now **93 commits** ahead.

---

## 8. Non-obvious state, and cautions

- **A DETACHED Rscript IS RUNNING** and will keep running after this session ends. It was launched
  with `nohup`, so **nothing will notify you when it finishes** — check the log. Do not launch a
  second heavy job alongside it: 16 GB Mac, and the arms are sequential *on purpose*.
- **`R/calibrate.R` DOES NOT CONTAIN THE BOUND.** The refit's `h_ml` bound is an in-process override
  in the driver. `CCX_PARAM_TABLE$h_ml` is still [30, 200] on disk, and every diagnostic sees that.
  **Do not "fix" the apparent inconsistency by editing `R/calibrate.R`.**
- **The bounded objective's logpost is NOT comparable with anything earlier.** §4.
- **Two traps for anyone writing a diagnostic here, both hit this session:**
  `ccx_par_to_unc(ccx_default_params())` **errors** — `bomb_total`, `luc_scale`, both sigmas and both
  gradient offsets are fitted parameters with **no field in `ccx_default_params()`**; use
  `ccx_init_unc()`. And `ccx_loglik(by_stream = TRUE)` returns a **named numeric VECTOR, not a list**,
  so `[[missing_name]]` **errors** instead of returning NULL.
- **`h_ml` = 30 cannot be evaluated** — it is the prior's own bound, where `qlogis(0)` = −Inf. The
  diagnostic's argmax at 32 m means `h_ml` runs **into its bound**, not that 32 is an interior optimum.
- **Do not quote the 236 as the cost of the bound.** §3: upper bound, and probably a large
  overstatement.
- **Do not quote anything from the smoke runs** — `pump_arms_SMOKE/` (16f) or the 1067-log-unit gain
  (§5.2). Neither is converged.
- **`calibration/output/mode_fit.rds` is still absent.** Every "at the mode" number in any handoff
  comes from `quarantine/20260815_pre_gradient_terms/mode_fit.rds`, which predates the gradient terms
  **and** the pump. **The running refit is what replaces it** — and it will land at
  `output/pump_arms/mode_fit_pump{N,D}.rds`, **not** at `mode_fit.rds`.
- **Name collision, unchanged:** `grad_off_co2` / `grad_off_d13c` in `err` are the **MLO−SPO
  ATMOSPHERIC** offsets. The ocean rows are `LIK_OCEAN_GRAD_*` / `ocean_grad_*`.
- **The 4 remaining test failures are unchanged and undiagnosed** — see 16f §8.

**Still do NOT:** hand-tune stream weights; delete `excess_c14_ocean` or `d14c_intcal`; free any land
turnover parameter; delete the `kz` bracket bare; build the conveyor; splice any pre-2026-08-15
posterior; **compare any logL across the 2026-08-16 boundary**; quote §4.2's ~384 log-units or its
1996.2555 baseline; **quote the SHIM's export figures or the "3.6×" POC ratio**; **quote §5.2g's
+259.4 as the pump's value without the upper-bound caveat**; **quote 274.5 as `pump_grad`'s value**.

---

## 9. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-16g_hml_decomposed_refit_launched.md`. **16f's `h_ml` blocker is
> discharged**: the cliff decomposed to *exactly* "the three rows appeared" (1e-12), a taper fixes the
> barrier and **not** the incentive, and the rows turned out to be **irrelevant** to where `h_ml` goes
> (236-log-unit pull vs a 10.0 cliff; deleting the rows moves the argmax 32 → 32 m). Marcus bounded
> `h_ml` to [85, 120] for this refit and **the two-arm refit is running** —
> `calibration/output/pump_arms/_run.log`. **First job: §5.3 — check whether `co2_level_SPO`/`MLO`
> RECOVERED in the per-stream table BEFORE reading the Laplace evidence.** If they did, proceed to
> N-vs-D; if they stayed large in both arms, `h_ml` was absorbing a CO₂-level misfit no other
> parameter can take, both modes are bad, and §2.4's σ-inflation is the live alternative.
