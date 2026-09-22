# REVIEW 2026-09-22 — Marcus's comments on the CarboTope app, triaged

Source: `CarboTopecomments.9.22.26.docx` (received 09-22). ~45 comments over 7 sections.
This note triages every one, records what I MEASURED for the ones that assert a fact, and
separates what I can do from what needs a ruling. **Nothing is implemented in this note.**

Classes: **BUG** (the app is wrong) · **FALSE** (the app says something untrue) · **COPY**
(wording, Marcus's call, exact text often supplied) · **FEATURE** (new work) · **Q** (a
question I must answer, not edit) · **RULING** (a methodological choice).

---

## 0. THE HEADLINE — two comments are one bug, and it is a big one

> *"In 2024, why isn't the dashed line the sum of the three colored bars? … the gap between the
> grey line and the dashed line is much bigger than the negative green line."*
> *"I'm also concerned about the disparity between our land estimate and GCB's land estimate."*

**MEASURED at `hilda29l` over 1750–2024** (`partition_table()` + `app_build_forcing()`):

| | GtC |
|---|---|
| cumulative **fossil** | 504.7 |
| cumulative **land-use** | 237.6 |
| **cumulative total — what the dashed line draws** | **742.3** |
| atmosphere +314.2, land **−32.1**, ocean +221.5 → **sum of the three areas** | **503.6** |
| sum − cumulative **fossil** | **−1.05** (0.2 %) |
| sum − cumulative **total** | **−238.7** (32 %) |

⇒ **Carbon is conserved; the model is fine. The CHART is wrong.** Land-use emissions are an
**internal transfer** in this model — they move carbon out of the land pool into the air — so
they cannot also be an addition to the atmosphere+land+ocean system. Only **fossil** carbon is
new to that system, and against fossil the three areas close to **0.2 %**. The dashed line
counts LUC anyway, so it floats 237.6 GtC above a stack that can never reach it. **The gap IS
cumulative LUC, to within 1 GtC.**

**The same convention error is in the GCB bar chart**, and it is the whole of the land
disparity Marcus flagged. `plot_gcb_bars()` uses the raw pool change:

```r
ann$land_sink <- c(NA, diff(ann$land_C))          # app/R/plots.R -- RAW, includes the LUC outflow
```

while the gate that PASSES does the GCB-comparable thing (`dg_annual_sinks()`):

```r
land = stock(o$land_C) + el$eluc[match(yrs, el$year)]   # adds the LUC flux BACK
```

GCB's "land sink" is the **residual terrestrial sink, excluding land-use emissions**. So the
app's model bar is low by the LUC flux (~1 GtC/yr recently) against a GCB bar that excludes it
— **not like-for-like**, while GATE 7 scores land 3.09 vs GCB and passes. **The gate is right
and the app panel is wrong.**

**FIX (needs a ruling on presentation, not on physics — §6 R1).** Two coherent options:
- **(a)** plot the **GCB convention**: land area = `land_C` change **+ cumulative LUC**, dashed
  line stays **total** emissions. The three then sum to total, matching how everyone reads a
  carbon budget, and the GCB bars become like-for-like by the same change.
- **(b)** keep the raw pools and make the dashed line **cumulative fossil only**, relabelled.
  Honest, closes to 0.2 %, but it is not the budget anyone recognises and it makes the LUC
  story invisible.
**I recommend (a)** — it is the convention the gate already uses, it fixes both panels with one
change, and it makes Marcus's requested deforestation note (§2) natural to add.

---

## 1. Overall

| # | comment | class | note |
|---|---|---|---|
| O1 | Retitle to **CarboTope** | COPY | `APP_TITLE` is the one constant every label derives from. ⚠ The rename was recorded as "Marcus leaning" on 08-25 and never done; repo name and `ccx_` prefix can stay (handoff 08-25b §6). Decide the **deployed URL** at the same time — renaming after the post circulates is the expensive direction. |
| O2 | Simplify yellow-box text | COPY | The provenance banner. It currently carries stage + version + parameter counts + the "single best fit" sentence + the beta note + the reviewer pointer. I will cut it to the version, the one-line fit description, and the reviewer pointer, and move the rest into "Under the hood". |

## 2. The Keeling Curve

