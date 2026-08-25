# Handoff — CarbonCycleEmulator, 2026-08-24b: the plateau leverage question, settled

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `4ee56ba`.
**Tests:** 1007 pass, 2 fail — both the **pre-existing by-design** `test-fluxes.R:99/100`,
verified against a clean `git stash` before and after this session's work.

**Read with:** `handoff_2026-08-23c_ocean_box_next.md` (the build spec this discharges),
`handoff_2026-08-24_ocean_box_result.md` (the at-mode three-arm comparison), and the two
pre-registrations — `prereg_2026-08-24_ocean_sink_14c_null.md`,
`prereg_2026-08-24b_ocean_probe_rate_scan.md`. **This one is self-contained on the leverage
result.**

---

## 0. STATE IN EIGHT LINES

1. **MARCUS'S QUESTION IS ANSWERED, AND THE ANSWER IS "NO".** Relieving the plateau decade does
   not relax `rep_dC`. §2. Six refits, all predictions pre-registered before launch.
2. **`rep_dC` moves |≤0.32| σ with an INCONSISTENT SIGN** in every live arm, free or pinned,
   where the `foss` probe moved it **−6.02 σ** at the same CO₂ relief. §2.
3. **The relief `foss` bought was payment for its PERMANENT LEVEL SHIFT**, not for the plateau. §3.
4. **There is no rate at which relieving the plateau improves the plateau term.** §4 — the model
   already sits 1.67 ppm BELOW the ice there.
5. **P3 was FALSIFIED and the lesson generalises.** §5. I claimed an escape route was closed by
   construction; it moved 2.94 σ.
6. **Four of my thresholds/labels were wrong, one fired against a CORRECT result.** §6.
7. **DE-RANK the plateau.** `rep_dC` belongs to the century drift, already traced to GCB's own
   budget imbalance (r = 0.771). §7.
8. Still no posterior. Objective unchanged. All sink switches still default OFF.

---

## 1. WHAT WAS RUN

Six refits of arm N, `CCX_SINK_MODE=ocean`, scoping `RESTARTS=8 CYCLES=2` — **identical to the
2026-08-23 `pump_arms_SINK25*` runs**, so the scan is like-for-like with them. 4-way then 2-way
parallel, BLAS pinned to one thread each (`OMP_NUM_THREADS`, `VECLIB_MAXIMUM_THREADS`,
`OPENBLAS_NUM_THREADS` = 1), ~150 MB RSS per arm, 0.15 s/eval.

`calibration/output/ocean_probe_scan/` — **SCRATCH, never the shipped mode.**
Analysis: `calibration/diag_ocean_probe_scan.R` (also writes `scan_summary.rds`).

**Rate 0 is the matched zero and it reproduces the shipped mode, gain 0.0000 in 13.8 min.** That
is a gate, not a throwaway: the scan's reference is the adopted mode itself rather than a
re-derivation that might have drifted.

## 2. THE RESULT

| arm | logpost | `rep_dC` | Δσ | `luc_scale` Δσ | (`beta_max`,`fert_k`) Δσ |
|---|---|---|---|---|---|
| 0 | −1859.32 | 5.5658 | — | — | — |
| 2.5 | −1860.38 | 5.6042 | +0.16 | +0.52 | −0.14 / −0.19 |
| 9.434 | −1874.34 | 5.6447 | **+0.32** | +1.90 | −0.54 / −0.72 |
| 15 | −1895.97 | 5.6174 | +0.21 | **+2.94** | −0.84 / −1.12 |
| 9.434 **pin** | −1868.5 | 5.6086 | +0.18 | pinned | +1.31 / +1.13 |
| 15 **pin** | −1893.4 | 5.5252 | −0.17 | pinned | **+2.08 / +1.75** |

> **A PINNED ARM'S LOGPOST AND LAPLACE EVIDENCE ARE NOT COMPARABLE TO A FREE ONE'S** — the
> `luc_scale` prior was replaced by a near-delta. Read parameters and per-stream logL only. The
> driver tags pinned arms with a trailing `P` and says so in its header.

**Verdicts: P1 HOLDS / P2 HOLDS / P3 FALSIFIED / P4 HOLDS / P5 HOLDS / P6 HOLDS.**

