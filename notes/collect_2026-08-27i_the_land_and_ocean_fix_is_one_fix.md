# COLLECT 27i — **`seas_npp_amp_SH` HAS THE SIGN BUT NOT THE PRICE, AND THE REASON IS THE RESULT**
# The land and the ocean corrections are not two candidate fixes. They are ONE fix.

> ## ⚠ RE-RUN 2026-08-28 AFTER THE `h_ml` BAND-DECODE FIX — **THE CONCLUSION HOLDS**
>
> Every number below was produced with `h_ml = 85.73 m` (`ccx_unc_to_par(md$u_mode)` under the
> SHIPPED band) where the canonical mode's `h_ml` is **96.47 m**. Fixed by `ccx_adopt_mode_band()`
> (`R/paths.R`, commit `abc9704`); pre-fix outputs are in
> `outputs/quarantine/20260828_hml_band_decode/`. **The driver was re-run and NO VERDICT CHANGED.**
> GPP-end SH-land **0.892 ppm = 1.31× observed** at a conditional cost of **−80.27** (was −79.01); partition 1.931 → **1.830**.
>
> The SPO seasonal decomposition turns out to be nearly insensitive to `h_ml` — the mixed layer
> sets the ocean's carbon CAPACITY, while the SPO seasonal AMPLITUDE is driven by
> `sst_seas_amp_SH` and the entrainment channel. **The harness offset is now −1.5805, not −3.3223**;
> the 1.7418 difference was the wrong decode, and what remains is the bounded refit's
> narrowed-prior constant.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
**Follows** `collect_2026-08-27h_tau_ex_has_no_power_and_the_wrong_sign.md`, which killed fork (a)
and left the SH-LOCAL land channel standing as the blocker. Marcus chose **(A)** — power-check
`seas_npp_amp_SH` before designing any refit around it.

    Rscript calibration/diag_seas_npp_sh_power.R      # ~50 min, 10-point profile + 3 conditional

**Nothing in `R/` or `src/` was touched.** No prereg: this is a power measurement, not a scored test.

---

## 0. THE GRID CAME FROM THE MEASUREMENT, NOT FROM A CHOSEN SPAN

`R/constants.R`: `SEAS_NPP_AMP_SH = 0.5027` is the least-squares scale of the
`CCX_SEAS_PHI_EFF['SH'] = −30` insolation shape onto MOD17A2HGF C6.1 **PsnNet**, **sd 0.087** — and
**GPP gives 0.352** as the other end, "a far wider bracket than the NH's, because SH productivity is
tropical and water-driven". So the GPP end is **−1.73 sd** and the bracket is a *measured
disagreement between two products*, not a prior. The grid is ±sd units about PsnNet.
[[threshold_from_obs_or_law]]

**Gate passed:** the driver factor `insol/n − 1` integrates to **1.086e-16** over a year, so scaling
this constant redistributes carbon *within* the year and cannot shift the annual budget. Measured
rectification is negligible in the event — every level row moves ≤ 0.06 log-units across the whole
grid. (Gated structurally and *measured* separately, because a zero-mean flux **can** rectify
through q10 and this project has been bitten by exactly that. [[seas_isotope_rectification]])

---

## 1. IT HAS THE SIGN — unlike `tau_ex`

| `seas_npp_amp_SH` | sd | SH-local land at SPO | vs obs 0.683 | SPO total | raw Δlp | cond Δlp |
|---|---|---|---|---|---|---|
| 0.5027 (PsnNet, shipped) | 0 | 1.308 | **1.92×** | 1.141 | 0 | 0 |
| 0.4157 | −1.00 | 1.068 | 1.56× | 0.978 | −45.8 | — |
| **0.3520 (GPP end)** | **−1.73** | **0.892** | **1.31×** | 0.882 | −113.9 | **−79.0** |
| 0.2556 | −2.84 | 0.676 | 0.99× | 0.791 | −273.2 | −193.7 |

**The measurement's own bracket closes 67 % of the excess.** That is a real lever, and it points the
right way — where `tau_ex` at 4× made the ratio *worse*. The conditional slice buys back ~30 %
(0.69–0.71×), the same discount 27h measured.

The partition ratio moves too, **and the two arms disagree in sign**, so both must be quoted:

| SPO δ¹³C-per-ppm | PsnNet | GPP end |
|---|---|---|
| raw (rest of the block frozen) | 1.930 | 1.950 — **worse** |
| conditional (block re-optimised) | 1.940 | **1.834 — better** |

MLO control 0.965 → 0.965, invariant: the SH move is not contaminating the NH station.

