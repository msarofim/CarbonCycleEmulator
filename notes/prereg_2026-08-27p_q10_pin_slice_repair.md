# PREREG 2026-08-27p — **THE CONDITIONAL SLICE LEAKED THE LEVER THROUGH `q10`**
# A slice-repair control, written and committed BEFORE the driver exists.

**Status when this was written:** repo clean at `bb2623e`, nothing running, suite 1157/0.
**Nothing below may be edited once the driver exists.** Gates are fixed here.

---

## 0. WHY THIS EXISTS, AND HOW IT CORRECTS 27o §7

27o §7 flagged the `(seas_T_amp_NH, q10)` ridge as a **SPEED** problem — "Nelder-Mead crawls a
direction the data does not constrain — points took 10 / 70 / 150+ min." Reading the stored
`outputs/diagnostics/seas_T_amp_sh_power.rds` shows it is **not only slow. It ATTENUATED the lever
the arm existed to test**, and the attenuation is measurable to three figures:

| a_t (K) | q10 | seas_T_amp_NH | **NH product** | **SH product** | SH-land |
|---|---|---|---|---|---|
| MODE | 1.13579 | 23.4574 | 2.98679 | 0.13231 | 1.3080 (full-frozen) |
| 1.0391 | 1.10920 | 28.6327 | 2.96745 | 0.10769 | 1.3234 |
| 3.5915 | 1.06276 | 49.0455 | 2.98550 | 0.21863 | 1.2552 |
| 5.0502 | 1.04956 | 61.7339 | 2.98638 | 0.24430 | 1.2395 |
| 7.1012 | 1.03834 | **79.3466** | 2.98556 | 0.26719 | 1.2256 |

**`R/model.R:194-195` — the project's OWN documentation, written before this arc:** "seas_T_amp_*
absorbs the LINEAR seasonal response (**at small amplitude only the product `A_T * ln(q10)` is
identified**), leaving q10 only the nonlinear part."

⇒ Three facts follow, and none of them is a new hypothesis:

1. **The NH product is held to 2.9855 ± 0.0009 = 0.03 %** while its two factors move **2.77×** and
   **3.7× in ln-space**. The optimizer is riding the documented ridge, not fitting anything.
2. **`q10` IS SHARED WITH THE SH.** Sliding it down the NH ridge cancels the SH perturbation. The SH
   product — the quantity the arm actually perturbs — rose only **0.10769 → 0.26719 = 2.48×**, where
   at pinned `q10` the same grid gives **6.83×**. **THE ARM DELIVERED 36 % OF ITS OWN LEVER.**
3. The bill for holding the NH product was paid by **`seas_T_amp_NH` running to 79.35 K = 443 % of
   its measured HIGH end (17.92 K)** — a driver amplitude 4.4× outside its own bracket.

⇒ **27n's "84 % buy-back" is NOT the likelihood restoring the signal through legitimate
re-optimization. 64 % of it is `q10` undoing the perturbation through a flat direction.** That is
`[[no_power_null]]` in a new dress: not a null with no lever, but a lever **silently attenuated by a
route back through a shared parameter**. 27n's P4 verdict (−35.11, "the prediction was wrong") and
its P8 headline (**1.79× obs, 15.3 % of the excess closed**) are therefore measured on a
**partly-disarmed lever** and must not be quoted as the cancellation mechanism's reach.

⚠ This does NOT resurrect `seas_T_amp_SH`. The FULL-FROZEN cost at bracket HI is **−204.45**, of
which `co2_seasonal_SPO` carries −187.21. The veto in 27o §6 stands. What is in question is the
**SIZE of the lever**, which every downstream design — the 2×2 of §6 included — needs correct.

## 1. THE REPAIR, AND WHY PINNING `q10` IS NOT A LOSS OF FREEDOM

27o §7 offered two repairs: **drop `q10`**, or **reparameterize to (product, ratio)**. They are the
same slice up to a relabeling, and the simpler one is exact:

> With `q10` **PINNED** and `seas_T_amp_NH` **FREE**, the NH product `seas_T_amp_NH · ln(q10)` still
> spans its whole range. Nothing identified by the seasonal rows is removed. What IS removed is
> `q10`'s **nonlinear** part and its **cross-timescale duty** (`model.R:1086`, `q10^(gmst/10)`),
> which are identified by `gcb_land_sink` and the level rows — **NOT by a seasonal arm, which has no
> business dragging them.**

So the pin is a **restriction of the escape route, not of the fit.** Its price is measurable and S0
measures it.

## 2. THE SLICE

    PINNED  : c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH", "seas_lag_p")   # q10 OUT
    27n FREE: c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH", "seas_lag_p", "q10")

