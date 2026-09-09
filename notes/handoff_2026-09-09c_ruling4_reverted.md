# Handoff — 2026-09-09c. **RULING 4 REVERTED to 1.0 (Marcus). All four rulings are now closed, none of them left an objective change, and NO REFIT IS OWED. `hilda31` is canonical again and every stored logpost is valid.** Branch `isotopic-audit-20260909` is ready to merge to `main`.

Read first: **CHANGELOG 09-09b → 09-09f**, `notes/handoff_2026-09-09b_rulings_audit.md` (the evidence, in full), `notes/handoff_2026-09-08j_next_step_recommendation.md` (round 6, still the plan).
Memory: [[ccx_debias_invalidates_hilda31]] (now RESOLVED), [[ccx_debias_penalty_is_post_1970]], [[ccx_bomb_rep_sensitivity]], [[ccx_nl_ocean_cannot_rank_debias]], [[ccx_gate5_argmax_on_bimodal]], [[ccx_gate_gl_augmented]].

## 0. STATE OF THE TREE
- Branch **`isotopic-audit-20260909`**, 7 commits ahead of `main`. **`main` is still untouched.**
- **`data/forcing_bomb_c14.rds` is at divisor 1.0** and is **bit-identical to `main` on all four data columns** (`t`, `year`, `month`, `shape_per_yr`; max |diff| 0.000e+00, `identical()` TRUE for each). Only the provenance differs, and only by recording `t2_high_bias_divisor = 1.0` **explicitly** where `main` has no field.
- **Suite: 3 fail / 4 skip** — `test-alpha-as.R:116,117` (gate Q, deliberate) and `test-seas-lag-split.R:199` (error). **The two ruling-4 provenance guards `test-enso-demean.R:144,162` are GREEN again**, which is exactly what they were written to report.
- ⭐ **NOTHING IS OWED.** No refit, no re-promotion, no objective change from any of the four rulings.

## 1. All four rulings, closed
| # | ruling | outcome |
|---|---|---|
| 1 | gate 5's NH statistic → **TROUGH DEPTH**, first-peak time reported | ✅ **IMPLEMENTED** — gate-side, no logpost moved |
| 2 | σ_rep table → re-bin on the model's own layer edges | ✅ **CLOSED, NO CHANGE** — the ruling named what the code already does |
| 3 | GL's bound → **AUGMENTED (CO₂-control) form** | ✅ **IMPLEMENTED** — gate-side, no logpost moved |
| 4 | Tans ~20 % Telegadas high-bias ÷1.20 | ⛔ **APPLIED, MEASURED, THEN REVERTED to 1.0** |

## 2. Why ruling 4 was reverted — and what the reason is NOT
Marcus asked: *"So it seems like the factor of 1.2 creates inconsistencies with the independent compilations?"*

⚠ **The premise was corrected before acting.** The ÷1.20 does **NOT** create an inconsistency *between* Graven and Hua — they disagree with each other in 1963–65 either way and the divisor does not touch that. It makes the **MODEL** fit the observed Δ¹⁴C record worse, and that cost lands **post-1970, where the two compilations AGREE to 2–3 ‰**. The corrected statement — *it degrades agreement with the best-established part of the observations* — still supports the revert, so the revert proceeded.

