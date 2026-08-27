# COLLECT 27j — **ONE FIX: CONFIRMED. INTERACTION +64.99 AGAINST A GATE OF +39.59.**
# The channel finally lands inside its physical band, the ocean limb rotates 5.11 months into
# place — and the residual that is left is STILL LAND

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
**Pre-registered:** `notes/prereg_2026-08-27j_joint_land_ocean_arm.md`, committed **`fa83faa`
before `calibration/diag_joint_land_ocean_refit.R` existed.** No gate was moved.
**Nothing in `R/` or `src/` was touched.** All four arms converged (1 restart, last gain 0.0000).

    Rscript calibration/diag_joint_land_ocean_refit.R    # ~75 min, four optimiser arms

---

## 0. THE SCORECARD AS IT SCORED

| | prediction | result | verdict |
|---|---|---|---|
| **P0** | method control reproduces 27h/27i | total 1.141, SH-land 1.308, NH-orig 0.821, ratio 1.930, offset −3.3223 — all exact | **PASS** |
| **P1** | INTERACTION ≥ 0.5 × land-only cost = **+39.59** | **+64.99** | **CONFIRMED** |
| **P2** | `ent_seas_amp_SH` ∈ [5, 30] | **8.11** | **PASS** (27g: 4.16, below) |
| **P3** | SPO δ¹³C-per-ppm ≤ 1.70 | **1.390** | **PASS** |
| **P4** | SPO total ∈ [1.114, 1.222] | **1.267** (+8.5 % on obs 1.168) | **FAIL** |
| **P5** | SPO ocean ratio ≥ 0.75× | **0.495×** | **FAIL** |
| **P6** | MLO control ∈ [0.90, 1.10] | **0.966** | **PASS** |

---

## 1. P1 — THE INTERACTION, AND IT IS THE RESULT

| arm | land | ent | vs INCUMBENT | npar |
|---|---|---|---|---|
| INCUMBENT | 0.5027 | 0 | 0 | 6 |
| LAND-only | 0.352 | 0 | **−79.18** | 6 |
| OCEAN-only | 0.5027 | 4.31 | **+11.93** | 7 |
| **JOINT** | 0.352 | **8.11** | **−2.26** | 7 |
| | | | *sum of singles* **−67.25** | |

    INTERACTION = JOINT − LAND − OCEAN + INCUMBENT = +64.99      npar 7−6−7+6 = 0

**82 % of the land reduction's 79-log-unit penalty is recovered when the channel is present.** The
count balances to zero, so unlike a bare challenger-minus-incumbent gap — which 27g correctly
refused to read as a model comparison — **this contrast is interpretable.** That is what four arms
bought.

**OCEAN-only reproduces 27g** under a better-converged optimiser: ent **4.31** against 27g's 4.16,
**+11.93** against +11.62. The design is doing what it did before; only the land is new.

## 2. WHAT CHANGED MECHANICALLY — the channel was being SUPPRESSED by the land error

| | mode | INCUMBENT | LAND-only | OCEAN-only | **JOINT** |
|---|---|---|---|---|---|
| `ent_seas_amp_SH` | — | 0 | 0 | 4.31 (below band) | **8.11 (in band)** |
| `sst_seas_amp_SH` | 0.360 | 0.371 | **0.176** | 0.754 | **0.656** |
| — as % of observed 1.746 | 20.6 | 21.2 | **10.1** | 43.2 | **37.6** |
| — prior z | −6.32 | −6.20 | **−9.18** | −3.36 | **−3.92** |
| SPO ocean component | — | 0.253 **@ mo 4.13** | 0.120 @ 4.13 | 0.166 @ 4.85 | **0.258 @ mo 9.24** |

**THE OCEAN LIMB ROTATED 4.13 → 9.24 MONTHS, against an observed 8.52 — 0.72 months away.**
⚠ **This was NOT a pre-registered gate in 27j and is not claimed as a pass.** It is the quantity
**27g's P3 scored FAILED** on (3.35 → 3.45, +0.10 months). With the land corrected it moves
**+5.11 months**. Reported as a measured outcome, not a scored one.

**And the LAND-only arm proves the cancellation mechanically.** Cutting land should shrink the
total, so a compensating fit should *raise* the ocean. It does the opposite — `sst_seas_amp_SH`
collapses to **0.176 (z −9.18)** — because the solubility limb at month 4.13 is ANTIPHASE to land
at 10.11 and was **subtracting**. Removing the subtraction is how that arm claws the total back to
0.954. That is the cancellation, caught in the act.

