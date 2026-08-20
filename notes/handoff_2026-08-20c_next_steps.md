# Handoff — CarbonCycleEmulator, 2026-08-20c: NEXT STEPS. The seasonal AMPLITUDE deficit is the live work, and it has a hemispheric signature.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, HEAD `1a34c8c`.
Working tree clean. **889 tests pass, 0 fail.**

**Reading order.** This note is the forward-looking one and is self-contained. Its two
predecessors are still the record for *how* we got here and should be read only if you need the
evidence behind a claim:
- `handoff_2026-08-20_refit_landed_seasonal_phase.md` — the 21-parameter two-arm refit. Its §1,
  §2, §3b, §3c, §4 stand. **Its §3a and open decision 1 are SUPERSEDED.**
- `handoff_2026-08-20b_seasonal_phase_closed_amplitude_open.md` — the seasonal-phase test, the
  factor-of-2 correction, the lag profile, the Torch probe, and the `h_ml` diagnosis.

---

## 0. STATE IN TEN LINES

1. **The 21-parameter two-arm refit landed.** Modes at
   `calibration/output/pump_arms/mode_fit_pump{N,D}.rds`. **Arm N adopted.**
2. **Neither arm is converged** (both hit the restart cap while still gaining) and the
   **evidence (D − N = +10.69) is still NOT QUOTABLE** — for the four reasons in the 08-20
   note's §0.3, none of which changed.
3. **The arms are indistinguishable** — all 21 coordinates within ~0.1 prior-sd except `h_ml`.
   That, not the evidence, is the result.
4. **The seasonal PHASE hypothesis is dead.** The scored observable is on time (MLO CO2 peaks
   0.09 months EARLY); the shipped `CCX_SEAS_T_LAG = 2.0` beats the "climatological" mid-July
   value by 18,944 log-units. **Do not redo the refit for it.**
5. **The seasonal AMPLITUDE is the real defect, and it is the live work.** §2 below.
6. **The `h_ml` scare is closed** — a band-provenance issue in the reader, not the files. §4.
7. **Torch is verified end to end** and reproduces the Mac exactly. §5.
8. **There is still NO POSTERIOR** — the sampler has never converged.
9. `output/mode_fit.rds` remains ABSENT; the adopted mode is `mode_fit_pumpN.rds`. Do not
   conflate them.
10. **Two corrections landed today that invert earlier readings** — the observed seasonal
    amplitude reference was a factor of 2 out, and the "corrupt `u_mode`" was my reader. Both
    are recorded in place rather than rewritten.

---

## 1. THE ONE-PARAGRAPH ORIENTATION

The 08-18 rework moved the seasonal cycle onto physical drivers (insolation + Q10 on seasonal
land T + observed HadSST4 SST) and added a 21st parameter. The refit that followed put five
parameters beyond 3σ, the same five in both arms — including `sst_seas_amp_{NH,SH}` driven to
zero and `seas_T_amp_NH` at an impossible 48 K. The 08-20 diagnostics read that as a seasonal
PHASE bug. **It is not.** The phase is right; the model cannot make a seasonal cycle of the
right SIZE, and the fit is buying size with unphysical parameter values. That is the thing to
fix, and until it is fixed `seas_T_amp_NH` and `q10` are individually uninterpretable.

---

## 2. THE LIVE WORK — the seasonal amplitude deficit

### 2a. The numbers

Peak-to-peak first-harmonic amplitude, 1975–2024, at the arm-N mode
(`calibration/diag_seasonal_phase_obs_vs_model.R`):

| stream | observed | model | error |
|---|---|---|---|
| MLO CO2 | 6.764 ppm | 5.242 | **−22 %** |
| SPO CO2 | 1.196 ppm | 1.666 | **+39 %** |
| MLO d13C | 0.358 ‰ | 0.423 | +18 % |
| SPO d13C | 0.045 ‰ | 0.158 | **+253 %** |

