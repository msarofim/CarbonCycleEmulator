# Handoff — CarbonCycleEmulator, 2026-08-12 (c)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`.
Supersedes `handoff_2026-08-12b_partition_and_land_structure.md`. Its §7 step 1 was **wrong**
(§3), its §7 step 2 (φ) is **closed by the restructure, not by a decision** (§5), and its §7
step 3 is **done** (§6).

**Branch.** `luc-veg-debit` = `85ef079`, **still NOT merged**. Suite **380 pass / 4 fail /
2 skip** — same count as before, **different set** (§8).

---

## 0. START HERE — do not pick up a task, recommend one

**The first thing this session should do is read §1–§9, then come back to Marcus with a
recommended ordering of next steps and wait.** There is no queue to work through. Two things
make that the right opening move rather than boilerplate:

1. **A mode-find was running when this was written and its result is not in here.** It changes
   what is worth doing. Check `calibration/output/modefind.log` first (§2) — several of the
   items below are conditional on it.
2. **§4 is an open finding that may invalidate the framing of the model's headline ¹⁴C
   diagnostic.** It is cheap to settle and it changes what the remaining defect *is*. Almost
   nothing downstream should be started before it is decided, and it is Marcus' call, not a
   session's.

Read §9 for the candidate list, with what each is worth and what it depends on. **Bring a
recommendation, not a plan already executed.**

---

## 1. Where the model got to

The bomb-¹⁴C reservoir **partition error is closed** — this was the session's main result. It
had been the model's largest structural defect: a biosphere 51–58 % above Naegler & Levin and a
troposphere 40–44 % below, in the same direction at two reference years twenty years apart.
Fixed by replacing the two-pool land with a four-pool one. §3 and §5 are how; §7 is what it cost.

---

## 2. The mode-find — check this before anything else

Launched in the background at the end of the session, against the four-pool land + LUC debit.
17 parameters, `tau_soil_fast` in place of `tau_soil`. Progress when this was written:

```
start:      log-post at hand-set init = -4530.7
restart  1: -2388.8  (gain 2141.9)  evals 11718
restart  2: -2331.2  (gain   57.6)  evals 30156
```

`MODE_RESTARTS = 12`, `MODE_TOL = 1e-4`, so it stops early on convergence. **It had not
finished.** If the process is gone and `calibration/output/mode_fit.rds` exists, it completed;
if the file is absent, it was killed and must be re-run.

**Do not compare `-2331.2` to any earlier mode.** The quarantined `-2374.1` and `-2359.3` were
maximized by different likelihoods on a different model. They are not comparable and saying so
is the point of the quarantine README.

When it has converged:

- **Re-run `diag_bomb_partition.R`.** It falls back to `ccx_default_params()` and prints
  `NO mode fit found`; with the file present it picks the mode up automatically. **Every ¹⁴C
  number in this handoff is at DEFAULTS** and will move.
- **Re-check the two likelihood fixtures at the mode** (§8). If they pass there, they were
  exactly the stale fixture the previous handoff called them. If they do not, that is new.
- **Re-measure the deep ocean.** At defaults it is **−194.7 ‰**, inside the observed −150 to
  −200 bracket. Handoff-b quoted −105 ‰ **at the old mode fit** — the two are *not* comparable,
  and nobody should conclude the deep ocean was fixed by the land until it is re-measured at the
  new mode. This is a live trap: it looks like a win and may be a parameter difference.

---

## 3. What was built, and the method that mattered more than the result

The previous handoff prescribed: *"split the single responsive soil pool into fast and slow."*
**That cannot work.** A soil-only split tops out at **30.0 / 19.5 kmol on 2214 GtC** against
N&L's 21.7 / 18.9 on 2200 — 1995 right, **1975 38 % high** — because a single 600 GtC vegetation
pool at `tau_veg` 10 **already holds ~20 kmol at 1975**, essentially N&L's whole biosphere. No
soil layout underneath it can help. **The vegetation had to be split too.**

**That was found before the rebuild, not after**, by `calibration/diag_land_topology.R`: the
land's bomb-¹⁴C uptake is **linear** once the carbon fluxes are fixed, so a candidate topology's
inventory integrates straight from an atmospheric Δ¹⁴C history — ~1 ms per candidate, no core
rebuild — instead of restructuring 32 boxes once per idea. Building the prescribed version first
would have meant doing the restructure twice. The generalizable form is in memory as
`feedback_offline_emulator_before_restructure`.

