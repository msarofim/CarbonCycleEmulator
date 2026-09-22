# PLAN 2026-09-22 — the BETA APP at `v1.0-hilda29l`: put the red flags in front of the community

**Re-scoped 09-22 (Marcus): "This is not a paper yet, this is a Shiny app. I want community input
on the red flags and whether they are deal-breakers, fixable, or acceptable before I move to a
paper."** ⇒ the beta's PURPOSE is the review. The app must (1) show each red flag on screen with
its number, (2) say what the model's reason is, (3) ask the three-way question, and (4) have a
channel the answer can come back through. The paper structure drafted in the first cut of this
note is parked at the bottom (§7) for later; nothing there is owed now.

Numbers: the 09-21 scorecard (`outputs/diagnostics/whole_model_scorecard_20260921_hilda29l.log`)
and the freeze record (`notes/assessment_2026-09-21_product_ready.md`).

## 0. What exists and what the beta adds

The app that exists is the 08-11 six (`app/ui.R`): The Keeling Curve · Where does the carbon go?
· What if…? · Isotope fingerprints · Futures · Under the hood. It runs the canonical live on the
periodic spinup (the 09-21 i fix; CO₂ 2024 = 424.37 = the objective's run); non-dismissible
provenance banner; computed takeaways. Its audience was the undergraduate (DESIGN §1).

**The beta adds a second audience — the reviewer — without rebuilding the six.** The 08-29
six-tab spec (checkboxes, van Vuuren/FaIR/MAGICC, hemispheric, ocean transport) was never built
and is NOT what the review needs; it stays parked. What the review needs is:

1. **A seventh tab: "Known issues — we want your view"** (reviewer-facing; the undergraduate
   tabs are untouched). One card per red flag: the figure that shows it, the number, the
   model's reason in one sentence, the class (structural / accounting / shim / comparison), and
   the question — *deal-breaker, fixable, or acceptable for a pedagogical model?* — with a link
   to the feedback channel pre-filled with the issue's tag.
2. **The banner gains "beta · v1.0-hilda29l · reviewers: see Known issues."**
3. **Per-tab flags where a red is already on screen** (two are): a one-line caption on the
   Isotope tab (the 2× δ¹³C gradient — the panel plots MLO and SPO, so it shows it) and on
   the Keeling tab (the `rep_dC` gap, ~4 ppm box above station).
4. **A feedback channel.** ⚠ **The repo has no remote** (handoff (k) §4) and `APP_REPO_URL`
   points at `github.com/msarofim/CarbonCycleEmulator`, which does not exist as a public repo.
   Community input needs one of: (a) publish the repo and use GitHub Issues with a template
   per red (best — the reviewer sees the code and the CHANGELOG); (b) a form (Google Form /
   Qualtrics) linked from each card; (c) email. **Decision, not implementation.**
5. **A timed real deploy to shinyapps.io before any announcement** — startup 73 s idle / 2.8
   min under load on the M4; DEPLOY.md's "~20 s" is a warm-cache number and shinyapps.io times
   out on startup.

## 1. The reviewer tab — card by card

Every card: **[figure] · the number · the reason · the class · the question · the link.** The
figures are new (nothing in `outputs/figures/`; `app/R/plots.R` has none of these panels). Each
is a live run of the canonical plus one control where named — no precomputed image, same
convention as the six tabs. Ordering is by how visible the flaw is to a user of the six tabs,
so the reviewer meets first what a student would meet first.

| card | figure (new `plot_*`) | the number | the model's reason (one sentence) | class | the question, sharpened |
|---|---|---|---|---|---|
| **1 The model box sits above Mauna Loa** | Keeling panel with the residual (model − MLO) beneath it, `rep_dC` drawn as a dashed line | +5.2 ppm fitted offset, prior z +3.52; ~4 ppm visible on the default view | a two-box atmosphere has no Mauna Loa; the station sits below the hemispheric mean and the fit carries that as a representation offset | shim | is a fitted station offset acceptable in a teaching tool, and should the panel DRAW it (which exports a 3.5σ prior strain as a display convention) or show the gap? |
| **2 The north–south δ¹³C gradient is twice observed** | MLO and SPO δ¹³C (obs + model) with the CO₂ gradient beside it | gradient −0.134 vs −0.067 ± 0.003 ‰ (2.00×), a constant offset; CO₂ gradient 0.91× | closing it needs a persistent NH−SH isoflux of ~+64 GtC‰/yr that a one-column-per-hemisphere ocean has no carrier for; every lever tried moves the level, not the gradient | structural | is a 2× hemispheric isotope gradient a deal-breaker when the CO₂ gradient and both Suess trends are right? what carrier would you expect? |
| **3 The surface-ocean δ¹³C disequilibrium asymmetry** | NH/SH air-sea disequilibrium, model mixed layer and cold box vs the GLODAP bottles | asym +0.094 vs +0.286 ± 0.029 (z −6.60); the deficit is NH-side (+1.03 vs +1.28) | same structure as card 2; the air-sea isotopic timescale is over-determined by ~15 % between the bottles and the atmospheric decline | structural | same question as 2 — the two are one flaw with two observables; and would an interhemispheric deep exchange (a NEW model) be worth it for a teaching tool? |
| **4 Year-to-year wobble is 60 % of observed** | detrended annual CO₂ growth rate, model vs obs, with the sd of each; beneath it ocean-uptake anomaly vs Niño3.4 with the slopes | sd 0.548 vs 0.933 ± 0.084 ppm/yr (0.59×); the ENSO SLOPE is 0.89× (+0.103 ± 0.042 vs +0.115 ± 0.025 GtC/yr per index) | the ENSO sensitivity is carried by a physical upwelling limb (13.7 ± 2.1 Sv per index, in the observed 14–25 bracket); the variance the record has beyond ENSO — volcanic, land — has no mechanism here | structural | the app's ENSO switch is a sensitivity, not a reconstruction: is that acceptable, or must a "what makes CO₂ wobble" tab reproduce the variance? |
| **5 The pulse decays faster than the multi-model mean** | IRF 0–1000 yr with the Joos 2013 band; the 1000-yr partition bars vs the band | IRF(100) 0.283 vs 0.409; partition at 1000 yr 34 / 48 / 18 % vs 16 ± 14 / 59 ± 12 / 25 ± 9 (inside the band on every term) | a comparison, not a gate — nothing from Joos scores the model; where the difference lives (land share high, ocean low at 1000 yr) is stated, not tuned | comparison | the app teaches "how long it lasts": is a lifetime shorter than the multi-model mean, with the shape inside the band, acceptable to teach? |
| **6 A simpler control fits better** | NH seasonal CO₂ and δ¹³C at MLO: canonical vs the seas_ml-0 control vs obs | ΔAIC +4.18 against `hilda31pe` (31 names beats 29 by 4.09 on 26 rows) | the seasonal mixed layer was kept over the fit because it is a real entrainment channel (`h_ml` 57.3 ± 3.7 m) and the shim it replaced was not | accounting | when a named mechanism loses to a shim by 4 AIC, keep the mechanism? |
| **7 No uncertainty bands** | (no figure — the banner) | a single MAP; Hessian PD, cond 2.5e5 | no MCMC has been run; a Gaussian on a 29-dim MAP at that condition number is not a posterior | product gap | is a beta without bands acceptable, or is a Hessian band (labelled as such) better than none? |
| **8 Stand-ins and provisional constants** | the parameter table with the five shims and the nine pins marked; the constants ledger | 5 shims (`rep_dC`, `grad_off_d13c`, `sst_seas_amp_NH/SH` 30 % under obs, `ent_seas_amp_SH` 0, the ocean ENSO pair 0); 11 constants provisional | each names a mechanism the design does not carry rather than hiding it | design | which of these would you want carried before you trusted the chain? |

Cards 2–4 and 6 are the freeze record's four reds; 1, 5, 7, 8 are the flags a reviewer will
raise unprompted, pre-empted.

**Not on a card, to re-measure first:** the 13.1 ppm step between the Keeling tab (GCB land-use
history) and the Futures tab (LUH2/SSP history), measured 08-21 at an older vector
([[ccx_app_beta_blockers]]). If it stands at `hilda29l` it is an app-internal inconsistency a
reviewer WILL find by flipping tabs, and it belongs on the tab before the review opens — splice
the SSP series onto the GCB history at 2020 rather than caption two histories.

## 2. What the reviewer needs to be ABLE to say "fixable"

A reviewer cannot judge "fixable" from a card. Each card therefore links to the closed arc's
record — the CHANGELOG entry and the scoping/prereg note — so "we tried X, Y, Z and each moved
the level not the asymmetry" is a link, not a claim:
- card 2/3 → `notes/scoping_2026-09-21c_gate_d_larger_structures.md`, CHANGELOG 09-20 s / 09-21 e;
- card 4 → CHANGELOG 09-20 r (GATE V parked), `diag_gateV_variability_drivers.R`;
- card 5 → `diag_joos_irf.R`, the Joos band's construction (⚠ the "389 ppm background" is from
  recollection — verify against Joos 2013 before it goes on a card);
