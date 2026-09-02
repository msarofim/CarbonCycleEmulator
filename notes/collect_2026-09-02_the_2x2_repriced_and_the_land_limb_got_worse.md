# Collect — 2026-09-02: the 08-27q 2×2 re-priced at the 25-parameter mode
# **THE VERDICT IS NOT REHABILITATED. IT IS STRENGTHENED.**
# **The overshoot grew +42.4 % → +62.1 %, and the SH LAND LIMB got 33 % WORSE
# while its PARAMETER moved inside its bracket.**
# **The cause is `npp_frac_NH`, a JUDGEMENT-width prior, not `seas_T_amp_SH`.**

> **CORRECTION 2026-09-02 (second session).** The title line above read
> **+18.7 % → +62.1 %** while the body (§ the 2×2 table, below) reads
> **+42.4 % → +62.1 %** off the same "put ocean AT obs" column, 1.424 → 1.621.
> The body is right. The stray 1.187 behind "+18.7 %" is JOINT_hi's *SPO
> total/obs* — a different row of a different table. The memory
> `ccx_land_limb_worse_at_enso25` had inherited the same wrong number in its
> frontmatter and was corrected at the same time; the handoff and the CHANGELOG
> always said +42.4 %. Nothing downstream of this note used the wrong figure.

**What ran:** `calibration/diag_2x2_repriced_at_enso25.R` (~70 s), on
`calibration/lib_seas_limbs.R` (new). Log and rds under `outputs/diagnostics/`.
**Adopts nothing.** ⚠ **MEASURED BEFORE the 09-02 alpha change** — see §9. `CCX_MODE_CANONICAL` and `R/constants.R` untouched; every mode read BY PATH.
**Refits nothing** — 27q's headline statistic is an INTERACTION between six refitted arms and no
gate here is 27q's P1. What is re-priced is the ARITHMETIC verdict, which is what
`handoff_2026-09-01f` §4 says went out of date.

---

## 1. The question §4 asked

08-27q concluded that rotating the SH ocean limb into phase **removes the SH cancellation and
overshoots the SPO total by 18 %** ([[ccx_seas_2x2_admissible]]). That is arithmetic about two
limbs ADDING — and §2 of the prior screen found `seas_T_amp_SH` had moved from 29 % of its bracket
LOW end to **INSIDE** the bracket, i.e. one addend changed. An arithmetic verdict whose addend moved
is an old measurement, not a verdict.

## 2. GATE R — the old column IS reproducible, once ONE named change is switched off

Re-scoring 27q's three stored arms through today's harness misses their stored amplitudes by
**1.8e-3 to 5.0e-3 relative** — all the same sign, all amplitude, phases exact to 1e-4 months.
⚠ The bound was **1e-8, an identity bound**, and it fired. It was **not widened**. It was
**ATTRIBUTED**: with `gamma_diff` returned to its pre-adoption **0**, every one of the twelve limbs
reproduces to **≤7e-14**.

⇒ The whole gap is **volcanic diffuse-light fertilisation** — implemented `328cdb8`, coefficient
adopted at 0.25 in `a2298dc`, both 2026-08-29; **27q ran 2026-08-28 and therefore ran at 0**. Nothing
else moved. That control is in the script, so a SECOND change later would fail it rather than hide
inside a loosened tolerance. [[gate_bound_matches_its_claim]]

⇒ Consequence for reading the tables: **sec.2–6 re-score EVERY vector, old arms included, through
today's model**, so the columns are like-for-like with each other. The stored 27q numbers are the
historical record and differ from their re-scored selves by the amounts above.

## 3. Where the limbs actually are

| vector | total | mo | SH-land | mo | SH-ocn | mo | NH-orig | SPO r |
|---|---|---|---|---|---|---|---|---|
| 27q INCUMBENT | 1.146 | 8.71 | 1.312 | 10.09 | 0.248 | 4.17 | 0.824 | 1.933 |
| 27q LAND_hi | 1.094 | 8.08 | 0.862 | 9.59 | 0.105 | 4.17 | 0.795 | 1.790 |
| 27q JOINT_hi | 1.386 | 8.48 | 0.861 | 9.59 | 0.287 | 9.47 | 0.796 | 1.432 |
| **enso25 A** | **1.083** | 9.00 | **1.743** | 10.62 | **0.370** | 4.17 | **1.133** | **2.063** |
| **enso25 B** | 1.083 | 9.00 | 1.743 | 10.62 | 0.370 | 4.18 | 1.133 | 2.062 |
| OBSERVED | 1.170 | 9.01 | 0.679 | 9.39 | 0.522 | 8.52 | | 1.000 |

