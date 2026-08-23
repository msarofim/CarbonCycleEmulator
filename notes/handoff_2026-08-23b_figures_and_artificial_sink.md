# Handoff — CarbonCycleEmulator, 2026-08-23b: figures, and the artificial mid-century sink

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
**Follows:** `notes/handoff_2026-08-23_sweep_refit_and_rep_dC.md` (the sweep, the refit, the
Hessian, `rep_dC`). That handoff stands; this adds the figure set, the 1940s-plateau literature,
the 12.7 σ correction, and **Marcus's artificial-sink question, which is LIVE with a run in
flight.**

---

## 0. STATE IN TEN LINES

1. **A re-optimisation is RUNNING** with a 2.5 GtC/yr artificial sink over 1942–49, writing to
   `calibration/output/pump_arms_SINK25/`. **It is INDICATIVE ONLY** — §4c. Nothing is decided.
2. **The objective is unchanged for the shipped mode.** Both new switches default OFF and
   reproduce every existing number exactly.
3. **The figure set exists** — `calibration/fig_model_vs_obs.R`, 3 PNGs. §1.
4. **`rep_dC` is the blocker the sink actually moves: 5.55 → 0.89** as the sink goes 0 → 3.5
   GtC/yr, i.e. from a 5.6 σ prior violation to *inside 1 σ*. §4b. **This is the session's result.**
5. **My first answer to the sink question was WRONG and Marcus corrected it.** §3.
6. **The 1940s plateau is a named, unexplained feature** that no model reproduces. §2.
7. **The 12.7 σ is ~5 σ** — it was computed on `n`, not `n_eff`. §2b. The conclusion survives.
8. **Marcus's ice-vs-flask challenge is settled**: the offset does not differ (−0.31 ± 0.15 ppm).
9. **The artificial sink's isotopic signature is WRONG as implemented** and that bounds what the
   running refit can be used for. §4c.
10. **Still no posterior.**

---

## 1. THE FIGURES

`Rscript calibration/fig_model_vs_obs.R [N|D]`, ~30 s → `calibration/output/figures/`:
`fig1_co2_d13c.png` (CO₂ + δ¹³C, each with a residual panel), `fig2_d14c.png` (bomb spike),
`fig3_plateau_zoom.png` (1900–1985 with growth rates).

**They draw BOTH the model box and the station prediction (`box − rep_dC`), which the app does
not.** `plot_keeling()` draws only the box, so the calibrated model necessarily sits ~5.6 ppm
above Mauna Loa there, by construction and unexplained to the viewer.

**FIG 1 PANEL B IS THE ONE TO LOOK AT.** Post-1958 the **ice** residual sits at **+4.8 ppm** while
the **stations** sit at **~0** — and the two observing systems read the same air to
−0.31 ± 0.15 ppm (§2c). That is `rep_dC` hiding a model level bias for one of them, drawn.

**Two plotting bugs found and fixed in the making, both of a kind that would have been quoted:**
differencing the *monthly* series at integer years aliased the SH seasonal cycle into the "growth
rate" (±0.3 ppm/yr, comparable to the plateau signal itself); and `approx(rule = 2)` manufactured
pre-1750 "residuals" that were the flat extrapolation of the model's 1750 value.

---

## 2. WHAT THE LITERATURE AND THE VALIDATION DID TO THE MID-CENTURY

Full write-up: `notes/lit_2026-08-23_1940s_co2_plateau.md`.

**(a) The pause is the published 1940s CO₂ plateau** — ~310–312 ppm, 1940 to the early 1950s,
present in the revised Rubino et al. (2019) record **we score against**. It needs **2–3 GtC/yr
over 1942–49 AFTER firn diffusion and bubble trapping**, so smoothing does not dispose of it.
Bastos et al. (2016): mismatch **0.9–2.0 PgC/yr** across four LUC datasets; the ocean hypothesis
"cannot be confirmed by independent data"; CMIP5 ocean variability supplies only **~0.5 PgC/yr,
"unlikely to be higher"**; Brovkin (2004) says CO₂ should have risen **2.6 ppm even with zero
land use**. **No model reproduces it — and our model reproduces the literature's failure mode**
("reconstructions greatly overestimate atmospheric CO₂ growth rate during the plateau period").

