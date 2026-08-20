# Handoff — CarbonCycleEmulator, 2026-08-20: THE 21-PARAMETER REFIT LANDED. Arms indistinguishable, and three diagnostics point at a SEASONAL PHASE problem and a 6 ppm CO2 LEVEL BIAS.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
**Supersedes `handoff_2026-08-18d_refit_launched_hml_kink.md`** — that note's in-flight run is
this note's result. Its §1–§4 (the `ARM_HESS_EPS` check and the `h_ml` kink) still stand.

## 0. START HERE

1. **THE REFIT IS DONE.** `mode_fit_pump{N,D}.rds` + `pump_arms_comparison.rds` in
   `calibration/output/pump_arms/`. Log `refit_20260818.log`. 32.6 h wall clock.
2. **NEITHER MODE IS CONVERGED** (both hit the restart cap while still gaining), and they
   stopped UNEQUALLY — N gaining 0.45–1.24/restart, D 0.10–0.12. **N is further from its
   mode, and that asymmetry favours D.**
3. **DO NOT QUOTE THE EVIDENCE.** D − N = +10.61, and it is not usable: two non-converged
   modes, `kz` pinned in both, D's `log|-H|` carrying two step-unstable rows to N's one, and
   the optimisation asymmetry pointing the same way as the margin.
4. **THE ARMS ARE INDISTINGUISHABLE** — all 21 coordinates agree within ~0.1 prior-sd except
   `h_ml` (0.8σ). That, not the evidence, is the result.
5. **THREE DIAGNOSTICS RAN AFTER THE REFIT AND TWO OF THEM OVERTURNED MY FIRST READING.**
   §3 is the live work. **The seasonal PHASE geometry is the priority.**
6. Pre-refit 20-parameter modes are preserved in `pump_arms/pre_refit_20260818d/`.

## 1. Results

**Per-stream, D minus N — the reading REVERSES AGAIN.** Pre-refit it was "D's gain is entirely
the CO2 record"; the 08-18 morning refit made it "CO2 ties, δ¹³C levels (N) vs sinks+¹⁴C (D)".
**Now D's gain is ENTIRELY THE SEASONAL ROWS**: `co2_seasonal_MLO` **+12.68**,
`d13c_seasonal_SPO` +9.56, `d13c_seasonal_MLO` +5.45, `co2_seasonal_SPO` +4.36 (**+32.1**),
against `gcb_ocean_sink` −7.36, `d14c_SH` −4.67, `d13c_level_MLO` −3.14, `d14c_NH` −2.88,
`co2_icecore` −2.42. CO2 levels tie. **The arms differ exactly where the 08-18 rework added
new physics** — which is a reason to fix the seasonal model before re-adjudicating N vs D.

**Five parameters beyond 3σ, the SAME five in both arms, agreeing to two decimals** (N / D):
`rep_dC` +6.44/+6.67, `sst_seas_amp_NH` −6.03/−6.06, `sst_seas_amp_SH` −4.72/−4.63,
`seas_T_amp_NH` +3.83/+3.78, `bomb_total` +3.24/+3.33. Reproducing under a different pump
structure makes them **structural, not search artifacts**.

**Standing questions.** `kz` PINNED both arms (98.8 % / 98.2 %) — §5.2h P2 again. `h_ml`
INTERIOR, gradient rows LIVE both (95.66 / 88.39 m). `pump_grad` 310.71 / 319.23, ABOVE the
233.11 prior centre and above the old 1-D optimum 274.5.

**The pre-launch Hessian checks earned their place.** `h_ml` was CLEAR of the kinks in both
arms (gaps 2.75 m / 10.02 m vs steps reaching 2.2e-3 / 9.2e-4 m). Step-stability flagged `kz`
in N and **`h_ml` AND `kz` in D** — D's `h_ml` sits 3.4 m off the band's lower bound and reads
the bound, not the data.

## 2. THE OPERATOR ERROR — read before running anything long

**`run_modefind_pump_arms.R` was edited WHILE RUNNING** (the runtime-header correction,
`9f5bf71`) on the false premise that the running process had already parsed it. **Rscript
parses INCREMENTALLY.** Inserting ~15 lines near the top shifted every later byte offset and
the job died mid-expression ~30 h in with `Error: unexpected symbol`.

Both arms had already written their rds and the comparison had already printed, so the loss was
the standing-questions print and `pump_arms_comparison.rds`. Rebuilt by
`calibration/finish_pump_arms_comparison.R`, which reads ONLY the two arm files (so it cannot
introduce a number the run did not produce) and gates that they are the same run first.

**RULE: never edit a script a long job is executing. Copy it, edit the copy.**

