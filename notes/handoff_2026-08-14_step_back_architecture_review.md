# Handoff — CarbonCycleEmulator, 2026-08-14: STEP BACK AND REVIEW THE WHOLE MODEL

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`,
**not merged**. Tag `checkpoint/pre-phase1-2026-08-13` marks the pre-13i state.
Suite **10 fail** (was 2; the new ones are fixture-driven and deliberately unfixed).

**Supersedes the SEQUENCE, not the CONTENT, of `handoff_2026-08-13h_sequenced_plan.md`.**
13h ordered the work cheap-fixes → refit → pump. PHASE 1 is done
(`handoff_2026-08-13i_phase1_measured.md`), and Marcus has called a stop before PHASE 2:

> **Take a step back and look at the big picture first.**

13h §§3–4 (the refit design, the pump case) stay on the shelf, unchanged, until the review
below says whether they are still the right next steps.

---

## 0. START HERE

1. **DO NOT start the refit. DO NOT build the biological pump.** The first deliverable of
   this session is the review in §2, not code.
2. **The review is a DESIGN document, not a to-do list.** Its output should be a written
   answer to §2's four questions that a later session can implement against — the same role
   `DESIGN.md` plays, and it may well end as an amendment to `DESIGN.md` §3.
3. **One defect was found while taking inventory for this note and is NOT fixed** — §1. It
   is in the objective function, so it invalidates any refit run before it lands. Read it
   first; it is also a worked example of what the review is for.
4. **Read `handoff_2026-08-13i` §2 and its ADDENDUM §A1 before forming opinions.** Two
   structural tensions and one reversed pedagogical claim are already on the table, and the
   review should absorb them rather than rediscover them.
5. **Standing discipline that keeps biting here:** implausible result = bug; suspicious
   uniformity = bug signal; confidence words need receipts; carry the evidence, not the
   label. All four earned their place in this project in the last week.

---

## 1. FOUND WHILE WRITING THIS NOTE, NOT FIXED: the GCB land-sink term compares two
## different quantities

`R/likelihood.R` ~line 590:

```r
mod_ld <- c(NA, diff(g$land_C))                    # model NET land flux (sink - E_LUC)
add("gcb_land_sink",
    sum(stats::dnorm(g$land_sink[k], mod_ld[k], ...)))   # GCB GROSS residual sink
