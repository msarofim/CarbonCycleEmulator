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
| **1 The model box sits above Mauna Loa** | Keeling panel with the residual (model − MLO) beneath it, `rep_dC` drawn as a dashed line | fitted offset **3.515 ppm** on a 1.0 ppm prior = **z +3.52**; raw box **+3.40 ppm** above MLO in the mean, **RMS 0.73 ppm** once the offset is applied (all measured 09-22) | a two-box atmosphere has no Mauna Loa; the station sits below the hemispheric mean and the fit carries that as a representation offset | shim | is a fitted station offset acceptable in a teaching tool, and should the panel DRAW it (which exports a 3.5σ prior strain as a display convention) or show the gap? |
| **2 The north–south δ¹³C gradient is twice observed** | MLO and SPO δ¹³C (obs + model) with the CO₂ gradient beside it | gradient −0.134 vs −0.067 ± 0.003 ‰ (2.00×), a constant offset; CO₂ gradient 0.91× | closing it needs a persistent NH−SH isoflux of ~+64 GtC‰/yr that a one-column-per-hemisphere ocean has no carrier for; every lever tried moves the level, not the gradient | structural | is a 2× hemispheric isotope gradient a deal-breaker when the CO₂ gradient and both Suess trends are right? what carrier would you expect? |
| **3 The surface-ocean δ¹³C disequilibrium asymmetry** | NH/SH air-sea disequilibrium, model mixed layer and cold box vs the GLODAP bottles | asym +0.094 vs +0.286 ± 0.029 (z −6.60); the deficit is NH-side (+1.03 vs +1.28) | same structure as card 2; the air-sea isotopic timescale is over-determined by ~15 % between the bottles and the atmospheric decline | structural | same question as 2 — the two are one flaw with two observables; and would an interhemispheric deep exchange (a NEW model) be worth it for a teaching tool? |
| **4 Year-to-year wobble is 60 % of observed** | detrended annual CO₂ growth rate, model vs obs, with the sd of each; beneath it ocean-uptake anomaly vs Niño3.4 with the slopes | sd 0.548 vs 0.933 ± 0.084 ppm/yr (0.59×); the ENSO SLOPE is 0.89× (+0.103 ± 0.042 vs +0.115 ± 0.025 GtC/yr per index) | the ENSO sensitivity is carried by a physical upwelling limb (13.7 ± 2.1 Sv per index, in the observed 14–25 bracket); the variance the record has beyond ENSO — volcanic, land — has no mechanism here | structural | the app's ENSO switch is a sensitivity, not a reconstruction: is that acceptable, or must a "what makes CO₂ wobble" tab reproduce the variance? |
| **5 The pulse decays faster than the multi-model mean** | IRF 0–1000 yr with the Joos 2013 band; the 1000-yr partition bars vs the band | IRF(100) 0.283 vs 0.409; partition at 1000 yr 34 / 48 / 18 % vs 16 ± 14 / 59 ± 12 / 25 ± 9 (inside the band on every term) | a comparison, not a gate — nothing from Joos scores the model; where the difference lives (land share high, ocean low at 1000 yr) is stated, not tuned | comparison | the app teaches "how long it lasts": is a lifetime shorter than the multi-model mean, with the shape inside the band, acceptable to teach? |
| **6 A simpler control fits better** | NH seasonal CO₂ and δ¹³C at MLO: canonical vs the seas_ml-0 control vs obs | ΔAIC +4.18 against `hilda31pe` (31 names beats 29 by 4.09 on 26 rows) | the seasonal mixed layer was kept over the fit because it is a real entrainment channel (`h_ml` 57.3 ± 3.7 m) and the shim it replaced was not | accounting | when a named mechanism loses to a shim by 4 AIC, keep the mechanism? |
| **7 No uncertainty bands** | (no figure — the banner) | a single MAP; Hessian PD, cond 2.5e5 | no MCMC has been run; a Gaussian on a 29-dim MAP at that condition number is not a posterior | product gap | is a beta without bands acceptable, or is a Hessian band (labelled as such) better than none? |
| **8 Stand-ins and provisional constants** | the parameter table with the five shims and the nine pins marked; the constants ledger | 5 shims (`rep_dC`, `grad_off_d13c`, `sst_seas_amp_NH/SH` 30 % under obs, `ent_seas_amp_SH` 0, the ocean ENSO pair 0); 11 constants provisional | each names a mechanism the design does not carry rather than hiding it | design | which of these would you want carried before you trusted the chain? |

