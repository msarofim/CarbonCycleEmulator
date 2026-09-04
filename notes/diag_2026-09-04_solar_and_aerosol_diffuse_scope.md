# SOLAR → PHOTOSYNTHESIS AND ANTHROPOGENIC AEROSOL → DIFFUSE LIGHT: SCOPED, BOTH DECLINED
**2026-09-04 · `calibration/diag_aerosol_solar_diffuse_scope.R`**

Marcus: *"I wouldn't expect to be able to capture all of the interannual variability with just
ENSO, volcanoes, and temperature. Let's look into adding the solar insolation/photosynthesis link
(which isn't only about the 11 year cycle but also the increase in solar activity in the early 20th
century) or anthropogenic aerosol emissions → diffuse light to see if there is some easy benefit
there, but interannual variability is not a dealbreaker."*

**Answer: no easy benefit from either.** Solar is dead on magnitude, by a factor of ~175 against the
mechanism the model already has. Anthropogenic aerosol is a *real* mechanism — it is what Mercado et
al. 2009 is actually about, the same paper the volcanic term already cites — but it is ~100 %
degenerate with CO₂ fertilisation, contributes nothing to interannual variability, and buying it
would relocate `beta_max` by 2.3× while changing nothing the data can see.

⇒ Gate V's status is now recorded in the lib: **a FAIL is not a blocker.**

---

## 1. Solar → photosynthesis: three orders of magnitude short

The early-20th-century rise Marcus named **is there** in the CMIP7/FaIR-1.6.0 solar ERF, and it is
small:

| | ERF | ΔTSI | % of TSI | **NPP upper bound** |
|---|---|---|---|---|
| 11-yr cycle, peak-to-trough | 0.0756 W/m² | 0.426 W/m² | 0.031 % | **0.0082 GtC/yr amplitude** |
| secular 1900–19 → 1950–69 | +0.0267 W/m² | 0.150 W/m² | 0.011 % | **0.0058 GtC/yr** |

NPP taken **proportional to irradiance**, which is a ceiling — photosynthesis saturates with light.
Against the observed interannual anomaly sd of 0.911 GtC/yr, the 11-yr amplitude is **0.91 % of the
sd and 0.004 % of the variance**; the secular shift is worth **0.29 GtC over the 50 years it takes**.

For scale, the mechanism already in the model: `gamma_diff` 0.25 × Pinatubo AOD 0.110 = **2.74 % of
NPP = 1.445 GtC/yr — 175× the solar 11-yr bound.**

⭐ **The structural reason, not just the arithmetic.** Aerosols change the **diffuse fraction**,
which redistributes light into shaded canopy that direct beam never reaches — that is why the
mechanism has leverage at all (Gu 2003, Mercado 2009). The sun changes **total irradiance**, which is
1:1 at best. *The high-leverage channel is unavailable to solar by physics.* No implementation and no
run can rescue a three-order-of-magnitude variance deficit, so none was built.

## 2. Anthropogenic aerosol: predicted smooth, and it is

CMIP7 SO₂: 2.3 Mt/yr (1750) → **peak 139.9 in 1979** → 71.8 (2024) — the dimming-then-brightening
shape. But its interannual sd about a 12-dof spline is **3.79 Mt = 2.7 % of the peak**, and sulfate
lifetime is days, so anthropogenic AOD inherits that smoothness. **Predicted before running: it
cannot help gate V.** It does not:

| A_peak (peak anthropogenic AOD-equivalent) | NPP + % | sd(V) | z(V) | AF trend /decade |
|---|---|---|---|---|
| 0.00 | 0.00 | 0.698 | −2.67 | +0.0057 |
| 0.02 | 0.50 | 0.696 | −2.69 | +0.0071 |
| 0.05 | 1.25 | 0.694 | −2.72 | +0.0091 |
| 0.10 | 2.50 | 0.691 | −2.76 | +0.0120 |
| 0.20 | 5.00 | 0.690 | −2.77 | +0.0246 |
| **observed** | | **0.911** | | **+0.0147 ± 0.0080** |

