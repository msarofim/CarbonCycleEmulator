# COLLECT — 2026-09-06. **THE ATTACHMENT VERDICT IS CONTROL-DEPENDENT, THE PURE COLUMN CANNOT MATCH THE DEEP SHAPE AT ANY `kz`, AND AT MATCHED PARAMETERS EVERY DEEP-RIGHT ARM LOSES THE MODERN SINK.**
# **⭐ C3 PASSES: with `kz` solved to the OBSERVATION, bottom attachment puts every scored layer inside |z| < 1 — first time in the arc.**
# **⛔ C5 FAILS: HILDA's own depth-independent attachment ALSO gets there, and scores slightly BETTER (0.461 vs 0.551).**
# **⛔ D2 FAILS by 7×: the conduit decouples the DEEP from `kz`, but `kz` still sets the THERMOCLINE, and the decadal streams pay.**

Scores `notes/prereg_2026-09-06_q_attachment_scan_and_obs_pin.md`. `calibration/diag_q_attachment_scan.R`,
log `outputs/diagnostics/diag_q_attachment_scan_20260906.log` (2 min). **Nothing adopted, nothing
fitted.** `hs_frac` ships 0; `ent26` untouched. Every HS/HD arm is *HILDA HS/HD boxes with `q`
attached below the surface* where `q_attach_from > 1` — **NOT HILDA's model.**

---

## 0. SCORECARD

| | prediction | result |
|---|---|---|
| **A1** | bottom beats depth-indep on the FREE layers at BOTH `kz` | ✅ +1.835 at 1900, +1.477 at 2686 |
| **A2** | attachment main effect > `kz` main effect | ✅ **+1.656 vs +1.194** |
| **A3** | interaction < smaller main effect | ✅ −0.358 |
| **B1** | `kz` monotone non-decreasing in attachment | ⛔ **FAIL** — dips 2367 → 2353 at layers 8 → 9 (§2) |
| **B2** | no interior optimum | ✅ argmin = layer 10 |
| **B3** | FREE stat non-increasing over 7 … 10 | ✅ (7 → 8 rises 0.019, inside the 0.05 tolerance) |
| **B4** | every arm solves | ✅ 10/10 |
| **B5** | HD moves with `kz`, not the attachment | ✅ |
| **C1** | incumbent obs-pinned `kz` in [4800, 6200], inside the bracket | ✅ **5267** |
| **C2** | incumbent 1622 m stays z > +1 | ✅ **+2.28** |
| **C3** | ⭐ bottom attachment: every scored layer inside \|z\| < 1 | ✅ **−0.24 / −0.86 / +0.20**, `kz` 1747 |
| **C4** | bottom `kz` in [1500, 2300], outside the bracket | ✅ 1747, bracket is [4379, 8110] |
| **C5** | HILDA attachment does NOT reach all-inside | ⛔ **FAIL — +0.50 / +0.42 / +0.20 at `kz` 1061, FREE 0.461 < bottom's 0.551** |
| **D1** | pure column: decadal loss > deep gain | ✅ 47.2 lost vs 1.7 gained |
| **D2** | ⭐ bottom keeps more of the decadal set than the column | ⛔ **FAIL — R2 −340.7 vs R1 −47.2** |
| **D3** | R2 sink inside gate 7's bound | ✅ z −1.66 (R0 −0.32) — inside, barely |
| **D4** | R2 NH bomb peak no later than R0 | ✅ +2.16 vs +2.17 — ⚠ a NO-POWER pass, the peak time never moves (§4) |
| **D5** | land/seasonal streams move < 2 | ⛔ `gcb_land_sink` −2.78 (R2), −3.80 (R3), via the shared atmosphere |

## 1. ✅ PART A — THE 09-05f ATTRIBUTION SURVIVES ITS PREREG

| `kz` | attach | bottom | control? | z 1622 | z 2268 | FREE |
|---|---|---|---|---|---|---|
| 1900 | indep | −156.1 | on | +2.28 | +2.01 | 2.147 |
| 1900 | bottom | −171.7 | OFF | +0.23 | −0.39 | 0.312 |
| 2686 | indep | −143.3 | OFF | +3.31 | +3.01 | 3.162 |
| 2686 | bottom | −156.1 | on | +1.98 | +1.39 | 1.685 |

The attachment effect (+1.66) exceeds the `kz` effect (+1.19) and the two are roughly additive
(interaction −0.36). **The P2 gain of 09-05f is the attachment's.** Closed.

## 2. PART B — THE SCAN IS FLAT UNTIL THE LAST STEP

| attach | depth | `kz` | HD | FREE |
|---|---|---|---|---|
| 1 | 160 | 1900 | −109.2 | 2.147 |
| 2–7 | 221 … 1160 | 1960 … 2353 | −109.7 … −113.9 | 2.17 … 2.41 |
| 8 | 1622 | 2367 | −114.1 | 2.424 |
| 9 | 2268 | **2353** | −111.6 | 2.195 |
| **10** | **3172** | **2686** | **−98.7** | **1.685** |

