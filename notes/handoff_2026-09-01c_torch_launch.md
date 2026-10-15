# Handoff — CarbonCycleEmulator, 2026-09-01c
# **LAUNCH THE TORCH DISPERSED MULTI-START. THE BUNDLE IS RE-CUT FOR 25 PARAMETERS.**
# **Everything is preflighted on the Mac; the remaining steps need Marcus's VPN, Duo and password.**
# **Read §2 before submitting anything — one decision is owed first.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at **`778baa3`**.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use
`git -C <abspath>`.

**Suite 1365 / 6 FAIL / 2 skip** — the same six as before every change in this arc (see §6).
**Nothing is adopted.** `CCX_MODE_CANONICAL` is untouched.

**Read first:** `calibration/torch/README.md` — it carries the experiment's design, the four choices
it makes, the partition analysis and the full command list. **This file does not repeat it.** Read
`handoff_2026-09-01b_enso_four_param_implementation.md` for what changed in the model.

---

## 0. STATE IN SIX LINES

1. ✅ **The bundle is RE-CUT for 25 parameters and rebuilt** — `/tmp/ccx_torch_bundle.tar.gz`, **2.1 MB** (`du -h` rounds it to 3.0M — that is allocated blocks, not the file).
   `port_targets.csv` is regenerated at commit `778baa3`'s parent `53ef03d`, `n_par = 25`. §1
2. ✅ **Preflighted for ids 0, 1, 2, 3, 7.** PORT GATE (a) verified to **rel 4.5e-15** on the
   reference machine. The whole chain — migrate, encode, gate, draw — runs at 25. §1
3. ⚠ **ONE DECISION IS OWED BEFORE SUBMITTING: 40 starts in 25 dimensions, or more?** §2
4. ⭐ **The split cost the objective NOTHING at either reference point** — both logposts moved by
   *exactly* the prior-split constant, residual 3e−7. §3
5. ⛔ **Both reference points are MIGRATED vectors, so neither is a mode of this space** — there is a
   measured uphill direction at each. It does not block the survey, and it means a serial
   25-parameter polish can run on the Mac **in parallel**. §4
6. ⚠ **Do NOT reuse `calibration/output/multistart_20260831/` for a different parameter set.** The
   resume now refuses a stale checkpoint, but a fresh `CCX_MS_OUTDIR` is the clean answer. §5

---

## 1. WHAT IS READY, AND WHAT WAS STALE

The bundle was staged 08-31f for a **22-parameter** build. The ENSO split (22 → 25, `71155ad`)
landed after it.

| piece | was | now |
|---|---|---|
| `port_targets.csv` | `n_par = 22`, commit `3346ded` | **`n_par = 25`, commit `53ef03d`** |
| dispersion sd | 1.0493 | **0.9592** (recomputed at every run; see §3) |
| `run_dispersed_multistart.R` | — | **unchanged and correct** — it already migrates both reference points |
| tarball | staged 08-31f | **rebuilt, 2.1 MB** |

⭐ **The stale CSV would have been CAUGHT, not silently used.** The port gate refuses a target
recorded on a different parameter count — "The target is stale" — killing every task about two
seconds in. That is the gate doing exactly the job it was built for; it is worth knowing it fired in
rehearsal rather than in the array.

**Preflight, run on the Mac (this is the real code path, not a copy of it):**

```bash
for id in 0 1 2 3 7; do CCX_MS_PREFLIGHT=1 CCX_MS_ID=$id Rscript calibration/run_dispersed_multistart.R; done
```

All five printed `PORT GATE (a) PASSED` and `port VERIFIED rel 4.5e-15`. ⚠ On the Mac that gate is
near-tautological — it compares the machine against itself. **Its real test is the first Torch task,
and that is the whole reason to submit ids 0–2 first.**

## 2. ⚠ THE DECISION OWED BEFORE SUBMITTING