## 3. WHY THE `foss` PROBE LOOKED LIKE IT WORKED

`foss` at 2.5 GtC/yr and `ocean` at 9.434 have the **same window-end CO₂ drawdown, −6.51 ppm by
construction**. They differ in what happens afterwards:

| | 1950 | 1960 | 2024 |
|---|---|---|---|
| `foss` 2.5 | 1.00 | 0.715 | **0.420** |
| `ocean` 9.434 | 1.00 | 0.224 | **0.033** |

`foss` applies a **permanent level shift**; `ocean` is a pulse. With `luc_scale` pinned in both,
`foss` moved `rep_dC` **−6.02 σ** and `ocean` **+0.18 σ**. **⇒ the `rep_dC` relief was bought by
the persistent half of the `foss` probe, which is a level correction — `rep_dC`'s and
`luc_scale`'s own job — and not by explaining the plateau at all.**

## 4. THE PLATEAU TERM ITSELF

`co2_icecore` vs rate 0: **0.00 → +0.87 → −5.53 → −19.16.** Non-monotone, as pre-registered.

The ice residual (model − obs, ppm) at the mode, by era: **−1.89 / −4.09 / −3.10 / −1.67 / +1.17 /
+4.83** over 1850-1900 / 1900-35 / 1935-42 / 1942-50 / 1950-60 / 1960-2000. **The model already
sits 1.67 ppm BELOW the ice in the plateau window**, so pushing that decade down overshoots almost
immediately. The error is a **monotone century-long drift** and the plateau window sits mid-drift.

## 5. P3 WAS FALSIFIED — THE METHODOLOGICAL FINDING

I predicted `luc_scale` < 1 σ (falsifier 2 σ) because the probe's time-shape (3.3 % of its 1950
effect left by 2024) is nearly orthogonal to a `luc_scale` rescale's (196 % by 2024), and claimed
the escape route was **closed by construction**. **It moved +0.52 / +1.90 / +2.94 σ.**

> **A FIT DOES NOT NEED TO MATCH A PERTURBATION'S SHAPE TO ROUTE AROUND IT — it only needs to
> trade enough likelihood elsewhere.** Orthogonality bounds the **exchange rate** (measured
> 0.34× `foss` at matched CO₂ effect), never the possibility. **Predict the exchange rate, not a
> yes/no, and pin the lever anyway when the conclusion depends on it not moving.**

**Escape routes, in the order the model uses them:** `luc_scale` first (+2.94 σ); with it pinned,
the (`beta_max`, `fert_k`) ridge (ρ = +0.997) takes over at **+2.08 / +1.75 σ** — the same second
route the pinned `foss` run used (0.93→2.70, 423→1738).

## 6. FOUR WRONG THRESHOLDS OF MINE, AND A SEED-COPY TRAP

All caught by reading output, none by a gate. One fired **against a correct result**.

1. **THE PIN GATE, hand-picked at `1e-6`**, errored with *"the pin did NOT bind"* when it had bound
   perfectly. `ARM_PIN_SD` is **1e-4 in LOG space**, so `luc_scale` may move ~9e-5 absolute; the
   converged arm sat **1.04e-6** away = **0.01 prior sd**. Now derived as **10 × the pin's own
   prior sd**, which still rejects a free arm by 70×.
2. **`paste0(character(0), "P")` is `"P"` in R**, not `character(0)` — the scalar recycles against
   the empty vector, injecting a phantom column that killed the run in `ccx_par_to_unc()`.
3. **"ratio at matched CO₂ effect"** was computed from the **unmatched** largest arm.
4. **Monotonicity** was tested on differences that dropped the reference arm's implicit 0.00 — the
   point the rise-then-fall turns on — and printed *"monotone? YES"* for 0.00 → +0.87 → −5.53.
5. The pre-registration quoted **−21 σ** where the measured value is **−6.02 σ**; corrected in
   place with a **visible note**, because a wrong number in a pre-registration is the last thing
   that should be quietly repaired.