Four sections:

- **[1] validates the emulator against the full model** on the **live** parameters (derived from
  `ccx_default_params()`, not restated, so it cannot go stale). −0.9 % / −0.6 % on the four-pool
  land; −6.5 % / −3.1 % on the two-pool one. Gated at `TOPO_VALID_TOL`; the script **exits** if
  it fails.
- **[2] the scan**, under **two** drivers. Read the **OBSERVED**-atmosphere block as the design
  target: the model's troposphere was short *because* its land took too much, so designing
  against the model's own depressed atmosphere would understate how inert the land must be.
- **[3] the refinement surface — it is FLAT.** 0.60/30/0.04 and 0.70/40/0.04 both sit near 6 %
  RMS. That is what licenses calling the defaults a defensible center. **Four knobs against
  three targets would fit anything; do not present these as fitted values.**
- **[4] what the fix cost** — §7.

**The structure.** `leaf` (60 % of NPP, τ 1 yr) and `wood` (τ 20 yr) fed by NPP; litter split
95/5 into `soil_fast` (τ 2 yr) and `soil_slow` (τ 500 yr). **NB 28 → 32.** Vegetation 516 GtC,
responsive soil 114, passive 1500, total 2130.

| routing choice | |
|---|---|
| capacity (φ) keys on | `leaf + wood`, against the same total at spinup |
| Ra loop | per vegetation pool, at each pool's own ratio |
| litter split | **per source pool** — the two carry different ¹⁴C ratios, and pooling first would average them |
| seasonal NEP | through `leaf` |
| ENSO | out of `soil_fast` |
| **LUC** | **debits `wood`** (Marcus 2026-08-12) |

**The result**, paired bomb-only at `bomb_total` 102, vs N&L Table 4:

| | before (2-pool, old mode) | after (4-pool, defaults) | N&L |
|---|---|---|---|
| biosphere 1975 | 32.80 (+51 %) | **21.73 (+0 %)** | 21.70 |
| biosphere 1995 | 29.88 (+58 %) | **20.83 (+10 %)** | 18.90 |
| troposphere 1975 | 16.13 (−40 %) | 31.34 (+17 %) | 26.80 |
| troposphere 1995 | 9.82 (−44 %) | 15.91 (−9 %) | 17.50 |

(Before-column at the old mode, after at defaults; at defaults the two-pool land gave 39.74, so
the structural effect dwarfs any parameter effect.) **The four-pool land is NOT calibrated.**

---

## 4. OPEN AND CONSEQUENTIAL — the comparison framing may be wrong

`calibration/diag_stratosphere.R`, written to answer "would a stratospheric layer help?", turned
up something bigger on the way. **This needs deciding before the ocean work, and it is Marcus'
call.**

`diag_bomb_partition.R` compares the model's atmosphere box to N&L's **troposphere alone**, and
removes their stratosphere from their **total** as well. The stated reason is that the bomb
source is a delivery *rate to the troposphere*, so the stratospheric delay is already inside it.

**That argument is about TIMING. It says nothing about MASS.** The box carries
`GtC_PER_PPM = 2.124` — the **whole atmosphere** — while `likelihood.R` fits its Δ¹⁴C to
`obs_d14c_zonal`, which is **surface stations**, i.e. tropospheric. Its excess-¹⁴C *inventory*
is therefore whole-atmosphere mass × tropospheric Δ¹⁴C, and the like-for-like target is
troposphere **plus** stratosphere.

| | A (current) | B (proposed) |
|---|---|---|
| atmosphere 1975 | 31.34 vs 26.80 = **+16.9 %** | 31.34 vs 35.40 = **−11.5 %** |
| atmosphere 1995 | 15.91 vs 17.50 = −9.1 % | 15.91 vs 22.20 = **−28.3 %** |
| SUM 1975 | vs total−strat = **+7.2 %** | vs total_input = **−2.1 %** |
| SUM 1995 | vs total−strat = **+5.6 %** | vs total_input = **+0.7 %** |

**Under B the budget closes.** The SUM error collapses to the model's own input excess over N&L
(+2.8 % / +0.9 %, since the model runs at 102 kmol against their decay-corrected 99.2 / 101.1).
That is what a model which conserves ¹⁴C and is given a prescribed input **must** do — a
"+6–7 % delivery error" was never physically sensible for one, and its apparent existence is
what has been sending sessions after the bomb source shape.