⭐ **THE TWO CLUSTER REPRESENTATIVES AGREE TO THREE DECIMALS ON EVERY LIMB.** The `h_ml`
micro-split costs nothing here either — the same answer the prior screen got on the priors.

⛔ **The SH land limb went 1.312 → 1.743, i.e. 1.92× observed → 2.55×.** The land half of the
seasonal problem has **NOT** closed in the OBSERVABLE. What closed in §2 was the PARAMETER.
⛔ The SPO total went 0.981× obs → **0.927×**, so 27q's P4 window [1.114, 1.222] now FAILS from
BELOW, and the d13C-per-ppm ratio **worsened 1.933 → 2.063**.
⚠ The two SH limbs are still **5.55 months apart and subtracting** — the cancellation is intact and
now OVER-cancels.

## 4. The re-priced arithmetic

Holding NH-origin, SH-land and the (printed) three-limb remainder, and asking what the SH ocean
limb would have to BE for the SPO total to be right:

| vector | required ocean | @ mo | / obs | put the ocean AT obs ⇒ total / obs |
|---|---|---|---|---|
| 27q INCUMBENT | 0.170 | 2.58 | 0.326 | 1.582 |
| 27q LAND_hi | 0.466 | 11.53 | 0.893 | 1.425 |
| **27q JOINT_hi** | 0.467 | 11.53 | **0.894** | **1.424** |
| **enso25 A/B** | 0.296 | 4.44 | **0.567** | **1.621** |

⇒ **THE OVERSHOOT GOT BIGGER, NOT SMALLER: +42.4 % → +62.1 %.** And the required ocean limb moved
**away** from the observed one on both axes — 0.89× → 0.57× in size, and from 3.0 months off the
observed phase to **4.1 months** off.
✅ Arithmetic self-check: 27q's JOINT_hi, whose ocean was already rotated by its refit, gives
measured 1.386 vs arithmetic 1.376 (−0.010) — so the device reproduces what the refit did to within
1 %, and the new rows inherit that precision, not more.

## 5. ⭐ WHICH MOVE DID IT — and it is not the one §2 was about

One parameter group at a time, 27q INCUMBENT → enso25 A, on the SH-land limb:

| parameter | from | to | d SH-land | d total |
|---|---|---|---|---|
| **`npp_frac_NH`** | 0.6485 | 0.5076 | **+0.600** | +0.478 |
| `seas_T_amp_SH` | 1.039 | 4.054 | −0.228 | −0.062 |
| `fert_k` | 154.8 | 309 | −0.114 | −0.130 |
| `beta_max` | 0.511 | 0.663 | +0.076 | +0.086 |
| `q10` | 1.136 | 1.033 | +0.060 | +0.368 |
| `seas_lag_p` | 1.768 | 1.457 | −0.027 | **−0.520** |

Sum of all 21 singles +0.340 vs the actual move +0.431 ⇒ interaction +0.091. ⚠ One-at-a-time across
two basins is not a decomposition; the ORDERING is what is read.

⭐ **`seas_T_amp_SH` did exactly what 27q said it does — it pulls the limb DOWN, −0.228 — and it is
outvoted 2.6 : 1 by `npp_frac_NH` moving the other way.**

**Quantitative pre-check, run before believing it.** `npp_frac_NH` is the NH share of global NPP, so
the SH land limb should scale with the SH share to first order: 0.3515 → 0.4924 is ×1.4008, which
predicts 1.838 against a measured 1.912 — **+4.0 %**. The step IS a productivity shift across the
equator and nothing else.

⇒ **THE FIT TRADED A MEASURED-BRACKET FLAG FOR A JUDGEMENT-WIDTH ONE AND THE OBSERVABLE GOT WORSE.**
`npp_frac_NH`'s width is `NPP_FRAC_NH_SD` = 0.04, one of the two the prior screen labels JUDGEMENT;
the move is **−0.141, i.e. 3.5 prior-sd**, and it is the same parameter §2 recorded as having
"crossed zero AGAIN" (+1.25 at from90 → −2.28 now).

