# REVIEW 2026-10-01 (c) — what is waiting on Marcus after the `hilda33d` adoption

> ⭐ **RULED 2026-10-01 (Marcus), all of §A and §B — applied in CHANGELOG 10-01 (j), (k), (l), (m).**
> Verbatim: "1) Retire card 6. 2) Say about 1.4 dC per 1000 GtC. 3) Delete the fertilisation sentence where it
> appears. 4) Fix Card 4 and 5, and the land pools, and add N deposition as a driver. 5) update the version to BETA
> v1.0 CarboTope. 6) Do the recommendation. 7) Follow recommendations. 8) If it is a gross rate, then name it that.
> 9) Reword: is should be specifically about CO2 fertilization, with nitrogen effects a different arm (even though
> they matter for CO2 fertilization limits). 10) I think apply it now: I don't expect another refit anytime soon.
> 11) Laplace first, MCMC as the check. 12) Draft after 1-11 are done."
> Mapping: 1 = A1, 2 = A2, 3 = A3, 4 = A4–A7, 5 = B2, 6 = B1, 7 = B3 + B3b, 8 = B4, 9 = B5, 10 = B6, 11 = B7,
> 12 = B8. Follow-up answers: B6's test ledger "Approve all"; B5 "No, wording only"; B7 MCMC "Torch"; the Laplace
> band failed its check and is HELD ("Hold the bands"). B8's draft is `notes/assessment_2026-10-01_hilda33d_DRAFT.md`.
> **§C stays unruled.** Read the handoff `notes/handoff_2026-10-01d_rulings_applied.md`, not this list, for the state.

Follows `notes/handoff_2026-10-01b_hilda33d_adopted.md` §2–§3. Two subagent sweeps fed it:
- every user-visible app string, checked against hilda33d;
- every handoff since 09-22, for decisions never ruled.

Every item below was re-checked against the source or re-measured before it went in. Nothing here is
implemented by the note itself; §0 lists what this session changed.

Classes: **COPY** (app text, yours) · **RULING** (a methodological choice, yours) · **FYI**.

All measurements are at `hilda33d`, with BLAS pinned, on the commits named.

---

## 0. What this session CHANGED (yours to veto)

1. **The two counterfactual switches are complete again** (`4fd433d`). Both were complete until hilda33d
   made two D2 paths live. Their tests ran at defaults, where those paths are 0, so neither could see it.
   Each fix is one line in `R/mechanisms.R`.

   | switch | what it missed | 2024 CO₂ in the app, before → after |
   |---|---|---|
   | "Warming's effect on the carbon cycle" | `npp_tsens` (the greening term), contradicting its own caveat ("only the carbon cycle's response to that warming") | 419.5 → **418** (the effect goes from −5.3 to −6.8 ppm) |
   | "Our emissions" ("nature alone") | the ANTHROPOGENIC N deposition, built from NOx + NH₃ emissions (your D2 (a) emissions proxy) and already classed as emissions-driven by `ccx_hold_climate()` | 277.0 → **282.3**. The N sink had been cancelling the warming release the caveat promises. |

   - New tests: under the warming switch, the canonical's run is BLIND to a +1 K shift in the climate
     record; under the emissions switch, it is blind to doubling every human carbon input. Each test
     carries a column inventory, so a future forcing column must be classified.
   - Mutation-tested: drop either fix and its test fails (4 and 8 failures).
   - Verified in the running app (What-if tab): 418 / 282 / 483 ppm against 425.
   - **Veto path:** remove one line (or the two names) plus its test.
2. **The pulse box re-measured at hilda33d** (`0823103`, `6bfc6cf`).
   - `diag_pulse_vs_tcre.R` now stamps the mode and commit in its log and CSV.
   - Its anchor was re-read off the running app (1.36 per 1000 GtC).
   - Output: `outputs/diagnostics/pulse_vs_tcre_20261001.{csv,log}`.
   - ⛔ **`test-pulse-linearity.R` is now a NAMED RED (5 failures), and deliberately so:** the box's typed
     numbers are hilda29l's, and its horizon claim no longer holds (A2). The test and the constants are
     untouched. They move together with your rewrite of the sentence.