**(b) THE 12.7 σ IS ~5 σ.** `diag_d13c_midcentury.R` used `sd/sqrt(n)`, treating each ice sample
as an independent draw. Law Dome's **air-age spectral width is 4.5–7.0 yr**, and the 1940–1960
window's **13 samples are four groups spanning 18 yr** → 2–3.6 draws. Corrected: **± 0.016 →
± 0.041 ‰, 13.1 σ → 5.1 σ, range 5–7.** **Never quote 12.7 again.** The conclusion survives, so
the 08-22 withdrawal of the LUC time-profile programme stands. **Same non-independence the panel
flagged for the CO₂ ice term — when a correlated-rows defect appears in one stream, audit every
stream built from those samples.** A third term (systematic/calibration, non-linear and localised)
is still unbounded and is now binding.

**(c) The ice-vs-flask offset does not differ.** No download was needed — `obs$ice` IS the raw
sample file (DATA.md mislabelled it "spline"; corrected). Overlap 1962–96: **ice − SPO
−0.31 ± 0.15 ppm**; FIRN −0.40 ± 0.19 (n=20), ICE −0.24 ± 0.23 (n=27), n.s. apart. Smoothing also
fails on its **own correct predictor**: curvature R² 0.008 (p 0.27) vs growth rate R² 0.212.

---

## 3. THE QUESTION I ANSWERED WRONGLY FIRST

Marcus asked whether an artificial correction for the mid-century alone would let the rest of the
model solve better. **I answered a different question and got the wrong answer.**

- **I read "correction" as an OFFSET.** It is not: Marcus meant **an artificial short-term ocean
  SINK** — a *flux*. A flux removes carbon and therefore changes the trajectory **permanently
  after** the window; an offset cannot. Everything I measured about offsets (that a constant
  cannot change a difference; that the swing is +8.91 ppm either way) is true and **irrelevant**.
- **I used RESIDUALS to argue LEVERAGE.** I showed the plateau window fits well (mean |resid|
  2.22 ppm vs 3.14 elsewhere; logL/row −2.58, the second-best era) and concluded it was not the
  problem. **That is backwards.** Marcus's point is that it may fit well *because the parameters
  were bent to make it fit* — a good in-window residual is the symptom of the distortion, not
  evidence against it. **Only a re-optimisation answers a leverage question.**

Keep both errors in view: the residual table in `R/likelihood.R`'s `LIK_ICE_DISCREPANCY` comment
is correct as far as it goes and **must not be read as answering the sink question**.

---

## 4. THE ARTIFICIAL SINK

