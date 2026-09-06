# DESIGN FOR A RULING — 2026-09-07. **THE REFIT WITH HILDA'S STRUCTURE: what is declared, what is fitted, what the objective must first learn to see.**

Not yet a pre-registration of a run: a design put to Marcus, because every choice below is a
methodological one ([[handoff_open_item_is_not_a_ruling]]). It follows
`collect_2026-09-06c_structure_identifiability.md` §6–§8 and Marcus's 2026-09-06 priority: *"use
observations and known physical laws to constrain the model's behavior; document what comes from
HILDA as caveats."*

## 1. What the observations now say, in one paragraph

The interior Δ¹⁴C profile is flat below 2000 m (B − deep = −0.4 ± 4 ‰, a measured contrast). A
diffusive column cannot produce that at any `K` (bottom oldest, +4σ); a conduit attached at the
bottom cannot either (mid-depth minimum, −3 to −5σ); high-latitude water entering the interior at
every depth can, and does at HILDA's own `z_K` with a deep `K` of 300–600 m²/yr once the cold box
exchanges at 0.7–0.8 of the low-latitude rate. The modern sink is a thermocline quantity that the
`K(z)` anchor preserves. The bomb curves support the cold box's exchange factor directly. **The
structure is forced by observations; only three of its numbers are HILDA's.**

## 2. Step 0 — objective change #9: let the objective see the contrast (BEFORE any fit)

Replace the three independent interior rows (`d14c_mid_1500_2000`, `d14c_mid_2000_2627`,
`d14c_deep_ocean`) by **one multivariate-normal row on the (A, B, deep) vector with the measured
3×3 covariance** from `diag_d14c_profile_covariance.R`. This is not a new observation and not a
re-weighting: it is the same three means with the sampling correlation the independent form
discards. Choice for Marcus: the **60° block** covariance (conservative; contrast se 4.0) or the
30° (3.5). The level variances would then come from the same bootstrap (13.5–16.4 at 60°) rather
than sd_w/√20 (13.5 / 13.6 / 10.3) — near-identical, so the levels' weight barely moves while the
contrast gains a factor ~3–4 in precision. Mutation test: the bottom-attached arm must lose ≥ 9
log-units on the row (its −5σ contrast) relative to the independent form.

## 3. What is DECLARED, and from what