---

## 2. BUT THE PRICE IS 79 LOG-UNITS, AND **THE ENTIRE BILL IS ONE ROW**

At the GPP end, of the −113.87 raw:

| row | Δ |
|---|---|
| **`co2_seasonal_SPO`** | **−113.25** |
| `d13c_seasonal_MLO` | −3.48 |
| `co2_seasonal_MLO` | **+1.42** |
| **`d13c_seasonal_SPO`** | **+2.99** |
| every level / gradient row | ≤ 0.03 |

**The CO2 amplitude row vetoes the land reduction. The δ¹³C row WANTS it.**

And that CO2 row is precisely the one with no power to identify anything:
[[seas_right_observable_wrong_drivers]] — the mode matches observed SH seasonal CO2 to ~1 %, so
those rows are already matched and can only punish a driver that moves, never reward a correct one.

---

## 3. ⇒ WHY, AND IT IS THE POINT OF THE WHOLE ARC

**The model's SPO total cycle is right BY CANCELLATION.** Model 1.141 against observed **1.168**
(−2.3 %) — assembled from a land component **1.92× too big** and an ocean component **0.45× too
small**, peaking about **5 months apart** ([[seas_spo_two_wrong_pieces]]).

Remove the excess land *alone* and the total collapses to **0.882 (−25 %)**, and `co2_seasonal_SPO`
charges 113 log-units for it. **This is the exact mirror of 27g.** There, the entrainment channel
worked mechanically (P1 PASS) but the fit spent it as a counterweight rather than a replacement —
because the total was already right, so a bigger *net* ocean limb was unaffordable at any phase
([[ent_channel_counterweight]]). Here the land reduction is unaffordable for the same reason,
running the other way.

> **⇒ THE LAND CORRECTION AND THE OCEAN CORRECTION ARE NOT TWO CANDIDATE FIXES. THEY ARE ONE FIX,
> AND NEITHER ARM CAN BE SCORED ALONE. Every experiment that has moved one of them while holding
> the other has been charged for breaking a cancellation.**

### The joint arithmetic, and it lands

- Land at the GPP end leaves the SPO total **0.286 ppm short** of observed (0.882 vs 1.168).
- 27g's P1 measured the entrainment channel moving the SPO **ocean limb 0.247 @ mo 3.68 → 0.614 @
  mo 9.91** at 10 µmol/kg — inside the 5–30 physical pre-check band — i.e. **≈ +0.37 ppm at a phase
  within 1.4 months of the observed ocean peak of 8.52.**
- **Right size, right phase, to replace exactly what the land reduction removes.** And it would put
  the ocean component near the observed 0.522 instead of 0.236.

That is a prediction that can fail, and it is cheap: **one joint arm on top of machinery that
already exists.**

---

## 4. THE TEST I RECOMMEND, STATED SO IT CAN FAIL

**Pre-register a JOINT arm** — `seas_npp_amp_SH` at the **GPP end 0.352** (a defensible measured
value, not a fitted one) **AND** `ent_seas_amp_SH` free in the 5–30 band — against a matched
incumbent, same `match_incumbents_optim` design as 27g.

- **PREDICT** SPO total within ~10 % of observed 1.168; SPO land ratio ≤ 1.45×; SPO ocean ratio
  ≥ 0.75× (from 0.45×); `ent_seas_amp_SH` lands **inside** 5–30 (27g got 4.16, below it); the
  partition residual falls below the 1.93× standing target.
- **FALSIFIER** the joint arm still pays `co2_seasonal_SPO` more than ~15 log-units, or
  `ent_seas_amp_SH` again lands below 5. **That outcome is a real finding**: it would mean the
  entrainment channel cannot supply the ocean amplitude at the phase the land reduction vacates,
  and **4b — a genuine second SH ocean column — becomes the live question**, this time on a
  residual that has had both levers available.

⚠ **`seas_npp_amp_SH` is half of a (shape, size) unit with `CCX_SEAS_PHI_EFF['SH'] = −30`**, and
`R/constants.R` says so: move phi and the amplitude must be re-derived. Nothing here moved phi, so
every number above is **conditional on phi_eff**. [[ccx_phi_eff_amplitude]] already reports the
latitudes right and the amplitude not — which is why this was the place to look, and also why a
phi_eff re-derivation is the natural follow-up if the joint arm underperforms.

⚠ Moving a **measured constant** to the far end of its bracket to buy fit is a step that needs
Marcus's sign-off on its own terms, separately from whether it works. The honest framing is that
PsnNet and GPP disagree by 1.4× and the model currently uses one end without saying why.
