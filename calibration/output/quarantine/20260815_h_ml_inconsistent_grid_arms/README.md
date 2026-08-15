# Quarantined 2026-08-15 — the first h_ml decomposition was INVALID BY DESIGN

## The bug

`diag_h_ml_roles.R`'s original three arms drove h_ml's two roles at different depths by
building a grid whose `h_ml` (→ `aux$ml_mass_kg`, the chemistry's capacity) and `dz[0]`
(→ the diffusive gradient) disagreed:

```
BOTH     capacity = h,     geometry = h        <- the real model, VALID
CAPACITY capacity = h,     geometry = h_ref    <- INVALID
EXPORT   capacity = h_ref, geometry = h        <- INVALID
```

**`ml_mass_kg` and `dz[0]` are not two independent knobs — they are two encodings of the same
quantity.** The core (`src/ccx_core.cpp`) computes the chemistry's concentration as
`dic_ml = y_ml * mol_per_GtC / ml_mass_kg` and the diffusion's as `y_ml / dz[0]`. Both are "the
mixed layer's carbon per unit depth". Making them disagree does not decompose a mechanism; it
makes *mixed-layer concentration* mean two different things in two parts of the same timestep.

## How it announced itself

At the MAP mode's other parameters, h = 184 m:

| arm | Δ log-lik vs h = 75 |
|---|---|
| BOTH | **+425.9** |
| CAPACITY | −26,203.8 |
| EXPORT | −29,035.3 |
| implied interaction | **+55,664.9** |

An interaction 130× the effect being decomposed. Per `~/.claude/CLAUDE.md` ("implausible
result = bug"; "suspicious uniformity ≈ bug signal") this was diagnosed rather than
interpreted, and the sign pattern confirms it exactly:

- **CAPACITY arm** — 2.45× the ML carbon divided by an unchanged `dz[0] = 75` ⇒ a spurious
  downward gradient ⇒ over-ventilation. Observed: deep Δ¹⁴C −216 vs −161 at reference, ocean
  sink 4.84 vs 2.87 GtC/yr.
- **EXPORT arm** — 75 m-worth of ML carbon divided by `dz[0] = 184` ⇒ a spuriously weak
  gradient ⇒ under-ventilation. Observed: deep Δ¹⁴C −133, sink 1.53.

Both are the artefact, in the direction the artefact predicts. Neither is physics.

## A second, smaller defect in the same file

`total_no_deep` filtered on a stream named `d14c_deep`; the actual stream is
**`d14c_deep_ocean`**. The deep-Δ¹⁴C confound control was a silent no-op — `d_total_nd` is
identical to `d_total` in every row above. Caught by the two columns being equal everywhere,
which is why the diagnostic printed both.

## What replaced it

`calibration/diag_h_ml_roles.R` (rewritten, same path) — a design using only **consistent**
grids. It reads the two channels' *signs* off the grid, confirms the mechanism *positively* by
asking where the extra carbon is stored, and uses `kz` as the model's genuine pure-export knob.
Conclusions in the 2026-08-15 CHANGELOG entry. The `BOTH` arm above is valid and its numbers
reproduce in the replacement.