New switch, OFF by default: `CCX_ARTIFICIAL_SINK_{WIN,RATE}` in `R/forcing.R`, set via
`CCX_SINK_RATE`. Window 1942–49 (the literature's), rate in GtC/yr. **Prescribed, unfitted,
externally sized, carries no free parameter** — so it is *not* the §12c programme the panel
withdrew, which fitted a free E_LUC shape and would have reported it as a mechanism.

**(a) SIZING.** The removal does not stay out of the atmosphere 1:1 — the IRF decays it. At
IRF@50 ≈ 0.38, erasing the model's +4.83 ppm 1960–97 excess needs **~3.4 GtC/yr over 8 yr**,
*above* the literature's 2–3. That gap is itself a result.

**(b) WHAT IT DOES, no re-optimisation, ice residual by era:**

| sink | 1750–1850 | 1850–1900 | 1900–1935 | 1935–1960 | 1960–1997 | **swing** |
|---|---|---|---|---|---|---|
| 0.0 | −0.93 | −1.89 | −4.08 | −1.21 | **+4.83** | **8.91** |
| 1.5 | −0.93 | −1.89 | −4.08 | −2.86 | +2.52 | 6.61 |
| 2.5 | −0.93 | −1.89 | −4.08 | −3.95 | +0.99 | 5.08 |
| 3.5 | −0.93 | −1.89 | −4.08 | −5.04 | −0.53 | **3.55** |

**It is a clean lever on exactly the late half — the pre-1935 record is untouched.**

**And with `rep_dC` re-optimised on the CO₂ streams at each rate (1-D, everything else frozen):**

| sink | `rep_dC`* | co2_MLO | co2_SPO | co2_icecore | CO₂ total |
|---|---|---|---|---|---|
| 0.0 | **5.55** | −75.1 | −64.3 | −690.9 | −836.6 |
| 1.5 | 3.54 | −84.5 | −69.4 | **−671.8** | **−831.9** |
| 2.5 | 2.21 | −94.9 | −75.0 | −677.1 | −853.3 |
| 3.5 | **0.89** | −108.6 | −82.5 | −696.7 | −894.1 |

**`rep_dC` collapses 5.55 → 0.89 — from a 5.6 σ prior violation to inside 1 σ, i.e. to a
physically plausible station-vs-box offset. The sink absorbs exactly what `rep_dC` was
absorbing.** That is strong support for Marcus's hypothesis. But with only `rep_dC` free the CO₂
total barely moves (best +4.7, at 1.5) and the *station* streams degrade monotonically — **a lower
bound by construction**, since the hypothesis is that the other 20 parameters were bent.

**(c) THE RUNNING TEST, AND WHY IT IS INDICATIVE ONLY.**
`calibration/output/pump_arms_SINK25/` — arm N, warm, `CCX_SINK_RATE=2.5`, 8 restarts × 2 cycles.
Warm start reads **−2655.8** against the sink-off **−1859.3**, matching the −796.5 measured
directly, so it is correctly configured.

> **⚠ THE SINK IS APPLIED AS A NEGATIVE FOSSIL EMISSION.** Two consequences, both load-bearing:
> **(1)** the carbon leaves the *system* rather than entering the ocean box, so ocean inventory,
> excess-¹⁴C and conservation are wrong under it; **(2)** it therefore carries the **fossil δ¹³C
> (−28 ‰)** where a real ocean sink is near-neutral (~−2 ‰ discrimination) — **a factor ~10**.
> Measured contamination: **+0.113 ‰ at 1945**, decaying to +0.071 (1960), +0.025 (1980), +0.011
> (2020), against δ¹³C residuals of ~0.1 ‰. **So δ¹³C, Δ¹⁴C and sink numbers from this run are
> NOT trustworthy.** CO₂ outvotes partition ~40:1 ([[ccx_stream_leverage]]), so the CO₂ and
> `rep_dC` results are informative; nothing else is.

**READ FROM IT:** where `rep_dC` lands, what the CO₂ station and ice streams do, and whether the
six out-of-prior parameters come in. **DO NOT READ:** any δ¹³C or ¹⁴C stream, `gcb_ocean_sink`,
or the total logL.

**(d) THE PROPER IMPLEMENTATION, which is the next step if (c) is encouraging.** Route the flux
**into the ocean box** at its own isotopic signature instead of subtracting it from fossil
emissions. That fixes conservation, the ocean inventory and the ¹⁴C terms at once, and makes the
δ¹³C streams usable — which matters because δ¹³C is how the literature attributes the plateau to
the ocean in the first place, and how we reject a terrestrial source at ~5 σ.

---

## 5. NON-OBVIOUS STATE

- **Two new switches, both OFF by default and both verified inert**: `LIK_ICE_DISCREPANCY_*`
  (σ-inflation window on the ice term — `co2_icecore` reproduces −690.86) and
  `CCX_ARTIFICIAL_SINK_*`. Neither changes the shipped objective.
- **The `LIK_ICE_DISCREPANCY` window must NOT be pointed at the plateau** — its own comment
  carries the per-era table showing the plateau is the second-*best*-fitting era. That finding is
  about **offsets and σ**, not about the sink; see §3.
- `pump_arms_SINK25/` is a **scratch** directory. It must never become the shipped mode.
- Everything in handoff 2026-08-23 §7 still applies.

---

## 6. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-23b_figures_and_artificial_sink.md`, then
> `notes/handoff_2026-08-23_sweep_refit_and_rep_dC.md` for the refit/Hessian/`rep_dC` state.
>
> **FIRST: check `calibration/output/pump_arms_SINK25/refit_sink25.log`.** A sink-on
> re-optimisation was in flight. **Read only CO₂ and `rep_dC` from it** — §4c says why.
>
> **The live question is Marcus's:** is the fit being bent to a mid-century the field cannot
> explain, at the expense of the modern period? **The 1-D evidence is strong — `rep_dC` goes
> 5.55 → 0.89 as the sink goes 0 → 3.5 — and the full-refit evidence is what is running.**
>
> **If it is encouraging, §4d is the next build:** route the sink into the ocean box at its own
> isotopic signature, which makes δ¹³C and ¹⁴C usable and fixes conservation.
>
> **Do NOT** quote 12.7 σ (it is ~5), re-centre `rep_dC`'s prior, point the ice-discrepancy window
> at the plateau, or re-run arm D.
