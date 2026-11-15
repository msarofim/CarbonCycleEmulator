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
