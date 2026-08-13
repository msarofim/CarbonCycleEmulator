# Handoff — CarbonCycleEmulator, 2026-08-12 (d)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`.
Supersedes `handoff_2026-08-12c_four_pool_land.md`. Its §4 is **resolved** (§2), its §7 γ_L
caveat is **checked and the recollection was wrong** (§3), its §9(h) production line is
**re-framed** (§4), and its §9(a)/(b)/(c) are **done** (§5, §6).

**Branch.** `luc-veg-debit` = `0b5bb41`, **still NOT merged**. Suite **388 pass / 4 fail /
2 skip** — the same four failures as 12c, plus 10 new passing guard assertions (§9).

**A 16-parameter mode exists and is CONVERGED**, at `calibration/output/mode_fit.rds`.
**Do not use it.** It is flagged `q10 = 0.169` (§7).

---

## 0. START HERE — the first three steps, in this order

The model has now had **two rounds of parameter-freezing, and each one relocated the
pathology rather than removing it** (§7). That pattern is the reason for the ordering below:
steps 1 and 2 are about removing the fit's ability to *choose its own targets*, and only then
does constraining `q10` mean anything. Doing step 3 first would move the mole a third time.

### Step 1 — fix the three σ's instead of calibrating them

`sigma_co2`, `sigma_d13c`, `sigma_d14c` are currently free. The mode uses that freedom to
**re-weight which data it believes**:

| | table init | at the mode | prior-tail |
|---|---|---|---|
| `sigma_co2` | 1.5 ppm | **0.301** (5× tighter) | −2.13 σ |
| `sigma_d13c` | 0.1 ‰ | **0.440** (4.4× looser) | +2.20 σ |
| `sigma_d14c` | 5 ‰ | 5.748 | +0.38 σ |

CO₂ errors are declared tiny and δ¹³C errors large — and **δ¹³C is the constraint DESIGN.md
added specifically to separate the land and ocean sinks**. The fit is loosening the one term
that would discipline the land sink, then absorbing the rest into an unphysical `q10`.
Removing this freedom is the cheapest test of whether the `q10` pathology is driven by
re-weighting or by real structure.

> **METHODOLOGICAL CHOICE — needs Marcus, do not silently resolve.** *Fixing* them is agreed;
> **what to fix them AT is not.** These are model–data mismatch scales, not pure measurement
> error, so there is no purely observational answer. Two defensible options: the **prior
> medians** (1.5 / 0.1 / 5), which is the "declared up front" choice; or values reflecting
> honest mismatch for each series. Note the gap is large — `sigma_co2` 1.5 vs the mode's 0.301
> will change the fit substantially. Get the call before editing `CCX_PARAM_TABLE`.

Mechanics: delete the three entries from `CCX_PARAM_TABLE` (that is all it takes — see §10),
and put the chosen values in `ccx_default_params()`. **16 → 13 parameters.**

### Step 2 — replace the `kz` bound with a deep-Δ¹⁴C likelihood term

**The `kz` bound added in `0b5bb41` LEAKS, and the leak is understood** (§8). Bounding a
*parameter* as a proxy for an *observable* is the mistake. Deep-ocean Δ¹⁴C is observed
(−150 to −200 ‰) and the spinup already computes it as
`ccx_spinup(p)$diagnostics$d14c_deep_ocean` — so it belongs in `ccx_loglik()` as a soft
constraint, where it stays valid no matter what the other parameters do.

Once the term is in, **relax `kz` back to an unbounded (or generously bounded) `log`
transform** — the likelihood, not the transform, should be holding the deep age. Keep the
bound only as a backstop if you want belt and braces; do not keep it as the primary mechanism.

The pattern to copy is `excess_c14_ocean` in `ccx_loglik()`, which is the existing example of
scoring a spinup-derived inventory against Naegler & Levin.

### Step 3 — bound `q10` to physical values, **if still needed**

`q10 < 1` means respiration *falls* as the world warms, and the current mode sits at
**0.169**. That is indefensible in a model whose job is communication. Bound it to a physical
range (`[1, 4]` is the obvious span) via the same `logit` treatment `beta`/`h_ml` already use.

**But do this last, and check first whether steps 1–2 already fixed it.** If `q10` comes back
physical once the σ's are fixed, the bound is unnecessary and the pathology was re-weighting.
If it still rails against 1, that is a **structural** finding worth recording — it says the
model cannot produce the observed sink partition with physical parameters, and that is a real
result about the model, not a nuisance to clamp.