3. **Full suite at `4fd433d`** (frozen copy, BLAS pinned; `outputs/diagnostics/suite_20261001_post4fd433d_all.log`):
   **5482 passed, 0 failed, 0 errors, 5 skipped.** That is +29 expectations, from the two new tests.
   - Since then only the driver and the new pulse CSV have changed, and only `test-pulse-linearity` reads
     the CSV.
   - That file alone, at HEAD: 8 passed, **5 failed**. This is the named red in item 2.

---

## A. App text that is now FALSE at hilda33d (COPY), ranked by how wrong

The app is not deployed (`APP_FEEDBACK_URL` is still a placeholder), so no reader has seen any of this.

**A1. Known-issues card 6 is now backwards.**
- Its title is "A simpler version of the model fits the data better". Its text says the version with the
  mixed layer off has "more free parameters" and "still scores better by AIC".
- At hilda33d the canonical (33 names) BEATS the control `hilda31pe` (31): +4.68 log-units, ΔAIC
  −5.35, on the 24 like-for-like rows.
- The caption prints "ΔAIC %+.2f in the simpler version's favour" whatever the sign, so it now reads
  **"ΔAIC −33.07 in the simpler version's favour"** (`app/R/plots_review.R:340`).
- That −33.07 also sums each file's STORED rows. Those mix objective #14 with #13, which is item B3's
  problem.
- The card's premise (named red #2) has turned. **Retire the card, or rewrite it** (e.g. as "the
  mechanism now also wins on fit").

**A2. The pulse box contradicts itself.**
- Its live headline is "0.136 °C a century later — 1.36 °C per 1000 GtC". The same box then says
  "1.43 at 20 years … 1.20 at 50, **1.03 at 100** and 0.97 at 200", and "moves by only 4.2 %".
- Measured at hilda33d:

  | | +20 yr | +50 yr | +100 yr | +200 yr | size spread, 10–500 GtC |
  |---|---|---|---|---|---|
  | typed (hilda29l, 09-29) | 1.43 | 1.20 | 1.03 | 0.97 | 4.2 % |
  | **hilda33d** (100 GtC) | **1.44** | **1.38** | **1.36** | **1.41** | **2.5 %** |

- ⚠ The claim "flat in pulse size but NOT in when you look" no longer holds. The figure varies about
  ±3 % across horizons, and it RISES after +100 yr.
- The physics: the slower pulse decay (IRF(100) 0.288 → 0.360) now balances the thermal lag, which is
  the TCRE-like behaviour. That is arguably a better lesson.
- Against AR6's TCRE the box's number is now 1.36, 82 % of the 1.65 best estimate and inside the likely
  range. It was 1.03, 62 %, before.
- **Needs your sentence.** The constants and the test's "falls with horizon" assertion then follow it.

**A3. "Fertilisation is the land's only long-term sink"** appears in four places:
- `app/ui.R:346–350` (the "Why there is no separate 'no land sink' switch" box);
- `app/server.R:168–169`;
- `app/server.R:1072–1074`;
- `R/mechanisms.R:90–95`, the fertilisation switch's label "(the land sink)", "Switch it off and the
  land stops taking up carbon", and "there is no separate land-uptake mechanism".

N retention is a second long-term sink. With fertilisation off it still holds **30 GtC** on land by
2024, and CO₂ is 9.4 ppm lower than with both off. See B5 for the behaviour question.

**A4. Card 4 says "whose fitted strength lands inside the observed range".**
- `w_enso_l2` is **11.91 ± 1.81** Sv/index at hilda33d, against Meinen's [14, 25]. That is below the range
  even at +1σ (13.82 on the logit scale).
- hilda29l's 13.71 ± 2.13 was inside at 1σ.

**A5. Card 5 says "the land holds a larger share here … and the ocean a smaller one".**
- The 1000-yr partition is now 18 / 60 / 22 % against Joos 16 / 59 / 25, so the ocean is LARGER.
- "Decays faster than the multi-model mean" still holds, but the gap has halved: IRF(100) 0.360 vs
  0.409 (it was 0.288).

**A6. The model description.**
- "a two-pool land biosphere" (`app/ui.R:623`) and "Two land pools" (`app/ui.R:664`). The land is four
  pools plus the inert box. This was already wrong at hilda29l.
