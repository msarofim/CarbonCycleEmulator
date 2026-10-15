# COLLECT 2026-08-29d — **THE LAG IS PROHIBITIVE, AND IT IS PROHIBITIVE FOR A STRUCTURAL REASON**
# −838 conditional at lag 2.25, of which the **NH pays 94 %** — because ONE SCALAR LAG SERVES BOTH
# HEMISPHERES. ⚠ And Q3 FAILED in the informative direction: **the fit WANTS the geometry.**

**Prereg:** `notes/prereg_2026-08-29d_price_the_lag.md` (`1f3731c`), gates fixed before the driver.
**Driver:** `calibration/diag_price_the_lag.R`. **Output:** `outputs/diagnostics/price_the_lag.{rds,log}`.
10.2 min. **Q0 PASS on all six controls** (total 1.1402, SH-land 1.3080, NEP 1.3896 @ 10.15, resp
0.0923 @ 5.05, θ 152.9°, r_SPO 1.9309).

---

## 1. THE PRICE

| lag | θ | **frozen** | **conditional** | buy-back | SH-land | `seas_T_amp_SH` |
|---|---|---|---|---|---|---|
| 1.7677 (mode) | 152.9° | 0 | 0 | — | 1.308 | 1.0391 |
| 2.00 | 160.2° | −391.5 | **−184.8** | 53 % | 1.231 | 1.7960 |
| **2.25** | **168.1°** | **−1599.9** | **−838.3** | **48 %** | **1.071** | **3.4945** |
| 2.50 | 176.0° | −3456.7 | −1972.9 | 43 % | 0.890 | 5.4056 |

**Q4 → PROHIBITIVE.** Pre-registered bands: CHEAP ≤ 20, MODERATE ≤ 100, PROHIBITIVE > 100.
**⚠ MY REGISTERED PREDICTION WAS "MODERATE, −20 to −60". Measured −838.3 — wrong by more than an
order of magnitude.** For scale, 27n's cancellation lever cost −204 frozen / −35 conditional; this
is **24× that conditionally.**

## 2. WHY — AND IT IS A MODEL-STRUCTURE FACT, NOT A FIT RESULT

**Q1 PASS, overwhelmingly. The NH pays 94 % of the conditional bill:**

    co2_seasonal_MLO   -586.96      d13c_seasonal_MLO  -201.57     = -788.53  of -838.32
    co2_seasonal_SPO    -35.30      d13c_seasonal_SPO   +14.56

