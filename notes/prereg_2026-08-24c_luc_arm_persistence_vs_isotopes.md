# Pre-registration — the pinned `luc` refit: persistence or isotopic signature?

**Written before launch, 2026-08-24c.** Repo `CarbonCycleEmulator`, trunk `main`.
Discharges the **residual confound** recorded in `handoff_2026-08-24b_plateau_leverage_settled.md`
§8 item 1 and CHANGELOG 2026-08-24b ("RESIDUAL CONFOUND, recorded not buried").

---

## 1. THE CONFOUND, AND WHY IT NEEDS NO NEW ARM

08-24b measured two pinned refits at matched window-end CO₂ relief:

| arm | Δ`rep_dC` (pinned) |
|---|---|
| `foss` 2.5 GtC/yr | **−6.02 σ** |
| `ocean` 9.434 GtC/yr | **+0.18 σ** |

`foss` and `ocean` differ in **two** ways — **persistence** and **isotopic signature** — so the
pair cannot say which bought the relief. §8 proposed building `ocean_deep` to separate them, and
blocked on its vertical profile.

**`ocean_deep` is not needed. The `luc` arm already occupies the discriminating cell**, it is
implemented, and its at-mode numbers are on disk
(`calibration/output/sink_three_arms/three_arms_N_rate2.5.rds`, produced 2026-08-24a):

| arm | fraction of window-end CO₂ effect left at 1960 / 2024 | Δ¹⁴C excursion 1941–50 NH |
|---|---|---|
| `foss` 2.5 | 0.736 / **0.432** | **+9.72 ‰** |
| **`luc` 2.5** | 0.745 / **0.501** | **+0.170 ‰** |
| `ocean` 2.5 | 0.181 / **0.027** | −0.122 ‰ |