| # | comment | class | finding |
|---|---|---|---|
| K1 | *"Aren't CO₂ concentrations over time part of the calibration process? In which case we are tuning parameters to the shape of the curve"* | **FALSE — confirmed** | **Yes.** The objective's 26 rows include `co2_level_MLO`, `co2_level_SPO`, `co2_seasonal_MLO`, `co2_seasonal_SPO`, `co2_icecore`. The takeaway currently says *"Nothing here was tuned to the shape of this curve — the rise comes out of the carbon bookkeeping."* **That is untrue and must go.** |
| K2 | *"Aren't we giving the curve emissions, global temperatures, ENSO, and volcanic aerosols?"* | **FALSE — confirmed** | Yes: `gmst`, `sst_anom_*`, `enso`, `aod_*`, `e_foss_*`, `e_luc_*` are all **prescribed**. The takeaway's *"Given only emissions"* is wrong on four counts. Replacement must say what is prescribed and what is fitted. |
| K3 | Is there an **observed** MLO-vs-hemispheric-mean offset to compare `rep_dC` against? | **Q — open, and it is the right question** | I have not found one in-repo. This is the honest test of whether 3.5 ppm is defensible: candidates are NOAA's MBL reference surface (marine boundary layer, latitude-resolved — gives a zonal-mean vs station offset directly), or a flask-network zonal mean. ⚠ **Not verified — I have not checked what the MBL product's vertical/latitudinal scope is against our box definition.** Worth doing before the post: it converts card 1 from "we fitted an offset" to "we fitted an offset and here is the measured one". |
| K4 | Exact replacement text for the `see_card` box | COPY | Supplied verbatim; will use as given. |

## 3. Where does the carbon go

| # | comment | class | finding |
|---|---|---|---|
| W1 | Replace *"the only reason the number is not far worse"* with a factual report of each box | COPY | Agreed — and the takeaway is computed, so this is a template change only. |
| W2 | Note that deforestation **added** to emissions up to [DATE] and was a net sink after | **Q + COPY** | Needs the date FROM OUR OWN DRIVER, not recollection. Computable from `ccx_forcing_eluc_annual()` — the year `e_luc` turns negative, if it does. ⚠ **I have not computed it yet; I will not write a date I have not measured.** |
| W3 | Dashed line ≠ sum of bars | **BUG** | **§0.** |
| W4 | *"I wouldn't call [airborne fraction] the most useful summary"* — it is a function of how fast emissions change and how far sinks are from equilibrium | COPY | Correct, and the current gloss ("the single most useful summary") overclaims. Will reword to what it is and what it is not. |
| W5 | Numbers on the ocean bar are **cut off** | **BUG (rendering)** | `geom_text(vjust = -0.4)` with no headroom — the label leaves the panel. Fix: expand the y scale. |
| W6 | Land-vs-GCB disparity | **BUG** | **§0** — same convention error. |

## 4. What if…?

| # | comment | class | finding |
|---|---|---|---|
| C1 | Add **observations** — hard to see why ENSO matters until it improves model/obs fit | FEATURE | Agreed, and it is the cheapest high-value one here. |
| C2 | Add a **year-over-year CO₂ increase** chart | FEATURE | This is also 08-29 spec item ①b. It makes C1, C3 and card 4 all land. **Highest-value single addition in the review.** |
| C3 | *"switch it off and the wobbles go"* would make more sense with the YoY chart | COPY | Depends on C2. |
| C4 | Delete *"and, since 2026-09-01, in and out of the surface ocean"* | COPY | ⚠ Note this string is a **dated code comment leaking into user-facing copy** — worth a sweep for others. |
| C5 | *"the land takes up carbon for exactly one reason: plants grow faster when CO₂ is higher"* — **what about the annual cycle? That's sunlight-based, not CO₂-based** | **FALSE — he is right** | The seasonal NPP cycle is driven by a prescribed seasonal shape, not by CO₂. The info-box claim is true of the **secular sink** and false as stated. Must be narrowed to the trend. |
| C6 | Add **volcanic aerosol** on/off (and maybe temperature) | **FEATURE — and it corrects a related FALSE, see V2** | `gamma_diff = 0.25` is **live** (`ccx_default_params()`; not fitted, not pinned). The AOD→diffuse-light→NPP path **is running**. A switch is buildable. ⚠ Per spec §3a it needs **two** edits to be honest — zero `aod_*` AND remove the volcanic component from `gmst`/`sst_anom_*` — otherwise the thermal half keeps running. Temperature likewise. |

