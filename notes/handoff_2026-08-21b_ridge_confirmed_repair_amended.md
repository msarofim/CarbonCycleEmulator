# Handoff — CarbonCycleEmulator, 2026-08-21b: §2's ridge is exact, §3 was a false alarm, and the refit's answer was computed instead of run

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `7b7f3b6`.
**Predecessor:** `handoff_2026-08-21_refit_landed_next_three.md`. This file supersedes its
§§2–3. Its §4 (`sst_seas_amp_NH`) is **untouched and still the open item**.

---

## 0. STATE IN EIGHT LINES

1. **§2's ridge claim is CONFIRMED, exactly.** `seas_T_amp_NH` × ln(`q10`) is conserved to
   0.2 % across a 2.5× range of `q10`; the re-optimised `A_T` at `q10` = 2.0 is 3.2695 K
   against the analytic 2.2513/ln 2 = 3.2479.
2. **§2's DIAGNOSIS is half right and its SUCCESS CRITERION is not reachable.** Damping both
   land amplitude priors by 0.2838 flips `q10` = 2.0 from losing by 63.7 log-units to
   winning by 4.0 — but the interior optimum lands at **`q10` ≈ 1.35–1.5**, not 2.0.
3. **§3 is CLOSED and the blocker was a false alarm.** Recomputed with a validated
   per-parameter step: `log|−H|` 127.0986 vs 127.1280 stored, `h_ml`'s sd moves 2 %,
   everything else < 0.5 %. **The uncertainties were quotable all along.**
4. **`q10` is NOT determined to ±0.019.** That Laplace marginal is local; the profile shows
   `beta_max`/`fert_k` absorb **85 %** of the cost of raising `q10`.
5. **`prior_z()` was wrong by up to 1.3 sd** and had already mis-ranked this work.
   `seas_T_amp_NH` (+2.65) and `bomb_total` (+1.81) come OFF the |z| > 3 flag list.
6. **Two latent bugs fixed**, both caught by gates: a double-applied `luc_scale` in the
   diagnostic LUC idiom, and `recompute_hessian.R` overwriting the mode file in place.
7. **§4 is now the top item** — `sst_seas_amp_NH` at −6.27 σ (was −5.97; the correction made
   it worse), untouched by any of the above.
8. Still no posterior. Nothing here changes that.

---

## 1. WHAT WAS RUN, AND WHERE IT LIVES

| script | what it answers | output |
|---|---|---|
| `calibration/diag_seas_T_amp_q10_ridge.R` | the (`A_T`, `q10`) ridge, both axes, four tiers, two objectives | `output/seas_T_amp_q10_ridge_*.rds` + `.log` |
| `calibration/diag_seas_reanchor_arithmetic.R` | what a re-anchored prior set would do, **without a refit** | prints |
| `calibration/recompute_hessian.R` (rewritten) | the second-order block, per-parameter step | `output/pump_arms/mode_fit_pumpN_hess.rds` |
| `R/calibrate.R::ccx_prior_z` + `tests/testthat/test-prior-z.R` | prior-tail position, correctly | — |

`mode_fit_pumpN.rds` is **NOT modified**. The recomputed second-order block sits beside it;
`--update` is required to write it back, and it has not been passed.

---

## 2. §2 — THE RIDGE IS REAL AND THE REPAIR NEEDS AMENDING

### 2a. The falsification test passes

`Rscript calibration/diag_seas_T_amp_q10_ridge.R q10 partial pairSH,land <grid> partial`

PAIRSH tier (`seas_T_amp_NH` + `seas_T_amp_SH` free — q10 is SHARED between hemispheres, so
freezing the SH breaks its own product by construction):

| `q10` | `A_T` (K) | product | Δ(seas4) | Δ(rest) |
|---|---|---|---|---|
| 1.0907 (mode) | 26.04 | 2.2609 | 0.0 | 0.0 |
| 1.2174 | 11.51 | 2.2635 | −2.3 | −13.3 |
| 1.5 | 5.59 | 2.2652 | −3.8 | −100.4 |
| 2.0 | 3.27 | 2.2663 | −4.3 | −352.1 |

**The four seasonal rows move 4.3 log-units across the whole range.** They do not identify
`q10`. The Hessian agrees independently: **cor(`q10`, `seas_T_amp_NH`) = −0.972** — strong,
and NOT degenerate (a pure product ridge would be −0.999 or tighter).

### 2b. Two things I got wrong on the way, both worth not repeating

**The 352 is a FROZEN-BLOCK number.** BLOCK freezes `beta_max`, `fert_k`, `luc_scale`, and
β–γ compensation is exactly the repair it forbids. Freeing them (`land` tier) drops the cost
of `q10` = 2.0 to **50.3**. `match_incumbents_optim`, applied to myself.