**N = 40 starts was chosen for a 22-dimensional space and is the one choice in the bundle with no
measurement behind it** (the README says so). The space is now **25-dimensional**. Nothing about the
survey breaks at 40; it is simply sparser, and the same fairshare argument that set it applies.

**What is measured and bears on the choice:**
- The four new coordinates are the **SOFTEST in the space** — diagonal conditional sd 0.10–0.16 in
  u, against 0.0022 for `luc_scale`. At the shipped dispersion they get **6–9 sds** where the
  stiffest coordinates get **325–430**. So the new directions are the *cheapest* part of the search,
  not the expensive part.
- Nelder-Mead's simplex is now **26 vertices**, so each task converges less far in its 180 min than
  the 22-dimensional design assumed. **Checkpoint/resume is how you buy that back** — re-submitting
  the same array continues each task.

⇒ **My reading, for Marcus to accept or override: keep N = 40 for round 1 and plan on a second
submission of the same array rather than a larger first one.** Resume is tested and costs ~2 min of
R startup per round; a wider array costs fairshare up front and cannot be narrowed later.

## 3. ⭐ THE SPLIT COST THE OBJECTIVE NOTHING — MEASURED ON THE OBJECTIVE ITSELF

|  | 22-par offset | 25-par offset | shift | analytic prior-split | residual |
|---|---|---|---|---|---|
| incumbent | +0.8125 | −3.9643 | **−4.7768** | **−4.7768** | 3e−7 |
| new basin | +0.7364 | −4.0379 | **−4.7743** | **−4.7743** | 3e−7 |

The analytic shift is replacing one `N(0, 2)` prior term with four, evaluated at the migrated point.
**The residual is the precision of `gamma_enso` as printed, not a discrepancy.**

⇒ **The likelihood at both reference points is untouched.** That is a stronger statement of the
split's behavior-preserving default than the trajectory bit-identity test in `test-enso-split.R`,
because it covers the whole objective rather than two output columns.

**And the dispersion scale moved for a bookkeeping reason, not a physical one.** 1.0493 → 0.9592,
because the two known basins differ by 0.01 in the two land coordinates and by **exactly 0** in the
two ocean ones — neither file has an ocean term — so four near-identical coordinates dilute the
per-coordinate RMS by exactly **√(21/25) = 0.9165**. Over the 21 shared coordinates the separation is
**1.0466**, essentially what it always was. ⚠ **The survey's dispersion therefore carries no
information about how far apart basins can be in the ENSO directions.** Nothing to fix — but do not
read 0.9592 as "the basins got closer".

## 4. ⛔ NEITHER REFERENCE POINT IS A MODE OF THIS SPACE

Both are **migrated 21-parameter vectors** with the ocean ENSO pair at 0, and
`diag_enso_objective_leverage.R` measures a strictly uphill direction at each: the ocean pair is
worth **+1.98** at the new basin after re-optimizing a 3-parameter carbon slice, with a conditional
optimum near **+0.10 in each hemisphere**.

**This does not block the survey.** Reference points are start points and port-gate anchors, not
claims about optima, and the survey disperses about the COLD init in any case.

⇒ **It does mean the survey and a serial 25-parameter polish answer different questions and should
run in parallel.** The survey asks "is there a third basin"; the polish asks "where does *this*
basin go now that the ocean term exists". The polish is a Mac job:

```bash
Rscript calibration/run_modefind_pump_arms.R
```

It warm-starts from `par_mode` through `ccx_migrate_par_set()` and prints what it filled.
⚠ **Do not warm-start by decoding `u_mode`** — a 21-length vector in a 25-parameter build.

## 5. ⚠ NON-OBVIOUS STATE

- ⚠ **`calibration/output/multistart_20260831/` is EMPTY and its name is a date, not a parameter
  set.** Checkpoints now record `param_names` and the resume **refuses** one written under a
  different set (mutation-tested — both the wrong-set and the no-field-recorded refusals fire with
  the reason). Still: **use a fresh `CCX_MS_OUTDIR` for a new parameter set** rather than relying on
  the guard.
