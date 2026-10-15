# COLLECT — 2026-09-06c. **HOW MANY CAN WE AFFORD? ONE THROUGH THE BOMB ROWS (THE HS EXCHANGE), NONE THROUGH THE PROFILE — BECAUSE THE PROFILE IS A TEN-LOG-UNIT VOTE AGAINST HUNDREDS, AND ITS n_eff IS MEASURED AND RIGHT.**
# **⛔ Every free fit removes the structure: the free run switched the conduit off, the declared-conduit run switched K(z) off, and both left the intermediate slabs 2–3σ too young.**
# **⭐ `hs_asx_frac` is data-supported (0.65–0.74, marginal sd ≤ 0.10) through the bomb curves; `h_hs` has power in the transient, contrary to 09-05b's steady-state "no lever".**
# **⚠ Two of my pre-registered predictions failed for reasons worth more than the passes: the Hessian at a non-optimum is not a count, and the slabs' n_eff is 21 / 20, not "> 2× different".**

Scores `notes/prereg_2026-09-06c_structure_identifiability.md` §3 (the original six), §5 (I7–I10),
§6 (I11–I14), §7 (I15–I18, the price — §5 below). Scripts `calibration/diag_structure_identifiability.R`,
`diag_structure_conditional_optimum.R`, `diag_structure_declared_optimum.R`, `diag_mid_d14c_neff.R`,
`diag_structure_profile_price.R`; logs in `outputs/diagnostics/*20260906*`. **Nothing adopted.**
Objective throughout = the likelihood under objective change #8 (the two intermediate rows in), no priors.

---

## 0. THE FOUR RUNS IN ONE TABLE

| run | free | logL (true) | vs `ent26` (−1431.3) | slabs z (A / B) | deep z | conduit | `K(z)` floor f | `hs_asx_frac` |
|---|---|---|---|---|---|---|---|---|
| working arm (09-06b) | 0 | −1883.5 | −452 | −0.26 / −1.49 | +0.20 | on (38 / 538) | 0.166 | 1 |
| **1. Hessian at the arm** | — | — | — | — | — | — | — | — |
| **2. free optimum** | 10 | **−1430.5** | **+0.8** | **+2.13 / +0.96** | −0.7 | **OFF** (`tau_q` 5000 bound, `u_hs` 9.8) | 0.43 | 0.65 |
| **3. conduit declared** | 7 | −1467.5 | −36 | **+2.95 / +2.35** | +2.4 | on (declared) | **1.00 (bound = uniform)** | 0.74 |
| `ent26` itself | — | −1431.3 | — | +3.16 / +2.56 | +1.85 | none | 1 | — |

⇒ **Given the freedom, the likelihood walks to the incumbent's over-ventilated column every time**,
by whichever route is open: `K(z)` floor + conduit off (run 2: `kz` 8821, `h_ml` 196), or uniform `K`
+ conduit on (run 3: `kz` 3786, `h_ml` 202). The intermediate profile is the casualty in both. The
gains come from the bomb rows (`d14c_SH` +115), the pump's δ¹³C gradient (+167 to +193) and
`d13c_level_SPO` (+59 to +62) — the three matched-parameter losses of 09-06b, all recoverable by
nuisances, which is what the fit did.

## 1. RUN 1 — THE HESSIAN AT THE ARM IS NOT A COUNT (I1–I6 as pre-registered: 3 pass, 3 fail, none decisive)

−H had **four negative eigenvalues** (−13 … −430); gradients **−3460** (`k_w`), **+6114**
(`bomb_total`), **−1025** (`hs_asx_frac`) per log-unit. Conditional sds 0.003–0.14 everywhere;
marginals 1–2.4 off a regularized matrix, driven by trades: `hs_asx_frac`–`k_w` **r −0.97**,
`hs_asx_frac`–`u_hs` −0.94, `u_hs`–`k_w` +0.84, f–`z_K` −0.74. **I1 failed for a good reason:**
`h_hs` moves `d14c_SH` by 16 log-units at ±0.5 — the cold box's bomb capacity before it flushes to
HD scales with thickness; 09-05b's "not a term" was a steady-state result I over-generalized.
⇒ [[hessian_at_non_optimum_is_not_a_count]].

## 2. RUN 2 — THE FREE OPTIMUM REMOVES THE CONDUIT (I7–I10)

L-BFGS-B, 76 iterations, 3.6 min; +453 log-units, the whole gap. **I7 ✅** (trivially), **I8 ✅**
(`hs_asx_frac` 0.646), **I9 ✅** (`k_w` ×0.97, `bomb_total` ×1.001), **I10 ⛔** (still indefinite on the
`h_ml`/`kz`/`h_hs` ridge, eigenvalues −42 and −5.5 — the ridge [[ccx_hessian_is_the_blocker]] knows).
Where it went: `tau_q` → **5000 (upper bound)**, `u_hs` → 9.8, f → 0.43 (K_deep 3810), `kz` → 8821,
`h_ml` → 196. **That is candidate A alone** — DESIGN §3.4a's "K(z) fixes the deep age" — rediscovered
by the optimizer, with the deep at −183 and the intermediate abandoned.