- "no nutrient limitation" (`app/ui.R:665`) is still literally true, but it is now incomplete: N
  deposition adds a sink.

**A7. The drivers list omits N deposition.**
- "The model's inputs are emissions, global temperature, an ENSO index and volcanic aerosol"
  (`app/server.R:79–80`).
- The "What drives the model" table (`app/server.R:1208–1221`).

**A8. The version label and stage note:** item B2.

**A9. Lower priority** (from the audit; each re-checkable):
- The imbalance panel still frames the imbalance only as an after-the-fact "extreme attribution", while
  the fit itself now assigns 59 % of it to land (`app/ui.R:249–255`, `app/R/plots.R:616–621`,
  `app/server.R:212–254`; "runs above the measured line throughout" needs a re-check).
- The warming switch's blurb names soil and seawater, not plants. The emissions blurb lists fuels,
  cement and land clearing; it now also removes N deposition.
- The AOD driver label: in anomaly mode the plotted series goes negative (`R/mechanisms.R:73–77`).
- The box diagram draws N retention inside "photosynthesis → Vegetation"; the flux actually goes to
  slow soil (`app/R/plots.R:1555–1563`).
- The "fitted to" table's GCB row does not mention the moved targets (`app/server.R:1233`).
- Some verdict phrases print regardless of the computed value: `app/R/plots_review.R:168–169`, `:202–203`
  and `:235`, and `app/server.R:178–183`.
- Typed numbers that still hold but will drift at the next refit: cards 1–4 and 8, and the constraint-map
  judgements.

---

## B. RULINGS

### B1. D2 choice 4 — does the modern-NPP readout include the N-retention flux?

Status quo (until ruled): EXCLUDED. Your "Pros/cons?" question (10-01 c) quoted the wrong flux. The
0.33 GtC/yr it gave is the NET sink; the readout would add the GROSS flux.

| readout | D4 window 2001–2023 | z vs 56.1 ± 7.75 |
|---|---|---|
| exclude (GPP − Ra + ENSO term; status quo) | 67.67 GtC/yr | +1.50 |
| include (+ `ndep_ret` × 1e-3 × deposition = +0.498) | 68.17 GtC/yr | +1.56 |

**For including:**
- The model books the retained carbon as photosynthetic uptake: `alpha_photo`, the atmosphere's ¹⁴C,
  and `gpp` in the flux trace.

**For excluding:**
- The parameter is a RETENTION efficiency (carbon kept per kg N, from the whole-forest sequestration
  literature).
- The flux goes straight into `soil_slow`, bypassing vegetation, litter and their respiration. That makes
  it a sink, not productivity, and MOD17 and the verified totals measure productivity.
- Continuity: the D4 record since 09-29 uses the exclusive definition.

Either way D4 stays a named tension. **Recommendation: exclude, and quote "+0.50 GtC/yr retained via N
deposition" beside D4.**

### B2. The version label

The app runs hilda33d but says `v1.0-hilda29l`.

Where the stale label lives:
- `APP_VERSION <- "v1.0-hilda29l"` (`app/global.R:77`), printed by the banner (`app/ui.R:42`) and the
  Known-issues header (`app/ui.R:522`);
- `APP_STAGE_NOTE` (`app/global.R:79`): "The model is frozen at this version", stale since the 09-30
  unfreeze;
- `app/DEPLOY.md:36, 87, 101`: "ships as beta v1.0-hilda29l", and hilda29l's file named as the
  parameter set the app runs on;
- README's status block, which is already dual-labelled correctly;
- **No test pins the label**, which is why it drifted silently.

Options:
- (a) a new release name, your wording;
- (b) derive the mode suffix from the constant (alone it would print "v1.0-hilda33d", a release that
  never existed);
- (c) hold the app on hilda29l via its own `APP_MODE` until the D1 copy is done.

**Recommendation: (a), plus a test that the label's mode suffix equals the mode `app_params` loads.**
The stage note and DEPLOY.md follow your wording.

### B3. `test-mode-file`'s AIC gate: which rows count when the arms' objectives differ?

The gate (`tests/testthat/test-mode-file.R:306–330`) intersects stream NAMES. Under #14, `gcb_land_sink`
and `gcb_ocean_sink` score against targets moved by s · I(t) (`R/likelihood.R:2538–2553`).