**A pure-likelihood objective lets the NUISANCE parameters escape.** The first `land` run
put `seas_T_amp_SH` at 1e-23 and `sst_seas_amp_NH` at 1e-31 in every row — both channels
off, z = −37.5 apiece — and reported 15.9. Internally consistent, and a profile of a
DIFFERENT MODEL. The objective is now `partial`: drop the priors on the two parameters
UNDER TEST, keep every other one. **GATE 3 prints which are dropped and which kept.** Use
`partial` (the default); `lik` exists only to reproduce the first pass.

### 2c. The refit's answer, computed

`diag_seas_reanchor_arithmetic.R` re-scores the `land` points under a re-anchored prior set.
No model runs — the parameter vectors are already on disk.

| `q10` | `A_T` (K) | `seas_T_amp_SH` | Δ logpost NOW | Δ logpost DAMPED |
|---|---|---|---|---|
| 1.0907 | 26.49 | 1.31 | 0.00 | 0.00 |
| 1.15 | 16.58 | 0.96 | −2.7 | +12.4 |
| **1.35** | **7.81** | 0.55 | −20.2 | **+19.7** |
| 1.50 | 5.86 | 0.45 | −31.2 | +18.1 |
| 1.70 | 4.46 | 0.37 | −45.9 | +12.5 |
| 2.00 | 3.45 | 0.28 | **−63.7** | +4.0 |

Damping applied to **both** priors (NH centre 14.32 → 4.06 K, SH 5.05 → 1.43 K; the bracket
ends scale, so the centre scales and the width does not).

**Read it as: the repair has leverage, and it does not reach its own success criterion.**
The sign flips; the landing is `q10` ≈ 1.35–1.5, not 2.0. And **the decisive lever is the
SH prior as much as the NH one** — `seas_T_amp_SH` must fall to 0.28 K to hold the SH
product at a large `q10`, and that is where most of the 50.3 sits. §2 as written only
proposed re-anchoring on the NH argument.

**Two caveats, and they matter.** The damping 0.2838 is **DERIVED** to put the mode's
product at the literature `q10` — the most favourable value the hypothesis could have, and
not a measurement. §2 step 2's requirement for provenance stands and is now the gate on the
whole thing. And the `land` points were optimised under the CURRENT priors, so the damped
column is a **lower bound** on what a refit would find.

### 2d. What to do

1. **Get a damping factor with provenance first.** A measured soil-temperature seasonal
   climatology, at a respiration-weighted depth. **If it comes back far from 0.28, that is
   the falsification and the refit should not be run at all.**
2. If it is near 0.28: re-anchor **both** land amplitude priors, keeping the bracket-derived
   widths, and refit (~15 h, warm-started).
3. **Pre-register the criterion as `q10` → 1.35–1.5, `A_T` → 6–8 K.** Not "q10 back near
   2.0" — the table above already says that will not happen.

---

## 3. §3 — CLOSED, AND SMALLER THAN IT LOOKED

`recompute_hessian.R` needed three repairs before it could answer anything: it read
`md$u_mode` and decoded it under the DEFAULT table (band-dependent — `mode_fit_pumpN.rds`
does round-trip, and GATE 1 now prints both rather than assuming); it **wrote its result
back over the mode file**; and its step grid stopped at 3e-4, which is where `h_ml`'s
problem starts.

**The step is now DERIVED:** `eps_k = 0.1 × sd_k`, each direction's own posterior width, so
the objective moves 0.005 log-units in EVERY direction by construction — ~5,000× above this
integrator's noise floor, truncation error ~0.25 %. All 21 parameters stable to < 1 % across
eps/3 → 3·eps.

**A rule I tried first and rejected, recorded so it is not retried:** "largest step whose
diagonal curvature is stable" chose eps = 1e-1 for nearly everything — 313 log-units for
`beta_max` — and produced a Hessian with a **positive** eigenvalue of +86.8 in the
(`beta_max`, `fert_k`) plane, whose correlation is **+0.997**. A diagonal-only stability
scan cannot see a cross-derivative going bad.

**The cause is not the one §3 proposed.** 3e-4 is 0.5–1.8× the right step for the seven
STIFF directions and 0.003–0.06× for the soft ones: it was calibrated on the stiff subspace.
`h_ml` is simply the SOFTEST direction (unconstrained sd 0.888), so 3e-4 is 296× too small
there. **`kz` was under-stepped 181× and `gamma_enso` 66×, neither near a bound and neither
flagged** — the instability report was UNDER-reporting, not over-reporting. The
logit-compression story is true about REACH and wrong about CAUSE.

**And it barely mattered:** `log|−H|` 127.0986 vs 127.1280; `h_ml` sd +2 %; everything else
< 0.5 %; −H positive-definite. **"NO UNCERTAINTIES ARE QUOTABLE" was over-cautious** — the
right call on the evidence then, but they were usable all along. What the work buys is that
they are verified, the step is recorded, and the flag would now catch something real.

---

## 4. THE PRIOR-TAIL SCREEN WAS WRONG, AND IT HAD RANKED THIS WORK

