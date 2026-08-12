# Handoff — CarbonCycleEmulator, 2026-08-12 (c)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`.
Supersedes `handoff_2026-08-12b_partition_and_land_structure.md`. Its §7 step 1 was **wrong**
(§1), its §7 step 2 (φ) is **closed by the restructure, not by a decision** (§4), and its §7
step 3 is **done** (§5).

**Branch.** `luc-veg-debit` = `1703f2a`, **still NOT merged**. Suite **380 pass / 4 fail /
2 skip** — same count as before, **different set** (§6).

---

## 1. Read this before planning anything

The previous handoff prescribed: *"split the single responsive soil pool into fast and slow."*

**That cannot work, and it was cheap to find out.** A soil-only split tops out at
**30.0 / 19.5 kmol on 2214 GtC** against N&L's 21.7 / 18.9 on 2200 — 1995 right, **1975 38 %
high**. The reason is arithmetic and was sitting in plain sight: a single 600 GtC vegetation
pool at `tau_veg` 10 **already holds ~20 kmol at 1975**, essentially N&L's entire biosphere. No
soil layout underneath it can help. **The vegetation had to be split too.**

The generalisable move is in §2. It is now a memory: `feedback_offline_emulator_before_restructure`.

---

## 2. `calibration/diag_land_topology.R` — choose the structure before building it

The land's bomb-¹⁴C uptake is **linear** once the carbon fluxes are fixed: pools fill at the
atmosphere's ratio and drain at their own. So a candidate topology's inventory can be integrated
straight from an atmospheric Δ¹⁴C history — **~1 ms per candidate, no core rebuild** — instead
of restructuring 32 boxes once per idea.

Four sections, all runnable from the repo root:

- **[1] validates the emulator against the full model** on the **live** parameters (derived from
  `ccx_default_params()`, not restated, so it cannot go stale). −0.9 % / −0.6 % on the four-pool
  land; −6.5 % / −3.1 % on the two-pool one. Gated at `TOPO_VALID_TOL`; the script **exits** if
  it fails. Residual is one-signed and explained: fixed pool sizes, no CO₂ fertilisation, no LUC.
- **[2] the topology scan**, under **two** drivers. Read the **OBSERVED**-atmosphere block as the
  design target: the model's troposphere was 40–44 % short *because* its land took too much, so
  designing against the model's own depressed atmosphere would understate how inert the land
  must be.
- **[3] the refinement surface.** It is **FLAT** — 0.60/30/0.04 and 0.70/40/0.04 both ~6 % RMS.
  That is what licenses calling the defaults a defensible centre rather than a fit. **Four knobs
  against three targets would fit anything; do not present these as fitted values.**
- **[4] what the fix cost** — §4 below.

---

## 3. The structure, and the result

`leaf` (60 % of NPP, τ 1 yr) and `wood` (τ 20 yr) fed by NPP; litter split 95/5 into `soil_fast`
(τ 2 yr) and `soil_slow` (τ 500 yr). **NB 28 → 32.** Vegetation 516 GtC, responsive soil 114,
passive 1500, total 2130 — every pool independently defensible.

Routing choices, all stated at the point of use in the derivative:

| | |
|---|---|
| capacity (φ) keys on | `leaf + wood`, against the same total at spinup |
| Ra loop | per vegetation pool, at each pool's own ratio |
| litter split | applied **per source pool** — the two carry different ¹⁴C ratios, and pooling first would average them |
| seasonal NEP | through `leaf` |
| ENSO | out of `soil_fast` |
| **LUC** | **debits `wood`** (Marcus 2026-08-12) |

Paired bomb-only at `bomb_total` 102, vs Naegler & Levin Table 4:

| | before (2-pool, old mode) | after (4-pool, defaults) | N&L |
|---|---|---|---|
| biosphere 1975 | 32.80 (+51 %) | **21.73 (+0 %)** | 21.70 |
| biosphere 1995 | 29.88 (+58 %) | **20.83 (+10 %)** | 18.90 |
| troposphere 1975 | 16.13 (−40 %) | 31.34 (+17 %) | 26.80 |
| troposphere 1995 | 9.82 (−44 %) | 15.91 (−9 %) | 17.50 |
| SUM delivered | +8 / +7 % | +7 / +6 % | — |

**The 40–58 % partition error is gone.** What remains is the delivery error alone — which was
always the ceiling on what a re-shaped source could repair. **The four-pool land is NOT
calibrated: read the partition, not the level.** (The before-column is at the old mode, the
after at defaults; the structural effect is far larger than any parameter effect — at defaults
the two-pool land gave 39.74.)

---

## 4. What it cost — the durable result

**The bomb ¹⁴C bounds the soil-respiration carbon-climate feedback from above.**

