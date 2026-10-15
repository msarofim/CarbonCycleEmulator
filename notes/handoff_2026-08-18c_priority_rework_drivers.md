# Handoff — CarbonCycleEmulator, 2026-08-18c: THE PRIORITY REWORK — sigma_d13c out, rep_dC in, d13C seasonality scored, and the SEASONAL CYCLE MOVED ONTO PHYSICAL DRIVERS. REFIT HELD.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, tree clean.
**HEAD = `1a73e3e`.** Session commits: `dd1b293` → `e073730` → `6219df7` → `53efc93` → `2815560` → `1a73e3e`.
**Supersedes `handoff_2026-08-18b_test_repairs_applied.md`** for its §4 items — this session
executed the priority rework that grew out of them. 18b's §2 (mutation-test lessons) stands.

## 0. START HERE

1. **MARCUS'S PRIORITY ORDER (2026-08-18, verbatim in effect):** *isotopes and observed
   monthly + hemispheric concentration patterns FIRST; Joos pulse matching is very secondary.*
   Everything below follows from it.
2. **THE OBJECTIVE AND THE MODEL BOTH CHANGED TODAY. NOTHING is comparable across
   2026-08-18.** `mode_fit_pump{N,D}.rds` is stale against the new objective AND the new
   model. **THE REFIT IS HELD (Marcus) — no quotable number exists on the new model.**
3. **Parameters: 20 → 21**, three times re-shaped: −`sigma_d13c` +`rep_dC` (20), then
   −seas_amp/phase ×4 +`seas_T_amp_NH/SH` +`seas_lag_p` (19), then +`sst_seas_amp_NH/SH`
   (21) when Marcus moved SEASONAL SST ahead of the refit (`6fadb34`).
4. **Suite `FAIL 0 | WARN 55 | SKIP 2 | PASS 884`.** Every legacy stream in the rds
   reproduces to **0.000e+00** through the escape hatches (`diag_rep_dC_gates.R` gate 1).
5. **The next driver candidate is SST** (§5) — after the refit.

## 1. Why: the fit diagnosis (`dd1b293`, `e073730`)

`calibration/diag_fit_at_mode.R` (gated: recomputed logL == stored rds, all streams):
nothing grossly misfit (RMS z 0.40–1.18), gate 7 passes at the mode — **but the d13C levels
were almost PURE BIAS** (MLO +0.233 ‰, 1.17 of its 1.18 RMS z), the misfit **rank-one**
(fitted `grad_off_d13c` = the MLO−SPO bias difference to 0.003 ‰), and **`sigma_d13c` had
inflated to 4× the representation floor while the de-biased scatter sat BELOW the floor** —
an error bar absorbing a structural bias. `diag_station_representation.R`: the common-mode
d13C bias is **30.3× too large to be station-vs-box representation** (mass balance from the
measured CO2 bias predicts +0.0064 ‰ vs +0.194 ‰ measured); sign right, magnitude wrong ⇒
mostly Suess overshoot, NOT representation. Memory: `ccx_fit_at_mode`.

## 2. The likelihood changes (`6219df7`, `53efc93`)

- **`sigma_d13c` RETIRED, `sigma_d14c` KEPT** — the de-biased-scatter measurement separates
  them (d14C has real excess scatter, 14/12 ‰ vs ~4.2 obs). Absence contract as `sigma_co2`.
- **`rep_dC` ADDED**: ONE station-vs-box level offset generating BOTH species' offsets via
  mass balance (`LIK_REP_SOURCE_D13C` = −26.5 ‰), prior N(0, 1.0 ppm). Deliberately NOT a
  free d13C offset — that would swallow the Suess overshoot. Gates: legacy parity exact;
  rep_dC = 0 ≡ absent; coupling −0.04898 ‰/ppm vs −0.04919 predicted from obs (0.4 %),
  single-knobbed. Test pins all three.
- **d13C seasonality SCORED** (`d13c_seasonal_{MLO,SPO}`, `LIK_USE_D13C_SEAS`): the old
  "double-counts the NEP harmonic" reasoning conflated one mechanism with one measurement.
  At the old mode the model OVERSHOOTS the d13C seasonal amplitude (MLO 0.212 vs 0.178 ‰;
  SPO 2×) — never visible before.

## 3. THE SEASONAL CYCLE ON PHYSICAL DRIVERS (`2815560`, `1a73e3e`)

Marcus, replacing the second-harmonic fork: tie the cycle to insolation and temperature.
**Offline first** (`diag_seasonal_drivers_offline.R`) — and the fit sequence is the lesson:
unconstrained → **mirror solution** (both fluxes negative, physics inside out); constrained
without phenology lag → collapse (March peak); with the lag and **fluxes PINNED at the
model's own 36 GtC/yr: RMS 0.357 vs the fitted sine's 0.608, amp2/amp1 0.21 vs obs 0.24 —
EMERGED, not fitted.**

