# Handoff — CarbonCycleEmulator, 2026-09-04 (second session of the day)
# **THE GATE SET WAS AUDITED AND CUT. 4, 8, 10 RETIRED · GATE V ADDED · 12 DEMOTED.**
# **⭐ THE RULE THAT DID IT (Marcus): every test compares an OBSERVED VARIABLE — including**
# **measures of interannual variability and other SECOND-ORDER observations — or a PHYSICAL LAW.**
# **⛔ AND P5 IS NO LONGER "FALSIFIED": gate 12 is a comparison now, not a test.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, commits
`613a4ca..e7d8a89` (3). No remote; nothing to push.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-04_ent26_adopted.md` — the adoption whose open decision 1
this session answered and then reversed.

**Suite: 1742 → 1757 pass / 0 fail / 0 error / 4 skip.** Green throughout.

---

## 0. WHAT THIS SESSION DID

1. **Measured open decision 1 (gate 4)** — and found it had no power. `83307a5`.
2. **Audited the whole gate set against Marcus's rule**; he ruled; I implemented. `109107a`.
3. **Scoped both candidate mechanisms for gate V** (solar, anthropogenic aerosol). Both declined. `e7d8a89`.
4. Found and fixed **two dead-code bugs** on the way (§5).

---

## 1. ⛔ GATE 4 HAD NO POWER — AND THE "SMOOTHER THAN THE DEFAULTS" READING WAS A TREND ARTIFACT

Open decision 1 was *"why did the AF decadal spread get SMOOTHER? 0.48× observed against defaults'
0.76× — the clearest new lead the adoption produced."* Both numbers reproduce exactly (0.763 /
0.478 against the retired target), so this was a **re-reading of the same measurement**.

* ⛔ **THE TWO SIDES OF THE GATE USED DIFFERENT ESTIMATORS.** `DG_AF_OBS_DEC` was seven typed 2-dp
  literals. Recomputed from the GCB budget the likelihood reads, only the **MEAN OF ANNUAL AF**
  reproduces all seven (0.3534 0.4265 …), while `dg_gate4()` always computed the model side as a
  **RATIO OF DECADE SUMS** (0.3568 …). Rounding hid it in six of seven decades; **only the 1960s
  exposes it** (0.3568 → 0.36 vs the typed 0.35). The gate's BOUND is that vector's sd: **0.0515 →
  0.0483**, so the model was asked to beat a spread 6.6 % wider than the observations have.
* ⛔ **70 % OF THE TARGET'S VARIANCE IS SAMPLING NOISE.** Anomaly 0.911 GtC/yr and white (ρ +0.014)
  ⇒ per-decade floor rms **0.0404** against an observed spread of **0.0483** ⇒ resolved decadal
  signal **0.0265**. Analytic se **validated against a matched Monte Carlo** (agreement 1–4 %).
* ⭐⭐ **THE DEFAULTS' ADVANTAGE WAS A DRIFT.** Detrended, defaults **0.617** and ent26 **0.613** —
  identical. The adoption changed the AF **trend** (+0.0157 → +0.0057 /decade) and `sd()` over seven
  decades charged it to variability. And the observed trend is **+0.0147 ± 0.0080, t = +1.83**, with
  both arms inside its 95 % CI.
* ⭐ **DECISIVE:** every arm sits INSIDE a null built on its OWN trend and OWN anomaly amplitude
  (ent26 0.0246 ∈ [0.0165, 0.0489]). **Nothing decadal is left over.**
* ✅ **What survives:** the 2020s at z **−2.68** — model growth 22.92 vs GCB 28.50 GtC, ~1.1 GtC/yr
  of excess sink, cumulative CO₂ +0.37 ppm @2019 → **−2.26 ppm @2024**. ⚠ **2024 alone is −2.89 GtC,
  52 % of it** (observed record 7.92 GtC/yr read as 5.03) — the ENSO arc, not a decadal finding. The
  steadier ~1 GtC/yr over **2020–2022 is unattributed and still open.**

`calibration/diag_gate4_af_spread.R`, note `diag_2026-09-04_gate4_has_no_power.md`,
memory `ccx_gate4_no_power`.

---

## 2. ⭐⭐ THE AUDIT, AND WHAT THE SET LOOKS LIKE NOW

| gate | quantity | source | independent of the objective? |
|---|---|---|---|
| **V** | interannual CO₂ growth variability | GCB, 2nd-order | **yes — nothing scores it** |
| **Q** | air-sea δ¹³C disequilibrium | Quay 2003 | **yes** |
| **G** | ocean surface DIC | GLODAP | **yes** |
| 5 | bomb ¹⁴C peak / lag / e-fold | Hua 2022 | different functional of a scored stream |
| 6 | MLO seasonal amplitude **growth** | Scripps | different functional; **PASSES**, +19.4 % vs +15.6 % |
| 7 | land / ocean sinks | GCB (obs + model) | no — documented restatement |
| S | SPO ocean limb phase | obs **inverted through the model** | ⚠ **self-declared CIRCULAR, all consts provisional** |
| 11 | uniformity screen | — | a screen, not a claim |
| 12/12a/12b | pulse IRF | **another model** | ⚠ **a COMPARISON, not a gate** |
| ~~4~~ ~~8~~ ~~10~~ | — | — | **RETIRED** |

**Why each retirement:**
* **4** — numerator is a scored stream, denominator a model input; its 2020s signal reappears in
  `co2_level_MLO` at **mean z −0.96, max |z| 1.63**, the largest decadal excursion in that stream's
  record. AF still COMPUTED and PRINTED; `dg_gate4_verdict()` **ERRORS with the reason**.
* **8** — differenced two station-years that `d13c_level_MLO/SPO` score every year of, at a typed
  0.10 ‰ with no derivation.
* **10** — its own header said target AND sigma came from `ccx_deep_d14c_target()`, "the LIKELIHOOD's
  own accessor". **A gate tied to the stream it checks cannot fail independently of the optimizer.**
⚠ Each retirement block records **what was lost**: 8 and 10 were the only places certain quantities
were PRINTED beside their targets. **Bring back the print, never the verdict.**

---

## 3. ⭐ GATE V — AND ITS FAILURE IS **NOT A BLOCKER**

Estimator identical both sides: `grow_y = AF(y)·emis_y + eps_y`, AF a natural spline (`DG_V_DF` 3);
the gate is `sd(eps)` in GtC/yr. **The bound is DERIVED FROM THE OBSERVATION** — the sampling error
of an sd, `sd/sqrt(2(n−1))` = **0.080 GtC/yr**, MC-validated to 3 decimals — **two-sided** at
`DG_V_NSD` = 2. Nothing in the objective asks for it (`co2_level_*` scores levels at a soft 1.0 ppm).

| | sd GtC/yr | ratio | z |
|---|---|---|---|
| GCB 2025 | **0.911 ± 0.080** (n 66, ρ +0.014 = WHITE) | 1.00 | — |
| defaults | 0.638 | 0.70 | −3.42 |
| **ent26** | **0.698** | 0.77 | **−2.67 FAIL** |

⚠⚠ **MARCUS, SAME DAY: "interannual variability is not a dealbreaker."** Recorded **at the gate** in
`lib_design_gates.R`. **Report it; do not chase it; do not read a FAIL as blocking a headline claim.**

**Knockout decomposition** (`diag_gateV_variability_drivers.R`, 5 runs in 0.5 s). Temperature is
**SMOOTHED with an 11-yr centered mean, NOT held** — `ccx_hold_climate()` removes the TREND and would
compare two climates:

| driver removed | sd | variance lost |
|---|---|---|
| **ENSO** (land + ocean) | 0.405 | **−66.3 %** |
| **TEMPERATURE** (`gmst` + `sst_anom_*`) | 0.505 | **−47.8 %** |
| VOLCANIC (AOD → diffuse light) | 0.677 | −6.1 % |
| all three | 0.190 | −92.6 % |

⚠ Singles sum to 0.586 against the joint 0.451 — **the difference is INTERACTION**, printed not
hidden. Driver-free residual 7 %. ⇒ **The drivers would need 1.76× their present combined variance
to close it**, and **ENSO is the largest share — gate V points at Fix B.**

---

## 4. ⛔ BOTH CANDIDATE FIXES FOR GATE V ARE DECLINED

**SOLAR → PHOTOSYNTHESIS: dead on magnitude, ~175×.** The early-20th-century rise Marcus named **is
there** (CMIP7/FaIR-1.6.0 solar ERF, **1900-19 → 1950-69 = +0.0267 W/m²**; 11-yr amplitude 0.0378),
and both are tiny converted: ΔTSI **0.031 %** and **0.011 %**. With NPP taken proportional to
irradiance — a **CEILING**, since photosynthesis saturates — that is **0.0082 GtC/yr** of 11-yr
amplitude = **0.91 % of the anomaly sd, 0.004 % of its variance**, and **0.29 GtC over 50 yr** for
the secular shift. `gamma_diff` 0.25 × Pinatubo AOD 0.110 is **1.445 GtC/yr**.
⭐⭐ **THE STRUCTURAL REASON, WHICH GENERALIZES: aerosols change the DIFFUSE FRACTION** (light into
shaded canopy — Gu 2003 / Mercado 2009, the pair the volcanic term already cites); **the sun changes
TOTAL irradiance, 1:1 at best.** The high-leverage channel is unavailable to solar **by physics**.
**Nothing was implemented** — no run rescues three orders of magnitude.

**ANTHROPOGENIC AEROSOL → DIFFUSE LIGHT: real, but unidentifiable.** CMIP7 SO₂ 2.3 → **peak 139.9
Mt/yr in 1979** → 71.8, but its interannual sd about a 12-dof spline is **2.7 % of the peak**
(sulfate lifetime is days). Gate V moves **0.698 → 0.690**, slightly the WRONG way. What it DOES
move is the **AF trend, +0.0057 → +0.0120 /decade** (obs +0.0147 ± 0.0080), level still right.
⛔⛔ **~100 % DEGENERATE WITH CO₂ FERTILIZATION**, and the frozen column says the opposite — the same
trap as the August `gamma_diff` pricing (frozen overstated by 82 %). Re-optimizing (`beta_max`,
`fert_k`): frozen **−106 / −692 / −2810 / −11362** becomes **+5.3 / +8.3 / +1.0 / −151.9**.
⚠ FACE narrows but does not decide: R(400→564) **11.5 → 15.5 %** against an envelope from **0 %**
(EucFACE, mature P-limited) to **23 %** (Norby 2005 young plantations).
⇒ **THE ARGUMENT AGAINST ADDING IT NOW: it relocates `beta_max` 2.3× while changing nothing
measurable**, and `beta_max` carries the pulse IRF and every fertilization result.
⇒ **REVISIT ONLY with a target keyed to the POST-1979 DECLINE** (the brightening signature —
the one feature fertilization cannot imitate). **Never with more CO₂ data.**

---

## 5. 🐛 TWO PIECES OF DEAD CODE FOUND ON THE WAY

1. ⛔ **`diag_design_gates_unscored.R`'s SUMMARY COULD NOT RUN AT ALL.** `cn` was the typed literal
   `"from90"` — an arm quarantined that same day — so every `g6/g8/g10/g11[[cn]]` lookup indexed a
   NULL. Now `CCX_MODE_CANONICAL`. **The file's own `vecs` block already states the
   label-derives-from-the-constant rule; it was applied there and not twelve lines later.**
2. ⛔ **`test-pulse.R` asserted the model matched Joos within a typed 40 % band — at
   `ccx_default_params()`, not at the fitted mode.** Gone with the gate-12 demotion.

---

## 6. ⚠ GATE 12 IS NOW A COMPARISON — AND WHAT THAT CHANGES

Marcus: *"make gate 12 a post-model comparison but not a strict test: we don't necessarily expect to
meet it, the long lifetime should be an emergent behavior."* Joos 2013 is another MODEL, and **no
observation constrains a CO₂ perturbation lifetime** (¹⁴C measures tracer transport; ~2.8× apart at
100 yr). Still computed and PRINTED with *inside/BELOW/ABOVE*; **nothing scored, gated, or chased.**

⛔⛔ **P5 IS NO LONGER "FALSIFIED."** IRF(100) = 0.276 is a **REPORTED DIFFERENCE** about where the
emergent lifetime sits. **Every record saying "P5 FALSIFIED" predates 2026-09-04** — including
paragraphs still standing in older notes and handoffs. `test-joos-irf.R` keeps every assertion,
because none of them is about our model: the single-exponential locus is parameter-free ALGEBRA and
the rest are properties of the REFERENCE.

---

## 7. ⚠ NON-OBVIOUS STATE

* **Torch: nothing running.** Everything this session ran locally in seconds (a full model run is
  ~0.2 s; the whole gate-4 diagnostic is 2 runs).
* ⚠ **`diag_gates_at_refit_20260903.R` is pinned to `multistart_20260902_demean25`** (the 25-par
  refit, logpost −1482.61), NOT to `ent26`. That is pre-existing and correct for what the file is
  named for — but do not read its numbers as canonical-mode numbers. Use `dg_vector(CCX_MODE_CANONICAL)`.
* ⚠ **`DG_AF_OBS` / `DG_AF_OBS_DEC` are now COMPUTED at source time** from `ccx_prepare_obs()$gcb`.
  Sourcing `lib_design_gates.R` therefore reads the obs bundle (0.18 s). The retired literals survive
  as `DG_AF_OBS_TYPED` / `DG_AF_OBS_DEC_TYPED` and their provenance is pinned in `test-gate-bounds.R`.
* ⚠ **`JOOS_POINT_TOL` is now `JOOS_POINT_TOL_RETIRED`** — provenance only, read by nothing.
* ⚠ **MEMORY IS AT THE CEILING.** `INDEX_ccx.md` is **17,974 bytes of content** (excluding the 464-byte
  header) against an **18 KB hard ceiling**; `MEMORY.md` is 16,998 against a 12 KB soft target. I
  bought room twice this session by compressing genuinely stale text (the Hessian paragraph still
  said "1.11e6" and "`h_ml` STILL step-unstable", both superseded by the adoption).
  **⇒ THE NEXT ADDITION NEEDS A RESTRUCTURE, NOT ANOTHER TRIM.** 516 files.
* ⚠ Everything else from the previous handoff's §6 still stands: `pin90` retired and the
  free-vs-pinned check DARK; `ccx_default_params()$ent_seas_amp_SH` = 10.9524; `tau_ex_seas_amp`
  implemented, defaulted 0, unfitted.

---

## 8. ⇒ THE OPEN DECISIONS, RE-RANKED

1. ⭐⭐ **GATE S IS CIRCULAR, and the check that would fix it is already on disk.** Its target is an
   SPO observation **inverted through the model's own signatures**; all six `SPO_SEAS_*` constants
   carry `status = "provisional"` and say so. The independent check its own source names — the **MPI
   SOM-FFN surface-ocean pCO₂ climatology**, `data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc` — is
   downloaded and used only to bracket `sst_seas_amp`. ⭐ **The same product is the Fix B pre-test
   that has been owed since 09-03, and gate V's knockouts now point at Fix B.** One measurement
   serves both. **This is the top of the list.**
2. ⭐ **Fix C on its own terms** (P5's lifetime). ⚠ Re-read §6 first: it is no longer a falsified
   claim, so the question is now "what makes the tail emergent", not "how do we pass Joos".
3. ⭐ **`sst_seas_amp_NH` at −3.91**, the worst prior violation. Unchanged, needs its own diagnosis.
4. **A posterior.** The adoption's §1 says both stated blockers are gone at `ent26`.
5. **The 2020–2022 growth deficit** (~1 GtC/yr, unattributed) — the half of the 2020s miss that is
   NOT the 2024 El Niño.
6. **Observations we HAVE and do not test:** `obs_d14c_station_validation` (160 station Δ¹⁴C points,
   built explicitly as a HELD-OUT VALIDATION SET, read by nothing but its build script); the Eide
   ocean δ¹³C Suess **depth profile** in `obs_oceanic_suess$eide_profile`; the MOD17 **global** NPP
   level (52.7 PgC/yr — only the NH *share* is used).
7. **Not in the repo at all:** the ocean **anthropogenic carbon inventory** (GLODAP/Sabine Cant —
   the ocean ¹⁴C inventory IS scored, but ¹⁴C measures ventilation, not buffer CAPACITY, and gate
   12a's standing verdict is an ocean-CAPACITY defect); and **atmospheric O₂/APO**, the independent
   observational split of land vs ocean sink, which would need an O₂:C stoichiometry layer.
8. **Still owed from before:** the 34 tied SPO copies on touch; the bare-overlay lint's remaining
   occurrences; a 26-par PINNED refit if the free-vs-pinned check is worth restoring.

---

## 9. ⇒ THE STANDING RULES THIS SESSION ADDED TO

* ⭐⭐ **A gate that reports ONE number for TWO mechanisms is evidence about NEITHER.** Gate 4's
  `sd()` could not separate a drift from a wiggle, so the same statistic ranked the UNCALIBRATED
  DEFAULTS above the adopted mode — and the ranking inverted the moment the two were separated.
* ⭐ **A gate whose target and sigma come from the stream it checks cannot fail independently of the
  optimizer** (gate 10, which said so in its own header and was kept anyway).
* ⭐ **Price a new NPP term CONDITIONALLY or not at all.** Twice now the frozen-parameter cost has
  been ~100 % wrong in the direction that rejects a real mechanism.
* ⭐ **Before believing a null, state what it could have detected** (the solar-cycle band search:
  93rd percentile of a band-matched white-noise null, with power down to ~15 % of the variance).
* ⭐ **When two mechanisms are degenerate, name the ONE feature that separates them** — here the
  post-1979 decline — and say plainly that nothing currently measures it.