After each step: re-run `Rscript calibration/run_modefind.R` (≈4 h, §10) and
`Rscript calibration/diag_bomb_partition.R`. **Quarantine the previous mode first** (§10).

---

## 1. What this session actually settled

Three things closed, two decisions taken, one new problem found. In order of durability:

| | result |
|---|---|
| §2 | The atmospheric ¹⁴C **framing question is resolved** — it was neither A nor B, and the budget closes |
| §3 | **Arora γ_L recollection was wrong**; the four-pool land is not an outlier |
| §4 | The **¹⁴C "production shortfall" is arithmetic**, not a defect |
| §5 | **Decision 1**: the land layout is structure, not calibrated |
| §6 | **Decision 2**: `kz` bounded on deep-ocean age — *implemented, and it leaks* (§8) |
| §7 | **NEW**: `q10` inverts, and the whack-a-mole pattern is the real finding |

---

## 2. The framing question — RESOLVED, and it was a third option

12c §4 left this as A-vs-B with "report both, score on neither" as the likely answer. That was
the wrong resolution: **there is a third framing that is like-for-like and computable.**

`R/model.R`'s atmosphere is one box carrying `GtC_PER_PPM` = **whole-atmosphere** carbon, but
`likelihood.R` fits its Δ¹⁴C to `obs_d14c_zonal` = **surface** stations. Its inventory is
whole-atmosphere **mass** at a tropospheric **ratio**. So A (vs troposphere) is wrong by the
entire stratospheric mass, B (vs trop+strat) credits an enrichment a well-mixed box cannot
carry, and **C — N&L's troposphere scaled to whole-atmosphere mass — is the score.**

The scale factor is read from **N&L's own model**: their Figure 2 puts the GRACE tropopause at
**9 km poleward of 30°, 15 km equatorward** (= "22 boxes, six troposphere, 16 stratosphere",
six latitude bands). US Standard Atmosphere ⇒ troposphere = **78.8 %** of atmospheric mass,
strat/trop mass ratio **0.2686**. Computed from named constants in `diag_bomb_partition.R`.

**The check that confirms it:** N&L's own strat/trop ¹⁴C ratio falls 0.321 (1975) → **0.269**
(1995), landing on the derived mass ratio **0.2686** to three decimals. Their stratosphere
carries exactly its mass share by 1995, so **B and C coincide at 1995** and differ only at the
spike.

Result at defaults **(kz 4000 — see the trap in §10)**: SUM **−0.7 % / +0.7 %**.
**The budget closes.** The "+6–7 % delivery error" that sent two handoffs after the bomb
source shape **does not exist**; `data-raw/build_bomb_c14_source.R` does not need reopening on
those grounds. The residual is **atmosphere short / ocean long ⇒ ventilation**.

---

## 3. γ_L against C4MIP — the recollection was wrong by 2.5× on the spread

