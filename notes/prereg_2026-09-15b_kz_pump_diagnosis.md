# PREREG (diagnostic tier) — THE kz / PUMP STRUCTURE, DIAGNOSED UNREFITTED AT `hilda30c`

**2026-09-15 (b). Written BEFORE any core edit and before any run, from HEAD `2e1b76c`.** Implements Marcus's 09-15 (b)
ruling: "the kz/pump structure, diagnose first — decompose what carries the bomb ¹⁴C (diffusion vs any advective path) and
what the δ¹³C rows are buying at kz ≈ 11,000 — a cheap unrefitted probe set, then a scoping note." Every number below is
read from the canonical's prepared invariants (`ccx_prepare()` at the `hilda30c` vector, this session) or from the mode
file; nothing is recalled. Torch verdict, said aloud: **laptop** — ≤ 300 C++ evals at ~0.2 s plus two R-path runs.
`hilda30c` stays canonical; nothing is adopted here; no refit is launched.

## 0. What is already known, and is the PRIOR on this — not its answer
- The 09-14 (g) review's root cause (1): kz **10,964** m²/yr at the ML base; the solved export **45.6 GtC/yr** (Nowicki LS
  9.08 [8.12, 9.92]); ML exchange with layer 1 **2.87 /yr** (layer 1's side 3.59 /yr) vs the air–sea 2.65 /yr — read as one
  object: "diffusion carries the bomb ¹⁴C, so kz is large, so the export must be large". ⚠ That chain was a READING; its
  first link (what carries the bomb ¹⁴C) was never measured. This prereg measures it.
- The E array (09-15): prescribing the export at 8.35 GtC/yr with a 243-Sv ventilation loop carried the bomb rows (pass)
  yet kz fell only ×1.27, the refit raised deep K ×5.9 and thinned the ML to 38 m, and the δ¹³C rows paid −29. ⇒ the bomb
  rows are NOT what holds kz up on their own; something else does. The candidates are the ocean sink row, the δ¹³C rows, the
  CO₂ record itself, and the DIC gradient.
- 08-31 ([[ccx_gates_priced]], 32-box column, pre-HILDA / pre-K(z) / pre-periodic): forcing kz down on a frontier that
  re-optimises `beta_max`/`fert_k`/`q10` makes every gate worse because the LAND takes over the drawdown. A RAW one-at-a-time
  scan manufactures its answer ([[match_incumbents_optim]]). ⇒ the kz scan here has a raw arm AND a land-compensated arm,
  and the second is the one that is read for "what holds kz".
- 09-08 (c): an unrefitted 1-D pin is charged FIRST through the CO₂-level rows. Expected, and why arm B exists.
- The pump's solved field is `S = div(kz_int · dC)` at the prescribed PI gradient (`R/model.R:3284-3288`): **the export scales
  linearly with kz** — a kz scan re-solves the pump, export ∝ kz. This is the "one object" mechanically; the scan reports it.

## 1. The instrument — a ¹⁴C EDGE RECORDER on the R derivative (recording only; no tendency touched)
The R recorder (`ccx_deriv(record = TRUE)`, `R/model.R:1836-1872`) logs CARBON per edge; nothing logs ¹⁴C by pathway on
either core. Built here: `.edges14` / `.pump14` / `.diff14` matrices (from + 1 × to + 1, the `.edges` layout), fed by
`add_flux` (after `f14`, the source-ratio ¹⁴C the tendency actually applies) and `add_diffusion` (the `tr == "C14"` pass);
exposed as `attr(dy, "fluxes")$edges14 / pump_edges14 / diff_edges14`. `ccx_run()` gains `edge_fn = NULL`: when given,
`res$edge_trace[[i]] <- edge_fn(fl, y, t)` at each month's opening state (the diagnostic decides what to keep; the core stores
nothing new by default). C++ untouched (the diagnostic runs the R path). **Test (the `test-fluxes.R` load-bearing pattern):
for every non-atmosphere box, `colSums(edges14) − rowSums(edges14)` must equal `dy[, "C14"] + λ·y[, "C14"]` to 1e-12
relative — proving the tap is complete and faithful. If it does NOT close, there is an unrecorded ¹⁴C tendency and THAT is
the first finding.**

