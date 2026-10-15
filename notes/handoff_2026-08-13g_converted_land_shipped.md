# Handoff — CarbonCycleEmulator, 2026-08-13 (g)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
at **`404d66d`** (still **not merged**). Suite **505 pass / 2 fail / 2 skip**, up from
490 / 4 — and *which* two stopped failing is §3.

Supersedes **13f §4** (the decision is taken and built). 13f §§1–3 stand as the diagnosis.
13e §§0.1–0.3, 0.5 and 13c §5's three ocean decisions are **still open and still Marcus'**;
12d §§2–8 and §10 continue to apply.

---

## 0. START HERE

1. **The converted-land term is BUILT, ON BY DEFAULT, and in DESIGN §3.3.** Land-use
   emissions no longer have an airborne fraction of 0.002 at 100 years.
2. **`f_luc_perm = 0` reproduces the bug exactly** and is tested. That is how the
   regression stays measurable; it is not a supported configuration.
3. **THE DEFAULT `beta` IS NOW WRONG BY CONSTRUCTION.** At 0.38 the model runs **+17.5 ppm
   high at 2024**, because 0.38 was re-centered on 2026-08-12 *against the bug*. The CO₂
   record's 1-D preferred β moves **0.30 → 0.50**. **Do not quote any absolute CO₂ number
   at the default parameters until a refit or at minimum a re-centering.**
4. **THE δ¹³C MISFIT GOT WORSE, as predicted in 13f §3 and now measured on a clean
   comparison:** the 1900→2020 Suess decline goes −2.209 → **−2.366 ‰**, 7.1 % faster,
   against a model already ~25 % too fast. **The 13b/13c ocean conclusions were measured on
   the defective model and must be re-measured before `sigma_d13c` or the deep-Δ¹⁴C target
   is settled on them.** That is now the top item.
5. **The MCMC has still never been run**, and `mode_fit.rds` now has *four* reasons to be
   stale: the pre-1850 LUC forcing, the un-recomputed pedagogical curves, the LUC-regrowth
   defect it was fitted to, and now the model that replaced it.

---

## 1. What was built

```
c(t) = f_luc_perm · cumLUC(t) / land0        NPP0 → NPP0(1−c),  veg0 → veg0(1−c)
```

**`land0` is TOTAL preindustrial land carbon — all four pools — and that is the whole
point.** Scaling NPP₀ scales *every* pool's equilibrium, so the land's equilibrium carbon
falls by `c · land0`; setting `c = cumLUC / land0` makes that fall equal what deforestation
removed. The debit is permanent **by construction**, which is why `f_luc_perm = 1` is a
mass-consistent point and not a fitted knob. **`veg0` would have shrunk the equilibrium by
a quarter of what was taken** and the land would have re-absorbed the rest.

`cumLUC` is a **forcing column**, not a state — so the C++ state dimension is untouched.
It accumulates **from the start of the emissions record, not the run window** (§4).

| where | what |
|---|---|
| `R/model.R` | `f_luc_perm`, `CCX_F_LUC_PERM_DEFAULT`, `CCX_LUC_CLEARED_MAX`, `aux$land0`, the term |
| `R/forcing.R` | `cum_luc_*` columns, `ccx_forcing_cum_luc()`, the windowed-run warning |
| `R/cpp.R`, `src/ccx_core.cpp` | mirror; `CCX_FORCING_COLS` 10 → 12, `N_FORCING` |
| `R/mechanisms.R` | the "no emissions" switch un-clears the land (§5.2) |
| `tests/testthat/test-luc-permanence.R` | the gate |
| `calibration/diag_1900_deficit.R` | rewritten around three arms, all isotopically honest |

---

## 2. What it does, measured

100 GtC pulse, zero-emission background, GMST and ENSO frozen, control flat to +0.027 ppm
over 275 yr. **No historical forcing, no observation, no fit.**

| AF at lag | 10 | 25 | 50 | 100 | 150 | 264 |
|---|---|---|---|---|---|---|
| fossil | 0.605 | 0.445 | 0.337 | **0.262** | 0.226 | 0.180 |
| LUC, `f_luc_perm = 0` | 0.577 | 0.260 | 0.072 | **0.002** | −0.003 | −0.001 |
| LUC, shipped | 0.646 | 0.362 | 0.193 | **0.130** | 0.127 | 0.131 |

**THE INDEPENDENT CHECK NOBODY AIMED AT.** Cumulative partition 1750–2024, GtC:

| | atm | land | ocean |
|---|---|---|---|
| `f_luc_perm = 0` | +300.5 | **+29.4** | +169.1 |
| shipped | +350.5 | **−53.6** | +202.2 |
| **GCB 2025** | +311.8 | **−57.4** | +209.8 |

The fix was derived from the pulse argument and from GCB's own column layout (E_LUC and
S_LAND are separate terms). **That it lands the partition on GCB is a result, not a
target** — and the land's *sign* was wrong before it.

### Why ~50 % and not 100 % — tested, not argued