## 3. THE THREE DIAGNOSTICS — and the two corrections

### 3a. THE SEASONAL PHASE GEOMETRY IS ~1–2 MONTHS LATE (`diag_sst_seas_zeroing.R`)

**My first reading — "degeneracy, not a phase bug" — was WRONG, and so was the script line that
printed it.** That test compared AMPLITUDES only; the likelihood scores `ccx_year_harmonic`'s
sin/cos coefficients, i.e. **amplitude AND phase**. Moving `sst_seas_amp_NH` from its fitted
0.089 K to the physical 2.0 K, per stream:

| stream | Δ logL |
|---|---|
| `co2_seasonal_MLO` | **−673.4** |
| `co2_seasonal_SPO` | +88.7 |
| `d13c_seasonal_MLO` | +29.4 |
| `co2_level_MLO` | −1.1 |

A physical ocean cycle **helps SPO and δ¹³C and destroys MLO CO2** — amplitude improves
(5.30 → 3.89 ppm against obs 3.02) while phase rotates away. **The annual-mean rectifier
hypothesis is also dead**: mean CO2 moves 379.41 → 379.35 ppm, and `co2_level_MLO` only −1.1.

**MEASURED PEAK MONTHS** (`ccx_insol`, the T sines, on a monthly grid):

| driver | NH code | NH expected | SH code | SH expected |
|---|---|---|---|---|
| seasonal SST | **Oct** | Aug–Sep | Mar | Feb–Mar |
| land seasonal T | **Sep** | Jul | **Mar** | Jan |
| insolation / NPP | **Aug** | Jun–Jul | **Feb** | Dec–Jan |

**Everything is 1–2 months late, systematically, in both hemispheres.** The `(3.5 + LAG)/12`
convention puts the zero-lag land-T peak at mid-July; `CCX_SEAS_T_LAG = 2.0` then pushes it to
**mid-September**, while the constant's own comment says "seasonal land T peak after Jun" —
i.e. August. That is a ~1 month discrepancy between the code and its own stated intent.

**THE EXISTING GATE CANNOT CATCH THIS.** The 08-18 verification checked mid-Jan vs mid-Jul
respiration factors (NH 0.56 / 1.28). Both sit on the same side of a 1–2 month phase error, so
it passes either way — `mutation_test_gates` again.

**The profile is an INTERIOR optimum, not a rail** (all else frozen at the mode):

| amp (K) | 1e-4 | 0.01 | 0.05 | **0.089** | 0.25 | 0.5 | 1 | 2 | 4 |
|---|---|---|---|---|---|---|---|---|---|
| Δ logpost | −165 | −26.5 | −2.6 | **fitted** | −13.2 | −53.1 | −167 | **−513** | −1664 |

So the likelihood sharply and genuinely wants ~0.09 K. **The −6σ is against the PRIOR; the
LIKELIHOOD has a clean interior optimum there.** The parameter is not railing — it is being
told, by a phase-sensitive stream, that the physical value is 513 log-units wrong.

**NEXT TEST, and it is the one that settles it:** compare the MODELLED MLO CO2 seasonal phase
against the OBSERVED phase the likelihood already scores (`ccx_year_harmonic` on obs vs model,
the sin/cos coefficients, not the amplitude). If the model's phase is 1–2 months late, the
geometry is the bug and `sst_seas_amp` is the messenger. The "expected" column above is my
statement of climatology and should itself be checked against HadSST4's own monthly
climatology, which the repo has.

### 3b. `rep_dC` IS CORRECTING A ~6 ppm CO2 LEVEL BIAS, NOT THE SUESS OVERSHOOT (`diag_rep_dC_pinned.R`)

**My first reading — "it is absorbing the Suess overshoot" — was WRONG.** Fitted +5.9554 ppm
(≈6σ). Pinning it to zero costs **3,959 log-units**, and it pays in ALL FOUR level streams:

| stream | Δ logL (free minus pinned) |
|---|---|
| `co2_level_SPO` | **+1082.0** |
| `co2_level_MLO` | **+1072.3** |
| `d13c_level_MLO` | +950.8 |
| `d13c_level_SPO` | +605.2 |

The pre-registered criterion was: a representation offset pays in BOTH species (mass balance);
a bias sink pays in δ¹³C and **CHARGES** CO2. **It pays hugely in CO2, so it is not the bias-sink
signature.** What it is: **the mode carries a ~6 ppm roughly uniform CO2 level bias, and
`rep_dC` is the only parameter that can shift CO2 level directly.** The δ¹³C partner offset
(−0.2917 ‰ via the −0.04898 ‰/ppm coupling) comes along and happens to help too.