Independent check in different units, so this is not an artifact of the harmonic estimator: the
raw NOAA monthly climatology (`co2_ppm − co2_deseas`, 1990–2014) gives MLO peak-to-trough
**6.61 ppm** and SPO **1.10 ppm**.

Three of the four scored seasonal rows are **amplitude-dominated** in cost (`co2_MLO` 228 vs 58,
`co2_SPO` 116 vs 63, `d13c_SPO` 361 vs 35); only `d13c_MLO` is phase-dominated (202 vs 59).

### 2b. THE SIGNATURE, and it is the most useful thing in this note

**The NH undershoots and the SH overshoots, in both species.** That is not a global
amplitude-scale problem — it is a hemispheric PARTITION problem. The model is putting too much
seasonal amplitude in the SH and too little in the NH.

That has a ready-made suspect, and the code predicted it. `R/model.R` ~line 195:

> *"SH is UNFITTED: the offline work fitted MLO only (SPO's 0.55 ppm cycle is substantially
> oceanic, which this land-only term does not model). `CCX_SEAS_PHI_EFF["SH"]` is the SH land
> centroid, and `seas_T_amp_SH` is free to absorb the amplitude. **Revisit if the SPO seasonal
> stream misfits.**"*

The SPO seasonal stream misfits. At the mode `seas_T_amp_SH = 11.18 K` and
`CCX_SEAS_PHI_EFF["SH"] = −30°` — a land-only term carrying a cycle the comment itself says is
substantially oceanic. **This is the revisit that comment asked for.**

*(Hypothesis, stated as such — the table above is measurement, the mechanism is not yet tested.)*

### 2c. Suggested tests, in order, cheapest first

1. **CHANNEL DECOMPOSITION, per hemisphere.** Turn each seasonal channel off in turn — NEP /
   insolation (`seas_drivers` path), respiration (`q10` × `seas_T_amp`), air-sea
   (`sst_seas_amp`) — and re-run `ccx_year_harmonic` on `co2_NH` / `co2_SH` / `d13c_NH` /
   `d13c_SH`. That gives the amplitude BUDGET, which is what is missing: right now we know the
   totals are wrong but not which channel owns the error in which hemisphere. Follow
   `decompose_channels` — a channel you did not argue teaches you nothing.
   **Reuse `diag_seasonal_phase_obs_vs_model.R`'s `run_stats()` / `summarise_stream()`; the
   scaffolding is already there.** One model run per case, ~2 s each.
2. **Then the SH structural question**, informed by (1): if the SH error is in the land channel,
   `CCX_SEAS_PHI_EFF["SH"]` and/or the land-only assumption is the target; if it is oceanic,
   the SH needs an air-sea seasonal term that is not currently identified (`sst_seas_amp_SH` is
   fitted at 0.064 K, i.e. off).
3. **Then the NH deficit.** Note from the 08-20b §4 ladder that the NH is **non-monotone**: more
   respiration swing gives LESS MLO amplitude, because respiration counter-cycles NEP. So the
   NH deficit is probably an NEP-amplitude statement, and the NEP seasonal amplitude "is not a
   knob — it is the model's own NPP". If the deficit lives there it is a statement about NPP
   magnitude or about `CCX_SEAS_PHI_EFF["NH"] = 75°`, which is far enough poleward that the
   insolation shape has polar-night kinks (that is why `ccx_seas_norms()` uses a 720-point grid).
4. **Only then** reconsider whether `seas_T_amp_NH` needs a tighter prior. Tightening the prior
   before the structure is right would just move the misfit somewhere less visible —
   `ccx_path_relocates`.

### 2d. The trap to avoid

**Do not run an amplitude-only direction test and conclude a mechanism is redundant.** The rows
score sin AND cos, so every seasonal comparison is amplitude *and* phase — that is what made the
08-20 reading wrong in both directions. And **compute both sides of any amplitude comparison
with the same expression in the same script**: the factor-of-2 that inverted this whole arc was
an inline literal (semi-amplitude) compared against a live computation (peak-to-peak).

---