> **THE SEED-COPY TRAP, for any warm-started scan.** Every arm dir was seeded with a copy of the
> adopted mode so the warm-start path runs as production does — so **`mode_fit_pumpN.rds` exists in
> an arm that has not started, and it is the UNPERTURBED reference.** Keying completion on it
> reported the still-running rate-15 arm as finished with every delta exactly **+0.00**.
> Completion now keys on `pump_arms_comparison.rds` (written once, at the end) **plus** a
> bit-identity gate. All-exactly-zero is a code path, never nature.

## 7. WHAT THIS CHANGES

- **DE-RANK "fit the mid-century".** Two independent instruments now say the plateau is not where
  the leverage is: the isotopes cleared the ocean routing (08-24a) and the leverage scan says
  relieving it buys nothing (this one).
- **`rep_dC` belongs to the CENTURY DRIFT**, not the plateau. That drift was already traced to
  GCB's own budget imbalance (r = 0.771, slope 0.781; `ccx_swing_not_carbon`). **That is where
  `rep_dC` work should go next**, and it is an INPUT problem, not a calibration one.
- The three sink switches stay OFF by default and are research instruments only.

## 8. OPEN FOR MARCUS

1. **`ocean_deep` — now for a NEW reason.** `ocean` differs from `foss` in **two** ways,
   persistence AND isotopic signature, so §3's pair does not strictly isolate which drives the
   `rep_dC` difference. The mechanism argument favours persistence (`rep_dC` is a CO₂ *level*
   offset; only persistence touches the level after 1960) but it is an argument, not a
   measurement. **`ocean_deep` has `foss`'s CO₂ trajectory and `ocean`'s isotopes, so it
   discriminates them directly.** Its vertical profile is a mechanism choice — pump export shape
   (couples it to `pump_grad`), top interior box, or uniform — and **I have not made it**.
2. **Carried from 23c:** whether to pin `beta_max`/`fert_k`. §5 shows the ridge IS the second
   escape route. Pinning three levers closes both known routes but may cross from testing the
   model into constraining it to an answer.
3. **The century drift** (§7) as the successor programme to the plateau arc.

## 9. NON-OBVIOUS STATE

- **`ccx_scaled_forcing()` and `ccx_make_logpost()` ERROR on the `luc` sink arm** when
  `luc_scale != 1` (`.ccx_assert_luc_arm_safe`). They apply `luc_scale` as a **column multiply**,
  exact only because the LUC columns are LINEAR in the annual series; the `luc` arm makes them
  **affine**. Build that arm with `ccx_build_forcing(luc_scale =, sink_mode = "luc")`.
- **`obs$d14$NH` DOES NOT EXIST** — `ccx_prepare_obs()` returns `d14_nh`/`d14_sh`
  (`t`, `d14c`, `sd_meas`, `sd`). The ice term is `obs$ice$CO2ppm` interpolated at `ice$year`
  (**not** `year + 0.5`) against **`co2_SH`**, and it carries **no `rep_dC`**.
- **`CCX_SCAN_DIR`** overrides the scan directory so the pinned reporting path can be exercised
  against a throwaway tree — the live `_PINLUC` dirs are unsafe to fake into (see the seed trap).
- **14 ¹⁴C is NOT conserved and must not be gated as a total** — it decays; a closed-system gate
  fails at 4.2e-4 = λ. Gate a new flux's contribution as a **difference** (on minus off).
- Scratch dirs never to ship: `pump_arms_SINK25/`, `pump_arms_SINK25_PINLUC/`,
  `ocean_probe_scan/`.
- **Do NOT quote 12.7 σ** for the terrestrial rejection — it is ~5.1 (range 5–7).
- Everything in 23c §6, 23b §5 and 24a §7 still applies.

---

## 10. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-24b_plateau_leverage_settled.md`.
>
> **The plateau arc is CLOSED on both fronts.** ¹⁴C cleared the ocean routing (08-24a) and six
> refits say relieving that decade does not relax `rep_dC` (08-24b) — the `foss` probe's apparent
> relief was payment for a permanent level shift. §8 carries the three open decisions.
>
> **Do NOT** re-run the six arms expecting a different answer, build `ocean_deep` without settling
> its vertical profile, attribute `rep_dC` to the plateau, quote 12.7 σ, re-centre `rep_dC`'s
> prior, or ship any `ocean_probe_scan` / `pump_arms_SINK25*` output.