| parameter | value | from | caveat? |
|---|---|---|---|
| attachment `q_attach_from` | **1 — every layer** | the measured contrast (observation) | no |
| `hs_frac` | 0.16 | area with SST < 5 °C (observation; the 5 °C cut is HILDA's convention) | convention noted |
| `sst_hs` | 2 °C | the box's annual mean; the chemistry's validity floor | no |
| `z_K` (`kz_zscale`) | 253 m | HILDA Table 1 (one remove; weakly identified, sd 1.8) | **yes** + sensitivity scan {150, 253, 500} reported whole |
| `u_hs` | 38 m/yr | HILDA Table 1 (one remove; degenerate with the exchange factor) | **yes** + scan {19, 38, 76} |
| `tau_q` | 538 yr | HILDA Table 1 (one remove; a free fit removes the conduit through it) | **yes** + scan {269, 538, 1076} |
| `h_hs` | follows `h_ml` | 09-06c: weakly identified (sd 0.36); freeing it buys little | no; note the transient power |

## 4. What is FITTED (the count: two structural, plus the nuisances that trade with them)

- **`kz_deep_frac`** (f), log scale, box (0.005, 1]; no prior — the deep row and the contrast pin
  it (0.05–0.10 at HILDA's attachment). ⚠ f = 1 is the uniform model; the fit reaching it would
  mean the structure is not wanted, which is a result, not a failure.
- **`hs_asx_frac`**, log scale, box [0.2, 2]; no prior — supported by the bomb rows at sd ≤ 0.10.
  ⚠ OWED as a cross-check, not a prior: the annual open-water fraction over the HS area from a
  sea-ice product (a `data-raw/` download script). If it disagrees with the fitted value by > 2 sd,
  that is the finding.
- The existing 26, with **the `kz` bracket RE-BISECTED on the 36-box structure** by the same
  recipe as 2026-09-01 (default parameters, sourced GLODAP target, k = 3σ) — [4379, 8110] was
  bisected for the column and is meaningless here (the deep is now K_deep's, not `kz`'s).
  Everything else unchanged, priors unchanged.

## 5. Where and how

- **Torch**, the 26-par refit's harness (46 dispersed starts, `run_modefind_pump_arms.R` lineage),
  structure ON in `base_params`. Say the verdict: the local conditional optima took 3–4 min per
  ten-parameter L-BFGS-B; a 28-parameter multistart with polish is the hours-scale job the laptop
  should not carry ([[consider_torch_first]]).
- Comparison baseline: `ent26` re-scored under objective #9 (a likelihood, stream by stream — a
  logpost across #8 and #9 is not comparable).
- Gates, all mutation-tested before launch: P0 identity at f = 1 / `hs_frac` 0; the contrast row
  fires on the bottom arm; the MVN row reduces to the three Gaussians when the covariance is
  diagonal.

## 6. Predictions to register once the design is ruled (drafted, not yet binding)

| | prediction |
|---|---|
| R1 | the mode keeps the structure: f < 0.3 and `hs_asx_frac` in [0.5, 0.9] |
| R2 | the (A, B, deep) row sits inside 1σ on all three levels AND the contrast |
| R3 | the modern sink and the bomb curves are within 2 log-units each of `ent26`'s |
| R4 | the pump-δ¹³C gradient row recovers to within 5 of `ent26` (nuisances, as in every conditional optimum) |
| R5 | the likelihood beats `ent26`'s under objective #9 by more than the contrast row's own gain |
| R6 | the `kz` bracket re-bisection lands `kz` INTERIOR (not on a bound) |

## 7. The questions that are Marcus's

1. Objective #9 as in §2 — yes, and which block size.
2. `z_K`, `u_hs`, `tau_q` declared at HILDA's values with caveats and scans (§3) — or one of them freed.
3. `h_hs` declared (follow `h_ml`) — or freed given its transient power.
4. The sea-ice pin for `hs_asx_frac`: cross-check (recommended) or prior.
5. Launch on Torch with the 46-start harness.

## 8. ADDENDUM 2026-09-06d — the numbers the design asked for (nothing ruled; see CHANGELOG 09-06d)

- **§4's sea-ice cross-check is DONE and it passes**: the observation-and-law factor is **0.653**
  (`data/obs_hs_exchange_factor.rds`; ice × wind 1.064, Schmidt 0.549), within 1 sd of the fitted
  0.74 ± 0.10. ⚠ Open-water fraction ALONE (this section's original statistic) is 0.651 by two
  cancelling omissions; the full factor is the one to quote. Question 4 can be answered either way
  on the same number: as a cross-check it passes; as a prior it would be N(0.65, ~0.05) with the
  window spread as the width. `hs_frac` is now measured (0.160) rather than HILDA's.
- **§3's scans are DONE** (`calibration/diag_declared_param_scans.R`): every declared parameter's
  window is ONE-SIDED — `z_K` 500, `u_hs` 76 and `tau_q` 269 leave no deep floor that holds the deep;
  the other direction costs 223 / 517 on the transient (`z_K` 150 / `u_hs` 19) or GAINS 93 while
  failing the contrast at +4.3σ (`tau_q` 1076). The last is the case for doing §2 before the refit.
- **§2 is BUILT and ships OFF** (`LIK_USE_D14C_PROFILE_MVN`, block 60): the mutation gate passes on
  the arm it was written for (K(z)+bottom, extra loss 25.4 ≥ 9) and not on the uniform-`kz` bottom pin
  (2.8; its contrast is −2.9σ). The gate line should read "the K(z)+bottom arm"; the ≥ 9 stands.
