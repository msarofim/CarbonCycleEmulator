# PLAN 2026-09-22 — the PRODUCT at `v1.0-hilda29l`: beta-app cut, write-up structure, figure set, red-flag ledger

Proposal for Marcus's direction. Numbers are the 09-21 scorecard
(`outputs/diagnostics/whole_model_scorecard_20260921_hilda29l.log`) and the freeze record
(`notes/assessment_2026-09-21_product_ready.md`) unless cited otherwise. **No prose for the
write-up here** — Marcus drafts the text; this note is structure, figures, tables, numbers.
Nothing in it is built yet: `outputs/figures/` does not exist, and no figure-producing script
exists (the `calibration/diag_*.R` family writes logs and `.rds`, not plots).

## 0. Two products, one freeze; what "beta" means for each

| product | the frozen thing it exposes | what "beta" labels |
|---|---|---|
| **the app** | the canonical run, live (`app/global.R` → `ccx_mode_file()`) | a single MAP fit, no bands; four named gate failures the app's own panels can display |
| **the write-up** | the same run + the scorecard + the freeze record | the same four, stated as the design's edge, not tuned away |

**Beta = the model's numbers are final at this tag; the DISCLOSURE of its flaws is what is still
being designed.** That is the honest framing and it is also what lets the red-flag ledger (§4)
be a product decision rather than a model reopening.

## 1. The app — where it stands against its own spec