**If B is right, the entire remaining ¹⁴C residual is a different defect**: atmosphere **short**
(−11 % / −28 %), ocean **long** (+4.7 % / +8.6 %), biosphere fine (+0.1 % / +9.6 %). Too much
bomb ¹⁴C is going into the ocean. That is a ventilation problem, and it makes §9's ocean item
the live one rather than anything to do with the source.

**I am not certain B is right and did not change the diagnostic.** The case against it: N&L's
stratosphere was genuinely more enriched than their troposphere during the spike (their ratio is
0.321 at 1975 against 0.269 at 1995), so "whole-atmosphere mass × tropospheric Δ¹⁴C" understates
the real atmosphere at 1975 — B is a slight over-correction there and an under-correction later.
The honest resolution is probably to report **both** framings and stop treating either as the
score. Decide it deliberately; it has already misdirected two handoffs.

---

## 5. Would a stratospheric layer help? — measured, and the answer is nuanced

`calibration/diag_stratosphere.R` [2] tests the obvious hypothesis: a stratosphere as a
**delay**. A one-way reservoir of residence τ convolves the source with an exponential; if one τ
reconciles the delivered sum at both years, a stratospheric box fixes it.

**It does not.** The 1995 column barely moves at any τ (+5.6 % at τ = 0.5 through 3, +5.2 % at
τ = 5), because the source is over by 1980 and a one-way reservoir has emptied fifteen years
later. τ ≈ 3 fixes 1975 exactly (+0.3 %) and does nothing for 1995; τ ≈ 5 overshoots 1975 to
−8.7 % and still does nothing for 1995.

**And N&L's stratosphere is not a delay line either.** Holding 4.7 kmol in 1995 from 8.6 kmol in
1975 requires τ ≈ **33 yr**; observed stratosphere–troposphere exchange is ~1–2 yr. Their
stratosphere/troposphere ratio *falls* 0.321 → 0.269, relaxing toward a **mass** ratio. It is a
**co-equilibrating reservoir carrying its share of the excess**, not a reservoir holding it back.

**So: yes, worth doing — but for a different reason than the one that motivates it.**
The model has to satisfy **tropospheric** Δ¹⁴C observations using a box holding
**whole-atmosphere** carbon. During the spike, when the real stratosphere was far more enriched
than the troposphere, it therefore *cannot* hold the atmosphere's true ¹⁴C inventory, and the
surplus is pushed into the ocean. Splitting the box lets the troposphere match observations while
the stratosphere holds the enriched remainder. **That mechanism predicts exactly §4's signature:
atmosphere short, ocean long.** It is the same defect from the other side, which is encouraging —
but note that §4 must be settled first, because under framing A the signature does not exist.

**What a stratosphere would NOT touch:** γ_L (§7); the ocean carbon inventory; and the natural
¹⁴C production ratio — it adds well under 1 % of system ¹⁴C inventory against a ~34 % shortfall.

**Cost:** NB 32 → 34, **and the bomb source must be rebuilt as an injection rate rather than a
delivery rate**, or the stratospheric delay is double-counted. That rebuild is
`data-raw/build_bomb_c14_source.R`, which is also where the Part A/Part B join lives. It is a
package, not a box.

---

## 6. φ closed itself, and β was re-centered

**φ.** `test-pulse.R:112/113` — the Joos airborne-fraction benchmark that φ = 0.5 broke — **now
pass unmodified**. `diag_land_structure.R` [1] shows why: φ's effect **flipped sign**. Under the
two-pool land, raising φ grew the vegetation pool and drew CO₂ *down* (413.7 → 322.2 ppm across
the grid) — the capacity term was mostly amplifying CO₂ fertilization, more veg → more NPP →
more veg, and that positive loop over-drained the pulse. Under the four-pool land CO₂ **rises**
with φ (426.8 → 476.8) and land carbon **falls** (1.015 → 0.916 of its 1750 value), because LUC
debits **wood** and wood is most of the vegetation — so φ now costs capacity when land is
cleared, which is the job it was added to do. **No clamp needed; φ stays 0.5.** Still not
bounded: every value to 1.10 (φ·f = 1.28) is stable.

**β** re-centered 0.40 → **0.38**, in `ccx_default_params()` **and** the `CCX_PARAM_TABLE` init,
which must track it. Set by the **1-D optimum of the real log-posterior** with every other
parameter at its table init (−4560.2 → −4530.6); the CO₂-at-2020 route agrees independently.
Much smaller than handoff-b's expected 0.25–0.30, because that estimate was for the LUC debit
against the **two-pool** land.