This is a model/input problem wearing the parameter, and it connects to the standing
`ccx_co2_level` ("CO2 vs GCB budget disagree") and `ccx_luc_input` ("30 ppm misfit is an INPUT
error") threads. Some share is also incomplete optimisation — the mode is not converged.

### 3c. `seas_T_amp_NH` = 48 K IS A DEGENERACY WITH `q10`

`q10` fell **2.2275 → 1.2613** (below its literature range) while `seas_T_amp_NH` rose to
**48.07 K** (impossible as a land seasonal temperature amplitude). Only the product enters, so
the realised respiration swing is **9.3×** peak-to-trough — large but not absurd:

```
Jan 0.43  Feb 0.28  Mar 0.25  Apr 0.28  May 0.43  Jun 0.75
Jul 1.31  Aug 1.97  Sep 2.28  Oct 1.97  Nov 1.31  Dec 0.75
```

**Respiration peaks in September**, consistent with 3a. This is 18c §5.1's watch-item ("`q10`
now has seasonal duty") resolving into an unphysical corner. **Neither parameter is
individually interpretable at this mode.**

## 4. N vs D — there IS a reason beyond fit, and it favours N

**DESIGN.md line 723 labels them: `"N"` nutrient-limited (mass fixed) / `"D"` DIC-limited.**

- **Scientific:** marine export production is limited by N, P and Fe, not by carbon — DIC is
  not limiting for phytoplankton. N is the conventional assumption for a box model of this
  class. D implies export RISES as DIC rises, a negative feedback on atmospheric CO2 that
  mainstream models do not carry. *(Stated as the conventional position — NOT backed here by a
  specific citation. Check before it goes in writing.)*
- **Pedagogical:** DESIGN.md line 740 — a constant-mass pump changes the ocean sink by EXACTLY
  ZERO; mode D by construction does not. N therefore gives the app a clean, teachable
  separation: *the biological pump sets the ocean's vertical carbon gradient but does not by
  itself change how much carbon the ocean absorbs.* D entangles pump and sink.

**RECOMMENDATION: keep N — not as "N won", but as "the data do not distinguish them and N is
the defensible default."** The two refits disagree in SIGN on this question (08-18 morning:
N by 5.62; 08-20: D by 10.61), on different objectives, which is itself evidence the comparison
is not resolving anything. Consider carrying `pump_mode` as a structural uncertainty through the
ensemble instead of choosing.

## 5. Open decisions (for Marcus)

1. **The seasonal phase geometry** — fix `(3.5 + LAG)/12`, or demonstrate it is right? Gates
   everything: the seasonal rows are where the arms differ and where three of the five flagged
   parameters live. A fix means the refit is redone (~33 h, or far less — see §6).
2. **`rep_dC`** — now that it is a CO2 level bias and not a d13C sink: chase the 6 ppm bias, or
   tighten the prior and let it show in the residuals?
3. **Matched re-polish** — only worth it if an evidence number is wanted; moot if
   "indistinguishable" is accepted (§4).
4. **`kz` bracket** — pinned at ~98 % in both arms; must be settled before any sampler.
5. **Pump-shape smoothing** (18d §3) — deferred, the kinks did not bite.

## 6. TORCH — recommended for the next big compute, but RESTRUCTURE, do not port

Nelder-Mead with 20 SEQUENTIAL restarts is inherently serial; Torch would not touch the 15 h,
and running the two arms concurrently is only 2× (RSS is 158 MB, so the driver's
swap-thrashing argument for sequential arms does not survive measurement — see the 08-18
CHANGELOG entry).

**The win is replacing sequential restarts with PARALLEL DISPERSED MULTI-START**: 20+
independent starts at once, take the best. Embarrassingly parallel, ~15 h → under an hour on 20
cores, **and a better estimator** — it samples basin structure instead of walking one
trajectory, which is exactly what the non-monotone gain sequence and the 31–35 log-unit BFGS
jumps say is needed. The pilot MCMC (never converged) benefits more still.

**Check first:** R availability and version on Torch. See the `nyu-torch-hpc` skill for the
ProxyJump config, partitions, and the login-node SIGKILL / NFS mmap gotchas.

## 7. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-20_refit_landed_seasonal_phase.md`. The 21-parameter two-arm
> refit landed; **the arms are indistinguishable and the evidence is not quotable**. The live
> work is **§3a, the seasonal phase geometry** — every driver peaks 1–2 months late and that is
> probably why `sst_seas_amp` is being zeroed. Start with the modelled-vs-observed MLO CO2
> seasonal PHASE comparison named at the end of §3a. Do not re-adjudicate N vs D until the
> seasonal model is fixed — that is where the arms differ.