## 3. WHY P4 AND P5 FAILED, AND THEY FAIL FOR ONE REASON

| at SPO | INCUMBENT | **JOINT** | OBSERVED |
|---|---|---|---|
| total | 1.138 @ 8.72 | **1.267 @ 8.68** | 1.168 |
| SH-local land | 1.315 @ 10.09 | **0.906 @ 10.08** | 0.683 |
| SH ocean | 0.253 @ 4.13 | **0.258 @ 9.24** | 0.522 @ 8.52 |
| NH-origin | 0.821 @ 6.47 | 0.816 @ 6.47 | — |
| δ¹³C-per-ppm | 1.940 | **1.390** | 1.000 |

Once the ocean limb rotates to 9.24 it is nearly **in phase** with land at 10.08, so the two now
**ADD** where they used to cancel — which is what nature does (observed land ~9.3, ocean 8.52, and
[[seas_spo_two_wrong_pieces]] says nature ADDS two in-phase parts where the model SUBTRACTED two
antiphase ones). **The model has finally got the right assembly.** But:

1. **SH-local land is still 0.906 = 1.33× the observed 0.683.** The GPP end was not far enough. Two
   in-phase parts, one of them a third too big, overshoot — hence P4 at +8.5 %.
2. **The wrong-phase solubility limb is still being used, at `sst_seas_amp_SH` = 0.656.** It sits
   ~5 months from the entrainment limb and partially cancels it, holding the NET ocean at 0.258
   instead of the observed 0.522 — hence P5 at 0.495×.

**Both residuals are the same residual seen twice: there is still too much land-phase amplitude in
the SH, and the fit is still buying prior credit with a limb it should not need.**

⚠ `seas_T_amp_NH` lands at **31.41, prior z +3.50** in the JOINT arm — the largest positive flag in
the slice, and it moves the same way in every arm (mode 23.46 → 29.9–33.3). It is not caused by
this experiment, but it is not explained by it either, and it should not be quoted as clean.

---

## 4. ⇒ WHAT THIS DOES AND DOES NOT LICENCE

**Established.** The land and ocean corrections interact, strongly and in the predicted direction,
with a parameter-balanced statistic. 27g's entrainment channel is vindicated on the evidence it
could not supply alone: given a corrected land, the fit takes it to **8.11 µmol/kg — inside the
physical band for the first time** — and uses it to **rotate the ocean limb into place** rather
than as a counterweight. The standing partition target moves **1.93 → 1.390**, better than either
single arm (1.834 land, 1.765 ocean) and the best this arc has produced.

**NOT established, and must not be quoted as if it were.**
- **This is not a licence to adopt the GPP end.** `seas_npp_amp_SH` was FIXED, not fitted, and a
  clean interaction shows the two corrections couple — not that 0.352 is the right value. PsnNet
  and GPP disagree by 1.4× and the model uses one end without saying why. **Marcus's call, on the
  measurement's terms.**
- **Not a verdict on `phi_eff`.** `seas_npp_amp_SH` is half of a (shape, size) unit with
  `CCX_SEAS_PHI_EFF['SH'] = −30` and `R/constants.R` says the pair must be re-derived together.
  Everything above is conditional on phi. [[ccx_phi_eff_amplitude]]
- **4b is NOT ruled out** — but it is no longer the indicated next step. P1 passed, so the case
  that a second SH ocean COLUMN is needed has weakened: the existing channel reached its physical
  band and the right phase. What is left is a LAND size error and a solubility limb the fit will
  not put down.

**The two candidates the residual actually points at**, in the order I would take them:

- **(A) RE-DERIVE THE (shape, size) PAIR.** `CCX_SEAS_PHI_EFF['SH']` and `SEAS_NPP_AMP_SH` fitted
  TOGETHER against the observed SH productivity cycle, as `R/constants.R` says they must be. The
  residual is a land SIZE error of ~1.33×, and the size is half of a pair whose shape has never
  been re-fitted for the SH. This is the direct descendant of P4's failure.
- **(B) PIN `sst_seas_amp_SH`, or price it honestly.** It is at 37.6 % of its observed value with
  z −3.92, cancelling the channel that now works. [[orthogonality_bounds_efficiency]] — if the
  conclusion needs the lever pinned, pin it and measure the exchange rate rather than arguing
  about it.
