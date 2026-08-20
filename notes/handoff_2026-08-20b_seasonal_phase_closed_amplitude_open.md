# Handoff — CarbonCycleEmulator, 2026-08-20 (later): THE SEASONAL PHASE HYPOTHESIS IS DEAD. The observable is on time, the shipped lag wins by 18,944 log-units, and the "model overshoots MLO" premise was a factor of 2.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, HEAD `c722694`.
**Supersedes §3a and open decision 1 of `handoff_2026-08-20_refit_landed_seasonal_phase.md`.**
Everything else in that note stands unchanged — §1 (results), §2 (the operator error), §3b
(`rep_dC` is a ~6 ppm CO2 level bias), §3c (the `q10` degeneracy), §4 (keep N), §6 (Torch).

## 0. START HERE

1. **The test named at the end of §3a ran, and it went against the hypothesis.** The modelled
   MLO CO2 seasonal cycle peaks **0.09 months (2.7 days) EARLY** against the observed cycle
   the likelihood scores. All four seasonal streams are inside half a month.
2. **The shipped `CCX_SEAS_T_LAG = 2.0` is a clean interior optimum** and beats the
   "climatologically correct" mid-July peak by **18,944 log-units** on the seasonal rows.
3. **A factor of 2 inverted the earlier reading.** The observed MLO amplitude is **6.764 ppm
   peak-to-peak**, not 3.02 — 3.02 is the semi-amplitude. The model **UNDERSHOOTS** by 22 %.
4. **The real defect is AMPLITUDE, not phase.** Three of four seasonal rows are
   amplitude-dominated in cost. **That is the live work.** §4 below.
5. **Do NOT redo the 33 h refit for the phase convention.** Open decision 1 is answered NO.
6. **Torch is still unmeasured** — the final ssh hop is refused from here. §5.

## 1. What ran

Three scripts, all committed, all reproducible from a clean tree:

- **`calibration/diag_seasonal_phase_obs_vs_model.R` (new)** — the decisive test. Both sides
  reduced by `ccx_seasonal_target()` over `LIK_SEAS_WINDOW` (1975–2024), so nothing depends on
  a definition of "phase" the fit does not use. `a·sin(2πφ) + b·cos(2πφ)` peaks at
  `φ = atan2(a, b)/2π`; that is the whole conversion.
- **`calibration/diag_seas_lag_profile.R` (new)** — profiles `CCX_SEAS_T_LAG` and
  `CCX_SST_SEAS_LAG`. Both are compile-time constants with `static const double` twins in
  `src/ccx_core.cpp`, so each point is a source patch + rebuild + fresh process. The script
  does this in a `tempdir()` copy and **never touches the working tree** — §2 of the previous
  handoff, applied to the model source. It gates that the patch took before spending a run.
- **`calibration/diag_sst_seas_zeroing.R` (edited)** — correction block, named `SSTZ_OBS_P2P`
  constants replacing the inline literals. The original premise is **marked WRONG in place,
  not rewritten**, so the postmortem survives.

## 2. THE PHASE RESULT — the observable is on time

Model minus observed peak phase at the arm-N mode. Positive = the model peaks later.

| stream | obs peak | model peak | Δ (months) | Δ per-year sd |
|---|---|---|---|---|
| `co2_seasonal_MLO` | month 3.56 | month 3.48 | **−0.09** | 0.11 |
| `co2_seasonal_SPO` | month 9.01 | month 8.50 | −0.51 | 0.40 |
| `d13c_seasonal_MLO` | month 9.41 | month 9.81 | +0.40 | 0.14 |
| `d13c_seasonal_SPO` | month 3.24 | month 3.03 | −0.21 | 1.74 |

**A late DRIVER is not a late OBSERVABLE.** The measured driver peaks (NH SST Oct, land T Sep,
NPP Aug) are real — TEST 3 confirms the `(3.5 + LAG)/12` arithmetic exactly — but they do not
propagate to what the likelihood sees.

**Cost decomposition** — each row's own Gaussian cost, then re-evaluated with the model's
radius at the observed phase (amplitude-only error) and the observed radius at the model's
phase (phase-only error):

| stream | cost | amp-only | phase-only | verdict |
|---|---|---|---|---|
| `co2_seasonal_MLO` | 309.0 | **228.1** | 57.5 | AMPLITUDE |
| `co2_seasonal_SPO` | 202.2 | **116.1** | 63.3 | AMPLITUDE |
| `d13c_seasonal_MLO` | 366.1 | 58.9 | **202.4** | PHASE |
| `d13c_seasonal_SPO` | 386.6 | **360.6** | 35.0 | AMPLITUDE |

## 3. THE LAG PROFILE — the data want the late lag, and the COMMENT is what is wrong

Seasonal-row logL at the mode, everything else frozen:

| `CCX_SEAS_T_LAG` | 0.0 | 0.5 | 1.0 | 1.5 | **2.0** | 2.5 | 3.0 |
|---|---|---|---|---|---|---|---|
| seasonal logL | −19466 | −10841 | −4764 | −1411 | **−521** | −1507 | −3650 |
| MLO p2p (ppm) | 8.30 | 6.30 | 4.63 | 4.12 | 5.24 | 7.17 | 9.20 |
| MLO Δ phase (mo) | +2.36 | +2.25 | +1.76 | +0.77 | **−0.09** | −0.46 | −0.57 |

**`CCX_SST_SEAS_LAG` is nearly FLAT** (−490 at 0.5 mo → −532 at 3.5 mo). It is unidentified at
this mode, which follows directly from `sst_seas_amp` sitting at ~0.09 K.

