# Handoff — 2026-09-08b. THE TWO DECLARED-OR-RAILED QUANTITIES ROUND 3 LEFT: `u_hs` (declared 38 m/yr = a 70 Sv flush) and `h_ml` (40 m in every HILDA round). What the literature says each should be, how far the model is from it, and the tests that decide the fix before a round 4.
# **⛔ Design note for a ruling. Nothing built, nothing launched. Canonical `ent26`. Every number below is either GENERATED (the R one-liners are quoted) or CITED; recollections are labelled.**

Read first: `handoff_2026-09-08_round3_result.md` (the result), CHANGELOG 2026-09-08. Related memory:
[[ccx_round3_result]], [[ccx_hs_pump_probe]], [[ccx_hs_endmember_probe]], [[overturning_and_mld_literature]].

## 0. What round 3 established, restated as two open quantities
The HS pump fixes the deep biology (δ¹³C row −27.6 → −7.0, ALK −13.8 → −0.1, rest −47.8 → −9.0) and every basin buys it
with **137.5 gC m⁻² yr⁻¹ = 7.94 GtC/yr** of cold-box export (+3.0σ of the float-based prior) plus a cold surface δ¹³C at
z +3.8. The export that holds a given deep enrichment is proportional to the flush of HD, `u_hs`, which is DECLARED
(HILDA's 38 ± 17 m/yr) and was never fitted or observation-pinned. Separately, `h_ml` sits at **39.8 m** in every HILDA
round (44 / 37 / 39.8) against `ent26`'s 134 m, and the two basin families of every round differ mainly in it
(40 vs 180–200 m), with the δ¹³C gradient row as the lever.

## 1. `u_hs` — the flush against the observed overturning
**The model's number (generated):** `u_hs` 38 m/yr × a_hs 5.776e13 m² (16 % of each hemisphere) = 2.195e15 m³/yr =
**69.6 Sv**, as a two-way gross HS↔HD exchange (`R/model.R`, the (b) limb; HILDA Fig. 1 calls `u` an "HS↔HD exchange").

**The observed deep-water formation, cited:**
| water mass | rate | source |
|---|---|---|
| NADW crossing 32 °S | **18 Sv** | Talley 2013, Oceanography 26(1):80–97, Fig. 6a text: "The 18 Sv of NADW that flow across 32°S" |
| AABW formation | **29 Sv** | Talley 2013: "total of 29 Sv formation of Antarctic Bottom Water … consistent with various independent formation rate estimates" |
| AABW formation | **21 ± 7 Sv** | Lumpkin & Speer 2007 (J. Phys. Oceanogr. 37:2550), as quoted by Cessi 2019 (Annu. Rev. Mar. Sci. 11:249): "Lumpkin & Speer (2007) estimated 21 ± 7 Sv, while Talley (2013) estimated 29 Sv" |
| NADW returned to intermediate/surface | "approximately 18 Sv" | Cessi 2019 |
| abyssal upwelling north of 30 °S | 10–15 Sv | Cessi 2019 (de Lavergne et al. 2016b) |

The cold box is BOTH hemispheres' high latitudes, so the comparable quantity is NADW + AABW = **39–47 Sv**. Over the HS
area that is (generated: `Sv × 3.156e13 / 5.776e13`) **21–26 m/yr** — inside HILDA's own 38 ± 17 but at its low edge.
⚠ Note the 13 Sv of Talley's AABW is RECYCLED NADW; a "formation" sum double-counts it, so 39–47 is an upper bound on the
independent flush; ~34 Sv (18 + 16 new) is the lower reading ⇒ **18–26 m/yr**.
**So the flush is 1.5–2× the observation — not the 4× of the export excess.** Something else carries the rest.

**The export accounting (generated, Martin b = 0.86; recollection: Martin et al. 1987's canonical exponent, UNSOURCED here):**
the model's HS export leaves a box `h_hs` = 400 m thick, so the literature-equivalent is the flux at ~400 m, not the
100–500 m ANCP the prior was built on: F(400)/F(100) = 0.30, F(1000)/F(100) = 0.14. Of Nowicki 2022's 10.2 PgC/yr global
export that is **3.1 GtC/yr at 400 m, 1.4 at 1000 m**; of Liniger 2025's 2.69 PgC/yr Southern-Ocean export, 0.8 / 0.4.
The model's 7.94 GtC/yr from the cold box alone is therefore **2.6× the WHOLE ocean's 400 m flux and 5.6× its 1000 m
flux** — i.e. the HS pump is standing in for the global remineralisation loop that the real deep ocean accumulates
along a ~1000-yr path, and it does so through a 1.5–2× too-strong flush. The two factors multiply to ~4.
**Hypotheses, ranked:** H1 the flush (`u_hs`); H2 the horizon (`h_hs` 400 m makes "export" a deep flux — the prior's
meaning shifted with the fitted thickness); H3 the LS pump's remineralised carbon does not reach HD at the right rate
(the conduit exchanges interior↔HD at τ_q 538 yr and the export shape is GLODAP's shallow profile), so HD's enrichment
must be made locally. ⚠ H3 is the one where "implausible = bug" applies: check the sign and magnitude of the
interior→HD carbon flux at the winner before invoking physics.

**Tests (cheap, one spinup + transient each, at the round-3 winner; pre-register before running):**
- **T1 (H1):** profile the likelihood in `pump_hs_gcm2` alone at `u_hs` ∈ {38, 30, 24, 18} m/yr. Prediction: the
  conditional optimum scales ~linearly with `u_hs` (137 → ~85 at 24), and the HS surface δ¹³C falls with it.
- **T2 (H2):** same profile with `h_hs` pinned at 75 m (HILDA's) vs 400. Prediction: a thinner box wants a SMALLER
  export per area to hold the same HD enrichment only if the gas-exchange/residence ratio changes it —
  [[ccx_hs_endmember_is_kw]] says thickness cancels in the steady ratio, so predict NO first-order change; a large
  change would mean the horizon is doing work the algebra says it cannot.
- **T3 (H3):** at the winner, read the flux trace: net carbon interior → HD through the conduit, GtC/yr, and the LS
  pump's remineralisation below 1000 m. If interior→HD is small or reversed, the model's deep water cannot inherit the
  low-latitude loop's carbon and the HS pump is compensating for a missing path — that is a structure question, not a
  prior question.
- **T4 (the observable the model has never been compared with):** the model's total remineralisation below 1000 m (LS +
  HS) vs the literature 1.4 GtC/yr (Nowicki × Martin). A single number, generated, that says whether the deep carbon
  budget is right for the wrong reason.

**Ruling options for `u_hs`:** (a) DECLARE it at the observation, 22 ± 4 m/yr (34–47 Sv), and refit (cheapest, one
declared value moves); (b) FREE it with a prior centred there (log-sd ~0.3) — HILDA fitted it too; (c) leave 38 and
re-centre the export prior on the 400 m/1000 m flux meaning (H2 accounting) — weakest, because it moves the prior to
meet the model. **Recommendation: (b), with T1 and T3 run first** so the round-4 prereg can predict the export.

## 2. `h_ml` — 40 m against the mixed-layer climatologies
**What the model's `h_ml` IS:** a time-constant low-latitude mixed-layer THICKNESS (no seasonal cycle in thickness; the
seasonal SST/`sst_seas_amp_*` machinery is separate), the layer the air–sea flux and the pump act on, and — since the
HILDA boxes — no longer the sole bomb-¹⁴C capacity (HS/HD carry the cold half). `ent26` (column) fitted **134 m**; every
HILDA round fits **~40 m** with a 180–200 m twin family 5 log-units behind. The 09-07c reading was that the ML depth is
being used as a δ¹³C-gradient lever (the two families differ by ~5 on `ocean_grad_d13c`).

**The observation, cited (no global annual mean is printed in either paper; the number must be COMPUTED from the
product):** de Boyer Montégut et al. 2004 (JGR 109, C12003, doi:10.1029/2004JC002378) — 2° profile-based climatology,
criteria ΔT = 0.2 °C or Δσθ = 0.03 kg m⁻³ from 10 m; averaged profiles give a 25 % shallow bias, so use the
individual-profile product. Holte et al. 2017 (GRL 44, doi:10.1002/2017GL073426) — ~1.25 M Argo profiles, monthly 1°
climatology, density-threshold AND hybrid-algorithm MLDs; winter maxima > 1500 m in the Labrador/Nordic Seas, ~400 m
elsewhere at high latitude; algorithm vs threshold differ 50 ± 5 m (SO Indian/Pacific), 90 ± 10 m (Labrador Sea),
20 ± 1 m (subtropics) at the winter maximum. ⚠ Recollection, UNSOURCED: the low-latitude ANNUAL-mean threshold MLD is
of order 30–60 m and the subtropical winter maximum 100–150 m — i.e. the HILDA rounds' 40 m is not obviously wrong and
`ent26`'s 134 m looks like a winter or a bomb-capacity number, not an annual mean.

**The computation (specified, NOT run — the product is a 115 MB download,
`https://mixedlayer.ucsd.edu/data/Argo_mixedlayers_monthlyclim_04142022.nc`, awaiting Marcus's OK):**
`data-raw/build_mld_targets.R` → `data/obs_mld.rds`: monthly density-threshold MLD (`mld_dt_mean` or the file's
equivalent) → annual mean per cell → cos(lat) area-weighted means over (i) |lat| < 57° = the LS region (`h_ml`'s
observation), (ii) |lat| ≥ 57° = the HS region (`h_hs`'s, for the record — the algebra says thickness is not a lever),
with the between-cell sd as the representation spread; report both the mean-of-monthly and the annual-maximum
variants, because a time-constant thickness can be argued either way and that choice is a RULING. 57° is
1 − sin(57°) = 0.16 of a hemisphere, the model's own `hs_frac`.

**Tests:** **T5** pin `h_ml` at the computed LS annual mean at the round-3 winner and re-read every stream — which
rows pay (the δ¹³C gradient? the seasonal `d13c_seasonal_MLO`? the bomb curves?) says WHAT the 40 m is buying. **T6**
the same at the annual-maximum variant. **T7** re-run the 09-07c family comparison (40 vs 190 m) on the round-3 rows to
see whether the lever is still `ocean_grad_d13c` now that the HS pump carries the deep.

**Ruling options for `h_ml`:** (a) observation-pin it (declared, from the climatology, with the mean-vs-max choice made
explicitly); (b) free it with a prior centred there; (c) leave it fitted and accept 40 m as the model's annual-mean
reading — defensible ONLY if T5 shows nothing physical is being bought. **Recommendation: compute the observation first
(the download), then (b).**

## 3. Round-4 shape, if both go the (b) way
32 parameters (`u_hs`, `h_ml` with observation priors), the HS pump prior re-stated at the 400 m-flux meaning if T2 says
the horizon matters, objective #10 + #11, harness as round 3. Predictions to write once T1–T7 are in: the export lands
inside the prior's 2σ; the HS surface δ¹³C moves toward +1.31; `h_ml` interior; the profile stays inside 2σ; the rest-
of-likelihood stays ≥ −10. **Owed before any of it:** a sourced Martin exponent (or Nowicki's own 1000 m flux), and the
conduit + HS limb in the pump/ALK operators.
