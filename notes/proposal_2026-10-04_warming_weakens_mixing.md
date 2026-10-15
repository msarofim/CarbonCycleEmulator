# PROPOSAL 2026-10-04 — ocean mixing weakens as the climate warms (a new mechanism) — FOR MARCUS'S RULING

> **RULED 2026-10-04 (Marcus), verbatim labels:**
> - Q1: "Thermocline mixing only (Recommended)".
> - Q2: "Obs × law, fixed (Recommended)".
> - Q3: "GMST minus lagged deep ocean (Recommended)".
> - Q4: "History + futures, one #16 refit (Recommended)".
> - Q5 (the pump) was not asked, so constraint 2 stands as written and the regenerated-carbon omission is disclosed.
>
> **⇒ To BUILD:** g = (1 + s·T_key)^(−q/2) on the upper part of K(z), with q = 1 and s re-derived against the ruled key
> (§4's 4.4 %/K is per K of GMST). T_key = max(0, GMST − T_deep), where T_deep is GMST lagged exponentially with the
> climate module's slow timescale. The export is rescaled with g. It is fixed (structural, not fitted) and on in
> history and futures; it is priced on every registered mode and enters objective #16 with the greening decision.

> **Status.** Drafted on Marcus's direction (2026-10-04): *"The 'ocean mixing slows as the ocean warms' follows pretty
> directly from physical understanding, so I would be interested in incorporating that into the model."*
> - Nothing is built and no objective is changed. The rulings asked for are in §7.
> - The code facts come from a read of both cores. The literature numbers are in §4, each with its source.
> - The idea came out of the MAGICC ocean review (CHANGELOG 10-04 l). MAGICC weakens its upwelling and thermocline
>   diffusivity with warming, for HEAT only. CCX would be the first of the two to apply it to carbon and its isotopes.

## 1. The physics, in one paragraph (the app's sentence comes from this)
- Warming is strongest at the surface, so the upper ocean becomes more stably stratified.
- In a more stratified ocean, the same mixing energy moves less water across density surfaces. Deep-water formation
  also weakens.
- So the ocean carries anthropogenic carbon (and bomb ¹⁴C) down from the surface more slowly, and the ocean sink falls
  behind what a fixed-circulation ocean would take up.
- It is a positive carbon-climate feedback, separate from the solubility one CCX already has (warmer water holds less
  CO₂).

## 2. What the 08-25 record said, and why it does not close this
- 08-25 (c) abandoned "stratification" because a STATIC `kz` scan moved the airborne-fraction TREND by only ±0.0002
  (CHANGELOG 08-25 c; `calibration/diag_af_trend_levers.R`). That question was whether stratification explains a
  historical trend.
- This proposal asks something else: whether the FUTURES should carry a known physical feedback.
- A time-varying K was never measured. The 08-25 conclusion "a time-varying kz would act only through the level" was
  inferred from the static scan (`calibration/diag_fert_ridge_gates.R:11-15`).

## 3. The mechanism, as it would enter CCX (code facts verified 10-04)
**Where mixing lives.** The interior diffusivity is K(z) = kz·[f + (1−f)·exp(−(z−h_ml)/z_K)] (`ccx_kz_profile()`,
`R/model.R:3886-3906`).
- It is computed once per run into `aux$kz_int` and read at each layer interface in both cores (R 2980; C++ 775).
- At hilda34g (kz 14,224 m²/yr, f = 0.0079, z_K 253 m), the exponential "upper" part is 99 % of K at the mixed-layer
  base, 93 % at 620 m, 48 % at 1.3 km and 0.5 % at 2.6 km.

**The factor.** g(t) multiplies the upper part only:
K(z, t) = kz·[f + (1−f)·g(t)·exp(−(z−h_ml)/z_K)] = K_int(z) − (1 − g(t))·K_up(z).
- The abyssal floor (f·kz, tidally driven deep mixing) is left alone.
- g is computed from the GMST forcing column, which already reaches both derivatives (`forc$gmst`, C++ `f[4]`). It is
  held across the RK4 substeps like every other forcing term.

**Two hard constraints (not choices):**
1. **g(0) = 1 exactly, and g ≤ 1 always.**
   - The spinup sees GMST = 0 (`ccx_hold_climate(F, value = 0)`). g(0) = 1 leaves the spinup, the solved pump and
     every registered mode's spinup bit-identical.
   - IGCC GMST dips to −0.24 K (1904). An uncapped factor would RAISE K above the held value the substep controller
     bounds (`ccx_substeps_for()`, 10-04 a). Near the P8 wall that is the 10-03 (j) artifact again, silently.
   - So the key enters as max(T, 0).
2. **The solved export must be rescaled with the same factor.**
   - The canonical's pump (mode "N") is solved ONCE per run as the divergence of K × the observed DIC profile
     (`ccx_pump_export()`, `R/model.R:3866-3884`). It is held fixed (sc = 1).
   - If K fell under a fixed export, the natural DIC gradient would sharpen. The mixed layer would lose natural carbon
     at about (1−g) × 59 GtC/yr (hilda34g's export): a 5 % cut means about 3 GtC/yr of SPURIOUS uptake, the size of
     the whole modern ocean sink, with the opposite sign.
   - The export is linear in K, so S(t) = S_full − (1−g(t))·S_up, with S_up solved against K_up alone, is exact. The
     natural gradient then stays where the pump holds it, and the mechanism acts only on the perturbation
     (anthropogenic carbon, bomb ¹⁴C, the Suess effect).
   - **Physically,** mode "N" means the export is set by the nutrient supply, and mixing delivers that supply. Export
     falling in proportion to mixing is what "nutrient-limited" means. So the rescaling follows from the mode, not an
     ad-hoc patch.
   - ⚠ What it leaves out: changes in the biological pump's own efficiency, whose sign ESMs disagree on. Stated, not
     modeled.

**Closing the loop in the futures.** `ccx_run_coupled()` computes future temperature from the model's own CO₂ (plus
FaIR non-CO₂ forcing), iterated to 1e-4 °C (`R/climate.R:192-292`). A K(T) feedback is closed automatically: CO₂ → T
→ K → uptake → CO₂.

## 4. How strong: the sensitivity (literature read 10-04; the two central numbers re-checked in the papers' own text)
**The route the rules prefer: an observation × a physical law.**
- **The observation: stratification (N²) is rising.**
  - Cheng et al. 2025 (Nat. Rev. Earth Environ. 6:637, doi:10.1038/s43017-025-00715-5): **0.8 ± 0.1 %/decade**
    in the upper 2,000 m since the 1960s (a three-dataset ensemble, 90 % CI). It is 1.1 ± 0.2 %/decade at 0–200 m.
  - Li et al. 2020 (Nat. Clim. Change 10:1116, doi:10.1038/s41558-020-00918-2): **5.3 % [5.0, 5.8] over 1960–2018,
    0.90 %/decade**, about 71 % of it in the upper 200 m, more than 90 % temperature-driven.
  - Cheng 2025 is the most recent, so it is the central value; Li 2020 is the cross-check.
  - Against IGCC GMST's 1960–2024 trend (0.182 K/decade, from `data/forcing_gmst.rds`): **s ≈ 4.4 %/K** (0–2000 m),
    6.0 %/K (0–200 m); Li: 5.3 %/K.
- **The law: diapycnal diffusivity K ∝ N^−q.**
  - q = 2 at fixed dissipation (Osborn 1980, as restated in Gargett & Holloway 1984 eq. 21).
  - q = 1 where dissipation scales with N (Gargett 1984 J. Mar. Res. 42:359; basin budgets give q = 0.8–1.2).
  - q = ½ for the Garrett–Munk broadband case.
- **Combined:** d ln K / dT = −(q/2)·s, i.e. g(T) = (1 + s·T)^(−q/2).
  - Central (s 4.4 %/K, q = 1): **−2.2 %/K**. Range over q ½–2 and s 4.4–6.0: **−1.1 to −6 %/K**.
  - At SSP5-8.5's coupled +4.6 K (2100) and +7.6 K (2300), g = 0.91 and 0.87 at the central value.
- ⚠ **The scale caveat.** CCX's K (~1e4 m²/yr ≈ 3.2 cm²/s) is about 30× the measured diapycnal diffusivity of the
  upper kilometer (~0.1 cm²/s; Gargett 1984 p. 383). It is an EFFECTIVE ventilation coefficient: it also does the job
  of subduction along density surfaces, which the box model has no channel for.
  - Applying the N-law to all of the upper K assumes ventilation weakens in proportion. CMIP6's large ventilation term
    (below) supports the direction; nothing observed fixes the proportion.
  - If only the diapycnal part responded, the effect would be ~30× smaller (negligible).

**Model precedents (the rules' last resort; named and dated):**

| source | what weakens | sensitivity | key |
|---|---|---|---|
| MAGICC6 (Meinshausen 2011 ACP 11:1417, Table B3, CMIP3) | heat-uptake K | ratio of means −24 %/K; half the 19 fits at a search limit | top-minus-bottom ocean ΔT, not GMST |
| MAGICC6 upwelling (p. 1422) | heat overturning | −30 % over 8 K ≈ −3.75 %/K | GMST |
| OSCAR v2 (Gasser 2017 GMD 10:271; params from its v3 repo) | mixed-layer depth (shoals) | ≈ −7 %/K of GMST (mean CMIP5) | SST. ⚠ opposite in sign to the observed summer deepening (Sallée 2021) |
| CMIP6 AMOC (Weijer 2020 GRL; AR6 warming) | overturning | ≈ 9–13 %/K (indicative) | GMST |

**Benchmarks for the BUILT model** (checks, not calibration):
- **GCB 2025** (ESSD 18:3211, p. 3242): the ocean's climate effect is −0.20 ± 0.05 GtC/yr (2015–2024; −7.1 %).
  - ⚠ Its baseline is a "normal year" climate, not 1850.
  - It includes wind-driven variability, which CCX lacks (in one model, wind is ~2/3 of it; Bunsen 2024 GRL).
- **CMIP6 γ_O** (Arora 2020 Biogeosciences 17:4173, abstract and p. 4195): −17.2 ± 5.0 PgC/°C. It splits into
  - solubility −12.8,
  - VENTILATION (disequilibrium) −16.4,
  - REGENERATED (biological) +12.3: slower circulation also lets the biological pump hold more carbon.
- ⚠ **What this means for CCX.** With the pump rescaled (constraint 2), CCX models the ventilation term and holds the
  regenerated term at zero. Against CMIP6 it would therefore OVERSTATE the net circulation effect (CMIP6's two terms
  net to about −4 PgC/°C). That goes in the caveat, unless Marcus wants a partial pump response (§7 Q5).
- **Reduced-complexity precedent:** of MAGICC6, Hector, BernSCM, CICERO-SCM, FaIR and OSCAR, none lets circulation
  touch ocean CARBON except OSCAR (mixed-layer depth only). Bern2.5D (an intermediate-complexity model) does it
  dynamically: circulation change cuts its 1765–2100 uptake by 4.5 % (SST 9.5 %, biota −5.9 %, total 7.9 %; Plattner
  2001 Tellus B 53:564, Table 3). CCX would be unusual among simple models.

## 5. Expected magnitude (first principles, BEFORE any run)
- For a diffusion-limited column, the anthropogenic flux into the ocean scales roughly as √K (the box-diffusion
  result: penetration depth ∝ √(K t)).
- A fractional cut ε in the upper K therefore cuts uptake by about ε/2 once the warming is in place.
- CCX's own numbers at hilda34g (one coupled run each, measured 10-04, `ccx_run_coupled()`):

| | SSP5-8.5 | SSP2-4.5 |
|---|---|---|
| coupled GMST, 2100 / 2300 (K) | 4.60 / 7.59 | 2.73 / 3.02 |
| ocean uptake, 2025–2100 / 2025–2300 (GtC) | 437 / 1292 | 228 / 433 |
| CO₂, 2100 / 2300 (ppm) | 958 / 1449 | 523 / 477 |

- At a sensitivity of 2–5 %/K, the upper K is cut 9–23 % by 2100 and 15–38 % by 2300 at SSP5-8.5. That is about 5–12 %
  and 8–19 % less uptake once in place, less averaged over the ramp.
- Very roughly: 10–25 GtC more stays airborne by 2100, and 50–150 GtC by 2300 (after the land takes some back).
  **≈ 3–10 ppm at 2100 and ≈ 20–50 ppm at 2300 at SSP5-8.5**, comparable to the greening term's ~27 ppm. At SSP2-4.5,
  about a third of that.
- **At §4's central law** (g = 0.91 at 2100, 0.87 at 2300), the upper K is cut 9 % / 13 %. That means uptake falls
  ~4–6 % and CO₂ rises **≈ +2–4 ppm at 2100 and ≈ +10–25 ppm at 2300 at SSP5-8.5**. That is the low end of the range
  above.
  - An independent anchor: Bern2.5D's circulation change costs 4.5 % of its 1765–2100 uptake (§4), the same order.
- ⚠ An UPPER estimate: the √K scaling is for a purely diffusive column. Part of CCX's uptake goes through the HILDA
  high-latitude route (`u_hs`, `tau_q`), which a K-only factor does not touch.
- **MEASURED 10-04 (the built mechanism; CHANGELOG 10-04 n): the √K scaling OVERSTATES CCX by ~3.4×.**
  - CCX's own elasticity, d ln(ocean sink 2015–24) / d ln(kz), is **0.149**, the same at kz × 0.9675 and × 0.90
    (static runs, spinup re-spun, pump re-solved). A pure diffusive column would give 0.5.
  - The built mechanism at the canonical (g 2024 = 0.9675) cuts the 2015–24 sink by 0.0149 GtC/yr (−0.47 %).
    The static cut of the same size cuts it by 0.0154 (−0.49 %): the ramp costs almost nothing.
  - **⇒ the §5 futures numbers above should be divided by ~3.4 until the preview measures them directly:** roughly
    +1 ppm at 2100 and +3–7 ppm at 2300 at SSP5-8.5, at the central law. That is smaller than the greening term, not
    comparable to it.
- The historical effect is small (T ≤ 1.5 K). Every stored logpost still moves, which the preview will price.
- ⚠ This is the order of magnitude to check the preview against. A preview result 3× off it is a bug until shown
  otherwise.

## 6. Build plan (after the rulings)
1. **DESIGN.md first** (the inert-pool precedent): a §3.4a subsection with the equations, both constraints and the
   citations.
2. **Constants:** the sensitivity (and exponent or floor, by ruling) in `R/constants.R`, each with its citation (hard
   rule 2).
3. **The R reference** (`R/model.R`):
   - a model slot in `ccx_default_params()` defaulting to 0 = OFF;
   - `aux$kz_up` and the S_up solve in `ccx_prepare()`;
   - g(T) and the two substitutions in `ccx_deriv()`.
4. **The C++ twin** (`src/ccx_core.cpp`: `Aux`, `Par`, `deriv`) and `R/cpp.R` packing, in the same association order
   for bit-parity.
5. **Tests** (a new `test-mixing-feedback.R`, on the `test-l2-enso-limb.R` template), each with its mutation:
   - OFF is bit-exact: every registered mode reproduces its stored likelihood row by row;
   - R/C++ parity;
   - conservation to ~1e-10 with the mechanism on;
   - g(0) = 1: the spinup is unchanged with the mechanism on;
   - **natural state held**: zero emissions with a synthetic warming leave the natural ocean carbon unchanged.
     Mutation: drop the pump rescaling, and it must fail with a spurious sink;
   - direction: a warming run's ocean sink falls monotonically with the sensitivity;
   - g ≤ 1 at T < 0: the substep bound holds.
6. **A preview diagnostic** (no adoption):
   - the price on every registered mode (the D1 precedent);
   - the futures effect (SSP5-8.5, the vv markers, to 2300);
   - the POWER of the record on the sensitivity: a likelihood profile at the canonical. A flat profile means fixed and
     cited, not fitted;
   - the model's ocean carbon-climate feedback against the literature's (§4).
7. **The app:** a Futures-tab switch, with one sentence for undergrads and the caveat in the collapsible.
   - `warming_feedback` in `R/mechanisms.R` must also zero the sensitivity if the mechanism enters the canonical.
8. **Packaging:** if it enters the canonical, it should share ONE objective #16 and ONE refit with the greening
   decision (P0 vs P4), as the D1 precedent did.

## 7. What needs ruling (recommendations marked)
**Q1. What weakens?**
- (a) **Thermocline mixing only: the upper part of K, abyssal mixing unchanged.** RECOMMENDED. The observation × law
  route covers it, and it maps onto MAGICC's K(T).
- (b) (a) plus high-latitude deep-water formation (`u_hs`, an AMOC-like slowdown). Its strength could only come from
  CMIP6 (~9–13 %/K, indicative; the last resort).
- (c) One factor on all interior transport (`kz`, `u_hs`, `tau_q`). One number for the app, but the law does not
  govern deep-water formation.

**Q2. Where does the strength come from?**
- (a) **The observation × the law, FIXED and cited:** g = (1 + s·T)^(−q/2), s = 4.4 %/K (Cheng 2025), q = 1 (Gargett
  1984), i.e. −2.2 %/K. q = ½ and 2 bound an app range. RECOMMENDED.
- (b) The same, as a PRIOR on a fitted sensitivity. The preview measures the record's power first; I expect it flat.
- (c) Calibrate to GCB's ocean climate effect (−0.20 ± 0.05 GtC/yr) as an objective row: the ocean twin of P3. That
  effect is mostly wind-driven variability, which CCX lacks.
- (d) A model precedent (MAGICC6 / OSCAR / CMIP6: −4 to −24 %/K). The last resort.

**Q3. What temperature does it key on?**
- (a) **GMST minus a lagged deep-ocean temperature** (an exponential lag with CCX's own climate module's slow
  timescale, 195 yr; FaIR 2.2.4 calib 1.6.0, model-derived and named). Stratification is a surface-minus-deep
  contrast, so it relaxes as the deep ocean catches up: CMIP6's SSP1-2.6 stratification falls after 2050 at roughly
  flat GMST (Cheng 2025). At the 2300 horizon this roughly halves the effect against (b). RECOMMENDED.
- (b) GMST alone. Simplest, already in both cores. It overstates the effect after stabilization.

**Q4. Where does it apply?**
- (a) **History and futures,** with the price measured on every registered mode, and packaged with the greening
  decision into ONE objective #16 and ONE refit. Physically consistent. RECOMMENDED.
- (b) Futures only (a Futures-tab switch, the fit untouched). Cheaper, but the model would run one physics before 2025
  and another after.

**Q5 (can wait for the preview). The biological pump.**
- Constraint 2 holds the natural carbon fixed, which leaves out CMIP6's REGENERATED offset (§4).
- The alternative, a partial pump response, would need a sizing source that does not exist outside ESMs.
- My suggestion: keep the constraint and disclose the omission in the caveat.