- ⚠ **`sinfo -o "%P %l %m %c"` is still unrun.** The README's partition analysis rests on `cs`'s
  wall limit being unknown. One command settles it, and the answer only matters for a possible
  phase 2 (long climbs on the best few), not for round 1.
- ⚠ **The app has been shipping UNCALIBRATED DEFAULTS since 08-31, and NOT because of the ENSO
  split.** `app/global.R` skips any mode whose `param_names` differ and the canonical mode is a
  **21-parameter** file. It could migrate and say so; left as a separate decision.
- ⚠ **`ccx_require_param_set()` replaced EIGHT bare `stopifnot(identical(md$param_names, …))`.** The
  refusal is unchanged; it now names the retired and missing parameters. Those eight diagnostics are
  still refusals, deliberately — a Hessian or a ridge measured at a MIGRATED point is not the fitted
  one.
- **Everything in `handoff_2026-08-31f` §8/§9 still stands**: `kz` bracket **[4379.1, 8109.9]**,
  `test-likelihood.R:587` fails deliberately (8109.9 against a stale 7000 ceiling).

## 6. THE SIX SUITE FAILURES, UNCHANGED

`test-likelihood.R:587` is the deliberate `kz`-bracket failure. `test-mode-decode.R` ×2 and
`test-mode-file.R` ×3 all say one true thing — **the stored modes are on an older parameter set** —
and the owed refit resolves them. The count in their messages moved 22 → 25.

## 7. THE LAUNCH, IN ORDER

⚠ **Claude cannot do any of this**: Torch needs the NYU VPN, the gateway password, Duo, and a
Microsoft device-code at `login.torch`. **Full command list is in `calibration/torch/README.md`;
this is the order, not a replacement for it.**

1. **Ship it.** The tarball is already built at `/tmp/ccx_torch_bundle.tar.gz` (2.1 MB). If the repo
   has moved since, rebuild with `bash calibration/torch/make_bundle.sh` — **it re-runs nothing
   else, so re-run `Rscript calibration/make_port_targets.R` FIRST if the parameter table changed.**
2. **`bash calibration/torch/setup_torch.sh`** on the cluster (once).
3. **Submit ids 0–2 ONLY**: `sbatch --array=0-2 calibration/torch/multistart.sbatch`. These are the
   three reference starts, and they are what actually tests the port. **Wait for exit 0 and real
   output files before any larger array.**
4. **Read PORT GATE (a) in their logs.** A mismatch there is the one result that must stop
   everything: it means Torch does not reproduce the Mac's objective, and every number the survey
   would produce is unreadable. It is not a reason to widen a tolerance.
5. **Then the array**: `sbatch --array=3-42 calibration/torch/multistart.sbatch`.
6. **Re-submit the same array to continue** any task that reports `OUT OF TIME` — that is a clean
   exit 0 with a checkpoint, never a SLURM kill.
7. **In parallel, on the Mac**: the serial 25-parameter polish (§4).

## 8. NEXT, AFTER THE SURVEY LANDS

1. **Collect and compare** the `start_*.rds` files; is there a third basin, and does it beat −1496?
2. **Adopt** — `run_post_refit_adoption.R`, which refuses anything not on this parameter set.
3. **Ratify the ENSO prior** (`handoff_2026-09-01b` §5) — each of the four keeps N(0, 2), which
   widens the implied prior on the land TOTAL by √2. **Still the only open methodological choice.**
4. **Re-run `diag_enso_ocean_term_design.R`** before quoting its growth percentages: its slope
   arithmetic is sound but the two PARAMETER values it named were slope quantities, corrected 09-01j
   (land ×1.734 not ×1.89; ocean **+0.653 total**, not +0.274 — a factor 2.4).
5. **A profile or Hessian on the four**, which is what turns structural identifiability into
   demonstrated precision.
6. Still open from 08-31f: the polished mode's adoption, after the survey.
