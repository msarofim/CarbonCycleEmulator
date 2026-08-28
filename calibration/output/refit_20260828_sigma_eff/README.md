# refit_20260828_sigma_eff — the 21-parameter refit ONTO THE POST-OPTION-5 OBJECTIVE

**Launched 2026-08-28 by the session continuing `notes/handoff_2026-08-28c_option5_adopted.md` §4.1.**
This is the refit that handoff declared OWED AND NOT RUN. Nothing here is a result until
`mode_fit_pumpN.rds` has a completion timestamp and `_run.log` ends with the comparison write.

## WHY THIS DIRECTORY EXISTS AT ALL

The objective CHANGED on 2026-08-28 (option 5, sigma-inflation adopted): the three
ocean-gradient rows are now scored at `sigma_eff(h_ml)` at EVERY `h_ml`, and the
`LIK_OCEAN_GRAD_HML_OK` = [85, 120] skip is RETIRED. **Every pre-adoption fitted vector is
non-comparable** — including the incumbent canonical mode. `h_ml` is UNBOUNDED for this run.

## PROVENANCE OF THE INPUTS

- **Warm start:** `mode_fit_pumpN.rds` here was SEEDED as a byte copy of the incumbent
  canonical mode `calibration/output/refit_20260825f_from90/mode_fit_pumpN.rds`
  (logpost −1544.615, `fert_k` 154.85, `h_ml` 96.47 m) so `ARM_WARM` picks it up and the
  driver overwrites it in place. Warm-starting across the objective change is safe because
  `par_mode` is band-INDEPENDENT and is re-encoded under this run's table; `u_mode` is NOT
  (memory `ccx_hml_band_provenance`).
- **Driver:** `run_modefind_pump_arms_FROZEN.R` is a byte copy of
  `calibration/run_modefind_pump_arms.R` at commit 6cefa98, taken BEFORE launch. The run
  executes the FROZEN copy, not the tracked file, because Rscript parses incrementally and an
  edit to a live script shifts byte offsets under the running process
  (memory `never_edit_a_running_script`). **The tracked driver may be edited during this run;
  this copy may not.**
- **Objective dependency:** `data/obs_glodap_sigma_rep.rds` (built 2026-08-28 18:00 by
  `data-raw/build_glodap_sigma_rep.R`). Without it `ccx_ocean_sigma_eff()` errors by design.

## RUN CONFIGURATION

    cwd            = repo root (the driver does `source()` over `R/` relative to cwd)
    CCX_ARM_OUTDIR = calibration/output/refit_20260828_sigma_eff
    ARM_MODES      = "N"        (D not re-run; arms were indistinguishable 2026-08-18)
    ARM_RESTARTS   = 20, ARM_MAXIT = 20000, ARM_CYCLES = 6, ARM_SEED = 2026  (all production)
    h_ml           = UNBOUNDED over the shipped support
    BLAS threads   = PINNED TO 1 (OMP/OPENBLAS/VECLIB/MKL), memory `pin_blas_threads`
    ETA            ~18 h, measured at 21 parameters 2026-08-18 (0.161 s/eval)

## HOW TO READ THE RESULT WHEN IT LANDS

The 14.2-min smoke test (handoff §3) reported `h_ml` = 35.38 m and "gained" 4.1 — that is
**NOT a finding and NOT a bug**. Its entire gain was prior credit on `sst_seas_amp_SH` (+4.145)
and `sst_seas_amp_NH` (+1.632), bought with a WORSE fit (loglik −1.201). A crippled run wanders
down soft directions trading likelihood for prior. **The seasonal-amplitude prior conflict is the
dominant gradient in this refit and is how this run must be read** — decompose any `h_ml` move
into prior / jacobian / loglik before calling it a result. Stage B's interior maximum was found
with all 16 seasonal parameters HELD FIXED; they are FREE here.

Also expect: `kz` to rail again (95.3 % in the smoke, unchanged for many runs), and `h_ml` to be
piecewise-C1 but NOT smooth — 26 `1/eps` pump kinks survive in [30, 200]; option 5 removed the
band CLIFF (+7.30 / +8.43), not the kinks (handoff §5).

## WHAT THIS RUN BLOCKS (handoff §4, in order)

Until it lands, NOTHING may be quarantined — quarantining the incumbent before a replacement
exists breaks `ccx_mode_file()`, the app and every diagnostic. After it lands:
2. quarantine `refit_20260825f_from90/` → `quarantine/20260828_sigma_inflation_adopted/`, repoint
   `ccx_mode_file()`;  3. re-run `diag_hess_eps_21par.R` + `recompute_hessian.R`;  4. re-run the
design gates (`diag_design_gates_at_mode.R`, `diag_design_gates_unscored.R`, `diag_joos_irf.R`) —
no gate verdict is current;  5. re-run the 4 banner-flagged mirror diagnostics unbounded.

⚠ The harness offset −1.5805 is a PRE-ADOPTION number and is not current.
