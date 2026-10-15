# COLLECT — 2026-09-06b. **K(z) WITH THE CONDUIT: THE MODERN SINK COMES BACK (CO₂ rows −28 vs −2217), THE DEEP IS RIGHT AT 1622 m, AND EVERYTHING STILL LOST POINTS AT THE COLD BOX'S GAS EXCHANGE.**
# **⛔ E1/E2/E3 FAIL AS REGISTERED: HILDA's own attachment has NO solution (its deep floor is HD − 54 ≈ −171 ‰), and bottom attachment solves at ONE `z_K` only, with 2268 m 1.5σ too OLD.**
# **⭐ On the one arm that solves, the two-timescale penalty falls from −341 to −165 and the sink from z −1.66 to −0.52 — 48 % of R2's loss, inside the halving criterion by 3 %.**
# **⚠ MY SOLVER WAS WRONG ON THE FIRST RUN and reported a physical ceiling that was a bracket assumption — §5.**

Scores `notes/prereg_2026-09-06b_kz_profile_with_conduit.md`. `calibration/diag_kz_profile_conduit.R`;
log `outputs/diagnostics/diag_kz_profile_conduit_20260906.log` (the first run, with the endpoint
bracket, is kept as `..._run1_endpoint_bracket.log`). Mechanism `kz_deep_frac` / `kz_zscale` in both
cores, `tests/testthat/test-kz-profile.R` (26 expectations); **suite 1887 pass / 0 fail / 4 skip /
70 warn** (was 1861 / 0 / 4 / 66; the +26 are this file, the +4 warnings are its own Lueker
extrapolation and LUC-window notices). **Nothing adopted:** `kz_deep_frac` ships **1**, `hs_frac`
ships **0**, `ent26` untouched. Every HS/HD arm is *HILDA HS/HD boxes with K(z) and `q` attached at
the bottom* — **NOT "HILDA's model."**

---

## 0. SCORECARD

| | prediction | result |
|---|---|---|
| **E0** | absence bit-exact; parity; conservation; mutation | ✅ max\|d\| **0.000e+00**; R–C++ **5.68e-14**; closure **3.97e-17**; f 1 → 0.5 moves the deep −110.3 → −130.2 |
| **E1** | both conduit arms solve, f ∈ [0.05, 0.30] | ⛔ **HILDA's attachment: NO solution at any `z_K`** (closest +4.1 ‰ short); bottom: **f = 0.166** at `z_K` 253 (inside the window), none at 500 / 1000 / 2000 |
| **E2** | a conduit arm keeps every scored layer inside \|z\| < 1 | ⛔ bottom arm **−0.03 / −1.48 / +0.20** — 2268 m too OLD |
| **E3** | ⭐⭐ decadal penalty at least halves vs R2 (−340.7), BOTH arms | ⛔ as registered (one arm missing). **Bottom arm alone: −164.6 vs the −170.4 needed** — 48 % of R2's loss |
| **E3b** | a conduit arm beats R1 (−47.2) | ⛔ −164.6 |
| **E4** | gate 7 \|z\| ≤ 1 and CO₂-level loss < 500, both arms | NOT RUN as registered; **bottom arm: gate 7 z −0.52, CO₂ rows −28** — both inside |
| **E5** | A-alone control: 1622 m stays outside, larger f | ✅ z +2.39, f 0.799 |
| **E6** | the `z_K` trade-off is monotone on both branches | **VACUOUS** — one arm on one branch |
| **E7** | NH bomb-peak year z within 0.05 of R0 | ✅ +2.16 … +2.17 across every arm |

## 1. THE ARMS (f solved to hold the bottom box at −175.3; `kz` = 6356 held at the ML base)

| arm | `z_K` | f | K_deep m²/yr | HS | HD | LS ml | z 1622 | z 2268 | FREE |
|---|---|---|---|---|---|---|---|---|---|
| attach 1 — HILDA | 253 … 2000 | **none** | — | — | — | — | — | — | closest +4.1 ‰ (253), +17 (500), +31 (1000), +46 (2000) |
| **attach 10 — bottom** | **253** | **0.166** | **1058** | −79.1 | −107.8 | −29.5 | **−0.03** | **−1.48** | **0.751** |
| attach 10 — bottom | 500 / 1000 / 2000 | none | — | — | — | — | — | — | +3.3 / +18.6 / +36.8 ‰ short |
| no conduit, 32 boxes | 253 | 0.799 | 5079 | — | — | −47.7 | +2.39 | +1.41 | 1.903 |
| no conduit, 32 boxes | 500 / 1000 / 2000 | 0.773 / 0.713 / 0.582 | 4911 / 4529 / 3696 | — | — | −47.8 | +2.48 / +2.60 / +2.70 | +1.46 / +1.53 / +1.61 | 1.97 / 2.07 / 2.15 |

