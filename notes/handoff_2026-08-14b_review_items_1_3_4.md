# Handoff — CarbonCycleEmulator, 2026-08-14 (b): the review landed, items 1/3/4 are done

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
at **`3d923ef`**, still **not merged**. Suite **11 fail** (see §5 — the "10" in earlier
handoffs was wrong). Tag `checkpoint/pre-phase1-2026-08-13` still marks the pre-13i state.

**Supersedes the SEQUENCE of `handoff_2026-08-14_step_back_architecture_review.md`.** That
note asked for a review and forbade code; the review was delivered
(`notes/review_2026-08-14_architecture.md`, `4f70571`) and Marcus then said *"go ahead and
start on the priority list"*, so items **1, 3 and 4** are now done and item **7** is
unblocked but untouched. **The review document is still the authoritative statement of
WHAT is wrong and WHY; this note records what changed and what it changed about the plan.**

---

## 0. START HERE

1. **Read `notes/review_2026-08-14_architecture.md` first**, at least §0 and §7. Everything
   below is an amendment to it. Do not re-derive its inventories.
2. **The headline has not moved: the shipped default fails two of DESIGN §6's hard gates**
   (7, sinks; 12, Joos IRF), and the cause is the objective's 40 : 1 weighting of CO₂ over
   the partition terms. Items 1/3/4 did not fix that and were never going to.
3. **Three decisions are now waiting on Marcus and each has numbers attached** — §4. The
   most consequential is the **deep-Δ¹⁴C σ**, which turns out to be the whole of the kz
   decision rather than a detail of it.
4. **Two of my own predictions were refuted and are recorded as refuted**, in the files
   that made them, not deleted (§3.2, §6). Carry the evidence, not the label.
5. **Nothing has been merged and no default has moved.** `beta` is still 0.75,
   `f_luc_wood` still 0, and every gate that was failing is still failing.

---

## 1. What actually changed in the model

Three commits after the review. **Only the objective and the forcing changed; no model
physics, no defaults, no fixtures.**

| commit | what |
|---|---|
| `4f70571` | the review itself + `diag_stream_leverage.R`, `diag_luc_scale.R`, `diag_joos_beta_scan.R` |
| `304386a` | **items 1 + 3**: the GCB-sink block fixed three ways; `luc_scale` added as the 17th parameter |
| `ccb3b7d` | emission-input measurements: scale degeneracy, hemispheric split, seasonality |
| `3d923ef` | **item 4**: GLODAPv2 pulled; deep Δ¹⁴C / δ¹³C / DIC targets built |

### 1.1 `R/likelihood.R` — the GCB sink block

- **NET vs GROSS fixed.** Reconstructed as `net + E_LUC`, using the **model's own** land-use
  flux via a new `luc` argument to `ccx_loglik()`. `NULL` falls back to GCB's column, which
  is bit-identical to the forcing at `luc_scale = 1` (verified 1959–2024, max |diff| = 0),
  so every pre-existing caller stays correct without knowing the argument exists.
- **Year alignment fixed.** Stocks are interpolated to calendar-year *boundaries* and
  differenced, with **linear extrapolation** at the two ends — `rule = 2` would hold flat
  across the half-month the monthly grid leaves outside and under-count the end years.
- **`LIK_GCB_LAND_SD` 0.9 → 0.5**, with the whole GCB uncertainty block now quoted verbatim
  from `data-raw/downloads/gcb2025_global_budget.csv` (ocean ±0.4, land ±0.5, E_LUC ±0.7
  GtC/yr, fossil ±5 %, all 1σ). The 0.9 was labelled "GCB stated" with **no provenance in
  the repo**. This is a change to the objective and is logged as one.

**Consequence to carry:** gate 7's land miss at β 0.75 is **+4.4σ**, not the +2.5σ the
review computed on the uncited 0.9. Land-sink leverage on β went **2.0 → 24.3**.

### 1.2 `luc_scale`, the 17th parameter

`ccx_build_forcing(luc_scale=)` applied to the **annual** series, so the monthly flux, the
in-window cumulative and the **pre-window `luc_pre`** all scale together. Inside
`ccx_make_logpost()` it is an equivalent column multiply for speed; `test-luc-scale.R`
gates the two paths against each other.

Prior: **lognormal, median 1, sdlog 0.28**, from two independent receipts that agree —
OSCAR v3.1's own 206 ± 57 PgC (27.7 %) and the GCB-vs-OSCAR spread over the identical
1850–2018 window (|ln 0.746| = 0.293).

