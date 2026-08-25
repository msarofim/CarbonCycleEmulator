# P3's decisive test — the `luc` arm with `sigma_d14c` ALSO pinned. 2026-08-25. **SCRATCH.**

P3 of `notes/prereg_2026-08-24c_...md` predicted `sigma_d14c` ≤ 0.5 σ and named **1.5 σ** as the
falsifier. It moved **+1.671 σ**, so the pre-registration's own consequence applies: P1's −5.014 σ
`rep_dC` move is possibly contaminated and must not be quoted clean.

**A FIXED-STATE TEST HAS NO POWER HERE, MEASURED NOT ASSUMED.** `rep_dC` enters only the CO₂ and
δ¹³C station terms (`R/likelihood.R:1105, 1251`); `sigma_d14c` enters only the Δ¹⁴C terms. They are
additively separable, so at fixed model output the `rep_dC` optimum is invariant to `sigma_d14c`.
Mutation-tested: across `sigma_d14c` ∈ {2, 6.13, 7.22, 20, 60} the 1-D `rep_dC` argmax is
**bit-identical to 6 decimals** while the peak moves **~200 log-units**. Only a re-optimisation can
route the coupling through the model state.

Identical to `../luc_arm_pinluc/` in every setting **plus** `sigma_d14c` pinned at the reference
**6.125078**. Predictions in `notes/prereg_2026-08-25_p3_sigma_pin.md`, written before launch.

**SEED-COPY TRAP (08-24b §6):** `mode_fit_pumpN.rds` here is the seeded UNPERTURBED reference until
the run finishes. Completion keys on `pump_arms_comparison.rds`.