**`seas_lag_p` IS GLOBAL — VERIFIED IN THE SOURCE, not inferred.** `src/ccx_core.cpp:386`:

    P.seas_npp_amp[hi] * npp * (seas_insol(SEAS_PHI_EFF[hi], t - P.seas_lag_p / 12.0) ...

`SEAS_PHI_EFF` is indexed by hemisphere; **`seas_lag_p` is a SCALAR** and shifts the NPP phase in
BOTH hemispheres by the same amount. The amplitudes are already per-hemisphere arrays
(`seas_npp_amp[2]`, `seas_T_amp[2]`) — **the lag is the one that is not.** The respiration phase is
a separate compile-time global, `SEAS_T_LAG = 2.0` (`ccx_core.cpp:168`, applied line 379).

⇒ **The SH needs its NEP rotated ~12° later; the NH does not; there is exactly one knob for both.**
The model has no way to express the change the SH needs, and the MLO cycle — the part it fits
BEST — is what pays for asking.

**Q2 PASS as pre-registered: the lag buys nothing by itself.** Frozen at 2.25 the SH-land net moves
1.308 → 1.283 (−1.9 %) while the FLOOR falls 0.632 → 0.283. **It opens the door; it does not walk
through it.** **Q5 PASS**: r_SPO 1.930 → 1.956 frozen — and *away* from the observed 1.00.

## 3. ⚠ Q3 FAILED, AND THAT IS THE MOST INTERESTING RESULT HERE

**I predicted `seas_T_amp_SH` would NOT rise** — the CO2 seasonal rows are matched by cancellation
and have no power to ask for the partition fix ([[seas_right_observable_wrong_drivers]]).
**It rose 1.0391 → 3.4945 (3.4×) at lag 2.25, and to 5.4056 at 2.50**, taking SH-land **1.308 →
1.071 → 0.890** — from 1.92× observed to **1.57× and 1.30×**.

⇒ **Once the geometry permits cancellation, the fit USES it, unprompted.** The no-power argument was
right about θ = 152.9° and wrong as a general claim: at that separation raising respiration barely
helps and costs prior, so the rows *appeared* powerless. **They were not powerless; the geometry was
blocking the exchange.** That reframes [[seas_right_observable_wrong_drivers]] rather than
overturning it — the rows still cannot see the partition error itself, but they will spend a lever
that pays, and at a better θ this one pays.

⇒ **So the SH defect is not merely diagnosable — it is FIXABLE, and the fit will do it voluntarily.
What blocks it is entirely the NH bill from the shared lag.**

**⚠ AN OPEN DISCREPANCY, FLAGGED NOT RESOLVED.** The `seas_T_amp_SH` prior gain over these arms
measures **+90.66 log units** at lag 2.25 (`prior(log(x))`: −99.09 → −8.45). 27n recorded the
analogous move as **+8.34** (logprior −10.640 → −2.303). `ccx_prior_z("seas_T_amp_SH", 1.0391)`
returns **−4.6387**, which MATCHES 27n's −4.64 σ exactly, so **the prior's z has not changed** and
the two numbers are not measuring the same thing. **Do not quote either as "the prior credit" until
this is settled** — nothing in §1–2 depends on it, and the conclusion does not either.

## 4. WHAT THIS MEANS FOR THE PAIR

**The (gross, lag) 2×2 is NOT worth writing as posed.** Both members are now priced and the second
is unaffordable *through the parameter that exists*.

**⇒ THE INDICATED NEXT STEP IS A MODEL CHANGE, NOT A FIT: make the NPP lag HEMISPHERE-SPECIFIC** —
`seas_lag_p` → `seas_lag_p[2]`, exactly analogous to `seas_npp_amp[2]` and `seas_T_amp[2]` which are
already arrays a few lines away. Then the SH can be rotated to θ ≈ 165–168° while the NH stays at
its fitted 1.7677, and — on this run's own evidence — the fit should take the SH cancellation on its
own. **The prediction to pre-register: the NH rows' −788 disappears** (they are untouched), leaving
the SH-side cost of ~−35 to −50 against SH-land moving 1.308 → ~1.07.

⚠ **That is a DESIGN decision, not a diagnostic**, and it is Marcus's: it adds a 22nd calibrated
parameter, and `SEAS_T_LAG` (the respiration phase, also global, also compile-time) is an equally
valid place to open the same angle. **Not started.**

## 5. THE CMIP6 BLOCK — ⚠ DIAGNOSTIC ONLY

Under authorization 1; `seas_npp_amp_SH` = 0.94 is a CMIP6 ENSEMBLE value, **never shipped, never an
observational constraint**. The shipped constant remains **0.5027**, `status="data"`.

| lag | SH-land | r_SPO | `seas_T_amp_SH` | Δlogpost |
|---|---|---|---|---|
| 1.7677 | **2.304** | 2.755 | 3.788 | 0 |
| 2.25 | 1.246 | 2.087 | 15.467 | −746.6 |
| 2.50 | 0.919 | 1.992 | 18.523 | −1892.3 |

Consistent with 29c: at the mode's geometry the doubled gross just **doubles the error** (SH-land
2.304). It also shows the same lag bill (−746.6), so **the NH cost is independent of the gross** —
as it must be, since the gross is SH-only. Every `seas_T_amp_SH` here is far outside its bracket and
is a MEASUREMENT under authorization 2, not a fitted value.

## 6. NOTHING ADOPTED

`seas_lag_p` stays at the mode; `seas_npp_amp_SH` stays 0.5027; `ccx_mode_file()` still resolves
`from90`.