**The case, in the order it actually carries weight:**
1. ⭐⭐ **The cost is not where the forcing moved.** Localised per year (self-checked against `ccx_loglik`'s own stream totals): the 1955–62 "dump" carries **−22.0** of the −92.7 and only **−5.5** of the SH's −69.5; **post-1970 carries −49.9 (54 %), of which the SH is −45.4 (65 % of its own)** — *outside* the bomb window, at **σ ≈ 7 ‰ not 25**, in the years the compilations agree. And the model was **already z +4.31 too low in SH 1971 BEFORE the de-biasing** (→ +6.13 after), so it deepens a pre-existing deficit the fit could not close at the old forcing either.
2. **Gate 5's newly-ruled trough flips PASS → FAIL** (z −1.80 → −2.55). ⚠ A **SOFT** flip: both arms are on the same side of the observation, and the bound is a 30 %/4-draw tolerance.
3. **λ 0.1996 → 0.3490 /yr**, so gross air-sea exchange at Tans' own Broecker flux covers **75 % → 43 %** — DATA.md §9 names that agreement as the main evidence the budget-closure step is sound.

**⛔ WHAT DID *NOT* DECIDE IT — do not re-litigate these:**
- **The −92.7 is NOT an artifact of an over-tight target.** The bomb window is scored at **σ_eff 25.7 ‰** (`LIK_D14C_REP_BOMB` 25 ⊕ fitted `sigma_d14c` 5.45), already **~7×** Hua's own sd; widening to the full Graven–Hua spread (40) or the independent-errors bound (47) removes **only 21–25 %**.
- ⛔ **The "3–11× understatement" is RETRACTED** — it used Hua's 3.6 ‰, which is not the denominator the objective uses. Retracted at all four quoting sites.
- **The N&L ocean inventory has NO POWER** to rank the arms: both miss every target set on the same side by far more than they differ.
- ⚠ **"Why it can act at all" is NEUTRAL, not evidence against** — N&L's 102 kmol is a full-reservoir budget closure genuinely independent of Telegadas.
- ⚠ **The revert does not dispute Tans' caveat.** It declines to route the Telegadas-vs-N&L disagreement into the **pre-1963 troposphere** — the only channel available to it, and the least-observed part of the record.

## 3. Post-revert gate state, re-measured (not assumed)
| gate | ÷1.20 | **1.0 (canonical)** |
|---|---|---|
| gate 5 NH trough | 24.9, z −2.55 **FAIL** | **50.5, z −1.80 PASS** |
| gate 5 `sh_t` / `lag` | +0.76 / −1.43 | +1.47 / −0.94 |
| gate 5 first-peak z | +0.0008 | **+0.0008** |
| gate GL (augmented) | −8.67 FAIL | **−8.67 FAIL — UNCHANGED** |

⭐ **Gate GL is DIVISOR-INVARIANT** (the bomb ¹⁴C source does not move the δ¹³C gradient), so every ruling-3 number recorded in 09-09b stands as measured. ⚠ `sh_t` was *better* under the de-biasing (+0.76 vs +1.47) — it passes either way; recorded rather than buried.
⭐ **The headline of ruling 1 survives everything: the model's NH first-peak time matches the observation to z +0.0008 in BOTH arms. The NH bomb TIMING was never wrong** — the retired "+2.17 σ late" was `which.max()` picking the other lump.

## 4. Quarantine
**`outputs/quarantine/20260909_bomb_t2_debias/`** + README: `gate5_bimodal_20260909.{rds,log}`, `tg_gradient_level_gate_20260909.rds`, `bomb_delivery_tail_20260909.{rds,log}` — all **single-arm results on a different model input**. Canonical replacements regenerated at 1.0.
⛔ **NOT quarantined, deliberately** (they carry BOTH arms by construction, or no model, and are the provenance of the decision): `bomb_debias_impact`, `bomb_rep_sensitivity`, `debias_ocean_inventory_power`, `debias_penalty_by_year`, `graven_vs_hua`.
⭐ **The ÷1.20 arm remains reproducible in one env var:** `CCX_BOMB_T2_BIAS=1.20 Rscript data-raw/build_bomb_c14_source.R`.

## 5. Still open, from the σ audit — three items, NONE acted on
1. ⚠ **`gcb_ocean_sink` = 0.4 GtC/yr UNINFLATED** while the land sink gets ×3.0 — and gate 7's ledger calls the ocean sink *"a product of ocean biogeochemistry MODELS"*. **The clearest asymmetry in the stack.**
2. ⚠ **`excess_c14_ocean`'s target-set choice** (`table4_obs_range` vs the ~3× tighter `table2_peacock`) — **worth ~130 log-units**, flagged and never settled.
3. ⚠ **The mid-century ice discrepancy window (1935–1960) is a knob defaulted OFF** (`CCX_ICE_DISCREPANCY = 1`).

## 6. Stale docs found by measuring instead of quoting — both still true
- ⛔ **DATA.md §10's LUC-¹⁴C leak ("23.9 kmol at 1975, 28.3 at 1995") measures −0.11 and −0.00 at `hilda31`.** Never quote it for the canonical without re-measuring.
- ⛔ **`sprintf("%.2f", NULL)` returns a zero-length vector and `cat()` prints NOTHING.** Guard NULLs to `NA_real_` before any `sprintf` feeding a `cat`.
- ⚠ **`bomb_total` = 118.4 kmol vs N&L's own 99.3–104.9 production prior (+12.9 % above its top).** Unexplained, common to both arms, and worth its own look.
- ⚠ **`excess_c14_ocean` at 1995 sits ~72 kmol against an upper bound of 59** even after rescaling `bomb_total`. A SCORED stream, so the fit already sees it — check arc state before calling it new.

## 7. ⛔ THE METHOD LESSON OF THE DAY
**Twice in one session the penalty's mechanism was asserted from where the FORCING CHANGED rather than from where the COST LANDED, and both times it was wrong.** Localise a cost in time before explaining it. Both explanations were retracted in-pass at every quoting site.

## 8. What I would do first next session
1. **Merge `isotopic-audit-20260909` → `main`.** Nothing is owed, the suite is at its pre-existing 3, and the branch now carries four closed rulings plus five new diagnostics.
2. **Round 6 = C alone**, the plan of handoff 09-08j — now unblocked on every ruling.
3. ⚠ **OWED TIDY (carried three sessions now).** Budgets are **KiB on CONTENT** — strip `<!-- -->` blocks before counting ⇒ [[memory_budget_is_content_not_file]]; a bare `wc -c` has mis-flagged this root three handoffs running. **Measured 2026-09-09f:**
   | index | content | soft | verdict |
   |---|---|---|---|
   | `MEMORY.md` | 15,677 B | 12 KiB | **over by 3,389** (pre-existing; this session added ~360 B) |
   | `INDEX_ccx.md` | 14,581 B | 14 KiB | **over by 245** (pre-existing) |
   | `INDEX_ccx_gates.md` | 9,574 B | 14 KiB | OK (grew 6,726 → 9,574 this session) |

   Both overruns are SOFT ("merge when convenient"), neither is near the 18 KiB hard ceiling. The natural move for `INDEX_ccx.md` is the stale "LIVE STATE (2026-09-04)" 26-par / `ent26` refit history → `INDEX_ccx_arch`, **keeping the migration warnings**.
4. If the σ audit's item 1 is taken up, note it is an **objective change** and needs a ruling.