- card 6 → CHANGELOG 09-19 b (the ruling), CHANGELOG 09-22 j (the free parent: the pins cost
  5.70, one observable two carriers).
This only works if the repo is public (§0 item 4a).

## 3. Build list (if approved) — in order
1. Re-measure the cross-tab land-use step at `hilda29l` (one script; decides whether a fix
   precedes the review).
2. `app/R/plots_review.R` — the eight panels, each a function of the canonical run (+ the
   control for card 6, + Joos for card 5); labels from named constants (tag, mode, scorecard
   date) in `global.R`.
3. `ui.R` / `server.R` — the seventh tab; the banner; the two per-tab captions.
4. The feedback channel (decision first): issue templates per card if GitHub.
5. Timed deploy; `DEPLOY.md` + README `Status` gain the beta label.
6. A reviewer-facing README section: what we are asking, the eight questions, how to answer.

## 4. Decisions needed
- **A** — the feedback channel: publish the repo + GitHub Issues (recommended), a form, or email.
  (Publishing means the tag goes public as-is, with the CHANGELOG — that is the point.)
- **B** — the eight cards: any to drop, any to add, the ordering.
- **C** — card 1: draw `rep_dC` on the Keeling panel, or leave the gap and show the residual.
- **D** — card 7: banner only, or a labelled Hessian band as an interim.
- **E** — who the community is (a named list of reviewers vs an open link) — changes how
  sharp the questions can be and whether the undergraduate tabs need a "reviewer mode" toggle.

