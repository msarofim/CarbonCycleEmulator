# Handoff — 2026-09-09b. **Rulings 1–3 are DONE and objective-neutral; ruling 4 is still Marcus's, and the evidence moved AGAINST it late in the session.** Four commits on `isotopic-audit-20260909`; `main` still untouched.

Read first: `notes/handoff_2026-09-09_isotopic_audit.md` (the session this continues), **CHANGELOG 09-09b → 09-09e**, `INDEX_ccx_gates.md`.
Memory: [[ccx_debias_penalty_is_post_1970]], [[ccx_bomb_rep_sensitivity]], [[ccx_nl_ocean_cannot_rank_debias]], [[ccx_gate_gl_augmented]], [[ccx_gate5_argmax_on_bimodal]], [[ccx_debias_invalidates_hilda31]].

## 0. ⚠ STATE OF THE TREE
- **`main` UNCHANGED.** All work is on **`isotopic-audit-20260909`**, now **5 commits** (`00e1749` from the previous session, then `dcdfd04`, `9138e48`, `da0a852`, `c955620`).
- **Suite: 5 fail / 2265 pass / 4 skip** — the SAME 5 as at session start, all pre-existing: `test-alpha-as.R:116,117` (gate Q, deliberate), `test-seas-lag-split.R:199` (error), `test-enso-demean.R:144,162` (the ruling-4 provenance guards). Pass count rose 2226 → 2265 from new assertions. ⛔ **Do not "fix" the enso-demean pair** — they are the ledger saying a refit is owed if ruling 4 stands.
- `data/forcing_bomb_c14.rds` is still **de-biased** (`t2_high_bias_divisor = 1.20`). `git checkout main` restores the pre-de-biasing product. Every diagnostic that swaps it does so under `tryCatch(finally=)` **plus an md5 restore assertion**, and `git status data/` was verified clean after each.
- Scratchpad artifacts this session used: `bomb_pre.rds` (= `git show main:data/forcing_bomb_c14.rds`) and `live_backup.rds`. **Regenerate them, don't hunt for them** — they are session-local.

## 1. Rulings 1–3: DONE, and none of them moved the objective
Marcus: *"Definitely do 1 and 3. If 2 is a definite improvement, then do it now too, unless the attribution would be valuable for the pedagogy of the final website."*

| # | ruling | status |
|---|---|---|
| 1 | gate 5's NH statistic → **TROUGH DEPTH**, first-peak time reported | ✅ **IMPLEMENTED** (`dcdfd04`) |
| 2 | σ_rep table → re-bin on the model's own layer edges | ✅ **CLOSED WITH NO CHANGE** (Marcus: *"Leave it"*) |
| 3 | GL's bound → **AUGMENTED (CO₂-control) form** | ✅ **IMPLEMENTED** (`dcdfd04`) |
| 4 | Tans ~20 % Telegadas high-bias → apply | ⛔ **STILL OPEN — Marcus's call** |

**Gates live in `calibration/lib_design_gates.R`, so 1 and 3 moved NO stored logpost and owe NO refit.** Round 6's prereg is unblocked on everything except ruling 4.

### 1a. Ruling 1 — and it VINDICATED itself
`dg_nh_shape()` + `DG_G5_W1/WT/W2` **promoted out of** `diag_gate5_bimodal.R`'s local `feat()`; the diagnostic now delegates, so gate and diagnostic cannot report one statistic at two values. σ **derived** by the same leave-one-zone-out construction as every other gate-5 σ: **observed drop 111.34 ‰, σ 33.83 ‰** (4 draws).
- ⭐⭐ **The premise, MEASURED**: argmax time zonal sd **0.444 yr** vs first-peak **0.042 yr** — 10× tighter. Asserted in `test-gate-bounds.R` so the justification fails loudly if it stops holding.
- ⭐⭐ **The verdict vindicates it**: the model's first-peak time matches obs to **z +0.0008**, where the retired argmax said "+2.17 σ late". **The NH bomb timing was never wrong.**
- ⚠ **`lag` still inherits the argmax** (a lump flip moves it 1.86 σ, inside the bound). **RECORDED, NOT FIXED** — redefining the lag on the first-peak time is a separate methodological choice and needs a ruling.
- Mutation-tested four ways, including that a whole-lump argmax jump can no longer fail the gate.

### 1b. Ruling 3 — an allowance that cannot flip the verdict
`dg_gateGL_verdict()`'s `rep_frac` flips `0` → **DERIVED**: `dg_gl_rep_frac()` computes `|1 − R_co2|` from the same `(g, ho)`. Bare-se z reported as `z_bare`. `hilda31` **−13.31 → −8.67, still FAILS**; column_control −8.54; defaults −6.24. **Mutation-tested that a 2× gradient fails at every control detuning up to 30 %.**