## 2. The probes
**PK-1 — the bomb-¹⁴C PATHWAY BUDGET at the canonical** (`calibration/diag_kz_pump_pathways.R`). Paired R-path runs
1750–2025 at the `hilda30c` vector, bomb ON vs bomb OFF (`F$c14_bomb <- 0; F$c14_nuclear <- 0`, the `diag_bomb_partition.R`
idiom), `edge_fn` keeping the three ¹⁴C edge matrices and the state at each month. Excess = ON − OFF. Interior := `oc[1..10]`
+ `hd`, both hemispheres. Cumulative (dt = 1/12, opening-state fluxes) excess ¹⁴C ENTRY into the interior by pathway, at
1965 / 1975 / 1995 / 2010: (i) LS ML-base DIFFUSION net (`diff14[ml, oc1] − diff14[oc1, ml]`), (ii) LS ENTRAINMENT net (the
`(ml, oc1)` pair less diffusion less pump), (iii) LS PUMP (`pump14[ml, oc_k]`, all k), (iv) the HS ROUTE (`edges14[hs, hd] −
edges14[hd, hs]`, flush + HS pump). Also the SURFACE INVASION split (atm→ml vs atm→hs, net) and the per-LAYER budget
(diffusion from above, diffusion to below, pump, conduit `hd ↔ oc_k` net) for layers 1–10 at 1975 and 1995, against the
slab-A/B/deep bomb-excess inventories the `d14c_profile_*` rows read. Units: kmol ¹⁴C-signal (state × `mol_per_GtC × R14_STD`
inverted, `R/model.R:3113`) and shares.
**GATE PK-1g (closure, MEASURED tolerance).** For the interior as a whole: Σ pathway entries − decay = Δ inventory (ON − OFF).
The tolerance is NOT hand-picked: the SAME monthly Euler integration on the recorded CARBON edges (`edges`) gives a closure
error for C, and the ¹⁴C closure must be within 2× that relative error. **Mutation test:** drop pathway (iii) from the sum
⇒ the gate must FAIL by ≥ the pump's own share.
**PK-2 — the kz SCAN, two arms** (`calibration/diag_kz_pump_scan.R`, the C++ objective via `ccx_make_logpost(by_stream =
TRUE)` under the file's pins). Grid `kz × {0.35, 0.5, 0.7, 1, 1.4}` (log-spaced; the box is [1161.6, 27808]). Everything else
at the canonical vector; the pump re-solves (export ∝ kz). **Arm A — raw.** **Arm B — LAND-COMPENSATED:** at each kz,
`beta_max`, `fert_k`, `q10` re-optimised on the full logpost (`optim`, Nelder–Mead from the canonical, then BFGS polish; the
08-31 recipe), every other name held. **GATE PK-2g (self-check):** at kz × 1 the arm-B optimum must reproduce the stored
logpost (−1426.2428 after the pin shift) within 1e-3 — an optimiser that improves on the mode is a finding about the mode,
not a pass. Per point, both arms: the 25-row likelihood breakdown (Δ vs the canonical), the total, and the diagnostics: solved
export, `beta_max`, ML exchange rate, the modern surface–deep DIC gradient (the `ocean_grad_dic` reader), ocean sink 2010s,
atmospheric δ¹³C 2010 and its 1990–2010 trend, the seasonal δ¹³C amplitude at MLO, bomb ocean inventory 1975, IRF(100) if
cheap.
**PK-3 — the `kz_deep_frac` SCAN, arm A only**: f ∈ {0.0117 (canonical), 0.03, 0.06, 0.089 (the E mode), 0.15} at kz 10,964;
the same per-row read.
**PK-4 — the δ¹³C MECHANISM READ** (inside PK-2, no extra runs): for each kz in arm B, the cumulative 1850–2010 ocean vs land
¹³C-disequilibrium uptake (the two `d13c` sink channels from the same run's output) — whether the δ¹³C level rows move
BECAUSE the partition moved (land substituting for ocean) or because the ocean's own ¹³C uptake per unit carbon changed.

## 3. Predictions (falsifiable; each with its basis)
- **P1 (pathway).** At 1975, of the cumulative bomb-excess ¹⁴C delivered INTO the interior: diffusion + entrainment at the LS
  ML base ≥ **60 %**; the LS pump **5–20 %** (9.6 %/yr of the ML stock at ML composition vs a 2.87 /yr exchange on a
  fraction-of-excess gradient); the HS route **15–35 %** (12.8 % of area × `hs_asx_frac` 0.79 on gross invasion, but a 393-m box
  with no back-flux ceiling, flushed at 23.6 m/yr; the 09-06b "cold box takes too much" reading). If the HS route is > 35 %,
  the 09-14 (g) reading "diffusion carries the bomb ¹⁴C" is WRONG for the canonical and the structure question moves to the
  cold column. If the pump is > 20 %, the export IS a bomb-¹⁴C lever and the E result needs re-reading.
- **P1b (where it goes) — AMENDED before any run (§5).** By 1995 ≥ **80 %** of the ocean's bomb-excess ¹⁴C sits in the
  ML + layers 1–4 (≤ 435 m) + HS + HD; of the excess that entered layers 1–4, ≥ **70 %** came by diffusion from above
  (entrainment included), ≤ 30 % via the conduit (`hd → oc_k`). Basis: `tau_q` 538 yr on a_ls·dz_k volumes is 2–3 orders
  slower than kz/dz² over the top 300 m.
- **P2A (raw scan).** At kz × 0.5 the CO₂-level + ice-core rows carry the largest charge (the 09-08c behaviour); the bomb rows
  `d14c_NH + d14c_SH` charge ≥ **20** log-units combined (less ocean uptake ⇒ the 1965 atmospheric peak too high); the
  export halves to ~22.8 GtC/yr and the DIC-gradient row moves < 3 (the PI gradient is prescribed).
- **P2B (land-compensated — THE READ).** With the land three re-optimised at kz × 0.5, the CO₂-level rows recover to within
  **10** of the canonical, and the charges that remain rank: `d13c_level_MLO + SPO` ≥ **20** combined (the ¹³C budget prices
  the ocean/land partition — the double-deconvolution constraint; land carbon carries ε ≈ −18 ‰, ocean ≈ −2 ‰, so a land
  substitute leaves the atmosphere too heavy), `d14c_NH + SH` ≥ 10, `gcb_ocean_sink` ≥ 5 (z_ocean falls as in 08-31). **If the
  δ¹³C level rows move < 5 in arm B, they are NOT what holds kz and the E array's −29 there came from the ML thinning / the
  `hs_asx_frac` lean instead** — a different scoping.
- **P3 (deep frac).** f = 0.089 unrefitted costs ≥ **20** log-units, led by `ocean_grad_dic` (the deep gradient flattens) and
  `d14c_profile_bd` (the deep too young), with the CO₂ rows second. If instead it is cheap (< 5), the E refit's deep-K rise
  was free at the canonical and PE-1's "kz falls" premise was the wrong axis all along.
- **P4 (mechanism).** In arm B the land ¹³C-disequilibrium uptake rises with falling kz by at least the ocean's fall (the
  partition moves); the ocean's ¹³C uptake per GtC changes < 10 %.

## 4. Not claimed
- Nothing here is a frontier over the full parameter set: arm B re-optimises three land names only (the 08-31 recipe), so a
  charge that a fourth name could absorb is over-stated. Arm B's ranking is a read of WHICH rows, not a price.
- No σ changes, no new rows, no refit, no promotion. The scoping note that follows is the deliverable; the E array's
  `port_targets.csv` is stale for any other array and stays so until the next launch regenerates it.

## 5. Amendments (stamped; the original text stays above where it is struck)
- **A1 (before any run, after reading `ccx_model_d14c_slabs`, `R/likelihood.R:781`).** The `d14c_profile_ab/bd` rows read slabs
  A = 1500–2000 m and B = 2000–2627 m FROM THE SPINUP STATE — steady-state NATURAL ¹⁴C, set by K_deep, the conduit and decay;
  they are NOT bomb rows. The bomb rows are `d14c_NH/SH` (atmosphere) and `excess_c14_ocean` (the whole-ocean excess). P1b
  originally read the slab bomb-excess "against the rows"; that was a conflation and is replaced by the per-layer WHERE-IT-GOES
  read above. Consequence for the reading: the E array's −7.6 on the profile rows is a steady-state cost of deep K ×5.9, and
  PK-3 (the `kz_deep_frac` scan) is the probe that prices it — P3 stands.