```

This is the **same net-vs-gross trap** fixed in the diagnostics at `cc3abd5` — but here it
is **inside the objective the MCMC will optimize**. The model is being asked to make its
NET land flux equal GCB's GROSS sink, i.e. to over-absorb by exactly E_LUC (~1.37 GtC/yr
recently).

**Measured** (default params, β scanned, everything else fixed):

| β | term AS SHIPPED | term CORRECTED (`mod_ld + E_LUC`) | mean model−GCB, net | gross |
|---|---|---|---|---|
| 0.30 | −146.0 | −126.7 | −2.13 | −0.44 |
| 0.38 | −139.6 | **−125.7** | −1.75 | **−0.07** |
| 0.50 | −132.9 | −126.7 | −1.23 | +0.45 |
| 0.60 | −129.6 | −129.1 | −0.84 | +0.84 |
| 0.75 | −127.6 | −134.9 | −0.31 | +1.37 |
| 0.85 | **−127.8** | −139.6 | −0.00 | +1.68 |

**As shipped the term prefers β to rise** — monotonically, bottoming near 0.85, because
that is where the net flux finally equals GCB's gross sink. **Corrected, its own optimum is
β ≈ 0.39 and it resists rising β.** The sign of its pull is inverted by the bug, which is
exactly why nothing caught it: it was pushing the same way as the CO₂ stream.

**Why it is a bug and not a choice:** comparing two different physical quantities is not a
methodological option. The only choice attached to this term is its σ — `LIK_GCB_LAND_SD
0.9 × LIK_LAND_SINK_INFLATE 3.0 = 2.7 GtC/yr`, which traces to **`DESIGN.md` §9 Q1**
("GCB land sink as a *soft* constraint with inflated σ — default yes").

**Why it was left unfixed:** the fix changes the objective, the refit is blocked anyway,
and this note's job is to put it in front of the review rather than quietly alter what the
model is fitted to. **Fix it before any refit.**

**And note the second-order point, which is review material:** even corrected, the term
moves only ~9 log-units across β 0.38 → 0.75, against the CO₂ streams' ~12,000. At σ = 2.7
GtC/yr the "partition constraint" this model claims to have is **nearly decorative**. That
belongs under §2(a).

`gcb_ocean_sink` has no E_LUC analog and is **not** affected.

---

## 2. THE REVIEW — terms of reference

Marcus' framing, four parts. Each carries an inventory of what is actually in the repo
today (so the review starts from fact, not recollection) and the questions to answer.
**The inventories are verified against the code as of this commit**; the questions are not
answered here on purpose.

### (a) TARGETS — what are we asking the model to reproduce?

**Currently in the likelihood — 13 streams.** Values at default params, β 0.75, for scale:

| stream | logL | what it constrains |
|---|---|---|
| `co2_level_MLO` / `_SPO` | −195 / −158 | the level, 1958–2024 |
| `co2_seasonal_MLO` / `_SPO` | −837 / −103 | per-year harmonic coefficients — **the only thing constraining `seas_amp_*`, `seas_phase_*`** |
| `co2_icecore` | −683 | Law Dome, pre-1958 |
| `d13c_level_MLO` / `_SPO` | −198 / −52 | the Suess decline + the land/ocean partition |
| `d14c_NH` / `_SH` | −311 / −394 | zonal-aggregated annual means, incl. the bomb window |
| `d14c_intcal` | −670 | IntCal20 tree rings |
| `excess_c14_ocean` | −7.5 | ocean bomb-¹⁴C inventory, full covariance |
| `gcb_ocean_sink` | −58 | GCB partition |
| `gcb_land_sink` | −128 | GCB partition — **defective, see §1** |

**Monthly pattern.** Resolved: the model runs monthly and the seasonal cycle is scored as
per-year harmonic (a, b) coefficients, deliberately separated from the annual level so the
two are not double-counted. The NEP seasonality is a prescribed sinusoid,
`amp·sin(2π(t − phase/12))·(npp/npp0)`, **not** an emergent phenology.

**Hemispheric pattern.** Two boxes, exchange time `tau_ex` (1.3 yr default). Scored only
through MLO-vs-SPO in each stream — **there is no interhemispheric-gradient statistic**.
Known open mismatch: modeled MLO−SPO δ¹³C gradient **−0.210 ‰ vs observed −0.074**, and a
~1.1 ppm CO₂ gradient error visible in the residual (MLO mean −0.54, SPO +0.55).

**Isotopic pattern.** δ¹³C and Δ¹⁴C as above. Not in the likelihood but measured and
citable: **Quay et al. 2003** mixed-layer Suess rate (0.160 ± 0.020 ‰/dec), **Eide et al.
2017** cumulative surface Suess, **SHCal20** preindustrial NH−SH Δ¹⁴C offset
(+4.49 ± 3.38 ‰). Whether any becomes a likelihood term is `13h` §5 decision 3, still open.

**Questions to answer:**
- Is the target *set* right — what is missing, and what is in it that should not be?
  (Candidates in: the three isotopic diagnostics above; a deep-Δ¹⁴C term, see §3.)
- **Are the weights defensible?** CO₂ carries ~10³–10⁴ log-units; the two partition terms
  carry ~10²; `excess_c14_ocean` carries ~10⁰. A stream that cannot outvote noise in
  another stream is not a constraint. *This is the single most consequential question in
  (a)* — the whack-a-mole history (17 params → `tau_soil_fast` +3.6σ; 16 params → `q10`
  −7.0σ) is what an unbalanced objective looks like from the inside.
- Should the hemispheric gradient be a target in its own right, given it is 3× off?
- Monthly: is scoring harmonics of the *observed stations* the right target, or should the
  seasonal cycle be a **derived** check rather than a fitted one?

### (b) INPUTS — what is prescribed, and how good is it?

12 forcing columns: `e_foss_NH/SH`, `e_luc_NH/SH`, `gmst`, `enso`, `c14_bomb`,
`c14_nuclear`, `c14_cosmo`, `d13c_foss`, `cum_luc_NH/SH`.

| input | source | status |
|---|---|---|
| **Fossil CO₂** | GCB 2025, 1750–2024; 504.7 GtC cumulative | solid; NH share **0.95 provisional** |
| **LUC CO₂** | GCB bookkeeping 1850–2024 + **OSCAR v3.1 rescaled for 1750–1849**; 289.3 GtC | NH share **0.55 provisional**; `cum_luc` is a forcing column, not a state |
| **Bomb ¹⁴C** | Naegler & Levin (2006) 99.3–104.9 kmol; `bomb_total` is *calibrated* with that prior | **injection SHAPE still provisional** (`DATA.md` §8) — magnitude absorbs shape error |
| **Nuclear ¹⁴C** | 22 reporting countries | NH share **0.90 provisional** |
| **Cosmogenic ¹⁴C** | *derived* as a readout, 360 vs canonical 545 mol/yr (**ratio 0.66**) | see `project_ccx_prod_c14_is_a_readout` |
| **ENSO** | index, scaled by `gamma_enso` into a soil_fast↔atm transfer | **mean +0.286 over 1750–2100 and +1.438 post-2020** — it is not a zero-mean oscillation in the future |
| **GMST** | IGCC, per the standing obs convention; 0 before 1850 | flat-held past the record (warns) |
| **δ¹³C of fossil** | GCB by-fuel split, −24.0 ‰ (1850) → −28.3 ‰ (2024) | was a single −28; fixing it moved the bias only 3 % |

**Questions to answer:**
- The four **provisional hemispheric shares** (0.95 / 0.55 / 0.90 / 0.90) have never been
  tested for sensitivity, and (a) says the hemispheric gradient is 3× off. Are they the
  cause? *This is the cheapest unexplored lead in (b).*
- Is `E_LUC` the right *kind* of input at all? It is a **net bookkeeping flux** that already
  contains regrowth and legacy soil loss — which is the argument that decided the pro-rata
  debit — yet the model also has its own regrowth dynamics. Where is the boundary, and is
  anything double-counted? (`404d66d` fixed one instance of exactly this.)
- ENSO's non-zero future mean: is the forcing right, or is it an artifact of how the index
  is extended past the observational record?
- Does the bomb-¹⁴C **shape** need to stop being provisional before Δ¹⁴C can be trusted to
  constrain ventilation?

### (c) COMPONENTS — options, physical sense, and what each buys against the targets

This is the substance of the review. **Current structure**, all verified:

| component | as built | switches / options present | not present |
|---|---|---|---|
| **Atmosphere** | 2 well-mixed boxes, `tau_ex` gross both ways | — | no stratosphere (v2 backlog) |
| **Land** | **4 pools** — leaf 1 yr, wood 20, soil_fast 2, soil_slow 500; equilibrium shares 1.7 / 22.5 / 5.4 / **70.4 %** | `npp_veg_frac` (capacity), `ra_ratio` (gross GPP/Ra loop, **default 0 = no gross loop**) | no nutrient limitation; no phenology |
| **Land–LUC coupling** | converted-land term: `c = f_luc_perm·cumLUC/land0` scales `npp0` *and* `veg0` | `f_luc_perm` (1 = permanent), `f_luc_wood` (**0 = pro rata**, decided 2026-08-14) | no timing-resolved debit (fast veg / slow soil) — **logged, not built** |
| **Fertilization** | `NPP = NPP0(1 + β ln(χ/χ0))`, **unsaturated** | β only | **no saturation** — see §2(d), this is now a known failure mode |
| **Temperature** | `q10` on heterotrophic respiration; `sst_scale` on ocean solubility | `warming_feedback` mechanism switch | no separate NPP temperature response |
| **ENSO** | `gamma_enso · enso` transfer soil_fast → atm | `enso` switch | does not interact with `q10` or with NPP |
| **Ocean** | box-diffusion column per hemisphere: mixed layer + **10 interior layers**, `kz` diffusivity, full carbonate chemistry | `w_up`, `w_out_NH/SH` (advection), **conveyor `q_conv`/`conv_sink`/`conv_descent`/`conv_reverse` — BUILT, OFF**, `revelle_frozen` | **NO biological pump**; interior carries no carbonate chemistry |
| **Gross vs net** | gross both ways for air–sea and interhemispheric; land gross loop **off** by default | `ra_ratio` | — |

**Known measured facts that constrain the options** (do not re-derive these):
- Ocean interior **DIC gradient is EXACTLY ZERO** (1986.3 µmol/kg uniform through 3700 m;
  observed ~300) and the interior **δ¹³C gradient is exactly +1.560 ‰ uniform** (observed
  ~1–1.5 ‰). The ~14 % ocean inventory deficit and the missing DIC gradient are the same
  number (13e §6).
- The conveyor **fails its own falsification test** (13c §2c): it does not shrink the
  MLO−SPO δ¹³C gradient; it moves it slightly the wrong way.
- A pump's effect on the **atmospheric δ¹³C misfit is SIGN-UNKNOWN** (13e §7), and it works
  **against** the deep-age constraint. Adopt it for the interior gradients and the
  ventilation constraint, not for δ¹³C.
- **`kz` = 5000 m²/yr is ~9× Ledwell's NATRE 536.** The 1-D log-posterior nonetheless peaks
  at 5000, under both candidate σ_d13c.
- Reversing a closed vertical loop is **provably invisible to the atmosphere**
  (`project_ccx_upwelling_does_not_close_d13c`) — beware options that only permute an
  internal circulation.

**Questions to answer, component by component:** for each, *what are the options, which
make physical sense, and which are load-bearing for the targets in (a)?*
- **Land pools:** is 4 right? The four-pool layout was chosen to fix the bomb-¹⁴C partition
  and it did (biosphere +51 % → +0 % at 1975). Does anything in (a) still need more, or
  fewer?
- **Fertilization:** the unsaturated log form is now a **known defect** (§2d). Options:
  saturating (e.g. a Michaelis–Menten / β with a ceiling), nutrient-limited, or keep the
  log and cap the app's scenario range. This is the highest-value structural question in
  (c) because it is the one with a demonstrated failure.
- **Ocean:** pump, conveyor, both, or neither? Note the pump and the conveyor answer
  *different* mismatches, and 13h §4.3 says a pump alone is "mostly bookkeeping; a pump
  plus a return path is a mechanism."
- **Temperature × ENSO:** they currently act on the same pool (`soil_fast`) through
  independent terms and do not interact. Should they?
- **Gross vs net:** `ra_ratio` defaults to 0, so the land has **no gross photosynthesis
  loop** — the isotopes see only net NPP. Air–sea and interhemispheric *are* gross. Is that
  asymmetry defensible? (It was measured to move δ¹³C only 0.10 ‰ across `ra_ratio`'s whole
  range, while Δ¹⁴C moves 2.7 → −14.6 ‰, which is what forbids large values.)

### (d) DOES THE ASSEMBLED THING WORK — pulse lifetime, and pedagogy?

Marcus' own framing: **pulse lifetime is expected to be the weakest test.** Current state:

- **The Pulse Lab's Revelle-saturation lesson REVERSES above β ≈ 0.53** — an identical
  pulse persists *less* long on a high-CO₂ background, the opposite of what the tab
  teaches. ssp585 − ssp119 airborne fraction at 2150: **+0.204 (β 0.38), +0.085 (0.50),
  −0.011 (0.60), −0.109 (0.75)**. The LUC debit is irrelevant to it. Cause: unsaturated
  log-fertilization gives **2.48× preindustrial NPP at 1998 ppm**. The current default β is
  **0.75** — on the wrong side of this.
- Joos et al. (2013) IRF: the model sat **inside the 5–95 % range** when last checked
  (`project_ccx_pedagogy_spec_panel`) — **that check predates β 0.60/0.75 and must be re-run.**
- `test-pulse.R` currently fails at `:83, :100, :101, :112` for these reasons.

**Questions to answer:**
- What β can the app actually ship with, and is that compatible with any calibration
  criterion? If not, the fertilization form has to change — which makes (d) feed straight
  back into (c).
- Re-run the Joos IRF gate at the current default before anything else in (d).
- Pedagogy: the spec's own test is *"can each mechanism be explained in one sentence?"*
  Apply it to every option in (c). The conveyor **failed** this test where the pump passes
  ("plankton grow at the surface, die, and sink, which is why the deep ocean is rich in
  carbon and the surface is poor").
- Does the model still teach the right **turnover-vs-lifetime** distinction (4.69 yr
  turnover against a 40.3 yr mass 1/e)? That is the app's headline pedagogical claim.

---

## 3. State carried in — decisions, blockers, failures

**Decisions taken 2026-08-14:**

| | outcome |
|---|---|
| LUC debit | **PRO RATA** (`f_luc_wood` default 0). Reasoning in full at `CCX_F_LUC_WOOD_DEFAULT`. |
| `sigma_d13c` | **left free**. No code change. |
| failing-test re-derivations | **none written**. All left failing. |
| `kz` bracket | **delete + add a deep-Δ¹⁴C likelihood term** — **BLOCKED**, below |

**The `kz` decision is blocked on PROVENANCE and must not be forced.** The `[−150, −200] ‰`
target appears **once** in the repo (`DATA.md` §5, *"roughly −150 to −200"*) with no source.
Hard rule 2 forbids an uncited value in code, and a term in the objective is a stronger use
than the bound it replaces. **The bracket is therefore still in place**, because bare
deletion is the measured-and-rejected option (kz → 10,686, deep Δ¹⁴C −112.7 ‰).
**GLODAPv2 unblocks it, and 13h §4.3 needs the same pull for the pump's deep DIC and δ¹³C
targets — one `data-raw` pull serves both, and doing it early is the cheaper ordering.**

**The 10 failing tests**, none edited:

```
test-climate.R:121, :122       carbon-climate loop gain; higher beta damps it further
test-likelihood.R:114          CO2-bias cost -- fixture-dependent; curvature is UNCHANGED
                               ((cost(+1)+cost(-1))/2 = +26.40 at every beta)
