# Handoff — CarbonCycleEmulator, 2026-08-26: an isotope bug was fixed and the ridge verdict FLIPPED

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `7e126c8`.
**Machine reboot pending.** `ref` (pid 7879) will die with it; that is fine — see §5.

## 0. STATE IN SEVEN LINES

1. Handoff 08-25b's §4 premise was **wrong**: the station-level streams carried −0.1 % of the ridge
   veto, not 93 %. §1.
2. The veto was a **mean shift on white residuals**, immune to any effective-n reweighting. §1.
3. Its cause was a **bug**: `R/model.R` discriminated BOTH halves of the zero-mean seasonal NEP
   flux. **FIXED in both cores**, commit `6bda464`. §2.
4. **THE OBJECTIVE CHANGED.** Every pre-fix vector, arm N included, is **quarantined**. §3.
5. A 3-arm pre-registered refit was launched. **P3 FALSIFIED: a free arm seeded at `fert_k` = 90
   landed at 154.85 and beats the reference by +15.43 log-units.** There is a second basin. §4.
6. **For the first time the posterior's own preferred free mode moves gate 4 the right way** and
   passes gate 12 at 2 of 3 horizons. §4.
7. `ref` is a worse local optimum and was going to be stopped anyway. §5.

## 1. What 08-25b's inherited question turned out to be

`calibration/diag_landed_gap_streams.R`, `calibration/diag_stream_neff.R`;
`notes/collect_2026-08-25c_the_veto_is_not_a_weighting.md`.

08-25b §4 asked whether two CO₂ station-level streams should outvote the pulse response, on a
FROZEN-scan decomposition giving them 93 % of pin90's 86.7-log-unit penalty. **Measured at the
LANDED modes they carried −0.1 %** (net +0.09). The gap was `d13c_seasonal_SPO` −38.16 +
`d13c_seasonal_MLO` −24.22 + `gcb_land_sink` −24.00 = 100 %.

The effective-n audit (all 15 annual streams) **inverted the suspect list**: the station levels ARE
weakly informed (Geyer n_eff 12.6/66 and 13.2/59) and are exactly the streams that did NOT pay; the
three that paid had n_eff ≈ N with ρ₁ inside the white-noise band, and **all of their delta was
BIAS** (−38.12 / −24.96 / −24.48 vs scatter −0.04 / +0.73 / +0.48). Repricing gave a **15 % haircut,
not two orders of magnitude**. So the objection was physical, not a stream weight.

## 2. The bug

`R/model.R` emitted `add_flux(iatm, ilef, seas, alpha13 = aux$alpha_photo)`. **`seas` is zero-mean
by construction**, so it is negative half of every year, and `add_flux` swaps the SOURCE box for a
negative flux **while still applying `alpha13`** — autumn respiration out of the leaf pool was
discriminated a SECOND time. Photosynthesis discriminates; respiration does not.

**Receipt, no model needed:** a closed two-box system, one 60 GtC/yr zero-mean sinusoid, 50 cycles —
carbon returns to 9e−13 GtC and δ¹³C drifts **−0.124 ‰ PER CYCLE**, forever.

**Nothing caught it** because ¹³C conservation is antisymmetric (blind to a mis-partition), R↔C++
parity shares the rule, and `test-conservation.R:82` + `test-parity.R:72/151` all set
`seas_drivers <- 0`. New `tests/testthat/test-seas-isotope.R` is the first test here that runs the
seasonal isotope path with `seas_drivers = 1`.

**Option 1 adopted** (bidirectional NEP: no α on the return) over option 2 (GPP modulation), because
the NH leaf pool's CARBON oscillates by **38 % of its own mass** peak-to-trough — carbon really does
flow leaf→atm. Post-fix the two options differ by 0.012–0.025 ‰.

**The guard is the durable half:** `add_flux` now REFUSES a negative flux carrying `alpha13 != 1`.
Reviewed sites declare `alpha13_signed = TRUE` with a stated reason — (a) one-way by construction
(air-sea limbs, artificial sink, GPP limbs), or (b) **genuinely signed and OPEN: the biological
pump**, where `ccx_pump_export()` builds `S[k]` as a flux DIVERGENCE, negative in 2 of 10 layers
carrying 0.4 % of gross. **Grandfathered bit-exactly, NOT fixed — Marcus's call.**

## 3. QUARANTINE — read before using any mode file

`calibration/output/quarantine/20260825_seas_isotope_rectification/` holds **every pre-fix fitted
vector**, arm N included, with a README. **Nothing fitted before `6bda464` is comparable.** Same
class as the 2026-08-22 ice-hemisphere change.

## 4. The refit — `notes/prereg_2026-08-25f_post_isotope_fix_refit.md`, and §5 of
`notes/collect_2026-08-25g_post_fix_refit_p3_falsified.md`

