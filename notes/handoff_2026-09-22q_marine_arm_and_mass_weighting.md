# Handoff — 2026-09-22 (q). **Marcus's two R2/N5 questions, answered by measurement. The marine arm is EXTERNALLY VALIDATED and it STRENGTHENS the tie result instead of weakening it — the continental sites turn out to be the part of the network that OBEYS the mass balance. And T3 sizes the mass-weighting term at −0.98 ppm, which makes the `rep_dC` residue 36 % LARGER and is bigger than the entire relief re-centring the prior would buy. ⛔ On the way it found the model's code calling the same box a WHOLE ATMOSPHERE where it converts mass and a TROPOSPHERE where it feeds bomb-¹⁴C.**

> Self-contained for this half of the session. **Read first, in this order:** handoff **(p)**
> (the splice and the copy gate — the earlier half of the same session) · CHANGELOG 09-22 **(z)**
> and **(aa)** · `outputs/diagnostics/rep_dc_d13c_marine_20260922.log` ·
> `outputs/diagnostics/rep_dc_mass_weighting_20260922.log` · handoff **(o)** for everything before.
> ⚠ `~/.claude/CLAUDE.md` execution rules apply. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY — read
> `INDEX_ccx_ref.md` before answering anything about `rep_dC`, N5 or the app.

## 1. The model is untouched, a fourth time
`v1.0-hilda29l` at `3d1b0c0` is still the tag. **No model code, objective, mode file, parameter or
prior was modified.** Everything here is `calibration/`, `data-raw/`, two rebuilt observation
products, two diagnostic logs and `CHANGELOG.md`. Commits `c09b15e` · `2edbf4d`.

## 2. N5's MARINE ARM — Marcus: *"should we exclude the continental flasks?"*
`data-raw/download_data.R` (`fetch_mbl_sites`), `data-raw/build_hemispheric_flask_means.R`,
`calibration/diag_rep_dc_d13c_marine.R`; log `rep_dc_d13c_marine_20260922.log`.

**The argument for asking is about MASS, not cleanliness.** `rep_dC` compares a station against a
mass-weighted hemispheric box. NH continental boundary-layer air is ~6 % of NH atmospheric mass
(land ~0.39 × BL ~0.15); latitude-band-area weighting gives it its AREA share, several-fold more;
NOAA's MBL product gives it zero. **The two arms BRACKET what the box wants**, which is worth more
than either arm claiming to be the answer.

