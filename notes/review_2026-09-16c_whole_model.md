# Whole-model review — 2026-09-16 (c), at the canonical `hilda30c` (HEAD `feb3a5a` + the finding-2 fix)

**Marcus's three questions:** Is everything in the structure justified? Are there bugs? What are the remaining observational
mismatches and the best avenues? Three read-only review passes were run in parallel (structure justification; adversarial code
review with reproducing probes; the mismatch ledger from the scorecard, the mode file's streams and the memory indexes) and are
synthesised here. Every number is from the tree or a named memory file; nothing is recalled. The three raw reports are in the
session transcript; this note keeps what a decision needs.

---

## 1. Is the structure justified?

**Of the 30 free names, 22 rest on an observation, a law or a ruling.** The rest:

| name (fitted value) | what it is | what it stands in for |
|---|---|---|
| `rep_dC` +3.35 ppm (z +3.35) | licensed as a station-vs-box constant (receipt 0.4–0.6 ppm), fitted at 6–8× that | a CO₂ LEVEL bias the model cannot place (a ~9 ppm swing: −4.1 in 1900–40, +4.5 to +5.3 post-1958); unchanged by six pre-registered refits — "a data question" |
| `grad_off_d13c` 0.0646 | the δ¹³C interhemispheric offset | the table comment says it: it absorbs the STRUCTURAL δ¹³C misfit — gate GL FAILS at 1.97× (z −10.3) while `d13c_gradient` scores +106 |
| `gamma_enso_ocn_NH/SH` 0.34 / 0.05 | an air–sea flux ∝ Niño3.4 with no reservoir behind it | equatorial upwelling of a +55.5 µatm reservoir two hemispheric boxes cannot represent; it does ALL the canonical's ENSO-ocean work (off: +0.58× → −1.47×); its hemispheric split is physically inverted (the cold tongue is SH-heavy 1.56×) |
| `sst_seas_amp_NH/SH` 1.54 / 1.29 K | an OBSERVED quantity (ERSSTv5 2.24 / 1.75 K) fitted 30 % below its observation | the SH one is where the pinned shim's work moved (2.4 posterior σ, "not soft"): the thermal : DIC ratio of the SH mixed layer, ungated (assessment option K) |
| `ent_seas_amp_SH` PINNED 0 | the pCO₂-side DIC shim | wintertime entrainment — the mechanism (`seas_ml`) now exists; the pin costs −2.53, all on `d13c_seasonal_SPO`; held not retired so the `seas_ml` 0 control stays scorable |
| `sigma_d14c` 5.47 ‰ | a legitimate nuisance (de-biased scatter 14/12 ‰ vs the products' 4.2) | under pressure it is the valve that makes kz's hold SOFT (−295 → −86 when freed); any kz claim should be re-read with it pinned |
| `q10` 1.18 (z −2.11) | candidate shim, not proven | the δ¹³C Suess over-decline pushes it down. Test: refit with the δ¹³C level rows dropped; if q10 returns toward 2, it is compensating |

**Priors without a receipt** (justified parameters, soft spots): `q10` lognormal(2, 0.25) recollected; `k_w` "Wanninkhof [VERIFY]" and
`tau_ex` "SF₆-derived [VERIFY]" never discharged; `seas_lag_p_*` N(2.25, 0.75) is an OFFLINE OPTIMUM, not an observation; `h_hs`
dunif[20, 500] where the 09-11 ruling said "under the HS Holte prior" (103–128 m) — fitted 393 m; `kz` on a bisected 24× box is a
support, not an identification. Fifteen of 62 constants are `status = "provisional"` (`OCEAN_AREA_*`, `OCEAN_DEPTH`, `ALK_SURFACE`,
`ALPHA_PHOTO_EPS` 18 C3-only, `PUMP_EPS13_ORG` −20 "recollected", `NPP_GLOBAL_PI` 60, `RHO_SEAWATER`, …). `gamma_diff` 0.25 and
`npp_veg_frac` 0.5 are base defaults with no source.

**Contradictions with DESIGN or a ruling** (each a concrete, checkable item):
1. **`hs_frac` has two provenances.** `CCX_STRUCT_HILDA$hs_frac = 0.16` (`R/calibrate.R:1844`; the caveat register: "MEASURED on SST < 5 °C")
   while every HS data product — Holte HS MLD, the HS SST amplitude, gate S's mask, `obs_tr_box.rds` — uses the 57.14° boundary whose area
   is 0.128 (09-14 e). Consequence: `u_hs`'s prior centre (34–47 Sv over the model's HS area) is 21.8 m/yr at 0.16 and ≈27.3 at 0.128
   (×1.25); `pump_hs_gcm2`'s per-area meaning moves the same way. `hilda_c` carries 0.128, unadopted.
2. **`h_hs`'s ruled prior is not built** (residence time h/u = 393/23.6 = 16.7 yr vs ~5 yr at the observed MLD).
3. **`sst_NH/SH` 18/16 °C are TYPED** vs the measured, re-based 17.18/15.35 (whole-LS 22.3/18.7; 09-14 d/e); the T-dependent Zhang alphas
   make gate Q's 2.94σ share a lineage with this. `hilda_c` holds the fix; every registered mode runs the typed pair.
4. `ALPHA_PHOTO_EPS` 18 in use; the 09-14 h ruling set 15.6 for `hilda_c`.
5. `pump_mode` N vs D "DEFERRED TO THE REFIT (Marcus 08-16)" — never ruled; every refit since ran N.
6. **`ccx_default_params()` is the inverse of the canonical on two mechanisms**: `seas_ml = 0` ("default OFF while the mechanism is being
   built", stale since 09-11) and `ent_seas_amp_SH` at its table init with a 30-line argument that it "CANNOT STAY 0" — while the
   canonical pins it at 0. Mode-based consumers are protected by `ccx_apply_structure()`; any bare-defaults column in a gate runs the shim ON
   and the mixed layer OFF.
7. DESIGN §2's locked ENSO decision (MEIv2, a lagged land term, `L_MEI`, `τ_strat`) no longer describes the code (Niño3.4, demeaned, one-way
   GPP, no lag); §3.1 still says the canonical is `hilda31s`; §3.4's "K_z prior 2000–8000" is 1.4–4× under the fitted value and does not
   point at §6's class statement. The canonical mode file lacks `pump_field` (defaulted to "solved" by the reader) — a provenance gap.

**Structural-at-0 machinery.** Kept by the 09-16 c ruling as the instrument of the class statement: `pump_field = "martin"`, `pump_export`,
`w_vent`/`gamma_vent`, `w_thc`/`k_thc`, `pump_seas_*`, `pump_hs_seas_*`. Kept as parked instruments: `hilda_eq` (the only right-signed
ENSO-ocean path measured) and `hilda_tr`. **Dead weight a v2 can delete** (each measured, failed, superseded): the `q_conv` /
`conv_sink` / `conv_descent` / `conv_reverse` family (DESIGN §3.4a D: "falsified twice"; `conv_reverse` exists for one wiring test),
`w_up` / `w_out_*` (three instances of "the conveyor's death"; already REFUSED with the cell on), `tau_ex_seas_*` (its motivating gate now
passes in trough form), `alk_hs` ("not a lever"), `ra_ratio` (default-off, no arm, no ruling), and the reproduction-only fields (`beta` log
form, `seas_amp_*`/`seas_phase_*`, `sst_scale`, `ALPHA_AS_*_LEGACY`) behind one `legacy` switch.

---

## 2. Are there bugs?

**No result-breaking bug in the integrated model.** The twin cores agree flux by flux (probed on the branches the suite does not pin:
max |Δ| 5e-12); forcing order, carbonate coefficients, isotope carriage, bomb/nuclear delivery, seasonal conventions, the periodic-spinup
handover and the likelihood plumbing all checked CLEAN. Seven findings, ranked; one fixed in this commit.

| # | finding | severity | status |
|---|---|---|---|
| 1 | **The deep and mid Δ¹⁴C rows read the LS column ONLY (`R/spinup.R:197,242`; `R/likelihood.R:793`) while the GLODAP target is the volume-weighted mean of EVERY cell below the depth, high latitudes included.** Under HILDA the HD box IS the ventilated deep under 16 % of the area (Δ¹⁴C −137.5 vs the LS bottom −190.3 ‰). Measured at the canonical: scoring LS+HD moves the three rows toward the target by 8.4 / 6.6 / 8.2 ‰ = 0.82 / 0.49 / 0.60 σ, ALL the same sign — the scored quantity reads systematically OLDER than the model's own deep water, so these rows push kz / `kz_deep_frac` / `u_hs` / `tau_q` toward a younger LS column than the whole model needs. The spinup comment records the choice ("so the kz bracket stays comparable"); nothing prices it. | BIASES A ROW — and it steers exactly the kz object of §6's class statement | OPEN — a ruling: (a) score LS+HD volume-weighted, or (b) re-cut the target with the model's own mask (`build_glodap_deep_targets.R` can). Then profile kz under both reads. |
| 2 | R-side silent default: `f_luc_perm` ABSENT ⇒ `min(numeric(0), 0.9) = 0.9` — 90 % of the land cleared — while the C++ resolves absence to 1 (cleared ≈ 14 %). Reproduced: dC/dt[NH leaf] −4.1 vs +8.9 GtC/yr. Default lists carry the field, so no registered result was touched; hand-built lists on the R path (the flux trace, PK diagnostics) were exposed. | LATENT R/C++ divergence | **FIXED this commit** (`R/model.R`, resolver shared with the C++; `test-param-absent-ok.R` +1 test, 106/106; every registered mode still reproduces) |
| 3 | **Spinup and transient at DIFFERENT substep counts manufacture a 3–13 log-unit shift** (−3.0 at h_ml 65.2, −13.5 at 71.0) because the 4-step map's fixed point is not on the 64-step orbit — and `ccx_run_prepared`'s NA-retry (`R/cpp.R:492-494`) does exactly this: it doubles the transient's count and re-runs against the ORIGINAL spinup, recording `substeps` that nothing upstream reads. Like-for-like (both refined) the integrator error is ≤ 0.15 log-units and ≤ 0.004 ppm — the integrator is fine; the mismatch is the trap. It also invalidates any transient-only convergence check. | LATENT — a silent 3–13 log-unit error on any evaluation where the retry fires | OPEN — make the retry re-spin at the escalated count or return −Inf; stamp `substeps` on every stored logpost; convergence checks must override `CCX_SUBSTEPS_MIN`, never pass `substeps=` to the transient alone |
| 4 | The ocean-gradient rows are scored against the 0–100 m target with σ inflated by the like-for-like offset (option 5, 08-28 g) — at h_ml 65.2 the like-for-like DIC gradient is 246.9 vs the scored 233.1: a directional pull toward a too-small gradient (~0.5 σ_obs) that STRENGTHENS as h_ml shrinks, anti-correlated with the h_ml prior. Part of THC's "z +2.6 → +0.3" is this offset. | BIASES A ROW, mildly; Marcus's ruling | flag — a two-line alternate scorer would say whether the THC verdict flips |
| 5 | Pre-1850 SST anomaly is HELD AT THE SINGLE YEAR 1850 (−0.042 K, `R/forcing.R:1057` rule = 2) while GMST and the periodic spinup use 0: every surface box starts the transient 0.04 K colder than its spun-up orbit — a ~0.5 µatm, ~0.05 ppm step at 1850. Below every σ, but a single-year baseline held for a century is the trap `~/.claude/CLAUDE.md` names. | LATENT | OPEN — pre-1850 = the 1850–1900 mean; changes every stream at the 4th decimal ⇒ a restamp, so a ruling |
| 6 | `ccx_build_forcing()` defaults `prod_c14 = NA` and ships it as `c14_cosmo`: a bare `ccx_run(spin, ccx_build_forcing())` yields valid CO₂/δ¹³C and an all-NA Δ¹⁴C. Every calibration path overwrites it. | LATENT | OPEN — error on NA, or default to the spinup's value |
| 7 | Smaller: the conveyor limbs divide by `a_oc` while the boxes they cross are `a_ls`/`a_ml` (a Sv-label error on a parked mechanism); `ccx_spinup`'s interior guess scales by `eq_on` not `d1_on` (Newton absorbs it); the HS seasonal guard reads sample extremes where the LS guard reads the interpolant's; the substep bound omits the entrainment, air–sea and HS rates (safe at the floor, unbounded by construction); gradient rows silently `next` when `err$grad_off_*` is absent; `alk_hs` is in mol/kg while `alk_eq`/`alk_tr` are µmol/kg; four `tryCatch → NULL` data reads (a corrupt `obs_glodap_deep.rds` would turn the pump OFF with `pump_grad > 0` and say nothing) — none in `CCX_RUN_INPUTS`; forcing is held over `[t_i, t_i + 1/12]` with `t_i` the month CENTRE (a uniform half-month lag; calendar-year sums unaffected; ENSO's γ absorbs it). | LATENT | record; fix opportunistically |

---

## 3. The remaining observational mismatches, grouped by the mechanism the evidence says they share

Per-row streams at the canonical (log-lik; n differs, so a value is not a z): `co2_icecore` −662 (n 255, RMS z ≈ 1.4–1.7), `d14c_intcal`
−640 (n 191, RMS z ≈ 1.4), `d14c_NH/SH` −286 each, `gcb_land_sink` −100, `co2_level_MLO/SPO` −69/−61; every seasonal and δ¹³C row
POSITIVE (`d13c_seasonal_SPO` +250, `d13c_gradient` +106). Prior strains: `rep_dC` +3.35, `kz_deep_frac` −2.47, `pump_hs_gcm2` +2.22,
`q10` −2.11, `bomb_total` +1.49.

**M1. The diffusive column with no advective return (DESIGN §6's class statement).** Diffusion carries 70 % of the bomb ¹⁴C ⇒ kz 10,964
⇒ the solved export must be 45 GtC/yr (obs 5–13) ⇒ cold-equilibrated DIC exposed on every warm box. Owns: the export magnitude; kz at 10–40×
a diapycnal value; `pump_hs_gcm2` z +2.2 and `kz_deep_frac` z −2.5; the DIC gradient z +2.4–2.8 (302.8 vs 233 ± 25), the δ¹³C gradient
z ≈ −3.5σ_eff (too small), the ALK gradient 0.6×; ¾ of the **1995 ocean bomb inventory at z +3.8–4.2 in every configuration** (81.4 vs
51.4 ± 7.6 kmol; `bomb_total` 118 vs N&L's 99–105); the tropical excess (B1 +144 / +68 vs +55.5 obs) that blocks the ENSO fix; HS surface
δ¹³C 3.09 ‰ at PI (obs +1.29) → gate Q; and, at one remove, gates H (+11.6) and GL (1.97×) and the Suess over-decline that pushes q10 down.
Every in-class approximation is measured and refuted (T-A0 −135, E −37.5, O1 refuted, THC −319 net, D-alone −895, O5 a third, O5b nil).
**Parked 09-16 c.**

**M2. The ENSO → ocean path — THE RELEASE BLOCKER.** Solubility-only slope r −0.527 (wrong sign) vs GCB +0.115 ± 0.025 GtC/yr per Niño3.4
unit; net 0.58× obs only through the `gamma_enso_ocn` shim. Downstream: gate V (sd 0.719 vs 0.933 ± 0.084, z −2.55; ENSO is 66 % of the
knockout; non-blocking by ruling); the land ENSO response ~0.5× (land and ocean errors cancel 87 % in growth). Measured: T-A2's layer-2
return limb carries the WHOLE observed slope at 26 Sv/index with price +3.09 (unrefitted); the cell reaches the slope at 16 Sv/index but
fails the reservoir by z +13 (M1's wall); `hilda30e` not promoted.

**M3. The seasonal mixed layer's DIC side (the shim family).** `sst_seas_amp_SH` 1.29 vs 1.746 (2.4σ), `_NH` 1.54 vs 2.24; the thermal :
DIC ratio inside the SH limb (SST sine 0.65 @ 4.1 vs entrained 1.0 @ 9.7 → net 0.357 @ 8.92) has NO gate — gate S sees only the net;
the HS box's seasonal pCO₂ cycle ~0.5 µatm vs SOM-FFN's 16.3 @ 7.5 (30×, unscored); `h_hs` 393 vs 103–128 m.

**M4. The CO₂ level / mid-century seam (a data question).** `rep_dC` +3.35; the 1940s plateau (`co2_icecore` the worst row; `CCX_ICE_DISCREPANCY`
OFF); six refits and four obs-artefact tests say it is a common-mode +10.7 GtC, not the plateau.

**M5. Land takes up too fast in the first century.** IRF(100) 0.280 vs Joos 0.409 (a comparison, by ruling not chased); land sink +1.0 GtC/yr
over GCB at the bare σ (z +2.0; +0.65 at the objective's ×3); β_max, not kz, is the lever (−232 to close gate 7).

**M6. The bomb budget.** The atmosphere's 1995 share 18.4 % vs N&L 22.0 % forces input ×1.16; the post-1970 SH deficit (z +4.3 at 1971);
the bomb window scored at σ_eff 25.7 ‰ (7× Hua's 3.6); the `table2` vs `table4` target ruling (~130 log-units); Naegler's +8 % uptake
correction unapplied (−0.5σ). ¾ of it is M1.

**M7. Objective / σ hygiene (rulings, not builds).** `gcb_ocean_sink` σ 0.4 UNINFLATED while land gets ×3 (the ocean sink is a MODEL product);
`CCX_ICE_DISCREPANCY` off; deep n_eff 20 (known ×3.4); `hs_frac`, `sst_NH/SH`, `ALPHA_PHOTO_EPS` (the `hilda_c` batch, ~−290 unrefitted);
finding 1 above belongs here too.

Accepted / passing and not to be re-hunted: gates 1–3, 5 (trough form, inside 2σ), 7 (at the objective's σ), G (+1.21, partly circular), S
(weak pass), P7; the intermediate Δ¹⁴C rows (≤ 1.4σ); `h_ml` 65 vs Holte 60/118; `u_hs` 43 Sv vs NADW+AABW 34–47; gate 4 retired.

---

## 4. Avenues, ranked (with what each costs and what decides it)

| rank | avenue | closes | class | cost | decided by |
|---|---|---|---|---|---|
| **1** | **The Niño3.4 layer-2 return limb on the low-latitude ML as a REFIT** (T-A2's geometry; W0 pinned to Meinen 2001's 51–64 m/yr; γ prior the observed 14–25 Sv/index) | M2's sign and magnitude; retires `gamma_enso_ocn`; V's 66 % share | refit of the present class (one switch, 1–2 names) | days + one Torch array | GCB's +0.115 ± 0.025 reproduced with the solubility-only r flipped positive at γ inside Meinen's bracket. Landing ABOVE the bracket says the reservoir is needed → rank 3. Already priced: +3.09 unrefitted, no CO₂-level leak at k = 2. |
| **2** | **The objective-hygiene batch as ONE refit** — finding 1 (deep rows LS+HD or a masked target), the ocean-sink σ, `excess_c14` target set, `CCX_ICE_DISCREPANCY`, `hs_frac` 0.128, `sst_NH/SH` re-based, `ALPHA_PHOTO_EPS` 15.6, `h_hs` under its Holte prior, the SST pre-1850 baseline (finding 5), the substep retry (finding 3) | M7, part of M6 and M3; removes three known biases on the kz-steering rows before anyone reads kz again | rulings + one array (the queued `hilda_c` arm, ~−290 unrefitted, is most of it) | a session + 5 h Torch | no single observation — it is provenance; but every later comparison becomes like-for-like. **Do this before rank 1's array so the limb is refit against a clean objective.** |
| **3** | **An advective-return ocean** (upwelling–diffusion column / HILDA conveyor / 2-D) | M1 wholesale: export, kz, the gradients, ¾ of the bomb inventory, the tropical reservoir, HS δ¹³C → Q, and H/GL at one remove | **NEW MODEL CLASS** — out of v1 under §3.4a unless an observation forces it; §6 says "the next model, not a refit" | largest: every mode moves, re-bisect kz, ports, arrays | the WOCE 1995 inventory at z ≤ 1 with Nowicki's export and GLODAP's gradients held; then read H/GL/B1 |
| 4 | **Option K** — gate the thermal : non-thermal ratio of the SH limb (Takahashi 2002 / SOM-FFN split, 40–90 °S), then pin/price `sst_seas_amp_SH` | M3's 2.4σ, the weak gate S | a data task + a gate, maybe a refit | days | the ratio 0.65 : 1.0 at SPO vs the product's split |
| 5 | **Option B** — `ml_hi` = the HS box with its poleward MLD cycle under the HS Holte prior (R side written; C++ twin, prior, tests owed) | `h_hs`, the HS pCO₂ cycle (30×), HS δ¹³C → Q | refit (new structure label) | weeks | HS MLD 103–128 m; SOM-FFN 16.3 µatm @ 7.5; Quay 0.60 ± 0.10 |
| 6 | **G′** — the iso-fit frontier on gate GL | says what H/GL cost the rest of the objective | diagnostic | hours | — |
| 7 | Land first-century axis (saturating fertilisation / β_max) | M5 | refit | one array | GCB land at the bare σ; Joos stays a comparison |
| 8 | T5 tropical column | B1 → M2 | between refit and new class | 2–3 sessions + array | B1 +55.5; the preview says it inherits M1's exchange without an advective return |

**Where this differs from the standing recommendations.** The 09-12 assessment ranked option A (the limb) first; the 09-13 g ruling took the
cell instead and the cell hit M1's wall; the 09-14 g review put D+E first, and D+E have now been measured and parked. With the in-class
pump options closed, the layer-2 limb is the only measured fix of the blocker that is right-signed, reaches the observed slope, and costs
+3 rather than −37 — so it returns to the top. I put the hygiene batch ahead of its ARRAY (not ahead of its prereg) because finding 1 and
the typed constants sit on precisely the rows the limb's refit will lean on. Nothing on the list moves M4; the only in-repo action there is
the `CCX_ICE_DISCREPANCY` ruling and a WAIS Divide / Siple look-up.

---

## 5. What was done in this review's commit
- Finding 2 fixed (`R/model.R`: `f_luc_perm` absence → `CCX_F_LUC_PERM_DEFAULT`, the C++'s resolver) + a parity test at non-zero cum_luc
  (`test-param-absent-ok.R`, 106/106); every registered mode still reproduces (`test-hml-floor.R` 16/16).
- Nothing else changed: findings 1, 3, 5 and the contradictions are RULINGS (each moves a stored number or an objective) and are listed for
  Marcus, not resolved here.