`seas_T_amp_SH` is the profiled parameter and is OUT of both, as in 27n. Grid = 27n's
`TA_COND` bracket points **unchanged**: 1.0391 (landed), 3.5915 (LO), 5.0502 (center), 7.1012 (HI).
`q10` is pinned at the **mode's 1.13579**, not at any conditional landing.

## 3. THE PRE-REGISTERED GATES

Every number on the right-hand side is measured, quoted above, and fixed before the driver exists.

- **S0 — IDENTITY / PRICE OF THE PIN.** At the landed point `a_t = 1.0391`, pinned Δlp minus 27n's
  free Δlp (+1.43) must be **≤ 0** (removing a d.o.f. cannot improve a fit — an EXACT gate, a
  violation means a bug, not a finding) and **≥ −5.00** (the pin must not itself cost more than the
  whole conditional signal it is being used to measure).
- **S1 — THE LEAK IS REAL, AND THIS IS THE HEADLINE.** At bracket HI, pinned SH-land **≤ 1.05**.
  *Derivation, not a hope:* pinning puts the SH product on the FULL-FROZEN profile (0.90418 at HI),
  whose SH-land is **0.8728**; the four remaining slice members are two OCEAN amplitudes, the **NH**
  land amplitude and a LAG, none of which drives SH-local land, so most of 0.8728 must survive.
  1.05 sits midway between 0.8728 and the free-slice 1.2256. **Falsifier: pinned SH-land > 1.05
  means the leak is NOT mainly `q10` and 27n's reading stands as written.**
- **S2 — THE NH STOPS RUNNING AWAY.** Pinned `seas_T_amp_NH` at HI **≤ 30 K** (free: 79.35; mode:
  23.46; its own measured HI: 17.92). Predicted ≈ the mode, because with `q10` fixed the NH product
  needs no compensation.
- **S3 — THE COST IS HONEST.** Pinned conditional Δlp at HI **more negative than −33.68** (27n's
  free value). EXACT, same reason as S0. If it is less negative, the harness is not comparable and
  nothing below may be read.
- **S4 — WHICH ROW PAYS, and it must be the SAME row.** Per-stream breakdown at HI via
  `ccx_loglik(..., by_stream = TRUE)` — NOT `attr(lp(u), "streams")`, which returns NULL and made
  27n's first driver skip its own diagnostic gate `[[mutation_test_gates]]`. Gate:
  `co2_seasonal_SPO` carries **≥ 60 %** of the total pinned conditional cost at HI, as it did at
  87 % frozen and 87 % in 27i. **A DIFFERENT row paying would mean the pin moved the problem, not
  the lever, and the repair is rejected.**
- **S5 — `gcb_land_sink` CONTROL, the pin's own risk.** Pinning `q10` blocks the carbon-budget
  escape. Gate: `gcb_land_sink` changes by **< 25 %** of the total pinned conditional cost at HI. If
  it dominates instead, the pin is trading a seasonal problem for a budget one and must be reported
  as such.

## 4. WHAT IS *NOT* CLAIMED

- This is a **CONTROL, not an arm.** It cannot rehabilitate `seas_T_amp_SH`; the frozen −204.45
  veto is untouched and no gate here can move it.
- **NO CONSTANT AND NO PRIOR IS EDITED.** `SEAS_NPP_AMP_SH`, `phi_eff`, and the `q10` prior are
  untouched. Nothing in `R/` or `src/` is touched.
- It settles neither the **basis decision** (27o §8) nor the **`SEAS_NPP_AMP_SH` sd restatement**.
  Both remain Marcus's.
- ⚠ It does NOT license quoting an absolute logpost against the mode file. The harness sits
  **−3.3223** below it `[[ccx_mode_logpost_offset]]`; everything here is a within-harness difference.

## 5. WHAT THIS DECIDES NEXT — RECORDED NOW SO IT CANNOT BE BACK-FITTED

- **S1 PASSES ⇒** the 2×2 of 27o §6 must be built on the **PINNED** slice, and its reach must be
  re-derived: the land lever vacates ≈ **0.44 ppm** of SH-land (1.31 → 0.87), not the 0.098 ppm
  27n measured, which puts it **within 20 % of 27j's 0.416 ppm** — i.e. the two vetoed levers
  vacate nearly the SAME amount, and 27j's entrainment channel supplied ≈0.37 ppm against it.
- **S1 FAILS ⇒** 27n stands as written, the 2×2 may use either slice, and the 150-min points are a
  pure speed problem to be solved with warm-start rungs.