## 6. What this does and does not settle

* ✅ **§4's premise is answered and it goes the other way.** The 18 % overshoot was not an artefact
  of an SH land limb that has since moved; the limb moved and the overshoot grew.
* ⛔ **It does not re-run 27q's P1.** The interaction needs six refitted arms at 25 parameters —
  ~15 min locally, no Torch. Whether that is worth running is now a DIFFERENT question: the arm
  that made the land limb small (LAND_hi) is further from the current mode than it was.
* ⇒ **The open lever is `npp_frac_NH`, not `seas_T_amp_SH`.** Its width is invented, its move is
  3.5 of those invented sd, and it alone accounts for the SH land limb's excess. Measuring that
  width is the same job §3 of 09-01f did for `sst_seas_amp_*` — ⚠ and there the measured width made
  the flag BIGGER, so the outcome is not assumable in either direction.
* ⚠ **The four observed constants (SPO total 1.168 / land 0.683 / ocean 0.522 / ocean phase 8.52)
  are NOT in `R/constants.R`** — they are replicated file-locally across ~10 diagnostics. Gate O
  here checks them against the obs actually loaded (total 1.170, implied land 0.679, both within
  0.02) and they are mutually consistent as VECTORS, but a registry entry is owed.

## 7. What landed

* `calibration/lib_seas_limbs.R` — the SPO limb estimator, extracted. ⛔ `diag_admissible_2x2_land_ocean.R`
  is **NOT** edited to use it: that file is a pre-registered artefact whose gates may not move under a
  refactor. What binds them is GATE R, which re-scores its stored arms through the library.
  ⚠ The library's `sl_overlay()` refuses the `intersect(names(p), CCX_PARAM_NAMES)` idiom every
  pre-split diagnostic uses — on a 21-parameter ancestor that assigns NULL to `seas_lag_p_NH/_SH`,
  DELETING them, and the model then runs the ancestor at `CCX_SEAS_LAG_P_DEFAULT`. Absence goes
  through `ccx_migrate_par_set()` or errors.
* `calibration/diag_2x2_repriced_at_enso25.R` + its log and rds.

**One error of mine, caught by output contradicting a comment I wrote.** I documented the 21-parameter
ancestors as having run with the ENSO response OFF, on the pre-split default of 0. The new ENSO limb
came back at 0.0055 ppm on those arms instead of the identical zero I had predicted: **`gamma_enso`
was one of their 21 CALIBRATED names, fitted at 0.8512** and split 0.5/0.5 onto the land pair by the
migration contract. The machinery was right; the comment was wrong, and is corrected in place.

## 8. ⚠ THE SUITE WAS AT SEVEN, NOT SIX

`handoff_2026-09-01f` opens with "Suite 1365 / 6 FAIL / 2 skip, the same six, unchanged by
everything here." Measured today it was **1364 / 7 FAIL / 2 skip**. The seventh is
`test-mode-file.R:71`, the hardcoded-mode-path lint, and its single offender was
**`diag_prior_screen_enso25.R:72`** — `900f90b`, from that same session: the `from90` ancestor was
written as a path literal instead of `ccx_mode_file("from90")`.

⇒ Fixed here (the call resolves to the identical file), and the suite is back to **6 / 2**. My own
two files pass the lint. ⚠ The lesson is not the literal, which the registry exists to prevent and
the lint caught on the day. It is that the count was **quoted rather than read** — the same class as
the attribution header in §2 of that handoff that "was typed, then went stale within the hour".

## 9. ⚠ PROVENANCE: these are PRE-09-02 numbers

Later the same day the air-sea ¹³C alphas became temperature-dependent, which **changed the
objective**. Re-running this file reproduces **every CO₂ number exactly** — a ¹³C change cannot touch
total carbon, and that identity is itself worth having — but it moves the d¹³C-per-ppm ratios:
enso25 A `r_SPO` **2.063 → 2.172**, the 27q INCUMBENT **1.933 → 1.998**.

⇒ **The §3–§6 verdicts are CO₂ arithmetic and are unaffected**; only the two `SPO r` / `MLO r`
columns move. The committed `.rds` and `.log` are the pre-change run and are kept consistent with
each other; `alpha_as_tdep` is now recorded in the output so a stored run says which model made it.
