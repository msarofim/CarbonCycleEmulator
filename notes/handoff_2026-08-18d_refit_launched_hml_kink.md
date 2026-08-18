# Handoff — CarbonCycleEmulator, 2026-08-18d: THE HOLD IS RELEASED AND THE 21-PARAMETER TWO-ARM REFIT IS RUNNING. The pre-flight Hessian check kept `ARM_HESS_EPS` and found a KINK in `h_ml`.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, tree clean.
**HEAD = `1448681`.** Continues `handoff_2026-08-18c_priority_rework_drivers.md` — that note's
§5.1 (THE REFIT) is now IN FLIGHT; everything else in its §5 still stands.

## 0. START HERE

1. **THE REFIT IS RUNNING.** Launched 2026-08-18 from this session. **~10-12 h, two arms
   sequential (N then D).** Log: `calibration/output/pump_arms/refit_20260818.log`. Each arm
   writes its own `mode_fit_pump{N,D}.rds` as it finishes, so a kill after arm N loses only D.
2. **Marcus released the hold with one condition — check `ARM_HESS_EPS` at 21 parameters
   first.** Done (`calibration/diag_hess_eps_21par.R`). **The step is KEPT.** See §1.
3. **NOTHING IS QUOTABLE YET.** The objective and the model both changed on 08-18; the modes
   in `pump_arms/` from before today are on a DIFFERENT function. Do not compare across the
   08-18 boundary, and do not read `mode_fit_pumpN.rds` as current until the run overwrites it.
4. **Parameters are 21**, not the 19 that 18c's §5.1 says — that line predates the two SST
   commits (`6fadb34`, `98fd871`). 18c §0.3 has it right.
5. Suite at launch: **FAIL 0 | WARN 55 | SKIP 2 | PASS 889.**

## 1. The pre-flight check: `ARM_HESS_EPS = 3e-4` SURVIVES

**Why it mattered enough to delay an 11 h run by an hour.** The two-arm comparison's primary
statistic is a Laplace evidence, and the term a MAP-only comparison drops, `-0.5 log|-H|`, comes
from ONE fixed finite-difference step. The driver does not sweep it: a non-PD Hessian degrades
that arm's evidence to `NA`. Three things had changed since 3e-4 was last exercised — 18 → 21
parameters (six coordinates that did not previously exist); `rep_dC` on the IDENTITY scale, the
smallest curvature in the table and so the roundoff-vulnerable case; and `h_ml` bounded to
[85, 120], a logit support 4.9× narrower than the shipped [30, 200], i.e. a **different
unconstrained scale** — and a step size is a statement about a scale.

**Method.** No mode exists on the new model, so the sweep runs at TWO points rather than guessing
one: `init` (where both arms start) and `lifted` (the adopted arm-N mode's 15 surviving parameters
+ defaults for the 6 new ones — not a mode of anything, but physically different in the 15
directions carrying most of the curvature). Six steps, 1e-5 to 3e-3. Failing at either
disqualifies for 1 minute instead of 11 hours; passing at both is not proof it holds at the mode.

**VERDICT: KEEP 3e-4.** Inside a stable window at both points for every coordinate whose curvature
is a step-size question — 18/21 at `init`, 19/21 at `lifted`. **The exclusions are named, not
swept**: `sst_seas_amp_NH` (both) and `pump_grad` (init) have POSITIVE, step-STABLE curvature,
which means only that neither probe point is a maximum in that direction. The first draft of the
verdict called those step-size failures; that was a category error and the table now splits the
two. **The 1e-5 end is genuinely bad — it moves `gamma_enso` 7× and flips the sign of `kz`.**

## 2. THE FINDING: `h_ml` is a KINK, and no step size fixes a kink

`h_ml`'s second difference scales as **1/eps across six decades** (−170,900 at 1e-5 → −578 at
3e-3, factor 3.0 per factor 3.0 of step). **The scaling law IS the diagnosis**: 1/eps² would be a
jump in the VALUE, no scaling at all would be roundoff, **1/eps is a continuous function with a
discontinuous FIRST derivative.** Confirmed directly — the one-sided slopes at h_ml = 100 are
**−16.21 / −17.92**, each stable over the whole grid.

**Source: `ccx_pump_shape()`, and it is NOT a bug.** The 25 m GLODAP DIC bins are remapped onto
model layers by overlap integration, `pmax(0, pmin(b, bot) - pmax(a, top))` — the conservative,
correct way to do it. But **`h_ml` IS the first layer boundary**, so as it moves the clamp switches
against fixed observed bin edges, and a clamped overlap is a |x|.

**It reaches the ISOTOPES and not CO2** — the constant-mass pump's own signature, the same channel
as the pump × advection reversal. `d13c_level_MLO`/`_SPO` carry **−0.153 / −0.115** of the −0.270
total slope jump; `co2_level` carries −5e-4.

