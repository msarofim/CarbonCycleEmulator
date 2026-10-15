# PREREG — 2026-09-06b. **DEPTH-DEPENDENT `K` *WITH* THE CONDUIT: DESIGN §3.4a's B2, "A AND B TOGETHER", THE LAST UNTESTED CANDIDATE.**

Scores nothing yet. Written **before** the mechanism exists in either core and before any run.
Follows `collect_2026-09-06_q_attachment_scan.md` §5, which measured that the conduit decouples
the DEEP from `kz` but not the THERMOCLINE, and that at matched parameters every deep-right arm
loses the modern sink and the bomb uptake (D2 failed by 7×).

**Marcus's ruling (2026-09-05) still governs** — stay true to how CCX's ocean works, not to HILDA.
⚠ This prereg tests HILDA's *configuration* because DESIGN §3.4a names it as the one candidate that
does A and B together; the departure authorized on 09-05 (`q_attach_from`) is carried as an arm,
not reverted. Every HS/HD arm is **NOT "HILDA's model"** and is labeled so.

---

## 1. THE CLAIM, FROM TWO MEASUREMENTS ALREADY MADE

- **09-04k** ([[ccx_hilda_conduit_not_kz]]): `K(z)` **without** a conduit is counterproductive —
  under iso-deep in a 32-box column, any `K(z)` that holds the deep age must push MORE ventilation
  through the intermediate (2.55 → 3.87). Correct, and not overturned here.
- **09-06** (`collect_2026-09-06_q_attachment_scan` §4): the conduit **with** a uniform `kz` gets the
  deep profile inside |z| < 1 only by taking `kz` to 1061–1747, which starves the thermocline: the
  sink falls 3.07 → 2.54 GtC/yr, the CO₂ rows lose ~2200 log-units, bomb ¹⁴C ~300.

⇒ **Each half was tested without the other, and each failed for the reason the other exists.**
HILDA's `K(z) = 465 + 7096·exp(−(z − 75)/253)` m²/yr (Siegenthaler & Joos 1992, Table 1, as read in
`collect_2026-09-04k_candidateA_and_HILDA.md`) is 7500 at its surface-box base and 465 below ~700 m —
**the thermocline mixes at the incumbent's rate, the deep at a tenth of it, and the conduit fills
the abyss.** The claim under test: **with both halves on, the deep profile stays inside |z| < 1 AND
the decadal ocean streams recover most of what the uniform-`kz` arms lost.**

## 2. THE MECHANISM TO BUILD — declared before it is written

`K` at interface `k` (depth `z_k` = the base of layer `k`; `z_1` = `h_ml`):

    K(z) = kz · [ f + (1 − f) · exp(−(z − h_ml) / z_K) ]

- **`kz_deep_frac` = f ∈ (0, 1]**, `kz_zscale` = z_K > 0 m. **Default f = 1 ⇒ `K ≡ kz` at every
  interface, BIT-EXACT** (the profile is `rep(kz, nl)` by construction, the exponential never
  evaluated), and `kz_zscale` is then INERT. Absence of both fields means f = 1. Every result before
  today is reproduced.
- **Anchored at the ML base: `K(h_ml) = kz` exactly**, so `kz` keeps its meaning (the thermocline
  diffusivity `ent26` fitted the decadal streams with) and the NEW number is the deep floor
  `f · kz`. This is DESIGN §3.4a's own anchoring ("`kz` keeps a NATRE-comparable meaning").
- Applied in **both cores** at the same per-interface vector `aux$kz_int`, and in the two other
  places `kz` enters as a per-interface operator: the pump's export solve (`ccx_pump_export`) and
  `ccx_steady_profile_from_source`. The substep bound uses `max(K)` = `kz`.
- Tests (in `tests/testthat/test-kz-profile.R`): absence and f = 1 bit-exact in spinup AND a
  transient; `kz_zscale` inert at f = 1; MUTATION (f = 0.5 moves the deep > 1 ‰); R vs C++ parity
  at f = 0.5 with HS boxes on; conservation at f = 0.5; invalid values error by name; the pump
  export changes with f (so the solve reads the profile); `max(K)` anchor.

## 3. PROTOCOL

- Base: `ent26` via `dg_vector(CCX_MODE_CANONICAL)`; HS at HILDA's values as before (`hs_frac` 0.16,
  `u_hs` 38, `tau_q` 538, `sst_hs` 2). **`kz` stays at `ent26`'s 6356 in every `K(z)` arm** — the
  thermocline is not re-solved. **The ONE solved number per arm is `f`**, obs-pinned: `f` such that
  the LS bottom box hits the sourced target −175.3 (`ccx_deep_d14c_target()`), bisected on log f.
- **`z_K` is DECLARED, not solved: HILDA's 253 m** is the primary arm. A scan over
  `z_K` ∈ {253, 500, 1000, 2000} is reported WHOLE and never scored by its best — it is the
  trade-off curve, and its shape is a prediction (E6).