## 3. SECOND ITEM — the mode-file provenance fix (small, not applied)

The arm rds records `kz_bracket` but **not** the `h_ml` band it was fitted under. That asymmetry
is what cost an afternoon today (§4). Two changes, both small:

1. In `calibration/run_modefind_pump_arms.R`, add `hml_bound = ARM_HML_BOUND` to the `out` list.
2. Gate the round-trip wherever a mode file is loaded:
   `stopifnot(max(abs(unlist(ccx_unc_to_par(u_mode)[CCX_PARAM_NAMES]) - unlist(par_mode[CCX_PARAM_NAMES]))) < tol)`

**NOT APPLIED — awaiting Marcus**, because it edits the driver that produced the current
outputs. (1) affects future runs only; (2) is reader-side and safe.

---

## 4. HOW TO LOAD A MODE FILE CORRECTLY — read this before touching `u_mode`

`run_modefind_pump_arms.R` overrides `CCX_PARAM_TABLE$h_ml` **in-process** to
`ARM_HML_BOUND = c(85, 120)` (Marcus 2026-08-16g; outside `LIK_OCEAN_GRAD_HML_OK` all three
ocean-gradient rows SKIP). The repo default is `logit, lo = 30, hi = 200`.

- **`par_mode` is physical and band-independent. Prefer it. It is always safe.**
- **`u_mode`, `hessian`, `cov`, `sd_unc`, `eigen`, `logdet_negH` are u-space and
  BAND-DEPENDENT.** Decoding `u_mode` under the default band silently gives `h_ml` = 81.75 m
  (N) / 46.46 m (D) instead of 95.66 / 88.39, moves the log-posteriors by +2.4 / −42.9, and
  **flips the D − N margin to −34.63**. Under the correct band everything reproduces to
  0.000e+00 / ~5e-10.

To use any u-space field, re-apply the override first:

```r
BAND <- c(85, 120)                                    # ARM_HML_BOUND
CCX_PARAM_TABLE$h_ml$lo <- BAND[1]; CCX_PARAM_TABLE$h_ml$hi <- BAND[2]
CCX_PARAM_TABLE$h_ml$init  <- 100
CCX_PARAM_TABLE$h_ml$prior <- local({ lo <- BAND[1]; hi <- BAND[2]
  function(x) stats::dunif(x, lo, hi, log = TRUE) })
```

**The stored Laplace evidence is fine** — it was computed in-process under the band.

---

## 5. TORCH — verified, and what it is and is not good for

Probe job `16075825`, `cpu_short`, 25 s. Artifacts at `/scratch/ms17839/ccx-probe/`
(`ccx_torch_probe.R`, `probe.sbatch`, `logs/`).

- **R 4.5.1**; `Rcpp 1.1.0`, `Matrix 1.7.4`, `testthat 3.2.3` present.
  **`adaptMCMC` MISSING** — install to `/scratch/ms17839/.Rlib` (already on `.libPaths()`)
  before any sampler work.
- **`src/ccx_core.cpp` compiles there in 4.1 s**, unmodified.
- **Exact cross-platform parity**: Torch and Mac both give `logpost = -2674.035951671` on an
  identical subset. A Torch-run mode-find is comparable with Mac results.
- **Per-eval the Mac is ~2× FASTER** (0.141 s vs 0.294 s). **Torch's case is CORE COUNT, not
  per-core speed** — parallel dispersed multi-start needs ≳4 concurrent starts just to break
  even, and is worth it only above that. Nelder-Mead's 20 sequential restarts is inherently
  serial and would gain nothing from a port.
- **The R wrapper is a Singularity container.** `/share/apps/r/4.5.1/bin/Rscript` symlinks to
  `__run_base_r.bash`, which binds `${SLURM_TMPDIR}/rtmp-$$` (or, unset,
  `/state/partition1/${USER}/rtmp-$$`) onto the container's `/tmp`. **It FAILS on login
  nodes** — R can only be run under SLURM. The overlay is `:ro`, so packages go to
  `R_LIBS_USER` on scratch. **Write sbatch files locally and `scp` them**; generating them
  through nested ssh heredocs mangled the `SLURM_TMPDIR` fallback and cost one failed job.
