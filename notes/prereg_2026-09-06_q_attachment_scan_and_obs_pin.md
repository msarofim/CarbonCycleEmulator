# PREREG — 2026-09-06. **`q`'s ATTACHMENT: THE DECOMPOSITION, THE BOUNDARY, THE PIN AT THE OBSERVATION, AND THE TWO-TIMESCALE TEST.**

Scores nothing yet. Written **before** `calibration/diag_q_attachment_scan.R` exists and before any
run. Follows `collect_2026-09-05f_q_attachment.md` §5, which owed items 1 and 2 below, and
`handoff_2026-09-06_session_close.md` §7.

**Marcus's ruling (2026-09-05) still governs:** *"We don't need to stay true to HILDA, but we should
stay true to the conceptual way that the simplified model's ocean works."* Every arm with
`q_attach_from > 1` is **HILDA HS/HD boxes with `q` attached below the surface — a deliberate
departure from HILDA. NOT "HILDA's model."** Nothing here is adopted, fitted or refit. `hs_frac`
ships 0; `ent26` is untouched.

---

## 0. WHAT IS OWED, AND WHAT IS NEW

| part | status | what it settles |
|---|---|---|
| **A** matched-`kz` decomposition | **OWED** — 09-05f ran it POST HOC | is the P2 gain the attachment's, or `kz`'s |
| **B** the attachment BOUNDARY | **OWED** — only layers 1 and 10 were run | is the bottom the optimum, or was it a lucky endpoint |
| **C** the pin at the OBSERVATION | **NEW** | can this structure put the whole scored band inside \|z\| < 1 at all |
| **D** the two-timescale test | **NEW** | does the structure hold the DECADAL ocean streams while the deep is right — HILDA's actual claim |

### Why C is not optional, and why it is a control change and not a score change

The iso-deep control pins the LS bottom box at the **incumbent's own** value, **−156.145 ‰** — which
sits at **z = +1.85** against the sourced GLODAP target (−175.3 ± 10.3, `d14c_deep_ocean`). That
choice was right for its purpose: it made the intermediate PROFILE comparable across 2.55 / 2.048 /
1.81 / 1.739 at one deep age. But it has two consequences the arc has now measured:

1. **A third of every arm's score is the same +1.85** ([[iso_deep_control_licenses_one_comparison]]).
   The floor of the full-band statistic is 1.85/3 = **0.62** even with the free layers perfect, and
   **no arm on that control can ever reach DESIGN §3.4a's \|z\| < 1 on every layer** — the pinned
   layer is outside it by construction.
2. The control is a threshold taken **from the code under test**. `~/.claude/CLAUDE.md`: *"Thresholds
   come from an OBSERVATION or a PHYSICAL LAW first … 'another model' NEVER means the code under
   test."* The observation exists and is the likelihood's own sourced target.

⇒ Part C keeps the iso-deep protocol for continuity and ADDS a second control — **`kz` solved so
the bottom box hits the sourced target −175.3** — and reads the profile there. ⚠ This does NOT
replace the score; both statistics are reported on every arm, with the pinned layer's dead-weight
\|z\| printed beside them. **Measure the dead weight; never silently redefine a score.**

### Why D is the test that matters for adoption

A steady-state profile cannot discriminate structures: with `kz` free, **any** column can be made
to hit one deep number. What the incumbent could not do is hold the deep age AND the decadal ocean
constraints — the bomb Δ¹⁴C (`d14c_NH`/`d14c_SH`, gate 5) and the modern sink (`gcb_ocean_sink`,
gate 7) — with one `kz`. That is the tension `ent26` resolved by leaving the deep at +1.85. HILDA's
claim is that a high-latitude formation pathway lets the low-latitude `K` be small (deep right)
while the cold box carries the decadal uptake. **D tests that claim directly, at matched
parameters, before any refit.**

---

## 1. PROTOCOL (shared)

- Base vector: `dg_vector(CCX_MODE_CANONICAL)` = `ent26`, migrated, printed. HS at HILDA's values:
  `hs_frac` 0.16, `u_hs` 38, `tau_q` 538, `sst_hs` 2 — exactly `diag_q_attachment.R`'s `par_q()`.
- Steady-state preindustrial spinup for A–C; the 1750–2024 transient (`dg_run`) for D.
- Observed profile: `dg_obs_profile()` on the mode's grid, z = (model − obs)/(sd/√20), n_eff as the
  likelihood's. Scored band = layers with `zmid > 1500` (1622 / 2268 / 3172 m). **Two statistics on
  every arm, always both:** `mean|z|_band` (comparable with the arc) and `mean|z|_free` (the two
  unpinned layers). The pinned layer's own |z| is printed as the dead weight.
- **Iso-deep** = `kz` solved to hold the bottom box at the incumbent's `d0` (recomputed in-run).
  **Obs-pinned** = `kz` solved to hold it at `ccx_deep_d14c_target()$target` (read, not typed).
