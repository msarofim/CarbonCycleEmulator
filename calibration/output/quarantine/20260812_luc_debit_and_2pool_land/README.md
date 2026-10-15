# Quarantine — 2026-08-12, LUC carbon/¹⁴C leak and the two-pool land

**Nothing in this directory may be quoted as a result.** Everything here was
produced by a model that (1) created carbon and ¹⁴C from nothing, and (2) had a
land structure that has since been replaced outright.

## 1. Which bugs apply

**(a) The LUC leak — a real bug, fixed on `luc-veg-debit` commit `98c1783`.**
Land-use-change emissions were emitted with `add_source()` into the atmosphere
while the vegetation box was left intact. LUC carbon is *inside* the modeled
biosphere (unlike fossil carbon, which is geological), so this created carbon
ex nihilo: **321.6 GtC** of phantom land carbon by 2024, and ~**28 kmol** of
¹⁴C by 1995 — 14–16 % of the system excess. After the fix the model is
carbon-conservative (total change 1750→2024 = 503.79 GtC against 504.67 GtC of
cumulative fossil, residual −0.88 GtC).

Consequence for these files: **`beta = 0.883` existed largely to absorb the
phantom carbon.** A post-fix mode-find is expected to put β near 0.25–0.30.

**(b) The two-pool land — a structural replacement, not a bug fix.**
These files were fitted with a single vegetation pool (`tau_veg`) and a single
responsive soil pool (`tau_soil`). That structure **cannot** hold Naegler &
Levin (2006)'s biosphere carbon (2200 PgC) and their bomb-¹⁴C inventory
(21.7 kmol at 1975) at the same time; it ran 51–58 % long on ¹⁴C. It was
replaced on 2026-08-12 by a four-pool land (leaf / wood / soil_fast /
soil_slow). **`tau_veg` and `tau_soil` no longer exist as parameters**, so
these fits are not merely stale — they are not loadable into the current model.
`R/cpp.R` raises an explicit error rather than silently substituting a land.

## 2. What is here

| file | what it was |
|---|---|
| `mode_fit.rds` | 2026-08-11 posterior mode, 17 parameters. Scored −2374.1 under the model that produced it; **−56,349.7** under the post-debit model. |
| `modefind.log` | its run log |
| `profile_bomb_total.rds`, `.log` | the `bomb_total` profile that railed at +4.5 σ — the rail was the *partition* error, not a data conflict |
| `profile_kz.log` | ventilation profile at the same parameters |

## 3. Canonical replacement

**There is none yet.** The post-fix mode-find has not been run — it is the next
calibration step (handoff `2026-08-12b` §7 step 4, re-scoped by the land
restructure). When it is run it writes to `calibration/output/mode_fit.rds` at
the canonical path, and this directory stays as provenance.

Diagnostics that need a parameter vector currently fall back to
`ccx_default_params()`, which is the honest behavior: `diag_bomb_partition.R`
prints `parameters: ccx_default_params() -- NO mode fit found`.

## 4. The two older quarantine directories are not equivalent

- `20260811_ar1_pathology_and_solver_wall/` — 18 parameters against today's 17;
  genuinely, visibly wrong.
- `20260811b_pre_excess_c14/` — **more dangerous, because it looks current**:
  same 17 parameters, same model. Its `logpost` −2359.3 must not be quoted.