- ⭐ **THE CRITERION IS NOAA'S, NOT OURS.** `fetch_mbl_sites()` pulls the CO₂ MBL site selection
  from `gml.noaa.gov/ccgg/mbl/map.php?param=co2` — **43 sites**, parsed from the page's own
  `createMarker` calls — and **refuses** if the parse returns a short list or if it fails to
  CONTAIN `spo` and EXCLUDE `mlo` (NOAA's documented selection). **39 of our 87 are on it, the same
  39 for both species**, so the tie test keeps its common network.
- ⭐⭐ **THE EXTERNAL CHECK, which is what makes this a measurement and not a second judgment call.**
  ⚠ Over **the same 1989–2014 months**, never against the published 47-yr mean — the NH offset
  trends at −0.105 ppm/decade and that comparison would have manufactured a discrepancy.

| NH CO₂ offset | value | vs MBL zonal (+0.803, same months) |
|---|---|---|
| **marine (NOAA MBL sites)** | **+0.794** | **INSIDE** the arm's 95 % CI |
| all sites | **+1.288** | **OUTSIDE** |

  ⚠ **The SH does NOT reproduce**: +0.784 vs +0.857, outside a CI of ±0.065. A band-weighted mean
  over a sparse southern network is not NOAA's fitted sin-lat surface. **A limit, not a verdict
  change** — every verdict below is the same on all three arms.
- ⛔⛔ **THE DIRECTION IS THE OPPOSITE OF THE ONE PREDICTED, and the prediction was mine.** I argued
  −35.1 ‰ looked like a continental local source mix and that the marine arm would move toward the
  assumed −26.5. **It moves AWAY, to −39.9.** Removing continental sites cuts the CO₂ offset 38 %
  but the δ¹³C offset only 28 %, so the ratio steepens.
- ⭐⭐⭐ **§5 INVERTS THE INCREMENT ITSELF AND THAT IS THE FINDING.** The air the continental sites
  add carries **−27.7 ‰ [−29.6, −25.6] and CONTAINS the model's assumed −26.5.** ⇒ **the
  continental sites are the part of the network that OBEYS the mass-balance tie; the marine
  residual is the part that does not.** Result 2 is **strengthened** by the continental question.
- ⭐⭐ **ERROR BARS, which the (v) run had none of.** Block bootstrap **by year** (2000 draws, seed
  20260922 stamped in the log), resampling the **same years for both species** so the ratio keeps
  their covariance. **All six arm × hemisphere combinations EXCLUDE −26.5:** NH all-sites
  [−38.5, −32.3], NH marine [−46.3, −34.7]; SH all-sites [−18.1, −9.2], SH marine [−20.1, −10.6].
  **NH and SH do not overlap** ⇒ "no one value describes both hemispheres" now has a bound.
- ⭐ **The specific worry is answered:** the SH δ¹³C offset's own CI is **[−0.0204, −0.0022]** —
  small, but **excluding zero**. The SH half is a measurement, not a near-zero numerator.
- ⚠ **A POWER GUARD WAS NEEDED AND FIRES.** The SH *increment*'s CO₂ denominator is −0.018 ppm and
  its signature CI is **1242 ‰ wide** — it "CONTAINS −26.5" the way it would contain anything.
  `sig_verdict()` declares an interval wider than the plausible span of carbon source signatures
  (~35 ‰, −10 to −45) **UNINFORMATIVE** instead of returning a verdict. The SH increment is the
  live demonstration that it works.
- **Weighting sensitivity of the SIGNATURE** — the gap (v) left, which carried δ¹³C under three
  weightings but CO₂ under one: NH **−35.2 / −34.5 / −32.5** (all sites), **−39.9 / −40.8 / −35.5**
  (marine). ~5 ‰ against a ~13 ‰ gap; **the conclusion survives the ruling's wording.**
- ⚠ **Self-inclusion, measured and small.** The all-sites NH mean CONTAINS Mauna Loa, the station it
  is differenced against. NOAA's selection drops MLO anyway; it keeps SPO, and the `_mblx` arm
  prices that in the SH at **−0.0146 → −0.0151 ‰**. Negligible.
- **GATED:** the all-sites columns are **bit-identical** across the rebuild (max|diff| 0 on all
  three weightings, both products), so the marine arm cannot have moved the answer the ruling asked
  for. ⛔ Nothing adopted; **all-sites remains the primary**, per Marcus's ruling.

## 3. T3 — the mass-weighting term, sized
`calibration/diag_rep_dc_mass_weighting.R`; log `rep_dc_mass_weighting_20260922.log`.

- ⛔⛔ **THE CODE CONTRADICTS ITSELF ABOUT WHICH MEAN THE BOX IS.** `R/model.R:3874`
  (`gtc_per_ppm_hemi = GtC_PER_PPM / 2`) converts with **whole-atmosphere** mass ⇒ the box's ppm is
  a mass-weighted whole-atmosphere mean. `R/forcing.R:347` calls the same box *"a single well-mixed
  **TROPOSPHERE** per hemisphere with no stratospheric box"* — which is **why** the bomb-¹⁴C input
  is a stratosphere→troposphere FLUX rather than a production rate. Both are load-bearing where they
  sit; they cannot both describe the same box, and **`rep_dC` absorbs the difference.**
- **Inputs, each labelled in the log.** `f_strat` **0.1645** DERIVED (area-weighted mean tropopause
  166.6 hPa from a 100→300 hPa profile, flat-tropopause sensitivities printed); `γ` **1.837 ppm/yr**
  OBSERVED from the repo's own MLO (1.866) / SPO (1.808) series over 1989–2014; `Γ`, the
  **mass-weighted** stratospheric mean age, **ASSUMED and carried as a BAND 1.5–5.0 yr**.
  ⇒ **D_strat = −0.45 to −1.51 ppm, midpoint −0.98.**
- ⚠ **A CORRECTION TO A NUMBER I GAVE MARCUS IN CHAT.** I estimated ~1.8 ppm using a flat 5-yr age
  and a *recalled* 2.4 ppm/yr growth. A flat 5 yr is the mid/upper-stratospheric figure and roughly
  half of stratospheric mass sits in the lowermost stratosphere where air is far younger; measured
  growth is 1.837. **The banded answer is about half my first pass.** Γ remains the weak input.
- ⭐ **THE RESULT.** Expected box − station = **+0.738** (marine, OBSERVED) **+0.029** (continental
  at its MASS share — an order-of-magnitude BOUND, not a measurement) **−0.98** = **−0.215 ppm**:
  the box should sit slightly **BELOW** its station. The model has it **+3.408** above.
  **Discrepancy +3.62 NH / +3.79 SH, against +2.67 / +2.81 without this term — 36 % / 35 % larger.**
- ⭐⭐ **THE DECISION-RELEVANT COMPARISON FOR R2.** Re-centring the prior on the measured offset
  moves it **+0.74 ppm**; this term moves the TARGET **−0.98** the other way — **ratio 1.33 (NH),
  1.21 (SH): larger than the entire relief re-centring buys.** ⇒ **rule R2 against the LARGER
  residue, not the smaller one.**
- **The one download that would sharpen it:** an observational mass-weighted stratospheric mean age.
  Everything else in the calculation is measured or bounded.

## 4. WHERE R2 STANDS NOW, and what is left
**Nothing about R2 has been adopted and it is still a ruling.** What has changed is the size of the
thing being ruled on: the residue is **+3.62 ppm**, not +2.67, and re-centring buys less than the
correction costs. From the test menu put to Marcus, **T3 is done**; three remain:

1. **T1 — the product profile along a `rep_dC` ladder.** Fix `rep_dC` at 3.52 → 0.78, **fully**
   re-optimise the rest at each rung (the 09-22 (u) side test moved 8 of 29), and read the
   **PRODUCTS**, not just loglik: IRF(100), the 1000-yr partition, airborne fraction, gate D's
   asymmetry, the δ¹³C gradient, `CO2_PI`, the GCB sink split. **Flat products ⇒ R2 is a labelling
   decision; a product that moves ⇒ it is a physics decision.** This is the direct answer to
   "potential impact" and needs no objective change.
2. **T2 — the release test.** (u) says the cost of forcing `rep_dC` down lands on `co2_icecore`
   (−13.45) and bomb-¹⁴C (−10.7), not the station levels. Re-run the ladder with (a) the ice σ at
   its **measured** 1.05 ppm scatter instead of its stated ~4.04, (b) the ice block dropped,
   (c) bomb dropped — **diagnostic arms, never adopted.** If the cost collapses under (a),
   `rep_dC` is standing in for a mis-set ice weight; under (b), for a preindustrial-anchor error.
3. **T4 — a full refit under the candidate prior, registered as an ARM** (like `hilda32f`), scored
   on the 26 rows and the gates. The only thing that answers "what would the model look like".
   ⛔ Still the objective change: freeze record §4.1, a ruling then a restamp of every mode.

⛔ **And the standing constraint on all of it:** >1/3 of `rep_dC`'s value is ISOTOPIC, so R2 is
never a CO₂-only ruling — and §2 has now shown the isotopic side is the harder half, not the softer.

## 5. State to carry — non-obvious
- ⚠ **`data-raw/downloads/*` IS GITIGNORED except `MANIFEST.csv`.** So `mbl_sites_co2.txt` is **not
  in the repo** and a fresh clone must re-run `fetch_mbl_sites()`. The build **errors loudly** if it
  is missing and explicitly refuses to fall back to an invented marine rule. Its MANIFEST row (URL,
  citation, date, SHA-256 `f692644f3cf7`, 1144 bytes) was appended by a targeted script rather than
  by re-running the whole of `download_data.R`; **verified purely additive — 47 → 48 rows, no key
  lost, every pre-existing row identical.**
- ⚠ **The two observation products were REBUILT** (`obs_d13c_hemispheric.rds`,
  `obs_co2_hemispheric_flask.rds`) and are now 18 columns instead of 8. **The all-sites columns are
  bit-identical**; the new ones are `*_mbl` and `*_mblx`. The arm definitions travel **in the
  product** as an `arms` attribute, so a reader never has to take the script's word for it.
- ⚠ **The (v) log is NOT overwritten.** `rep_dc_d13c_hemispheric_20260922.log` is still the
  all-sites artifact; the marine work writes `rep_dc_d13c_marine_20260922.log`. Deliberate — a
  same-day re-run of the old script WOULD overwrite it.
- **The app is RUNNING on `http://127.0.0.1:7788`**, restarted by this session at the splice
  (handoff (p) §4). ⛔ Stop it via the process holding the RESOURCE
  (`lsof -nP -iTCP:7788 -sTCP:LISTEN -t`), never `pkill -f` on the runApp string.
- ⚠ **`CarboTopeSubstack.docx` + its `~$` lock are still in the repo root.** Marcus's drafting —
  do not read, edit or commit. Untracked, left as found.
- ⚠ **`outputs/diagnostics/whole_model_scorecard_20260920_hilda29l.rds` has an uncommitted
  modification PREDATING this session.** Still not touched, still not committed.
- **Suites run this session:** `app|review` **117/0** (2 pre-existing warnings),
  `struct-lint|overlay-idiom` **13/13**, the new copy gate **36/0**. The full suite was NOT re-run;
  the two standing failures from (o) §6 are untouched by anything here.
- **Memory:** `ccx_rep_dc_tie_unsupported` and `ccx_rep_dc_co2_bias` both extended in place (the
  original findings kept, the new sections appended); `INDEX_ccx_ref.md` updated on both lines,
  11.7 KB, inside budget. `ccx_app_three_histories` from (p) is also indexed there.
