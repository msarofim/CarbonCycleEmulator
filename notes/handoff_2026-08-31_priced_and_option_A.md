# Handoff — CarbonCycleEmulator, 2026-08-31
# **THE REFIT LANDED, THE GATES WERE PRICED, AND OPTION A SHIPPED — WHICH SUPERSEDED THE REFIT.**
# **NEXT: re-run the refit on 22 parameters. It is owed twice over.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean at `11ff844`**.
**Suite 1255 pass / 6 FAIL / 2 skip.** Nothing running. 4 commits; continues
`handoff_2026-08-30b_the_seven_ruled.md`, whose §4 checklist is now DISCHARGED.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THE CODE WORK IS IN `CarbonCycleEmulator/`.**

---

## 0. STATE IN EIGHT LINES

1. **The 21-param refit LANDED**, both arms converged, cycle-2 gain 0.0000. §1
2. **The 08-28 "shallow `h_ml` = prior credit" rejection does NOT apply to it.** §1
3. **A 14 h refit that gained +33 of LIKELIHOOD moved ZERO DESIGN gates.** §2
4. ⇒ **PRICED: it is STRUCTURAL. `kz` is NOT the lever; the LAND axis is.** §3
5. ⇒ **And gate 12a closes on NEITHER axis — it is an EQUILIBRIUM defect.** §3
6. **Option A SHIPPED: the NPP lag is per-hemisphere, 22 parameters.** §4
7. ⚠ **Which makes the refit in ④ a 21-parameter file in a 22-parameter build.** §4
8. **Seasonal `tau_ex` measured — partially supported, phase not yet pinned.** §5

---

## 1. THE REFIT LANDED (`ae9a0c6`)

`calibration/output/refit_20260830_gamma_diff_remap/{from90,pin90}`, both exit 0, **cycle 2 gain
0.0000 on both**, so neither hit the restart cap while still gaining. from90 **14.0 h**, pin90
**11.0 h**; each parallel arm ran at ~90 % of the 10.9 h single-arm precedent, so pairing cost
almost nothing.

| arm | logpost | `fert_k` | `beta_max` | `h_ml` | `kz` |
|---|---|---|---|---|---|
| from90 | **−1547.2** | 189.22 | 0.5552 | **35.25** | 6400 (95.1 %, rails) |
| pin90 | −1556.7 | 90 (pinned) | 0.4740 | 50.78 | 6464 (97.5 %, rails) |

**THE DECISIVE CHECK.** `h_ml` landed at 35.25 m — essentially the 35.38 m the 08-28 refit was
RATIFIED "do not adopt" over. That ratification rested on a **SPLIT**, not on the value:

    refit     -1547.158 = prior -52.287 + loglik -1494.871
    incumbent -1586.766 = prior -58.932 + loglik -1527.833
    DELTA        +39.608 = prior  +6.645 + loglik   +32.962
    08-28 reject  +4.060 = prior  +7.397 + loglik    -1.199

Comparable prior credit, but the **likelihood IMPROVES by +33.0 instead of degrading**.
⚠ **This does NOT vindicate `h_ml` = 35.25.** Most of that +33 is recovering the adoption's own
cost — the incumbent is a pre-adoption vector read under a post-adoption objective. The claim is
"the refit is likelihood-driven", and isolating `h_ml` needs a PROFILE.
⚠ The split needed **no new machinery** — it is `ccx_make_logpost()`'s own prior loop recomputed.
I first wrote its absence up as blocked on the quarantined `diag_landed_gap_streams.R`. It was not.