## 3. RUN 3 — THE DECLARED CONDUIT REMOVES `K(z)` INSTEAD (I11–I13)

Conduit held at HILDA (`u_hs` 38, `tau_q` 538, `z_K` 253, bottom); free {f, `hs_asx_frac`, `h_hs`,
`kz`, `k_w`, `bomb_total`, `h_ml`}. Gap −36. **f → 1.000, the UPPER bound = uniform `K`**; `kz` →
3786, `h_ml` → 202. Slabs **+2.95 / +2.35**, deep +2.4 — worse than `ent26` on the profile. **I11 ⛔,
I12 ✅ (−36), I13 ⛔** (f on the bound). ⚠ The printed "3 of 3 DATA-SUPPORTED" is an artifact for f:
a parameter on a bound has a fake 4e12 curvature. For `hs_asx_frac` (0.736, msd **0.096**) and
`h_hs` (122 m, msd 0.36) the support is real, −H is PD (I10 ✅ here), and the L-BFGS-B line-search
abort (code 52) is at the bound, not before it.

## 4. THE n_eff MEASUREMENT (I14 ⛔ — and the failure is the good news)

`diag_mid_d14c_neff.R`, the deep script's four admissible estimators on each slab's own cells, gate
reproducing the deep set to 4 %: **slab A median 21.1** (6.6 / 14.8 / 27.5 / 110.4), **slab B 20.0**
(6.1 / 14.0 / 26.1 / 86.5). The reused 20 was right. The 15× bracket (floor vs empirical) is the
same residual ambiguity as for the deep — sampled structure vs exchangeable water masses — and the
median is the convention Marcus chose on 2026-08-14/16. ⇒ **The rows' weight is not the problem to
fix; it is the measurement.**

## 5. THE PRICE IS ZERO — AND THAT IS THE PROBLEM (I15 ✅, I16 ✅, I17 ⛔, I18 ✅)

Iso-fit frontier on the slabs' weight (W = 3, 10, 30 as a device; every point re-scored under the
TRUE objective):

| W | logL true | vs `ent26` | slabs z A / B | deep z | f | `z_K` | `u_hs` | `tau_q` | `hs_asx` | `kz` | `h_ml` |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 3 | −1428.9 | **+2.4** | +1.42 / +0.24 | −1.65 | 0.50 | 198 | 13.5 | 5000 (bound) | 0.83 | 7320 | 201 |
| 10 | −1430.9 | +0.3 | **+0.88 / −0.26** | −2.19 | 0.67 | 109 | 19.7 | 5000 | 0.95 | 5395 | 219 |
| 30 | −1431.2 | +0.1 | +0.71 / −0.37 | −2.27 | 1.00 | 52 | 37.0 | 5000 | 0.91 | 3683 | 209 |

**Holding the intermediate profile inside its error bars costs NOTHING** — the frontier sits at
+2.4 / +0.3 / +0.1 against `ent26`. The likelihood is flat along the direction that fixes the
slabs. But **I17 fails**: every frontier point holds the profile with the conduit OFF (`tau_q` at
its bound), a very shallow `K(z)` (`z_K` 50–200 m) and a **200–220 m mixed layer** — the deep mixed
layer counterfeiting near-surface mixing that DESIGN §3.4a A warned of — and the bottom box then
overshoots by 2σ. The payers (I18) are `co2_seasonal_SPO` −5 and the pump rows −2 to −3.
⇒ **Three interior LEVELS at ±13 ‰ cannot distinguish "abyss filled from below" from "sharp K(z)
plus a deep mixed layer". The levels are the wrong statistic.**

## 6. ⭐⭐ THE VERTICAL CONTRAST IS THE OBSERVATION THE LEVELS THROW AWAY (`diag_d14c_profile_covariance.R`)