Cards 2–4 and 6 are the freeze record's four reds; 1, 5, 7, 8 are the flags a reviewer will
raise unprompted, pre-empted.

**Not on a card — MEASURED 09-22 (x), and it is WORSE than the item said.** There are **three**
histories on this app, not two (`calibration/diag_app_cross_tab_step.R`; log at
`outputs/diagnostics/app_cross_tab_step_20260922.log`) ⇒ [[ccx_app_three_histories]]:

| tab | inventory | CO₂ 2024 | step |
|---|---|---|---|
| The Keeling Curve | historical (GCB) | **424.37 ppm** | — |
| Futures | ssp245 (SSP/LUH2) | **412.33** | **−12.05** |
| What if… | GCB fossil + SSP land-use | **410.79** | **−13.58** |

`app_stylised_emissions()` takes fossil from the GCB history and land-use from the SSP
background for EVERY year, so the hybrid past is under all four stylised pathways — the `kind`
switch only rewrites the future. The gap is **−91.4 GtC of land use**; verified to be the
inventory and not a reading convention or a temperature difference. **A reviewer flipping tab 1
→ tab 3 sees 13.6 ppm with nothing on the page to explain it.** ⏳ **RULING OPEN:** splice the
SSP series onto the GCB history at the handover year, caption the discontinuity, or both.

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
1. ~~Re-measure the cross-tab land-use step at `hilda29l`~~ **DONE 09-22 (x)** — and it found a
   third history. The fix/caption is a RULING (§1); nothing is built.
2. `app/R/plots_review.R` — the eight panels, each a function of the canonical run (+ the
   control for card 6, + Joos for card 5); labels from named constants (tag, mode, scorecard
   date) in `global.R`.
3. `ui.R` / `server.R` — the seventh tab; the banner; the two per-tab captions.
4. The feedback channel (decision first): issue templates per card if GitHub.
5. Timed deploy; `DEPLOY.md` + README `Status` gain the beta label.
6. A reviewer-facing README section: what we are asking, the eight questions, how to answer.

## 4. ⭐ ALL FIVE DECISIONS SETTLED 09-22 — AND BUILT (CHANGELOG 09-22 (l))

| | decision | Marcus, 09-22 | built |
|---|---|---|---|
| **A** | feedback channel | **the Substack post on the model.** Comments public there; credit in the acknowledgements | `APP_FEEDBACK_URL` + a per-card deep link; a visible warning until it is set |
| **B** | the eight cards | **approved as drafted** | `RV_CARDS`, gated by `test-review-cards.R` |
| **C** | the Keeling panel | **C2 + C3** | both model lines on the teaching tab; the residual pair on card 1 |
| **D** | bands | **D1.** "D3 should wait until we have a final model, not a beta product" | banner only; card 7 states the posterior is deferred to the final model, and asks whether that is acceptable |
| **E** | the audience | Substack / LinkedIn / Facebook / Bluesky followers, **"the only people commenting on the cards will be subject-matter experts"**; a couple of hundred reads in the first hours, click-through unknown; **the three-minute warm-up can be warned about in the post** | cards written in one technical register with a plain lede, not two; `APP_WARMUP_NOTE` on the first tab; the host's concurrency is on the DEPLOY checklist |

⚠ **What E's answer changes from §4a's draft.** The expectation that only subject-matter experts
comment removes the two-register requirement — the cards keep a plain opening sentence and put the
mechanism in a collapsible, rather than being written twice. **It does NOT remove §4a item 2**: the
response will still skew to the intuitive cards, so if the structural reds (2, 3) are what gate the
paper, naming a few carbon-cycle colleagues in the post and asking them for 2, 3 and 6 specifically
is still worth doing on top of the open call.

### The original framing of the choices, kept for the record

- **A — SETTLED: the feedback channel is Marcus's Substack post on the model.** ⇒ the repo does
  not have to be published for the channel to work, but §2's "how would a reviewer judge
  *fixable*" links (CHANGELOG, scoping notes) all point into a repo with **no remote**. Either
  publish it (the links work) or drop §2's links and let each card carry the tried-and-failed
  list as text. `APP_REPO_URL` in `app/global.R:47` currently points at a GitHub repo that does
  not exist — **it must be fixed or removed before the app is public either way.**
