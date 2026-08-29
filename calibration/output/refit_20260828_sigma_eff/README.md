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

---

# ⚖ RATIFIED 2026-08-29: **DO NOT ADOPT.** (Marcus)

`handoff_2026-08-29` §3 recommended against adopting this refit; **Marcus ratified that on
2026-08-29.** The recommendation and the ratification rest on the same measurements:

- The refit **CONVERGED** — cycle 2 gained exactly 0.0000, NM restarts and BFGS polish both gain
  zero from the cycle-1 mode. This is a legitimate posterior mode of the adopted objective.
- **But the +4.06 is ENTIRELY PRIOR CREDIT and the LIKELIHOOD IS WORSE by 1.199**, and `h_ml`
  = 35.38 m moves ocean structure the **WRONG WAY**: at fixed `sst_seas_amp_SH`, 96 → 35 m takes
  the SH ocean limb from 58.7 % to **49.4 %** of observed — on a defect that needs a DOUBLING —
  and rotates its phase from 4.15 to 3.90 mo, further from the observed 8.52.
  (`diag_hml_seasonal_limbs.R`, `diag_hml_sst_elasticity.R`; memory `hml_shallow_is_prior_credit`.)

**⇒ `ccx_mode_file()` STAYS ON `from90`.** `run_post_refit_adoption.R` stages `quarantine`,
`repoint` and `rerun` are **NOT to be run** for this refit; only `--stage=check` (5/5) and
`--stage=read` have ever been run, and that remains correct.

**These outputs are kept and committed as PROVENANCE** (`042a0df`) — they are the evidence for the
non-adoption and the regression baseline for any future h_ml work. Never delete them.

## THE SUCCESSOR CANDIDATE IS NOT A CONFIG CHANGE — READ THIS BEFORE QUEUEING IT

`handoff_2026-08-29` §3 names the candidate: **a refit with `h_ml` PINNED at ~96**, keeping option
5's σ-inflation while denying it the anti-physical lever. **It cannot simply be launched.** Checked
2026-08-29:

1. **There is no switch.** `run_modefind_pump_arms.R:111` still defines `ARM_HML_BOUND` but marks it
   **"⚠ PROVENANCE ONLY since 2026-08-28 — nothing may bound h_ml with this"**, and the driver's
   §"h_ml IS **UNBOUNDED** FOR THIS REFIT" block is unconditional. Re-bounding therefore needs a
   **reviewed code change** introducing a NEW named constant with its own justification — reusing
   the retired one would be the retired objective wearing the new one's clothes, which is precisely
   what `2153bd6` set out to stop.
2. **A bound is not a pin.** The 08-16g mechanism BOUNDED `h_ml` to [85, 120] **and renormalised its
   prior over that band** — that renormalisation is what produced the −1.5805 offset constant. A
   true pin at 96.47 is a different object again (one fewer d.o.f.), and which of the two is wanted
   is itself a decision, not an implementation detail.
3. **The machine was busy.** At 2026-08-29 10:30 four Julia workers were each at ~99 % CPU (load
   6.32) — the SLR/BRICK side. An 18 h refit launched on top of that slows both jobs and the ETA
   stops meaning anything (memory `eta_in_days_is_not_a_slow_run`).

**⇒ QUEUED, NOT LAUNCHED**, pending (a) the choice of bound-vs-pin, (b) the reviewed constant, and
(c) a free machine.