## 5. Not in the beta (parked)
The 08-29 six-tab spec (`notes/spec_2026-08-29_app_six_tabs.md`): checkboxes need the GMST
decomposition; ③ needs cross-repo van Vuuren/FaIR/MAGICC data; ⑤'s deferral condition ("until
the component is fixed") cannot be met inside this design — build it as the teaching point or
drop it, after the review says which.

## 6. What the review's answers feed
Each card's answers sort into the freeze record's §6 ("what would re-open it"): a ruling on the
objective (σ items), the interhemispheric deep exchange (a new model), or a posterior. The
paper (§7) is written after that sorting, not before.

## 7. PARKED — the paper (first cut of this note, 09-22)
Structure with lane marks (✍ Marcus / ⚙ Claude): Intro ✍ · Model ⚙ · Calibration ⚙ · Results as
the chain ✍⚙ · What the design cannot do ✍⚙ · App ⚙ · Discussion ✍ · Supplement ⚙. Figure set
F1 schematic · F2 CO₂ record · F3 isotopes incl. the deep Δ¹⁴C profile vs the column control
(+233) · F4 sinks + ENSO · F5 what emerges (IRF, partition, label vs perturbation) · F6 the
edge (D, GL, V) · F7 seasonal ML vs control; Tables 1 parameters · 2 data streams · 3 gate
ledger · 4 comparisons; S1–S3. The review cards above ARE F6 + F5 + F7 + the Keeling residual,
so building the beta builds a third of the paper's figures.
