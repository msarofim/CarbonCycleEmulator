# Handoff — CarbonCycleEmulator, 2026-09-04 (the OCEAN-STRUCTURE arc; 4th–7th sessions of the day)
# **⭐⭐ THE HILDA HIGH-LATITUDE CONDUIT WORKS (3/3) AND IS NOW THE BEST-SUPPORTED NEW STRUCTURE.**
# **⛔ FIX B VIA ENSO IS DEAD ON EVERY BUILT LEVER; ROUTE 1 IS CLOSED; DEPTH-DEPENDENT K BACKFIRES.**
# **⛔ THE TWO-SIGNATURE INVERSION IS RETIRED; GATE S REBASED; GATE H ADDED.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`,
commits **`e686c82..81f8bcc` (14)**. No remote; nothing to push.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-04_gate_audit.md`, then
`handoff_2026-09-04g_gateS_corroborated_fixB_priced.md`.

**Suite: 1757 → 1798 pass / 0 fail / 0 error / 4 skip.** Green throughout.
**No refit, no adoption, no model change.** `ent26` remains canonical and untouched.

---

## 0. WHAT THIS ARC ESTABLISHED, IN ORDER

1. Gate S's target **corroborated** by an independent pCO₂ route, then **rebased onto it** when the
   inversion that produced it turned out not to run. §2
2. **GATE H added** — the interhemispheric gradient contrast, which nothing scored. §3
3. **Fix B killed on every built ocean lever** (sign), and **route 1 closed** (the chemistry is
   right). §4
4. The ventilation error **located at intermediate depth**. §5
5. **Depth-dependent K measured and shown counterproductive**; **HILDA read from the paper**; **its
   conduit tested and it WORKS**. §6 — **this is the live thread.**

---

## 1. ⛔ THREE RETRACTIONS I MADE THIS ARC — read these before quoting anything older

1. **"The SPO land limb is 1.683× observed and 1.90 months late, 56 % cancels."** ⛔ **WRONG.** I
   compared `SL_CASES$SH_land` (an **ORIGIN** split, SH-land only) against `SPO_SEAS_AMP_LAND_INV`
   (a **TYPE** split, all land by δ¹³C signature). Like-for-like at `ent26`: **land 1.05×, ocean
   0.77×, both INSIDE their bootstrap intervals, and the limbs ADD (−3 %)**. The 56 % belongs to the
   ORIGIN split and is interhemispheric TRANSPORT ⇒ [[ccx_land_limb_is_ungated]].
2. **"The δ¹³C level, gate H and the ENSO sign all say the model has no ocean upwelling."**
   ⛔ **Two-thirds refuted by measurement**: only the δ¹³C level responds as predicted; the ENSO sign
   moves **backwards** and gate H gets **worse** ⇒ [[ccx_fixB_levers_dead_on_sign]].
3. **"`MEMORY.md` is 17 KB against a 12 KB target."** ⛔ It measured the **FILE**; 28 % is HTML
   comment and the **CONTENT is 11,939 B — compliant.** Two handoffs in a row made this error.

---

## 2. GATE S: CORROBORATED, THEN REBASED (option (a), Marcus's choice)

⛔ **`diag_seas_signature_inversion.R` DOES NOT RUN at the canonical mode** — its own antiphase gate
drops all four ocean channels, `s_O` = NaN. **Cause isolated**: the 2026-09-02 T-dependent air-sea
¹³C alphas make the ocean signature **rotate seasonally**, so it is not the signed SCALAR the method
assumes. `alpha_as_tdep = 0` restores it and reproduces the registered CI exactly. **Physics, not a
bug.** ⚠ Gate S was **built on 09-03, after the premise broke on 09-02**, and nothing noticed for two
days because this is a diagnostic, not a test.
✅ **Marcus chose (a): retire it.** Six `SPO_SEAS_*_INV` constants are `status = "retired"` (a new
state, roster asserted); the script **errors by name** unless `CCX_ALLOW_RETIRED_INVERSION=1`.
✅ **GATE S now reads `SO_DPCO2_PEAK_MO` = 7.4107** (SOM-FFN, no model in the loop) **+ a
quarter-cycle lag bound** — arc **[7.411, 10.411]**, `ent26` at 8.871 **PASSES**.
⚠ **The bound's KIND changed with its source**: an INTERVAL, not a sigma. Wider (3.00 vs 1.41 mo,
p(random) = 0.25) and **the test asserts it still EXCLUDES the pre-fix limb (3.35, 4.16)**.
🐛 Also fixed: `ent_seas_amp_SH` was **clobbered to 0 on every run** of that script since 09-03.

## 3. ⭐ GATE H — the gradient contrast (the assessment's #1 fix, and it was cheap)

⭐⭐ **All three additive nuisance parameters sit on the discrepancy they absorb, to 4 dp**:
`rep_dC` **+3.3930** vs a CO₂ bias +3.31/+3.55 ppm (z **+3.39**, visible); `grad_off_co2` **+0.2098**
vs −0.2120 (z +0.42, **invisible**); `grad_off_d13c` **+0.06464** vs −0.06470 (z +0.43,
**invisible**). ⇒ **the δ¹³C gradient is 1.97× observed and `d13c_gradient` still scores +106.**
⚠ **NOT a silent gate** — the compensator simply is not strained, so no prior screen can find it.
**GATE H** scores the **CONTRAST** `R_d13c − R_co2` because a transport error is tracer-independent
and cancels, making **CO₂ an internal control**. defaults **+6.56σ**, `ent26` **+6.55σ**, both FAIL;
the CO₂ control **passes** (−1.06 se). Mutation-tested: adding `grad_off_*` back breaks 5 assertions.

## 4. ⛔ FIX B IS DEAD ON EVERY BUILT LEVER, AND ROUTE 1 IS CLOSED

- **`w_up` / `w_out`: `d(sink)/d(w) = +0.11010` for BOTH.** The observed story needs El Niño to
  SUPPRESS upwelling and INCREASE uptake ⇒ a NEGATIVE derivative. **Third instance** of the
  conveyor's death. ⚠ I predicted the magnitude would fail too — **it did not (44 %)**. Sign only.
- **Route 1 CLOSED**: the model's emergent `d ln pCO₂/dT` is **0.04198** vs Takahashi **0.04230** =
  **0.99×**, a genuine out-of-sample check because the model **does not use**
  `SST_PCO2_SENSITIVITY`. And **rescaling a wrong-signed path cannot make it right-signed.**
- ⭐⭐ **THE OCEAN SINK IS BLIND TO CIRCULATION GEOMETRY.** `w_up` and `w_out` differ hugely in deep
  Δ¹⁴C (−81.2 vs −100.5) and their sink is **identical to 1e-12** — the spinup pins ML DIC (spread
  **exactly 0.000** µmol/kg) so uptake sees only the volumetric rate. ⇒ **Score ocean structures on
  INTERIOR tracers. DESIGN §3.4a's "ocean sink" row cannot discriminate at all.**

## 5. ⭐ THE VENTILATION ERROR IS AT INTERMEDIATE DEPTH

vs GLODAP at the 2002 bottle epoch: **upper ≤500 m z +0.61** (matches), **mid 500–2500 m z +3.30,
max +4.49 at 1160 m**, **bottom >2500 m z +1.85 — the ONLY layer the likelihood scores.**
**The interior is OVER-ventilated below ~600 m and the scored row sits BELOW the problem.**
⚠⚠ **TRAP**: comparing the PREINDUSTRIAL state to modern bottles reads a **98 ‰** surface error that
is **entirely the bomb spike**. `likelihood.R`'s "preindustrial is the right comparison" argument
covers the **DEEP BOX ONLY**. Run the transient; print the bomb addition per layer.
⚠⚠ **UNRESOLVED TENSION**: an over-ventilated interior should take up **MORE** anthropogenic carbon,
yet IRF(100) is too **LOW**. Transport and capacity point opposite ways ⇒ the capacity shortfall is
likely **buffer chemistry**, not ventilation.

## 6. ⭐⭐ THE LIVE THREAD — HILDA'S CONDUIT WORKS

**Depth-dependent K first**, because §3.4a licenses new structure only when cheaper candidates fail:
at iso-deep it is **counterproductive** — scored mean |z| **2.55 → 3.87** (floorless) and **3.08** at
Siegenthaler & Joos's OWN fitted shape. ⚠ **I almost tested the wrong form**: the repo's inherited
`oc_shape()` is **floorless** with z_K 1200–5000 m; theirs is **`K = 465 + 7096·exp(−(z−75)/253)`** —
a floor plus a **5–20× shorter** scale. **Both scanned, same verdict.** ⇒ **§3.4a's gate FIRES.**
⛔ **The August shim is INERT on the spinup** (it overrides `ccx_deriv`; `ccx_spinup` calls
**`ccx_deriv_fast`**, which `iso_operator()` differentiates). **Shim `ccx_deriv_fast`.**

⭐⭐ **HILDA (paper read from `~/Documents/2010/Essenhigh/siegenthaler92tel.pdf`, not recalled):**
LS surface (**84 %**) over an advective-diffusive Interior **+ a separate HS surface box (16 %,
SST < 5 °C) over its own HD deep box**; four transport parameters `K`, `w`, `u` (HS↔HD), `q`
(HD↔Interior). **K(z) does the UPPER ocean; the CONDUIT does the DEEP. Their fitted deep K₀ = 465.**
**We have no conduit, so K does both — every arm needs a deep K of 2519–6356, 5–14× theirs.**

✅ **AND THE CONDUIT TEST PASSED 3/3.** A two-way **ML↔BOTTOM exchange with NO distributed return**
(what `w_out` got wrong):

| u (m/yr) | kz | kz/kz(0) | 1622 m | 2268 m | scored mean \|z\| |
|---|---|---|---|---|---|
| 0 | 6356 | 1.000 | +3.25 | +2.57 | **2.55** |
| **1** | **3177** | **0.500** | **+2.03** | **+1.54** | **1.81** |

**P1 is the mechanism itself and it held**: the conduit **halves** the diffusivity the deep needs.
Unscored peak 1160 m **+3.12 → +1.98**. ⛔ **Ceiling: at u ≥ 2 NO `kz` holds the deep age.**
⚠ Does **not** reach |z| < 1; **`u` here is NOT HILDA's 38 m/yr** (theirs is between high-latitude
boxes over 16 % of area — never quote them together); the **GEOMETRY** is tested, the physics is not.

---

## 7. ⚠ NON-OBVIOUS STATE

* **Torch: nothing running.** Everything here is local, seconds to ~2 min.
* ⚠ **`diag_seas_signature_inversion.R` ERRORS by design.** `CCX_ALLOW_RETIRED_INVERSION=1` plus a
  `CCX_PAR_RDS` setting `alpha_as_tdep = 0` reproduces pre-09-02 provenance, and **nothing else**.
* ⚠ **Two shims now exist and they are NOT interchangeable.** `diag_ocean_candidates.R` wraps
  `ccx_deriv` (inert on the spinup); `diag_candidateA_intermediate.R` and `diag_hilda_conduit.R`
  wrap **`ccx_deriv_fast`** (reaches the spinup). Both carry mutation gates. **Use the second.**
* ⚠ **`SO_DPCO2_PEAK_MO` = 7.4107 is typed, tied by `test-gate-bounds.R` to the registry** — but the
  NetCDF recomputation tie was **NOT built**. If the SOM-FFN file changes, nothing catches it.
* ⚠ **Gate S left the shared-NSD family**; `DG_S_NSD` and `DG_S_SD` no longer exist and a test
  asserts they never come back.
* **Memory:** `INDEX_ccx_var.md` is NEW (the 09-04g restructure); `INDEX_ccx.md` fell 18,689 →
  ~16.5 KB; `INDEX_ccx_ocean.md` is now ~15.6 KB (over soft 14 KB, under hard 18 KB — **merge when
  convenient**). Root content **11,939 B, compliant**.
* **Public readiness**: `notes/assessment_2026-09-04_public_readiness.md` (§2b RETRACTED in place)
  and `notes/assessment_2026-09-04h_what_is_actually_wrong.md`. **README is now accurate**;
  **DESIGN.md §6 is NOT** — it still presents retired gate 4 at the quarantined `from90`, with no
  gate V/S/Q/G/H, under "all must pass". **There is still no LICENSE file.**

## 8. ⇒ THE OPEN DECISIONS, RE-RANKED

1. ⭐⭐ **BUILD THE HILDA CONDUIT PROPERLY AND RE-MEASURE.** The reduced form closes ~29 % of the
   intermediate gap with the mechanism confirmed. What it does NOT have — a **cold** HS surface at
   16 % of area with its own poorly-equilibrated Δ¹⁴C (**−120 ‰** vs LS's −40) — is plausibly what
   closes the remaining 0.81. ⚠ **This is real structure: new boxes, a state-vector change, R+C++
   twins, a parity test.** Pre-register the profile prediction BEFORE building.
2. ⭐ **Decide between the two candidate boxes on measurement, not argument.** High-latitude conduit
   (intermediate water, now supported) vs equatorial box (ENSO, scoped 09-04j, untested on the
   profile). ⚠ The equatorial box's ENSO case survives **only** if a tropical box's sign differs from
   every within-column lever — untested, and it is the assumption everything rests on.
3. ⭐ **`DESIGN.md` §6** — the acceptance criteria describe a retired gate set at a quarantined mode.
4. **LICENCE** — Marcus's call, blocks any public release.
5. **`sst_seas_amp_NH` at −3.91σ**, still the worst prior violation, still undiagnosed; the SH's twin
   was relieved by giving it a MECHANISM.
6. **A posterior** (both blockers gone at `ent26`); a **Joos hypothesis**; the provisional-constant
   triage (20 of 48); CITATION + DOI.
7. **Owed from before**: the 34 tied SPO copies on touch; the bare-overlay lint's remaining
   occurrences; the SOM-FFN recomputation tie (§7).

## 9. ⇒ STANDING RULES THIS ARC ADDED

* ⭐⭐ **A COMPENSATOR THAT IS NOT STRAINED HIDES A DEFECT FROM EVERY PRIOR SCREEN.** Print each
  additive nuisance parameter **beside the residual it absorbs**; nothing else finds it.
* ⭐⭐ **THE OCEAN SINK CANNOT DISCRIMINATE OCEAN STRUCTURES** — score them on INTERIOR tracers.
* ⭐ **A METHOD CAN BE INVALIDATED BY A MODEL IMPROVEMENT.** The inversion's premise was falsified by
  a better fractionation. **Put a constant's provenance script in the suite, at least as a
  does-it-still-run smoke test.**
* ⭐ **CHECK THE FUNCTIONAL FORM AGAINST THE SOURCE BEFORE SCORING A "PUBLISHED" CANDIDATE.** The
  repo's inherited K(z) was floorless with a 5–20× longer scale than the paper's.
* ⭐ **A SHIM IS ONLY AS GOOD AS THE FUNCTION IT WRAPS.** Mutation-test that it reaches the code path
  you care about — the August one did not reach the spinup and nothing said so.