- **B — the eight cards: approved (Marcus 09-22).** Ordering and register change under E.
- **E — SETTLED: the audience is Marcus's Substack / LinkedIn / Facebook / Bluesky followers.**
  Open link, no named reviewer list. Consequences in §4a.
- **C — the Keeling panel and `rep_dC`:** §4b.
- **D — uncertainty bands:** §4c.

### 4a. What an open social-media audience changes

1. **Every card needs two registers.** The cards as drafted assume a reader who knows what a
   δ¹³C gradient is. Each card gets a **plain headline question anyone can answer** plus a
   collapsible with the number, the σ, and the mechanism. The three-way answer
   (deal-breaker / fixable / acceptable) is answerable by a lay reader on cards 1, 4, 5, 7;
   cards 2, 3, 6, 8 will effectively only be answered by colleagues.
2. **Expect a skewed response.** Volume will land on the intuitive cards (1, 4, 5) and near zero
   on 3 and 6. ⇒ if the structural reds (2, 3) are the ones whose verdict actually gates the
   paper, an open call will not deliver it — **consider naming a handful of carbon-cycle
   colleagues in the post and asking them for 2, 3 and 6 specifically**, on top of the open call.
3. **One comment thread, eight questions, will tangle.** Number the cards in the app, and have
   each card's button deep-link to the post's anchor for that card with "lead your comment with
   **#N**". Alternative: a short form per card. Substack comments keep the discussion public and
   attributable, which is worth more than tidy data here.
4. **Say up front how answers will be used** — whether comments may be quoted and attributed in
   the eventual write-up. Cheaper to state in the post than to ask retroactively.
5. **The app goes public with the post.** ⚠ Check the shinyapps.io plan's active-hours and
   concurrent-connection limits against a LinkedIn + Facebook + Bluesky push before announcing;
   a cold start of 73 s idle (2.8 min under load) with a queue behind it is a bad first
   impression, and the free tier's monthly active hours are finite. Time the real deploy, and
   consider warming it before the post goes out.
6. **"Not peer-reviewed, not for citation"** is already in Under the hood; it should also be in
   the post and on the banner, because a public link travels away from both.

### 4b. C — the Keeling panel: what the choice actually is

**The mechanism.** The model's atmosphere is two hemispheric-mean boxes. Mauna Loa is a remote
marine station; a hemispheric mean contains continental boundary-layer air the station never
sees, carrying extra CO₂ that is isotopically light. `rep_dC` is **one** parameter that converts
box to station for **both species at once** through mass balance (`R/likelihood.R`, the
`LIK_REP_SOURCE_D13C` block):

```
predicted station CO2   = box CO2  − rep_dC
predicted station δ13C  = box δ13C − rep_dC · (d_s − δ13C_box) / CO2_box
```

It is tied across species deliberately: a **free** δ¹³C level offset would have swallowed the
Suess overshoot whole and reported a good fit. Prior **N(0, 1.0 ppm)**, and the 1.0 is the
repo's own station-vs-box scale with a receipt (co-located NOAA in-situ vs SIO flask at MLO
disagree 0.39–0.59 ppm RMS over 702 months, so a station-vs-*box* term must exceed that). The
MAP sits at **3.515 ppm = z +3.52** — three and a half times the scale the prior thinks
representation is worth. That strain is card 1's content and is real.
⚠ **CORRECTION (09-22, measured).** The first cut of this note, and a comment in `app/global.R`,
both said "+5.2". There is no 5.2 in this model: the offset is **3.515 ppm** and its prior z is
**+3.52** — the z had been garbled into a ppm value and propagated. The scorecard's strained-prior
line has always read `rep_dC +3.52`. Both places are corrected, and card 1 now computes all three
numbers rather than quoting any.

⚠ **THE DISPLAY PROBLEM IS NOT THE STRAIN — IT IS THAT THE PANEL DRAWS A DIFFERENT COMPARISON
FROM THE ONE THE FIT WAS SCORED ON.** `plot_keeling()` (`app/R/plots.R:53`) plots the raw box
`d$co2_NH` against the MLO points. The likelihood scored `box − rep_dC` against those same
points. The two comparisons differ by 3.5 ppm, so **the flagship panel is not like-for-like with
the calibration**: it shows a +3.40 ppm mean miss where the comparison that was scored sits
at −0.12 ppm mean, 0.73 ppm RMS (measured 09-22).

