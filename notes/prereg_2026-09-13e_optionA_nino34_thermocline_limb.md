# PRE-REGISTRATION — T-A1: option A's UNREFITTED probe at `hilda30c`
# (the Niño3.4-modulated upwelling limb on `ml_lo` WITH A THERMOCLINE RETURN)

**Written 2026-09-13 (e), BEFORE `calibration/diag_ta1_enso_thermocline_limb.R` was written or run.**
Owed by the 09-12 assessment (`notes/assessment_2026-09-12_hilda31s.md` §4, option A: "UNREFITTED
probe … does the solubility-only r flip … at a γ the +55 µatm reservoir implies? Prereg first") and by
handoff 09-13 (d) §4. It is option B's **ruling 2** (`prereg_2026-09-11_option_b_ml_box.md` §2a:
"Fix B = a Niño3.4-modulated upwelling LIMB on `ml_lo` first, with a thermocline return") probed
without a refit and without touching either core, exactly as T-A0 probed the plain `w_up` limb.

---

## 1. Why T-A0 did not settle this, and what is different now

T-A0 (09-08g, `diag_ta0_enso_upwelling_sign.R`, memory `ccx_phase1_cheap_tests_20260908g`) switched
the classical **whole-column** upwelling limb on (`w_up` > 0: every interface upwells at `w_up`, the
mixed layer sinks to the BOTTOM box in one step) and modulated it by (1 − γ·Niño3.4). Result: the
ocean's solubility-only ENSO slope is **linear in W0·γ** (−0.163 + 0.100 × W0·γ GtC/yr per index
unit), the sign flips at W0·γ ≈ 1.6 m/yr, and the observed +0.115 needs **≈ 2.8 m/yr ≈ 26 Sv**
modulated. But the plain limb's MEAN state cost **−135 log-units at 0.5 m/yr** (−4001 at 4), almost
all on `d14c_profile_bd` — the one-step return to the bottom box. Verdict: "A ruled out AS BUILT; B is
the build (shallow, thermocline return)".

**What is different here.** The limb's return is the THERMOCLINE (layer 1), not the bottom box. A
two-way volume exchange V between the mixed layer and layer 1 — V·C₁/dz₁ up, V·C_ml/dz_ml down —
is algebraically the model's own interface diffusion `F = K (C_ml/dz_ml − C₁/dz₁)/dz_mid` with
**V = K/dz_mid**, tracer by tracer (bulk transport at the source ratio = diffusion on each tracer's
own gradient). So the limb's MEAN part is already in the fitted `kz`, and the probe modulates ONLY the
anomaly:

    V_eff(t) = V0 − γ_A · Niño3.4(t),   V0 = kz_int[1] / dz_mid[1],   γ_A ≥ 0 in m/yr per index unit,

applied to `aux$kz_int[1]` (K_eff = K − γ_A·N·dz_mid[1]) in a session wrapper on the pure-R
`ccx_deriv()` — the T-A0 device. **At γ_A = 0 the run IS the canonical (a zero-perturbation
identity), so the mean state is untouched and the price is the ANOMALY's alone.** Both hemispheres
are modulated equally (Niño3.4 is 5 °S–5 °N; the model has no tropical box — accepted by ruling 2).

