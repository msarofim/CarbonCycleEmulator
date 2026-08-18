# Handoff — CarbonCycleEmulator, 2026-08-18: THE REFIT LANDED, ARM N ADOPTED (provisionally), `luc-veg-debit` MERGED — and the next job is the 4 test failures

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`. **TRUNK IS `main` AGAIN** —
`luc-veg-debit` was fast-forwarded into it this session after ~100 commits unmerged.
**HEAD = `a7438a6` on `main`**, working tree clean.

**Supersedes `handoff_2026-08-16g_hml_decomposed_refit_launched.md`** for its §5 (the running refit)
and its open items 1, 2, 5 and 9 — all discharged. Its §2 (the decomposition), §3 (part 7) and §4
(the bound and its gates) **stand**, and its §8 cautions still hold except where explicitly retired
below.

**Commits this session:** `89dfb5a` → `7ea5c4b` → `705dae5` → `438fc82` → `e2c9238` → `a7438a6`.

---

## 0. START HERE

1. **THE REFIT IS DONE.** 23 h 57 m, both arms. `calibration/output/pump_arms/` holds
   `mode_fit_pump{N,D}.rds` and `pump_arms_comparison.rds`. §2.
2. **§5.3 TOOK THE GOOD BRANCH.** The CO₂-level streams recovered hugely (`co2_level_SPO`
   −255.94 → **−62.87**), so the bound was cheap and the N-vs-D comparison is readable. §2.1.
3. **`h_ml` LANDED INTERIOR IN BOTH ARMS (94.36 / 91.16), ROWS LIVE.** Nobody pre-registered this and
   it is the cleanest result of the run: **16g's 236-log-unit pull was an artefact of freezing the
   other 19 parameters.** §2.2.
4. **ARM N ADOPTED, PROVISIONALLY** (Marcus 2026-08-18). Evidence favours N by **5.62**, but read
   §2.4 before quoting that — the driver itself says *indicative, not a Bayes factor*. §3.
5. **THE PER-STREAM READING REVERSED.** "D's gain is entirely the CO₂ record" is **wrong**: CO₂ ties,
   and the contest is δ¹³C levels vs sinks + ¹⁴C. §2.3.
6. **JOB B IS DONE — the 4 test failures are DIAGNOSED, and none is a code bug.** Three
   mis-specified bars, one stale test premise. **Repairs specified, NOT applied — they need a
   decision.** §6, and `notes/diag_2026-08-18_test_failures.md`.
7. **STILL NO POSTERIOR.** The sampler has never converged on this model. The mode is a mode. §7.

---

## 1. What was asked, and what was done

16g left the refit running and said §5.3 was the first job. This session read it, cleared the two
zero-compute open items while the machine was busy, took Marcus's two decisions (adopt N; do the
merge), and executed them.

Marcus's instructions, verbatim in effect: *finish the refit first; cue up the land-use-change merge,
the failure diagnosis and the item-4 spec for when it finishes* → then *adopt N, flag it provisional*
and *do the merge* → then *write the handoff, with job B next*.

---

## 2. THE REFIT

`calibration/run_modefind_pump_arms.R`, launched 16g, **23 h 57 m**. N: 753.5 min / 303,661 evals.
D: 683.0 min / 297,804 evals.

### 2.1 §5.3 — the CO₂-level streams RECOVERED

Verified against 16g's **saved rds**, not its prose:

| stream | 16g @ `h_ml` = 100, else init | arm-N mode | recovery |
|---|---|---|---|
| `co2_level_SPO` | −255.94 | **−62.87** | **+193.1** |
| `co2_level_MLO` | −182.72 | **−73.75** | **+109.0** |

Biggest movers overall: `co2_seasonal_MLO` **+676.3** (−674.6 → +1.7), `d13c_gradient` **+490.0**,
`d14c_SH` +166.7, `d13c_level_MLO` +166.1. **Only three streams got worse, all trivially:**
`excess_c14_ocean` −3.2, `d14c_deep_ocean` −2.1, `d14c_intcal` −1.8.

Per 16g §5.3 this is the "the bound was cheap, `kz`/`k_w`/`beta_max` absorbed the pull, the refit is
clean" branch. **The evidence contrast is therefore readable** — which was the precondition for
everything below.

### 2.2 THE RESULT NOBODY PRE-REGISTERED — `h_ml` went interior in BOTH arms

| arm | `h_ml` | rows | `pump_grad` | `kz` (% up bracket) |
|---|---|---|---|---|
| N | **94.36** | LIVE | **289.60** | 6439.2 (96.6 %) |
| D | **91.16** | LIVE | **282.26** | 6241.6 (88.9 %) |

**Had the 236-log-unit pull survived a refit, `h_ml` would sit pinned at the 85 bound. It does not, in
either arm.** This confirms 16g §3's reading directly: with 19 parameters frozen, `h_ml` was merely
the cheapest patch for a CO₂-level misfit that `kz`/`k_w`/`beta_max` absorb on their own. **The 236
was an artefact of the freeze, and it is now retired as a live concern for the mode-find.**

**`pump_grad` is CONSTRAINED in both arms** — 289.60 / 282.26, against **963.6 / 1431.0** in 16f's
rows-off truncated arms. Both near the old mode's 1-D optimum (274.5), above the observed 233.11.
The gradient rows are doing what they were added to do.

### 2.3 THE PER-STREAM TABLE REVERSED THE PRE-REFIT READING

16g §5.4 said "read the real table fresh" and was right to. 16f's *truncated, unconverged* table
hinted D gains on `co2_seasonal_MLO`, `d14c_NH` and `d13c_level_SPO`. Two held. **The third reversed
outright.**

| D buys | Δ (D−N) | D sells | Δ (D−N) |
|---|---|---|---|
| `gcb_ocean_sink` | +2.51 | `d13c_level_SPO` | **−9.74** |
| `gcb_land_sink` | +1.93 | `d13c_level_MLO` | **−7.30** |
| `d14c_NH` | +1.92 | | |
| `d14c_SH` | +1.80 | | |
| `co2_seasonal_MLO` | +0.90 | | |
| `d14c_deep_ocean` | +0.77 | | |

**"D's gain is entirely the CO₂ record" is WRONG.** The CO₂ levels **tie** (−0.43 MLO, −0.16 SPO) and
`d13c_gradient` ties to **+0.00**. The whole contest is **δ¹³C levels (N wins, −17.04) against
sinks + ¹⁴C (D wins, +10.91)**; net loglik −6.13.

**This independently corroborates the pump × advection symmetry result** (memory `ccx_pump_advec`:
the reversal ties CO₂ and breaks only the ISOTOPES). At two modes differing in **all 20 parameters**,
CO₂ ties and only the isotopes decide. That was a prediction of the symmetry argument and it held in
a setting the argument was not fitted to.

### 2.4 The comparison, and why it is not a Bayes factor

| | N | D | D − N |
|---|---|---|---|
| log-posterior at MAP | −2091.16 | −2096.26 | −5.10 |
| ½ log\|−H\| | 61.43 | 61.96 | +0.52 |
| **Laplace log-evidence** | | | **−5.62** |

Both Hessians **PD** (cond 6.8e5 / 5.5e5) ⇒ **`recompute_hessian.R` was needed for neither arm.**
`(d/2)log2π` cancels (same 20 parameters) and 16g §4's prior renormalisation constant (+1.5805) is
identical in both arms, so it cancels too.

**⚠️ THE DRIVER'S OWN VERDICT: "READ THIS AS INDICATIVE, NOT AS A BAYES FACTOR."** `kz` is pinned near
its bracket top in both arms, so the posterior is non-Gaussian in that direction and the Hessian
reports the **transformed coordinate's** curvature, not a free one's.

**AND BOTH ARMS HIT THE 20-RESTART CAP WHILE STILL GAINING** — both flagged NOT CONVERGED. `ARM_TOL`
= 1e-4 is unreachable for a 20-parameter Nelder-Mead here; N's last restart gained 0.0141, ~140× the
tolerance. They are **plateaus, not climbs** (N moved 0.7 log-units over restarts 8→19; BFGS polish
+0.09) — **but that ~0.7 wander is the noise floor, and 5.62 is only ~8× it.**

---

## 3. THE DECISION — arm N, PROVISIONALLY (Marcus 2026-08-18)

**The case for N:** favoured on evidence (5.62), on MAP height, and it wins the **δ¹³C levels
(+17.04)** — the stream class the gradient rows and the pump exist to constrain.

**What "provisional" is carrying, and it is not a formality:**

- the "indicative, not a Bayes factor" caveat above, and a pinned `kz` in both arms;
- both arms capped and flagged not converged, with 5.62 only ~8× the plateau noise;
- **`bomb_total` sits at z = +3.01 in N and is FLAGGED; D flags nothing** — the adopted arm is the one
  with a parameter in a prior tail;
- **`ARM_HESS_EPS` = 3e-4 is still inherited from an 18-parameter run**, un-re-derived at 20, and the
  evidence contrast depends on the Hessian it produces.

**Revisit when a converged posterior exists.** Nothing downstream is expensive to redo, which is what
makes this defensible as provisional rather than a deferral.

**Arm N mode, natural scale:**

```
beta_max     0.5290    bomb_total  121.2200    fert_k       155.7044   gamma_enso    0.5155
grad_off_co2 -0.0456   grad_off_d13c 0.0826    h_ml          94.3587   k_w         1968.7733
kz        6439.1654    luc_scale     1.0081    npp_frac_NH    0.6396   pump_grad    289.6009
q10          2.2275    seas_amp_NH  17.7976    seas_amp_SH    3.7300   seas_phase_NH 3.9028
seas_phase_SH 10.6551  sigma_d13c    0.1931    sigma_d14c     6.2779   tau_ex        1.0706
```

---

## 4. THE MERGE — `luc-veg-debit` → `main` (16g item 9)

**A STRICT FAST-FORWARD, which is easier than eight consecutive handoffs implied.** `main` was a
direct ancestor: **99 ahead, 0 behind**, no conflicts, **no working-tree change at all**. Verified
with `git merge-base --is-ancestor` before executing, then run as `git merge --ff-only`.

| | before | after |
|---|---|---|
| `main` | `0b7371c` | **`e2c9238`** (then `a7438a6` with the log entry) |
| HEAD | `luc-veg-debit` | **`main`** |

**Fast-forward was chosen over a squash for RECOVERABILITY, not taste:** a squashed history can always
be produced later from preserved commits; an un-squash cannot. This project also bisects per-commit
provenance for the pump and gradient work. **Marcus did not answer the ff-vs-squash sub-question — this
was my call and it is reversible.** `luc-veg-debit` is **KEPT, not deleted**; `0b7371c` is the
recovery ref (`git branch -f main 0b7371c`).

**No remote is configured. Nothing was pushed.**

---

## 5. The two items cleared while the machine was busy

**16g item 5 — the "1.61 σ" prose (`89dfb5a`).** `R/likelihood.R`'s `h_ml` gate paragraph now reads
**"0.07 σ at 100 and 0.80 σ at 184"**, named as the gate's own quantity; the fixed-depth TARGET
bullet's bare "1.61 σ" became **1.26 σ** (the frozen-at-75 contrast on the σ that term actually
ships). **Comment-only — the diff was verified to reach no executable line** before touching a file
the running refit had sourced. `HB_REF_MISMATCH_184 <- 1.61` in the diagnostic **stays 1.61 by
design**: part 5 divides by it to recover the implied σ, which is the step identifying it as blk30.

**16g item 4's blocker — alkalinity's `σ_rep` (`7ea5c4b`).** 16g recorded it as unquantified because
"the GLODAP subset carries no `talk` column, so it would need a new download or a stated assumption."
**The clause is true of the file 16g's part 4 reads; the inference is WRONG.** The shipped ALK target
was never built from that file — `data-raw/build_glodap_deep_targets.R:324` reads
`glodap_dic_talk_subset.csv`, **464,590 QC-passed bottles already on disk**. New
`calibration/diag_alk_sigma_rep.R` (3 gates + 3 predictions, all pass) reproduces **both** shipped
targets from that file's cells to **0.00e+00**, then measures:

| row | in band | all `h_ml` |
|---|---|---|
| DIC | 0.04–0.34 | 0.04–0.87 |
| δ¹³C | 0.01–0.55 | 0.01–1.11 |
| **ALK** | **0.02–0.07** | **0.02–0.34** |

**The row feared unquantified is the best-behaved of the three.** Lesson filed as memory
`blocker_reason`: a recorded blocker carries a *reason*, and the reason is the part that decays.

**The σ-inflation spec** is at `notes/spec_2026-08-17_sigma_inflation.md` — spec only, still Marcus's
call, and its one missing input (the cost, re-derived over all three rows) is §7 item 3.

---

## 6. JOB B — the 4 test failures, DIAGNOSED 2026-08-18 (none is a code bug)

**Full account: `notes/diag_2026-08-18_test_failures.md`. Suite baseline MEASURED, not inherited:
`FAIL 4 | WARN 53 | SKIP 2 | PASS 857`.** 16f's "plausibly stale gates" was *"an assessment, not a
verdict"* — attacking it rather than accepting it is what produced the diagnosis. **Every bar was
DERIVED at the protocol it should have been stated at; none was re-baselined.**

| # | test | measured vs bar | verdict |
|---|---|---|---|
| 1 | `test-pulse.R:113` | 0.213 vs > 0.30 | **bar mis-specified** — cites Joos **PD100** (389 ppm held) but measures on **SSP1-1.9**. Model's own diagnostic: PD-held 0.297, ssp126 0.267, PI 0.152. **0.213 is where it belongs.** |
| 2 | `test-luc-permanence.R:88` | 0.151 vs > 0.2 | **bar mis-specified, match EXACT** — `lp_background()` is a **preindustrial** background; `diag_joos_irf.R`'s "PI, held" IRF@100 = **0.152** vs the test's **0.151**. |
| 3 | `test-mechanisms.R:32` | 0.30 vs > 0.5 | **wrong statistic** — one endpoint bar for six mechanisms. Five are monotone and clear it 36–450×; **ENSO is the only OSCILLATORY one**, so 2100 reads *phase*. Its **max is 0.537 at 2032**. It IS wired. |
| 4 | `test-luc-permanence.R:104` | 0.074 vs < 0.02 | **stale premise** — needs **both** `f_luc_perm = 0` **and** `f_luc_wood = 1`. With both: af@100 = **−0.0032**, af@150 = −0.0026, reproducing the recorded old signature and passing. |

**A REAL DEFECT FOUND ALONGSIDE (4), minor but load-bearing:** `R/cpp.R:104-105` asserts *"this default
IS the old behaviour, because `f_luc_wood` = 1 is the incumbent decision"* while **`R/model.R:159` sets
`CCX_F_LUC_WOOD_DEFAULT <- 0`** — a comment claiming a default the code does not have, **in the block
whose stated purpose is stopping the R and C++ cores from silently running different models** ("which
is exactly what `gamma_enso` did"). Behaviour is correct; the comment misleads.

**ON JOOS, FRAMING CORRECTED (Marcus 2026-08-18).** The re-measurement was the *evidence* that the
failing numbers are right, and an earlier draft over-promoted it. On the **integrated** IRF the model
is **12.7 / 15.5 / 20.0 % low and inside all three 5–95 % bands** — for a box model tuned only to the
historical record, that is a **good result**. **The proposed "gate 12 needs a level check" item is
RETRACTED.** My pre-registered predictions were both WRONG and are recorded as such: the pump did
**not** move the integrated IRF (12.4 / 25.6 / 41.9 reproduced exactly — that status line is **not**
stale), and PD100 af(100) came in at **0.292**, below my predicted 0.33–0.36.

**⚠️ THE REPAIRS ARE NOT APPLIED, AND THAT IS DELIBERATE** — the standing rule is to report a failing
test rather than edit it into passing. `notes/diag_…` §5 specifies all five, including **"do not simply
lower 0.30"** and **"do not simply lower 0.2"**. They need Marcus's go-ahead.

### The original triage, retained

Named, not counted, from 16f §8:

| test | failure | 16f's triage |
|---|---|---|
| `test-pulse.R` | af(100) = 0.213 vs bar > 0.30 | *unbenchmarked* ballpark on a **declining** ssp119 background; the protocol-matched gate 12 **passes** (12.4 / 25.6 / 41.9 yr) |
| `test-luc-permanence.R` (×2) | the fossil reference arm; a case needing `f_luc_wood = 1` | — |
| `test-mechanisms.R` | ENSO 0.30 vs bar > 0.5 | — |

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && Rscript tests/run_tests.R 2>&1 | tail -60
```