> **A real trap.** `beta` is **logit**-transformed on [0, 1.5], **not log**. A first pass at that
> profile set the unconstrained value to `log(beta)` and therefore scanned
> `plogis(log(beta)) * 1.5` — it looked entirely plausible and returned 0.34. Go through
> `.to_unc(v, CCX_PARAM_TABLE$beta)` and assert the round-trip.

`app/global.R` no longer claims the model "reads about 27 ppm high" — wrong in **sign** as well
as magnitude, written once and never re-derived. Replaced with text stating **no** computed
quantity, rather than a freshly-hardcoded number that would decay the same way.

---

## 7. What the land fix cost — the session's other durable result

**The bomb ¹⁴C bounds the soil-respiration carbon-climate feedback from above.**

γ_L fell **−57.6 → −19.6 GtC/K** (land carbon at 2100, q10 = 2 vs q10 = 1, coupled SSP5-8.5,
over GMST at 2100 — measured in **both** models, the two-pool one via a worktree at `818fe93`).

Mechanism, one number: only soil respires with q10, and a q10 anomaly can only move carbon a
pool can release on the horizon in question. **Responding carbon**, Σ C_j (1 − e^(−100/τ_j)),
fell ~1470 → ~390 GtC. Factor 3.8 against factor 2.9 in γ_L — the metric explains the loss.

**An intermediate soil pool (τ 30–100 yr) does not rescue it** (`diag_land_topology.R` [4], soil
stock held fixed): ~**+0.7 kmol at 1975 per +100 GtC of responding carbon**, ≈3 % of the target.
Doubling responding carbon to ~730 still leaves it at half the two-pool value while pushing 1975
from exact to +13 %. `tau_soil_fast` is bounded the same way: at 5 yr the 1975 inventory is
+27 %, at 10 yr +56 %.

**The escape this model does not have.** Its only carbon-climate feedback is q10 on heterotrophic
respiration. Real land models draw much of γ_L from productivity decline and disturbance — a
**temperature dependence of NPP**, which this model lacks entirely. Not implemented; recorded as
the recommendation.

> γ_L ≈ −20 being "at the low edge" rests on my **recollection** of CMIP6 C4MIP (~−34 ± 20
> GtC/K, Arora et al. 2020). **Not verified against the paper.** Worth ten minutes before anyone
> quotes it — and it decides whether §7 is a regression or a correction.

---

## 8. The four red tests — a DIFFERENT set from handoff-b. Do not "fix" them blind.

| test | cause | status |
|---|---|---|
| `test-climate.R:122` | **NEW** — γ_L, §7 | feedback 0.091 °C, bound 0.1. **Structural.** Not absorbable: q10 would have to reach ~4–5. |
| `test-mechanisms.R:32` | **NEW** — small `soil_fast` | ENSO switch moves CO₂ 0.29 ppm, bound 0.5. **Absorbable** — `gamma_enso` is calibrated (prior N(0,2)); the test pins it at 0.5. |
| `test-likelihood.R:114` | stale fixture | `cost(1) = −89.9` (was −139.2). Improved by the β re-centering, still negative. |
| `test-likelihood.R:117` | stale fixture | same fixture, monotonicity |

**The two likelihood failures still are not a loophole.** The AR(1) pathology they were written
to catch has **not** returned — `cost(50) > 10000` still passes, which is the assertion that
actually tests it. They fail only because the defaults remain low-biased across the record, so a
+1 ppm shift still helps. One parameter cannot remove a whole-record bias; **the mode-find is
what resolves them** (§2). `test-pulse.R:112/113` passed on their own.

None of the four has been modified or skipped, per the standing rule.

---

## 9. Candidate next steps — for this session to rank, not to execute

