# Handoff — CarbonCycleEmulator, 2026-08-28b: **σ-INFLATION IS MEASURED TO ERASE THE FREE LUNCH**
# The pull is **0.033**, not the ~1.6 the previous handoff inferred. Option 5 is priced, NOT adopted.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean.
**Nothing is running.** Opens from `c76465c` (the 08-28 handoff).

⚠ **THE SESSION CWD WAS `FaIRtoFrEDI/`, BUT ALL OF THIS WORK IS IN `CarbonCycleEmulator/`.**
⚠ **A Julia SLR job (`postprocess_mcmc_ext.jl --tag=L21`, `SLR-RFF-BRICK`) was running on this Mac
throughout — not mine, not touched.** Stage B was run single-threaded from a frozen copy.

---

## 0. STATE IN SEVEN LINES

1. **This continues the previous handoff's own §6**, the one it left as "Marcus's call": price
   σ-inflation by MEASUREMENT rather than by scaling 16g's number. §1
2. ⚠ **§6's "~1.6 residual, 80 % reduction NOT elimination" IS REFUTED. Measured: +0.033, a
   99.55 % reduction.** Its arithmetic was `ratio_needs_its_base` from inside the project. §2
3. **Both cliffs are GONE** — 85 m **+7.3005 → −0.0064**, 120 m **+8.4257 → −0.0047** — and
   leaving the band is now slightly DOWNHILL at both edges. §3
4. **`h_ml` gains an INTERIOR MAXIMUM over the whole [30, 200] support.** That, not the argmax's
   exact location, is the substantive case for option 5. §3
5. **B1 ✗ as I pre-registered I expected**: the argmax IS 3 m outside the lower edge — **by 0.033,
   21× below the refit's own noise floor.** Not a preference the fit can act on. §2
6. ⚠ **NOT ADOPTED. `R/` and `src/` are untouched, the band and skip ship exactly as before, and
   the TARGET-correction variant is NOT priced.** Still Marcus's call. §6
7. **`kz` still rails, unchanged. `pump_grad` narrows 226–446 → 253–302.** §5

**Commits:** `15d1906` prereg → `1ea4922` Stage A → `672dd8b` amendment → `ec1a58e` Stage B,
plus CHANGELOG. Prereg and amendment each committed BEFORE the driver they govern.

## 1. WHAT WAS ASKED, AND WHAT WAS ACTUALLY RUN

08-28 §6 proposed re-running §5's out-of-band points with inflation ON. **Both sides turned out to
be boundable exactly from artifacts already on disk**, so this ran in two stages:

- **Stage A** (`diag_sigma_inflation_pricing.R`, seconds): bracket every point.
- **Stage B** (`diag_sigma_inflation_profile.R`, ~55 min): refit all 26 with the rows ON.

`σ_eff(h)² = σ_obs² + σ_rep(h)²`, normalisation retained, **σ_rep PCHIP through the MEASURED
points** — `hml_band_discontinuity.rds` (DIC, δ¹³C) and `alk_sigma_rep.rds` (ALK). Never fitted.

## 2. THE HEADLINE, AND THE RETRACTION

    best in-band  -1544.357 at 85.01 m
    best out      -1544.324 at 82.00 m
    residual pull       +0.0334        vs the shipped skip's +7.39   (99.55 % reduction)

