# COLLECT — 2026-09-05d. **DO NOT BUILD THE GATE.** THE SURFACE Δ¹⁴C IS UNSCORED
# BUT NOT UNCONSTRAINED: THE EXISTING OBJECTIVE PINS IT TO **±0.93 ‰**.
# ⛔ **AND THIS RETRACTS 09-05c's "GEOSECS EXCLUDES THE ARM" AS A CLAIM THAT ADDED ANYTHING.**

Scores `notes/prereg_2026-09-05d_surface_d14c_power.md`.
`calibration/diag_surface_d14c_power.R`. **No gate built, no target asserted, nothing adopted.**

---

## 0. THE ANSWER

| | prediction | result |
|---|---|---|
| **P1d** | the quantity moves > 20 ‰ across the prior support | ✅ **98.4 ‰** (−123.2 to −24.7) |
| **P2d** | it can move > 20 ‰ for < 2 logpost units, i.e. it is NEW information | ⛔ **FALSIFIED. Posterior-induced sd = 0.93 ‰.** |
| **P3d** | rises with `k_w`, falls with `kz` | ✅ both, as predicted |

⇒ ⛔ **THE GATE WOULD BE REDUNDANT AND SHOULD NOT BE BUILT.** At the mode the model reads
**−48.35 ‰**, which is already **z = −0.42** inside HILDA's −40 ± 20, and the existing objective
holds it there to **±0.93 ‰** — twenty times tighter than the target's own width. A gate on it could
never reject anything the likelihood does not already reject: **it would pass by construction, which
is the definition of a silent gate.**

## 1. ⭐ THE MEASUREMENT WAS ALMOST WRONG, AND THE FIX IS THE REPO'S OWN LESSON

The first pass measured P2d on a **2-D SLICE** — `k_w` × `kz` with the other 24 parameters held —
and got "0.0 ‰ within 2 logpost units, 1 cell of 25". ⛔ **That number cannot establish redundancy.**
[[ccx_gates_priced]] measured that an iso-fit frontier which **re-optimises the others REVERSES**
what a one-at-a-time `kz` scan says; a slice through a correlated posterior **overstates** how
pinned a quantity is.

**Redone on the posterior's own directions**, using the Laplace covariance already stored in the
mode file (26 × 26, `pd = TRUE`) — linearise the observable in the unconstrained coordinates and
take `sd = sqrt(gᵀ Σ g)`. **52 spinups, not 25 refits.**

⇒ **sd = 0.93 ‰**, and **the slice and the profile agree** — so the risk I flagged did not
materialise this time. ⚠ **That is not the same as the slice having been fine**: it was still the
wrong measure, and it agreed by luck of a near-diagonal direction.

⭐ **AND AN INDEPENDENT ARITHMETIC CROSS-CHECK CLOSES IT.** The scan gives
**d(surface)/d ln `k_w` ≈ 59.9 ‰ per log unit**; the stored posterior sd of `k_w` is
**0.0193 in log space**. 59.9 × 0.0193 = **1.15 ‰** against the Laplace result **0.93** —
**consistent**, by two routes that share no code.

## 2. ⛔⛔ THE RETRACTION THIS FORCES

`collect_2026-09-05bc_hs_endmember.md` §4 said the `k_w` = 906 arm was **"EXCLUDED by GEOSECS"** and
called the pair *"coupled through an UNSCORED observable — a candidate gate"*. **The exclusion is
real and the inference from it was not.**

**The posterior pins `k_w` to sd = 0.0193 in log space — 20.8× tighter than its own prior.** HILDA's
`k_w` = 906 is therefore **−35.3 POSTERIOR sigma** from the mode. **The existing likelihood had
already excluded that arm by a colossal margin; GEOSECS agreed with something that was not in
doubt.** An observation that agrees with a quantity already pinned to ±0.93 ‰ adds no information,
however well sourced it is.

⇒ ⭐⭐ **STANDING RULE: "UNSCORED" IS NOT "UNCONSTRAINED".** An observable absent from the likelihood
can still be pinned by everything else in it. **Before proposing a gate on an unscored quantity,
measure the spread the EXISTING objective still permits — on the posterior's own directions, not on
a coordinate slice.** A gate whose observable is already pinned is a silent gate that passes by
construction, and it will look like a check for as long as nobody measures it.

## 3. ⚠ AND THE TARGET WAS NEVER SOURCED — WHICH NO LONGER MATTERS, BUT SHOULD BE ON THE RECORD

The value in play, **−40 ± 20 ‰**, is **prescribed in HILDA's Table 2** — a model calibration paper
— attributed there to GEOSECS. **I did not read the primary and the number was never promoted to a
sourced target.** The right product exists: **GLODAP's mapped NATURAL (pre-bomb) Δ¹⁴C**, from the
Rubin & Key (2002) potential-alkalinity separation, published in Key et al. (2004) *GBC* 18:GB4031.
It is a gridded field, **not in this repo**, and acquiring it would have meant a download.
⇒ **Measuring the power first is what made that download unnecessary.** Had the order been
reversed, the dataset would have been acquired, a build script written, a MANIFEST entry added, and
an `n_eff` argued — to gate a quantity with an achievable spread of 0.93 ‰.

## 4. ⇒ WHAT IS LEFT

- ⛔ **The GEOSECS surface gate is CLOSED as a proposal.** Not because the observation is bad, but
  because the model has no freedom left in that direction.
- ⚠ **The 09-05 mechanism result is untouched by any of this**: `q` injects water younger than the
  interior everywhere below ~1000 m, and its **attachment depth** remains the only candidate the
  diagnosis names for the intermediate defect — a **departure from HILDA's Fig. 1**, still awaiting
  a decision.
- ⭐ **One thing the scan produced that IS worth keeping**: the model's preindustrial surface Δ¹⁴C is
  **−48.35 ‰**, and the observation it would have been gated against puts it at **−40 ± 20**.
  **Report it as an agreement, never as a test.**