**It must never enter `ccx_default_params()`** — a test guards this. It is an input scale,
like `bomb_total`, not a model parameter; put it in the defaults and every diagnostic that
does not know about it silently rescales.

### 1.3 GLODAPv2 (item 4)

`data-raw/build_glodap_deep_targets.R` → `data/obs_glodap_deep.rds`. MANIFEST key
`glodap_v2_2023`. **The 110 MB zip and the 853 MB CSV are gitignored** (as all downloads
are); the extracted `glodap_c13c14_subset.csv` (50,634 rows, 3.1 MB) is also gitignored, so
**a fresh clone must re-run the download + the awk extraction** — the extraction command is
in the CHANGELOG entry and the subset's columns are documented in the build script.

---

## 2. What was measured, and what it means for the plan

### 2.1 The three deep targets, on the model's OWN bottom layer (2627–3700 m)

Binned 5°×10°×250 m, cos(lat)-weighted, because GLODAP over-samples the Atlantic.

| | model | observed | spread |
|---|---|---|---|
| Δ¹⁴C | kz-dependent | **−175.3 ‰** (N-Atl cut −178.2) | ±45.9 |
| δ¹³C | **+1.560 UNIFORM** | **+0.424 ‰** | ±0.3 |
| DIC | **1986.3 UNIFORM** | **2273.1 µmol/kg** | ±53.9 |

**DATA.md §5's uncited "roughly −150 to −200 ‰" was RIGHT** — its midpoint −175 is within
0.3 ‰ of the measurement. The recollection was good and simply had no receipt.

**The pump's targets are now quantities, not directions:** observed surface→deep DIC
gradient **+233 µmol/kg** against the model's exactly 0; δ¹³C **−0.861 ‰** against the
model's 0 at a uniform +1.560. The model's deep DIC is **12.6 % below** observed, which
independently reproduces 13e §6's "~14 % ocean inventory deficit" from a different
measurement. *Correction to the repo's recollection:* the observed interior δ¹³C gradient
was recorded as "~1–1.5 ‰"; on the model's own layers it is **0.861** — right order, ~30 %
high.

### 2.2 The emission inputs

- **`foss_scale` is identifiable but low-value — NOT added.** Δ¹⁴C separates the two scales
  (82 log-units along the iso-carbon line at β 0.75, of which Δ¹⁴C is −104), so they are
  **not degenerate** — but identification is 10–20× weaker along that line than across it,
  and GCB's fossil prior (±5 % = 25 GtC) admits 3.2× less carbon movement than LUC's
  (±28 % = 81 GtC), so it would mostly reproduce its own prior. **Add it only if the refit
  drives `luc_scale` to a prior edge.**
- **The LUC hemispheric share is TIME-VARYING and the constant 0.55 is wrong at both ends.**
  From OSCAR v3.1's *Regional* sheet: NH share falls **0.838 (1750–1849) → 0.398
  (1990–2018)**. Within-region NH fractions are geographic judgements so everything is
  bracketed — and the conclusion survives the whole bracket (pre-1950 even the low bound is
  ≥0.60; post-1990 even the high bound is ≤0.53). **~23 GtC of early land-use carbon is in
  the wrong hemisphere.**
- **The objective cannot see the shares.** Fossil share 0.90 → 0.97 moves the MLO−SPO CO₂
  gradient by **0.84 ppm** — most of the model's 1.09 ppm error — for **5.1 log-units**.
- **The δ¹³C-gradient-from-shares lead is DEAD.** Across the whole plausible range the
  modelled δ¹³C gradient moves only −0.213 to −0.258 against an observed −0.074. The 3×
  miss is structural. Review §3.4's "cheapest unexplored lead" is now explored and negative.
- **Omitted input seasonality biases the fitted NEP amplitude by ~8 %.** Bounding test:
  LUC + fossil seasonality of plausible size is worth **+0.369 ppm** of MLO peak-to-peak —
  almost exactly what moving `seas_amp_NH` 12 → 13 does (**+0.373**). Absorbed one-for-one
  by the one free NEP amplitude, in the objective's highest-leverage stream. **Phase control
  passed:** flipping the NH burning peak Jan → Jul turns +130 log-units into −40, so it is
  not "any extra variance helps".

---

## 3. The pre-registered predictions, and how they came out

**Both are kept in the files that made them.** Neither was edited after the fact.

### 3.1 MET, conditionally — β and `luc_scale`

Review §3.3 predicted β falls to 0.40–0.55 and `luc_scale` to 0.6–0.8.
`diag_beta_luc_profile.R`, 2-D slice of the **full** log-posterior:

| σ_d13c | β | `luc_scale` | cum LUC | CO₂ bias | land | ocean |
|---|---|---|---|---|---|---|
| 0.10 (table init) | 0.70 | 0.90 | 260 GtC | +3.53 ppm | +3.8σ | −2.0σ |
| **0.44 (mode_fit)** | **0.55** | **0.70** | **203 GtC** | **−0.40 ppm** | +2.0σ | −1.6σ |
| 5.00 (muted) | 0.55 | 0.70 | 203 | −0.40 | +2.0σ | −1.6σ |
| *`luc_scale` pinned at 1* | **0.75** | — | 289 | +3.34 | +4.4σ | −2.1σ |

**With LUC pinned, β = 0.75 at every σ_d13c** — pinning the input is what made the high β
look robust. The settlement's cumulative LUC of **203 GtC lands on OSCAR's central 206**
without being told to; the prior supplied only a width.

### 3.2 REFUTED on the first run, and why that matters

The first run of `diag_beta_luc_profile.R` held σ_d13c at the table's 0.10 and put the
argmax at **β 0.70 — refuting the prediction**. The refutation was conditional: at σ 0.10
δ¹³C contributes ~740 log-units in favour of high β while carrying a known unclosed 0.53 ‰
**structural** misfit, i.e. σ 0.10 asserts that misfit is measurement noise. At 0.44 and at
5.00 the answer is identical, so **0.10 is the outlier**. The refutation is in the file's
header, not deleted.

**Consequence: Marcus' 2026-08-14 "leave `sigma_d13c` free" decision is now load-bearing on
β**, which it was not when taken.

---

## 4. DECISIONS WAITING ON MARCUS — all three now have numbers

| | decision | the measurement it rests on |
|---|---|---|
| **1** | **the deep-Δ¹⁴C σ — and it is now the WHOLE of the kz decision** | §4.1 below |
| **2** | **the β default**, given gates 7 and 12 | review §5; `luc_scale` gets it to 0.55, still above the ≈0.50 ceiling |
| **3** | **`sigma_d13c`: still free?** | §3.2 — it now decides where the (β, `luc_scale`) ridge settles |

### 4.1 The σ decision, stated fully because it inverts 13i §A3

13i §A3 said GLODAPv2 would supply "a real spatial spread for the sigma". **It supplies the
spread; the spread is not the sigma.** A one-box model is scored against the volume-weighted
*mean*, whose uncertainty is the spread ÷ an effective sample size — and deep water masses
are basin-coherent, so n_eff is of order *tens*, not the 3,592 cells. Measured against the
runaway bare deletion produces (kz → 10,686, deep Δ¹⁴C −112.7 ‰):

| candidate σ | ‰ | runaway at | verdict |
|---|---|---|---|
| measurement error alone | 3.0 | 20.9σ | HOLDS kz |
| SE of the weighted mean, n_eff = 20 | 10.3 | 6.1σ | HOLDS kz |
| SE of the weighted mean, n_eff = 5 | 20.5 | 3.0σ | HOLDS kz |
| **full spatial spread (n_eff = 1)** | **45.9** | **1.4σ** | **DOES NOT HOLD kz** |

**And the incumbent bracket [3830, 6200] is effectively a hard ±25 ‰ box — tighter than
every candidate but the most aggressive.** So *deleting the bracket in favour of an "honest"
likelihood term would LOOSEN the constraint, not tighten it.* Marcus' A2 decision 1 ("delete
+ add a term") was taken believing the opposite. **Re-take it.**

---

## 5. The 11 failing tests — and a correction to the count

**The pre-change suite was 11, not the 10 recorded in 13i §A5 and carried into two later
handoffs.** `test-pulse.R:113` was already failing; 13i §A1's *text* listed it and §A5's
*summary list* did not. Verified by running the suite on the stashed pre-change tree.

```
test-climate.R:121, :122        carbon-climate loop gain, weakened by beta 0.75
test-likelihood.R:114           CO2-bias cost -- fixture-dependent; curvature UNCHANGED
test-luc-permanence.R:88        the FOSSIL reference arm, 0.189 vs > 0.2 -- moved by beta
test-luc-permanence.R:104       needs f_luc_perm = 0 AND f_luc_wood = 1; sets only the first
test-mechanisms.R:32            ENSO switch weak on the level and on growth-rate sd
test-pulse.R:83,:100,:101,:112,:113   THE PULSE LAB -- externally corroborated, see below
```

**`test-likelihood.R:165` was the only newly-failing test** and it is the parameter-count
tripwire doing its job. Updated to 17 **with the reason written in**, plus two new guards
(`luc_scale` must be in `CCX_PARAM_NAMES`, must **never** be in `ccx_default_params()`).