| option | what the panel shows | for | against |
|---|---|---|---|
| **C1 leave it** (was current) | raw box vs station | nothing hidden; the gap is visible | the panel is not the comparison that was fitted; on an open launch the top comment becomes "your model is 3–4 ppm high", a display artefact that crowds out the eight real cards |
| **C2 draw both lines** — box (light) **and** box − `rep_dC` labelled "model, as the station would measure it" (solid), caption naming the fitted offset and its 3.5σ | the scored comparison, plus the raw box beside it | like-for-like with the calibration; the strain is stated, not hidden; card 1 still owns the accounting | a reader who skips the caption sees a good fit and misses that the offset is fitted, not measured |
| **C3 residual panel** — keep the box line, add model − MLO underneath with `rep_dC` as a horizontal line | the gap as the subject | most informative for a reviewer | costs vertical space on the default tab and asks a general audience to read a residual plot |

**Recommendation: C2 on the Keeling tab, C3 on card 1.** The undergraduate tab shows the
comparison that was actually scored (with the raw box visible beside it, so nothing is
concealed); the reviewer card carries the residual and the 3.5σ and asks whether a fitted
station offset is acceptable in a teaching tool. ⚠ **C2 is a display change only — it changes
no number in the model and no number in the fit.** The thing to guard against is the version of
C2 that drops the raw box line: that one *would* be concealment.

### 4c. D — bands: three options, and what is newly true

**The state.** No posterior exists; the app runs a single MAP and the banner says so. The stored
Hessian is **PD, condition number 2.4e5** at the canonical (2.46e5 at the free parent), with
per-parameter standard errors (e.g. `h_ml` 57.3 ± 3.7 m, `w_enso_l2` 13.71 ± 2.13 Sv).

⭐ **What changed: the two things that were named as blocking a posterior are gone at this
canonical.** `ccx_hessian_is_the_blocker` recorded cond **1.11e6**, `h_ml` at a **hard bound
1.5σ below the mode**, and `kz` railed. At `hilda29l`: cond 2.4e5, `h_ml` 57.3 ± 3.7 on a floor
of 42.5 m = **4.0σ clear**, and no step-unstable direction (one exception reported: the free
parent's `gamma_enso_ocn_SH`, which sits at ~0). ⇒ **"a posterior is not feasible" is no longer
a true sentence**, and that matters for how card 7 is phrased.

| option | what ships | for | against |
|---|---|---|---|
| **D1 banner only** (current) | single lines; the banner says no bands and why | honest; zero work; zero chance of a mislabelled band travelling as "the uncertainty" | a reviewer's reflex first question on a calibrated model is "with what uncertainty" — unanswered, it will absorb a share of the feedback that should have gone to the eight cards |
| **D2 a Laplace band** — draw N from MVN(MAP, stored cov), run each, plot the envelope, labelled "parameter uncertainty at the mode, Gaussian approximation, **not** a posterior" | something to look at on every historical panel | cheap (the covariance is stored; N ≈ 200 runs); makes the tightly- vs loosely-constrained parts of the record visibly different | ⚠ a quadratic approximation at cond 2.4e5 means the band's **width is dominated by the directions the data constrains least — exactly where the Gaussian is worst**; draws in the transformed coordinates can land where the carbonate-range warning fires; and a band on a public chart *reads as* the uncertainty no matter what the label says |
| **D3 run the MCMC** | the posterior DESIGN §5.3 calls for; real ribbons | answers card 7 rather than asking it; the blockers above are gone | **0.2712 s/eval** on the canonical arm ⇒ ~200k evals ≈ **15 h per chain**, 4 chains ≈ 15 h at 4-wide on the M4 or a Torch array — but the project has **never had a sampler converge**, so the risk is convergence in 29 dimensions, not compute. Weeks, not days. It changes no number in the model (same objective #13) |

**Recommendation: D1 for the beta, and make D3 the actual question on card 7** — "would you
want the posterior before you'd trust this, or is a single best fit acceptable for a teaching
tool?" That is precisely a question the community should answer, because the answer costs weeks
and nobody inside the project can price it.

⚠ **If a band is wanted anyway, D2 must be MEASURED before it is shipped, not after**: draw 200,
run them, and compare the band's width to the model−obs residuals on the same panel. **A band
narrower than the residuals it is drawn over is not credible and must not ship.** Never ship an
unmeasured band.

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