| row set | canonical's lead | ΔAIC (k 33 vs 31) | verdict |
|---|---|---|---|
| 26 rows by name (status quo) | +18.54 | −33.1 | PASS |
| 24 like-for-like rows | +4.68 | −5.35 | PASS |

- The verdict is PASS either way. The 26-row margin rewards the canonical for agreeing with targets its own
  shares moved.
- **Recommendation: drop the moved rows whenever the arms' D3 gate states differ.** Detect this
  structurally, and mutation-check that #14 vs #14 keeps all 26 rows. Card 6's live ΔAIC (A1) should use
  the same rule.
- The comment blocks are stale either way: red #2 (lines 312–319, plus the label string) and red #1
  (lines 288–291, discharged 09-22 k).

**B3b. hilda33d has no registered free parent.**
- `CCX_MODE_PINNED_PARENT <- "hilda32f"` (`R/paths.R:335`) is documented as "the free parent on the
  canonical's own structure". It is hilda29l's (`hilda_csl3`, #13).
- What reads it:
  - `test-mode-file` (b) passes but now ranks #13 arms only;
  - its printed "parent price" crosses objectives;
  - `ccx_mode_free_name()` is fine for fixtures;
  - `ccx_ms_reference_set()` would seed any FUTURE free wave from hilda32f.
- Options:
  - (i) re-document it as the v1.0 canonical's parent;
  - (ii) a #14 free-parent wave (36 names, roughly 9–10 h on the Mac; Torch suits it too), which
    re-measures the pins' price (5.70 at hilda29l).
- **Recommendation: (i) now; (ii) only if you want that price.**

### B4. The drafted labels for the four gated names (COPY; `app/R/params_meta.R:113–121`)

| name | drafted label | unit | fitted | note |
|---|---|---|---|---|
| `ndep_ret` | "Carbon stored per unit of nitrogen deposited on land" | kg C per kg N | 10.19 | ⚠ GROSS. The realised NET is 7.0 kg C/kg N (1990–2023), and "stored" reads as net. |
| `npp_tsens` | "Plant growth's response to warming" | per °C | −0.00785 | Correct, but opaque: it means −0.8 % NPP per °C |
| `imb_share_land` | "Share of the carbon budget's unexplained gap assigned to the land" | — | 0.593 | |
| `imb_share_ocean_rest` | "Ocean's share of the gap the land does not take" | — | 0.208 | Accurate. The ocean's share of the WHOLE gap is (1 − 0.593) × 0.208 = 0.085. |

Constraint-map components (`calibration/diag_constraint_map.R:141,155`) are also drafts:
- `ndep_ret` and `npp_tsens` → "Land uptake";
- the two shares → "Input scalings & reporting".

### B5. The fertilisation switch: change the behaviour, or the words? (from A3)

- (a) The switch also zeroes `ndep_ret`, so "the land sink" stays true.
- (b) The switch stays CO₂ fertilisation only, and the text changes (A3).
- (c) Add a separate "Nitrogen deposition" switch (a feature).

**Recommendation: (b).** N retention is not CO₂ fertilisation, and (c) is worth it only if you want
students to see the N sink on its own.

### B6. ⚠ A ruled change that missed its refit: the piecewise-constant emissions interpolation

- Branch `emissions-interp-constant` (`35f38dc`, "Marcus, option 1") was marked "SHOULD RIDE WITH THE
  NEXT REFIT … merge this FIRST so the ledger is paid once" (handoff 09-24d).
- 09-24 (l) reduced it to flipping `CCX_EMIS_METHOD_DEFAULT` ("spline" → "constant", `R/constants.R:1064`).
- It was carried in handoffs to 09-27c, then dropped. The 09-28 arrays and the #14 refit both ran
  without it.
- Its measured size is small: −0.137 log-units at the then-canonical, ≤ 0.020 ppm on the historical
  record. The cost is the ledger: every stored logpost restamps.
- The app's pulse lab already uses "constant" (the app-only route).

Options:
- (a) flip now and restamp the registered modes, with no refit;
- (b) hold for the next refit, on the launch checklist this time;
- (c) drop it.

**Recommendation: (b), unless a refit is far off, in which case (a).**

### B7. Precomputed posterior ribbons for the app's futures

Today the app shows no uncertainty. Measured unit costs: one draw (its own spin-up plus the seven vV
futures to 2150) is ≤ 2.8 s; one log-posterior evaluation is about 0.2 s.

| choice | options | cost |
|---|---|---|
| sampler | (A) Laplace: MVN draws in u-space, the full nonlinear model per draw. (B) MCMC: `ccx_run_mcmc()` exists; no chain has ever run on a registered mode. | (A) 1000 draws ≤ 47 core-min, about 6–8 min on 8 cores. (B) 10⁵ evaluations per chain, about 5.5–6.5 h, × chains. |
| what gets a band | the seven vV futures to 2150 / the pulse lab / the historical panels | about 0.3 s per scenario per draw |
| band | 5–95 % / 17–83 % | — |
| pins | conditional on the 9 held values (stated) / other | — |

- ⚠ The Laplace spread is ±39 ppm (SSP5-8.5 2300), and it is linear. MCMC would also test whether that
  spread is honest, given the `h_ml` near-degeneracy and the `npp_tsens` ridge.
- The bands inherit the σ-audit items: the uninflated `gcb_ocean_sink` σ narrows them.
- **Recommendation: (A), 1000 draws, 5–95 %, the vV futures first, labelled "Gaussian approximation at
  the best fit, conditional on the nine held values"; (B) later as the check.**
- Torch: (A) does not need it; (B) does (ask first).

### B8. The new assessment / freeze record

- The 09-21 record is the template.
- The evidence sections can be drafted now. D4's quoted number waits on B1, the release name on B2, and
  the AIC line on B3.
- The VERDICT and the acts are yours.
- **Question: draft the evidence now, or after B1–B3?**

---

## C. Older items with no ruling found

From the sweep of the 09-22 → 10-01 handoffs; each was checked against later entries. B6 is the
weightiest of them and is lifted out above.

1. **Pre-launch checklist** (DEPLOY.md):
   - `APP_FEEDBACK_URL` / `APP_REPO_URL` are still placeholders (`app/global.R:105–106`);
   - start-up has not been re-timed on an idle machine;
   - the hosting plan's limits are unchecked;
   - the carbotope account name is unclaimed.

   These were carried as "deploy blockers, all yours" until 09-27c, then dropped.
2. **R2, the `rep_dC` prior.** You reopened it 09-29. The menu is `notes/r2_explained_2026-09-30.md` §6:
   (a) keep it as a named shim, or (c) σ 0.2 centred on 0.776, at −16.0. No ruling yet.
3. **The σ-audit's three objective items:**
   - `gcb_ocean_sink` 0.4 uninflated;
   - the `excess_c14_ocean` target set;
   - `CCX_ICE_DISCREPANCY` (off).

   Plus the freeze record's OUT list (five shims, eleven provisional constants).
4. **Freeing `ra_ratio` (≈ 0.08) under the AR6 GPP cap.** It would gain +3.2 log-units (09-30 g). It was
   not in #14.
5. **A century-scale q10 split** (09-29). Recorded view: "even less motivated now". Never ruled.
6. **The pre-registration's P1 wording** (09-28 e). Low stakes: P1 passes in every form.
7. **The scenario menu's descriptors** (`app/global.R:118–122`) are still marked drafts.
8. **`f_luc_wood` = 0 is uncited**, and **`kz_deep_frac`** is held up only by its Jacobian (z −2.79)
   (09-29 e).
9. **The sink→source "major caveat" wording** (09-29). It belongs in B8. Its numbers moved at hilda33d
   (K 740, β 2.20).
10. **Listing `INDEX_ccx_phi.md` in `FaIRtoFrEDI/CLAUDE.md`** needs your approval (09-29). It is still not
    listed.
11. **Two of your 09-24 questions were never answered:**
    - Q2: is the Revelle effect on year-to-year scatter really that large?
    - Q5: is there literature newer than Joos 2013 for card 5? This now matters more: see A5.
12. **Never explicitly ratified:**
    - the W4 copy ratchet;
    - the Futures tab's fitted-range caveat;
    - GATE V's phase-blind statistic.
13. **Pending work, not rulings:**
    - axis labels and legend titles have never been measured against their panels;
    - `calibration/diag_app_params.R:52` still carries a typed year span.
