# COLLECT — 2026-09-04k. DEPTH-DEPENDENT K MAKES THE INTERMEDIATE PROFILE
# **WORSE**, IN BOTH FORMS — AND HILDA SAYS WHY, AND SAYS THE MISSING PIECE
# IS **HIGH-LATITUDE**, NOT EQUATORIAL

Marcus: *"Test the depth-dependent K. Separately, consider the HILDA model and whether it should be
informing any of our model's ocean structure."* `calibration/diag_candidateA_intermediate.R`.
**Nothing implemented.**

---

## 1. THE TEST — and it needed a new shim, because the old one was inert

`diag_ocean_candidates.R` overrides `ccx_deriv`; `ccx_spinup()` calls **`ccx_deriv_fast`**, and the
preindustrial isotope state comes from `iso_operator()`, which builds its matrix by numerically
differentiating `ccx_deriv_fast` column by column. So the August shim **cannot reach the
preindustrial profile** — mutation-tested, deep Δ¹⁴C identical to 6 dp with it on and off. This file
shims `ccx_deriv_fast`, which `iso_operator()` then picks up for free.
**Mutation gate passed both ways**: `f == 1` is **bit-exact**; `f = exp(−z/1500)` moves deep Δ¹⁴C
**−156.145 → −275.885**.

**Control is ISO-DEEP, not iso-sink.** `kz` is re-solved per shape to hold the bottom box's Δ¹⁴C at
the incumbent −156.145, so the question is purely: *at the same deep age, does the intermediate
profile improve?* (An iso-sink control would have had no power anyway — 09-04i measured that the
ocean sink cannot discriminate ocean structures at all.)
⚠ Preindustrial steady state only, so the scored band is **> 1500 m**, where the bomb addition is
≤ 4.5 ‰ against an observed sd of 52–60. The error's PEAK (1160 m) is deliberately outside it.

## 2. ⛔⛔ THE RESULT: EVERY DEPTH-DEPENDENT FORM IS WORSE, MONOTONICALLY

| arm | kz solved | K(ML base) | K(bottom) | scored mean \|z\| | max \|z\| |
|---|---|---|---|---|---|
| **Inf (incumbent)** | 6356 | 6356 | **6356** | **2.55** | 3.25 |
| A:5000 | 8061 | 8061 | 4879 | 2.84 | 3.77 |
| A:3000 | 9586 | 9586 | 4151 | 3.05 | 4.13 |
| A:2000 | 12106 | 12106 | 3450 | 3.32 | 4.59 |
| A:1200 | 20407 | 20407 | 2519 | 3.87 | 5.49 |
| **H:253/6 % — Siegenthaler & Joos's OWN fitted shape** | **71084** | 71084 | 4375 | **3.08** | 4.34 |
| H:253/2 % | 184675 | 184675 | 3702 | 3.34 | 4.83 |
| H:500/6 % | 42734 | 42734 | 2893 | 3.76 | 5.53 |
| H:1000/6 % | 20211 | 20211 | 2784 | 3.72 | 5.30 |

⭐ **I ALMOST TESTED THE WRONG THING.** The repo's inherited `oc_shape()` is
`K = kz·exp(−(z−h_ml)/z_K)` — **no floor**, and the August grid swept z_K over **1200–5000 m**.
Siegenthaler & Joos (1992, *Tellus* 44B:186) §3(3) eq.1 fit **`K(z) = K₀ + K₁·exp(−(z−z_LS)/z₀)`
with K₀ = 465, K₁ = 7096 m²/yr, z₀ = 253 m** — a **floor** plus a decay scale **5–20× shorter**
(their K runs 7561 at the ML base, 1788 at 500 m, 648 at 1000 m). **The August form does not test
HILDA's.** Both families are scanned above; **the verdict is the same in both**, which is what makes
it robust rather than a form artifact.
⚠ **And the grid resolves it**: layers 2–5 are 51 / 72 / 100 / 140 m against a 253 m decay scale, so
this is not a resolution failure.