| arm | logpost | `fert_k` | `enh(420)` | `rep_dC` | AF trend | TH20/50/100 |
|---|---|---|---|---|---|---|
| pre-fix ref | −1859.32 (old obj.) | 554.5 | 0.207 | +5.566 | −0.0007 | ✗✗✗ |
| `ref` cycle 2, **NOT FINAL** | −1559.6 | 483.1 | 0.212 | +3.834 | −0.0006 | ✗✗✗ |
| **`from90` FINAL** | **−1544.61** | **154.85** | 0.245 | +3.378 | **+0.0080** | ✗✓✓ |
| `pin90` FINAL, pin removed | −1556.17 | 90 (pinned) | 0.288 | +3.093 | +0.0137 | ✓✓✓ |

**P3 FALSIFIED** (predicted > 400, falsifier < 200). **P4 FALSIFIED** — `rep_dC` 3.834, the largest
mover in the vector at 1.73 prior sd where nothing else exceeds 0.58. **P2 not supported as stated**
(it failed to name `rep_dC`). **P5 holds** — SPO partition 1.47–1.50×, improved from 2.45× but not
closed. **P1 settled on the evidence** (`from90` and `pin90` both far above the frozen post-fix
−1909.0) though `ref` was not run to convergence.

`from90`'s +15.43 is `co2_icecore` +7.82, `co2_seasonal_SPO` +5.13, `co2_level_MLO` +3.94 … against
**`gcb_land_sink` −7.94** — the exact inverse of the pre-fix decomposition. The land sink is the one
objection that survives, outvoted rather than decisive.

## 5. NON-OBVIOUS STATE — read before touching anything

- **THE CANONICAL MODE IS `from90`, NOT `ref`.** Highest free arm wins regardless of name.
  `calibration/output/refit_20260825f_from90/mode_fit_pumpN.rds`.
- **⚠ RESTARTING `ref` HAS A TRAP.** The driver warm-starts from `ARM_OUT(mode)` =
  `<dir>/mode_fit_pumpN.rds`, and in `refit_20260825f_ref/` **that file is still the SEED I copied
  in** (the pre-fix mode, logpost −1909 under the new objective, mtime 2026-08-25 20:41). Cycle 1's
  real result is in `mode_fit_pumpN_progress.rds` (−1560.05, mtime 08-26 12:21). **Copy the progress
  file over `mode_fit_pumpN.rds` before relaunching, or you throw away 16 hours.** The driver has no
  resume-from-progress path; adding one is the prerequisite for ever running this inside a 4 h
  SLURM wall.
- **`h_ml` is bounded to [85, 120] by the driver** and must be restored before recomputing any
  logpost from these files, or every arm is off by ~1.1 in the same direction and `u_mode` does not
  decode at all (max |u − u(par_mode)| = 1.7). `par_mode` is the authority. [[ccx_hml_band_provenance]]
- **The pin offset is +11.6698**, computed from the transform at `fert_k` = 90. Do not quote the old
  +11.33–12.21 range.
- **A progress file carries no `param_names`** — assert ordering on `names(par_mode)` instead.
- **Eval cost:** 0.162 s/eval by the driver's own counter (which includes cheap −Inf rejections),
  0.422 s/eval measured for valid evaluations under 3-way load. ~332k evals per arm in cycle 1.
- **`kz` still rails** at 6140–6431 against a bracket top of 6528. Unchanged by any of this.
- **STILL NO POSTERIOR.** All of this is mode-finding; the sampler has never converged.

## 6. NEXT

1. **Decide `ref`'s fate.** Recommendation: leave it dead. Its only unique job was P1, already
   settled. If it is wanted, apply the §5 restart trap fix first.
2. **The pump's `alpha13_signed` (b) case** — 0.4 % of gross, and `PUMP_EPS13_ORG` is uncited.
3. **A DESIGN §6 gate sweep** at the new modes — four gates were re-measured, there are more.
4. **The reparametrisation race, REDESIGNED.** `calibration/diag_ridge_reparam.R` exists and its
   gate passes (`lp2(v) = lp(u(v))` to 2.6e−9), but its starts are at lp −26,000 to −150,000, i.e.
   1.4–8× worse than the driver's COLD init — it measures gross descent, not the near-optimum
   ridge-crawling that costs 332k evals. Use start sd ≈ 0.02–0.03 (median lp −1,672),
   evals-to-threshold as the statistic. It parallelises: ~50 min on four free cores.
5. **Torch** — worth it for arm COUNT and the MCMC, not for a single arm (Nelder-Mead is serial).
   `cpu_short` caps at 4 h wall = ~89k iterations, so MCMC needs `cs` or checkpointing.