⚠ **08-28 §6 said inflation would leave ≈1.53.** 16g measured **2.14 of 10.01** — a **DIFFERENCE**
(in-band row cost − out-of-band inflated cost) over **ITS OWN** base. §6 multiplied that 21 % by
§5's base of **7.30**. **The subtrahend is set by the σ's, not by the base**, so the ratio never
transferred. **16g's 21 % is not wrong** — it correctly describes 16g's frozen-19 configuration,
DIC + δ¹³C only (ALK's σ_rep did not exist until 08-18).

**B1 ✗ and I pre-registered that I expected it to fail.** The argmax is at 82 m. **B2 is what
decides**: 0.033 is 21× below the 0.70 restart noise floor and below the optimiser's own restart
tolerance. **An argmax 3 m outside a band by less than the fit's own noise is not actionable.**

## 3. BOTH CLIFFS GONE, AND THE PROFILE IS NOW WELL-POSED

    straddle 85 m   +7.3005 -> -0.0064          straddle 120 m   +8.4257 -> -0.0047
    32 m  -5.56  |  65-120 m: a 1.64-log-unit PLATEAU over 55 m  |  198 m  -13.03

**The inflated objective has an INTERIOR maximum and falls away on BOTH sides.** With the rows
scored everywhere, `h_ml` no longer needs a hard bound to stay put — the data holds it. Under the
shipped skip the same profile ran to the edge of the support and had to be stopped by a wall.
**That is the substantive argument for option 5, and it does not depend on the 82-vs-96 argmax.**

## 4. THE METHOD, WHICH IS THE REUSABLE PART

    LOWER(h) = lp_shipped - rows_shipped + rows_inflated_AT_THE_STORED_VECTOR
    UPPER(h) = lp_shipped - rows_shipped + SUM -log(sqrt(2pi) sigma_eff)      [the density PEAK]

Rigorous in opposite directions: re-optimising with a term switched ON can only RAISE the objective
above its value at the stored vector, and no term can beat its own density peak. **B3 ✓ 26/26 —
every refit landed inside.** Stage A cost seconds and correctly localised the undecided region to
the shallow side alone. ⇒ **Score a candidate objective change at the incumbent's OWN stored
vectors before refitting it.**

**And the identity that avoided duplicating `ccx_make_logpost()`** (the project has paid 309 logL
for a challenger that did not match its incumbent's path):

    dnorm(t, v, s_eff, log) = dnorm(t, v', s_obs, log) - log(s_eff/s_obs),  v' = t - (t-v)*s_obs/s_eff

so the **shipped** `ccx_loglik` does the scoring; `ccx_ocean_grad_scored()` is overridden **in the
driver's process only** (captured and restored `on.exit`), and the normalisation rides as a
per-point constant — `h_ml` is FIXED at each point, so it cannot influence the optimisation.
**The guard, that the override reproduce Stage A's LOWER at the mode by a completely different
route, agreed at 0.000e+00.**

## 5. TWO SIDE-FINDINGS

- ⚠ **`kz` STILL RAILS AND STILL INVERTS** — 97.9 % of bracket at 32 m → 92.4 % at 96.47 → 66.1 %
  at 198 — **unchanged by inflation. This arc has now TWICE failed to be the `kz` rail's cause.**
  It is an independent open item and should stop being attached to `h_ml` work.
- **`pump_grad` NARROWS 226–446 → 253–302.** §5's **H4 ✗** could only say the rows-off effect needs
  more freedom than the uptake set. **This is its positive half**: with the rows on at every
  `h_ml`, the quantity they exist to constrain stops wandering. First direct evidence those three
  rows do the identifying.

## 6. ⇒ WHAT IS OWED IF MARCUS ADOPTS OPTION 5 — NOT RUN, NOT PRE-REGISTERED

- **A full 21-parameter refit.** The conditional argmax moves **96.47 → 82 m**. Inside the noise,
  but the objective changes and every fitted vector would be non-comparable, exactly as on
  2026-08-22 and 2026-08-25f. **Nothing fitted before an adoption would be comparable after it.**
- **A σ_rep interpolation that ships.** Stage A/B PCHIP two rds files in the driver. An adopted
  option 5 needs σ_rep(h) inside `R/`, with its own test, or it is a hidden dependency on two
  diagnostic outputs.
- **The `LIK_OCEAN_GRAD_HML_OK` band would be deleted, not widened** — that is the point.
- ⚠ **THE ALTERNATIVE IS STILL UNPRICED.** Correcting the **target** to its like-for-like value at
  `h_ml` is a different and strictly more aggressive remedy, measurable from the same stored
  `like_for_like` columns. **Deliberately not run.** Marcus's call which — if either.
- ⚠ **NONE OF THIS SPEAKS TO THE BELIEF QUESTION.** As the 08-28 prereg said: an argmax that stays
  put says the bound is *harmless*, not that truncating the posterior's softest direction is
  *right*.

## 7. NON-OBVIOUS STATE — READ BEFORE TOUCHING ANYTHING

- **Everything in §7 of the 08-28 handoff still stands** — `ccx_mode_params()` never
  `ccx_unc_to_par(md$u_mode)`; the harness offset is **−1.5805**; `ccx_loglik(by_stream=TRUE)`
  returns a named VECTOR so test membership not nullity; write the artifact BEFORE the
  pretty-printing; spell out `md$u_mode`; seven of the 21 names are likelihood-side.
- **Stage B writes its rds EVERY ROW**, not at the end. A reap costs one point, not the run.
- ⚠ **`MEMORY.md` root is 17.7 KB against a 12 KB soft target and `INDEX_ccx.md` is now 15.0 KB
  against 14 KB.** Both over soft, both under the 18 KB hard ceiling. **Flagged, not restructured**
  — this session added one sub-index bullet and put the finding in its own file, per the tiering
  rules, rather than growing the root.
- **Suite not re-run this session** — no `R/`, `src/` or `tests/` file was touched. Last known
  1164 / 0 at `54fe499`.

## 8. STILL OPEN BEHIND THIS (unchanged from 08-28 §8, minus the one this closed)

- **The controlled lever contrast** (27q §4): 27j's `seas_npp_amp_SH` on the PINNED slice.
- **4b — the SH ocean AMPLITUDE**, which P5 has failed three times for the same reason.
- **`kz` RAILING** — see §5; now twice shown NOT to be an `h_ml` problem.
- **THERE IS STILL NO POSTERIOR** — the project's oldest open item.
- Gate 8's Suess overshoot; gate 10's crossed target; the δ¹³C `alpha_as_*` provisional constants;
  `co2_NH`'s missing seasonal representation term. All objective changes.
- **The basis decision (27o §8) is STILL OPEN.**

## 9. HOW TO RUN WHAT THIS SESSION ADDED

    Rscript calibration/diag_sigma_inflation_pricing.R   # ~1 min, the bracket (Stage A)
    Rscript calibration/diag_sigma_inflation_profile.R   # ~55 min, 26 points -- HOLD THE PROCESS

Outputs `outputs/diagnostics/sigma_inflation_pricing.rds` and `sigma_inflation_profile.rds`.
**Nothing was quarantined** — no shipped output changed, because no objective changed.