**⚠️ THE WARNING THAT PRODUCED THE DIAGNOSIS ABOVE — keep it for the next such job.** 16f's own words are *"All four are plausibly stale
gates rather than physics failures — but nobody has diagnosed them, so that is an assessment, not a
verdict."* **Treat "plausibly stale" as the hypothesis to ATTACK, not the answer.** A stale-fixture
label has already hidden a real bug in this project for five handoffs (memory
`explained_away_test`), and the repair rule is **derive, never re-baseline**
(`stale_fixture_repair`): fix a bar by curvature, closed form, or measured residual — **never** by
moving it to where the code happens to land. Three of these four have a *number* and no derivation
behind it. Any bar that cannot be derived should be **deleted or explicitly marked unbenchmarked**,
not loosened.

**Also worth doing while there:** the suite has not been run since the merge, and `855 pass vs 802`
(16e) is the last count on record. Establish the current baseline first so "4 failures" is measured
rather than inherited.

---

## 7. Open decisions, in dependency order

1. **APPLY THE 4 TEST REPAIRS + the `R/cpp.R` comment fix.** §6 / `notes/diag_…` §5. Diagnosed and
   specified; **needs Marcus's go-ahead** because they edit tests. **Next.**
2. **Re-derive `ARM_HESS_EPS` at 20 parameters** rather than inheriting 3e-4 from an 18-parameter run.
   Both Hessians came back PD, so this is no longer urgent — but the adopted evidence contrast depends
   on it. (16g item 3, partially discharged: `recompute_hessian.R` was not needed.)