γ_L fell **−57.6 → −19.6 GtC/K** (land carbon at 2100, q10 = 2 vs q10 = 1, coupled SSP5-8.5,
over GMST at 2100 — measured in **both** models, the two-pool one via a worktree at `818fe93`,
so it is like for like).

Mechanism, one number: only soil respires with q10, and a q10 anomaly can only move carbon a
pool can release on the horizon in question. **Responding carbon**, Σ C_j (1 − e^(−100/τ_j)),
fell from ~1470 GtC to ~390. Factor 3.8 against factor 2.9 in γ_L — the metric explains the loss,
so it is the right thing to scan against.

**An intermediate soil pool (τ 30–100 yr) does not rescue it** ([4], soil stock held fixed):
~**+0.7 kmol at 1975 per +100 GtC of responding carbon**, ≈3 % of the target. Doubling responding
carbon to ~730 still leaves it at half the two-pool value while pushing 1975 from exact to +13 %.

`tau_soil_fast` is likewise hard-bounded: at 5 yr the 1975 inventory is +27 %, at 10 yr +56 %.

**The escape this model does not have.** Its only carbon-climate feedback is q10 on heterotrophic
respiration. Real land models draw much of γ_L from productivity decline and disturbance — a
**temperature dependence of NPP**, which this model lacks entirely. If γ_L needs to be larger,
that is where it should come from. Not implemented; recorded as the recommendation.

*(γ_L ≈ −20 is at the low edge of what I recall of CMIP6 C4MIP, roughly −34 ± 20 GtC/K from
Arora et al. 2020 — **recollection, not verified against the paper**. Worth 10 minutes with the
PDF before anyone quotes it.)*

**φ closed itself.** `test-pulse.R:112/113` — the Joos airborne-fraction benchmark that φ = 0.5
broke — **now pass unmodified**. The capacity term's runaway (more veg → more NPP → more veg)
was an artefact of one 600 GtC pool at τ 10. No clamp needed, φ stays 0.5. The previous
handoff's §7 step 2 is **not a decision any more**.

---

## 5. `beta` re-centred to 0.38, and a trap

Handoff-b §7 step 3, done. 0.3810 is the **1-D optimum of the real log-posterior** with every
other parameter at its table init (−4560.2 → −4530.6); the CO₂-at-2020 route agrees
independently (both near 415 ppm). Changed in `ccx_default_params()` **and** the
`CCX_PARAM_TABLE` init, which must track it.

The move is far smaller than handoff-b anticipated (it expected 0.25–0.30). That estimate was
for the LUC debit against the **two-pool** land; the four-pool land absorbs most of what the
debit displaced, and the ~12 ppm low bias is down to ~3.6 ppm before this change.

**THE TRAP.** `beta` is **logit**-transformed on [0, 1.5], **not log**. A first pass at this
profile set the unconstrained value to `log(beta)` and therefore scanned
`plogis(log(beta)) * 1.5` — it looked entirely plausible and returned 0.34. Go through
`.to_unc(v, CCX_PARAM_TABLE$beta)` and assert the round-trip.

`app/global.R` no longer claims the model "reads about 27 ppm high" — that was wrong in **sign**
as well as magnitude, written once and never re-derived. Replaced with text stating **no**
computed quantity, rather than a freshly-hardcoded number that would decay the same way.

---

## 6. The four red tests — a DIFFERENT set from handoff-b. Do not "fix" them blind.

| test | cause | status |
|---|---|---|
| `test-climate.R:122` | **NEW** — γ_L, §4 | feedback 0.091 °C, bound 0.1. **Structural.** Not absorbable: q10 would have to reach ~4–5. |
| `test-mechanisms.R:32` | **NEW** — small `soil_fast` | ENSO switch moves CO₂ 0.29 ppm, bound 0.5. **Absorbable** — `gamma_enso` is calibrated (prior N(0,2)); the test pins it at 0.5. |
| `test-likelihood.R:114` | stale fixture | `cost(1) = −89.9` (was −139.2). Improved by the β re-centring but still negative. |
| `test-likelihood.R:117` | stale fixture | same fixture, monotonicity |

**The two likelihood failures still are not a loophole.** The AR(1) pathology they were written
to catch has **not** returned — `cost(50) > 10000` still passes, which is the assertion that
actually tests it. They fail only because the defaults remain low-biased across the record, so
a +1 ppm shift still helps. **One parameter cannot remove a whole-record bias; the mode-find is
what resolves them.** `test-pulse.R:112/113` passed on their own.

None of the four has been modified or skipped, per the standing rule.

---

## 7. What to do next, in order

1. **Read `calibration/output/modefind.log`.** A mode-find was **launched in the background** at
   the end of this session against the four-pool land + LUC debit (17 parameters, `tau_soil_fast`
   in place of `tau_soil`; ~2 h). It had **not finished** when this was written. Check it
   converged before anything else — and re-run `diag_bomb_partition.R`, which will now pick the
   new `mode_fit.rds` up automatically instead of falling back to defaults.
