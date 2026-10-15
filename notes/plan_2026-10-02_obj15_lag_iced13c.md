# PLAN 2026-10-02 — the ENSO lag (`L_MEI`), the Law Dome rows, the gate repairs, and one refit

**Rulings:** CHANGELOG 10-02 (z) carries them verbatim. Diagnosis: 10-02 (x). Audit: 10-02 (y) and
`notes/audit_2026-10-02_design_vs_build.md`.
**State at writing:**
- canonical `hilda33d`, objective #14, label `hilda_csl3v0kaidgb`, logpost −1405.411447;
- the app previews at localhost:7788 (`ccx-app`).
- Marcus's `carbotopecomment*.docx` files are untracked and his; `carbotopecomments.10.2.26.docx` is new and not yet
  read.

## What gets built (W1–W5), then one refit

### W1 — `L_MEI`: a fitted lag on the LAND ENSO term (DESIGN §3.3, §5.1)
- **Semantics.**
  - The land term reads Niño 3.4 at t − L, and every ocean channel keeps reading it at t.
  - L is in months, prior U(0, 12) (DESIGN), carried as `logit` on (0, 12).
  - **Absent = 0 = today's model, bit-identical.**
  - One lag for both hemispheres, as designed.
- **Numerics (my choice; it can be overruled).**
  - The fractional lag uses **C¹ cubic-Hermite (Catmull-Rom) interpolation** of the monthly index. Linear
    interpolation is kinked at integer L, which hurts the BFGS polish and the Hessian's plateau search.
  - The init is the prior midpoint, **6 months**. Precedent forbids an init taken from a screen (calibrate.R:1067-71),
    which rules out using 10-02 (x)'s 5 months.
- **Where (code map, 10-02).**
  - The land term: `R/model.R:2555-2556` and `src/ccx_core.cpp:641`.
  - The same `forc$enso` feeds six ocean reads, so the land term needs its OWN input:
    - R: `forc$enso_land`, which falls back to `forc$enso`;
    - C++: an extra `deriv()` argument, so `N_FORCING` stays 19.
  - The lagged series is computed when a run is prepared, from the forcing's `enso` column plus pre-history.
  - Requirements:
    - the single-derivative entry points (`ccx_deriv`, `ccx_deriv_cpp`) take the lagged value;
    - an explicit guard for `i − k − 1 < 0`;
    - `ccx_flux_trace` uses the same series;
    - **segment runs keep the pre-segment history** (`ccx_irf_pd` joos_irf.R:141-147, app/R/review.R:372,
      test-enso-split.R:198);
    - the What-if ENSO switch zeroes the land input too.
- **Registration.**
  - `CCX_PARAM_TABLE` and `.CCX_PARAM_ORDER`;
  - a `ccx_default_params()` slot. Without it the fitted value never reaches the model, and nothing errors;
  - the `ccx_cpp_par` default and whitelist, and the C++ `Par` / `unpack_par`;
  - the migration absence contract;
  - `APP_PARAM_META` and the app's `gated_fit`.
- **Gate mechanism.**
  - The label gate (09-30 p) is one flag over ONE all-or-nothing set: the four D2/D3 names. Adding the lag to that
    set breaks `hilda33d`, because its own label opens the gate but it lacks the new name.
  - ⇒ **Generalize to several gates, one flag and one set each.** That touches ~14 sites: calibrate.R 1088-1285,
    1584, 1700, 2683; model.R:598; paths.R:655; params_meta.R:166; global.R:287.
  - A new label chained from `kaidgb` opens both gates. Extend `GP_OPEN_LABELS` and the four label ledgers.
- **Tests**, from the templates `test-npp-tsens.R`, `test-ndep.R`, `test-l2-enso-limb.R`:
  - OFF is `identical()`;
  - R↔C++ parity at L ≠ 0 and at absence;
  - trajectory and conservation;
  - **exactness: at an integer L the land flux equals a run whose land index is shifted by L months**;
  - segment history;
  - the ENSO switch zeroes the land input;
  - every gate and test mutation-tested.
  - ⚠ The land coefficients default to 0, so a test at defaults has no power. Use nonzero γ and a window past 1948.
- **Stale items to fix on the way:**
  - ccx_core.cpp:1386 ("n × 10") and :517-520 (the layout omits the ndep columns);
  - R/cpp.R's "unpacks as garbage" (it actually throws);
  - CHANGELOG 09-30 (p)'s `ccx_overlay_par` refusal, removed 10-01.

### W2 — the Law Dome ice-core δ¹³C row (ruled: add)
- The data are `ice$d13c_samples` (105 samples, Rubino et al. 2019). They are already loaded; today only
  `diag_d13c_midcentury.R` and `fig_model_vs_obs.R` read them.
- The model series is the **SH box**, like `co2_icecore` since 08-22 (Law Dome is at 66.7 °S).
- **To settle with Marcus before launch:**
  - **the σ**: Rubino's stated uncertainty plus a representation error for a 2-box atmosphere, with numbers;
  - **circularity with the pre-industrial δ¹³C anchor**: if `D13C_PI` (−6.469) comes from Law Dome, the
    pre-industrial samples are already used once;
  - the end year (DESIGN: "pre-1990").

