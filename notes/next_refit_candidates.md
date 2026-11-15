# Candidates for the next refit

Started 2026-11-15 (Marcus: "Add a wider prior to the list for a future refit"). Until now the items owed to "the
next refit" lived in separate handoffs. Two of them have since landed and are not repeated here: `aod_mode = anomaly`
is in the canonical (`hilda31fl`, `aod_mode = 1`), and the emissions-interpolation flip (`35f38dc`) was superseded by
10-01 (k) and its branch deleted (CHANGELOG 10-01 n). Add an item with its date, who asked, and where it is priced.

## 1. A wider prior on `hs_asx_frac` (Marcus 2026-11-15)

**What it is.** `hs_asx_frac` is the cold high-latitude box's air–sea gas exchange per unit area, relative to the
warm surface's. Its prior (`R/calibrate.R`, `CCX_PARAM_TABLE$hs_asx_frac`, via `ccx_hs_asx_prior()`) is lognormal on
0.653, the value measured from ice cover × wind × Schmidt number (`data/obs_hs_exchange_factor.rds`, 09-06d), with
log-sd 0.15. The centre is an observation; the width is a judgement (about 2.5× the measured component spread).

**Why it is on the list.** It is the prior that holds the gas transfer speed `k_w` near 1,840 m/yr against the
literature's 1,446 (Naegler 2009). Profiled at `hilda31fl` (`outputs/diagnostics/price_profile_20261111_hilda31fl/`):
at `k_w` = 1,446 the likelihood is +6.28 better, `hs_asx_frac` moves 0.73 → 1.67 (prior z 0.75 → 6.26), and that
prior is 89 % of the posterior price (−15.34). App card 7 states this (group B item B20).

**What a wider width would do, and what it reopens.**
- At log-sd 0.44 (the north–south spread of the measured factor, NH 0.32 / SH 0.78) the 1,446 point sits at z 2.1.
- ⚠ 09-08e deliberately did NOT carry that spread: the code comment calls the hemispheric split "a representation
  error, not carried", because the model pools both hemispheres into one cold box. Widening reopens that ruling.
- ⚠ The same 09-08e comment records why the prior exists: with no prior, round 4 used `hs_asx_frac` as the free
  compensator (0.82 → 1.83, 2.8× the measured value). A wide prior can let it take that role again.
- At 1,446 the re-fit also moves `h_hs` to 470.6 m against its 500 m upper bound (10-05: 472.6, step-unstable there).

**Before a refit:** price it as a profile (the `run_price_profile.R` recipe) at one or two widths, and read whether
`h_hs` or another name then sits on a bound. A cheaper first step is a single re-fit at log-sd 0.30.

## 2. Refresh the pins (from the `hilda31fl` adoption, 2026-10-23)

The adoption ruled "Pins' file, no 2nd pass": `w_enso_l2` sits at −0.156 σ against the pins (a second pass would gain
+0.017 module log-likelihood). `notes/handoff_2026-10-23_hilda31fl_adopted.md`: "Refresh the pins at the next refit
run for its own reasons."

## 3. A better fit to ENSO's timing (Marcus 2026-11-15)

**What it is.** The model's CO₂ growth follows El Niño at the right lag but not in the months before it peaks. On the
interannual module's estimator (centred 12-month growth, monthly, 1980–2024) both series' r with Niño 3.4 peak at the
same lag (model 6 months, record 5; difference +1, 90 % −1 to +2) and the miss is uncorrelated there (r −0.05). With
the index six months after the growth, the record's r is −0.20 and the model's +0.12, and the miss correlates with the
index at +0.38 (model minus record r +0.32, 90 % +0.21 to +0.46). Card 4a's calendar-year index sits at that point,
which is why card 4's misses follow the same calendar year's index (r +0.48). Record: T1 and T2,
`calibration/diag_card4_enso_knockouts.R`, `outputs/diagnostics/card4_enso_knockouts_20261115_hilda31fl.log`,
`notes/drafts_2026-11-15_group_b.md` §1c, CHANGELOG 2026-11-15 (f).

**Why a re-run is not enough.** The four ENSO settings (`CCX_IAV_MODULE_NAMES`: `lag_enso_land`, the two land
amplitudes scaled together, `w_enso_l2`) are fitted in the module (`ccx_iav_module_loglik()`, `R/likelihood.R`: the
SSR of the detrended monthly growth plus the `gcb_ocean_enso_slope` row) and already sit near its optimum: a second
pass gains +0.017 (item 2). A better fit needs a new degree of freedom or a changed objective.

**What the knockouts say about where one could come from** (each a run of the canonical with one pathway off):
- The land term carries the model's early-side r (its contribution +0.10 at −6, +0.91 at its 6-month peak).
- The ocean limb is the one pathway pulling the other way (its contribution −0.26 at −6), at about a third of the land
  term's size (sd 0.12 against 0.38 ppm/yr). Its size is held by the GCB slope row and it has no lag of its own.
- With both off, the prescribed temperature record still gives r +0.17 at −6.
- Not a candidate on its own: a land response with memory. Previewed 10-06 at `hilda33p` (`calibration/
  diag_iav_kernel_preview.R`, C5, before the module existed): no memory (τ 0) was best for the growth.

**Candidates (none priced; which to try is Marcus's call):** a lag or lead on the ocean limb; reopening the equatorial
cell (`eq_frac` 0 at the canonical; the limb cannot run with it); a response to an index that leads Niño 3.4 (not
looked at). Before any of them, two cheap tests from the 11-15 handoff §3 that were not run: T3 (the miss at every lag)
and T4 (leave out 1982–83, 1997–98, 2015–16) say whether the early-side difference is general or carried by a few
events.

**Before a refit:** fit the module with the new degree of freedom at `hilda31fl` and read the module log-likelihood,
the miss r at −6, the GCB slope row and card 4a's same-year miss r.