2. **Re-check the two likelihood fixtures at the mode.** If they pass there, they were exactly
   what §6 says. If they do not, that is new information and worth chasing.
3. **Decide whether the land layout stays frozen in the calibration.** Right now exactly one
   land degree of freedom is calibrated (`tau_soil_fast`), and the other five are held fixed so
   a CO₂ fit cannot undo the partition fix. **That is a choice, and it needs Marcus.** Widening
   it would change the posterior.
4. **Then merge `luc-veg-debit` to `main`.** Pre-fix calibration output is **already quarantined**
   to `calibration/output/quarantine/20260812_luc_debit_and_2pool_land/` with a README.
5. **Then the ocean.** Its single ventilation timescale, and then its carbon inventory (32,827
   GtC vs ~38,000; DIC exactly uniform with depth; ¹⁴C production **359** mol/yr vs canonical
   ~545 — note this got slightly *worse* with the new land, 382 → 359, and is unexplained).
   **NB the deep-ocean Δ¹⁴C at defaults is now −194.7 ‰, inside the observed −150 to −200
   bracket.** Handoff-b quoted −105 ‰ *at the old mode fit* — the two are not comparable, and
   nobody should conclude the deep ocean was fixed by the land until it is re-measured at the
   new mode.
6. **Then** whether γ_L wants a temperature-dependent NPP term (§4). This is a modelling
   decision, not a bug fix.
7. **Then** production MCMC: 50k × 4, gate on **R̂ < 1.05 AND ESS ≥ 400**. The app picks up
   `calibration/output/posterior_draws.rds` automatically.

---

## 8. Non-obvious state

- **`calibration/output/mode_fit.rds` is absent** (quarantined). Diagnostics fall back to
  `ccx_default_params()` and **say so** — `diag_bomb_partition.R` prints `NO mode fit found`.
  The background run will recreate it at the canonical path.
- **`R/cpp.R` now ERRORS on a pre-four-pool parameter list** rather than silently substituting a
  land. An older list carrying `tau_veg`/`tau_soil` gets a named diagnostic. `ccx_deriv()` (the R
  reference) still has no such guard — the same pre-existing wart as `p$gamma_enso`.
- **`aux$veg0` = `npp0 * (npp_leaf_frac*tau_leaf + (1-npp_leaf_frac)*tau_wood)` must keep matching
  `ccx_spinup()`'s leaf + wood exactly**, or the spinup state stops being a fixed point.
- `CCX_LAND_POOLS` (R/model.R) is a **structural** constant: the C++ core hard-codes both the
  order and the count (`NPH = 16`, `IML = 5`) as a stride.
- `aux$idx[[h]]$land` now exists — every land index in state order. Use it instead of listing
  pools at each call site.
- The φ stability comment in `ccx_deriv` was **rewritten, not deleted**: the decoupled bound is
  still wrong, and the two-pool coefficient `(phi*f - 1)/tau_veg` is replaced by the wood
  coefficient. **Do not reinstate a hard φ bound from algebra** without re-running
  `diag_land_structure.R` [1].
- `calibration/diag_land_structure.R` **still runs on `tau_veg`/`tau_soil` and is now BROKEN.**
  It is the provenance of the [4] sub-linearity finding that motivated all of this. Either port
  it to the four-pool land or retire it explicitly — do not leave it looking runnable.
- Everything from 2026-08-11 §8 still applies: `ccx_ll_ar1_SUPERSEDED()`, the
  **`ccx_build_forcing()` flat-GMST warning** (it bit this session — a γ_L measurement on the
  prescribed path read 1.53 K of warming at 2100 on SSP5-8.5; use `ccx_run_coupled`), the FaIR
  export in `data-raw/downloads/fair_v145_ssp/`, the 1817 post-Tambora worst year, and the
  `SST_PCO2_SENSITIVITY` double-counting check open since 2026-08-09.
- `LIK_EXCESS_C14_REP_FRAC = 0.15` is still undecided and still low-stakes (nothing changes in
  0.02 ≤ rep_frac ≤ 0.20).
- Hand-transcribed manual CSVs carry their citation as a leading `#` block — read with
  `read.csv(comment.char = "#")`, **not** `fread`.

---

## 9. Commits

| | |
|---|---|
| `818fe93` | Offline land-topology scan: a soil-only split cannot reach N&L's partition |
| `e236fba` | Four-pool land: the bomb-14C partition error is closed |
| `16d2bb2` | diag_land_topology [4] + CHANGELOG: the 14C bounds the soil carbon-climate feedback |
| `1703f2a` | Re-centre beta to 0.38, and stop hardcoding the app's CO2 bias |

---

## 10. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-12c_four_pool_land.md` and continue carbon cycle emulator
> development on branch `luc-veg-debit`. Start by checking whether the background mode-find
> in `calibration/output/modefind.log` converged.