test-luc-permanence.R:88       the FOSSIL reference arm, 0.189 vs > 0.2 -- moved by beta
test-luc-permanence.R:104      needs f_luc_perm = 0 AND f_luc_wood = 1; sets only the first
test-mechanisms.R:32           ENSO switch weak on the level AND on growth-rate sd
test-pulse.R:83,:100,:101,:112 THE PULSE LAB -- see 2(d); :100/:101 is the reversed lesson
```

**Two structural tensions already on the table** (from `handoff_2026-08-13i`):
1. **CO₂ level vs GCB budget** — matching GCB's cumulative land costs ~21 ppm of CO₂ bias,
   under **both** debits. §1 above bears directly on this and may change its size.
2. **δ¹³C** — the model over-depletes by ~0.53 ‰ at a CO₂-consistent β, and neither the
   source signature, the fractionation constants, the reachable partition, nor the gross
   land loop closes it.

---

## 4. Non-obvious state

- **`ccx_default_params()$beta` is 0.75 and `f_luc_wood` is 0.** Every "at default
  parameters" number written before 2026-08-14 is at some other β. This default has moved
  **three times** in two days (0.38 → 0.60 → 0.75); check the date on any quoted number.
- `mode_fit.rds` is stale in **six** ways now (13g §0.5's four, plus both β moves) and its
  `par_mode` carries only the 16 calibrated names — overlay it on `ccx_default_params()` or
  `ccx_spinup()` dies in the carbonate solve on the missing `sst_NH`.
- **The MCMC has never been run.** There is no `posterior_draws.rds`. A mode-find is not a
  posterior, and `DESIGN.md` §5.4 wants uncertainty.
- **`ccx_luc_pool_shares()` (R) and the `w4[]` block in `ccx_core.cpp` are independently
  derived** from the same six land parameters. Deliberate — `test-parity.R`'s pro-rata case
  is what catches a disagreement — but a land-structure change must be checked against it.
- **`CCX_LUC_CLEARED_MAX` (R) and `LUC_CLEARED_MAX` (C++) are duplicated and nothing catches
  a disagreement.** If one moves the other must move in the same commit.
- A window starting mid-record no longer begins at a fixed point; `ccx_build_forcing()`
  warns, and **the 48 warnings in a suite run are all real**.
- A forcing with LUC emissions and no `cum_luc` is an **ERROR**, not a zero-default.
- A zero-emission run is **not flat** unless GMST and ENSO are frozen (+8.34 ppm / 275 yr).
- **Do not scan a default by monkey-patching `ccx_default_params()` into
  `testthat::test_file()`** — it silently does not take, and returns byte-identical numbers
  at every value. Edit the default, or use a standalone probe verified against the test at
  one shared point.
- New diagnostics from PHASE 1: `diag_recentre_beta.R`, `diag_luc_prorata.R`,
  `diag_kz_bracket.R`. Everything in 12d §§2–8 and §10 still applies.

## 5. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-14_step_back_architecture_review.md` and do **§2 only**:
> a written big-picture review of targets, inputs, components and whether the assembled
> model works. **Do not start the refit and do not build the pump** — the point of this
> session is to decide whether those are still the right next steps. Start from §1, the
> defect in the objective found while taking inventory; it is unfixed on purpose and it is
> a worked example of what the review is looking for. The inventories in §2 are verified
> against the code — build on them rather than re-deriving them, and spend the effort on
> the questions, which are deliberately unanswered. Expect the output to be a design
> document, most likely an amendment to `DESIGN.md` §3.
