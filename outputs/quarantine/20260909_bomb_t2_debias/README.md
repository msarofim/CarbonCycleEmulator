# QUARANTINE — outputs produced under `BOMB_T2_HIGH_BIAS = 1.20`

**Created 2026-09-09f**, when Marcus **reverted ruling 4** (the Tans Table-2 ÷1.20 Telegadas
high-bias de-biasing) back to **1.0**. See CHANGELOG 2026-09-09f and
`notes/handoff_2026-09-09c_ruling4_reverted.md`.

## 1. Which "bug" applies
Not a bug — a **reverted methodological choice**. Between commits `00e1749` and `0e4415b` the shipped
`data/forcing_bomb_c14.rds` divided Tans (1981) Table 2 by **1.20**, moving the pre/post-1963.04
delivery split **35.4 % → 46.1 %** and the t0 burden **65.92 → 54.94 kmol**. Any single-arm model
result produced in that window is on a **different model input** from the canonical and is NOT
comparable to anything produced before or after it.

## 2. Which files
| file | what it is | why quarantined |
|---|---|---|
| `gate5_bimodal_20260909.{rds,log}` | gate 5's NH double-peak features at `hilda31` | single arm, ÷1.20 — its trough reads **24.9** where the canonical reads **50.5** |
| `tg_gradient_level_gate_20260909.rds` | gate GL / gate H at three arms | single arm, ÷1.20 |
| `bomb_delivery_tail_20260909.{rds,log}` | the delivery-tail check | divisor-aware; recorded **1.20** |

## 3. Canonical post-revert replacements
Same basenames in **`outputs/diagnostics/`**, regenerated 2026-09-09f at divisor **1.0**. Compare
against those, never against these.

## 4. ⛔ What is NOT quarantined, and must not be
These carry **BOTH arms by construction** (or no model at all) and are the **provenance of the
decision itself**. They stay at canonical paths:
`bomb_debias_impact_20260909.rds`, `bomb_rep_sensitivity_20260909.rds`,
`debias_ocean_inventory_power_20260909.{rds,log}`, `debias_penalty_by_year_20260909.rds`,
`graven_vs_hua_20260909.rds` (pure observation comparison, no model).

## 5. Why kept rather than deleted
They are the regression test for the revert and the record of the correction's size. The ÷1.20 arm
is reachable in one env var — `CCX_BOMB_T2_BIAS=1.20 Rscript data-raw/build_bomb_c14_source.R` —
so these remain reproducible and are what a re-run should be checked against.

⭐ **VERIFIED 2026-09-09f, not merely claimed.** Round-tripped **1.0 → 1.20 → 1.0**: the 1.20 arm
rebuilds to burden **54.9362** kmol / λ **0.3490 /yr**, and rebuilding back at the default restores
**every data column identically** (burden 65.9234, λ 0.1996). The kept mechanism is genuinely
reversible in both directions.