**The pulse failures now have EXTERNAL corroboration** — `diag_joos_beta_scan.R` reproduces
the same defect against Joos et al. (2013) at the same β. They are the model reporting a
real structural failure. **Leave them failing until the fertilisation form changes.**

---

## 6. The ordering, amended

Review §7's list with items 1, 3, 4 struck and the new findings folded in.

| # | task | status |
|---|---|---|
| ~~1~~ | ~~fix the objective~~ | **DONE** `304386a` |
| **2** | **re-take the β default against DESIGN's gates** | **Marcus** — `luc_scale` gets it to 0.55, gate 12 needs ≤0.50 |
| ~~3~~ | ~~`luc_scale`~~ | **DONE** `304386a` |
| ~~4~~ | ~~GLODAPv2~~ | **DONE** `3d923ef` — but see §4.1, it relocated the decision |
| **5** | **interhemispheric-gradient terms (CO₂ + δ¹³C)** | now priced: 0.84 ppm of gradient for 5.1 log-units |
| **5b** | **NEW — time-varying LUC hemispheric share**, from OSCAR regions | §2.2; do it *with* 5, since 5 is what would score it |
| **5c** | **NEW — sourced monthly seasonality for both emission inputs** (GFED; a monthly fossil product) | §2.2; ~8 % bias in `seas_amp_NH` |
| **6** | **re-take `sigma_d13c` and `LIK_EXCESS_C14_TARGET`** | §3.2 — σ_d13c now decides β |
| **7** | **saturating fertilisation**, to review §4.1's design target | **the highest-value structural item, now unblocked and untouched** |
| **8** | **THEN the refit**, ~18 parameters | blocked on 2, 5, 6, 7 |
| **9** | **pump**, on review §4.2's pre-registered ocean-sink test | targets now quantified (§2.1) |

**Still do NOT:** hand-tune stream weights; delete `excess_c14_ocean` or `d14c_intcal`; free
any land turnover parameter; **delete the `kz` bracket bare** (§4.1 now makes this worse,
not better, than the review thought); adopt LUC × 0.65 as a fixture; add `foss_scale`
before the refit shows `luc_scale` at a prior edge.

---

## 7. Non-obvious state

- **`calibration/output/recentre_beta_scan.rds` was overwritten** by re-running
  `diag_recentre_beta.R` at the current defaults; it was last written at β 0.60 / wood-only.
  Numbers quoted from the old file no longer correspond to it.
- **Every "at default parameters" number in this repo is at `gamma_enso` = 0**, i.e. ENSO
  OFF, which is `ccx_default_params()` — while `app/global.R:71` overrides it to the table's
  0.5. Documented and deliberate (`model.R:372–382`) but a live provenance hazard.
- **`ccx_loglik()` gained a 4th argument before `by_stream`.** Every existing caller passes
  `by_stream =` by name, so nothing broke — but a *positional* 4th argument now means `luc`.
- **`ccx_forcing_eluc_annual()`** is the way to get the model's own annual E_LUC; do not
  re-read GCB's column in anything that varies `luc_scale`.
- `data/obs_glodap_deep.rds` carries the σ candidates and the runaway value alongside the
  targets, so the §4.1 table can be regenerated without the 853 MB CSV.
- New diagnostics: `diag_stream_leverage.R`, `diag_luc_scale.R`, `diag_joos_beta_scan.R`,
  `diag_beta_luc_profile.R`, `diag_emission_scale_degeneracy.R`,
  `diag_emission_split_and_season.R`. Everything in 12d §§2–8 and §10 still applies.
- `diag_stream_leverage.R` no longer carries its hand-rolled "CORRECTED" land term.
  **Review numbers quoted as "corrected" (7.3 log-units on β) are at the OLD σ = 0.9**; the
  file now reports 24.3.

---

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-14b_review_items_1_3_4.md` and, behind it,
> `notes/review_2026-08-14_architecture.md` §§0 and 7. Items 1, 3 and 4 are done. **Three
> decisions are waiting (§4) and the first of them — the deep-Δ¹⁴C σ — inverted what 13i
> §A3 assumed, so do not delete the `kz` bracket on the old reasoning.** If the decisions
> are in hand, the highest-value remaining work is **item 7, the saturating fertilisation
> form**, to the design target in review §4.1: reproduce β ≈ 0.7's historical integral with
> β ≈ 0.5's marginal slope at 388 ppm. It is the one component with a demonstrated failure
> against an external benchmark, and `luc_scale` explicitly did **not** remove the need for
> it. Do not start the refit before it.
