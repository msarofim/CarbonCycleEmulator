# Handoff — CarbonCycleEmulator, 2026-08-21d: the app is calibrated, and the CO₂ level is not

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `3985910`.
**Supersedes:** `handoff_2026-08-21c_three_closed_app_next.md`. Its §§1–5, 7, 8 stand. **Its §6
does not — the table there does not reproduce, and it had set the session's priority.** Read
this one; 21c is provenance for everything except §6.

---

## 0. STATE IN TEN LINES

1. **The app runs on the calibrated mode.** Landed, tested, committed (`8b94ba4`).
2. **The fix was NOT the path.** Two of the 21 fitted parameters are FORCING parameters worth
   5.8 ppm; the path fix alone makes the app **worse** than the defaults it replaces. §2.
3. **21c §6's table does not reproduce, in both numbers and sign.** The app was never 14.6 ppm
   low — it was **1.1**. And **DESIGN §6 gate 7 is NOT stale**, contra 21c §6. §3.
4. **`rep_dC` = +5.18 σ is not a representation offset.** It is 97 % common-mode and it absorbs
   the late half of a **~9 ppm swing** that changes sign in the 1940s. §4. **This is the
   session's real finding and it is bigger than the app.**
5. **The absolute CO₂ level is effectively unconstrained after 1958** — 210 log-units of
   likelihood per log-unit of prior, against an ice-core term ~100× weaker than the stations.
   The calibration fits the **shape** of the Keeling curve, not its height. §4.
6. **A 13.1 ppm step between tab 1 and tab 5 of the same app** — 91.4 GtC of cumulative land-use
   carbon between the GCB and SSP/LUH2 inventories. Pre-existing, parameter-independent,
   not previously written down. §5.
7. Cold start measured **73 s** unloaded. DEPLOY.md claims ~20. Untested against shinyapps.io. §6.
8. **974 / 976 tests pass** — the by-design `test-fluxes.R:99,:100` pair, unchanged.
9. Still no posterior. Nothing here changes that.
10. **The science has NOT reached a good-enough state for a research claim about levels or
    sinks. It has for a pedagogical app about shape and mechanism** — with captions that say so.
    §7 is the argument.

---

## 1. WHAT WAS RUN, AND WHERE IT LIVES

| script | answers | how long |
|---|---|---|
| `calibration/diag_app_params.R` | what the app ships vs what it could ship, 5 gates | 4 s |
| `calibration/diag_rep_dC_shape.R` | is the offset a level, a trend, or a swing — 5 gates | 6 s |

Both are new and committed. Neither needs an argument. `diag_app_params.R` is the one to re-run
after any change to a fertilisation default or an emissions input.