The three means are built from the SAME 5°×10° columns at different depths, so their sampling
errors are correlated **0.97–0.99** and the contrasts are known far better than the levels. Joint
block bootstrap (the deep n_eff decision's own estimator):

| block | level se A / B / deep | se(A − B) | **se(B − deep)** |
|---|---|---|---|
| 30° | 11.6 / 11.7 / 9.1 | 1.8 | **3.5** |
| 60° | 15.7 / 16.4 / 13.5 | 2.3 | **4.0** |

Observed **B − deep = −0.4 ‰**: the deep profile is FLAT below 2000 m. Every arm of the arc read
against it (60° se; 30° in brackets):

| arm | B | deep | B − deep | **z** |
|---|---|---|---|---|
| `ent26` column | −140.7 | −156.1 | +15.4 | **+3.9** (+4.5) |
| column, obs-pinned `kz` 5267 | −157.1 | −175.3 | +18.2 | **+4.6** (+5.3) |
| **HILDA attachment, obs-pinned** | −169.9 | −175.3 | +5.4 | **+1.4** (+1.6) |
| bottom attachment, obs-pinned | −187.3 | −175.3 | −12.0 | **−2.9** (−3.3) |
| K(z) + bottom conduit (09-06b) | −195.8 | −175.3 | −20.5 | **−5.0** (−5.7) |
| frontier W10 (K(z) + deep ML, conduit off) | −179.1 | −197.9 | +18.8 | **+4.7** (+5.5) |

⇒ **Every column arm and every bottom-attached arm is rejected at 3–5σ; HILDA's depth-independent
attachment is the only structure tested that is inside 2σ.** A diffusive column ages monotonically
(bottom oldest); bottom injection makes a mid-depth minimum (bottom younger by 12–20 ‰); only
high-latitude water entering at EVERY depth holds the whole deep near one age. **The 09-05f
departure from HILDA is reversed by an observation**, not by a score: [[ccx_q_attach_control_dependent]]
said the levels cannot rank the attachments; the contrast ranks them, decisively, HILDA first.

## 7. ⭐ HILDA'S CONFIGURATION SOLVES ONCE THE COLD BOX EXCHANGES MORE SLOWLY — and it is the best arm of the arc

09-06b found HILDA's attachment had no `K(z)` solution because HS was too equilibrated. With
`hs_asx_frac` — the parameter the bomb rows support at 0.65–0.74 — the floor drops:

| `hs_asx_frac` | f | K_deep | slabs A / B | deep | B − deep (z) | slab z A / B | HS / HD |
|---|---|---|---|---|---|---|---|
| 1 | no solution (+4.1 ‰ short) | | | | | | |
| **0.8** | **0.049** | **309** | −161.2 / −172.0 | −175.3 | **+3.2 (+0.9)** | **+0.55 / +0.26** | −94.7 / −121.9 |
| 0.7 | 0.095 | 602 | −155.8 / −169.2 | −175.3 | +6.1 (+1.6) | +0.95 / +0.47 | −98.7 / −123.5 |

**HILDA's geometry, HILDA's `z_K`, a deep `K` bracketing HILDA's 465, and every interior row —
three levels AND the contrast — inside 1σ.** Transient at matched parameters (no refit):

| arm | Δ total vs `ent26` | decadal | CO₂ level | pump δ¹³C | `d13c_level_SPO` | mid rows | sink (z) |
|---|---|---|---|---|---|---|---|
| `hs_asx` 0.8 | −255 | −42 | −68 | **−134** | −6 | +8 | 2.97 (−0.59) |
| `hs_asx` 0.7 | **−193** | −15 | −51 | **−115** | +3 | +8 | 2.98 (−0.55) |

Against the 09-06b bottom arm's −459 and the uniform conduit's −2849. Of the −193, the pump's δ¹³C
gradient is −115 — the matched-parameter artifact the optimizer recovered in every run — so the
structure's true unrecovered cost before a refit is of order **−60 to −80**, mostly CO₂ level and
bomb. That is the arm to refit.

## 8. ⇒ THE ANSWER TO "HOW MANY", AND WHAT IT HANDS TO MARCUS

- **Through the bomb rows: one** — `hs_asx_frac` (0.65–0.8, marginal sd ≤ 0.10 wherever it was
  free), with `h_hs` weakly (sd 0.36). **Through the profile LEVELS: none** — the fit removes
  whichever structure it is allowed to. **Through the profile CONTRAST: the attachment is
  decided** (HILDA's), and with it the deep floor f is pinned to 0.05–0.10 (K_deep 300–600).
- ⇒ **Objective change #9 is indicated and observation-based**: score the three interior levels as
  one multivariate row with the measured covariance (the 60° block, the conservative one), which is
  exactly the contrast information the independent rows discard. Then the refit: attachment and
  `z_K` DECLARED (HILDA, with the caveat), `hs_frac`/`sst_hs`/`h_hs` declared from observation,
  **free f and `hs_asx_frac`** with the nuisances, `u_hs`/`tau_q` declared at HILDA's values under
  a caveat with their sensitivity scanned. Design: `notes/prereg_2026-09-07_hilda_refit_design.md`.

## 9. ⛔ WHAT THIS IS NOT
Nothing adopted; every default ships as before. Four conditional optima and one probe are not a
mode. The contrast row is measured but NOT in the objective. The refit design is a ruling.