Wired in both cores behind `seas_drivers` (default 1; **0 = the sine, bit-exact; cpp.R
absence-default 0** so old param lists run the model they were fitted to). Parity 2.4e-15.
Constants (offline interior optimum): `CCX_SEAS_PHI_EFF` (75 N, −30 S), `CCX_SEAS_T_LAG`
2.0 mo; light threshold = 0 (polar night self-rectifies). **The NPP amplitude is now a
PREDICTION** — and the amplitude trend emerged at **+17 % (1960-80 → 2000-20) vs observed
~15-20 %, fitted to nothing.** NH amp2 0.94 ppm (was 0.03). At defaults amp1 overshoots
(5.0 vs 3.0 ppm; d13C 0.37 vs 0.18 ‰) — `seas_T_amp` is the counter-cycle, the refit's job.

**Control-drift decomposition** (measured, not assumed): +0.43 ppm/275 yr zero-emission =
+0.33 **fertilization rectifier** (real physics, shrinks with calibrated amplitude) + +0.10
integrator quadrature over the polar-night kinks (cut from +0.22 by **720-point norms** in
both cores; the residual is the integrator's own). Sine drifted +0.044.

## 4. Traps left armed (ALL new since 18b)

- **Zeroing `seas_amp_*` no longer disables seasonality.** Five test sites hit this; any new
  test wanting a seasonless run must set `seas_drivers <- 0`.
- **`ccx_spinup` zeroes BOTH seasonal paths** — the driver terms are zero-mean over a year
  but not at the single t the isotope solve evaluates; left on, the operator is SINGULAR.
- **Mode-reconstruction diagnostics MUST set `seas_drivers <- 0`** (and pass legacy
  `sigma_d13c`) — `diag_fit_at_mode.R`, `diag_rep_dC_gates.R`, `diag_station_representation.R`
  do, with the rds gate as the tripwire.
- The strict 1e-15 parity arms (pump-off, frozen-Revelle) run the sine; the driver path sits
  at ~2e-15 under the derived tolerance. Do not "fix" by weakening 1e-15.
- `run_modefind_pump_arms.R`'s per-stream err list now names `rep_dC`/`sigma_d14c` — it must
  keep tracking CCX_PARAM_NAMES or the decomposition describes a different objective.

## 5. Open, in dependency order

1. **THE REFIT** — held for Marcus's review of the day's changes. It now carries: 19
   params, 2 new streams, rep_dC, and the driver seasonal model. Everything downstream
   (h_ml bound question, pilot MCMC, ensemble, app) queues behind it. **When it runs,
   expect `seas_T_amp_NH` to climb** (amp 5.0 → ~3.0 needs a stronger respiration
   counter-cycle) **and watch `q10`** — it now has seasonal duty; the linear part is
   absorbed by `seas_T_amp` but the nonlinear part is q10's own.
2. **SEASONAL SST: DONE, pre-refit** (`6fadb34`, Marcus's call — refit economics + not
   baking the SPO mis-attribution into `seas_T_amp_SH`). Under `seas_drivers`; params 21;
   at defaults the ocean term opposes the NH land cycle (MLO 4.77 → 4.41 ppm, toward obs
   3.02). **A SH PHASE BUG was caught in the process**: the land seasonal-T sine had no
   hemisphere flip (SH respiration peaking in austral winter), and the log-transformed
   amplitude meant no sampler could ever have repaired it — only zeroed it. Fixed both cores.
   **OBSERVED SST: DONE too (`98fd871`, Marcus: HadSST4)** — historical hemispheric HadSST4
   anomalies (re-based to 1850-1900) replace `0.8 × GMST`; forward scaling = constant
   last-30-yr obs ratios (NH 0.819 / SH 0.762, `diag_hemis_t_ratios.R` — the window spread is
   AEROSOL history, not warming-level dependence), with `ccx_sst_anom_from_gmst()` the single
   seam for a future CMIP6 scaling. `sst_obs` switch (absence-default 0); N_FORCING 12 → 14;
   `ccx_hold_climate()` now the ONLY sanctioned way to freeze climate on a built forcing
   (hand-rolled `F$gmst <- F$gmst[1]` leaves real SST warming in a "frozen" run); the
   `warming_feedback` mechanism sets `sst_obs = 0`. CRUTEM5 land ratios measured (NH 1.54)
   but **land-T into q10 NOT wired** — a further structural change, not ordered. The refit
   now carries: 21 params, 2 new streams, rep_dC, driver seasonality (land + SST), and
   observed annual SST.
3. Carried from 18b: defaults-vs-mode bar derivation gap; gate 12 has no test;
   `ARM_HESS_EPS` at the new param count (now 19); σ-inflation spec; `kz` bracket; pilot
   MCMC barrier question; DESIGN §5.4 products.

## 6. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-18c_priority_rework_drivers.md`. **Marcus's priority: isotopes
> + monthly/hemispheric patterns first, Joos secondary.** The objective AND model changed
> 2026-08-18 (sigma_d13c → rep_dC; d13C seasonality scored; seasonal cycle on physical
> drivers, params 20 → 19, sine at `seas_drivers = 0`). **REFIT HELD — nothing quotable
> exists on the new model; nothing is comparable across 08-18.** Suite `FAIL 0 | PASS 884`;
> the rds reproduces 0.000e+00 through the escape hatches. First job when Marcus releases
> the hold: the refit (§5.1, with the seas_T_amp and q10 watch-items). Next driver after
> that: SST (§5.2).