Measured at `hilda30c` (the pinned canonical; `dg_vector()` is pin-aware, `dg_spinup()` gives the
file's own periodic spinup): **V0 = 10964.4 / 58.645 = 187.0 m/yr.** Niño3.4 never exceeds ~3, so
the floor `max(0, ·)` cannot bind below γ_A ≈ 60 m/yr — it is stated, never exercised.

## 2. The mechanism's precondition, stated before the run
El Niño weakens the exchange; the mixed layer's DIC then moves TOWARD its own air-sea equilibrium
and AWAY from layer 1's. Uptake rises (the right sign) **only if layer 1 is DIC-richer than the
mixed layer** in the annual mean — the thermocline reservoir. The anthropogenic transient runs the
other way (the surface is loaded first, so its excess diffuses DOWN; less exchange keeps more of it
in the ML → less uptake). The probe therefore RECORDS the annual-mean layer-1 − ML concentration
contrast (µmol/kg, each box over its mass at the time — `seasonal_box_observable_artefact`) over
1959–2024, per hemisphere, from inside the wrapper. ⚠ The periodic PI state read at the January
instant shows the NH contrast NEGATIVE (ML 3.51 vs layer 1 2.14 GtC/m at a 24 m winter layer 1) and
the SH positive — the pump's divergence construction on a thin seasonal layer. **The annual mean is
the quantity, not the instant.**

## 3. First-principles sizing (the pre-check, before any run)
Supply anomaly per unit γ_A: ΔS = γ_A · N · A_ls · Δc, Δc the contrast per meter. At Δc ≈ 30 µmol/kg
over the two low-latitude columns (A_ls ≈ 3.0e14 m²): 3.0e14 × 1025 × 30e-6 × 12 g / 1e15 ≈ **0.11
GtC/yr per (m/yr) per index unit** at 100 % conversion. The observed slope is +0.1153 ± 0.0246, so
at full efficiency ~1 m/yr per index would carry it; with the mixed layer's own buffering (only part
of a supply anomaly leaves through the surface within the year) **2–3 m/yr** — the T-A0 scale
(2.8 m/yr ≈ 26 Sv over A_ls). If the contrast is ≤ 10 µmol/kg the needed γ_A rises 3× and is no
longer "physical" (the obs-implied 26 Sv is the whole modulated equatorial upwelling).

## 4. Pre-registered predictions (each with its falsifier)
| id | prediction | falsified if |
|---|---|---|
| **P0** | γ_A = 0 through the R wrapper reproduces the C++ solubility-only arm to < 1e-6 ppm and reproduces the scorecard's hilda30c reads (solubility-only r −0.527; full 0.58× obs) | any mismatch — the wrapper or the spinup is off-mode; STOP |
| **P1** | the annual-mean layer-1 − ML DIC contrast is POSITIVE in both hemispheres over 1959–2024 | either hemisphere ≤ 0 — the mechanism has nothing right-signed to modulate AS BUILT |
| **P2** | the solubility-only r flips from −0.527 to **≥ +0.3** at **γ_A ≤ 3 m/yr** per index unit | r < +0.3 at 3 m/yr; then read where it flips and price the γ_A the obs needs |
| **P3** | the slope is linear in γ_A (as T-A0 found in W0·γ), and **γ_A = −1 mirrors +1** about the γ_A = 0 slope to 10 % (the sign-flip test, climate-modeling skill) | non-mirroring — the floor or a nonlinearity is in play and the read is not a slope |
| **P4** | the UNREFITTED likelihood price at the γ_A that reaches the observed slope is **> −10 log-units** vs the solubility-only arm (mean state untouched; only the ENSO-year rows move), i.e. > 10× cheaper than T-A0's −135 | ≤ −10 — name the rows; the anomaly leaks into something a refit would have to buy back |
| **P5** | the gain per m/yr is within 2× of T-A0's 0.100 GtC/yr per (m/yr) per index — the same water is delivered to the same box | < 0.05 or > 0.20 — the return path matters more than the delivery, and §2's contrast reading says why |

## 5. What this probe can and cannot decide
- It decides whether **the sign and the magnitude are reachable at a physical γ_A without a refit**
  — the assessment's question. It does NOT retire `gamma_enso_ocn_*` (that is a refit with the limb
  in BOTH cores + parity), does not build a tropical box, and adopts nothing.
- "Physical γ_A" is T-A0's obs-implied 26 Sv (2.8 m/yr over A_ls) — a MODEL-DERIVED scale, labeled as
  such; the observation is the GCB slope (+0.1153 ± 0.0246, n 66) and the pCO₂ reservoir (+55.5 µatm,
  needing 0.24× itself = 13.15 µatm over 4.1 % of area = 0.64 µatm over `ml_lo`).
- The estimator is the scorecard's (09-04g: annual ocean uptake ~ year + Niño3.4, 1959–2024, calendar
  years, `dg_annual_sinks`), so P0's reference numbers are the 09-13 (d) scorecard's, like-for-like.

## 6. Scan
γ_A ∈ {0 (C++ and R), −1, 0.5, 1, 2, 3, 4, 8} m/yr per index unit; `gamma_enso_ocn_NH/SH` = 0 in every
arm (solubility-only + limb). Streams via `dg_streams()` against the γ_A = 0 arm. Output
`outputs/diagnostics/ta1_enso_thermocline_limb_20260913.{log,rds}`.