**Files changed:** `app/global.R` (the resolution block, two wrappers), `app/server.R` (4 call
sites), `R/climate.R` (`ccx_run_coupled()` pass-through, additive, defaults from
`ccx_build_forcing()`'s own formals), `app/DEPLOY.md`, `CHANGELOG.md`.

---

## 2. THE APP FIX, AND WHY THE PATH WAS THE SMALL HALF

`app/global.R` resolved `calibration/output/mode_fit.rds`. **That file has never existed.** So
the app fell through to `ccx_default_params()` and its banner correctly, and unread, said so.

**Repointing it is necessary and not sufficient.** Six of the 21 fitted parameters have no slot
in `ccx_default_params()`, and the existing `for (n in intersect(names(p), names(pm)))` dropped
all six without a word:

- `sigma_d14c`, `rep_dC`, `grad_off_co2`, `grad_off_d13c` — **likelihood** parameters. They
  score the model against observations and cannot move a trajectory. Dropping them is right.
- **`bomb_total` (122.22 kmol) and `luc_scale` (0.8902) — FORCING parameters.**
  `ccx_make_logpost()` applies them by rescaling the bomb-¹⁴C column and the four LUC columns.
  The app builds its own forcing and would have run the fitted parameters against a forcing the
  fit never saw.

| resolution | NH box @2024 | vs MLO 424.3 | land sink | ocean sink | peak Δ¹⁴C |
|---|---|---|---|---|---|
| DEFAULTS (shipped until today) | 423.3 | −1.1 | +2.18 σ | −1.49 σ | 801 ‰ |
| PAR-ONLY (**path fix alone**) | 433.8 | **+9.4** | +2.06 σ | −0.47 σ | 732 ‰ |
| **FULL (landed)** | **428.0** | **+3.6** | +2.04 σ | **−0.62 σ** | 892 ‰ |
| GCB 2025 / obs | 424.3 | — | 2.36 ± 0.5 | 3.22 ± 0.4 | — |

**What the fix buys is the ocean sink: −1.49 → −0.62 σ.** The land sink does not move and still
misses by 2 σ. **The path fix alone would have shipped a 9.4 ppm error** — worse than the
defaults, and nothing would have reported it.

**The structural repair, not just the value.** Every forcing in the app now goes through
`app_build_forcing()` / `app_run_coupled()`. The second needed a pass-through added to
`ccx_run_coupled()`, which built its own forcing internally — without it the futures and pulse
tabs disagreed with the historical tab by 2.7 ppm at 2100. `pump_mode` is now set explicitly
from the mode file too: it matches the default today, and setting it is what keeps that a fact
rather than a coincidence. **Do not call `ccx_build_forcing()` or `ccx_run_coupled()` directly
from the app again.**

---

## 3. 21c §6's TABLE DOES NOT REPRODUCE

21c §6 reported, and this memory-and-handoff chain propagated:

| | CO₂ @2024 | vs obs | land | ocean |
|---|---|---|---|---|
| 21c §6, "app defaults today" | 409.8 | −14.6 | 2.73 | 2.44 (−1.96 σ) |
| 21c §6, "calibrated arm-N mode" | 418.6 | −5.8 | 2.54 | 2.89 (−0.83 σ) |
| **measured here, defaults** | **423.3** | **−1.1** | **3.45** | **2.62 (−1.49 σ)** |

**Two independent checks say the row above is right.** (a) Sourcing `app/global.R` itself and
reading its own `APP_HIST` returns 423.3 / land 3.45 / ocean 2.62 — the diagnostic reproduces
the app's startup path to the digit. (b) **DESIGN §6 gate 7's recorded status line** (land
+2.28 σ / 3.50 GtC/yr, ocean −1.52 σ / 2.61, measured 2026-08-14) **agrees to within 0.1 σ on
both**, across a week of commits that did not touch the land or ocean defaults.

**So gate 7's line is NOT stale**, contra 21c §6's closing paragraph, and **the app was never
14.6 ppm low.** The fix was still worth making — it is the ocean sink, and it is structural —
but the reason given for it, and its ranking as "the single highest-value fix in the repo",
came from a measurement that does not reproduce. I did not diagnose 21c's harness; I recorded
the contradiction and re-measured from the app's own code path.

**The pattern worth carrying:** 21c §6's numbers were never gated against anything. Both of the
checks that caught them are cheap and were available at the time.

---

## 4. THE REAL FINDING — `rep_dC` IS THE LATE HALF OF A 9 ppm SWING

`rep_dC` has prior N(0, `LIK_CO2_REP_ERR` = 1.0 ppm) — the repo's own station-vs-box scale,
with a receipt (co-located NOAA in-situ vs SIO flask at Mauna Loa disagree 0.39–0.59 ppm RMS
over 702 months). The arm-N mode puts it at **+5.176 ppm**, the largest |z| in the fit.
`R/calibrate.R` says the prior exists to "resist a structural error wearing its clothes", and
that the case it was built for wants **−4.19** ppm. **Opposite sign, larger magnitude.**

**GATE A — 97 % common-mode.** NH−MLO +5.15, SH−SPO +4.93, **difference 0.22 ppm.** A
station-vs-box offset is a property of a station's latitude inside its box. The same number in
both hemispheres is **+10.7 GtC of atmospheric carbon**, not a representation constant.

**GATE B — flat over 1958–2024.** Trend +0.0120 ± 0.0039 ppm/yr; 0.79 ppm of drift on a
5.06 ppm mean.

**GATE C — and the fit is otherwise excellent.** Subtract 5.18 and **no decade of either
station is off by more than 0.9 ppm.** The model has the shape.

**GATE D — but 1958–2024 was the wrong window, because that is the window that HAS the offset.**
`rep_dC` applies only to the station streams; the ice-core term is scored without it. On
Antarctic CO₂ across the whole record — Law Dome ice, then SPO flask, and **the two products
agree to 0.31 ppm over their 54 overlapping years**, so they read as one continuous target:

| era | model−obs | era | model−obs | era | model−obs |
|---|---|---|---|---|---|
| 1750–1800 | −0.57 | 1900–1940 | **−4.12** | 1958–1980 | +4.51 |
| 1800–1850 | −1.28 | 1940–1960 | −0.77 | 1980–2000 | **+5.29** |
| 1850–1900 | −2.03 | | | 2000–2025 | +5.08 |

**A ~9 ppm swing with its crossover in the 1940s.** The model under-accumulates through
1900–1940 and over-accumulates after 1950, and a constant fitted on the second half hides the
first. The 1900 deficit is a known arc — `diag_1900_deficit.R` took it from −6.5 to −2.08 ppm
at default parameters. **What is new is that it did not go away, that it changes sign, and that
the parameter absorbing the modern half is 5 σ into its prior.**

**GATE E — why the prior never stood a chance.** `rep_dC` 5.18 → 0:

| stream | at 5.18 | at 0 | Δ |
|---|---|---|---|
| `co2_level_MLO` | −74.1 | −954.7 | **+880.6** |
| `d13c_level_MLO` | +53.5 | −738.8 | **+792.3** |
| `co2_level_SPO` | −64.2 | −817.6 | **+753.4** |
| `d13c_level_SPO` | +65.6 | −320.2 | **+385.8** |
| **likelihood bought** | | | **+2812.1** |
| **prior paid** | | | **−13.4** |

**210 log-units of likelihood per log-unit of prior.** The absolute CO₂ level is held by the
ice-core term alone — ~14 units of inverse variance (255 rows at σ 4.0–7.5 ppm) against **1523**
monthly station points at σ ≈ 1 ppm. **Post-1958 the model's absolute height is effectively
free.** No prior width that anyone would defend on physical grounds survives a 210:1 gradient;
this is an identification problem, not a prior-tuning problem.

**Recorded, not acted on:** the ice term is scored against `co2_NH` on a "globally well mixed
pre-1900" argument — sound for its 87 pre-1900 rows, and progressively less so for its 52
post-1958 ones, where the model's own NH−SH gradient reaches **3.5 ppm**.

### 4a. WHAT I DID NOT DO, AND WHY

**I did not apply `rep_dC` to the app's Keeling panel.** It would make the panel look right —
the station-equivalent prediction is 422.8 against MLO's 424.3, a −1.5 ppm miss instead of
+3.6. And it would be exporting a **5 σ prior violation into a public-facing figure as if it
were a display convention**. That is a methodological choice, so it is Marcus's. The banner now
says the fit constrains shape more tightly than height; the panel still draws the raw box.

**I did not widen the `rep_dC` prior, or pin it.** Both would move the number without touching
the swing, and GATE E says the prior is not the binding object.

---

## 5. A 13.1 ppm STEP BETWEEN TWO TABS OF THE SAME APP

Pre-existing, parameter-independent, and not previously written down. `diag_app_params.R`
gate 5. Tab 1 (Keeling) runs `scenario = "historical"` → the GCB 2025 budget. Tab 5 (Futures)
runs `ccx_run_coupled()` on an SSP → the SSP/LUH2 harmonisation. Over 1750–2020:

| | fossil | **land-use** | total |
|---|---|---|---|
| GCB historical | 423.8 | **278.6** | 702.4 |
| ssp245 | 430.7 | **187.2** | 617.9 |
| difference | +6.9 | **−91.4 GtC** | −84.5 GtC |

**Measured: 425.9 ppm at 2024 on tab 1, 412.8 ppm at 2024 on tab 5.** SSP2-4.5 reaches
499.6 ppm at 2100 carrying the same deficit — so every scenario on that tab is ~13 ppm low
against the historical tab drawn four tabs to the left, and the app presents both as "the
model". **This is an emissions-inventory question, not a parameter question, and it is a
decision (harmonise the SSP historical segment to GCB? caption the discontinuity? both?) rather
than a bug to fix.**

---

## 6. THE REMAINING BETA LIST, RE-RANKED AFTER THIS SESSION

1. **The tab-1/tab-5 13.1 ppm step (§5).** Now the largest single visible inconsistency.
2. **The `rep_dC` display decision (§4a).** Tab 1's takeaway line says the model "reproduces"
   the record; §4 says it reproduces the *shape*. The line and the caption need to agree with
   what §4 measured, whichever way the offset decision goes.
3. **No posterior ⇒ no uncertainty ribbons**, which DESIGN §7 calls for. Unchanged.
4. **Land sink +2.04 σ.** Tab 2 is literally "Where does the carbon go?", and the fix did not
   move this. Connect to 21c §8 — 40 % of a pulse in the land at year 3000, which no gate scores.
5. **Cold start 73 s** measured on an unloaded M4; DEPLOY.md claims ~20 s. shinyapps.io has
   startup timeouts. **Do a timed real deploy before announcing.** Still the item most likely
   to stop a launch outright.
6. Gate 12 passes but at the low end; point IRF 0.077–0.118 below the multi-model mean. Belongs
   in a caption.
7. Two silent millennial-run labels: non-CO₂ ERF held flat past 2500, CO₂→forcing extrapolated
   above 1687 ppm.

**Still specified and prototyped, not built:** the §7b pulse-partition panel (21c §7). Its one
prerequisite is unchanged — `ccx_run_fast()` must return leaf/wood/soil_fast/soil_slow as
columns. Its three traps are unchanged and still real.

---

## 7. IS THE SCIENCE GOOD ENOUGH? — THE ARGUMENT, NOT THE VERDICT

Asked directly this session. Split by claim, because the answer is not the same for all of them.

**Good enough, now:**
- **Mechanism and shape.** The Keeling curve's shape is fitted to better than 0.9 ppm per decade
  in both hemispheres (§4 GATE C). The isotopic fingerprints, the bomb spike and its drawdown,
  the seasonal cycle on physical drivers, the counterfactual mechanism switches — these are
  what the app is for and they hold up.
- **Pulse behaviour, with a caption.** Gate 12 passes. Carbon conservation over a 970-year
  post-pulse run closes to 0.000 %.
- **The structural questions closed in 21c.** The ridge, the Hessian, the δ¹³C veto. Those
  closures survive everything found here.

**Not good enough, and the gap is now measured rather than suspected:**
- **Absolute CO₂ level.** §4 GATE E: unconstrained post-1958 at a 210:1 exchange rate. Any
  statement of the form "the model reproduces the concentration record" is a statement about
  shape.
- **The land sink**, +2.04 σ and unmoved by the calibration.
- **The 1900–1940 vs post-1950 swing**, which is a structural misfit currently being laundered
  and which no gate scores.

**What I would not do next.** Another mode-finding run. Three things now point the same way —
the +2.04 σ land sink, gate 12's point IRF 0.077–0.118 below the multi-model mean, and the
sign-changing level swing — and 21c §2 measured that `beta_max`/`fert_k` absorb 85 % of a q10
change. **A land sink that is too eager, with the wrong time dependence, would explain all
four.** That is a structural hypothesis with a pre-registrable test, and refitting 21 parameters
against the same streams will move numbers without addressing it.

**The honest summary: the model is good enough to teach with and not yet good enough to publish
a level or a sink from.** The app can ship on that basis, provided its captions claim shape and
mechanism rather than height and magnitude — which is a writing task, and per the standing
convention the text is Marcus's.

---

## 8. NON-OBVIOUS STATE

- **`diag_app_params.R` gate 3 will start failing usefully** if `ccx_default_params()`'s
  `pump_mode` ever moves off "N". It reports MATCH/MISMATCH rather than stopping, because the
  app now sets it explicitly and the gate is there to notice, not to block.
- **`ccx_run_coupled()`'s two new arguments default from `formals(ccx_build_forcing)`**, not
  from retyped literals, so the two cannot drift. Any new caller gets package defaults, which
  is right for the package and wrong for a calibrated run — hence the app wrappers.
- **`mode_fit_pumpN.rds` is still NOT modified**, and `mode_fit_pumpN_hess.rds` still sits
  beside it un-merged (21c §1). `--update` has still not been passed.
- **The stale `prior_z` field in the arm file is still stale** (21c §5) and still not
  quarantined. `ccx_prior_z()` is the live path.
- **Everything in 21c §9 and in handoff 20e §9's trap list still applies.**

---

## 9. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-21d_app_landed_level_swing.md`. The app is calibrated and
> committed — do not re-open it. **Do NOT trust handoff 21c §6's numbers; §3 here shows they do
> not reproduce.**
>
> **The open scientific question is §4: a ~9 ppm swing, sign-changing in the 1940s, absorbed by
> a 5.2 σ `rep_dC`.** The hypothesis worth pre-registering (§7) is a land sink that is too
> eager with the wrong time dependence — it would also explain the +2.04 σ land sink and gate
> 12's low point IRF. **Design the test before running anything: a refit will move numbers
> without addressing it.**
>
> **The open app decisions are Marcus's, not mine:** whether the Keeling panel applies `rep_dC`
> (§4a), and what to do about the 13.1 ppm tab-1/tab-5 inventory step (§5).
>
> **Cheapest remaining blocker is a timed shinyapps.io deploy** — 73 s cold start locally
> against a platform startup timeout (§6.5).
>
> **Do NOT run the §2 refit** until a soil-damping factor with independent provenance exists.
> **Do NOT buy the Takahashi climatology.** Both unchanged from 21c.