### W3 — ice-core CO₂ cut to pre-1958 (ruled)
- `co2_icecore` scores only samples with year < 1958, as DESIGN §4 has it; the South Pole station row covers
  1957 onward.
- Then remove the comment block in `R/likelihood.R` (~2133) that defends the 52 post-1958 rows.

### W4 — gate repairs before the new mode is scored (ruled: all four)
- **Gates 6 and 11.**
  - Move them onto `dg_vector()` and the canonical: its own spinup, and the HILDA/seas_ml structure.
  - Add them to `DG_LEDGER` and the scorecard.
  - Re-derive gate 6's bound from the observation (`threshold_from_obs_or_law`). The typed one-sided 0.15 is cleared
    by the observation itself by only 0.6 pp.
  - Gate 11 must cover "all residual series", as DESIGN says.
- **P7.** Mixed layer ON vs OFF **within the same vector**, as `test-gate-p7.R` has done since 09-21 g.
- **Gate 7.** Target GCB + s·I(t), as objective #14's sink rows do (`dg_gcb_target()`). Also fix the stale "1.50"
  land-σ text, which is 0.5 since #12.
- **Gate 5.** Put the post-peak e-folding and the peak heights into the verdict, with bounds whose provenance is
  stated.
- Add a `DG_LEDGER` row for gate D. Mutation-test every repaired gate.

### W5 — cite the two `[VERIFY]` priors (`k_w`, `tau_ex`; audit C1)
- In progress (literature). A changed value is an objective change, so Marcus rules on it.

## Objective #15 and the refit — open choices for Marcus

| # | choice | my recommendation |
|---|---|---|
| D1 | Do W2/W3/W5 apply to **every label** (objective #15, the registry restamped at priced moves, old copies quarantined) or only to the new label? | ✅ **RULED 10-02: "Every version, as objective #15".** Price each registered mode's move, restamp it, and quarantine the old copies (with a README). |
| D2 | Run a **lag-0 control arm** (the new objective, lag gate closed) alongside the lag arm? | ✅ **RULED 10-02: "Yes, run the control".** |
| D3 | **How the lag is identified.** The audit's conditional probe at hilda33d (not yet reproduced by me): with today's rows the fit prefers **2–3 months**, via the GCB land sink and the seasonal-coefficient rows; the growth rate's own timing says **5**. The growth-rate row was declined 09-26, to be re-proposed only "with a NEW reason". | **Measure first.** After W1–W3, profile the NEW objective over L, with the ENSO amplitude free, in a committed script; then decide whether timing needs its own row. |
| D4 | The ice δ¹³C σ (W2) | Bring numbers before launch. |
| D5 | **Compute.** Two arms × 24 starts: Mac, 8 at a time, ~9 h per arm ≈ 18 h; or Torch, 48 at once in a ~6 h partition. | **Torch** for two arms. Every sbatch needs Marcus's go. |

## Refit mechanics (from the 10-01 #14 refit; CHANGELOG 09-30 p/q, 10-01 a-d/k)
1. **Frozen git worktree.** Copy in the git-ignored `data-raw/downloads/nuclear14c`, or the industrial ¹⁴C source
   silently goes to zero.
2. **Port targets.** Regenerate `make_port_targets.R` under the arm's structure and pins.
3. **Preflight** with `CCX_MS_PREFLIGHT=1`.
4. **Launch.**
   - Mac: `calibration/mac/run_multistart_mac.sh`. ⚠ Set `CCX_MS_OUTDIR` explicitly; the default omits `_sdby_` and
     the driver refuses it.
   - Torch: `make_bundle.sh` (mode directories are listed by hand at :43-54) → `multistart.sbatch`.
5. **Collect** with `CCX_MS_OUTDIR=<dir> Rscript calibration/collect_dispersed_multistart.R`. It takes an env
   variable, not `--outdir`.
6. **Promote** with `promote_multistart_mode.R` (GATES 1-5), then `recompute_hessian.R <mode> --update`.
7. **Score** with the scorecard, using the repaired gates. Compare **on likelihood**, not logpost.
8. **Adopt.**
   - Register the mode in `R/paths.R`.
   - Point the app at it: `APP_RELEASE_MODE` and `test-app-version`.
   - Re-measure the What-if fit with `diag_enso_growth_fit.R`.
   - Run the suite on a frozen copy with BLAS pinned.

## Deferred to a later pass (audit sections A–F, not refit-relevant)
- The app: tabs 5 and 6, §7a, the Revelle readout, tooltips and takeaways.
- The calibration report.
- Data provenance B5 (nuclear ¹⁴C manifest and rds; the MANIFEST overwrite).
- Mode vs median (B1) and the repository link (B8).
- The parked 08-29 spec items, D.
- The documentation drift, E.
- Marcus's airborne-fraction sentence, F.
