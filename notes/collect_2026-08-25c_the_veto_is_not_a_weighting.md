# Collection — the 86.7 log-unit veto is NOT a stream-weighting artifact. 2026-08-25c.

Inherited item: `handoff_2026-08-25b` §8.2, *"price the station-level streams' effective n —
the single highest-value unrun diagnostic"*, feeding §8.1, the objective-weighting question.

**The diagnostic was run and it answers a question that had already moved.** Two new files,
both report-only:

- `calibration/diag_landed_gap_streams.R` — where the gap lives AT THE LANDED MODES.
- `calibration/diag_stream_neff.R` — effective n of every annual stream, the repricing,
  the bias/scatter split, and what the bias physically is.

---

## 1. §4's premise does not survive its own warning

§4 asks whether *"two station-level streams, fitted through a 5.6 σ nuisance offset, should
outvote the pulse response and the airborne-fraction record"*, on the frozen decomposition's
**93 %**. §7 of the same handoff says frozen costs never predict where a refit lands. §4 did
not apply that to itself.

**At the landed modes the two station-level streams carry −0.1 % of the pin90 gap.**
`co2_level_MLO` **+2.49**, `co2_level_SPO` **−2.40**, net **+0.09** of −86.66.

| stream | Δ at pin90 | share |
|---|---|---|
| `d13c_seasonal_SPO` | **−38.16** | 44 % |
| `d13c_seasonal_MLO` | **−24.22** | 28 % |
| `gcb_land_sink` | **−24.00** | 28 % |
| — those three | **−86.39** | **100 %** |
| `d14c_SH` | −7.04 | 8 % |
| `co2_icecore` | **+7.22** | −8 % |
| `co2_seasonal_SPO` | +5.79 | −7 % |
| prior `rep_dC` | **+4.29** | −5 % |

Gated: both routes to the log-posterior (hand-assembled prior + `by_stream`, and
`ccx_make_logpost()` at the same `u`) agree, and the unpinned arms reproduce their **stored**
logpost to 0.01 — after the `h_ml` band is restored to `[85, 120]`. Under the default `[30, 200]`
band every arm is off by ~1.1 in the same direction, and `u_mode` does not decode at all
(max |u − u(par_mode)| = 1.7). `par_mode` is the authority. ([[ccx_hml_band_provenance]])

## 2. The station levels ARE weakly informed — and it changes nothing

Their effective n was worth measuring and the answer is what §4 expected:

| stream | N | ρ₁ | Geyer n_eff | Δ at pin90 |
|---|---|---|---|---|
| `co2_level_MLO` | 66 | +0.79 | **12.6** | +2.49 |
| `co2_level_SPO` | 59 | +0.73 | **13.2** | −2.40 |
| `d13c_level_MLO` | 45 | +0.66 | 8.6 | −2.55 |
| `d14c_SH` | 79 | +0.81 | 19.4 | −7.04 |

**The streams with small n_eff are exactly the streams that do not carry the gap, and the
streams that carry the gap have n_eff ≈ N.** [[audit_every_target]] in its purest form: which
targets were *already* fine is what decided the conclusion.

| stream | N | ρ₁ | Geyer n_eff | f = n_eff/N |
|---|---|---|---|---|
| `d13c_seasonal_SPO` | 88 | −0.20 (n.s.) | 88.0 | **1.000** |
| `d13c_seasonal_MLO` | 90 | −0.01 (n.s.) | 90.0 | **1.000** |
| `gcb_land_sink` | 66 | +0.16 (n.s.) | 50.3 | 0.762 |

ρ₁ is called insignificant when |ρ₁| < 2/√N_series — otherwise the correction is fitting the
sampling error of an acf.

## 3. AND THE VETO IS A MEAN SHIFT, WHICH n_eff MUST NOT FORGIVE

`R/likelihood.R`'s own `sigma_d13c` retirement block: *"the d13C residual is BIAS, not scatter,
and a free scale cannot tell the two apart … a robustness valve venting the signal."* An n_eff
correction is such a valve. Splitting each stream's Δ into a change in the residual **mean** and
a change in its **scatter**:

| stream | naive | bias | scatter |
|---|---|---|---|
| `d13c_seasonal_SPO` | −38.16 | **−38.12** | −0.04 |
| `d13c_seasonal_MLO` | −24.22 | **−24.96** | +0.73 |
| `gcb_land_sink` | −24.00 | **−24.48** | +0.48 |

**All three are pure bias.** So the two corrections both fail to reach it:

| arm | naive | A: scalar n_eff/N | B: AR(1) GLS |
|---|---|---|---|
| pin120 | −58.75 | −53.38 | −52.61 |
| **pin90** | **−96.91** | **−82.75** | **−82.08** |
| pin60 | −193.53 | −151.01 | −148.85 |

(priced streams only; `co2_icecore` is irregular — 255 rows over 136 years, spacing to 14 yr —
reported at Geyer n_eff **7.6 of 255** and excluded, because there a lag is not a year and the
question is air-age spectral width, i.e. [[ccx_d13c_neff]]'s, not this file's.)

**A 15 % haircut, not two orders of magnitude.** No defensible reweighting of the objective
rescues pin90.

## 4. What the bias IS — and it is a known misfit getting worse

The seasonal δ¹³C-per-ppm partition test ([[ccx_seas_partition]]), first-harmonic semi-amplitude
√(a²+b²) from the same estimator on both sides:

| arm | MLO per-ppm mod/obs | SPO per-ppm mod/obs |
|---|---|---|
| reference | 1.28× | **2.45×** |
| pin120 | 1.30× | 2.61× |
| pin90 | 1.31× | **2.68×** |
| pin60 | 1.33× | **2.84×** |

The CO₂ seasonal amplitude barely moves (MLO 0.92× throughout; SPO 1.06 → 1.05). **Saturation
buys the AF trend by making the seasonal flux MORE photosynthetic, deepening a partition error
that is already 2.45× at SPO.**

## ⇒ THE INHERITED QUESTION IS ANSWERED, AND IT IS NOT THE ONE THAT WAS ASKED

`diag_fert_ridge_streams.R` named three possibilities: (a) genuine physical conflict,
(b) an over-weighted or mis-specified stream, (c) a frozen-vector artifact. The refit killed (c).
**This kills (b): the objection is three streams' mean residuals, on white noise, immune to any
effective-n correction — and it is physically specific.** What is left is **(a)**.

The model cannot have the airborne-fraction trend and the seasonal isotopic partition at the
same time. That is a real internal contradiction and it is reportable as one. It is **not** a
question about how loudly two station-level streams are scored.

**What this does NOT settle, and is still Marcus's:** whether the seasonal δ¹³C streams are
correctly *specified* is a different question from whether they are correctly *weighted*, and
this file only closes the second. The model is 2.45× too depleted per ppm at SPO **before** any
saturation — the reference mode is already failing this test. A structural fix to the seasonal
partition would change what the ridge costs; a reweighting would not.
