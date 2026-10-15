# Handoff — CarbonCycleEmulator, 2026-08-16b: the gradient terms are IN THE OBJECTIVE, both §6 decisions are taken, and "zero leverage" did not survive the decision that was taken

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`, still
**not merged**, working tree clean at **`0f83dfe`**. Suite **4 failing / 746 passing** (was
4 / 737); the four are the pre-existing ones, unchanged, none flagged for Marcus.

**Supersedes `handoff_2026-08-16_candidates_neff_and_gradient_terms.md` for §4 and §6.**
That note's §2 (candidates A and B1) and §3 (`n_eff`) stand unchanged.

---

## 0. START HERE

1. **Task 12 is DONE. The terms are in the objective** — streams `ocean_grad_dic` and
   `ocean_grad_d13c`. §2 is what shipped.
2. **Both §6 blockers are resolved, and decision 1 had a SECOND AXIS the old note did not
   see:** not just the contamination question but the **layer definition**, worth ~1σ on its
   own. Marcus took both. §1.
3. **§4.2's "leverage is EXACTLY ZERO, so the terms are a pure constant and cannot hijack a
   parameter" IS NO LONGER TRUE of what shipped**, because Marcus chose transient scoring.
   It survives only for the *preindustrial* gradient. Measured leverage ≤ 0.09 σ_Δ per 10 %
   perturbation — 120× too weak to matter, but not zero, so the gate had to be re-aimed. §3.
   **If you carry one thing forward from this note, carry that.**
4. **δ¹³C is the STRONGER term** (z +16.5 vs DIC's −11.0) and will dominate the pump's fit,
   even though the pump was designed against the DIC row. §2. Nobody has checked whether the
   pump that satisfies DIC also satisfies δ¹³C at these weights.
5. **The pump is the other half of the round and it is NOT built.** §4.5 of the old note is
   unchanged: terms + pump in the SAME round, then **one** refit. The terms are the harmless
   half. **The refit still waits.** §5.
6. **I got a directional claim wrong mid-session and Marcus' question is what caught it.**
   §6. Weight the tables over the prose, including the prose here.

---

## 1. The two decisions, and the axis that was not in the old note

### 1.1 Contamination — Marcus took TRANSIENT SCORING, and it is measurably free

Score the model's **transient** gradient at the observations' epoch, rather than correct the
observed surface for anthropogenic carbon and Suess. **This was testable and it was tested**
(`diag_gradient_target_and_neff.R` part 5b), because "the cheap option is equivalent" is
exactly the kind of claim that is usually asserted:

| route | miss (µmol/kg) | σ_Δ |
|---|---|---|
| **option 3 — transient at obs epoch (SHIPPED)** | **278.29** | **11.02** |
| option 2 — preindustrial + ~50 µmol/kg C_ant | 283.11 | 11.21 |
| option 1 — raw modern vs preindustrial model | 233.11 | 9.23 |

**0.19 σ_Δ apart.** The contamination cancels on *both* sides because the model takes up
anthropogenic carbon too. Option 1 would have understated the miss by **1.98 σ**, all of it in
the direction that hides the pump — the old §4.4 trap, now quantified rather than flagged.

Option 2 was also the expensive one: **the GLODAPv2.2023 bottle master carries no C_ant
column** (checked directly). Only δ¹³C had its correction in-repo
(`eide2017_c13_suess_effect.nc`); DIC would have needed a new download or a ΔC* build.

### 1.2 Layers — a SECOND axis, worth ~1σ, that the old note did not have

Chasing why §4.4 said **+244.7 µmol/kg / −0.938 ‰** while the shipped
`data/obs_glodap_deep.rds` says **+233.11 / −0.8610** turned up two facts:

- The §4.4 numbers are the model's **own boxes at `h_ml` = 75 — the DEFAULT, not the fitted
  value.** Both reproduce exactly; it is a layer choice, not a discrepancy.
- **A model-anchored target is therefore a function of a FITTED PARAMETER:** +244.7 (h_ml 75)
  → +235.0 (100) → **+212.8 (184, the fitted value)**.

**Neither way out is neutral, and their biases point OPPOSITE ways** (priced at σ_Δ = 19.82):

| `h_ml` | like-for-like | frozen @75 | freezing costs (σ_Δ) | anchoring gives (log-u) |
|---|---|---|---|---|
| 75 | 244.71 | 244.71 | 0.00 | 76.2 |
| 100 *(pump)* | 234.98 | 244.71 | 0.49 | 70.3 |
| 184 *(fitted)* | 212.79 | 244.71 | **1.61** | **57.6** |
| 220 | 203.66 | 244.71 | 2.07 | 52.8 |

- **Model-anchoring** rewards a **LARGE `h_ml`** — pre-pump the model's gradient is 0 at every
  `h_ml`, so the penalty is target²/2σ² and falls 81 → 53 log-units across 50 → 220. It pushes
  **against clause 1**, the thing the pump exists to fix.
- **Freezing at `h_ml` = 75** overstates the miss by **1.61 σ_Δ** at the fitted 184, biasing
  **in favor of** adopting a pump and a stronger one — at the conclusion the term exists to test.

**MARCUS TOOK: fixed depths (the shipped rds layers) + an `h_ml` GATE.** The reason it beats
freezing: **at `h_ml` = 100 — the value the pump delivers (15d) — fixed depths are already
like-for-like to 0.09 σ_Δ.** So the gate defers the choice to the refit instead of pre-judging
it, and if the pump misses `h_ml` ≈ 100 the gate says so rather than the term quietly biasing.

---

## 2. What shipped

| | value | where it comes from |
|---|---|---|
| target, DIC | **+233.109 µmol/kg** | `obs_glodap_deep.rds$gradient`, fixed depths 0–100 m / >2627.2 m |
| target, δ¹³C | **−0.8610 ‰** | ditto |
| σ_Δ, DIC / δ¹³C | **25.25 / 0.1115** | block bootstrap **on the contrast**, conservative of the two valid block sizes |
| epoch (surf / deep) | **1999.8 / 2002.4** (DIC); 1999.8 / 2002.2 (δ¹³C) | cell-weighted mean sampling year, per field **and** per layer |
| `h_ml` gate | **[85, 120] m** | `LIK_OCEAN_GRAD_HML_OK` |

**Every number is a BUILD PRODUCT, not a literal in `likelihood.R`** — same discipline as
`ccx_deep_d14c_target()`, so changing the build cannot leave a stale constant behind.

**GRADIENT, not level, and for δ¹³C that is substantive:** the model's uniform ocean δ¹³C is
+1.560 ‰ against a preindustrial surface nearer +2.0. That **level** miss is air–sea
fractionation and the preindustrial atmospheric value — nothing to do with the pump. A level
term would conflate it with the pump signal; a gradient term is immune.

**σ came from a bootstrap ON THE CONTRAST, and that is not a detail.**
Var(Δ) = Var(D) + Var(S) − 2 Cov(D,S), and the covariance is neither negligible nor
same-signed across fields:

| field | corr(surf, deep) | effect on σ_Δ | deep-LEVEL n_eff |
|---|---|---|---|
| DIC | **−0.38 to −0.60** | **INFLATES ~25 %** | 10.2 – 23.3 |
| δ¹³C | +0.09 to +0.12 | cancels ~4–8 % | 10.2 – 23.5 |
| Δ¹⁴C (control) | ≈ 0 | none | 11.7 – 25.8 |

Composing σ from two per-layer `n_eff` would have got **DIC wrong by 25 % in the direction
that makes the term TOO STRONG.** Mechanism: surface DIC peaks where the water is cold and
dense — the high latitudes — which is exactly where the deep water is *youngest* and lowest in
respired carbon, so basins trade the two ends of the gradient and a basin-skewed sample misses
the **contrast** by more than either **level**. Same physics as the deep-Δ¹⁴C correlogram's
negative tail, on a different pair of layers. Confirmed by two estimators sharing no machinery
(block bootstrap; paired-column correlation on the raw field), agreeing on sign for all three.

**Old §4.6's worry does NOT bite for the LEVEL terms.** `LIK_D14C_DEEP_NEFF` = 20 sits inside
the measured bracket for **all three fields**. It bites only for the contrast.

**logL moved by ~199 log-units** (DIC 64.9, δ¹³C 134.5 at `h_ml` = 100) and is now
**incomparable with every prior run**. Expected, not a bug. Note this is not §4.2's ~384:
that was a *level* formulation and its baseline deep DIC 1996.2555 does not reproduce (the
default spinup column is uniform at **1986.3340** NH / **2003.7207** SH).

**δ¹³C IS THE STRONGER TERM: z +16.5 against DIC's −11.0.** The pump was designed against the
DIC row. Whether the pump that closes DIC also closes δ¹³C at these weights is **unchecked**
and is the first thing the pump work should look at.

---

## 3. THE THING THAT CHANGED UNDER THE DECISION: zero leverage did not survive

Old §4.2's argument was: leverage is exactly zero → the terms are a pure constant → **no
posterior distortion and no parameter hijacking**, and *gate it*.

**That holds for the PREINDUSTRIAL gradient and NOT for what shipped.** The preindustrial
interior is still uniform to machine precision for every parameter — it is a *proof* (DIC and
¹³C are conserved with no interior source, so any steady state of any transport operator has a
uniform interior; the ML value is carbonate equilibrium at fixed `ALK_SURFACE` and SST). But
the **transient** gradient depends on anthropogenic uptake, hence on the ocean parameters.

**Measured: ≤ 0.09 σ_Δ per 10 % perturbation** across `kz`, `h_ml`, `k_w`, `beta_max`, `q10`,
`tau_ex` (largest is `beta_max`, which makes sense — more land uptake, less ocean uptake, less
surface DIC rise), against an **11 σ miss**. So ~120× too weak to hijack a parameter, but not
zero.

**Consequence for the gate §4.2 asked for, and it had to be re-aimed rather than written as
specified:**

- **exact-zero** assertion → on the **preindustrial** gradient. That is the property the pump
  breaks on purpose, so it is the one worth gating exactly.
- **bound** (`LEV_MAX` = 0.25 σ) → on the **transient**, with a companion assertion that the
  miss is > 5 σ so the bound cannot pass for the wrong reason.

Writing §4.2's gate as literally specified would have **failed on the shipped quantity**.

---

## 4. Files

| file | what changed |
|---|---|
| `src/ccx_core.cpp` | **+8 output columns** — ML and bottom-box C and ¹³C per hemisphere, raw GtC. `out` is n×19. |
| `R/forcing.R` (`ccx_run`) | the same 8, in the R reference core |
| `R/model.R` | `CCX_OCEAN_BOX_COLS` — **order is load-bearing**, `ccx_run_fast()` names the C++ matrix positionally from it |
| `R/cpp.R` | names the new columns |
| `R/likelihood.R` | `LIK_USE_OCEAN_GRAD`, `LIK_OCEAN_GRAD_HML_OK`, `ccx_ocean_gradient_target()`, `ccx_model_ocean_gradient()`, `ccx_ocean_grad_scored()`, the two terms, `ocean_grad` argument |
| `R/calibrate.R` | passes `ocean_grad = ccx_ocean_grad_scored(r$out, sp)` |
| `data-raw/build_glodap_deep_targets.R` | `gradient` block: targets, bootstrap σ, epochs. **Gated: every pre-existing field is bit-identical.** |
| `data/obs_glodap_deep.rds` | rebuilt, `gradient` block added |
| `calibration/diag_gradient_target_and_neff.R` | **NEW**, ~25 s. Parts 1–5b; gates A, B, C |
| `tests/testthat/test-likelihood.R` | +4 blocks: absence contract, `h_ml` gate, preindustrial zero, transient bound |
| `tests/testthat/test-parity.R` | the 8 new columns + an anti-degeneracy check |
| `tests/testthat/test-ocean-advection.R` | **re-scoped and strengthened — see §6** |
| `DESIGN.md` | §5.2a (measurements), §5.2b (what shipped) |

---

## 5. The ordering, amended again

| # | task | status |
|---|---|---|
| ~~1–7, 6b, 10, 11~~ | objective, β, `luc_scale`, GLODAPv2, gradient, shares, seasonality, MM fertilization, `sigma_co2`, `K_z(z)` scored, outcrop DEAD | **DONE** |
| **6** | `LIK_EXCESS_C14_TARGET` | NOT a blocker |
| **12** | **DIC + δ¹³C gradient terms** | **DONE 2026-08-16, `0f83dfe`** |
| **9** | **THE PUMP** | **NOT BUILT. The other half of the round.** |
| **8** | **THE REFIT** | **after 9, once, against the complete objective** |

---

## 6. Open decisions, in dependency order

1. **THE PUMP (task 9).** All three clauses passed as a zero-parameter shim (15d); it now has
   an objective that can see it. **The C++ core does not know about it** — it is a shim over
   `ccx_deriv()`, which is why `diag_dic_gradient.R` costs 15 minutes. Porting is a shipping
   decision and it is the bulk of the remaining work.
2. **Does the pump that closes DIC also close δ¹³C?** Unchecked, and δ¹³C is now the stronger
   term (§2). This is cheap to look at with the existing shim and should come first.
3. **Where does the refit's `h_ml` land?** If it leaves **[85, 120]** the terms go absent and
   the target needs re-deriving. The gate exists so this is visible, not silent.
4. **σ_Δ has NOT plateaued in block size** (30° → 60° still rising), so it is a range, not a
   point. The 60° row is the most defensible and the noisiest (16 blocks); shipped
   conservative. Unresolved.
5. **Representation error still ZERO** (carried over). At σ 18.15 candidate A stops being
   adopted.
6. **Point σ vs Student-t** (carried over). Honest error model vs ever retiring the `kz` bracket.
7. **Is A's `kz` = 6404, outside [3830, 6200], a blocker or a re-derivation?** (carried over)
8. **Does A ship at all**, given it fixes clause 3 only? (carried over)

---

## 7. Non-obvious state, and a caution

- **I got a directional claim WRONG mid-session, and Marcus asking "are there any drawbacks?"
  is what caught it.** I wrote — into the CHANGELOG, DESIGN §5.2a, the script and a commit
  message — that a model-anchored target "rewards shrinking `h_ml`". **It is the opposite**
  (§1.2): the penalty *falls* with `h_ml`, so it rewards a LARGE one. I reasoned about the
  target's motion and never checked the sign of its effect on the penalty. Retracted in all
  four places, and the retraction is kept visible rather than edited away.
- **I also predicted the cross-layer covariance SIGN wrong**, in the file header, before
  measuring: I argued the layers share cruises so sampling error cancels. DIC anticorrelates
  and **inflates** σ_Δ ~25 %. Both estimators agree. Also kept visible.
- **A TEST FAILED AND IT WAS NOT A REGRESSION.** `test-ocean-advection.R:152` asserted
  `expect_equal(as.matrix(out$out), ...)` over the **whole** frame, under a comment saying
  "the ... TOTALS are tied ... the INTERIOR is not". Those were the same set only because
  `out` carried no interior quantity. Measured at the split: **every pre-existing column ties
  to ≤ 1.5e-10, the MIXED-LAYER columns tie to ≤ 2.9e-13, only the BOTTOM-BOX ones differ**
  (`deep_C_NH` by 3.68 GtC). Physics untouched; the assertion's scope was wrong. Re-scoped
  **and strengthened**: the mixed-layer tie is now asserted explicitly — that is the test's own
  mechanism claim ("air–sea acts at `iml` and nowhere else") measured directly rather than
  inferred from totals that could tie by cancellation — and the bottom-box columns are now
  asserted to DIFFER.
- **Gate C compares the diagnostic to the shipped build product** on a **3 % Monte Carlo
  tolerance**, not equality: both sides bootstrap from the same seed but a different call
  order, and gating a bootstrap SE on equality would test RNG call order, not the estimator.
- **`calibration/output/mode_fit.rds` is still EMPTY.** The app has no mode. Every "at the
  mode" number still comes from the quarantined pre-gradient one.
- **19 parameters.** The two OPPOSITE absence conventions in `err` still stand: gradient
  offsets absent → streams SKIPPED; `sigma_co2` absent → tighter sd. `ocean_grad` follows the
  **skip** convention.
- **Name collision to avoid:** `grad_off_co2` / `grad_off_d13c` in `err` are the **MLO−SPO
  ATMOSPHERIC** gradient offsets (review item 5), nothing to do with these ocean terms. The
  ocean ones are `LIK_OCEAN_GRAD_*` / `ocean_grad_*` throughout. Do not merge the two families.
- **`luc-veg-debit` has never been merged** and is now a long way from `main`.

**Still do NOT:** hand-tune stream weights (adding these terms was *adding a missing
constraint*, the sanctioned move — do not let it become a license to reweight); delete
`excess_c14_ocean` or `d14c_intcal`; free any land turnover parameter; delete the `kz` bracket
bare; build the conveyor; splice any pre-2026-08-15 posterior; **compare any logL across the
2026-08-16 boundary** (the objective moved ~199 units); quote §4.2's ~384 log-units or its
1996.2555 baseline (neither reproduces); quote the defaults-parameter clause-3 verdict as the
answer; or quote the free validations (ocean inventory, ¹⁴C production) as if the likelihood
had rewarded them.

---

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-16b_gradient_terms_shipped.md`. **Task 12 is done — the DIC and
> δ¹³C gradient terms are in the objective** on fixed depths with an `h_ml` gate, scored on
> the transient at the observations' epoch (measurably equivalent to the C_ant correction, to
> 0.19 σ). **§4.2's zero-leverage guarantee did NOT survive that decision** — it holds only
> for the preindustrial gradient; the transient's leverage is ≤ 0.09 σ, gated as a bound. **The
> pump (task 9) is the other half of the round and is not built; the refit waits for it.**
> Start with §6's items 1 and 2 — and note **δ¹³C is now the stronger term (z +16.5 vs −11.0)
> while the pump was designed on the DIC row.** Suite 4 failing / 746 passing, none flagged.