`luc` has **`foss`'s CO₂ trajectory** (window-end −6.531 vs −6.512 ppm, matched to **0.3 %**;
slightly *more* persistent at 2024) and **`ocean`-scale isotopes** (|0.170| vs |0.122| ‰, both
~1–2 % of `foss`'s 9.72). That is exactly the specification §8 wrote for `ocean_deep` —
*"`foss`'s CO₂ trajectory and `ocean`'s isotopes"* — with **no vertical profile to choose**.

This is [[bracket_needs_no_new_run]] firing a second time on this arc: *look for a recombination
among existing arms before building arm N+1.*

## 2. WHAT IS RUN

**ONE refit.** Arm N, `CCX_SINK_MODE=luc`, `CCX_SINK_RATE=2.5`, `luc_scale` **PINNED at 0.898400**
(`ARM_PIN_SD` 1e-4 in log space), `CCX_ARM_RESTARTS=8 CCX_ARM_CYCLES=2`, h_ml bounded [85, 120].
**Every one of those settings is copied from the pinned `foss` run**
(`calibration/output/pump_arms_SINK25_PINLUC/refit_sink25_pinluc.log`), so the comparison is
like-for-like down to the restart count. Output: `calibration/output/luc_arm_pinluc/` — **SCRATCH,
never the shipped mode.**

**A CODE CHANGE WAS REQUIRED AND IS GATED.** `ccx_make_logpost()` and `ccx_scaled_forcing()`
applied `luc_scale` as a column multiply and **refused** the `luc` arm, because the builder applies
the arm *after* `luc_scale`, making the columns **affine** (`s·L − S`) rather than linear. The
refusal was right that a guess is unacceptable; it was wrong that the answer is unknown —
`ccx_build_forcing()`'s documented order fixes it. `.ccx_make_luc_scaler()` now composes the closed
form from the arm-off base plus the perturbation: exact, constant-time, and **bit-identical to the
old path whenever the arm is off**. Gated in `test-luc-scale.R` against the builder and
**mutation-tested in both directions** — the refused multiply must FAIL, by a material 10 % of the
perturbation, and a base built with the arm OFF must be refused rather than silently accepted.

## 3. PREDICTIONS

Δσ is measured against the **rate-0 reference** −1859.32 / `rep_dC` **5.5658**, in posterior-sd
units (`rep_dC` sd ≈ 0.243, from `foss`'s 5.566 → 4.102 = −6.02 σ). **A pinned arm's logpost and
Laplace evidence are NOT comparable to a free arm's** — read parameters and per-stream logL only.

**Q1 — THE HEADLINE. Does persistence or isotopic signature buy the `rep_dC` relief?**

- **P1 (predicted): Δ`rep_dC` ≤ −5.0 σ**, i.e. persistence is the driver. *Falsifier:* |Δ| < 1.0 σ,
  which would say the **isotopic signature** did it and the mechanism argument in 08-24b §3 is
  wrong. *Intermediate:* −1 to −5 σ ⇒ **both** contribute, and the split is the measurement.
- **P2 (the exchange rate, per 08-24b §5's lesson — predict the rate, not a yes/no).** `luc` is
  **1.16×** as persistent as `foss` at 2024 (0.501/0.432) at 0.3 %-matched window-end effect. If
  relief is bought by persistence alone, **Δ`rep_dC` ∈ [−8.0, −5.0] σ**, i.e. at or beyond `foss`'s
  −6.02. *Falsifier:* outside [−9, −4].

**Q2 — is the read contaminated, as `foss`'s was?**

- **P3: `sigma_d14c` stays within 0.5 σ**, against `foss`'s **+3.85 σ** (which absorbed the
  14C-free artefact) and `ocean`'s ≤0.15 σ. The luc arm's Δ¹⁴C excursion is **1.75 %** of `foss`'s,
  so there is no Suess artefact to absorb. *Falsifier:* > 1.5 σ — and if it fires, P1's read is
  contaminated and must be reported as such rather than quoted.

**Q3 — the second escape route, with `luc_scale` pinned.**

- **P4: the (`beta_max`, `fert_k`) ρ = +0.997 ridge moves ≥ +1.0 σ in each**, the same direction
  the pinned `foss` (0.93→2.70, 423→1738) and pinned `ocean` (+2.08/+1.75) runs used.
  *Falsifier:* < 0.3 σ, or opposite signs between the two.

**Q4 — the ice term, which is where the plateau arc's sharpest signal was.**

- **P5: `co2_icecore` improves and lands near `foss`'s, not `ocean`'s.** At the mode the arms give
  `foss` **+13.78**, `luc` **+12.33**, `ocean` **+0.48**. After re-optimisation the sign must stay
  positive. *Falsifier:* negative, i.e. the refit spends the ice term.

**PROVENANCE GATE, checked before any of the above is read.** The warm-start logpost must be
≈ **−2691.2** = −1859.32 + (−839.879, the at-mode `luc` total from
`three_arms_N_rate2.5.rds`) + ~8.0 (the pin's prior replacing `luc_scale`'s). The pinned `foss` run
reproduced its own at-mode total the same way to ~1 log-unit (−2647.8 vs −1859.3 − 796.5 + 8.4).
**If this gate misses by more than ~2, the arm on disk is not the arm intended** — the seed-copy
trap of 08-24b §6 says a warm-started scan can look finished while carrying the reference.

## 4. WHAT WOULD BE CONCLUDED

- **P1 predicted + P3 holds** ⇒ the confound is **discharged in favour of persistence**, 08-24b §3's
  mechanism argument becomes a measurement, and **`ocean_deep` is never built** — its only stated
  purpose was this discrimination.
- **P1 falsified** ⇒ the isotopic signature drives `rep_dC`, which would be a genuinely new result:
  `rep_dC` is scored on CO₂ *and* δ¹³C station levels (`R/likelihood.R:1105, 1251`), so an isotopic
  route exists and would need to be traced.
- **Intermediate** ⇒ report the split. Do NOT round it to either story.

Nothing here re-opens the plateau: 08-24a and 08-24b both stand, and `rep_dC` still belongs to the
century drift. This measures **which property of a probe moves `rep_dC`**, which is what makes the
century-drift programme's next probe designable.
