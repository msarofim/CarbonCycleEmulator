# Handoff — CarbonCycleEmulator, 2026-08-20d: the drivers are now MEASURED, and the NH seasonal "deficit" inverted

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
**Predecessor:** `handoff_2026-08-20c_next_steps.md`. Read this one first; go back to 20c only
for the evidence behind a claim it makes. **§2 of 20c is now superseded by §2 here** — its
measurement stands, its *diagnosis* ("the NH undershoots") does not survive observed drivers.

---

## 0. STATE IN TEN LINES

1. **Four datasets acquired**: CRU absolute climatology + CRUTEM5 gridded mask (land seasonal
   cycle), ERSSTv5 (ocean seasonal cycle + a land-fraction mask), MOD17A3HGF C6.1 (NH/SH NPP).
2. **The seasonal drivers were fitted where they could have been measured.** Land amplitudes
   3–4× too big, ocean amplitudes ~25× too small, against priors that were recollections.
3. **`CCX_SST_SEAS_LAG` 2.50 → 1.32 APPLIED** (both cores). Measured, and worth **+18.7 logL free**.
4. **The four seasonal amplitude priors are RE-ANCHORED on the measurements** (§4). **This
   changes the objective — a refit is owed and the arm files' posterior fields are now stale.**
5. **THE HEADLINE INVERTED.** At observed drivers the NH cycle **overshoots** (8.78 ppm vs an
   observed 6.754), where the mode undershoots by 22 %. §3.
6. **The mechanism is cancellation, not a missing channel**: NEP and respiration are 6.6 months
   antiphase, each ~2× the net, and the fit was using an impossible 48 K to cancel them. §3.
7. **δ¹³C per ppm is the partition diagnostic** and it needs no new data: the cycle is 1.53×
   (MLO) / 2.54× (SPO) too depleted. Observed drivers move it to 0.068 — right way, not closed.
8. **Phase was 44 % of the ocean term's rejection**, not 0 % and not 100 %. §3.
9. **`npp_frac_NH` is the one OPEN DECISION** — the data is in hand, the *form* is not settled. §5.
10. **Still no posterior**, still no refit, `output/mode_fit.rds` still absent. Unchanged.

---

## 1. WHAT WAS ASKED AND WHAT WAS DONE

Marcus, three messages, in order:
1. *"Checking all the input drivers to make sure we are using all available information (e.g.
   land versus ocean in the southern hemisphere) is a first step."*
2. *"Which products are most compatible with the IGCC historical data? … If there are obvious
   winners, go ahead and pull them. I would actually do the ¹³C after the downloads."*
3. *"Use ERSSTv5. … pick the [NPP product] that is well regarded but also easy to download.
   Once that is done, then start the ¹³C channel decomposition."*
4. *"Keep adding in the more physically correct data even if it moves the fit in the slightly
   wrong direction."* ← **standing instruction, acted on in §4**

Five commits: `365804e` (audit), `6b5720b` (climatology), `30e53b0` (NPP), `e1b39e5`
(decomposition), plus §4's. **889 tests passed** through the core edit in `e1b39e5`; after §4's
changes the suite is **918 pass, 1 FAIL** — the failure is real, diagnosed, and left standing
rather than papered over. **See §4d.**

---

## 2. THE AUDIT'S FINDING, which set everything else up

**Every seasonal driver in the model was a free parameter; none was read from data.** The
emission side is exemplary — EDGAR fossil shares, OSCAR time-varying LUC shares, GFED fire
seasonality, all sourced and hemispheric. The seasonal *climate* side was not sourced at all.

**Nothing on disk could check it.** HadSST4 and CRUTEM5 are held as annual **anomaly** series,
and an anomaly has its monthly climatology subtracted — the seasonal cycle is gone by
construction. That is why the four knobs had never been checked, and it is not a small gap:

| parameter | fitted | old prior mid | **observed** | ratio | old prior-z |
|---|---|---|---|---|---|
| `seas_T_amp_NH` | 48.07 | 12.0 | **11.45** (>30N 15.7, >45N 17.9) | 0.2× | +3.83 |
| `seas_T_amp_SH` | 11.18 | 6.0 | **3.59** (>30S 7.1) | 0.3× | +1.25 |
| `sst_seas_amp_NH` | 0.089 | 2.0 | **2.237** | **25.1×** | −6.03 |
| `sst_seas_amp_SH` | 0.064 | 1.2 | **1.746** | **27.4×** | −4.72 |

**The recollections were close to right and the fit rejected them anyway.** That is the thing
to carry forward — this was never a mis-set prior.