- Every reference is recomputed in this run. No number is typed from a previous collect.
- Tolerance for "an arm beats another": **0.05 in mean|z|** = 0.05 × 13.4 ‰ ≈ **0.7 ‰** on a free
  layer. A JUDGMENT, declared here so it cannot be chosen after the fact; it is ~5 % of the
  arc's total range (2.55 → 1.74) and well above the shared-atmosphere coupling (4e-4 ‰).

---

## 2. PART A — THE DECOMPOSITION, PRE-REGISTERED THIS TIME

2 × 2: `kz` ∈ {`kz_ref` (iso-deep at attach 1), `kz_test` (iso-deep at attach 10)} × attach ∈ {1, 10}.
Off-diagonal cells are OFF the iso-deep control and their bottom box is not pinned, so **the
comparable statistic across all four cells is `mean|z|_free`**; the band statistic is printed for
the record and never quoted as a score off the diagonal.

| | prediction | falsifier |
|---|---|---|
| **A1** | at BOTH `kz` values, attach 10 beats attach 1 on `mean|z|_free` by > 0.05 | either `kz` fails |
| **A2** | the attachment main effect exceeds the `kz` main effect on `mean|z|_free` (averaged over the other factor) | `kz` effect ≥ attachment effect |
| **A3** | the interaction (difference of differences) is smaller than the smaller main effect — the two act roughly additively on this band | interaction ≥ the smaller main effect |

If A1 fails the 09-05f attribution is withdrawn: the gain would be `kz`'s, and the arm is not what
`ccx_q_attach_bottom` says it is.

## 3. PART B — THE BOUNDARY, DECLARED IN FULL

`q_attach_from` ∈ {1, …, 10}, **every layer**, iso-deep, `tau_q` = 538, `u_hs` = 38. The whole scan is
reported. ⛔ **It is not scored by picking its best.** The predictions below are about the SHAPE of
the scan, stated from the crossover arithmetic of 09-05 ([[ccx_q_attachment_wrong_sign]]: HD ≈ −100
to −109 ‰; the interior crosses that near layer 7, ~1160 m).

| | prediction | falsifier |
|---|---|---|
| **B1** | **`kz` is monotone non-decreasing in the attachment index** — `tau_q` is per-layer, so each layer dropped is less exchange and `kz` must do more | any decrease beyond solver tolerance (1e-3 relative) |
| **B2** | **no interior optimum:** `mean|z|_free` is minimized at layer 10, with every k < 10 worse by ≥ 0 (ties inside 0.05 count as "not worse") | some k < 10 beats 10 by > 0.05 |
| **B3** | over k = 7 … 10 (attachments at and below the crossover) `mean|z|_free` is non-increasing | an increase > 0.05 between consecutive k |
| **B4** | every arm SOLVES — no ceiling at `tau_q` = 538 | an arm with no `kz` holding the deep |
| **B5** | HD, read ACROSS the scan, moves mostly with `kz` — its range across the scan is explained by `kz` to within the 3:1 ratio 09-05f measured | HD moves > 5 ‰ between two arms whose `kz` differ < 10 % |

⚠ B2 failing is not a disaster, it is the finding that the boundary is a real question. It would
then be Marcus's call, from physics, not from the argmin.

## 4. PART C — THE PIN AT THE OBSERVATION

Three arms, each with `kz` solved to hold the bottom box at **−175.3** (the sourced target):
**incumbent** (32 boxes, `hs_frac` 0), **attach 1** (HILDA, depth-independent), **attach 10** (bottom).
Report `kz`, whether it sits inside the shipped `kz` bracket, the full profile with per-layer z,
both statistics, HS/HD/LS-ml, and the pinned layer's residual z (target −175.3 vs the binned
−177.6 ± 11.6 ⇒ **+0.20 by construction**, the same in every arm).

### Quantitative pre-check, from already-measured numbers

At `ent26` (`kz` 6356, 32 boxes) the deficits below the LS mixed layer (−29.3) are 105 / 119 / 127 ‰
at 1622 / 2268 / 3172 m. A diffusive deficit scales ≈ 1/`kz` to first order. Pinning the bottom to
−175.3 needs a deficit of 146 ⇒ ×1.15 ⇒ `kz` ≈ **5500**, and the free layers land at ≈ −150 (z
**+1.1**) and ≈ −166 (z **+0.7**). The 09-05f off-control row (attach 10, `kz` 1900) read
−162.1 / −180.9 / −171.7 (z +0.23 / −0.39 / −0.51). So:

| | prediction | falsifier |
|---|---|---|
| **C1** | the incumbent solves at `kz` in **[4800, 6200]** and INSIDE the bracket | outside |
| **C2** | the incumbent's 1622 m layer stays too young: z(1622) **> +1** — the pure column's SHAPE is too steep, not only its level | z(1622) ≤ +1 |
| **C3** | ⭐ **attach 10 puts EVERY scored layer inside \|z\| < 1** — DESIGN §3.4a's benchmark, met for the first time in this arc, on this control | any scored layer outside |
| **C4** | attach 10 solves at `kz` in **[1500, 2300]**, OUTSIDE the shipped bracket — which was bisected for the 32-box column and is structure-specific by construction | inside the bracket, or outside [1500, 2300] |
| **C5** | attach 1 (HILDA) does NOT reach C3: `q` injects HD water directly at 1622 m, which stays too young (z > +1), and its `kz` is driven below attach 10's | attach 1 reaches all-inside |

⚠ C3 is the headline and the one I most want to be true — said out loud. Its falsifier is a single
layer outside, and the 2268 m layer at `kz` 1900 was already at −0.39, so the margin is real but not
large. If C3 fails the structure cannot match the observed deep profile even with `kz` free, and
the arc's remaining candidate is the boundary (B), not more `kz`.

## 5. PART D — THE TWO-TIMESCALE TEST (transient, matched parameters, NO refit)

Four transient runs, 1750–2024, every parameter at `ent26` except `kz` and the structure:

| run | structure | `kz` |
|---|---|---|
| **R0** | incumbent, 32 boxes | 6356 (its own) — the reference, recomputed |
| **R1** | incumbent | obs-pinned (from C) |
| **R2** | attach 10 | obs-pinned (from C) |
| **R3** | attach 1 | obs-pinned (from C) |

Report per-stream log-likelihood (`dg_streams`), gate 5 (NH bomb peak year, e-fold), gate 7
(2015–2023 ocean sink vs GCB), and the min `sst_hs` reached in the run (the Lueker validity floor
is 2 °C and the HS box carries the hemisphere's anomaly; if the run dips below it, the dip is
reported as an EXTRAPOLATION, not hidden).

Define the **decadal ocean set** = `d14c_NH` + `d14c_SH` + `gcb_ocean_sink`, and the **deep term** =
`d14c_deep_ocean`.

| | prediction | falsifier |
|---|---|---|
| **D1** | R1 (pure column, deep right) LOSES on the decadal set by MORE than it gains on the deep term (≈ +1.7 = ½(1.85² − 0.2²)) — the two-timescale tension, priced | the decadal set loses less than the deep gains |
| **D2** | ⭐ **R2 keeps more of the decadal set than R1 does**: ΔlogL(decadal, R2 − R0) > ΔlogL(decadal, R1 − R0) by > 1 log-unit — the cold box carries decadal uptake the low-latitude `kz` no longer does | R2 loses as much as, or more than, R1 |
| **D3** | R2's gate 7 sink is INSIDE gate 7's bound (the objective's own sigma) | outside |
| **D4** | R2's gate 5 NH peak is no LATER than R0's (+2.17σ at `ent26`) — HS uptake sharpens the bomb peak | later |
| **D5** | the land/seasonal streams (`co2_seasonal_*`, `d13c_seasonal_*`, `gcb_land_sink`) move by < 2 log-units in every run — the structure is an ocean change; anything larger is an atmosphere-mediated side effect to report | ≥ 2 on any |

⚠ D2 is HILDA's mechanism and the prediction I am least sure of: `k_w`, `bomb_total`, `pump_grad`
and `h_ml` are all `ent26` values fitted for a 32-box column, so the structure is being tested with
someone else's nuisances. **A D2 pass under those conditions is strong; a D2 fail is not decisive
and points at the refit.** Pre-check: bomb penetration in the LS column scales as √`kz`, so at
`kz` ≈ 1800 the LS takes ≈ 0.53× the bomb ¹⁴C per unit area it took at 6356; the HS box over 16 % of
area is flushed at 38/75 ≈ 0.5 yr⁻¹ into a reservoir ~50× its own volume, so its uptake is
gas-exchange-limited and does not saturate. Whether 16 % of unsaturating area outweighs a 47 % cut
over 84 % is exactly what D2 measures; the arithmetic does not settle it.

## 6. SCOPE, AND WHAT THIS IS NOT

- **Nothing adopted, nothing fitted, nothing refit.** `hs_frac = 0` ships. Every number is at
  `ent26`'s 26 parameters, which were fitted with 32 boxes.
- **Part C's control is NOT a replacement for iso-deep.** Both are printed on every arm. Iso-deep
  keeps the arc comparable; obs-pinned asks the question the user's goal actually asks.
- ⛔ **B is reported whole and its argmin is not a decision.** If B2 fails, the boundary goes to
  Marcus as a physics question with the scan attached.
- ⛔ **D is matched-parameter, not a refit.** It bounds what the structure can do with the
  incumbent's nuisances; it cannot say what a refit would find. A pass here is a reason to refit;
  a fail here is a reason to refit too — the difference is the prior on the outcome.
- The carbonate formulation at `sst_hs` = 2 °C in a transient is the Lueker floor; the minimum
  reached is printed and any excursion below 2 °C is labeled an extrapolation.