**THE SLICE IS BIASED TOWARD THE INCUMBENT** and that has to be said with the numbers: the mode
was fitted at (2.0, 2.5) and no challenger is re-optimised — the `match_incumbents_optim` trap,
which bought 309 log-units of pure artifact last time. **19,000 is not 309**, and the profile is
smooth and single-peaked exactly at the shipped value.

**WHY THE LATE PEAK IS PHYSICAL: the constant multiplies SOIL respiration through `q10`, not
air temperature** (`R/model.R` ~line 949: it scales the `tau_soil_fast` / `tau_soil_slow`
fluxes). Soil temperature lags air temperature by weeks to months with depth, so a September
respiration peak is defensible. The comment "seasonal land T peak after Jun" is a leftover from
when the term was conceived as air temperature. **Fix the comment; leave the 2.0.**
*(Stated as the conventional soil-thermal-lag position — not backed here by a specific
citation. Check before it goes in writing.)*

## 4. THE LIVE WORK — the seasonal AMPLITUDE

Observed peak-to-peak, 1975–2024, versus the model at the mode:

| stream | observed | model | error |
|---|---|---|---|
| MLO CO2 | 6.764 ppm | 5.242 | **−22 %** |
| SPO CO2 | 1.196 ppm | 1.666 | +39 % |
| MLO d13C | 0.358 ‰ | 0.423 | +18 % |
| SPO d13C | 0.045 ‰ | 0.158 | **+253 %** |

Independent check in different units: the raw NOAA monthly climatology
(`co2_ppm − co2_deseas`, 1990–2014) gives an MLO peak-to-trough of **6.61 ppm** and an SPO one
of 1.10 ppm — so the harmonic numbers are not an artifact of the estimator.

**The `q10` × `seas_T_amp_NH` ladder (TEST 4), and it is counter-intuitive:** more respiration
swing gives LESS MLO amplitude, because respiration is a COUNTER-cycle to NEP.

| case | realised swing | MLO p2p | Δ phase | MLO cost |
|---|---|---|---|---|
| mode (q10 1.26, A 48.07 K) | 9.3× | 5.242 | −0.09 | **309** |
| q10 2.23, A 15 K (physical) | 11.1× | 4.494 | +0.17 | 453 |
| q10 2.23, A 10 K (physical) | 5.0× | 6.240 | +0.64 | 973 |
| q10 1.26, A 15 K | 2.0× | 9.155 | +0.71 | 3651 |
| q10 2.23, A 48.07 K | 2208× | 4.410 | −2.18 | 8008 |

Note the trade: `q10 2.23 / A 10 K` gets the AMPLITUDE much closer (6.24 vs 6.76) and is still
3× worse overall, because it costs 0.64 months of phase. **Phase is the sharply constrained
direction; amplitude is the slack one.** That is why the fit contorted to an unphysical corner —
it bought phase with amplitude, not the other way round.

**Suggested next tests, in order.**
1. **The SPO d13C 3.5× overshoot is the largest single seasonal misfit** and the cheapest to
   chase — SH seasonality is UNFITTED by construction (`R/model.R` ~line 197: "the offline work
   fitted MLO only"), and SPO's cycle is substantially oceanic, which the land-only term does
   not model. That comment predicted exactly this. Revisit it.
2. **Where does MLO's missing 22 % live?** Decompose the modelled MLO harmonic by turning each
   seasonal channel off in turn (NEP/insolation, respiration, air-sea) and re-running the
   harmonic. The NEP term's amplitude "is not a knob — it is the model's own NPP", so if the
   deficit is there it is an NPP-magnitude statement, not a seasonal one.
3. Only then reconsider whether `seas_T_amp_NH` needs a tighter prior.

## 5. TORCH — still unmeasured, and blocked on credentials

`ssh torch` reaches `login.torch.hpc.nyu.edu` through the `gw` ProxyJump, but the final hop is
refused (`Permission denied (gssapi-keyex,gssapi-with-mic,password,keyboard-interactive)`) and
`ssh-add -l` reports no identities. **R availability and version on Torch are therefore still
unknown** — §6 of the previous handoff is unchanged and its "check first" is still outstanding.
Marcus needs to load the key / establish the session.

**One measurement that does bear on it, made here:** a full 1750–2024 monthly run plus its
per-stream likelihood is **~2 s**, and 14 patch-rebuild-evaluate points took **32 s** wall
clock. So the 32.6 h refit is Nelder-Mead's eval COUNT, not per-eval cost — which is exactly
why §6's **parallel dispersed multi-start** is the right restructuring and a straight port
would buy nothing.

## 6. Open decisions (for Marcus) — the previous note's list, updated

1. ~~Seasonal phase geometry — fix or demonstrate right?~~ **ANSWERED: it is right.** The only
   change wanted is the two misleading comments on `CCX_SEAS_T_LAG` / `CCX_SST_SEAS_LAG`.
2. **`rep_dC`** — unchanged, still open (§3b of the previous note).
3. **Matched re-polish** — unchanged; moot if "indistinguishable" is accepted.
4. **`kz` bracket** — unchanged; pinned at ~98 % in both arms, must be settled before a sampler.
5. **Pump-shape smoothing** — unchanged, deferred.
6. **NEW: the seasonal amplitude deficit** (§4). Chase it before any sampler, since it is the
   thing driving `seas_T_amp_NH` / `q10` into an uninterpretable corner.

## 7. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-20b_seasonal_phase_closed_amplitude_open.md`. The seasonal PHASE
> hypothesis is dead — the observable is on time and the shipped lag wins by 18,944 log-units.
> The live work is **§4, the seasonal AMPLITUDE deficit**, starting with the SPO d13C 3.5×
> overshoot. Do not redo the refit for the phase convention.