**Sparse, which is why it is a caveat and not a blocker.** Exactly **three kinks in [85, 120] —
98.41, 100.00, 101.29 m** (5 of 3499 probe points), being the first three layer boundaries
crossing the 100 / 150 / 225 m bin edges. `ARM_HESS_EPS` reaches ~2e-3 m of `h_ml`, so a mode must
land within ~2 mm of one to contaminate the row.

**`ARM_HML_INIT = 100` sits EXACTLY on the largest kink** (it is the pump's own reference depth).
**Left at 100 deliberately** — Nelder-Mead is derivative-free, so a start point's differentiability
is irrelevant, and moving it would change the trajectory for no gain.

## 3. What was NOT done — a choice, not an oversight

**The model was not touched.** Smoothing the remap (PCHIP through bin midpoints instead of overlap
averaging) would make the objective C1 in `h_ml`, but it changes the **pump field** — i.e. the
model — on the eve of a refit, to remove a risk of order 1e-4. **Rejected. Standing item for
Marcus, not actioned.** If he wants it, it is a structural change and the refit would have to be
redone.

## 4. Driver hardening (all above the objective, so nothing is invalidated)

`run_modefind_pump_arms.R`:
1. The kink list is **DERIVED in-process** from `ccx_pump_shape()`, never typed, so it cannot drift
   from the code that creates the kinks. A count ≠ 3 prints a re-run warning.
2. **Kink-proximity check at the found mode**, with `ARM_HESS_EPS` converted from the unconstrained
   scale to **metres at wherever in the band the mode actually sits** (2.06e-3 m at h_ml 94.36,
   2.57e-3 m at 100 — the logit scale position matters). A straddle prints loudly that this arm's
   `log|-H|` and Laplace evidence are unreliable.
3. **Diagonal step-stability re-measured AT the mode** (eps × 1/3, 1, 3). The pre-refit sweep could
   only run at non-modes; this is the same test at the point that carries the evidence. Unstable
   coordinates are NAMED rather than silently entering the determinant.
4. Recorded into each arm's rds: `hess_eps`, `hess_diag_by_step`, `hess_unstable`, `hml_kinks`,
   `hml_kink_gap`, `hml_hess_reach`, `hml_kink_hit`.

**The proximity check is MUTATION-TESTED, not merely observed not to fire**: clear at h_ml = 94.36
(gap 4.05 m), fires at h_ml = 100.00. Per the 18b lesson — a gate that has never fired is a gate
that has never been tested.

## 5. Reading the run when it lands — IN THIS ORDER

1. **The per-stream table BEFORE the evidence** (18c/16g's standing instruction). The question the
   `h_ml` bound was imposed to answer: do `co2_level_SPO`/`_MLO` recover with `h_ml` in-band? If
   they stay large in BOTH arms, both modes are bad and N-vs-D is uninformative again.
2. **The two new watch-items from 18c §5.1**: `seas_T_amp_NH` should CLIMB (amp 5.0 → ~3.0 needs a
   stronger respiration counter-cycle) and `q10` now has seasonal duty — its linear part is absorbed
   by `seas_T_amp`, the nonlinear part is q10's own.
3. **The SST apportioning**: at defaults the ocean term opposes the NH land cycle (MLO 4.77 → 4.41
   vs obs 3.02) and adds at SPO (0.90 → 1.09 vs obs 0.55). Apportioning land vs ocean was the
   refit's job; check it did it rather than zeroing one side.
4. **THEN the evidence** — and check `hml_kink_hit` and `hess_unstable` first. A kink hit means
   that arm has no reliable `log|-H|`, so no Laplace evidence, and the comparison falls back to the
   per-stream reading.
5. The standing caveat is unchanged: `kz` pinned + both arms capped ⇒ the evidence is
   **INDICATIVE**, not a Bayes factor to quote.

## 6. Everything still queued behind the refit

Unchanged from 18c §5.3: defaults-vs-mode bar derivation gap; gate 12 has no test; σ-inflation
spec; `kz` bracket; pilot MCMC barrier question; DESIGN §5.4 products. Plus, new today: the
**pump-shape smoothing question** (§3), and **land-T into q10** (18c §5.2 — CRUTEM5 ratios measured
and MANIFESTED, NH 1.54, wiring NOT done, a further structural change and not ordered).

## 7. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-18d_refit_launched_hml_kink.md`. The 21-parameter two-arm refit was
> launched 2026-08-18; check `calibration/output/pump_arms/refit_20260818.log` and the two
> `mode_fit_pump{N,D}.rds` first. **Read the per-stream table BEFORE the evidence, and check
> `hml_kink_hit` / `hess_unstable` before trusting `log|-H|`.** Nothing from before 08-18 is
> comparable.