**The bottom arm's profile at `z_K` 253:** −29.5 / −33.1 / −35.8 / −40.3 / −48.2 / −62.2 / −86.6 /
−123.1 / **−165.5 / −195.7 / −175.3** against GLODAP −165.2 / −175.6 / −177.6 below 1500 m. The
mid-depth minimum that bottom attachment produces (09-06 §3) is now **overshot**: with the thermocline
fast and the deep at 1058 m²/yr, 2268 m is cut off from above AND is not where the conduit delivers.
⚠ A second root exists at **f = 0.0097** (K_deep 62): its intermediate is DEAD (−400 to −870 ‰
against GLODAP −144 / −165) and it is reported, not used — §5.

## 2. ⛔ HILDA's ATTACHMENT HAS A FLOOR, AND THE FLOOR IS THE HS ENDMEMBER

Along f at attach 1 the deep goes −110 (f 1) → −161 (0.1) → −170 (0.01) → **−171.1 (0.001)** and
stops: with `q` injecting HD water into EVERY layer at HILDA's `tau_q` = 538, the interior cannot
be older than HD minus the decay across one exchange time, **HD − ~54 ‰**, and our HD is **−117**.
HILDA's HD is **−136** because their HS is at −120 against our −86 ⇒ this is
[[ccx_hs_endmember_is_kw]] again, now as a HARD ceiling rather than a score: **at `ent26`'s `k_w`
(1788, 2× HILDA's 906-equivalent) the cold box is too well equilibrated for HILDA's geometry to
reach the observed deep age at any `K`.** The 32-box posterior pins `k_w` 20.8× tighter than its
prior — but that pin was fitted with ONE surface box. The structure re-opens the question of
whether HS should carry its own exchange (HILDA's own assumption is winter ice cover canceling the
stronger high-latitude winds — inherited in `R/model.R`'s comment as THEIR assumption).

## 3. ⭐ THE TRANSIENT: THE CO₂ SINK IS A THERMOCLINE QUANTITY, AND K(z) RETURNS IT

| run | `kz` / f | logL | Δ total | Δ decadal | Δ CO₂ level | sink 2015–23 (z) |
|---|---|---|---|---|---|---|
| R0 `ent26` | 6356 / 1 | −1415.9 | — | — | — | 3.07 (−0.32) |
| R1 column, uniform obs-pinned | 5267 | −1748.5 | −333 | −47 | −262 | 2.89 (−0.79) |
| R2 bottom conduit, uniform obs-pinned | 1747 | −4265.3 | **−2849** | **−341** | **−2217** | 2.54 (−1.66) |
| **B_253 bottom conduit + K(z)** | 6356 / **0.166** | **−1875.0** | **−459** | **−165** | **−28** | **2.99 (−0.52)** |
| N_253 column + K(z), no conduit | 6356 / 0.799 | −1498.9 | −83 | −9 | −68 | 2.97 (−0.57) |

⭐ **The CO₂-level rows go from −2217 (R2) to −28 — better than the pure column at R1 (−262).** With
K(z) anchored at `ent26`'s `kz` over the top ~350 m, the modern anthropogenic sink is 2.99 GtC/yr
against `ent26`'s 3.07 and GCB's target; **the sink lives in the thermocline and never needed the
deep `K` that the deep age forbids.** The deep is right at the same time. That is the two-timescale
claim, measured on the sink half.

⛔ **Not on the bomb half.** `d14c_NH` −46, `d14c_SH` −117. Probed: the arm's atmospheric bomb peaks
are **845.5 (NH) / 675.7 (SH) ‰ against obs 855.3 / 659.8 and R0's 859.4 / 693.0**, and by 1975
the atmosphere sits **21 ‰ BELOW R0** in both hemispheres (388 vs 409 NH; 373 vs 394 SH). **The
ocean takes up too much bomb ¹⁴C after the peak** — the cold box, flushed at 38 m/yr into a
reservoir ~50× its volume with `ent26`'s `k_w`, is a stronger bomb sink than the 32-box fit ever
had to accommodate (`bomb_total` 118 was fitted without it). Same organ as §2, opposite symptom:
**HS exchanges too fast for the deep age AND for the bomb curve.**

The other two losses are matched-parameter artifacts, said so they are not read as physics:
`ocean_grad_d13c` **−195** (the pump's export re-solves under K(z) and holds the DIC gradient to
−15, but its δ¹³C signature was fitted at uniform K), and `d13c_level_SPO` **−60** (the HS box's
cold-water ¹³C fractionation over 16 % of the SH, never seen by the fit). Gate 5's NH peak YEAR is
+2.16 in every arm (E7 ✅) — the peak time is set above the thermocline, as 09-06 found.

## 4. ⇒ WHAT THIS SETTLES, AND WHAT IT HANDS TO MARCUS

**Three structural statements now rest on observations, not on fit:**
1. The natural deep Δ¹⁴C profile is flat below 1600 m and a diffusive column cannot flatten it at
   any `K` ⇒ the abyss is filled from the surface at high latitude ([[ccx_column_cannot_flatten_deep]]).
2. A conduit with uniform `K` gets the deep right only by starving the thermocline ⇒ one mixing
   number cannot serve the centennial and the decadal timescale at once (09-06 §4).
3. Fast thermocline mixing + slow deep mixing + a bottom-attached conduit returns the modern sink
   with the deep right — at HILDA's `z_K` and at a deep `K` 2.3× HILDA's — and what it still gets
   wrong (bomb ¹⁴C, HILDA's attachment's floor) is one organ: **the cold box's air–sea exchange.**

**What it does NOT settle:** whether a refit closes the bomb rows and the 2268 m overshoot without
losing the sink. The window is narrow (`z_K` 500 misses the deep by 3.3 ‰), every nuisance is a
32-box value, and the `kz` bracket was bisected for the column. **A refit with the structure is
indicated and its design is a ruling** ([[handoff_open_item_is_not_a_ruling]]): which of {f,
`z_K`, `u_hs`, `tau_q`, an HS-specific exchange factor, `h_hs`} to free, `hs_frac` and the
attachment as declared choices, and the bracket re-bisected on the 36-box structure. Torch, not
the laptop ([[consider_torch_first]]): the 26-par refit was 46 tasks.

## 5. ⚠ MY SOLVER, AND A VACUOUS VERDICT — both caught, both on the record

- **The first run reported "NO f holds the deep" for BOTH conduit arms** from an endpoint-sign
  bracket that assumed the deep is monotone in f. A probe showed the bottom-attached deep going
  −116 (f 1) → **−187 (f 0.03)** → −156 (f 0.001): as `K_deep` → 0 the layer above the bottom box is
  cut off and decays toward −1000 while the bottom is held near HD − 60 by the conduit, so the deep
  gets old and then YOUNG again. **Two roots.** The solver now brackets every sign change and reports
  the LARGEST f (the branch continuous with the uniform model, whose intermediate is alive), printing
  the others. ⇒ the standing "implausible result = bug" rule: a "physical ceiling" that appears on the first run of
  a new solver is a bracket assumption until a scan says otherwise. The first log is kept.
- **The first run printed E6 "PASS" on ZERO conduit arms** — `all(diff(x))` on an empty vector is
  TRUE. Now prints VACUOUS. The silent-gate family's eleventh member, met on a fresh script within
  an hour of writing it ([[mutation_test_gates]]).

## 6. ⛔ WHAT THIS IS NOT

- **NOT an adoption.** `kz_deep_frac` ships 1; `hs_frac` ships 0; the structure is a switch with an
  absence contract, like `q_attach_from` and `tau_ex_seas_amp`.
- **NOT "HILDA's model."** HILDA's attachment cannot reach the deep age here (§2); the arm that works
  is HILDA's K(z) shape with the 09-05f bottom attachment, at 2.3× HILDA's deep `K`.
- **NOT a refit**, and the E3 margin (3 % of R2's loss) is not a result to build on — it is a reason
  to run one.