- Arms at `z_K` = 253: **conduit at attach 1** (HILDA's own), **conduit at attach 10** (the 09-05f
  departure), and the **32-box column, no conduit** (the A-alone control, re-measured under the obs
  pin). References recomputed in-run: **R0** (`ent26`, own `kz`), **R1** (32-box, uniform `kz`
  obs-pinned), **R2** (attach 10, uniform `kz` obs-pinned) — the three rows of the 09-06 collect §4.
- Steady-state profile (both statistics, dead weight printed) and the 1750–2024 transient
  (`dg_run`/`dg_streams`, gates 5 and 7, min `sst_hs`) for every arm. Decadal set and deep term as
  defined in the 09-06 prereg §5. Materiality tolerance 0.05 in mean|z| as before.

## 4. PREDICTIONS

| | prediction | falsifier |
|---|---|---|
| **E0** | absence / f = 1 bit-exact (spinup and transient); parity at f = 0.5 inside the standing tolerance; conservation < 1e-9; mutation fires | any of these |
| **E1** | at `z_K` = 253 both conduit arms SOLVE, with **f ∈ [0.05, 0.30]** (deep `K` 320–1900 m²/yr, bracketing HILDA's 465) | no solution, or f outside |
| **E2** | ⭐ **at `z_K` = 253 at least one conduit arm keeps every scored layer inside \|z\| < 1**; I expect both | neither |
| **E3** | ⭐⭐ **the two-timescale penalty at least HALVES**: for each conduit arm, Δ(decadal set) vs R0 is better than **½ × R2's** (recomputed; R2 read −341 on 09-06) | either arm loses ≥ ½ of R2's |
| **E3b** | *stretch:* a conduit arm beats **R1** on the decadal set (R1 read −47) — HILDA's configuration does what the best pure column cannot | neither beats R1 |
| **E4** | gate 7 ocean sink at `z_K` = 253, both conduit arms: **\|z\| ≤ 1** (R2 read −1.66) and the CO₂-level rows lose **< 500** (R2: −2217) | either outside |
| **E5** | the A-alone control (32 boxes, `K(z)`, no conduit) at the obs pin does **NOT** bring 1622 m inside \|z\| < 1 — 09-04k's rejection re-measured under this pin — and needs a **larger** f than the conduit arms | it does, or its f is smaller |
| **E6** | over `z_K` ∈ {253, 500, 1000, 2000}: the decadal loss **shrinks** monotonically (deeper fast mixing = more uptake) while the FREE-layer profile stat **grows** monotonically (deeper fast mixing = younger intermediate) — a trade-off, not a free lunch | either sequence non-monotone beyond tolerance |
| **E7** | the NH bomb-peak YEAR z stays within 0.05 of R0's +2.17 in every arm — the 09-06 no-power finding (the peak time is set above the thermocline) holds under `K(z)` too | it moves |

⚠ **E3 is the point and the one I most want.** Pre-check, from the interface depths on `ent26`'s
grid (134, 185, 257, 357, 497, 693, 968 … m) at `z_K` = 253 and f ≈ 0.1: `K`/`kz` = 1.00, 0.84,
0.65, 0.47, 0.31, 0.20, 0.13 … — the top ~350 m mixes at 0.65–1.0× the incumbent, the bomb/anthropogenic
penetration depth (√(`kz`·30 yr) ≈ 440 m) sits where `K` has fallen to ~0.4×. So the LS column should
recover **most but not all** of the decadal uptake; R1's −47 was at 0.83× uniform. If the truth is
that the sink needs the full column at 6356, E3 fails and the conclusion is that this model's
thermocline is deeper than HILDA's `z_K` — which is what E6 measures.

## 5. SCOPE, AND WHAT THIS IS NOT

- **Nothing adopted, nothing fitted, nothing refit.** Defaults f = 1 ship; `ent26` untouched;
  `hs_frac = 0` ships. Two base parameters are added with an absence contract, like `hs_frac`,
  `q_attach_from` and `tau_ex_seas_amp` before them; neither joins the 26.
- **Matched-parameter.** `k_w`, `h_ml`, `pump_grad`, `bomb_total` are `ent26`'s 32-box values. A
  pass is a reason to refit; a fail at E3 is a reason to scan `z_K` (E6) before refitting.
- ⛔ **If E3 passes, the pedagogical statement is the product:** *one mixing number cannot serve
  both timescales; the ocean needs fast thermocline mixing, slow deep mixing, and deep-water
  formation to match bomb ¹⁴C, the modern sink and the natural Δ¹⁴C profile at once.* That is
  DESIGN §3.4a's "complexity forced by the observations is its own pedagogical result", measured.
- The 2 °C Lueker floor excursion (1.62 °C on 09-06) is reported per arm as before.