⇒ **DESIGN §3.4a's EVIDENCE GATE FIRES.** The cheaper candidate — one parameter, no new box — is
**measured and shown insufficient** on the intermediate row. It is not merely insufficient, it is
**counterproductive**: every step of depth-dependence makes the 1622 m and 2268 m rows worse.

## 3. ⭐⭐ HILDA SAYS **WHY**, AND IT IS STRUCTURAL

**Read from the paper, not recalled** (`~/Documents/2010/Essenhigh/siegenthaler92tel.pdf`).
HILDA = High-Latitude Exchange/Interior Diffusion-Advection: a low-latitude surface box (LS, **84 %**
of area) over an advective-diffusive Interior, **plus a separate high-latitude surface box (HS,
16 %, mean SST < 5 °C — the Antarctic south of ~52 °S and parts of the North Atlantic) over its own
well-mixed high-latitude deep box (HD)**. Transport is **four** parameters: eddy diffusivity `K`,
upwelling `w`, HS↔HD exchange `u`, and HD↔Interior exchange `q`.

⭐⭐ **THE DIVISION OF LABOUR IS THE WHOLE POINT.** In HILDA, `K(z)` handles the **upper** ocean and
bomb-¹⁴C penetration; **deep ventilation goes through the high-latitude conduit** (`u`, `q`), NOT
through `K`. Their fitted deep diffusivity is **K₀ = 465 m²/yr**.
⛔ **Our model has no conduit, so `K` must do BOTH jobs — and the table above prices that: every arm
needs a deep K of 2519–6356 m²/yr to hold the observed deep age, 5–14× HILDA's 465.**
⇒ **That over-mixed interior IS our intermediate-water defect.** And it explains why depth-dependence
cannot fix it: sharpening K at the top forces `kz` up (6356 → 71084 at HILDA's own shape) to keep the
deep age, which ventilates the middle *harder*. **One mechanism cannot serve two timescales** — which
is the same "one scalar, two jobs" pattern as `tau_ex` and `q10`.

⭐ **AND SIEGENTHALER & JOOS HIT EXACTLY OUR PROBLEM AND SAID SO.** Calibrating constant-K to
steady-state ¹⁴C gave **K = 853**; calibrating it to bomb-¹⁴C gave **K = 4700** — a 5.5× split. Their
words: *"neither of the first two model versions can give reliable estimates of surface-to-depth
tracer transport on significantly different time scales… It is an unsatisfactory situation."* Their
fix was K(z) — **but they already had the high-latitude conduit carrying the deep.** We do not.
⚠ **And even HILDA's K(z) version is not clean**: the paper reports its pre-industrial ¹⁴C as *"too
low above 1500 m"*, i.e. a residual in the same band we are failing.

## 4. ⇒ WHAT THIS MEANS FOR THE EQUATORIAL BOX — AND IT IS AWKWARD

Marcus, 09-04j: *"If the equatorial surface box would help with the intermediate water problem, then
that should be sufficient."* **On this evidence it probably would not, and the two motivations for a
new box now point in different directions:**

| motivation | points to |
|---|---|
| **Fix B / ENSO** (dead on sign for every within-column lever) | an **EQUATORIAL** box |
| **the intermediate-water defect** (measured; §2–3) | a **HIGH-LATITUDE** conduit — HILDA's HS/HD |

Equatorial upwelling is the **return** limb of the cell; high-latitude sinking is the **ventilation**
limb, and it is the ventilation limb our Δ¹⁴C profile says is missing. An equatorial box would move
water the interior already has; it would not relieve `K` of the deep's job, which is what §3 prices.
⚠ **This is an argument, not a measurement** — the honest next step is to price the two against the
Δ¹⁴C profile the way §2 priced K(z), rather than to choose between them on reasoning.

⛔ **AND NOTE WHAT DOES NOT FOLLOW.** B1's August failure (`w_out`, within-column) does **not**
condemn HILDA's HS/HD: `w_out` lifted deep water into the *existing* mixed layer with no separate
cold surface, whereas HILDA's HS is **its own 16 %-of-area surface box exchanging with the atmosphere
at < 5 °C and sinking**. Those are different mechanisms and only the first has been measured.