(at the conditional optimum of §3; gate V moves by 0.008 GtC/yr and slightly the *wrong* way).

⭐ **What it DOES move is the AF trend** — the one quantity gate 4's retirement left as a real, if
not significant, difference: +0.0057 → +0.0120 per decade at A_peak = 0.10, against the observed
+0.0147, with the AF level still right (0.4225 vs 0.4313).

## 3. …but it is ~100 % degenerate with CO₂ fertilisation

The frozen-parameter cost is enormous and **almost entirely fictitious** — the same lesson the
volcanic `gamma_diff` pricing taught in August, when the frozen column overstated the real cost by
82 %. Re-optimising the fertilisation pair (`beta_max`, `fert_k`):

| A_peak | beta_max | fert_k | **Δ logL re-optimised** | Δ logL frozen | absorbed |
|---|---|---|---|---|---|
| 0.00 | 0.6974 | 304 | 0.0 | 0.0 | — |
| 0.02 | 0.7547 | 352 | **+5.3** | −106 | 105 % |
| 0.05 | 0.8975 | 465 | **+8.3** | −692 | 101 % |
| 0.10 | 1.6339 | 1027 | **+1.0** | −2810 | 100 % |
| 0.20 | 2.4085 | 2000 | −151.9 | −11362 | 99 % |

⇒ **The data cannot tell the two apart.** A gain of +5 to +8 log units on an objective measured in
thousands is not a signal; it is the fit shrugging. Both terms raise NPP monotonically over the
industrial period, so CO₂ fertilisation absorbs the aerosol term nearly exactly.

The only feature fertilisation *cannot* imitate is the **post-1979 decline** — the global-brightening
signature. Separating them needs a target keyed to that decline, which the objective does not have.

## 4. FACE narrows it but does not decide it

`beta_max` is not free: it also sets the model's predicted FACE response. At each conditional
optimum, R(400 → 564 ppm):

| A_peak | beta_max | R(400→564) |
|---|---|---|
| 0.00 | 0.6974 | 11.5 % |
| 0.05 | 0.8975 | 13.0 % |
| 0.10 | 1.6339 | **15.5 %** |
| 0.20 | 2.4085 | 14.3 % |

The FACE envelope runs from **0 %** (EucFACE, mature and P-limited) to **23 %** (Norby 2005 young
plantations), with the Norby 2025 synthesis at 21.8 % — too wide to reject any of these. So the
honest reading is that **neither the CO₂ record nor FACE can identify the term**.

⚠ **And that is the argument against adding it now**: buying the aerosol term relocates `beta_max`
by a factor of 2.3 while changing nothing measurable — and `beta_max` is what the pulse IRF and every
fertilisation result rest on. An unidentifiable term that silently moves an identified parameter is a
bad trade.

## 5. ⇒ Rulings recorded

* **Solar → photosynthesis: DECLINED** on magnitude and on structure. Not implemented; the
  arithmetic is in §1 and does not need a run.
* **Anthropogenic aerosol → diffuse light: DECLINED FOR NOW, not refuted.** It is physically real
  and roughly free once the fertilisation pair re-optimises, but unidentifiable against CO₂
  fertilisation on the current observation set, and it costs a 2.3× `beta_max` relocation.
  ⇒ **The thing that would make it worth revisiting is a target keyed to the post-1979 decline**
  (a land-sink or NPP trend constraint spanning the brightening period), not more CO₂ data.
* **Gate V's failure is NOT a blocker** (Marcus). Recorded at the gate itself in
  `lib_design_gates.R`, so no future session reads a FAIL there as something to chase.

## Files
`calibration/diag_aerosol_solar_diffuse_scope.R`,
`calibration/output/aerosol_solar_diffuse_scope/{rds,log}`,
`calibration/lib_design_gates.R` (gate V status block).
Drivers used, both CMIP7 / FaIR calib 1.6.0 like-for-like with the volcanic AOD product:
`FaIRtoFrEDI/calibration_v160_prod/volcanic_solar_M.csv` and `…/emissions_v160_cmip7harm_ssp245.csv`.