12c §7 flagged "γ_L ≈ −20 is at the low edge of CMIP6" as resting on an unverified recollection
of "~−34 ± 20 GtC/K, Arora et al. 2020". Checked against two sources quoting the abstract
verbatim ([Biogeosciences 17:4173](https://bg.copernicus.org/articles/17/4173/2020/),
[OSTI 1695755](https://www.osti.gov/pages/biblio/1695755)):

> γ_L = **−45.1 ± 50.6 PgC °C⁻¹**, γ_O = −17.2 ± 5.0 (11 CMIP6 models, 1pctCO2→4×CO₂, BGC−COU)

| | γ_L | from the CMIP6 mean |
|---|---|---|
| two-pool land | −57.6 GtC/K | −0.25 σ |
| four-pool land | −19.6 GtC/K | **+0.50 σ** |

**Both inside 1 σ.** "At the low edge" was an artefact of a spread misremembered by 2.5×.
CMIP6 does not constrain γ_L tightly enough to call the four-pool land a regression *or* a
correction. **Consequence: temperature-dependent NPP (12c §9(i)) loses its motivation** — still
a real structural gap, but a modelling choice, not a defect. *Caveat:* Arora's protocol is
4×CO₂/BGC−COU; ours is q10-on/off on coupled SSP5-8.5. Not protocol-matched; do not present it
as such.

---

## 4. `prod_c14` is a READOUT — the "shortfall" mis-frames a diagnostic

12c §9(h) carried "production **359** vs ~545 mol/yr — got *worse* with the new land, 382 → 359,
and is unexplained". Measured at the 1750 steady state:

```
total 14C inventory   2955 kmol
implied decay         359.3 mol/yr
model prod_c14        359.3 mol/yr
balance (decay/prod)  1.0000
```

**The model conserves ¹⁴C exactly.** `ccx_spinup()` solves for the production that balances
decay, so `prod_c14` is a readout of **carbon inventory × mean Δ¹⁴C**, not an independent
quantity that can be short. And **382 → 359 was the fix working** — the four-pool land holds
less ¹⁴C, so the inventory it must sustain is smaller. Reporting that as "worse" inverted it.

A realistic ~38,000 GtC ocean would give **~410 mol/yr**, closing about a third. Reaching 535
needs **~52,900 GtC, ~1.3× the real world** — not absorbable by fixing the ocean.

**NOT closed.** The 545 figure is 2.04 atoms cm⁻² s⁻¹ and published production estimates span
~1.6–2.5 (≈430–670 mol/yr). **Its provenance has not been verified** — that check is what
would settle whether anything remains to explain. Related: **uniform DIC with depth is
EXPECTED** for a pump-less diffusion ocean; it is the signature of the missing biological pump
(also why the inventory is ~16 % low), which is a **different** gap from the missing advection.

---

## 5. Decision 1 — the land layout is STRUCTURE (Marcus 2026-08-12)

`tau_soil_fast` is removed from `CCX_PARAM_TABLE`. The land now has **zero calibrated degrees
of freedom**; it keeps its values from `ccx_default_params()`.

**Why it was forced.** The 17-parameter mode drove `tau_soil_fast` to **11.16 yr (+3.61 σ)** —
caught by `run_modefind.R`'s own screen — and put the biosphere bomb-¹⁴C back to **+50 % /
+64 %**, i.e. all the way back to the two-pool land's original defect. `diag_land_topology.R`
[4] had already measured the bound ("at 10 yr the 1975 inventory is +56 %").

**Why it escaped:** N&L's biosphere row has **no observational estimate**, so there is no
¹⁴C-partition term in the likelihood. Nothing scores the thing the four-pool land was built to
fix. The old comment in `calibrate.R` had *predicted* this — it froze the other five land
parameters for exactly this reason — but left one DOF open, and one was enough.

**It worked:** biosphere at 1975 went **+50 % → −14 %** under the freeze.

---

## 6. Decision 2 — `kz` bounded on the deep-ocean age (Marcus 2026-08-12)

Unbounded, `kz` ran to **10,686**, putting the deep ocean at **−129.9 ‰** against an observed
−150 to −200. One diffusivity serves both the decadal bomb penetration and the millennial deep
age; unbounded, the bomb window wins. The deep age is the more teachable quantity, so `kz` was
bounded to the range that keeps it in the observed bracket, and the bomb window absorbs the
cost.

Bisected **at default parameters**: kz 3828.8 → −200.00 ‰, kz 5000 → −170.1, kz 6200.7 →
−150.00. Rounded inward to **[3830, 6200]**, `init` 5000. `ccx_default_params()$kz` re-centred
**4000 → 5000** to track the table init (the β precedent).

**This is implemented and it LEAKS. See §8 before relying on it.**

---

## 7. NEW AND CENTRAL — `q10` inverts, and the pattern is the finding

The 16-parameter refit is **converged** (gains 0.08–0.32 at the end; BFGS polish gained only
**0.41**, against 9.74 last time — raising `MODE_RESTARTS` 12 → 20 did its job). And its screen
flags:

```
*** FLAGGED, needs an explanation before this mode is used:  q10
q10 = 0.1686        (-7.03 sigma)
```

**q10 < 1 means respiration FALLS as the world warms** — the land gains carbon *because* of
warming. `run_modefind.R`'s own header records this exact failure from 2026-08-10 ("q10 = 0.28
means respiration FALLS with warming"). This is that pathology, deeper, against a tight
physical prior centred on 2.0.

It does not stand alone. Read the mode together:

| | value | prior-tail | reading |
|---|---|---|---|
| `q10` | 0.1686 | **−7.03 σ** | warming *increases* land uptake |
| `beta` | 0.0877 | −1.57 σ | CO₂ fertilisation nearly off |
| `sigma_co2` | 0.301 | −2.13 σ | CO₂ errors declared tiny |
| `sigma_d13c` | 0.440 | +2.20 σ | δ¹³C errors declared large |

**The fit nails CO₂, discards δ¹³C, and manufactures the land sink out of warming.**

### The whack-a-mole pattern — read this before constraining anything else

- 17 parameters → `tau_soil_fast` to **+3.61 σ**, partition destroyed.
- Freeze it → 16 parameters → `q10` to **−7.03 σ**, physics inverted.

**Two rounds, two relocations.** This is the signature of a **structural misfit being absorbed
by whichever parameter is still free**, not of individually badly-behaved parameters. It is why
§0 puts the σ's first: they are the mechanism by which the fit chooses what to be wrong about.
If `q10` still rails after steps 1–2, that is a **result** — record it, do not clamp it and
move on.

### A prediction that FAILED, recorded because it did

I predicted freezing the land would pull `bomb_total` down from +2.19 σ. **It went up**:
109.7 → **111.3 (+2.31 σ)**. The land freeze did not relieve the bomb-¹⁴C magnitude pressure.

---

## 8. The `kz` bound leaks — how, and why the fix is a likelihood term

I validated the kz→deep-Δ¹⁴C mapping against `h_ml`, found it moved <1.5 ‰ across h_ml
39.7–100, and called it "essentially univariate". **`h_ml` was the wrong thing to test.** The
mapping is robust to `h_ml` — and **shifts bodily when the other parameters move**:

| kz | at default params | at the 16-par mode |
|---|---|---|
| 6200 (the `hi` bound) | −150.0 ‰ | **−144.7 ‰** |
| 6031 (where the mode sat) | — | **−145.0 ‰** |

Measured at the mode, across the full `h_ml` range (rows kz, columns h_ml):

```
      kz   h_ml=75  h_ml=100  h_ml=140  h_ml=178  h_ml=200
    3830    -195.2    -194.5    -193.4    -192.3    -191.7
    5000    -165.0    -164.4    -163.5    -162.6    -162.1
    6031    -147.1    -146.6    -145.8    -145.0    -144.6
    6200    -144.7    -144.2    -143.4    -142.7    -142.2
```

`h_ml` moves it 3–4 ‰ across 75→200; the *parameter vector* moved it ~5 ‰ at fixed kz
(`k_w` went 1500 → 1697, and the land changed underneath it). So **`kz` sat obediently inside
its bound and the deep ocean still came out at −145.0 ‰, outside the bracket.**

**The lesson generalises: do not bound a parameter as a proxy for an observable.** Deep Δ¹⁴C is
observed; constrain it where observations live. Hence §0 step 2.

---

## 9. Test suite — 388 pass / 4 fail / 2 skip

The four failures are **the same set as 12c**; none is new.

| test | cause | status |
|---|---|---|
| `test-climate.R:122` | γ_L structural | 0.0924 vs bound 0.1 (was 0.091) |
| `test-likelihood.R:114` | stale fixture | `cost(1) = −178.3` (was −89.9 — moved by the kz default 4000→5000, not a new break) |
| `test-likelihood.R:117` | stale fixture | same fixture, monotonicity |
| `test-mechanisms.R:32` | `gamma_enso` pinned by the test | 0.28 vs bound 0.5 |

**One test was MODIFIED, deliberately, and you should know:** `test-likelihood.R`'s
`expect_length(CCX_PARAM_NAMES, 17L)` → `16L`. That is a spec assertion changed by decision,
not a masked regression. It was also **rewritten to guard both decisions** rather than record a
count: it now asserts every land-layout parameter is absent from `CCX_PARAM_TABLE`, and that
`kz$tr` is still `"logit"` with the bisected bounds — a silent revert to `tr = "log"` would
restore the runaway with no other visible symptom. **Step 1 will need the `16L` updated to
`13L`, and step 2 will need the `kz` assertions revisited** (they should become an assertion
that the deep-Δ¹⁴C likelihood term is present).

---

## 10. Non-obvious state

- **THE DEFAULTS MOVED.** `ccx_default_params()$kz` is **5000**, not 4000, since `0b5bb41`.
  **Every default-parameter ¹⁴C number written before 2026-08-12 evening is at kz 4000** —
  including §2's `−0.7 % / +0.7 %` and §4's `359.3 mol/yr`. Re-measure before quoting; do not
  assume they carry over.
- **`CCX_PARAM_NAMES <- names(CCX_PARAM_TABLE)`**, and `ccx_make_logpost()` does
  `for (n in intersect(names(p), CCX_PARAM_NAMES))`. So **freezing a parameter is a table
  deletion** — nothing else needs to change, and the value falls back to
  `ccx_default_params()`. This is what makes step 1 a three-line edit.
- **`beta` is `logit` on [0, 1.5], NOT `log`.** Going through `log()` scans
  `plogis(log(beta)) * 1.5` and returns a plausible wrong answer. **`kz` is now `logit` too**
  — same trap. Always go through `.to_unc(v, CCX_PARAM_TABLE$<n>)` and assert the round-trip;
  this was done for `kz` (`3830 → −21.5987 → 3830`, error 0).
- **Runtime:** the 16-parameter mode-find took **237 min** (237,318 evals, 0.060 s/eval) and ran
  all 20 restarts. `MODE_RESTARTS` was raised 12 → 20 because the 17-par run hit the cap of 12
  while still gaining 1.3–1.8 per restart. Budget ~4 h per refit; each of §0's steps needs one.
- **Quarantine before every refit.** The 17-par mode is at
  `calibration/output/quarantine/20260812b_free_tau_soil_fast_unbounded_kz/` with a README.
  **Its `logpost −2293.5` must NOT be quoted** — different parameter set *and* not converged.
  **`−2386.6` (16-par) is likewise NOT comparable to it**, and will not be comparable to
  step 1's 13-parameter mode either. Log-posteriors compare only within a fixed parameter set.
- The older quarantine dirs still apply as 12c described; `20260811b_pre_excess_c14/` remains
  the dangerous one because it *looks* current.
- **`profile_kz_ventilation.R` is 2/7 complete**, on the superseded two-pool land, hard-gated on
  `mode_fit.rds` at line 51, and its `PROF_KZ_GRID` is centred on the *old* mode's kz = 8354.
  It needs re-centring before it is worth the ~2.5 h. Two cautions: the bomb-window RMS is
  **non-monotonic** in kz (42.1 at 500, 46.3 at 1000), and the profile is a **conditional
  maximum, not a marginal**.
- **The ocean is pure diffusion.** `R/model.R` interior transport is `add_diffusion` and nothing
  else — no advective or overturning term. `tau_ex` is interhemispheric *atmospheric* exchange.
  DESIGN.md §2 rejected HILDA as "too many parameters to communicate"; that judgment stands for
  this audience and nothing found today overturns it.
- **This is a COMMUNICATIONS model** (audience: undergrad environmental-studies major, per
  DESIGN.md). That is the tie-breaker behind both decisions and behind §0: citable, explicable
  parameter values beat posterior optimality, and fewer free parameters beat better sampling.
  Items deliberately **dropped** on that basis: stratospheric box + bomb-source rebuild, ocean
  carbon inventory / biological pump, temperature-dependent NPP, ocean advection.
- Everything else from 12c §10 still applies: `R/cpp.R` errors on a pre-four-pool parameter
  list, `aux$veg0` must keep matching `ccx_spinup()`, `CCX_LAND_POOLS` is structural
  (`NPH = 16`, `IML = 5`), `ccx_build_forcing()`'s prescribed GMST is the FLAT path (use
  `ccx_run_coupled`), `LIK_EXCESS_C14_REP_FRAC = 0.15` still undecided, and manual CSVs need
  `read.csv(comment.char = "#")`.

---

## 11. Commits

| | |
|---|---|
| `de76c41` | Settle the ¹⁴C atmospheric framing: neither A nor B, and the budget closes |
| `80c8be3` | CHANGELOG: the ¹⁴C production "shortfall" is arithmetic, not a defect |
| `0b5bb41` | Freeze the land layout, bound kz on deep-ocean age (17 → 16 parameters) |

---

## 12. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-12d_frozen_land_bounded_kz.md`, on branch `luc-veg-debit`.
> Follow §0 in order: fix the three σ's (get Marcus' call on the VALUES first), replace the kz
> bound with a deep-Δ¹⁴C likelihood term, then bound q10 only if it is still needed. Read §7
> before constraining anything — two rounds of freezing have already relocated the pathology
> twice, and the point of the ordering is to stop doing that.