| | what | depends on | worth |
|---|---|---|---|
| a | Read the mode-find; re-run `diag_bomb_partition.R` and the deep-ocean check at the mode | — | **gates almost everything**; §2 |
| b | **Decide the §4 framing** (A, B, or report both) | a is helpful, not required | cheap; **changes what the residual is**; has already misdirected two handoffs |
| c | Decide whether the land layout stays frozen in the calibration | b | one land DOF is calibrated now; widening it **changes the posterior**. Marcus' call |
| d | Verify the Arora et al. 2020 γ_L range against the PDF | — | ~10 min; decides whether §7 is a regression or a correction |
| e | Merge `luc-veg-debit` → `main` | a, c | quarantine is **already done** |
| f | Ocean ventilation / the single mixing timescale | b (if B, this is the live defect) | the whole residual under framing B |
| g | Stratospheric box **+ source rebuilt as an injection rate** | b, f | §5 — real, but a package, and probably after f |
| h | Ocean carbon inventory (32,827 vs ~38,000 GtC; DIC exactly uniform with depth) and ¹⁴C production (**359** vs ~545 mol/yr — note it got *worse* with the new land, 382 → 359, and is unexplained) | f | large and unexplained |
| i | Temperature-dependent NPP, if γ_L is judged too weak | d | a modeling decision, not a bug fix |
| j | Production MCMC: 50k × 4, gate on **R̂ < 1.05 AND ESS ≥ 400** | a, c, e | the app picks up `posterior_draws.rds` automatically |

---

## 10. Non-obvious state

- **`R/cpp.R` ERRORS on a pre-four-pool parameter list** rather than silently substituting a
  land. An older list carrying `tau_veg`/`tau_soil` gets a named diagnostic. `ccx_deriv()` (the
  R reference) still has no such guard — the same pre-existing wart as `p$gamma_enso`.
- **`aux$veg0` = `npp0 * (npp_leaf_frac*tau_leaf + (1-npp_leaf_frac)*tau_wood)` must keep
  matching `ccx_spinup()`'s leaf + wood exactly**, or the spinup state stops being a fixed point.
- `CCX_LAND_POOLS` (R/model.R) is **structural**: the C++ core hard-codes the order and the count
  (`NPH = 16`, `IML = 5`) as a stride.
- `aux$idx[[h]]$land` now exists — every land index in state order. Use it rather than listing
  pools at each call site.
- The φ stability comment in `ccx_deriv` was **rewritten, not deleted**. **Do not reinstate a
  hard φ bound from algebra** without re-running `diag_land_structure.R` [1].
- `diag_land_structure.R` **[4] is retired** (it scanned `tau_veg`/`tau_soil`); [1]–[3] are
  ported and now print **measured** endpoints. The old paragraph hardcoded "39.7 → 44.1" and
  survived a structural change that invalidated it — the same failure mode as `app/global.R`'s
  "27 ppm high". **Numbers that describe a computed result get computed.**
- **`ccx_build_forcing()`'s prescribed GMST is the FLAT path.** It bit this session: a γ_L
  measurement on it read 1.53 K of warming at 2100 on SSP5-8.5. Use `ccx_run_coupled`.
- Pre-fix calibration output is quarantined to
  `calibration/output/quarantine/20260812_luc_debit_and_2pool_land/` with a README. The two
  older quarantine dirs are **not** equivalent — `20260811b_pre_excess_c14/` is the dangerous
  one because it *looks* current (same 17 parameters, same model); its `logpost` −2359.3 must
  not be quoted.
- `LIK_EXCESS_C14_REP_FRAC = 0.15` still undecided, still low-stakes (nothing changes in
  0.02 ≤ rep_frac ≤ 0.20).
- Hand-transcribed manual CSVs carry their citation as a leading `#` block — read with
  `read.csv(comment.char = "#")`, **not** `fread`.
- Everything else from 2026-08-11 §8 still applies: `ccx_ll_ar1_SUPERSEDED()`, the FaIR export
  in `data-raw/downloads/fair_v145_ssp/`, the 1817 post-Tambora worst year, and the
  `SST_PCO2_SENSITIVITY` double-counting check open since 2026-08-09.

---

## 11. Commits

| | |
|---|---|
| `818fe93` | Offline land-topology scan: a soil-only split cannot reach N&L's partition |
| `e236fba` | Four-pool land: the bomb-14C partition error is closed |
| `16d2bb2` | diag_land_topology [4] + CHANGELOG: the 14C bounds the soil carbon-climate feedback |
| `1703f2a` | Re-center beta to 0.38, and stop hardcoding the app's CO2 bias |
| `f924412` | Port diag_land_structure to the four-pool land; handoff 2026-08-12c |
| `85ef079` | diag_stratosphere: the delivery error may be a framing artifact, not a defect |

New diagnostics, all runnable from the repo root:
`calibration/diag_land_topology.R`, `calibration/diag_stratosphere.R`.

---

## 12. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-12c_four_pool_land.md`, on branch `luc-veg-debit`. Follow its §0:
> check the mode-find, read the open framing question in §4, and come back with a recommended
> ordering of §9 before starting any of it.