## 5. Isotope fingerprints

| # | comment | class | finding |
|---|---|---|---|
| I1 | We discuss north–south but only show the global match; add a hemisphere toggle like the Keeling tab | FEATURE | Straightforward, and it puts card 2's flaw where a reader can see it. Both hemispheres are already in `out`. |

## 6. Futures

| # | comment | class | finding |
|---|---|---|---|
| F1 | Reframe the FaIR paragraph (exact text supplied); delete the "honest reading" sentence | COPY | Will use verbatim. |
| F2 | Pulse lab: add a **second panel showing where the pulse carbon ends up** (% atmosphere/land/ocean) | FEATURE | Machinery exists (`dg_gateL_partition()`, already used by review card 5b). ⚠ **The label-vs-perturbation trap applies** ([[pulse_label_vs_perturb]], 2.8× apart at 100 yr): this panel answers "how much ADDED carbon is where", and must not be captioned as "where those molecules went". |
| F3 | Delete *"Running only the pulse case would confound it…"* | COPY | |

## 7. Known issues

| # | comment | class | finding |
|---|---|---|---|
| N1 | *"is credited"* → *"will be credited in the acknowledgements for the tool and any potential future publication"* | COPY | Verbatim. |
| N2 | Delete *"Each one is measured below by the running model, not quoted from a note."* | COPY | ⚠ That sentence is **true and load-bearing for me** (it is why the tab cannot go stale) but it is inside baseball for a reader. Deleting the sentence does not change the design. |
| N3 | **Should the `rep_dC` prior be centred at zero?** *"I wouldn't be surprised if there is supposed to be a station/hemisphere offset. Especially if the hemisphere is meant to represent surface CO₂ for ocean and land carbon sinks."* | **RULING — the sharpest comment in the review** | The prior is deliberately a **shrinkage** prior: `R/calibrate.R` says centring it on the measured offset "would tell the model the answer and then congratulate it for agreeing." **But Marcus's point is different and stronger** — if a hemispheric *surface* mean genuinely sits above a remote marine station, then **zero is not the physically neutral centre** and the 3.52σ strain is partly an artifact of centring. This is exactly K3: **measure the real offset, then decide.** Changing the prior centre is an **objective change** (restamps every mode) — §4.1 of the freeze record. |
| N4 | *"What carrier would you expect to close it?"* → *"What mechanism might help close it?"* | COPY | Verbatim. |
| N5 | Do we expect isotope differences between MLO/SPO and **hemispheric averages**? | **Q** | Same class as K3/N3, for δ¹³C. `grad_off_d13c` is the δ¹³C analogue and card 2 is scored **net** of it. Honest answer: yes, we should expect one, and we have not measured it. |
| N6 | *"one ocean column per hemisphere, no interhemispheric deep exchange"* — **"Do we have no ocean exchange at all? And didn't we add tropical boxes?"** | **Partly FALSE — needs care** | The phrase is about **interhemispheric deep** exchange specifically, but it reads as "no ocean circulation", which is wrong: `hilda_csl3` carries HILDA cold surface/deep boxes per hemisphere, a biological pump in both columns, and the **layer-3 Niño3.4 return limb**. The **tropical box (`hilda_tr`) and the equatorial cell were explored and NOT adopted** — that arc is closed. Text must say precisely what exists and what does not. |
| N7 | Commonalities between years the model over/undershoots the growth rate? | **FEATURE (analysis)** | A real diagnostic, and it would strengthen card 4. Candidates: volcanic years, strong El Niño/La Niña, the 1990s. Not yet run. |
| N8 | *"variance beyond ENSO — volcanic and land-side"* with **"no mechanism here"** — *"I thought we also had volcanic aerosol diffusion?"* | **FALSE — my error** | **He is right.** `gamma_diff = 0.25` is live. My card-4 text denies a mechanism the model has. Must be corrected to: the volcanic path exists (diffuse light → NPP) and the variance is still short — which is a **more interesting** statement, not a weaker one. |
| N9 | Reword the Joos comparison (exact text supplied) | COPY | Verbatim. ⚠ His phrasing *"we do not calibrate to match future projections"* is right and better than mine. |
| N10 | *"named mechanism"* → *"physical mechanism"* / *"replacing a shim with a physical mechanism"* | COPY | Verbatim. |
| N11 | Delete *"which is the most that naming buys: a named stand-in is still a stand-in"* | COPY | |
| N12 | **How do the three named shims relate to the 9 parameters listed below?** | **BUG (inconsistency) — he caught a real one** | They are **two different lists** and the card presents them as one. The table lists the **9 PINS** (`ent_seas_amp_SH`, `w_eq`, `gamma_eq`, `pump_export`, `w_vent`, `gamma_vent`, `w_thc`, `gamma_enso_ocn_NH/SH`) — names **held at a value**. The prose names the **SHIMS** (`rep_dC`, `grad_off_d13c`, `sst_seas_amp_NH/SH`) — names **fitted freely as stand-ins**. Only `ent_seas_amp_SH` and the ENSO pair are in both. **The card must show both lists, labelled, and say how they differ.** |

