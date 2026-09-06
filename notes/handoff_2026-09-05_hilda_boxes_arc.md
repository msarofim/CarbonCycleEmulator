# Handoff — CarbonCycleEmulator, 2026-09-05 (the HILDA HS/HD BOX-BUILD arc)
# **⭐⭐ THE STRUCTURE IS BUILT IN BOTH CORES, AND THE 09-04k2 CEILING WAS THE MISSING BOX.**
# **⛔ P4 FAILED: `q`'s ATTACHMENT DEPTH HAS THE WRONG SIGN, AND TWO ROUTES AROUND IT ARE NOW CLOSED.**
# **⛔ THREE RETRACTIONS, ALL MINE, ALL MADE IN PLACE — read §1 before quoting anything from today.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`,
commits **`7ae6011`, `e6008a4`, `afa25f5`, `d6587be` (4)**, working tree CLEAN. No remote.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-04_ocean_structure_arc.md` (this arc is its §8 item 1).

**Suite: 1798 → 1842 pass / 0 fail / 0 error / 4 skip.** Green throughout; +44 from
`tests/testthat/test-hilda-boxes.R`.
**No refit, no adoption, no model change to the shipped configuration.** `ent26` untouched;
`hs_frac` defaults to **0**, and 0 means the boxes do not exist.

---

## 0. WHAT THIS ARC ESTABLISHED, IN ORDER

1. **The HILDA HS/HD structure is BUILT** — 32 → 36 boxes, R **and** C++, parity tested, bit-exact
   off. §2
2. **P2: the 09-04k2 conduit ceiling WAS the missing box.** HILDA's own `u` is now feasible. §2
3. **P4 FAILED, and the reason is a mechanism result:** `q` injects water YOUNGER than the interior
   everywhere below ~1000 m. §3 — **this is the live finding.**
4. **Two routes around it are CLOSED**: HS thickness is analytically not a term; the gas exchange is
   the whole endmember but costs the entire `kz` relief and breaks an observation. §4
5. **The gate Marcus asked for should NOT be built** — the objective already pins that observable to
   ±0.93 ‰. §5
6. ⇒ **One candidate remains and it needs a DECISION, not a run.** §7

---

## 1. ⛔ THREE RETRACTIONS I MADE THIS ARC — read these before quoting anything from today

1. **"HS's shortfall against HILDA is TWO terms: gas exchange 1.97× AND thickness 1.79×, both
   pushing the same way."** ⛔ **THE THICKNESS TERM DOES NOT EXIST.** HS moves **0.2 ‰ across a 2.7×
   change** (134.1 → 50 m). It is **analytic**: in steady state HS's isotope ratio is a balance of
   rates *per unit volume*, and both the HS↔HD limbs (`u/h_hs`) and air-sea equilibration
   (`gx/(A·h_hs)`) carry the same `1/h_hs`, so the ratio — hence the steady state — is independent
   of it. Thickness sets the box's **INVENTORY**, i.e. how fast it *reaches* steady state.
   ⇒ **A RATIO OF TWO TIMESCALES THAT SHARE A FACTOR IS NOT A LEVER.** Retracted in place in
   `collect_2026-09-05_hilda_boxes.md` §2; pinned by a test whose control is the inventory.
2. **"GEOSECS excludes the `k_w` = 906 arm ⇒ `k_w` and `kz` are coupled through an UNSCORED
   observable ⇒ a candidate gate."** ⛔ **THE EXCLUSION IS REAL; THE INFERENCE WAS NOT.** The
   posterior pins `k_w` **20.8× tighter than its own prior**, so 906 is **−35.3 POSTERIOR sigma** —
   the likelihood had already excluded that arm by a colossal margin and the observation agreed with
   something not in doubt. Retracted in place in `collect_2026-09-05bc_hs_endmember.md` §4.
3. **My own gate scored a NO-CHANGE as a PASS.** `diag_hilda_hs_thickness.R` printed
   *"P4b — mean|z| below the 09-05 build's 2.05? 2.05 → CONFIRMED"*, comparing a live value against
   a constant **rounded to 2 dp out of the previous run's printout**; a fourth-decimal difference
   cleared it. ⇒ **NEVER GATE ON A THRESHOLD TYPED FROM ANOTHER RUN'S ROUNDED OUTPUT.**
   ⚠ Also **N1 in the first prereg was invalid by design** — see §6.

## 2. ⭐⭐ THE STRUCTURE, AND THE ONE PREDICTION THAT MADE THE ARC WORTH RUNNING

Siegenthaler & Joos (1992), *Tellus* **44B**:186–207, doi:10.3402/tellusb.v44i3.15441.
⚠ **The PDF at `~/Documents/2010/Essenhigh/siegenthaler92tel.pdf` is SCANNED — `pdftotext` returns
NOTHING. It must be read as images** (Fig. 1 p.187 is the geometry, Table 1 p.188 the parameters,
Table 2 p.189 the Δ¹⁴C targets).

Per hemisphere: a cold surface box **HS** at `hs_frac` of that hemisphere's ocean area over its own
well-mixed deep box **HD**, **beside** the low-latitude column, not under it. New parameters
`hs_frac` (0 = OFF), `u_hs` (HILDA **38 ± 17** m/yr over the HS area), `tau_q` (HILDA
**q⁻¹ = 538 ± 510** yr, volume-proportional), `sst_hs`, `h_hs` (0 = follow `h_ml`).

⚠⚠ **"OFF" MEANS ABSENT, NOT PRESENT-AND-EMPTY, AND THE BOX COUNT IS RUNTIME ON BOTH SIDES.**
Carrying two zero-mass boxes would make `ccx_spinup()`'s Newton Jacobian **and both isotope
operators singular** (all-zero rows and columns). `NPH`/`NB` in `src/ccx_core.cpp` are file statics
set by `unpack_aux()` from `aux$hs_on`, and **every entry point calls `unpack_aux()` before touching
`y`**. Not re-entrant across threads with two different structures; the calibration parallelises by
FORKING, so each worker has its own copy.

**P0 ✅** — `hs_frac = 0` bit-exact (32 boxes) with every HL parameter set; closure **1.33e-15**;
R vs C++ **5.70e-14**, *smaller than the incumbent's own 1.14e-13*.
⭐⭐ **P2 ✅ THE CEILING WAS THE MISSING BOX.** 09-04k2 found that at a whole-column-equivalent
`u` ≳ 2 **no `kz` holds the deep age at all**. HILDA's own `u` = 38 m/yr over 16 % of area is
**6.08** in that convention — **~3× beyond it** — and it solves at **`kz` = 1900 (0.299×)**, against
the reduced form's 0.500×. **P3 ✅.**
**P1 ✅ but BY 0.3 ‰**: HS emerges at **−80.3** against an LS mixed layer at −29.8 (a 50.5 ‰ split,
nothing prescribed), which is **outside HILDA's own −120 ± 30**. Do not quote it as "HILDA's HS
reproduced".
⛔ **P4 FAILED: scored mean |z| 2.05** (incumbent 2.55, reduced form **1.81**).

⭐ **The `u` = 0 arm is a finding on its own**: an HD reservoir with **no conduit at all** improves
the scored band **2.55 → 2.23 at essentially unchanged `kz`** (6356 → 6410). That is the reservoir,
not the conduit.

## 3. ⛔⛔ THE LIVE FINDING — `q`'s ATTACHMENT DEPTH HAS THE WRONG SIGN

At HILDA's own `u` and `τ_q`, **HD = −109.2 ‰** against the interior:

| depth | interior | HD − interior | what `q` does |
|---|---|---|---|
| 67–831 m | −29.3 … −101.0 | −79.8 … **−8.2** | **AGES** it |
| **1160 m** | −118.1 | **+8.9** | **YOUNGENS** it |
| **1622 m** | −134.7 | **+25.5** | **YOUNGENS** it |
| **2268 m** | −148.3 | **+39.1** | **YOUNGENS** it |

**The crossover sits at ~1000 m and the ENTIRE scored band is below it.** Those layers are already
too young (GLODAP −165.2 / −175.6 against the model's −134.7 / −148.3), so every unit of `q` there
is spent backwards.
⇒ **THE IMPROVEMENT COMES ENTIRELY FROM THE `kz` RELIEF AND `q` IS FIGHTING IT.** That is why the
reduced form beat the structure: **ML↔bottom-only collected the relief and paid NONE of the
penalty.**
⛔ **NOT a repeat of `w_out`** — that injected SURFACE water (−40 ‰); this injects HD water
(−109 ‰), 70 ‰ older. **The endmember is right; the DEPTH OF ATTACHMENT is wrong for our column.**

## 4. ⛔ BOTH ROUTES AROUND IT ARE CLOSED

**(a) HS thickness — analytically not a term.** See §1.1. It cannot move the crossover by one layer.

**(b) The endmember, reached through the gas exchange — the whole of it, and it does not pay.**
`k_w` derived in-script, not typed: HILDA's **15.1 ± 1.2 mol m⁻² yr⁻¹ at 280 ppm** against our
**29.80** at the same pCO₂ and 2 °C ⇒ **`k_w` = 906 m/yr**.

| arm | `k_w` | `kz` | HS | HD | mean \|z\| | LS ML vs GEOSECS −40 ± 20 |
|---|---|---|---|---|---|---|
| `ent26` | 1788 | **1900** | −80.3 | −109.2 | **2.048** | −29.8 ✅ |
| **HILDA** | **906** | **5334** | **−107.5** | −126.7 | 2.023 | **−78.5 ⛔** |
| half HILDA | 453 | — | — | — | — | **no `kz` holds the deep age** |

✅ HS **−107.5** against HILDA's own **−111** — **the endmember question is SETTLED, one term.**
✅ HD −126.7 and the crossover moves **1160 → 1622 m**.
⛔⛔ **But mean |z| moves 0.025, `kz` goes back to 5334 — almost the entire relief P2/P3 won is spent
buying the endmember — and the arm reads LS = −78.5.** ⚠ `k_w` is GLOBAL here, and HILDA themselves
assume **`g_l = g_h`**, so giving HS its own gas exchange would DEPART from the source.

## 5. ⛔ THE GATE MARCUS ASKED FOR SHOULD NOT BE BUILT

Marcus 09-05: *"Score GEOSECS LS-surface Delta14C as a gate first."* **Measured, and the answer is
no** — for a reason worth keeping.

⚠ **POWER WAS MEASURED BEFORE THE TARGET WAS SOURCED, DELIBERATELY.** The −40 ± 20 in play is
**prescribed in HILDA's Table 2**, a model calibration paper, attributed there to GEOSECS; **the
primary was never read.** The right product is **GLODAP's mapped NATURAL (pre-bomb) Δ¹⁴C** — Rubin &
Key (2002) potential-alkalinity separation, published in **Key et al. (2004) *GBC* 18:GB4031** — a
gridded field **not in this repo**, which would have needed a download.

✅ **P1d: the quantity spans 98.4 ‰** across ±2σ of `k_w`'s prior × the `kz` bracket.
⛔⛔ **P2d: the spread the EXISTING objective still permits is sd = 0.93 ‰**, against a 20 ‰ target
width; at the mode the model reads **−48.35**, already **z = −0.42** inside −40 ± 20.
⇒ **It would pass by construction — a SILENT GATE.**

⭐ **HOW IT WAS ALMOST MEASURED WRONG.** The first pass used a 2-D **SLICE** (the other 24 held).
That cannot establish redundancy — [[ccx_gates_priced]] measured that a **re-optimised** iso-fit
frontier REVERSES what a one-at-a-time `kz` scan says. Redone on the **posterior's own directions**
with the Laplace covariance already in the mode file: `sd = sqrt(gᵀ Σ g)`, **52 spinups, not 25
refits**. ⚠ Slice and profile agreed this time — **that is not the same as the slice having been
fine.**
⭐ **Independent hand cross-check:** the scan's **d(surface)/d ln `k_w` ≈ 59.9 ‰ per log unit** ×
the stored posterior sd **0.0193** = **1.15 ‰** against the Laplace **0.93** — consistent, two
routes sharing no code.
⇒ ⭐⭐ **"UNSCORED" IS NOT "UNCONSTRAINED".** Absence from the likelihood is about the list of rows;
being pinned is about the posterior. **Measuring power first is also what made the download
unnecessary.**

## 6. ⚠ NON-OBVIOUS STATE

* **Torch: nothing running.** Everything here is local; the diagnostics are seconds to ~3 min. The
  full suite is ~12 min.
* ⚠ **`hs_frac = 0` is the shipped configuration and MUST STAY THAT WAY** until a decision. Every
  number in `ent26` and every stored logpost is a 32-box number.
* ⚠ **The two columns SHARE AN ATMOSPHERE.** With `tau_q = 0` the high-latitude column is isolated
  *hydrographically* but HS still exchanges CO₂ with the atmosphere, so `prod_c14` moves and the LS
  bottom box shifts by **3.9e-04 ‰**. Pinned by a test; asserting exact equality there would be
  asserting that an air-sea flux does nothing.
* ⚠⚠ **N1 IN THE FIRST PREREG WAS INVALID AND I BUILT IT THAT WAY.** It gated the LEVEL of the
  ≤ 500 m band against GLODAP — but at a **preindustrial** steady state that band carries no bomb
  ¹⁴C, so the incumbent's own upper mean |z| is **4.54, essentially all artefact** (67 m: model
  −48.3 against an observed **+50.5**). This is the ⚠⚠ trap `handoff_2026-09-04` §5 states in so
  many words. **Only the between-arm DELTA is interpretable.** ⇒ **A control band must be chosen
  where the comparison is VALID, not where the defect is.**
* ⚠ **`sst_hs` has a HARD FLOOR of 2 °C, imposed by the chemistry, not by taste.**
  `data-raw/build_carbonate_tables.R` fits K0/K1/K2/Kb/Kw on `seq(2, 35, 0.25)` because **Lueker et
  al. (2000) is validated for 2–35 °C**. Verified with seacarb: at **+2 °C** it warns only for
  Kf/Kspa/Kspc, none of which this model uses; at **−1.8 °C** it warns for **K0, K1, K2, Kb AND
  Kw** — every constant the model does use. Going colder needs a polar-valid formulation
  (**Waters et al. 2014**, seacarb `k1k2 = "w14"`), which moves LS pCO₂ by **+0.14 % at 18 °C** and
  is therefore a separate, measured decision — **not a silent refit**. Marcus chose "refit to −2 °C"
  before this was known; **it was not done, and this is why.**
  ⚠ In a TRANSIENT run `sst_hs` picks up the hemispheric SST anomaly, so it dips below 2 °C and
  `carb_constants()` warns. Harmless for the preindustrial protocol used throughout this arc;
  **a transient study of these boxes needs the formulation question settled first.**
* ⚠ **`seacarb` is NOT on the default library path** — it lives in `~/Rlibs`. Use
  `.libPaths(c("~/Rlibs", .libPaths()))` before `library(seacarb)`.
* ⚠ **The `kz` bracket ENDPOINTS are not encodable.** `kz` is fitted under a **logit** transform, so
  `kzp$lo` / `kzp$hi` encode to ±Inf and `ccx_par_to_unc()` errors by name on them
  ([[runnable_is_not_encodable]] — the guard fired exactly as designed). `diag_surface_d14c_power.R`
  insets 2 % from each bound, with the reason at the constant.
* **`h_hs = 0` means FOLLOW `h_ml`**, and absence means the same thing. A parameter list written
  before 2026-09-05b reaches both cores as the 09-05 structure.
* **Memory:** four new files — `ccx_hilda_boxes_built`, `ccx_q_attachment_wrong_sign`,
  `ccx_hs_endmember_is_kw`, `unscored_is_not_unconstrained`, plus
  `gate_threshold_from_rounded_output`. `INDEX_ccx_ocean.md` is **17,227 B** and `INDEX_diag.md`
  **16,341 B** — both **over soft 14 KB, under hard 18 KB**; the superseded 09-04k conduit entries
  were compressed to make room. **Merge when convenient.**
* **Still owed from the previous handoff, untouched:** `DESIGN.md` §6 still describes a retired gate
  set at the quarantined `from90`; there is still **no LICENSE file**; the SOM-FFN recomputation tie
  for `SO_DPCO2_PEAK_MO`; `sst_seas_amp_NH` at −3.91σ; the posterior.

## 7. ⇒ THE OPEN DECISION, AND IT IS ONE DECISION

⭐⭐ **`q`'s ATTACHMENT DEPTH IS THE ONLY CANDIDATE THE DIAGNOSIS LEAVES, AND TAKING IT MEANS
DEPARTING FROM HILDA'S PUBLISHED STRUCTURE.** In HILDA, `q` exchanges with the Interior **as a
reservoir**, *"assumed independent of depth"* (their §2 and Fig. 1). Attaching it to the lower
interior only would make the structure **a boxed version of the 09-04k2 geometry that scored 1.81** —
it would collect the `kz` relief without the youngening penalty. **Cheap now that the boxes exist**
(one branch in each core, one prereg, one diagnostic). ⚠ **But the result could no longer be called
HILDA's model, and every number would need that label.**

**The alternative reading, which is honest and should be on the table:** P4 failed, both routes
around it are closed, and **HILDA's geometry may simply not fix our intermediate water.** The
structure stays in the repo, bit-exact off, available — and the arc closes.

**Ranked, for whoever picks this up:**
1. ⭐⭐ **The `q` attachment-depth decision** (above). Marcus's call, not a measurement.
2. ⭐ **`DESIGN.md` §6** — the acceptance criteria still describe a retired gate set at a
   quarantined mode. Cheap, uncontroversial, and it has been owed for two handoffs.
3. **LICENCE** — Marcus's call, blocks any public release.
4. **The carbonate formulation** (§6) — only needed if the HS boxes ever go transient or below 2 °C.
5. **A posterior**; `sst_seas_amp_NH` at −3.91σ; the provisional-constant triage; CITATION + DOI.

## 8. ⇒ STANDING RULES THIS ARC ADDED

* ⭐⭐ **"UNSCORED" IS NOT "UNCONSTRAINED".** Before proposing a gate on an observable the likelihood
  does not score, measure the spread the existing objective still permits — **on the posterior's own
  directions (`sqrt(gᵀ Σ g)` off the stored Laplace covariance), never on a coordinate SLICE**, which
  overstates the pinning. Cross-check by hand against `d(obs)/d ln(param) × sd_unc`.
* ⭐⭐ **A RATIO OF TWO TIMESCALES THAT SHARE A FACTOR IS NOT A LEVER.** Cancel the algebra before
  pricing the mechanism — and before predicting from it.
* ⭐ **NEVER GATE ON A THRESHOLD TYPED FROM ANOTHER RUN'S ROUNDED OUTPUT.** Recompute the baseline in
  the same run and gate on a DELTA against a named materiality tolerance. Where a cross-run
  reference genuinely cannot be recomputed, report a verdict inside its rounding as
  **INDISTINGUISHABLE**, not as a pass or a fail.
* ⭐ **A CONTROL BAND MUST BE CHOSEN WHERE THE COMPARISON IS VALID, NOT WHERE THE DEFECT IS.**
* ⭐ **"OFF" SHOULD MEAN ABSENT, NOT PRESENT-AND-EMPTY**, whenever a solver inverts the state: empty
  boxes are all-zero rows and columns, and they make a Jacobian singular rather than a no-op.
