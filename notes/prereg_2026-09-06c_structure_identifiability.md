# PREREG — 2026-09-06c. **HOW MANY OF THE STRUCTURE'S PARAMETERS CAN THE DATA AFFORD?** A curvature check before the refit is designed.

Scores nothing yet. Written before `calibration/diag_structure_identifiability.R` exists.
Marcus 2026-09-06: *"How many of the 5 variables can we afford to free? … the priority is to use
observations and known physical laws to constrain the model's behavior."*

**Objective:** the LIKELIHOOD (no priors), as shipped after objective change #8 — the 21 existing
streams plus the two intermediate GLODAP slabs (`d14c_mid_1500_2000`, `d14c_mid_2000_2627`) and the
deep row. **Base point:** the 09-06b working arm — `ent26`, HS at HILDA's values, `q` at the bottom,
`K(z)` with `z_K` 253 and f = 0.166, `hs_asx_frac` 1, `h_hs` set explicitly to `h_ml` (134.15) so it
can be varied. ⚠ Not an optimum of this objective; curvature at a non-optimum carries a
gradient term, so the check is a LOCAL statement about the data's leverage, not a posterior.

## 1. THE PARAMETERS, on the log scale

| candidate (new) | centre | prior width available (log) | source of the width |
|---|---|---|---|
| `kz_deep_frac` (f) | 0.166 | none | — |
| `kz_zscale` (z_K) | 253 m | none | HILDA's value, one remove |
| `u_hs` | 38 m/yr | 0.45 (38 ± 17) | HILDA Table 1, one remove |
| `tau_q` | 538 yr | 0.95 (538 ± 510) | HILDA Table 1, one remove |
| `hs_asx_frac` | 1 | none | — |
| `h_hs` | 134.15 m | none | expected FLAT (09-05b: both HS timescales carry 1/`h_hs`) |
| coupled (existing) | `kz` 6356, `k_w` 1788, `bomb_total` 118.3, `h_ml` 134.15 | — | the four most likely to trade against the new ones |

## 2. METHOD

Central-difference Hessian of the log-likelihood in the ten log-parameters, step 0.05 in log
(≈ 5 %), the four off-diagonal evaluations per pair; diagonal step-stability at 0.025 and 0.1 for
the six new parameters. Report: the conditional sd `1/√(−H_ii)`, the marginal sd `√(−H⁻¹)_ii`
(when −H is positive definite; otherwise the eigen-decomposition and the non-positive directions
are reported and no marginal sd is quoted), the correlation matrix, and the eigenvectors of the
two softest directions. Mutation: each parameter moved by ±0.5 in log must move at least one
stream by ≥ 2 log-units, or it is declared to have no power at this point.

**The affordability criterion, declared now.** A new parameter is DATA-SUPPORTED if its marginal
sd on the log scale is **< 0.5** (the data pin it to better than a factor 1.65) **and** below its
one-remove prior width where one exists. The count of data-supported parameters is the answer to
"how many can we afford"; the rest are declared, with a caveat.

## 3. PREDICTIONS

| | prediction | falsifier |
|---|---|---|
| **I1** | `h_hs` has NO power: mutation < 2 log-units on every stream, conditional sd > 2 | it moves a stream |
| **I2** | ⭐ `kz_deep_frac` and `hs_asx_frac` are data-supported (marginal sd < 0.5) | either is not |
| **I3** | `u_hs` and `tau_q` are NOT separately supported: their marginal sds exceed their HILDA widths, and the softest eigenvector of the new-parameter block is dominated by a `u_hs`/`tau_q`/`hs_asx_frac` combination | both inside their widths |
| **I4** | `kz_zscale` is weakly supported: marginal sd between 0.5 and 2 | outside that range either way |
| **I5** | the strongest cross-coupling of a new parameter is with `k_w` or `bomb_total` (the bomb-curve channel), |r| > 0.5 | strongest coupling is with `kz` or `h_ml` |
| **I6** | the diagonal curvatures of the six new parameters are step-stable: the 0.025 / 0.05 / 0.1 estimates agree within 25 % | one is not |

⇒ **The expected answer is TWO** (f and `hs_asx_frac`), with `z_K`, `u_hs`, `tau_q` declared at
HILDA's values under a caveat and `h_hs` not a parameter at all. If I2 fails the refit design
changes; if I3 fails, three may be affordable.

## 4. SCOPE
Nothing adopted or fitted. Matched parameters; a local curvature only. The observational pin for
`hs_asx_frac` (annual open-water fraction over the HS area) is owed separately and is not part of
this check.

---

## 5. AMENDMENT — written after the first run, before the second (2026-09-06)

**What the first run found** (`outputs/diagnostics/diag_structure_identifiability_20260906.log`):
the Hessian at the working arm is **indefinite** — four directions of positive logL curvature —
because the point is far from an optimum of this objective: gradients of **−3460 (`k_w`)**,
**+6114 (`bomb_total`)**, **−1025 (`hs_asx_frac`)** per log-unit. Conditional sds are tiny in every
direction (0.003–0.14; `tau_q` alone is convex); the marginals, taken off a regularised matrix, are
inflated by near-perfect trades — `hs_asx_frac` vs `k_w` **r −0.97**, vs `u_hs` **−0.94**,
`u_hs` vs `k_w` +0.84, f vs `z_K` −0.74. **Marginal sds off an indefinite matrix are not a count**,
so I1–I6 as scored there are not the answer; §2's caveat ("a local statement about the data's
leverage") became the finding. Two things did land: **`h_hs` HAS power in the transient** (16 log-units
on `d14c_SH`; the 09-05b "no lever" was a STEADY-STATE result and I over-generalised it in §3), and
the coupling structure above is real (I3, I5 pass on any reading).

**The second run** re-scores the same six predictions **at the conditional optimum** of the same ten
log-parameters — the likelihood maximised with everything else at `ent26`, no priors, box bounds
only to keep values physical (f ≤ 1; z_K 50–3000 m; `u_hs` 1–400; `tau_q` 30–5000; `hs_asx_frac`
0.05–5; `h_hs` 20–500; `kz` 500–20000; `k_w` 300–6000; `bomb_total` 60–200; `h_ml` 30–300), L-BFGS-B
with a 0.01 log gradient step. Any parameter on a bound is reported as such. The Hessian is then
recomputed there exactly as in §2. Nothing adopted; a conditional optimum of ten parameters with
sixteen held is not a mode.

Added predictions:

| | prediction | falsifier |
|---|---|---|
| **I7** | the conditional optimum closes **more than half** of the working arm's gap to `ent26` under objective #8 (−1883.5 vs −1431.3, gap −452) | it closes less |
| **I8** | `hs_asx_frac` lands **below 1** — the direction both 09-06b residuals (the deep floor, the bomb curve) and the gradient (−1025) point | ≥ 1 |
| **I9** | `k_w` falls and `bomb_total` rises from `ent26`'s values (their gradients' signs) | either moves the other way |
| **I10** | at the optimum −H is positive definite, so the marginal sds are a count | not PD |