Both mode-finders built the prior CDF on `seq(x/1e3, x*1e3, length.out = 4001)` — a LINEAR
grid. For `seas_T_amp_NH` at x = 25.94 that is 0.026 → 25,937 in 6.5 K steps against a prior
whose ±1 σ spans 11.4–17.9 K: **one grid point inside the entire prior.**

| parameter | reported | correct |
|---|---|---|
| `seas_T_amp_NH` | +3.29 | **+2.65** |
| `bomb_total` | +3.08 | **+1.81** |
| `q10` | −2.01 | **−2.43** |
| `rep_dC` | +5.75 | **+5.18** |
| `seas_T_amp_SH` | −3.71 | **−3.99** |
| `sst_seas_amp_NH` | −5.97 | **−6.27** |

The |z| > 3 list loses two of six. §2's headline pair was also mixing a file value with an
analytic one; the honest pair is **+2.65 / −2.43**, a symmetric ~2.5 σ tug.

Also: **the prior CENTRE for `seas_T_amp_NH` is 14.3215 K**, the geometric mean of the
bracket (`ccx_bracket_lnorm`), not the LO end 11.445. The joint prior implies **4.41×** the
modulation the mode accepts, not 3.52×.

Replaced by one `ccx_prior_z()` in `R/calibrate.R`, integrating in the unconstrained
coordinate where every prior in the table has scale O(1) by construction, centred on the
PRIOR's mode rather than on x, carrying both tails so −6.27 survives.
`tests/testthat/test-prior-z.R` pins it to the analytic answer for every closed-form prior.
27 assertions.

**The stale `prior_z` field in `mode_fit_pumpN.rds` is NOT quarantined**, deliberately: the
bug touched one reported field, never the objective, the mode or the Hessian, and §§2–4 all
read that file. It is superseded by `ccx_prior_z()` in one line.

---

## 5. §4 IS NOW THE TOP ITEM, AND IT GOT WORSE

`sst_seas_amp_NH`: observed 2.237, mode 0.4668, **−6.27 σ** (the correction moved it from
−5.97). Nothing in this session touched it. The predecessor handoff's §4 stands as written
— a per-stream veto profile before any new download — and **the machinery now exists**:
`diag_seas_T_amp_q10_ridge.R`'s axis table is a one-entry change, which is what its header
claims and has now been exercised twice.

One thing this session learned that bears on it: under a pure-likelihood objective
`sst_seas_amp_NH` runs to **1e-31** — the likelihood does not merely tolerate the ocean
channel being off, it wants it off, which is consistent with `ccx_seas_chan_budget`'s
"turning it OFF HELPS". Run §4 under `partial`, not `lik`.

---

## 6. NON-OBVIOUS STATE

- **`diag_seas_T_amp_q10_ridge.R` takes five args:** axis (`amp`|`q10`), tag, tiers, grid,
  objective (`partial`|`lik`). Tiers are `pair` / `pairSH` / `block` / `land`.
- **Never read the `pair` tier alone.** It freezes `seas_T_amp_SH` while `q10` — which both
  hemispheres share — moves, so it charges the NH profile for an SH misfit it did not cause.
  `pair` minus `pairSH` is the size of that artefact and it is large (the amp axis: 217.6
  spread vs 111.8).
- **One optimiser cell is bad:** `q10` = 2.3, BLOCK tier, `lik` objective — non-monotonic
  (`d13c_seasonal_MLO` −36.7 against −3.4 at `q10` = 2.0). A different local optimum. Read
  PAIRSH there.
- **`calibration/diag_phi_eff_profile.R` still carries the double-`luc_scale` bug** in its
  `by_stream`/`gcb_land_sink` column. Its optimisation went through `ccx_make_logpost()` and
  its seasonal-row conclusions never touch LUC, so its published findings stand — but do not
  copy that idiom again. `ccx_forcing_eluc_annual()` reads the forcing's `e_luc` columns, so
  it must be taken BEFORE the `luc_scale` column multiply.
- Everything in 20e §9's trap list still applies. The two `test-fluxes.R` failures (:99,
  :100) are still failing by design and still awaiting Marcus.

---

## 7. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-21b_ridge_confirmed_repair_amended.md`. §§2–3 of the previous
> handoff are CLOSED. **Start with §4** — `sst_seas_amp_NH` at −6.27 σ is now the largest
> single misfit and the only one of the three still open; the per-stream veto profile is
> specified in the 2026-08-21 handoff §4 and the machinery is a one-entry change to
> `diag_seas_T_amp_q10_ridge.R`'s axis table. **Run it under the `partial` objective, not
> `lik`** — under `lik` the ocean channel switches itself off at 1e-31 and the profile stops
> being about this model. **The §2 refit is BLOCKED on a soil-temperature damping factor
> with provenance**, and if that comes back far from 0.28 it should not be run at all.