## 8. Under the hood

| # | comment | class | finding |
|---|---|---|---|
| U1 | **Why are many parameters NA in name and units?** | **BUG — confirmed** | `output$h_params` maps `CCX_PARAM_NAMES` (**38** names) through a hand-written `desc`/`unit` list that still describes the **~22-name era** — it carries retired names (`beta`, `sigma_co2`) and lacks every name added since (the HILDA boxes, the pump, the seasonal ML, the limb). `unname(desc[nm])` yields **NA** for all of those. A hand-maintained table against a moving parameter set: the same decoupling class as the constants ledger. |
| U2 | IGCC temperature is a **driver**, not a calibration target; make a "what drives the model" box (IGCC T, ENSO, emissions, volcanic AOD — and land-use change?) | **FALSE + FEATURE** | Correct: `h_data` lists IGCC temperature under "What it is fitted to", which is wrong — it is prescribed forcing. **Yes, historical land-use change is a driver too** (`e_luc_*`, scaled by the fitted `luc_scale`). Two boxes needed. |
| U3 | Delete "Marron Institute" affiliation | COPY | ⚠ **Conflicts with a standing global rule** (`~/.claude/CLAUDE.md`: affiliation is "Marcus C. Sarofim (NYU Marron Institute)" only). **This instruction is newer and specific to this artifact, so it wins here** — but flagging it because it may mean the standing rule should change, or it may mean "drop it on this page only". |
| U4 | *"It carries all three carbon isotopes"* → *"All exchanges include all three isotopes"*; delete *"which is what lets the isotope tab work"* | COPY | Verbatim. |
| U5 | *"No ocean circulation — the deep ocean is reached by diffusion only"* — is that still true? high-latitude/mixed-layer exchange? the tropical box? how do the hemispheres interact? | **FALSE — stale text** | Same as N6, and worse here because it is stated flatly. As of `hilda_csl3`: vertical diffusion **plus** HILDA cold surface/deep boxes per hemisphere, a biological pump, and an ENSO-driven layer-3 upwelling limb. Hemispheres interact through the atmosphere (`tau_ex`) — **not** through the deep ocean, which is the real limitation and the honest sentence. The tropical box was **explored and not adopted**. |
| U6 | Lead with the **goal** before the structure: *"a carbon cycle model able to duplicate observed hemispheric, seasonal and isotopic patterns, integrated into a pedagogical framework"* | COPY | Verbatim; it is also a better statement of DESIGN §1 than what is on the page. |

---

## 8b. STATUS as of 2026-09-22 (o) — Tier 1 and Tier 2 are DONE

**DONE and verified in a browser against the running app** (CHANGELOG 09-22 (o)):
all of **Tier 1** — §0/W3/W6/W5 and R1 in (n); K1, K2, N8, N12, U1, U2, U5/N6, C5 in (o) — and
all of **Tier 2** except O1: O2, K4, W1, W4, C4, F1, F3, N1, N2, N4, N9, N10, N11, U3, U4, U6.