3. **σ-INFLATION: implement or not.** `notes/spec_2026-08-17_sigma_inflation.md`. **Marcus's call.**
   Its one missing input is the cost: **16g's "21 %, 2.14 of 10.01 log-units" was computed with
   alkalinity's `σ_rep` unavailable and MUST be re-derived over all three rows.** Needs the model;
   the machine is now free. Expect a small change (ALK's ratio is the smallest of the three) — but
   *expecting* small is not measuring it.
4. **THE PILOT MCMC**, and whether 16f §5.4's barrier is what has been breaking it. **The `h_ml`
   bound question RE-OPENS here** — a hard bound is defensible for a mode-find and is a **weaker
   claim for a sampler**. §2.2 removes much of the motivation for the bound (the pull was a freeze
   artefact), so a posterior run may not need it at all. **That is the single most consequential open
   question in the project.**
5. **`kz` pinned near its bracket top in both arms** (96.6 % / 88.9 %) — is this a blocker or does the
   bracket need re-deriving? It is also what makes the evidence "indicative". (carried, 16g item 8)
6. **DESIGN §5.4's products still do not exist** — no ~100-draw ensemble, no central parameter set.
   The app has nothing calibrated to run on.
7. Carried from 16c/16d/16f: **σ_Δ has NOT plateaued in block size**; **representation error still
   ZERO in the objective**; **point σ vs Student-t**; **does candidate A ship**.

**The critical path:** ~~`h_ml`~~ → ~~refit~~ → ~~N-vs-D~~ → **a pilot MCMC that actually converges**
→ ensemble → app. **The first three are now done.** Step 4 has no precedent on this model.

---

## 8. Non-obvious state, and cautions

- **TRUNK IS `main` NOW.** `luc-veg-debit` still exists and points at `e2c9238`; do not develop on it.
  Recovery ref for the merge is `0b7371c`.
- **`calibration/output/mode_fit.rds` IS STILL ABSENT, and this session did NOT create it.** The
  adopted mode is **`calibration/output/pump_arms/mode_fit_pumpN.rds`**. Do not conflate the paths —
  and note any handoff number sourced from `quarantine/20260815_pre_gradient_terms/mode_fit.rds`
  predates both the gradient terms and the pump.
- **THE BOUNDED OBJECTIVE IS A DIFFERENT FUNCTION.** 16g §4's `h_ml` ∈ [85, 120] bound was an
  **in-process override in the driver**; `R/calibrate.R` still carries [30, 200] and every diagnostic
  sees that. **Do not "fix" the apparent inconsistency by editing `R/calibrate.R`.** The refit's
  logpost is **not comparable** with any pre-2026-08-16 run's.
- **`ARM_TOL` = 1e-4 is effectively unreachable** for a 20-parameter Nelder-Mead here. Both arms
  ended on the restart cap. If a future run needs a converged flag rather than a plateau, that
  constant — not the restart count — is the thing to change.
- **One `conveyor 12C spinup did not converge` warning** during the run, |resid| = 1.79e-06.
- **Two traps for anyone writing a diagnostic here, both hit 2026-08-16g:**
  `ccx_par_to_unc(ccx_default_params())` **errors** (`bomb_total`, `luc_scale`, both sigmas and both
  gradient offsets have no field in `ccx_default_params()`; use `ccx_init_unc()`), and
  `ccx_loglik(by_stream = TRUE)` returns a **named numeric VECTOR, not a list**, so `[[missing_name]]`
  errors instead of returning NULL.
- **`tco2_alkpop` is NOT the shipped DIC row** — different bottle population, "reported for the ratio;
  NOT a term". Never quote it as one.
- **Name collision, unchanged:** `grad_off_co2` / `grad_off_d13c` in `err` are the **MLO−SPO
  ATMOSPHERIC** offsets. The ocean rows are `LIK_OCEAN_GRAD_*` / `ocean_grad_*`.

**Still do NOT:** hand-tune stream weights; delete `excess_c14_ocean` or `d14c_intcal`; free any land
turnover parameter; delete the `kz` bracket bare; build the conveyor; splice any pre-2026-08-15
posterior; **compare any logL across the 2026-08-16 boundary**; quote §4.2's ~384 log-units or its
1996.2555 baseline; **quote the SHIM's export figures or the "3.6×" POC ratio**; **quote 274.5 as
`pump_grad`'s value**; **quote 16g's 236 as the cost of the bound** (§2.2 retires it); **quote the
5.62 evidence as a Bayes factor** (§2.4).

---

## 9. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-18_refit_landed_n_adopted_merged.md`. **The refit LANDED**: §5.3 took
> the good branch (`co2_level_SPO` −256 → −63), **`h_ml` went INTERIOR in both arms (94.4 / 91.2)** so
> 16g's 236-log-unit pull was a freeze artefact, and **arm N is ADOPTED PROVISIONALLY** (evidence
> +5.62, but *indicative, not a Bayes factor* — `kz` pinned, both arms capped, 0.7 noise floor).
> `luc-veg-debit` is **merged; trunk is `main`**. **Job B is DONE**: all 4 test failures diagnosed and
> **none is a code bug** — three mis-specified bars, one stale premise needing `f_luc_wood = 1` as well
> as `f_luc_perm = 0` (§6). **First job: apply the 5 repairs**, which were deliberately NOT applied
> because they edit tests — `notes/diag_2026-08-18_test_failures.md` §5 specifies each, and "do not
> simply lower the bar" is written into two of them.