Other unsourced hemispheric splits, still open (audit block 10): `enso_share` **hardcoded
50/50** in `ccx_aux()` with no comment while GFED4.1s is already on disk and the flux it drives
is overwhelmingly tropical; `FORC_NUC_NH_SHARE` 0.95 and `FORC_BOMB_NH_SHARE` 0.90 provisional;
`OCEAN_AREA_{NH,SH}` provisional; `sst_{NH,SH}` = 18/16 °C uncited while setting K0/K1/K2 and
Revelle; **`CCX_SEAS_PHI_EFF["NH"] = 75°` an offline-fitted effective knob, `["SH"] = −30°`
asserted.** The last of these is now the prime suspect — §6.

---

## 3. THE LIVE RESULT — the NH deficit inverts, and why

### 3a. The channel budget (`calibration/diag_seas_channel_decomp.R`)

Contributions are **vector** differences of the scored (sin, cos) pair, never scalar amplitudes
— scalar reading is what made the 08-20 test wrong in both directions. **The channels sum to
the all-off case within 0.9 % (MLO) / 0.2 % (SPO)**, so the budget is genuinely additive and
can be reasoned with.

MLO, peak-to-peak contribution and each channel's own δ¹³C-per-ppm signature:

| channel | ΔCO₂ ppm | peak mo | signature |
|---|---|---|---|
| NEP NH | **11.77** | 4.51 | 0.0636 |
| resp NH | **7.71** | **11.09** | 0.0352 |
| air-sea NH | **0.05** | 11.21 | 0.0045 |
| emissions (EDGAR/GFED) | 0.36 | 3.60 | 0.0495 |
| **NET, all six** | **4.96** | 3.47 | **0.0848** |