⭐ **Nine of ten arms sit within 2.15–2.42. The whole gain arrives at the last step**, when HD stops
being injected at **2268 m** — the scored layer where the HD–interior contrast is largest (HD ≈ −112
against an interior ≈ −148). So "bottom attachment helps" means, precisely, "not injecting young HD
water into the deepest scored layer helps". B2 passes (argmin is the bottom), but the flatness says
the boundary was never a graded question: it is a step.
⛔ **B1 fails, small and mechanistic.** From attachment 8 to 9, `kz` FALLS 0.6 %. My prediction
treated HD as a fixed endmember; it is not — with fewer old layers to exchange with, **HD itself gets
younger** (−114.1 → −111.6), which youngens the deep it still touches, and the control lowers `kz`
to compensate. Two effects compete; at that one step the endmember wins. (The same fact is B5's
pass: HD is set by what it exchanges with, and by `kz`.)

## 3. ⭐ PART C — THE PIN AT THE OBSERVATION REVERSES THE RANKING

`kz` solved so the bottom box hits **−175.3** (the likelihood's sourced target); the pinned layer's
own z is +0.20 in every arm (target vs the binned −177.6).

| arm | `kz` | in bracket? | HS | HD | LS ml | z 1622 | z 2268 | z 3172 | FREE |
|---|---|---|---|---|---|---|---|---|---|
| incumbent, 32 boxes | **5267** | yes | — | — | −47.6 | **+2.28** | **+1.36** | +0.20 | **1.822** |
| attach 1 — HILDA | **1061** | NO | −91.4 | −124.3 | −24.4 | +0.50 | +0.42 | +0.20 | **0.461** |
| attach 10 — bottom | **1747** | NO | −79.3 | −108.0 | −29.0 | −0.24 | −0.86 | +0.20 | **0.551** |

Three findings, in order of weight:

1. ⭐⭐ **THE PURE COLUMN CANNOT MATCH THE DEEP PROFILE'S SHAPE AT ANY `kz`.** With the bottom
   right, 1622 m is still **+2.28σ too young** (−134.7 vs −165.2) and 2268 m +1.36. GLODAP's deep
   ocean is nearly **flat** below 1600 m (−165 / −176 / −178); a diffusive column with a no-flux
   bottom is **curved** (−135 / −157 / −175) — it must be, because the only route to the bottom
   runs through the intermediate. This is [[ccx_ventilation_error_is_intermediate]] proved
   `kz`-independent: the intermediate defect is the column's GEOMETRY, and lowering `kz` moves the
   whole profile down its curve without changing the curve.
2. ⭐ **BOTH conduit arms put the scored band inside \|z\| < 1 (C3 ✅)** — DESIGN §3.4a's benchmark,
   met for the first time in this arc. They do it with opposite SHAPES: HILDA's attachment gives a
   monotone profile (−158.5 / −169.9 / −175.3) that tracks the global mean; bottom attachment gives a
   **mid-depth MINIMUM** (−168.4 / **−187.3** / −175.3) — the Pacific-like shape, overshooting the
   global mean at 2268 m by 0.86σ.
3. ⛔ **C5 FAILS, and with it the 09-05f ranking.** Under iso-deep, bottom beat HILDA 1.685 vs
   2.147; under the obs pin HILDA edges it, **0.461 vs 0.551**. **The attachment verdict is a
   property of the CONTROL**, and the iso-deep control was pinned to a value 1.85σ from the
   observation. The 09-05f "attachment is the mechanism" is still true (Part A) — but it was the
   mechanism by which the arm coped with a WRONG deep age. With the deep age right, `q`'s attachment
   depth is a second-order choice the profile cannot rank. ⇒ [[ccx_q_attach_control_dependent]].
   ⚠ Neither arm's `kz` is inside the shipped bracket [4379, 8110] — which was bisected for the
   32-box column against this same target and is structure-specific by construction. Not a defect
   of the arms; a statement that the bracket does not transfer.

## 4. ⛔ PART D — AT MATCHED PARAMETERS, EVERY DEEP-RIGHT ARM LOSES THE MODERN OCEAN

Transient 1750–2024, all 26 parameters at `ent26`, only `kz` and the structure changed:

| run | `kz` | deep | logL | Δ total | sink 2015–23 (z) | Δ decadal set | Δ `co2_level` (MLO+SPO) |
|---|---|---|---|---|---|---|---|
| R0 incumbent, own `kz` | 6356 | −156.1 | −1415.9 | — | 3.07 (−0.32) | — | — |
| R1 incumbent, obs-pinned | 5267 | −175.3 | −1748.5 | **−333** | 2.89 (−0.79) | **−47** | −262 |
| R2 attach 10, obs-pinned | 1747 | −175.3 | −4265.3 | **−2849** | 2.54 (−1.66) | **−341** | **−2217** |
| R3 attach 1, obs-pinned | 1061 | −175.3 | −6996.6 | −5581 | 2.36 (−2.10) | −1036 | −3986 |

The deep term gains **+1.74** in every run (by construction). Everything else pays:

- **D1 ✅ — the two-timescale tension, priced on the pure column.** Getting the deep right with a
  uniform `kz` costs 47 on bomb ¹⁴C + sink and 262 on the CO₂ level: the sink drops 0.18 GtC/yr and
  the atmosphere drifts high by 2024. `ent26`'s +1.85 deep miss is a **cheap** compromise — 1.7
  log-units against 330.
- ⛔⛔ **D2 FAILS by 7× — HILDA's mechanism does NOT operate here as built.** At `kz` 1747 the LS
  column's thermocline mixing is 0.27× the incumbent's; bomb ¹⁴C penetration scales as √`kz` so the
  LS takes ~half the bomb carbon per unit area, the anthropogenic sink falls to 2.54, and the CO₂
  rows lose 2200 log-units. **The 16 % cold box does not make up the difference.** (Pre-check in the
  prereg: HS uptake ≈ 0.8 GtC/yr at ΔDIC 30 µmol/kg — it carried roughly that, and the LS lost ~1.4.)
  ⚠ Also `ocean_grad_d13c` −189: the pump's export was solved for the incumbent's operator and its
  δ¹³C gradient balloons at low `kz` — a matched-parameter artifact a refit would remove, said so it
  is not read as physics.
- **D3 ✅ on the bound, not on the sign** — gate 7's ocean z goes −0.32 → −1.66; inside ±2 and
  heading out.
- ⚠ **D4 is a NO-POWER pass.** The NH bomb peak YEAR reads +2.16 / +2.17 / +2.17 / +2.16 across four
  runs whose deep ventilation differs 6×. **The peak time is set by the air–sea exchange and the
  mixed layer, not by anything below** — the standing gate-5 miss is not an ocean-interior problem
  at all. ⇒ [[no_power_null]]; the gate should not be quoted as evidence about the interior.
- ⛔ **D5** — the land sink moves 2.8–3.8 log-units in the HS arms, through the atmosphere (higher
  CO₂ ⇒ more fertilisation). A side effect, reported; not a land mechanism.
- ⚠ **`sst_hs` reached 1.62 °C** in both HS transients — 0.38 °C below the Lueker floor, an
  EXTRAPOLATION of the carbonate constants. Small and smooth; flagged, not hidden.

## 5. ⇒ WHAT THIS MEANS, AND THE ONE CANDIDATE IT POINTS AT

**The conduit decouples the DEEP from `kz`. It does not decouple the THERMOCLINE from `kz`**, and
with one uniform `kz` the two are the same number. The obs-pinned arms get the deep right by starving
the thermocline. `ent26` gets the thermocline right by over-ventilating the deep. **Neither is a
model of the ocean; each is one half.**

HILDA does not have this problem because it never used a uniform `K`: **`K(z) = 465 + 7096·exp(−(z −
75)/253) m²/yr`** — 7500 at the surface-box base, 465 below ~700 m — WITH the HS/HD conduit
(Siegenthaler & Joos 1992, as read in `collect_2026-09-04k`). The upper ocean mixes fast (bomb, the
sink), the deep mixes slowly (old intermediate water), and the conduit fills the abyss.

⛔ **09-04k rejected `K(z)` — WITHOUT a conduit** ([[ccx_hilda_conduit_not_kz]]): under iso-deep in a
32-box column, any `K(z)` that holds the deep age must push MORE ventilation through the
intermediate, so it made the profile worse (2.55 → 3.87). That rejection was correct and is not
overturned; it was a rejection of A alone. DESIGN §3.4a already says it: *B2 is the only untested
candidate that does A and B together.* **It is now the only candidate left, and both of its halves
exist in the repo.** ⇒ `notes/prereg_2026-09-06b_kz_profile_with_conduit.md`.

## 6. ⛔ WHAT THIS IS NOT

- **NOT an adoption**, of either attachment. C5's failure means the profile cannot choose between
  them; D says neither is shippable at matched parameters.
- **NOT a refit.** `k_w` 1788, `h_ml` 134, `pump_grad` 268, `bomb_total` 118 are 32-box values.
  A refit could recover some of D's losses; it cannot recover a 0.5 GtC/yr sink through nuisances
  the CO₂ rows constrain at the ppm level.
- **NOT "HILDA's model."** HILDA's is `K(z)` + conduit; this arc has tested each without the other.