- Partitions present: `cpu_short`, `cpu_prem`, `cs`, `cl`. Fairshare **1.000000**.

---

## 6. STILL OPEN, unchanged from the 08-20 note

1. **`rep_dC`** — it is a ~6 ppm CO2 LEVEL bias, not a δ¹³C bias sink (pays +1082 / +1072 in the
   CO2 rows, worth 3,959 log-units). Chase the bias, or tighten the prior and let it show in the
   residuals? Connects to the standing `ccx_co2_level` and `ccx_luc_input` threads.
2. **`kz`** — PINNED at ~98 % of its bracket in both arms. **Must be settled before any
   sampler.**
3. **Matched re-polish** — only worth it if an evidence number is wanted; moot if
   "indistinguishable" is accepted.
4. **Pump-shape smoothing** — deferred; the kinks did not bite.
5. **N vs D** — keep N on physical and pedagogical grounds (nutrient- vs DIC-limited export;
   constant-mass changes the ocean sink by exactly zero). Consider carrying `pump_mode` as a
   structural uncertainty through the ensemble instead of choosing.

---

## 7. FILES

**New today** (all committed, all reproducible from a clean tree):
- `calibration/diag_seasonal_phase_obs_vs_model.R` — phase + cost decomposition + the (q10,
  seas_T_amp) ladder. **Its `run_stats()` / `summarise_stream()` are the scaffolding for §2c.**
- `calibration/diag_seas_lag_profile.R` — profiles the two compile-time lag constants by
  patch + rebuild + fresh process in a `tempdir()` copy; never touches the working tree.

**Edited today:**
- `calibration/diag_sst_seas_zeroing.R` — correction block + named `SSTZ_OBS_P2P` constants.
  The original (wrong) premise is marked WRONG in place, not rewritten.
- `R/model.R`, `src/ccx_core.cpp` — the two seasonal-lag comments only. **No behaviour change**;
  values identical, 889 tests pass.

**Unchanged and still authoritative:** `calibration/run_modefind_pump_arms.R`,
`calibration/finish_pump_arms_comparison.R`, both arm rds files.

---

## 8. NON-OBVIOUS STATE

- **`data-raw/downloads/nuclear14c/` is a LIVE runtime input and is NOT under version control**
  (gitignored). `ccx_nuclear_c14_annual()` reads the CSVs directly at run time and **warns
  rather than errors** if they are absent, silently zeroing the industrial ¹⁴C source and moving
  the log-posterior by ~6 log-units. Any copy of this repo made for a remote run must include
  that directory — the Torch probe did not, which is why its absolute numbers differ from the
  full-repo Mac run.
- **`CCX_SEAS_T_LAG` and `CCX_SST_SEAS_LAG` have hardcoded `static const double` twins in
  `src/ccx_core.cpp`.** They cannot be varied inside one R session. Use
  `diag_seas_lag_profile.R`'s pattern.
- **Never edit a script a long job is executing** — Rscript parses INCREMENTALLY; this killed
  the refit's tail ~30 h in. Copy it, edit the copy.
- The scratchpad copy at `.../scratchpad/ccx_lagprofile/` is **left patched at
  `CCX_SST_SEAS_LAG = 3.5`** from a manual profile run. It is disposable — do not read numbers
  out of it. (It already produced one wrong comparison today.)

---

## 9. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-20c_next_steps.md`. The live work is **§2, the seasonal amplitude
> deficit** — the NH undershoots and the SH overshoots in both species, which is a hemispheric
> partition problem, and `R/model.R` ~line 195 flagged the SH land-only assumption as the thing
> to revisit if SPO misfit. Start with **§2c test 1, the per-hemisphere channel decomposition**,
> reusing `diag_seasonal_phase_obs_vs_model.R`'s scaffolding. Read §4 before touching `u_mode`.