**The two big land channels are each larger than the total and 6.6 months antiphase. They
cancel.** That is the 08-20b non-monotonicity ("more respiration swing gives LESS MLO
amplitude") with a number on it. And it explains the isotopic excess: cancellation suppresses
net CO₂ amplitude **more** than net δ¹³C, so the model's net signature (0.0848) is **higher
than either channel producing it**. **The excess is cancellation geometry — do not go looking
for one guilty channel.**

The ocean channel, the only isotopically neutral one available (0.0045), contributes **1 %** of
the cycle, and turning it **off improves** the objective (+11.8 NH, +7.2 SH). At its fitted
amplitude it was not merely inert but slightly harmful.

**Emission seasonality is a seasonal channel and was missing from 20c's channel list.** It
contributes 0.36 ppm at MLO and carries fossil carbon at −27.9 ‰, the most isotopically extreme
thing in the model.

### 3b. The 2×3 factorial (`calibration/diag_seas_obs_drivers.R`)

Amplitude and phase varied **separately**, because 20c §2d is right that an amplitude-only test
cannot tell them apart. `CCX_SST_SEAS_LAG` is compile-time, so this patches + rebuilds + runs in
a fresh process in a `tempdir()` copy, gating that the patch took.

| SST lag | amplitudes | seas logL | MLO p2p | sig MLO | sig SPO |
|---|---|---|---|---|---|
| 2.50 shipped | fitted | −576.7 | 5.309 | 0.0825 | 0.0963 |
| 2.50 shipped | ocean=obs | −2039.7 | 4.454 | 0.0973 | 0.0893 |
| 2.50 shipped | ocean+land=obs | −6590.4 | 8.778 | 0.0684 | 0.0815 |
| **1.32 observed** | fitted | **−558.0** | 5.297 | 0.0827 | 0.0977 |
| 1.32 observed | ocean=obs | −1399.2 | 4.114 | 0.1053 | 0.1641 |
| 1.32 observed | ocean+land=obs | −6883.6 | 8.805 | 0.0683 | 0.1037 |

*(observed: MLO 6.754 ppm sig 0.0528; SPO 1.170 ppm sig 0.0288)*

1. **The lag correction is real, free and small: +18.7.** Small precisely because the amplitude
   it phases is ~0.
2. **Phase was 44 % of the ocean term's rejection** (−1463 → −823). 20c §2d was right that the
   amplitude-only test could not separate them — **but 56 % survives.** Phase is not the answer.
3. **THE HEADLINE INVERTS.** At observed land *and* ocean amplitudes the NH cycle **overshoots**:
   **8.78 ppm against an observed 6.754, +30 %**, where the mode undershoots by −22 %.
   **The NH "deficit" is not a deficit of drivers.** It is what two over-large antiphase land
   channels look like after being tuned to cancel, with `seas_T_amp_NH = 48 K` (4.2× observed)
   doing the cancelling. Restore the observed 11.45 K, the cancellation weakens, and the cycle
   blows up. **Anyone who reads 20c §2 and goes hunting for missing NH amplitude will waste the
   session.**
4. **The isotopes move the right way and do not close.** Observed drivers take the MLO signature
   0.0825 → 0.0684 against an observed 0.0528.

**CAVEAT THAT BOUNDS EVERY LOSS ABOVE:** these are profiles at a mode fitted **under the shipped
constants and priors**, so challengers are scored on the incumbent's home ground
(`match_incumbents_optim`). **A loss is weak evidence against; the +18.7 win is strong evidence
for.** After the refit that §4 now requires, these numbers must be recomputed.

---

## 4. WHAT WAS CHANGED, on Marcus' standing instruction

> *"Keep adding in the more physically correct data even if it moves the fit in the slightly
> wrong direction."*

Acted on. Three edits, all recorded in `CHANGELOG.md` and `DATA.md`.

**(a) `CCX_SST_SEAS_LAG` 2.50 → 1.32, both cores.** A measurement replacing a stated belief, in
a constant that was never fitted. Unambiguous, and it *gains* +18.7. **The C++ twin
`SST_SEAS_LAG` in `src/ccx_core.cpp` was changed in lockstep — these two must always move
together.**

**Not changed: `CCX_SEAS_T_LAG` stays at 2.0.** The climatology gives an NH land *air* T lag of
0.04, which looks like a discrepancy and is not: that constant multiplies **soil** respiration,
`R/model.R` says so, and the 18,944-logL profile rejects exactly the air-temperature value.
**Do not "fix" it.**

**(b) The four seasonal amplitude priors re-anchored on the measurements** (`R/calibrate.R`,
with the observations added to `R/constants.R` as data-status constants, the `PUMP_GRAD_OBS`
idiom). The **land widths are derived**, not chosen: the lognormal whose ±1σ spans the measured
area-weighted-to-boreal bracket, so the width *is* the weighting ambiguity. **The ocean width
(0.25 in log space) is a stated judgement** — `SST_SEAS_AMP_LOGSD`, flagged `provisional` —
because no bracket for it exists. Replacing it with a gas-exchange-weighted estimate is a real
improvement someone could make.

**(c) `seas_npp_amp_{NH,SH}` added to both cores** (in `e1b39e5`) — a per-hemisphere multiplier
on the seasonal NEP term, **default 1 = the shipped model bit for bit**, absent-means-1, not in
`CCX_PARAM_TABLE`, never fitted. It exists because the other two channels already had exact
switches and NEP did not (`CCX_SEAS_PHI_EFF` is compile-time). R↔C++ parity re-verified 1.7e-13.

### ⚠ WHAT (a) AND (b) INVALIDATE — read before quoting any stored number

**The objective changed.** `calibration/output/pump_arms/mode_fit_pump{N,D}.rds` were fitted
under the old priors and the old lag:

- **`par_mode` is still a valid parameter vector.** Diagnostics that only run the model at it
  are fine (though they now run it under a different lag constant, so they will not reproduce
  pre-08-20g numbers).
- **`logpost`, `prior_z`, `hessian`, `cov`, `sd_unc`, `eigen`, `logdet_negH` and the Laplace
  evidence now describe a posterior that no longer exists.** Do not quote them.
- **A REFIT IS OWED.** The mode is far outside the new priors — `seas_T_amp_NH` **+5.4 σ**,
  `sst_seas_amp_NH` **−12.9 σ** — and that is the point rather than a problem: the fit had been
  buying its seasonal cycle with values the data exclude.
- The `h_ml` band-provenance rule from 20c §4 still applies to `u_mode` and is unaffected by this.

### 4d. ⚠ ONE TEST IS FAILING, DELIBERATELY LEFT FAILING

`test-fluxes.R:99` — `expect_equal(on$tau_flux, off$tau_flux, tolerance = 1e-3)`, commented
"seas excluded". **It passed at lag 2.5 and fails at 1.32: 4.684 vs 4.692, relative 1.72e-3.**

**Not modified, per the standing rule that a newly failing test is reported rather than made to
pass.** It is reported here instead, diagnosed:

- **The test's claim is only approximately true.** `tau_turn` is not perfectly seasonality-free.
  Measured (`/tmp/tauprobe.R` pattern, replicating the test's own `mk()`): the discrepancy is
  **exactly 0** at `sst_seas_amp = 0` and grows monotonically with it — 5.4e-5 at 0.089, 7.2e-4
  at 1.0, **1.72e-3 at the default 2.0**. So the leak is the **seasonal SST term**, and the
  1e-3 tolerance was accommodating it.
- **Why the lag tipped it.** `tau_turn[1]` samples the **first month**, so it inherits whatever
  the seasonal SST happens to be at that instant. At lag 2.5 the month-1 factor is −0.2588
  (−0.518 K at amplitude 2.0); at lag 1.32 it is **−0.7705 (−1.541 K)** — **2.98× larger**,
  which is the whole of the 0.6e-3 → 1.7e-3 move.
- **So the tolerance was silently encoding `CCX_SST_SEAS_LAG = 2.5`**, and nothing said so.

**The options, for Marcus, not resolved here:** (i) accept and widen the tolerance to ~3e-3 with
a comment naming the leak and its amplitude-scaling — honest but weakens the assertion;
(ii) make the assertion phase-independent by evaluating `tau_turn` on an **annual mean** rather
than month 1, which is what "seasonality excluded" actually means and would make the test
stronger than it is now; (iii) run the case at `sst_seas_amp = 0`, which makes the claim exactly
true but stops testing the thing it was written to test. **(ii) looks right** — the test's intent
is a turnover time, and a turnover time sampled in one month is not one.

---

## 5. THE ONE OPEN DECISION — `npp_frac_NH`

The data is in hand; the **form** is not settled, and it is a real fork rather than a detail.

MOD17A3HGF C6.1, 0.5° netCDF regrid, no registration: **global 52.75 PgC/yr, NH share 0.5942**
(sd 0.0135 across 2001–2023). Compared **at the model's modern state, never at the parameter** —
`npp_frac_NH` is a 1750 split, MOD17 is 2001–2023, and NH-heavy clearing walks the realised
share down in between, so comparing the raw parameter would *understate* the gap:

| | |
|---|---|
| `npp_frac_NH` fitted (1750) | 0.4662 |
| → model's realised modern share | 0.4461 |
| MOD17 observed | **0.5942** |
| ⇒ 1750 anchor implied by MOD17 | **0.6136** |

It is a **single scalar applied at 1750**, not a time series; the realised share moves only
through clearing (0.4662 → 0.4466 over 1750–2024), and fertilisation cancels out of the share.
The implied anchor sits comfortably inside the old UNIFORM[0.4, 0.8], so nothing was bounding
the parameter away from it.

**The fork.** A prior on the 1750 *parameter* centred at 0.6136 bakes in the model's own
clearing at the current `luc_scale` — mildly circular. The alternative is a **likelihood term on
the modern realised NH NPP share**, which scores the observable instead
(`ccx_bound_observable`). **Not resolved, and deliberately not resolved silently** — unlike the
seasonal amplitudes, where the parameter *is* the observable and no such choice arises.

**And it will not be free either way.** Audit block 8 priced the move: at 0.60 the objective
loses **794** log-units, and the veto is **`d13c_seasonal_MLO` (−835)**, not the CO₂ rows —
raising NH NPP *helps* `co2_seasonal_MLO` (+216). **MOD17 does not settle `npp_frac_NH`; it
converts an unconstrained fit into a conflict with a scored stream**, which is far more useful.
Note the direction: MOD17's higher NH share makes §3's overshoot **worse**.

---

## 6. WHERE TO GO NEXT — the prime suspect, stated as a hypothesis

**`CCX_SEAS_PHI_EFF["NH"] = 75°`.** It gives the NEP shape a unit-mean peak-to-peak of **2.80**,
which on 28 GtC/yr of NH NPP is a **78 GtC/yr** seasonal swing. It was fitted offline against
MLO **under the pre-08-18 sine respiration**, i.e. against a model that no longer exists, and
audit block 10 already flagged it as an *effective knob* rather than a measured NPP centroid —
75°N is far poleward of any plausible NPP-weighted latitude.

If the NEP channel is over-driven, that is where it comes from, and it would explain §3 in one
move: an over-large NEP channel needs an over-large respiration channel to cancel it, which is
exactly the pair we found. **MOD17's higher NH NPP share sharpens rather than relieves this.**

**Suggested order.**
1. **Measure the NPP-weighted effective latitude from MOD17** — it is already on disk at 0.5°,
   and it is a weighted mean over the field the model claims to represent. Cheap, and it turns
   the suspect into a number.
2. **Profile `CCX_SEAS_PHI_EFF["NH"]`** with the patch-and-rebuild idiom (it is a compile-time
   constant with a C++ twin `SEAS_PHI_EFF`, same as the lags). Watch **both** the amplitude and
   the δ¹³C-per-ppm signature — the whole lesson of this arc is that amplitude alone misleads.
3. **Then the refit §4 owes**, under the new priors, and only then recompute §3b's table. Do
   not refit before the structural question is settled — `ccx_path_relocates`.
4. `enso_share` 50/50 is the cheapest remaining unsourced split and GFED is already on disk.

---

## 7. FILES

**New:**
- `calibration/diag_driver_audit.R` — 12 blocks, the whole audit. Blocks 11–12 are the
  fitted-vs-observed comparisons and are the payoff.
- `calibration/diag_seas_channel_decomp.R` — the vector channel budget.
- `calibration/diag_seas_obs_drivers.R` — the 2×3 factorial, with the rebuild harness.
- `data-raw/build_seasonal_climatology.R` → `data/obs_seasonal_clim.rds`
- `data-raw/build_npp_hemispheric.R` → `data/obs_npp_hemispheric.rds`

**Edited:** `R/model.R`, `src/ccx_core.cpp` (lag + the NEP switch), `R/calibrate.R` (priors),
`R/constants.R` (the observations), `R/cpp.R`, `DATA.md` §3b/§3c, `CHANGELOG.md`,
`data-raw/downloads/MANIFEST.csv` (4 new entries with SHA-256).

---

## 8. NON-OBVIOUS STATE AND TRAPS FOUND

Everything in 20c §8 still applies — especially **`data-raw/downloads/nuclear14c/` is a live,
gitignored runtime input** and **never edit a script a long job is executing**. New this session:

- **Downloads are gitignored** (`data-raw/downloads/*`), MANIFEST is the tracked provenance
  record. The four new files (63 KB + 13 MB + 150 MB + 46 MB) are **local only** — a fresh clone
  must re-download before either build script will run.
- **Four traps, each of which produced a plausible wrong answer first.** They are all the same
  shape — *a container is not the thing inside it* — and all are now gated:
  1. **CRU `absolute.nc` is spatially complete and has no `missing_value`** — interpolated over
     ocean too. Unmasked it gave an "NH land" 14.59 °C / 6.68 K. **The tell was NH and SH each
     returning exactly 1296 of 2592 cells.**
  2. **The two 5° grids run latitude in OPPOSITE order** (`absolute.nc` N→S, CRUTEM5 S→N) with
     matching dimensions — an order assumption masks Antarctica with the Arctic's coverage
     (`nameless_matrix_order`). Align by `match()` on values.
  3. **Cell area ≠ land area**: at 5° a cell with one coastal station counts as wholly land ⇒
     "land" = 41.9 % of the globe. Now weighted by an ERSST-derived land fraction (26.8 % vs a
     true ~29 %), which biases the land amplitude **low** — the conservative direction.
  4. **MOD17's `npp` is the mean over VALID pixels, not the cell mean.** Full-cell weighting
     gives 65.1 PgC/yr. `numberofvalidvalues` is proportional to valid area because MOD17 pixels
     are equal-area (14400 equator, 7258 at 60°N vs cos 60° = 0.500) ⇒ 52.75.
- **Never borrow `intersect(names(p), names(par_mode))` from `diag_seas_lag_profile.R`** into a
  script that reads error parameters. It **silently drops `bomb_total`, `rep_dC`, `sigma_d14c`
  and `grad_off_*`**, because `ccx_default_params()` has no fields for them and that script never
  reads them. Every case in the factorial died on `F$c14_bomb * NULL` = `numeric(0)`.
- **`system2(stderr = FALSE)` swallows worker errors into a row of NAs.** Capture it.
- **HadSST4 publishes no absolute form** — that is why the ocean climatology is ERSSTv5 and not
  the product the anomaly comes from. It is the ocean component of 2 of IGCC's 4 GMST datasets
  (NOAAGlobalTemp, GISTEMP); HadCRUT5's is HadSST4. No absolute product is common to all four.

---

## 9. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-20d_drivers_and_channels.md`. **§3 is the live result and it
> inverts 20c §2** — at observed drivers the NH seasonal cycle OVERSHOOTS, so do not go hunting
> for missing NH amplitude. The prime suspect is **§6, `CCX_SEAS_PHI_EFF["NH"] = 75°`**; start by
> measuring the NPP-weighted effective latitude from the MOD17 field already on disk. Read **§4's
> invalidation box before quoting anything out of the arm rds files** — the priors changed and a
> refit is owed. **§5 is the one decision waiting on Marcus.**