The app that exists is the **08-11 six** (`app/ui.R`): The Keeling Curve · Where does the carbon
go? · What if…? · Isotope fingerprints · Futures (Scenarios / Build your own / Pulse lab) · Under
the hood. It runs the canonical on the periodic spinup (the 09-21 i bug fixed; CO₂ 2024 = 424.37
= the objective's run). Provenance banner non-dismissible; takeaways computed, not written.

The **08-29 six-tab spec** (`notes/spec_2026-08-29_app_six_tabs.md`) was recorded and then the
model arcs took the next three weeks. **None of its new content is built:**

| spec tab | exists? | what is missing | size |
|---|---|---|---|
| ① historic CO₂ with the four checkboxes (ENSO / volcanoes / warming / emissions) | Keeling tab exists; **no checkboxes, no YoY panel, no input panels** | the GMST decomposition (Foster–Rahmstorf regression on GMST **and** HadSST4 — spec §3, §3a-bis: two edits per driver, three series); a "no emissions" switch (`CCX_MECHANISMS` has sinks only) | **major** |
| ② isotopes | exists | light re-cut only | light |
| ③ futures vs FaIR and MAGICC on van Vuuren | SSP futures exist (FaIR-derived climate module) | van Vuuren inputs; FaIR + MAGICC comparison series — **none in `data/`**; they cross from FaIRtoFrEDI / SLR-RFF-BRICK as provenance-stamped CSVs | **major** (data plumbing, not physics) |
| ④ pulses with a tracer: total CO₂ / tracer fraction by box / added CO₂ by box | Pulse lab exists (perturbation only) | the ¹⁴C-label run beside it; the two must not share a caption (2.8× at 100 yr, [[pulse_label_vs_perturb]]) | moderate — machinery exists (`diag_pulse_partition.R`, `diag_pedagogy.R`) |
| ⑤ hemispheric | — | was DEFERRED "until the component is fixed" (spec §3b). **The freeze says it will not be fixed in this design** (gates D, GL structural) ⇒ the deferral condition can no longer be met; the tab is either dropped or built as the teaching point | decision |
| ⑥ ocean transport | Under the hood has the box diagram | presentation of the pump / HILDA boxes / the deep Δ¹⁴C profile (the +233 gain) | moderate |

**Decision A (the beta scope).** Two honest options; the third is not honest:
- **A1 — ship the existing six as beta 1.0 now**, re-cut for disclosure (§4's ledger wired into
  the tabs where each red is visible), and build the 08-29 content as beta 1.1+. Ships in days.
- **A2 — build the 08-29 spec first**, then ship as beta. ① alone is a regression build + a
  three-series decomposition with its own gate (components must sum to the observed series or
  the all-on state stops reproducing the calibrated run); ③ is cross-repo data plumbing.
  Weeks, not days.
- ~~A3 — ship without the disclosure re-cut~~: the Keeling panel already shows the model box
  ~4 ppm above MLO (`rep_dC` = +5.2 ppm; the banner mentions it), and no panel says the
  interannual variance is 0.59× or the δ¹³C gradient 2×. A reader who finds one of those
  before the app tells them has found a hidden flaw.

**Beta re-cut, either way (A1 or A2):**
1. Banner gains **"beta"** and the tag (`v1.0-hilda29l`); the "no bands" sentence stays.
2. A **"What it gets wrong"** block in Under the hood — the §4 ledger rows 1–4, each one
   sentence, each with the number; plus the five shims and the eleven provisional constants by
   count with a link. (The current "What it cannot do" list is scope, not flaws.)
3. **Per-tab disclosure where the flaw is on screen**: Keeling tab (the `rep_dC` offset, already
   in the banner — decide whether to draw the offset; [[ccx_app_beta_blockers]] says that is a
   display-convention decision, not a fix); Isotope tab (the MLO−SPO δ¹³C gradient is 2× — the
   panel plots MLO and SPO, so it SHOWS this); What-if tab, ENSO switch ("a sensitivity, not a
   reconstruction": slope 0.89×, variance 0.59×).
4. **Timed real deploy** before announcing — startup measured 2.8 min under load, 73 s idle
   on an M4 (DEPLOY.md's "~20 s" is a compile-cached number); shinyapps.io has a startup
   timeout.
5. `app/DEPLOY.md` and README `Status` gain the beta label; nothing else in them is stale.

## 2. The write-up — structure

Venue is Marcus's call; this structure fits a model-description paper (GMD-style) and shrinks
to a pedagogical-tool note by dropping §4–5 into a supplement. **Lane marks:** ✍ = Marcus
drafts; ⚙ = Claude's lane (methods, figures, tables, numbers); ✍⚙ = Marcus drafts on a
Claude-supplied skeleton of numbers.

1. **Introduction** ✍ — the chain (DESIGN §1 goal 5: turnover vs adjustment; wobble vs rise);
   pedagogical, not an emulator.
2. **Model** ⚙ — structure `hilda_csl3` (two hemispheres; atmosphere; two-pool land; ocean column
   of a seasonal mixed layer over ten diffusive layers + HILDA cold surface/deep boxes + the
   biological pump + the layer-3 Niño3.4 return limb); isotopes ¹²C/¹³C/¹⁴C; forcings (all
   prescribed, monthly); numerics; the periodic spinup. Fig 1, Table 1.
3. **Calibration** ⚙ — the 26 data rows (Table 2), likelihood, priors, the 29 + 9 parameter
   set and why the 9 are held (Table 1), the MAP by dispersed multistart (24/24 converged, 17 on
   one basin), Hessian (PD, cond 2.46e5), reproduction gate (every registered mode reproduces
   its stored streams: canonical −6e−11, control +7e−8). Objective #13 frozen.
4. **Results — the chain, link by link** ✍⚙ — following the freeze record §2:
   4.1 the CO₂ record and its seasonal cycle (Fig 2); 4.2 the isotopes (Fig 3); 4.3 the sinks and
   their variability, the ENSO mechanism (Fig 4); 4.4 what emerges — the pulse (Fig 5).
5. **What the design cannot do** ✍⚙ — the four reds as a section, not a footnote (Fig 6,
   Table 3): the hemispheric δ¹³C structure (D, GL), the interannual variance (V), the
   AIC accounting (the seasonal mixed layer kept over a fit); τ_iso over-determined by ~15 %
   (freeze record §3); the three sentences the arcs left (handoff (k) §3).
6. **The app** ⚙ — what it shows, what it computes live, what it does not show (bands).
7. **Discussion / what would reopen it** ✍ — freeze record §6.
- **Supplement** ⚙ — gate ledger in full (Table S1), constants ledger (Table S2), free-parent
  comparison (Table S3), multistart convergence (Fig S1), the seasonal mixed layer's content
  (Fig S2), the label-vs-perturbation pair (Fig S3 — or promote into Fig 5).

## 3. The figure set and the tables — each with its source and its status

Every panel below is **computable from the canonical mode file + `data/*.rds` + the scorecard
`.rds`**; none exists as a plot. Column "source" names what the script reads; "build" is my
estimate of what has to be written. Labels derive from named constants (the tag, the mode name,
the objective number, the scorecard date) — one `fig_constants.R` shared by every figure.

### Main figures

| # | panels | the number it carries | source | build |
|---|---|---|---|---|
| **1 Schematic** | box diagram, arrows labelled by the model's own PI flux trace | ~72 GtC/yr photosynthesis; ~95 each way air–sea; against ~11 emissions (memory `ccx_shiny_app`; re-measure at `hilda29l`) | `R/fluxes.R`; the app's `h_diagram` | re-draw the app's diagram as a print figure |
| **2 The CO₂ record** | (a) monthly model vs MLO/SPO + ice core 1750–2024; (b) annual growth rate model vs obs; (c) seasonal-cycle amplitude by station over time | CO₂ 2024 424.37; `co2_seasonal` +68.9 on the likelihood; NH cycle carried by `h_ml` 57.3 ± 3.7 m | `obs_co2_monthly.rds`, `obs_icecore.rds`, the canonical run | new script; (a) mirrors `plot_keeling()` |
| **3 Isotopes** | (a) δ¹³C MLO/SPO 1980–2024 (Suess); (b) bomb Δ¹⁴C NH/SH 1950–2024; (c) the deep Δ¹⁴C profile vs GLODAP, `hilda29l` vs the column control `ent26` | (c) is the HILDA boxes' whole gain: `d14c_profile` −8.8 vs −241.6 (+233) | `obs_d13c_monthly.rds`, `obs_d14c_zonal.rds`, `obs_glodap_deep/intermediate.rds` | new script; (c) needs `ent26` run by path |
| **4 The sinks and ENSO** | (a) land and ocean sinks 1960–2024 model vs GCB with GCB's σ; (b) annual ocean-uptake anomaly vs Niño3.4, model full vs solubility-only vs GCB, slopes drawn | GATE 7 ocean 3.13 / land 3.09 GtC/yr (2010s); slope +0.1027 ± 0.042 vs GCB +0.1153 ± 0.025 (0.89×); solubility-only −0.18; `w_enso_l2` 13.71 ± 2.13 Sv in Meinen's [14, 25] | `gcb_budget.rds`, `forcing_enso.rds`, `diag_enso_model_vs_obs.R`'s estimator (09-04g) | new script over the existing estimator |
| **5 What emerges** | (a) IRF 0–1000 yr, `hilda29l` with the Joos 2013 multi-model band; (b) partition land/ocean/air at 100 and 1000 yr vs Joos's band; (c) the ¹⁴C LABEL beside the mass PERTURBATION from the same state (separate captions) | IRF(20/100/300) 0.472 / 0.283 / 0.205 vs 0.596 / 0.409 / 0.322; 1000-yr partition 34 / 48 / 18 % vs 16 ± 14 / 59 ± 12 / 25 ± 9 (z +1.25 / −0.89 / −0.76); label vs perturbation 2.8× at 100 yr | `R/joos_irf.R`, `diag_joos_irf.R`, `diag_pulse_partition.R`, `diag_pedagogy.R` | new script over existing machinery; Joos band from `joos_irf.R` (⚠ the "389 ppm background" is from recollection — verify against the paper before the caption) |
| **6 The edge of the design** | (a) MLO−SPO δ¹³C gradient, model vs obs, with the CO₂ gradient beside it (right) — the 2× as a constant offset; (b) hemispheric air-sea δ¹³C disequilibrium NH/SH, model ML/HS vs the GLODAP bottles; (c) detrended annual CO₂ growth-rate sd, model vs obs | GL 2.00× (−0.1336 vs −0.0668 ± 0.0030 ‰), CO₂ 0.91×; D asym +0.094 vs +0.286 ± 0.029 (NH +1.03 vs +1.28); V 0.548 vs 0.933 ± 0.084 | scorecard §2; `obs_hemi_diseq.rds`; `diag_gateV_variability_drivers.R` | new script; the three reds in one figure so §5 has one anchor |
| **7 The seasonal mixed layer** *(or S2)* | NH seasonal cycle and seasonal δ¹³C at MLO: `hilda29l` vs the seas_ml-0 control `hilda31pe`, with obs | the last 2.6 log-units on `d13c_seasonal_SPO` / `ocean_grad_alk` / `co2_seasonal_MLO`; ΔAIC +4.18 | both mode files; `obs_seasonal_clim.rds` | new script; two runs |

### Tables

| # | content | source | build |
|---|---|---|---|
| **1 Parameters** | 29 fitted: name, meaning, unit, prior, MAP ± Hessian se, |z| to prior (flag the four > 2: `q10` −2.41, `kz_deep_frac` −2.83, `pump_hs_gcm2` +2.06, `rep_dC` +3.52); the 9 pins with the reason each is held | `mode_fit_pumpN.rds` + `_hess.rds`; scorecard §5 | script; the app's `h_params` labels are a start |
| **2 Data streams** | the 26 rows: observable, product + vintage, window, σ (and its inflation), likelihood at the canonical by group | scorecard §1; `DATA.md`; `R/likelihood.R` | script over scorecard `.rds` + a hand-maintained provenance column from `DATA.md` |
| **3 Gate ledger (main)** | gate, what it tests, bound + provenance, verdict at `hilda29l`, class (structural / accounting) | scorecard §2; freeze record §1 table; `INDEX_ccx_gates` | hand-built from the scorecard; small |
| **4 Comparisons, not gates** | IRF at 20/100/300; partition at 100/1000 vs Joos | scorecard §4 | trivial |
| **S1 Gate ledger (full)** | Table 3 for all three arms (`ent26`, `hilda31pe`, `hilda29l`) | scorecard §2 | trivial |
| **S2 Constants** | every constant: value, source, status (cited / provisional) — the eleven provisional named with why | `R/constants.R`, `tests/test-constants.R` ledger | script |
| **S3 The free parent** | `hilda32f` vs `hilda29l` vs `hilda31pe`: names, likelihood, logpost, ΔAIC, what the three pins cost by row (5.70: `gcb_ocean_sink` 1.83, `d13c_seasonal_SPO` 1.73, `co2_icecore` 1.00, `ocean_grad_alk` 0.98) | `diag_free_parent_csl3_read.R`; CHANGELOG (j) | trivial |

### Supplement figures
- **S1 multistart** — 24 starts' logposts by basin (17 on one), the incumbent marked.
  Source: the wave outdir (`refit_20260922_hilda32f_…`, logs in the tree).
- **S3 label vs perturbation** — if not promoted into Fig 5c.

### Build order (if approved)
`fig_constants.R` → Table 1 + Table 2 (they check the mode file and scorecard can be read as I
think) → Fig 2, 3, 4 (the chain, all from existing runs) → Fig 5 (pulse machinery) → Fig 6 →
Fig 7 → supplement. Each script writes `outputs/figures/<name>_<tag>.{pdf,png}` and a
`.csv` of the plotted numbers with a provenance column (tag, mode, objective, scorecard date).

## 4. The red-flag ledger — for the beta advice

Every remaining red, its class, and the disclosure options. **This is the table to ask about.**
Fix options are listed only where the freeze record names one; "reopen" means an objective or
structure change that re-runs every mode.

| # | red | number | class | where a reader meets it | disclosure options |
|---|---|---|---|---|---|
| 1 | GATE D — hemispheric air-sea δ¹³C disequilibrium asymmetry | +0.094 vs +0.286 ± 0.029 (z −6.60); NH-side deficit | structural (one column per hemisphere; no interhemispheric deep exchange) | write-up §5 only — the app has no panel that shows it | (a) state in §5 + Fig 6b; (b) also a sentence in the app's "What it gets wrong"; (c) reopen: the shared deep reservoir gated by a hemisphere-split bottom-Δ¹⁴C row — a NEW model (handoff (e) §6.2) |
| 2 | GATE GL / H — the MLO−SPO δ¹³C gradient | 2.00× obs, a constant −0.0668 ‰ offset; CO₂ gradient right (0.91×); scored NET of `grad_off_d13c` | structural (needs +64 GtC‰/yr NH−SH isoflux, no carrier) | **the Isotope tab plots MLO and SPO δ¹³C — the 2× is ON SCREEN** | (a) caption it on the tab; (b) plot the residual explicitly as a teaching point (what an isoflux the model lacks would look like); (c) hide SPO on that panel — ⚠ that is concealment, listed to reject it |
| 3 | GATE V — interannual variance | sd 0.548 vs 0.933 ± 0.084 (0.59×); the SLOPE is 0.89× | structural (no ocean-side mechanism reaches the variance; parked 09-20 r) | Keeling tab's growth-rate wobble (if the YoY panel is built); the What-if ENSO switch | (a) "sensitivity, not reconstruction" on the switch (README already says this); (b) show obs vs model growth-rate sd on the panel; (c) reopen: none named |
| 4 | the AIC gate | ΔAIC +4.18 vs the seas_ml-0 control (31 names beats 29 by 4.09 on 26 rows) | accounting (a mechanism kept over a fit, ruling 09-19 b) | write-up §3/§5 only | (a) Table S3 + one sentence; (b) nothing in the app — it is not a displayed quantity |
| 5 | `rep_dC` — the model box sits above MLO | +5.2 ppm offset, prior z +3.52; the Keeling panel draws box vs station with no offset (~4 ppm visible) | a named shim (representation) | **the Keeling tab, default view** | (a) leave the gap and caption it (current); (b) draw the offset — a display convention that exports a 3.5σ prior strain into a public figure (Marcus's call, [[ccx_app_beta_blockers]]); (c) plot the residual panel |
| 6 | the IRF is short of the Joos multi-model mean | IRF(100) 0.283 vs 0.409; partition inside the band | a comparison, not a gate (nothing from Joos scores the model) | the Pulse lab; Fig 5 | (a) state as an open question (README does); (b) show the band on the Pulse-lab panel |
| 7 | no posterior ⇒ no bands | a single MAP; Hessian se only | product gap (DESIGN §5.3 future work) | every tab; the banner says it | (a) banner (current); (b) Hessian-based bands as an interim — ⚠ a Gaussian on a 29-dim MAP with cond 2.5e5 is not a posterior; label it if used |
| 8 | five named shims; eleven provisional constants | freeze record §4.2–4.3 | design (named, not removed) | Under the hood (parameter table) | (a) mark them in the table; (b) Table S2 |
| 9 | τ_iso over-determined by ~15 % | 6.9 / 6.4 yr NH/SH; bottles want ×1.18, Suess rows hold it | a quantitative statement (freeze §3) | write-up §5 | (a) one paragraph + the number; no app surface |
| 10 | the 13.1 ppm step between the historical (GCB budget) and SSP (LUH2) land-use series | 425.9 vs 412.8 ppm at 2024 across tabs (memory `ccx_app_beta_blockers`, 08-21) — ⚠ **re-measure at `hilda29l` before citing**; may have changed with `luc_scale` | app-internal inconsistency | Keeling vs Futures tabs | (a) re-measure; (b) if it stands, splice the SSP series onto the GCB history at 2020 rather than run two land-use histories; (c) caption |

Items 1–4 are the freeze record's reds (its §1 table); 5–10 are the beta-product flags around
them. Nothing here reopens the model unless Marcus rules on a (c).

## 5. Decisions needed before anything is built
- **A** — beta scope: A1 (ship the existing six, re-cut) or A2 (build the 08-29 spec first).
- **B** — write-up venue / length: full model-description paper (§2 as is) or short tool note
  (§2 with §4–5 to supplement). Changes which figures are main vs supplement, not the set.
- **C** — the red-flag advice: which of §4's rows to take up, in what order.
- **D** — `rep_dC` on the Keeling panel (row 5): leave, draw, or residual panel.
- **E** — the hemispheric tab ⑤: drop, or build as the teaching point (its deferral condition
  cannot be met inside this design).