The debit lands on **wood** (37 yr, per Marcus 2026-08-12: deforestation removes standing
woody biomass and the emitted carbon should carry that pool's lagged ¹⁴C) while the
equilibrium reduction is **pro rata**, 70 % of it in a 500-yr passive soil. Predicted
consequence: shorten that pool and the ratio should go to 1.

| ratio to fossil, at lag | 10 | 25 | 50 | 100 | 150 | 264 |
|---|---|---|---|---|---|---|
| `tau_soil_slow = 500` (default) | 1.07 | 0.81 | 0.57 | **0.50** | 0.56 | 0.72 |
| `tau_soil_slow = 20` | 1.29 | 1.22 | 1.11 | **1.02** | 1.01 | 1.01 |

**Confirmed.** Exactly permanent in the infinite-time limit; ~half on a century.
**Closing the remainder means debiting the pools PRO RATA**, which trades against the
2026-08-12 wood-¹⁴C call. **That is a decision for Marcus and I have not taken it.** The
honest framing: the residual is a *legacy* — fast regrowth against slow soil drainage — and
whether the model should have one at all is the question.

---

## 3. TWO SUITE FAILURES WERE NEVER A STALE FIXTURE

`test-likelihood.R:114/117` — "a CO₂ level bias is expensive" — were recorded as a stale
AR(1)-era fixture in handoffs **12d, 13, 13b, 13c and 13e**. They now pass, and the link is
**causal, not coincidental**: at `f_luc_perm = 0` the test's own quantity is
**`cost(+1 ppm) = −183.1`** — adding a positive bias *improved* the fit, because the model
was systematically low — and at `f_luc_perm = 1` it is **+534.5**.

**The suite had been reporting this bug since the day it landed, and the report was
relabeled five times.** A failing test you have explained away is still data. The two
remaining failures (`test-climate.R:122`, 0.092 against a 0.1 threshold;
`test-mechanisms.R:32`, 0.29 against 0.5) are **still uninvestigated and should now be
treated as claims rather than as furniture.**

---

## 4. Non-obvious state — read before writing a driver

- **A window that starts mid-record no longer begins at a fixed point.** `ccx_spinup()`
  returns preindustrial land; a run starting in 1900 hands it a land whose equilibrium has
  already shrunk by 88 GtC of clearing, so it relaxes and carries a start-up transient
  **that is not in the emissions**. `ccx_build_forcing()` now **warns**
  (`FORC_LUC_PRE_WARN` = 5 GtC). The **48 warnings in a suite run are all real.** Comparison
  runs where both arms share the transient are unaffected; absolute numbers are not.
- **A forcing with LUC emissions and no `cum_luc` is an ERROR**, not a zero-default.
  Defaulting it would restore the bug through a code path nobody chose.
- **`ccx_spinup()` is untouched and every pre-2026-08-13 spinup result is bit-identical**:
  its zero forcing has no LUC flux, so the cleared fraction is zero.
- **`CCX_LUC_CLEARED_MAX` (R) and `LUC_CLEARED_MAX` (C++) are duplicated and NOTHING
  catches a disagreement.** If one moves the other must move in the same commit. The
  forcing *column count* is caught (`ccx_cpp_forcing()`'s name check + the contract test).
- **The parity fixtures carry a NON-ZERO `cum_luc`** deliberately: at zero the new term
  collapses to `(1 − 0)` and the gate would be inert.
- The `emissions` mechanism switch now zeroes `cum_luc` too — see §5.2.
- Everything in 12d §§2–8 and §10 still applies.

---

## 5. Two holes this closed on its way in, both real

1. **`quiet_forcing()` in `test-conveyor.R`** zeroed the LUC *flux* and not the LUC
   *stock*, which asks the model to relax a pristine spinup toward a smaller land. The
   conveyor tests would have read that drift as a conveyor failure.
2. **The `emissions` mechanism switch had the same hole, and it is user-facing.** "What if
   we had never emitted" would have left the land relaxing toward an equilibrium shrunk by
   ~290 GtC of clearing the counterfactual never did. `test-mechanisms.R:54` caught it.

---

## 6. What to do next, in order

1. **Re-measure the δ¹³C and ocean diagnostics on the fixed model** — `diag_d13c_suess.R`,
   `diag_oceanic_suess.R`, `diag_conveyor.R`. 13b/13c's numbers, including the "atmosphere
   21–25 % too fast" headline and the whole `sigma_d13c` argument, were measured on a model
   with part of its Suess forcing switched off. **Do not settle the three ocean decisions on
   the old numbers.**
2. **Re-center `beta`** (or accept that defaults are provisional until the refit). +17.5 ppm
   at 2024 is not a fixture anyone should build an app panel on.
3. **Decide the pro-rata question** (§2) — it is the difference between a 0.5× and a 1×
   land-use airborne fraction on the century that matters most for the app.
4. Then the refit, once §1's re-measurement has informed the deep-Δ¹⁴C target.

## 7. Commits

| | |
|---|---|
| `6733f9c` | The 1900 deficit diagnosed: land-use carbon has an airborne fraction of zero |
| `404d66d` | The converted-land term: the land-use debit is made permanent |

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-13g_converted_land_shipped.md`, then
> `notes/handoff_2026-08-13f_luc_regrowth_double_count.md` for the diagnosis and
> `notes/handoff_2026-08-13e_marcus_directives.md` for the rest of the open state, on branch
> `luc-veg-debit`. **The land-use debit is now permanent, which made the δ¹³C misfit ~7 %
> worse and left the default `beta` +17.5 ppm high at 2024 — so re-measure the 13b/13c ocean
> diagnostics on the fixed model BEFORE settling `sigma_d13c` or the deep-Δ¹⁴C target.**
> One new decision is Marcus': whether the LUC debit should be taken pro rata across pools
> (airborne fraction 1× rather than 0.5× at 100 yr) at the cost of the 2026-08-12 call that
> the emitted carbon carries wood's ¹⁴C.