### 1c. Ruling 2 — closed because the ruling named something the code already does
1. **"Re-bin on the model's own layer edges" IS the construction** (`build_glodap_sigma_rep.R:135` calls `ccx_ocean_grid(h)` on a 1 m grid over `h_ml`'s whole support). No 25 m binning exists to remove.
2. **The steps are GLODAP's BOTTLE DEPTHS** — measured, the largest 1 m jumps sit at h = 30/40/50/75/100/150/200 in all three rows.
3. **Smoothing was already tried and REJECTED on measurement** (deviates by more than the jumps it removes).
⚠ And the premise is worth re-reading: **a sampler crosses a C1 shelf; a Laplace step-search does not** — so "the shelf blocks the posterior" is about the SAMPLER CHOICE, not the table.

## 2. ⛔⛔ RULING 4 — the evidence, re-sorted. IT MOVED AGAINST THE RULING.
Marcus: *"I care most about actual physical observational reasons"*, then *"My lean is to use the best data… I don't want to over fit to data which might be flawed."* Both were taken seriously and both changed the picture.

### 2a. Two of the four original counter-measurements are not physical
(1) the −92.7 and (2) the two red tests are **the same fixed-vector measurement twice**, on a mode fitted under the OLD forcing. ⚠ And **"why it can act at all" is NEUTRAL**: N&L's 102 kmol is a full-reservoir budget closure at 1975/1995 (DATA.md §10), genuinely independent of Telegadas' 1963–69 aircraft inventories, so scaling one and not the other is **correct** if Tans' caveat attaches to Telegadas — which is what Tans says.

### 2b. The N&L ocean inventory CANNOT arbitrate it (`9138e48`)
| year | obs (`table4_obs_range`) | pre | de-biased | arm shift |
|---|---|---|---|---|
| 1975 | 40.7–56.5 | 59.54 OUTSIDE | 61.41 OUTSIDE | +1.87 |
| 1995 | 43.8–59.0 | 81.18 OUTSIDE | 81.54 OUTSIDE | +0.36 |

**Both arms miss every target set on the SAME side by far more than they differ ⇒ ranks neither.** Also found: fitted `bomb_total` **118.4 kmol vs N&L's own 99.3–104.9 prior**; scaling to that top puts 1975 INSIDE, so the 1975 miss is an amplitude excursion common to both arms.

### 2c. ⛔ The "3–11× understatement" is RETRACTED (`da0a852`)
DATA.md §9c, CHANGELOG 09-09 and `ccx_graven_vs_hua` all said Hua's 3.6 ‰ understates by 3–11×, and I told Marcus this "defuses" (1) and (2). **3.6 ‰ is not the denominator the objective uses.** `LIK_D14C_REP_BOMB = 25 ‰` has been added in quadrature over 1955–1970 since August. **MEASURED: σ_eff 25.7–25.8 ‰ in 1963–65** vs 6.9–7.4 outside — already ~7× Hua's sd. Real shortfall at the peak ~1.55×. Retracted at all four quoting sites in one pass.

Rescoring at wider σ: **25 → −92.74 | 32 → −80.37 | 40 → −73.13 | 47 → −69.51.** **Only 21–25 % comes off.** ⇒ **the penalty is NOT an artifact of an over-tight target**, so the overfitting worry does not undermine applying the correction.

### 2d. ⭐⭐ AND THEN THE LOCALISATION CUT THE OTHER WAY (`c955620`)
| era | NH | SH | both |
|---|---|---|---|
| 1955–62 (the "dump") | −16.53 | −5.48 | **−22.02** |
| 1963–65 (peak) | +0.32 | −12.52 | −12.21 |
| **post-1970** | −4.51 | **−45.40** | **−49.91** |
| TOTAL | −23.22 | −69.45 | −92.68 |

**54 % of the cost, and 65 % of the SH's, is AFTER 1970** — outside the bomb window, at **σ ≈ 7 ‰**, in the years Graven and Hua **agree to 2–3 ‰**. The penalty is charged in the **BEST-observed** part of the record. (That is also why widening the window recovered only 21–25 %: most of the cost was never inside it.)

⭐ **And the model was already out there** — SH 1971 **z +4.31 → +6.13**, 1972 +3.14 → +5.10, 1973 +1.81 → +4.06. The correction **deepens a pre-existing post-peak SH deficit the fit could not close at the OLD forcing either**, which **bounds how much a refit can absorb**.

⇒ **This is the strongest observational argument against ruling 4 yet found.** ⚠ Still fixed-vector; a refit is owed either way.

### 2e. ⛔ THE METHOD LESSON OF THE DAY
**Twice in one session the penalty's mechanism was asserted from where the FORCING CHANGED rather than from where the COST LANDED, and both times it was wrong.** Localise before explaining.

### 2f. The gate-5 trough, for completeness
Under ruling 1's own derived bound: **pre-de-biasing trough 50.5, z −1.80 = PASS; de-biased 24.9, z −2.55 = FAIL.** ⚠ A **SOFT** flip (same side of obs; a 30 %/4-draw tolerance). Graven is **annual** and cannot arbitrate a within-year trough. First-peak z is +0.0008 in BOTH arms.

## 3. The wider σ audit (Marcus's second question) — three live items, NONE acted on
The stack carries explicit allowances almost everywhere, each with a receipt (`co2_level` deliberately soft at χ²/dof ≈ 0.38; gradient σ's measured against Scripps-vs-NOAA and floored by observational precision; icecore ⊕ 4 ppm; land sink ×3.0; `excess_c14` ⊕ a 0.15 shared method bias; `ocean_grad` ⊕ a measured σ_rep; `d14c_deep/mid` at a measured-consistent n_eff 20). Exceptions:
1. ⚠ **`gcb_ocean_sink` = 0.4 GtC/yr UNINFLATED** while the land sink gets ×3.0 — and gate 7's ledger calls the ocean sink *"a product of ocean biogeochemistry MODELS"*. **The clearest asymmetry in the stack.**
2. ⚠ **`excess_c14_ocean`'s target-set choice** (`table4_obs_range` vs the ~3× tighter `table2_peacock`) — **worth ~130 log-units**, flagged and never settled.
3. ⚠ **The mid-century ice discrepancy window (1935–1960) is a knob defaulted OFF** (`CCX_ICE_DISCREPANCY = 1`) ⇒ [[default_off_hides_the_bug]].

## 4. Stale docs found by measuring instead of quoting
- ⛔ **DATA.md §10's LUC-¹⁴C leak ("23.9 kmol at 1975, 28.3 at 1995") measures −0.11 and −0.00 at `hilda31`.** Either fixed after that text or mode-dependent; **never quote it for the canonical without re-measuring.**
- ⛔ **`sprintf("%.2f", NULL)` returns a zero-length vector and `cat()` prints NOTHING** — the pre-de-biasing product has no `t2_high_bias_divisor` field, and a whole diagnostic line vanished with no error. Guard NULLs to `NA_real_` before any `sprintf` feeding a `cat`.

## 5. New / changed files
| file | what |
|---|---|
| `calibration/lib_design_gates.R` | rulings 1 + 3: `dg_nh_shape`, `DG_G5_W1/WT/W2`, `dg_gl_rep_frac`, verdicts |
| `tests/testthat/test-gate-bounds.R` | +4 mutation tests; 173 pass / 0 fail in-file |
| `calibration/diag_gate5_bimodal.R`, `diag_tg_gradient_level_gate.R` | delegate to the promoted kernels; GL arms swapped roles |
| `calibration/diag_debias_ocean_inventory_power.R` | **new** — the N&L power measurement |
| `calibration/diag_bomb_rep_sensitivity.R` | **new** — the σ sensitivity + the 3–11× retraction |
| `calibration/diag_debias_penalty_by_year.R` | **new** — the localisation, self-checked against `ccx_loglik` |
| `DATA.md`, `CHANGELOG.md` | retractions propagated in-pass |

## 6. What I would do first next session
1. **Ruling 4 is Marcus's and the evidence is now complete.** His stated lean is to apply it ("use the best data"); §2c says the overfitting worry does not block that; **§2d is the argument that does cut against it** and is the one thing he has not yet responded to. **Ask; do not infer.**
2. If **KEPT** ⇒ objective change #8: **refit + re-promote before round 6 can be judged.** ⚠ Budget it knowing the SH post-1970 deficit was already 4.3σ at the OLD forcing — a refit is not likely to recover the −45.4.
3. If **REVERTED** ⇒ one line (`BOMB_T2_HIGH_BIAS` → 1.0) + rebuild; suite goes green; every diagnostic and finding above is KEPT.
4. Either way, **round 6 = C alone** remains the plan of handoff 09-08j; rulings 1–3 no longer block it.
5. ⚠ **OWED TIDY (carried from the last handoff, still true):** `INDEX_ccx.md` is 245 B over its 14 KB soft target; the natural move is the stale "LIVE STATE (2026-09-04)" 26-par / `ent26` refit history → `INDEX_ccx_arch`, **keeping the migration warnings**. `INDEX_ccx_gates.md` grew 6,726 → 9,229 B this session (soft target 14 KB, fine).