**Two of the Tier-1 items were not copy problems and did not get copy fixes.** U1 (the NA parameter
table) and N12 (pins-vs-shims) were both hand-maintained tables drifting away from a moving model,
so each now has a **gated** table — `app_validate_param_meta()` in `app/R/params_meta.R` and
`rv_validate_shims()` in `app/R/review.R`, both mutation-tested. Rewriting either by hand would
have bought a year at most.

**N8 carries a measurement it did not have when this note was written.** `gamma_diff` = 0.25 is
live, and a matched pair (0.25 vs 0, same spin-up function, same forcing) prices the
AOD → diffuse-light → NPP path at **1.53 ppm** at its largest in 1991–95 and **−0.73 ppm** at 2024.

**STILL OPEN:** **O1/R3** (the rename — left last on purpose: it decides the deployed URL),
**Tier 3** (C2 first, then F2, I1, C6, N7, W2 — awaiting Marcus's priority order), and **R2 /
K3 / N5**, which need the NOAA MBL **zonal** pull described in Appendix A §A4.

**R4 is RULED AND PROPAGATED:** the affiliation is off the app, and the standing rule in
`~/.claude/CLAUDE.md` now carries the professional/informal split rather than a single form.

---

## 9. What I propose to do, in order

**Tier 1 — the app is WRONG (do regardless).**
1. §0 the budget convention — partition chart + GCB bars (**needs R1 below**).
2. K1/K2 the Keeling takeaway ("nothing was tuned", "given only emissions").
3. N8 card 4's denial of the volcanic mechanism (my error).
4. N12 card 8's pins-vs-shims conflation.
5. U1 the NA parameter table.
6. U2/U5/N6 drivers-vs-targets, and the stale "no ocean circulation".
7. C5 the "exactly one reason" land claim.
8. W5 the clipped bar labels.

**Tier 2 — copy, all verbatim or near (O1, O2, K4, W1, W4, C4, F1, F3, N1, N2, N4, N9, N10, N11, U3, U4, U6).**

**Tier 3 — features, in Marcus's priority order.** C2 (YoY chart) first: it serves C1, C3 and card 4 at once. Then F2 (pulse partition panel — machinery exists), I1 (isotope hemisphere toggle), C6 (volcano/temperature switches — needs the GMST decomposition, the largest item here), N7 (over/undershoot analysis), W2 (the LUC sign-change date).

**Tier 4 — measurement and rulings, before the post if possible.** K3/N3/N5: measure the real station-vs-hemispheric-mean offset for CO₂ and δ¹³C. This is one investigation that bears on three comments and could change an objective row.

## 10. Rulings I need
- **R1 — the budget convention (§0).** (a) GCB convention (add LUC back to land; dashed stays total) — **recommended**; or (b) dashed line becomes fossil-only.
- **R2 — `rep_dC`'s prior centre (N3).** Measure first (K3), then decide. **An objective change**: it restamps every mode and is on the freeze record's OUT list. Not to be done casually before a review.
- **R3 — the rename (O1).** App title only, or repo/URL too? Decide before the post.
- **R4 — affiliation (U3).** Drop "NYU Marron Institute" here only, or change the standing rule?


---

# APPENDIX A (2026-09-22) — the `rep_dC` research: FIRST RESULT, and it is a hard one

Marcus asked for this after R1–R4. **Preliminary but strong: the fitted offset is the wrong SIGN
and ~4× the MAGNITUDE of the observed station-vs-mean offset, and its hemispheric ORDERING is
backwards.** Below, what is MEASURED, what is ESTIMATED, and what is still open.

## A1. What the parameter is (measured, from the code)
- The box is a **mass-weighted WHOLE-ATMOSPHERE hemispheric mean** — `gtc_per_ppm_hemi =
  GtC_PER_PPM / 2`, *"each hemisphere holds half the atmosphere"* (`R/model.R:3874`). Not a
  surface mean. The continental-boundary-layer argument in the likelihood's comments is weak
  against a whole-column mean: the BL is roughly a tenth of atmospheric mass.
- `rep_dC` is applied **identically to both stations** (`R/likelihood.R`, the
  `for (st in c("MLO","SPO"))` loop): one common-mode offset for two hemispheres.
- `rep_dC` and `grad_off_co2` **jointly** define per-hemisphere offsets. With
  `station = box − rep_dC` and `obs_grad = box_grad + grad_off_co2`:
  `off_SH − off_NH = grad_off_co2`. At the canonical → **off_NH ≈ +3.41, off_SH ≈ +3.62 ppm**,
  confirmed by the direct residuals (**MLO +3.37, SPO +3.69**).
- **Flat in time** (MLO +3.40 / +3.53 / +3.30 by era; SPO +3.58 / +3.69 / +3.76) ⇒ it is NOT
  absorbing a growth or budget drift. A genuine constant.
- **Worth 1306.9 log-units** at the canonical with one coordinate moved (no refit ⇒ an UPPER
  bound). ⚠ **More than a third is ISOTOPIC** (`d13c_level_MLO` −361.0, `d13c_level_SPO` −163.3
  vs `co2_level_SPO` −400.8, `co2_level_MLO` −381.8), because the parameter is tied across
  species by mass balance. **R2 cannot be decided as a CO₂-only question.**

## A2. What the observations say (MEASURED locally, re-derived — not transcribed)
NOAA GML annual means, **global MBL-surface mean − Mauna Loa**, from
`co2_annmean_gl.txt` and `co2_annmean_mlo.txt` (fetched 09-22, ~6 KB; re-derived in R):

| 1980 | 1990 | 2000 | 2010 | 2020 | 2023 | 2024 |
|---|---|---|---|---|---|---|
| +0.15 | −0.39 | −0.75 | −1.35 | −1.77 | −1.73 | −1.82 |

**mean 1980–2020 = −0.88 ppm**; 2001–2020 = −1.19; **negative in every year since 1981.**
Independently corroborated by **Wu et al. (2024), ACP 24:1249–1264, doi:10.5194/acp-24-1249-2024**,
which quotes global − MLO = **−0.46 to −0.88 ppm** (1980–2020) and global − SPO = **+1.91 to
+2.24 ppm**, across analysis methods, and finds the networks agree on the **growth rate** to
<0.023 ppm/yr — i.e. the disagreement is in the LEVEL, which is exactly `rep_dC`'s axis.

## A3. The confrontation
| | NH | SH |
|---|---|---|
| **model needs** (`rep_dC` ± `grad_off_co2`/2) | **+3.41** | **+3.62** |
| observed, hemispheric — ⚠ **ESTIMATED, see A4** | ~+0.9 | ~+0.3 |
| observed, global (measured) | −0.88 vs MLO | +1.9 to +2.2 vs SPO |

1. **Magnitude:** the model needs ~3–4× more offset than the observations support.
2. **Sign:** the marine-surface global mean sits **below** MLO; `rep_dC` needs the box **above**
   it. Nothing observational found pushes a hemispheric mean +3.5 ppm above Mauna Loa.
3. **Ordering is backwards:** observations make the NH offset the larger one (MLO is south of
   the NH centroid, in a hemisphere with a steep meridional gradient); the model has
   **SH ≥ NH**. A single shared `rep_dC` is mis-specified by construction — the two hemispheres
   do not have the same offset, and one of them does not even have the same sign at global scale.
4. **The surface → mass-weighted correction makes it worse, not better.** Stratospheric CO₂ lags
   the surface (mean age ~5 yr; **Andrews et al. 2001, doi:10.1029/2001JD000465**), so a
   mass-weighted mean sits **below** a surface mean. That correction is NEGATIVE.

## A4. ⚠ What is NOT established — do not quote A3's middle row as measured
- The **hemispheric** offsets in A3 are **my arithmetic**, not a measurement: global−station
  shifted by half an assumed ~3.5 ppm interhemispheric gradient. **The real measurement is the
  NOAA MBL Reference zonal product**, which offers NH and SH means directly
  (`gml.noaa.gov/ccgg/mbl/data.php`, Zonal → Northern/Southern Hemisphere, 1979–2025, text,
  ~100 KB). ⚠ Its download form is AJAX and the direct URL was not recoverable from the served
  HTML — it needs a browser session. **That is the next step, and it is cheap.**
- **No published ppm value exists** for (hemispheric mass-weighted mean − MLO/SPO), nor for
  (MBL surface mean − mass-weighted whole-atmosphere mean). Searched and not found; it has to be
  computed. Pandey et al. (2024), AGU Advances, doi:10.1029/2023AV001145 frames exactly this
  quantity but for **growth rates, not levels** (and was paywalled at 403).
- **Circularity, which matters for which product to use next:** NOAA's global mean **EXCLUDES
  Mauna Loa** (altitude site) — so MBL-mean − MLO is genuinely independent — but **INCLUDES South
  Pole**, so the SH side is partly circular. CarbonTracker assimilates **both** MLO and SPO
  (nighttime selection at mountain-top sites) and is fully circular here; CAMS EGG4 assimilates
  only satellite XCO₂ and is the least circular 3-D option, but carries its own ±10 ppm
  near-surface bias — larger than the effect being measured.
- A defensible **σ floor** for a station-representation term: **~0.2 ppm**, the inter-network
  spread on a station difference (**Francey et al. 2019, ACP 19:14741**, monthly sd 0.25 / 0.23 /
  0.16 ppm for MLO−CGO / MLO−SPO / CGO−SPO). That is **5× tighter than the current 1.0 ppm prior**.

## A5. Where this points (NOT a recommendation — R2 is Marcus's, and it is an objective change)
The evidence so far says `rep_dC` is **not** a representation offset: it is a constant, nearly
equal-in-both-hemispheres, ~3.5 ppm **level bias** in modern airborne CO₂ against an ice-core
anchored preindustrial (~7.4 GtC of excess airborne carbon). Re-centring its prior would not fix
that; it would move where the bias is booked. ⚠ And because a third of its value is isotopic,
any change must be judged on **both** species at once. **Next step is A4's MBL zonal pull** — it
converts A3's middle row from arithmetic into measurement, and it is an hour's work.

---

# APPENDIX B (2026-09-22 o) — the MBL ZONAL pull. **A4's middle row is now MEASUREMENT, and TWO OF A3's THREE CLAIMED FAILURES DO NOT SURVIVE IT.**

A4 named this pull as the step that would convert A3's hemispheric row from arithmetic into
measurement, and warned *"do not quote A3's middle row as measured."* That warning was right.
Reproducible from `data-raw/download_data.R` (`fetch_mbl_zonal()`, three MANIFEST rows) and
computed by **`calibration/diag_rep_dc_mbl_zonal.R`**.

⚠ **A4 also said the download "needs a browser session." It does not.** The form's Submit is
JavaScript, but it GETs a plain `ghg.php?...` endpoint that generates a `tmp/` file and returns
a fragment linking to it. Two requests, no session. The browser was needed only to READ the
endpoint out of the page once.

## B1. What was measured
NOAA MBL **zonal** reference, sine-latitude (area) weighted, 48/yr 1979–2025
(**Lan, Tans, Thoning & NOAA GML 2024, doi:10.15138/DVNP-F961**, X2019 scale), minus the repo's
**own** station series — the ones the likelihood scores `rep_dC` against — **matched month by
month**. Not annual means: SPO's flask record carries 12 months in only 36 of its 48 years, so an
annual comparison either truncates at 2020 or aliases a partial year's seasonal cycle into the
level. `approx()` without `rule = 2`, so a month outside the reference window is dropped, never
extrapolated.

| MBL mean − station | mean (ppm) | sd(ann) | positive in | trend (ppm/decade) |
|---|---|---|---|---|
| **NH − MLO** | **+0.738** | 0.282 | **47/47 yr** | **−0.105 ± 0.026** |
| **SH − SPO** | **+0.814** | 0.209 | **46/46 yr** | −0.012 ± 0.023 |
| global − MLO | −0.639 | 0.526 | 5/47 yr | −0.348 ± 0.024 |
| global − SPO | +2.165 | 0.529 | 46/46 yr | +0.281 ± 0.042 |

**VALIDATED, not trusted.** The two quantities **Wu et al. (2024)** report independently both land
inside their published ranges: global−MLO **−0.639** in [−0.88, −0.46]; global−SPO **+2.165** in
[+1.91, +2.24]. The gate is in the diagnostic and prints INSIDE/OUTSIDE.

## B2. The confrontation, with A3's claims marked
| | NH | SH | A3 said | now |
|---|---|---|---|---|
| model needs (`rep_dC` ∓ `grad_off_co2`/2) | **+3.41** | **+3.62** | | |
| **MBL zonal, MEASURED** | **+0.74** | **+0.81** | ~+0.9 / ~+0.3 (arithmetic) | measured |
| ratio | **4.6×** | **4.5×** | "~3–4× too large" | **STANDS, and sharper** |
| sign | + | + | **"the SIGN is wrong"** | ⛔ **RETRACTED** |
| ordering | SH > NH | SH > NH | **"ordering is backwards"** | ⛔ **RETRACTED** |

- ⛔ **THE SIGN CLAIM IS RETRACTED, and the way it went wrong is the standing like-for-like rule.**
  A3 read the sign off **global − MLO** (−0.88): a *global* mean against a *northern* station. That
  pair is not like-for-like — the global mean is dragged down by the southern hemisphere, and the
  comparison the model makes is hemisphere-against-its-own-station. Measured properly, **both
  hemispheric means sit ABOVE their station, in every one of 46–47 years.** `rep_dC`'s sign is the
  physically expected one.
- ⛔ **THE ORDERING CLAIM IS RETRACTED.** A3's ~+0.9 NH / ~+0.3 SH was the global number shifted by
  half an *assumed* 3.5 ppm gradient — A4 flagged it as arithmetic and it was wrong. Measured,
  **SH (+0.81) > NH (+0.74)**, which is the model's own ordering (3.62 > 3.41).
- ✅ **THE MAGNITUDE CLAIM SURVIVES and is now the whole of the case: ~4.5×.**
- **NEW, not in A3:** the NH offset **declines** at −0.105 ± 0.026 ppm/decade (4σ) while the model's
  is a constant. ~0.5 ppm of drift over the record — small against the 2.7 ppm discrepancy, real.

## B3. What it says about R2 — **a ruling input, not a recommendation**
- Re-centring the prior on the measured offset (≈ **+0.78 ppm**) moves the fitted +3.515 from
  **z +3.52 to z +2.74**: it **relieves 22 % of the strain and relabels the other 78 %.**
  **+2.74 ppm ≈ 5.8 GtC of airborne carbon still unexplained.** Re-centring does not dissolve the
  finding; it makes the residue smaller and better-founded.
- ⚠ **THE WIDTH IS THE BIGGER QUESTION THAN THE CENTRE.** A station-representation term's defensible
  σ floor is **~0.20 ppm** (Francey et al. 2019, ACP 19:14741) — **5× tighter than today's 1.0 ppm.**
  At that width the same fitted value sits at **z +13.7**. Today's prior is wide enough to admit a
  structural error wearing a representation term's clothes, which is exactly what `R/calibrate.R`
  says the prior exists to resist.
- ⛔ **STILL CANNOT BE DECIDED ON CO₂ ALONE.** `rep_dC` is tied across species by mass balance and
  **more than a third of its 1306.9 log-units is isotopic** (A1). A CO₂-justified re-centring moves
  the δ¹³C levels too.
- ⚠ **CIRCULARITY IS ASYMMETRIC and the SH row is the weaker one.** NOAA's MBL reference **excludes
  Mauna Loa** (altitude site) — so NH−MLO is genuinely independent — but **includes South Pole**.
- ⚠ **SURFACE vs MASS-WEIGHTED IS STILL NOT MEASURED, and it cuts both ways.** The MBL product is a
  marine *surface* mean; the model's box is converted as a *whole-atmosphere* mean
  (`GtC_PER_PPM/2`). Stratospheric lag (mean age ~5 yr, Andrews et al. 2001) puts a mass-weighted
  mean **below** a surface mean, which would widen the gap. ⚠ **But `R/model.R` gives each
  hemisphere one well-mixed troposphere and NO stratosphere**, so what the box physically is may be
  closer to a tropospheric mean than its own unit conversion claims. That is a modelling question,
  not a measurement, and **nothing here settles it.**

⛔ **Any change to this prior is an OBJECTIVE change** — freeze record §4.1: a ruling, then a restamp
of every mode. **Not taken.**
