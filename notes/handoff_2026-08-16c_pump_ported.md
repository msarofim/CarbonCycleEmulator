# Handoff — CarbonCycleEmulator, 2026-08-16c: task 9 is DONE (the pump is in both cores, OFF by default), the alkalinity row is the fourth term, and two numbers I reported earlier this session are CORRECTED

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`, still
**not merged**, working tree clean at **`aa16b2d`**. Suite **4 failing / 858 passing** (was
4 / 746 at the start of the session); the four are the pre-existing ones, unchanged, none
flagged for Marcus.

**Supersedes `handoff_2026-08-16b_gradient_terms_shipped.md` for §5 (the ordering) and §6
(open decisions).** Its §1–§4 stand: the gradient terms' targets, σ, epochs and `h_ml` gate
are unchanged, and its §3 point — that zero leverage did NOT survive transient scoring —
still holds and is now joined by a third row that has *literally* zero leverage (§3 below).

**Commits this session:** `78b0b28` (§6-item-2 answered) → `dd532b7` (alkalinity question) →
`a8a042c` (the fourth term) → `aa16b2d` (the port).

---

## 0. START HERE

1. **Task 9 is DONE. The pump is in `R/model.R` AND `src/ccx_core.cpp`, and it is OFF by
   default** — `pump_grad = 0` makes `aux$pump` NULL and not one line of pump code runs, so
   every pre-2026-08-16 result is bit-reproduced. §4.
2. **The objective now has FOUR ocean-gradient rows.** `ocean_grad_alk` shipped at
   +78.5927 ± 19.199 µmol/kg. **logL moved twice today** (−12.25 for the alkalinity row, and
   the port moves nothing while off) and is incomparable with anything before tonight.
3. **TWO NUMBERS I REPORTED EARLIER TODAY ARE WRONG AND ARE CORRECTED HERE.** The shim's
   export figures are **~15 % high** (§5), and the "3.6× the literature POC midpoint" claim is
   nearer **3.1×**. No row the likelihood scores is affected. **If you carry one thing forward,
   carry that** — the export is the pump's plausibility check and it gets quoted.
4. **The single soft-tissue pump does NOT close δ¹³C**, but it misses by a hair and the failure
   is a FRACTIONATION failure, not a size one. §2.
5. **The preindustrial arithmetic for the pump's fractionation is a TRAP** (ε = −8.40 ‰ is
   105.9 log-units WORSE than −20). Three independent GLODAP gradients are mutually consistent
   **only** under transient scoring. §2, §3.
6. **`pump_grad`'s value is a DESIGN decision nobody has taken.** The default is 0. §7 item 1.
7. **The refit (task 8) is now the only thing left in the round.**

---

## 1. What Marcus decided today

| question | decision |
|---|---|
| N vs D export law | **Port BOTH, decide at the refit.** Done — `pump_mode`, default `"N"`. |
| Should alkalinity stop being fixed? | Asked as a counter-question; **answered NO** by measurement (§3), and the ALK gradient became a term instead. |
| Make the ALK gradient a fourth term? | **Yes**, "if there isn't a good reason to avoid it". There wasn't. §3. |
| Start the port | Done. §4. |

---

## 2. §6 item 2, ANSWERED: the DIC pump does not close δ¹³C

`calibration/diag_pump_vs_gradient_terms.R` (~3.5 min), scored through the **shipped** streams
(transient, fixed depths, block-bootstrap σ) at the pre-gradient mode with `h_ml` forced to 100.

| arm | export | z_DIC | z_δ¹³C | z_deep¹⁴C | Δ logL |
|---|---|---|---|---|---|
| pump OFF | 0 | **−11.10** | **+16.84** | +1.48 | 0 |
| soft-tissue ε = −20, g = 1 | 25.2 | **−1.87** | **−2.42** | +1.08 | **+245.9** |
| ε = −8.40 (preindustrial arithmetic) | 25.2 | −1.87 | **+8.47** | +1.08 | +213.0 |
| ε = 0 (control) | 25.2 | −1.87 | +16.36 | +1.08 | +115.2 |
| **ε\* = −14.55, g\* = 1.2021** | 30.3 | **+0.00** | **+0.19** | +1.00 | **+252.3** |

*(Those exports are the SHIM's and are ~15 % high — §5. The z columns are unaffected.)*

**The rows want export scales 1.37× apart** — DIC ×1.202, δ¹³C ×0.874, and 1.37 = 20/14.55 is
exactly the fractionation gap. So no single scale closes both; it is the ε that is wrong.

**THE TRAP.** The observed pair (+233.109, −0.8610) at deep DIC 2273.1 implies ε = **−8.40 ‰**
(56 % carbonate). That is *preindustrial* arithmetic and the terms are *transient*: pump-OFF the
model sits at −47.1 µmol/kg and +1.0167 ‰ at the obs epoch, so the pump must supply
**+280.2 / −1.8777**, whose ratio is not the observed ratio. Building the pump on ε = −8.40
would have cost **105.9 log-units** on `ocean_grad_d13c` against plain soft-tissue.

**Unasked-for, FLAGGED NOT BANKED:** mode D gains **+441.3** against N's **+245.9**; the whole
**+195.4** is the CO₂ record (`co2_level_SPO` +107.3, MLO +93.6, icecore −9.1), sink
2.913 → 3.051 GtC/yr. **The gradient rows cannot tell N from D — they move identically.** A
refit has `beta_max` and `kz` free and could reallocate all of it. Hence "port both".

**Clause 3's operating-point sign flip reproduces:** deep Δ¹⁴C +1.48 → +1.08 at the mode
(toward), −1.01 → −1.42 at defaults (away).

**A verdict-logic error of mine, caught by its own run and kept visible in the file.** I first
classified the failure by the SIGNS of the two z. Both came out negative, which a sign test reads
as "one scale fixes both" — the opposite of the truth, because the DIC target is positive
(z < 0 = pump too small) and the δ¹³C target negative (z < 0 = too much depletion). Equal signs
are OPPOSITE corrections. Replaced with the required-scale test.

---

## 3. Alkalinity: the question was two questions, and the third thing was the prize

`calibration/diag_alk_gradient.R`.

**Q1 — is a carbonate limb blocked by fixed alkalinity? NO, and my own DESIGN §5.2c line saying
otherwise is corrected there.** Checked by grep, not recalled: `ALK_SURFACE` enters the
**mixed-layer carbonate solve and nowhere else** (`ccx_dic_for_pco2`, `pco2_from_dic`, a
`revelle_factor` diagnostic). The interior has no alkalinity and no carbonate chemistry, so a
carbonate limb is just a second export field with its own δ¹³C signature.

**Q2 — would a tracer change uptake? Barely, because the model is already right.** `ALK_SURFACE`
= 2300 against GLODAP's **2303.4** on the shipped surface layer; a tracer can only let it
*drift*, and alkalinity is near-conserved over 1750–2024. **d(Revelle)/d(ALK) = −0.0005 per
µmol/kg**, so 10 µmol/kg of drift moves the buffer factor **0.05 %**. Not competitive with
`h_ml`.

**Q3, the prize: `G2talk` was sitting in the 894 MB master this repo already had.** On the
shipped fixed depths with the same weighting: **2303.4 (0–100 m, 829 cells) / 2382.3
(>2627.2 m, 5886 cells), gradient +78.59** ⇒ with ΔALK = 2·C_carb − (16/117)·C_org, a
**23 % carbonate share**.

**It adjudicates transient-vs-preindustrial from an observation not used to decide it** —
alkalinity carries no Suess signal and essentially no C_ant. Fix the split by ALK and the
fractionation at ε_org = −20, and the δ¹³C gradient is a prediction with nothing left to tune:

| scoring | predicted δ¹³C | required | ratio |
|---|---|---|---|
| preindustrial (D = +233.1) | −1.578 ‰ | −0.861 | **1.83** |
| **transient (D = +280.2)** | **−1.965 ‰** | **−1.878** | **1.05** |

### 3.1 The fourth term as shipped

| | value |
|---|---|
| target | **+78.5927 µmol/kg**, same fixed depths and `h_ml` gate |
| σ | **19.199** — block bootstrap **on the contrast**, 4000 draws, seed 20260816, conservative of 30°/60° (30° gives 13.879) |
| miss with **no pump** | **4.09 σ = −12.25 log-units** |

Every pre-existing field of `obs_glodap_deep.rds` is **bit-identical** (`all.equal`,
tolerance 0). `gd_grad_boot()` re-seeds per call, so the new bootstrap cannot perturb the
shipped ones.

**POPULATION CHECK, because my first carbonate share mixed two samples.** The shipped DIC
target is on the isotope subset (2897/533 cells); alkalinity has 5886/829. The DIC gradient
recomputed **on the ALK population** is **+225.81** vs the shipped **+233.11** — a **−0.29 σ**
move, share 22 % → 23 %. Immaterial, now measured, stored as `gradient$tco2_alkpop`. **The
shipped DIC target is unchanged.**

**THE MODEL SIDE IS A STEADY-STATE SOLVE, NOT A FOURTH TRACER.** Alkalinity has no air-sea flux,
no decay and no anthropogenic source ⇒ **no transient** ⇒ its profile follows from the export
field alone. `ccx_steady_profile_from_source()` is the **exact inverse of `dg_export_field()`**,
which is what made the row testable before a pump existed (round-trip test).

**BEFORE THE PORT this row had LITERALLY zero leverage** — `ccx_model_ocean_alk_gradient()`
returned exactly 0 for every parameter, a model *prediction* (no carbonate pump ⇒ nothing can
separate the layers), asserted across `h_ml` × `kz`. **Since the port it is live**: it is read
off `spin$aux$pump`, the same field the derivative integrated, so it cannot be scored against a
pump the run did not use.

**A latent bug the new row exposed** in the row shipped that morning: the term loop used
`is.finite(ocean_grad[[field]])`, and every caller written earlier passes no `alk` element —
`is.finite(NULL)` is `logical(0)`, an **error** in `if`, not FALSE. Guarded with
`length(v) == 1L`, which also keeps the absence contract.

---

## 4. THE PORT (task 9)

Out of `calibration/pump_shim.R` and into both cores.

**OFF BY DEFAULT, AND OFF MEANS BIT-REPRODUCED.** The guard is `is.null(aux$pump)`; the whole
suite is the gate.

| parameter | default | what it is |
|---|---|---|
| `pump_grad` | **0** | preindustrial bottom-box-minus-ML DIC gradient held, µmol/kg |
| `pump_carb_frac` | **0.23** | carbonate share, **pinned by the alkalinity gradient**, not fitted |
| `pump_mode` | `"N"` | `"N"` mass fixed / `"D"` scales with ML carbon. Both ported. |

- **Zero fitted parameters in the field.** Still solved as the source that makes GLODAP's
  observed DIC shape an exact steady state of the model's own diffusion operator. The shape is
  now a build product (`obs_glodap_deep.rds$dic_profile`; **25 m bins to 300 m**, 50 m to 500,
  250 m below) integrated onto whatever layers a draw asks for.
- **`pump_grad` is RE-NORMALIZED on each grid's own layers**, so it delivers exactly the
  gradient it names. Without that step 233.109 landed at 235.7, because a model layer averages
  several observed bins and the bottom layer's mean shape is 1.011, not 1.
- **Emitted through `add_flux()`, not by touching `dy`** — conservative by the same construction
  as every other flux, isotopes at the source ratio, and it has its own `pump` flux channel. The
  shim could do none of this (it stopped with an error under `record = TRUE`).
- The two ¹³C fractionations (`PUMP_EPS13_ORG` −20 ‰, `PUMP_EPS13_CARB` +1 ‰) are the pump's
  **only uncited numbers** and are on the provisional-constants ledger.

**Verified:** R↔C++ parity **~1e-15** in both modes; the spinup is still an exact fixed point
(the Newton branch now fires on the pump as well as the conveyor); `pump_grad` delivered exactly
across `h_ml` ∈ {85, 100, 120} × three magnitudes; and the pre-registered **zero-uptake property**
of a constant-mass pump is now a standing test (`tests/testthat/test-pump.R`) rather than a
diagnostic's one-off finding.

**As shipped** (`pump_grad` 233.109, h_ml 100, 23 % carbonate): **z_DIC −1.79, z_δ¹³C +2.02,
z_ALK +0.21**. The carbonate limb does what it was added for — the same DIC gradient costs
δ¹³C −0.636 against the single limb's −1.132.

---

## 5. THE CORRECTION: the shim's export was 15 % high, and my first diagnosis of it was wrong

`calibration/diag_pump_port_parity.R`. Port parity agrees to **0.66 % on every row the
likelihood scores** (DIC 0.00 %, δ¹³C 0.66 %, deep Δ¹⁴C 0.23 %) — but export disagreed by 28 %.

**I assumed the fixed-bin profile was too coarse near the surface. Refining it moved the gap
28 % → 8.8 % → 15.2 % across 250 m → 50 m → 25 m bins — NOT monotonically toward the shim**,
which is what said the diagnosis was wrong rather than under-resolved.

**Measured cause.** Total export is the diffusive flux across the topmost interface alone (the
sum telescopes), so it is set by the **mixed layer's mean DIC**. The shim's `dg_bin()` assigns
cells by `floor(depth/250)`, so **all of 0–100 m is ONE cell** and its mean is weighted by
**bottle density** — and GLODAP over-samples the shallowest water, where DIC rises fastest
(25 m sub-bin means run 2017.7 → 2083.9 across 0–100 m). Shim ML **2038.29** against a
thickness-weighted **2048.33**: **10.04 µmol/kg too low**, ML-to-box-1 gradient too steep,
export **~15 % too high**. A model mixed layer is a well-mixed slab, so **the port is the better
estimator, not the deviant one**.

**What changes:** shim exports 20.6 GtC/yr (defaults) / 25.2 (mode) / 30.3 (g\*) are all high by
~15 %; **at defaults the port gives 17.4**, and the literature-POC ratio is nearer **3.1×** than
3.6×. **The mode and g\* figures were NOT re-measured.** Corrected in DESIGN §5.2c, the
CHANGELOG, and memory. Nothing the likelihood scores is affected.

---

## 6. Files

| file | what changed |
|---|---|
| `calibration/pump_shim.R` | **NEW** — the shim, `dg_export_field()`, `dg_spinup()`, `dg_parity_gate()` and the GLODAP profile helpers EXTRACTED verbatim from `diag_dic_gradient.R` so the diagnostics cannot drift; + a double-source guard |
| `calibration/diag_dic_gradient.R` | sources the shim instead of carrying it. Re-run end-to-end: `all.equal` vs the pre-refactor `.rds` is **TRUE** |
| `calibration/diag_pump_vs_gradient_terms.R` | **NEW**, ~3.5 min. §2 |
| `calibration/diag_alk_gradient.R` | **NEW**, ~2 min first run. §3 |
| `calibration/diag_pump_port_parity.R` | **NEW**, ~2 min. §5. The port's acceptance gate |
| `data-raw/build_glodap_deep_targets.R` | ALK gradient block (+ `G2talk` extraction → `glodap_dic_talk_subset.csv`), `tco2_alkpop`, and the `dic_profile` export shape |
| `data/obs_glodap_deep.rds` | rebuilt; pre-existing fields bit-identical |
| `R/likelihood.R` | `alk` target, `ccx_steady_profile_from_source()`, `ccx_model_ocean_alk_gradient()`, the third Gaussian, the `length(v) == 1L` guard, pump read off `spin$aux$pump` |
| `R/model.R` | `pump_grad` / `pump_carb_frac` / `pump_mode`; `ccx_pump_shape()`, `ccx_pump_export()`; `aux$pump`, `aux$ml_C0`; the pump flux in `ccx_deriv()` |
| `R/spinup.R` | Newton gate now fires on the pump as well as the conveyor |
| `R/cpp.R` | pump marshaling (flat 2×NL, zero-filled when off), `pump_mode` in the par contract |
| `R/constants.R` | `PUMP_EPS13_ORG`, `PUMP_EPS13_CARB` |
| `R/fluxes.R` | `pump` channel |
| `src/ccx_core.cpp` | `Aux.pump_*`/`ml_C0`/`alpha_pump_*`, `Par.pump_mode`, the flux |
| `tests/testthat/test-pump.R` | **NEW**, 6 blocks |
| `tests/testthat/test-likelihood.R` | +4 blocks for the alkalinity row |
| `tests/testthat/setup.R`, `test-climate.R` | `skip_if_no_cpp()` moved to `setup.R` |
| `tests/testthat/test-constants.R` | provisional-constants ledger updated |
| `DESIGN.md` | §5.2c **corrected**, §5.2d (alkalinity), §5.2e (the term), §5.2f (the port) |

---

## 7. Open decisions, in dependency order

1. **WHAT SHOULD `pump_grad` BE?** Not taken, deliberately; the default is 0. The observed
   gradient is **233.1**; the transient rows want **~1.20×** that (§2). And whether it becomes a
   FITTED parameter at the refit, or stays a fixed structural value, is the same decision.
2. **Does the pump ship ON?** Turning it on changes every result in the repo. The port is
   reversible by construction — this is a separate, explicit decision.
3. **N or D?** Deferred to the refit by decision. Note D's +195 is entirely the CO₂ record and a
   refit can reallocate it; do not read the unrefitted margin as evidence.
4. **THE REFIT (task 8)** — after 1–3, once, against the complete four-row objective.
5. **Where does the refit's `h_ml` land?** If it leaves **[85, 120]** all three gradient rows go
   absent and the targets need re-deriving. The gate exists so this is visible.
6. **σ_Δ has NOT plateaued in block size** (30° → 60° still rising) for any of the rows,
   including alkalinity. Shipped conservative. Unresolved. (carried)
7. **Representation error still ZERO**; **point σ vs Student-t**; **is A's `kz` = 6404 a blocker
   or a re-derivation**; **does candidate A ship at all**. (all carried unchanged)

---

## 8. Non-obvious state, and cautions

- **`calibration/output/mode_fit.rds` is still EMPTY.** Every "at the mode" number in this note
  comes from the quarantined pre-gradient mode at
  `calibration/output/quarantine/20260815_pre_gradient_terms/mode_fit.rds`.
- **19 parameters + 3 pump parameters**, none of the three free.
- **THREE of my claims were measured FALSE this session and all three are kept visible in the
  files rather than edited away**: the sign-based verdict test (§2), "the carbonate limb needs
  alkalinity freed" (§3 Q1), and "the export gap is bin resolution" (§5). Weight the tables over
  the prose, including the prose here.
- **Two of my own tests were wrong and are documented in place**: mode N and D are **identical**
  at the preindustrial state (the ML holds exactly `ml_C0`, so the DIC-limited scaling is 1) —
  they diverge only once it is loaded; and the corrected version asserted equality to 1e-14 when
  the Newton spinup lands the ML on `ml_C0` to ~1e-7 GtC.
- **Name collision, unchanged:** `grad_off_co2` / `grad_off_d13c` in `err` are the **MLO−SPO
  ATMOSPHERIC** offsets. The ocean rows are `LIK_OCEAN_GRAD_*` / `ocean_grad_*`. Do not merge.
- **`luc-veg-debit` has never been merged** and is now a long way from `main`.

**Still do NOT:** hand-tune stream weights; delete `excess_c14_ocean` or `d14c_intcal`; free any
land turnover parameter; delete the `kz` bracket bare; build the conveyor; splice any
pre-2026-08-15 posterior; **compare any logL across the 2026-08-16 boundary** (the objective moved
~199 log-units for the first two rows and another −12.25 for the third); quote §4.2's ~384
log-units or its 1996.2555 baseline; quote the defaults-parameter clause-3 verdict as the answer;
quote the free validations as if the likelihood had rewarded them; **quote the SHIM's export
figures or the "3.6×" POC ratio** (§5); or quote the alkalinity row as evidence about anything
from before the port, when it was a literal constant.

---

## 9. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-16c_pump_ported.md`. **Task 9 is done — the pump is in both cores,
> OFF by default (`pump_grad = 0` is bit-reproduced), two limbs with the carbonate share pinned
> at 23 % by GLODAP's alkalinity gradient, and both N and D export laws ported.** The objective
> now carries FOUR ocean rows; `ocean_grad_alk` is live off `spin$aux$pump`. **Do not quote the
> shim's export figures — they are ~15 % high (§5).** The open decision before the refit is §7
> item 1: **what `pump_grad` should be**, and whether it is fitted — the observed gradient is
> 233.1 and the transient rows want ~1.20× that. Suite 4 failing / 858 passing, none flagged.