**ARM GAP (Marcus's 08-30 ruling 3, discharged):** refitted **−21.19** vs incumbent-arms −19.86.
Refitting BOTH arms did not close it — it WIDENED. `PIN_PRIOR_CREDIT` is γ-independent, so the
excess **−9.52 is a likelihood differential re-optimization cannot recover.** ⇒ `test-mode-file.R`'s
premise is **permanently** false, not transiently; it needs rewriting, not re-tolerancing.

---

## 2. THE GATES AT THE NEW MODE (`f408f85`) — FIRST READING EVER

| gate | incumbent | **refit0830** | reference | verdict |
|---|---|---|---|---|
| 4 airborne fraction | 0.411 | **0.418** | GCB 0.431 | good |
| 4 AF trend | 0.030 | **0.028** | GCB 0.051 | WORSE |
| 5 bomb curve | fail | **fail** | one `tau_ex` | STRUCTURAL |
| 7 land sink | 3.58 (+2.33σ) | **3.60 (+2.37σ)** | 2.410 ± 0.50 | +49 % |
| 7 ocean sink | 2.97 (−0.59σ) | **2.87 (−0.82σ)** | 3.202 ± 0.40 | −10 % |
| 12a IRF(100) | 0.288 | **0.284** | Joos 0.409 | −31 % |
| 12 integrated | +3.78 % | **+3.15 %** | floor of 39.5–65.2 | inside, hugging floor |
| 12b airborne @300 | 0.204 | **0.200** | Joos 0.322, a₀ 0.2173 | BELOW the asymptote |

⇒ **+33 log-units of likelihood moved not one gate materially, and the ones that moved went the
wrong way.** That is a statement about what the objective is aimed at, not a failed refit.

Internal check the new arm is the consistent one: its stored stream sum reproduces under the current
objective to **−0.0** over 21 streams; the incumbent's is **−40.6** off.

---

## 3. ⚠ THE PRICING TEST (`5050df1`) — THE SESSION'S MAIN RESULT

Two iso-fit frontiers from the new mode, each **re-optimizing the other parameters at every step**
(a raw one-at-a-time scan manufactures the answer — `match_incumbents_optim`, 309 log-units of
artifact in this very model).

⚠ **A SELF-CHECK GATE NOW PINS THE FRONTIER'S LIKELIHOOD TO THE OBJECTIVE'S**: it must read
**−1494.871** at the mode's own vector. The first version did NOT — it passed the diagnostic default
sigmas and dropped `luc`/`deep`/`ocean_grad`, reading −1748.09. **253 log-units of pure construction
artifact**, the same trap wearing a new hat. Any future frontier must carry this gate.

**OCEAN AXIS** (`kz` forced down, `beta_max`/`fert_k`/`q10` re-optimized):

    kz     d loglik   z_land   z_ocean   IRF100
    6400        0     +2.37     -0.82    0.284
    5000     -122     +3.01     -1.61    0.282
    3000    -1212     +4.20     -2.99    0.274
    500    -19141     +7.27     -5.94    0.228

⇒ **EVERYTHING GETS WORSE.** As `kz` falls the optimizer raises `beta_max` 0.554 → 0.977 and the
**LAND takes over the drawdown the ocean stops doing**. The CO₂ record pins the TOTAL and the two
substitute almost perfectly, so the pulse decays just as fast.

⚠ **THIS REFUTES THE FRAMING I GAVE ON 08-30** — that the railed `kz` and the fast pulse were "the
same finger pointing at the same thing". **`kz` is not the lever.** `ccx_kz_joos_cost`'s own caveat
("NOT an argument for lowering `kz`", one-at-a-time at package defaults) is vindicated and
quantified: its kz = 500 row gives IRF 0.410; re-optimized it gives **0.228**.

**LAND AXIS** (`beta_max` forced down, `kz`/`fert_k`/`q10` re-optimized):

    beta_max  d loglik   z_land   z_ocean   IRF100
    0.5552          0     +2.35     -0.78    0.283
    0.4500      -38.8     +1.72     -0.47    0.305
    0.3500     -232.0     +0.78     +0.16    0.330
    0.3000     -449.4     +0.12     +0.72    0.342

⇒ **THIS IS THE LEVER.** Gate 7 **CLOSES** — both sinks inside |z| < 1 at `beta_max` 0.35 — and
IRF(100) improves alongside, so the land-sink excess and the fast pulse ARE coupled. **Price −232.**

⇒ ⚠ **BUT GATE 12a DOES NOT CLOSE.** IRF(100) reaches 0.342 of Joos's 0.409 and gate 7 is already
overshooting the other way; the axis would need `beta_max` ≈ 0.01 to reach 0.409.

**VERDICT.** Not weighting (−232 is a real fit cost). **Two coupled but distinct defects**: gate 7 is
closable on the land axis at a price that is **Marcus's judgment call**, and gate 12a is closable on
**neither** axis. The latter is an **EQUILIBRIUM** statement, not a rate one — the model sits at
0.200 airborne at 300 yr, already **below Joos's asymptote a₀ = 0.2173** — so it points at ocean
CAPACITY (buffer / Revelle / alkalinity), which no uptake RATE can fix. **That is the diagnostic to
write next if gate 12 matters.**

---

## 4. OPTION A SHIPPED (`11ff844`) — AND IT SUPERSEDED THE REFIT

`seas_lag_p` → **`seas_lag_p_NH` / `seas_lag_p_SH`**, both keeping the ORIGINAL prior so the split
adds a degree of freedom without smuggling in a belief. **22 parameters.**

**ONE RESOLVER, `ccx_seas_lag_p()`, AND BOTH CORES GO THROUGH IT** — `ccx_cpp_par()` fills the C++
`seas_lag_p[2]` from the same function, so the two cannot hold different opinions about absence.
That is the 08-30 `gamma_diff` lesson applied on the way IN. Absence contract: both fields → use
them; **legacy scalar only → BOTH hemispheres** (every stored 21-parameter `par_mode` takes this
branch, bit-identical); neither → the named default. Verified: legacy vs explicit-equal
**0.000e+00**; unequal lags move SH CO₂ **0.26 ppm**; R↔C++ parity **1.4e-13** at UNEQUAL lags AND
on the legacy path.

**THE REGISTERED PREDICTION SCORES** (`calibration/diag_split_lag_prediction.R`, ~4 min). Holding NH
at its fitted 1.7502 and rotating the SH alone to 2.25:

    total cost   -13.98   (both together: -838 conditional, -1599.9 FROZEN; this row
                           is frozen, so the like-for-like reduction is ~114x)
    NH rows pay   -2.41   (both together: order -788)
    SH rows pay  -17.44
    SH-land       0.647 <- 0.660

**All three structural claims SUPPORTED.** ⚠ The ABSOLUTE targets are NOT scored — that prediction
was registered against the 08-25f mode on a three-times-older objective, so "SH-land toward 1.07" is
meaningless now and only the DIRECTION is read.
⚠ **AND THE SPLIT ALREADY PAYS: SH lag 2.00 scores +11.33.** The fit wants a LATER SH lag than the
NH's, and the old scalar had no way to give it one.

⚠⚠ **THE ORDERING COST 14 HOURS.** Doing A *after* the refit means
`refit_20260830_gamma_diff_remap` is now a **21-parameter file in a 22-parameter build**. Its
`par_mode` still overlays correctly (the legacy branch), so it is a perfectly good **warm start** —
but it is not a mode of the current parameter space. **Had A shipped first, one refit would have
served both.** Do the structural changes BEFORE the refit next time.

**THREE MORE SITES OF THE LIVE-NAMES-ON-A-STORED-VECTOR DEFECT**, all found by the split:
`ccx_adopt_mode_band()`, `ccx_unc_to_par()` and `ccx_check_mode_decode()` each named a STORED
`u_mode` with the BUILD's `CCX_PARAM_NAMES` — correct only while the parameter set never moves. Each
now uses the file's own names and says plainly when a file is from another parameter set;
`ccx_adopt_mode_band()` also decodes only `h_ml`, the sole property it gates.

---

## 5. SEASONAL `tau_ex` (`11ff844`) — MEASURED, PARTIALLY SUPPORTED, NOT ADOPTED

Marcus's 08-31 hypothesis, offered as a cheaper alternative to tropical boxes. Implemented as a
**diagnostic**: `tau_ex_seas_amp` / `tau_ex_seas_phase`, **default 0, NOT one of the 22**, applied to
the **RATE** with a **zero-mean sinusoid** so the annual mean rate — and with it the steady gradient
— is preserved by construction. (Modulating `tau` itself would not: mean(1/τ) ≠ 1/mean(τ), and the
test would be confounded from the start.) Verified off-by-default bit-identical, live at amp 0.6
(27.8 ‰ on SH Δ¹⁴C), parity 1.4e-13.

| | lag gain | gradient cost |
|---|---|---|
| best cell (amp 0.6, phase 6) | **+0.268 yr** = 74 % of the 0.361 needed | **1.12 ppm = 38 %** of the gradient |
| quadrature (phase 3) | +0.169 yr at amp 0.9 | **~5× cheaper** per unit of lag |

⇒ **PARTIALLY SUPPORTED.** It IS a genuine shape-at-fixed-mean knob. The phase dependence is the
signature of **RECTIFICATION** — ⟨k(t)·ΔC(t)⟩ ≠ ⟨k⟩⟨ΔC⟩ against the NH seasonal CO₂ cycle — which is
exactly why phases 0/6 (in phase / antiphase) move the gradient ~5× more than 3/9 (quadrature).

⚠ **THE PHASE IS NOT A FREE PARAMETER.** It is set by ITCZ migration and is OBSERVABLE. Quoting the
best cell would be fitting a physical constant. **The next step is to PIN the phase from observation
and re-read**, not to adopt the scan's argmax. On this evidence it does not obviously save the
tropical-box restructure.

---

## 6. eVolv2k — LOCATED, NOT DOWNLOADED (needs Marcus's go-ahead)

Nothing local; `data-raw/` has the pattern (`download_data.R` + `MANIFEST.csv` with URL, access
date, size, SHA-256).

- **v3 — THE ONE WE WANT.** WDCC/DKRZ, DOI `10.26050/WDCC/eVolv2k_v3`, Toohey & Sigl 2019. NetCDF,
  **21.24 MiB**, 500 BCE–1900 CE, CC-BY-4.0. **Includes reconstructed AOD**, same format as the
  current CMIP7 file.
- **v4 — NEWER BUT NOT THE PRODUCT.** PANGAEA, DOI `10.1594/PANGAEA.971968`, Sigl & Toohey 2024.
  Tab-delimited, CC-BY-4.0. **VSSI only, no AOD** — would need the EVA forcing generator run.
  Better dating; note it for if we ever generate AOD ourselves.

⚠ **THE OVERLAP IS A GIFT: eVolv2k ends 1900, CMIP7 starts 1850 — 51 years of like-for-like
validation** before any splice. Same discipline as the Law Dome/SPO overlap used for the b0 bar on
08-30. **Measure the inter-product offset there; do not assume it.**
⚠ Splicing BREAKS the "like-for-like with the FaIR calib 1.6.0 + CMIP7 drivers" property the current
record was chosen for. It would also remove the 1850 turn-on step that tripped the conveyor test.

---

## 7. THE 6 FAILURES — ONE TRUE STATEMENT

`test-mode-decode.R:15` (ERROR), `:29`; `test-mode-file.R:109` ×2, `:203` (ERROR); `test-prior-z.R:38`
(ERROR). **All six say the same thing: the stored modes are 21-parameter files in a 22-parameter
build**, and `test-prior-z` additionally asserts the retired name `seas_lag_p`. **A refit resolves
them.** Left failing, same discipline as the 08-30 seven — a previously passing test is not edited to
make it pass.

(Two contract tests WERE deliberately inverted as part of the approved change, per the 08-28
h_ml-gate precedent: `test-likelihood.R`'s 21→22 count, and the parameter-name list.)

---

## 8. THE NEXT STEP, IN ORDER

1. ⚠ **RE-RUN THE REFIT ON 22 PARAMETERS.** Owed twice over: for the split, and to collect the
   +11.33 the split already shows is on the table. Warm-start from
   `refit_20260830_gamma_diff_remap/{from90,pin90}` (`par_mode` overlays via the legacy branch).
   **Recipe, verified this session** — frozen driver, dated dir, provenance README, both arms in
   parallel, BLAS pinned; ~14 h. Smoke first: `CCX_ARM_RESTARTS=1 CCX_ARM_CYCLES=1 CCX_ARM_MAXIT=60`.
   ⚠ **`CCX_ARM_MAXIT` is the knob that makes a smoke cheap** — leaving it at 20000 while cutting
   restarts/cycles produced a run still inside its FIRST restart at 23 min.
2. **Then the 6 failures resolve**, and `PIN_PRIOR_CREDIT` can be re-derived from comparable arms.
3. **Marcus's judgment call on the land axis**: gate 7 closes for −232 log-units. Is a correct sink
   partition worth that much CO₂/isotope fit? The model currently buys CO₂ accuracy with partition
   error, and the partition target is an INDEPENDENT observation.
4. **The gate-12a equilibrium diagnostic** — ocean buffer/Revelle capacity, not rates. Nothing on
   either uptake axis can close it.
5. **Pin the seasonal-`tau_ex` phase from observation** and re-read §5.
6. **eVolv2k v3 pull** on Marcus's go-ahead, via `data-raw/` + MANIFEST, with the 1850–1900 overlap
   measured first.

---

## 9. NON-OBVIOUS STATE

- **Nothing is running.** No partial jobs.
- **MEMORY IS UPDATED.** Two new files — [[ccx_gates_priced]] (§3, the session's main result) and
  [[ccx_seas_lag_split]] (§4) — plus a new "Gates, pricing, and model structure" section in
  `INDEX_ccx.md`. Zero dangling links.
  ⚠ `INDEX_ccx.md` hit **18363 B against an 18432 B hard ceiling** (69 bytes) before I moved the
  discharged 08-30 "seven failures" arc to `INDEX_ccx_arch.md`. Now **17430 B** — under hard, still
  **3 KB over soft (14336)**. **The split the 08-30 handoff predicted is still owed**; it has now
  been deferred twice.
- ⚠ **`tau_ex_seas_amp` / `tau_ex_seas_phase` are `base_param`s, NOT among the 22.** Default 0 = the
  shipped model bit for bit. Fitting them is a separate decision.
- ⚠ Everything in `handoff_2026-08-30b` §7 still stands: `ccx_hold_climate()` does not freeze
  `aod_*` (architecture); **never add an AOD → temperature term**; AOD pre-1850 is zero;
  `diag_landed_gap_streams.R` is QUARANTINED and hard-stops; `refit_20260828_sigma_eff` is RATIFIED
  "do not adopt"; the pinned-96 successor is undecided and is NOT a config change.
- ⚠ **`run_modefind_pump_arms.R`'s kink scan can no longer fail** — it prints "0 kink(s)" (the C1
  remap removed all 26) and fires its `!= 3` warning every run. **The substantive half is OWED**:
  `diag_hess_eps_21par.R` chose its Hessian step against a KINKED objective, so the step study must
  be re-run against the C1 objective before any covariance is trusted. Left unmodified for a ruling.
- ⚠ **`ccx_forcing_at(F, i)` takes a ROW INDEX, not a year.** Several parity tests call it as
  `ccx_forcing_at(F, 1900)` and read like dates; row 1900 of 3300 monthly rows is 1908.
- **b0 = 3.017** against its derived bar of 4.0 but **2.8× the external floor (1.087 ppm)**. Its
  fixture is on `ccx_default_params()`, so **no refit will move it** — a model-quality item.

## 10. COMMITS

    11ff844  Option A SHIPPED (22 params), and the seasonal tau_ex idea MEASURED
    5050df1  PRICED: it is STRUCTURAL, kz is NOT the lever, and gate 12a closes on neither axis
    f408f85  DESIGN gates read at the NEW mode: +33 logL of likelihood moved ZERO gates
    ae9a0c6  Refit LANDED, both arms converged -- and the 08-28 rejection does NOT apply

## 11. HOW TO RUN WHAT THIS SESSION ADDED

    Rscript calibration/diag_refit_20260830_landing.R    # ~3 min, the landing checks
    Rscript calibration/diag_price_the_gates.R           # ~20 min, BOTH frontiers
    Rscript calibration/diag_split_lag_prediction.R      # ~4 min, scores the prediction
    Rscript calibration/diag_seasonal_tau_ex.R           # ~8 min, amp x phase scan
    Rscript tests/run_tests.R                            # ~9 min; expect 6 FAILURES, see s.7
