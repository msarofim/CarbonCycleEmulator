# Handoff — CarbonCycleEmulator, 2026-08-30 (b)
# **ALL 7 RULED. 6 RESOLVED, 1 FAILING ON PURPOSE. A THIRD ONE-CORE-ONLY DEFAULT FOUND AND FIXED.**
# **NEXT: the 21-param REFIT — both arms, h_ml UNBOUNDED, smoke run first.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `6639e3f`.
**Suite 1243 pass / 1 FAIL / 2 skip — the one failure is DELIBERATE.** 2 commits; continues
`handoff_2026-08-30_two_adoptions_and_the_oob_read.md`.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THE CODE WORK IS IN `CarbonCycleEmulator/`.**

---

## 0. STATE IN SEVEN LINES

1. All 7 failures **MEASURED before being ruled on** — `calibration/diag_attribute_the_seven.R`. §1
2. **Two of the previous handoff's five sketches were WRONG.** §1
3. Marcus ruled on all three open questions; 6 of 7 resolved. §2
4. ⇒ Applying them **uncovered a THIRD silent one-core-only default, 0.647 GtC/yr.** §3
5. `test-mode-file.R` is **failing on purpose**, with the reason written into the file. §2
6. The **b0 bar is now DERIVED** from the CO2 record, not a round number. §2
7. ⇒ **NEXT: the refit.** Both arms, `h_ml` unbounded, smoke first. §4

---

## 1. THE 7 WERE MEASURED FIRST — AND TWO SKETCHES WERE WRONG

`calibration/diag_attribute_the_seven.R` (~6 min) measures each. Log committed at
`outputs/diag_attribute_the_seven_20260830.log`.

| test | the 08-30 sketch | what it MEASURES |
|---|---|---|
| `test-volcanic-diffuse.R` | asserts the OLD default | ✔ exactly that |
| `test-conveyor.R` ×3 | "volcanoes now drive NPP" | ✔ cause, ✘ mechanism — the **CMIP7 AOD record BEGINS in 1850**, so 99 of that test's 100 years are already silent. What trips it is the record's **TURN-ON STEP landing on the run's LAST year**, the one year an endpoint-minus-start gate reads. |
| `test-luc-permanence.R` | same cause | ✔, but **only the flatness PRECONDITION** breaks. The gate's three real assertions are pulse-minus-control DIFFERENCES and the volcanic signal cancels: af_foss 0.1506/0.1513, ratio 1.033/1.032, 150-yr 0.864/0.867. |
| `test-likelihood.R` | "re-guard AFTER the refit" | ✘ **IMPOSSIBLE.** `lik_fixture()` runs on `ccx_default_params()`, **not** the fitted mode — the refit does not touch it. b0 is **linear in γ** (2.418/2.718/**3.017** at 0/0.125/0.25) and was already at **81 % of its bar pre-adoption**. Curvature `A = 26.398` at all three — the half the test calls load-bearing is UNMOVED. |
| `test-mode-file.R` | "stored logpost changed, refresh provenance" | ✘ **The stored-logpost assertion PASSES.** The RECOMPUTED gap fails: **−11.4936 / −14.8961 / −19.8635** across the same γ. `PIN_PRIOR_CREDIT` is a PRIOR term with no γ dependence ⇒ the whole **+8.4 is a LIKELIHOOD differential** — diffuse light costs pin90 more than canonical. A finding, not bookkeeping. |

⚠ **The general lesson: "same harness ⇒ the objective cancels" holds for a COMMON SHIFT only.**
`gamma_diff` changes the MODEL, and two arms at different `fert_k` pay different amounts.

Consistency check that the harness is sound: the canonical arm's own frozen price across the
adoption is **−40.49**, which reproduces the recorded "the frozen column overstated by 82 %"
(7.42 / 0.18 = 41.2).

---

## 2. THE RULINGS (Marcus, 2026-08-30) — 6 RESOLVED, 1 DELIBERATELY NOT

1. **"QUIET" MEANS VOLCANICALLY QUIET.** `quiet_forcing()` and `lp_background()` zero `aod_*`
   themselves — which is what `R/forcing.R` already instructs, and the same shape as this suite's
   existing precedent of running the LUC control *seasonless* rather than loosening its gate.
   Conveyor **0.0246 → exactly 0.00000** ppm; LUC control **0.2322 → 0.0437** against 0.05.
   Both helpers carry a **mutation test at an EXPLICIT γ**, so the zeroing cannot go vacuous and
   the coverage does not move if the default moves.
   *Rejected:* loosening the tolerances (30× and 6×, and it confounds conveyor drift with volcanic
   response); making `ccx_hold_climate()` zero AOD (contradicts the 08-29 ruling that AOD is a
   radiative driver, and would silently disable diffuse light in every climate-held diagnostic).

2. **THE CO2 LEVEL BAR IS DERIVED** — `calibration/diag_co2_level_bar.R` (seconds). A uniform model
   shift is degenerate with a systematic level offset in the record, so the bar is that record's own
   level uncertainty: **`LIK_ICE_REP_ERR` = 4.0 ppm**. Validated against a fully external **FLOOR** —
   Law Dome vs **SPO** (like-for-like Antarctic; against MLO the comparison carries the real
   interhemispheric gradient and reads 1.6 ppm larger for no reason of record quality) over
   1962–1996, **RMS 1.087 ppm**, no model and no likelihood weight — showing the constant is
   **3.7× conservative**. Mutation-tested at 2× the bar.
   ⚠ **The floor is BLIND** to gas-age, firn smoothing and model-vs-ice representation (both records
   there are modern, precise and Antarctic), so it bounds FROM BELOW and is **not** the bar.
   ⚠ **Coupling named**: `LIK_ICE_REP_ERR` is inside the objective, but the dependence runs the wrong
   way to self-satisfy — inflating it DOWN-weights the ice and pulls b0 toward the MLO/SPO optimum.
   ⚠ **b0 = 3.017 is 75 % of the bar but 2.8× the floor.** That is a MODEL-QUALITY statement to
   re-read after the refit, not a passing grade.

3. **`test-mode-file.R` STAYS FAILING**, and the measurement is written into the file so it is not
   re-derived or mistaken for a regression. Re-measure `PIN_PRIOR_CREDIT` after the refit; deriving
   it now would bake in a number from vectors about to be replaced.

4. **`test-volcanic-diffuse.R`'s default contract INVERTED** (the 08-28 h_ml-gate precedent) and
   **re-aimed at the NAMED CONSTANT** rather than a bare literal, so it now breaks on a CONTRACT
   change instead of a VALUE change — and it pins **absence** in both cores.

---

## 3. ⚠ THE BUG THE RULINGS UNCOVERED — a THIRD silent one-core-only default

The 08-29k adoption stated it used the `CCX_FERT_FORM_DEFAULT` pattern "so R and C++ cannot disagree
about what a parameter list without the field MEANS". **Only `ccx_cpp_par()` got the constant.**
`ccx_deriv()` still hardcoded `if (is.null(p$gamma_diff)) 0`, so a list **WITHOUT** the field reached
the R reference as 0 and the C++ as 0.25 — an R↔C++ parity break of **0.647 GtC/yr** at the record's
loudest volcanic step, **9× larger than yesterday's out-of-bounds read**.
⚠ **`ccx_mode_params()` IS such a list** — the fitted 21 do not carry `gamma_diff`.

⚠ **THE ADOPTION'S OWN PARITY HARDENING COULD NOT CATCH IT, AND FOR A GOOD REASON.** It pins parity
at **EXPLICIT** γ = 0 / 0.25 / 0.97 — deliberately, so coverage would not move if the default moved —
and **an explicit value never exercises either fallback.** The dedicated contract test compared an
explicit default against an ABSENT field but ran both through `ccx_run_fast`, i.e. the C++ path
twice, so it agreed with itself.

⇒ **THE RULE, now `test-parity.R` item 5: A DEFAULT HAS TWO CONTRACTS — WHAT THE VALUE IS, AND WHAT
ABSENCE MEANS.** Pin both, in every core. Fixing the first without the second MOVED the blind spot
rather than closing it. Asserted at the **argmax of the driver column** so the gate cannot go vacuous
at a step where the mechanism is zero anyway. **Mutation-tested: re-introducing the split fails 2
assertions; the fix passes 57.** Memory: `default_off_hides_the_bug` (third instance appended).

⚠ **`ccx_forcing_at(F, i)` TAKES A ROW INDEX, NOT A YEAR.** Several parity tests call it as
`ccx_forcing_at(F, 1900)` and read like dates; row 1900 of 3300 monthly rows is 1908. Harmless where
both cores get the same row, but it silently hands a **tiny** AOD to anything meaning to land on a
volcano — it cost one iteration here.

---

## 4. THE NEXT STEP: THE REFIT (setup decided, smoke run)

**Marcus's setup calls, 2026-08-30:** **BOTH arms** (`from90` and `pin90`) — the pinned arm is what
re-measures `PIN_PRIOR_CREDIT` and closes the deliberately-failing test; **`h_ml` UNBOUNDED over
[30, 200]** — which is already the tracked driver's behavior since the 08-28 inversion, both of the
bound's original reasons now discharged (the σ-inflation adoption retired the skip, the C1 remap
removed the kinks); **SMOKE FIRST**.

**How the smoke was configured** (reproduce with):

    export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1
    export CCX_ARM_RESTARTS=1 CCX_ARM_CYCLES=1 CCX_ARM_MAXIT=60
    CCX_ARM_OUTDIR=<dir>/from90  Rscript <FROZEN copy of run_modefind_pump_arms.R>
    CCX_ARM_OUTDIR=<dir>/pin90 CCX_PIN_PARAMS="fert_k=90"  Rscript <same FROZEN copy>

⚠ **`CCX_ARM_MAXIT` IS THE ONE THAT MAKES A SMOKE CHEAP, AND I LEFT IT OUT FIRST.** Setting only
`RESTARTS`/`CYCLES` while `ARM_MAXIT` stayed at its production 20000 produced a run that was still
inside its FIRST Nelder-Mead restart at **23 minutes** and would have taken hours — the restart and
cycle counts multiply a cost that `MAXIT` sets. Killed and requeued on the recorded recipe from
`handoff_2026-08-28c` §4 (`RESTARTS=1 CYCLES=1 MAXIT=60`, **14.2 min** there). The lesson is the
existing one — read the meter early rather than wait — and the specific form worth keeping is that
**a "reduce the iteration count" knob set is only as cheap as the knob nobody reduced.**

⚠ **DO NOT READ PARAMETER VALUES OFF A `MAXIT=60` SMOKE.** `handoff_2026-08-28c` §3 makes this
point against its own smoke's alarming `h_ml` = 35.38 m. The smoke proves the pipeline runs
end-to-end and the gates fire; it does not locate a mode.

Each smoke dir was **seeded with a byte copy** of its incumbent (`refit_20260825f_from90` /
`_pin90`) so `ARM_WARM` exercises the real warm-start path. Driver run from a **FROZEN copy**.

**Startup gates all passed**: H1 (shipped support, prior NOT renormalized), H2 (init 75 round-trips),
H3 (rows LIVE at h_ml 31 / 75 / 199), and the pin round-trip (90 → 90, err 1.4e-14).

**Warm-start logposts** — and they are the expected drop, not a surprise:
`from90` **−1585.1** where its file says −1544.6; `pin90` **−1593.4** where its file says −1544.5.
The −40.5 on the free arm matches the frozen adoption price measured independently (§1).

**SMOKE RESULT — both arms exit 0, pipeline sound under the post-adoption objective:**

| arm | warm start | after one BFGS polish | gain |
|---|---|---|---|
| `from90` | −1585.1 | −1547.2 | **37.95** |
| `pin90`  | −1593.4 | −1556.1 | **37.30** |

The free arm recovering ~38 of the **40.49** the adoption cost the frozen vector, in ONE unconverged
polish, is the right order for the recorded CONDITIONAL price of diffuse light (−7.42, memory
`ccx_diffuse_light`). ⚠ Both arms drive `h_ml` to 35.25 / 36.99 and `kz` still rails (95.1 % / 97.7 %)
— **the SAME behavior `handoff_2026-08-28c` §3 ruled is not a finding**, and a MAXIT=60 artifact
until the converged run says otherwise.

**PRODUCTION RUN LAUNCHED** into `calibration/output/refit_20260830_gamma_diff_remap/{from90,pin90}`,
both arms in parallel, BLAS pinned to 1 thread each, frozen driver stored alongside, README carrying
full provenance (input md5s, commit `6639e3f`, the setup calls, and the smoke table). **It overwrites
nothing at a canonical path** — `ccx_mode_file()` still resolves to `refit_20260825f_*`, and
repointing it is a separate, later decision that must not be taken before a replacement exists
(`handoff_2026-08-28c` §4: quarantining the canonical mode before a replacement exists breaks
`ccx_mode_file()`, the app and every diagnostic).

⚠ **WHAT TO DO WHEN IT LANDS:** (1) check both `_run.log`s end with the comparison write and a
non-zero cycle count — a run that hit the restart cap while still gaining has NOT located the mode
(the 08-20r lesson baked into `ARM_WARM`); (2) re-measure `PIN_PRIOR_CREDIT` from the two new arms
and settle `test-mode-file.R`; (3) re-read `b0` against its derived bar (§2 ruling 2 — it sits at
2.8× the observational floor); (4) only then consider repointing `ccx_mode_file()`.

⚠ **THE OLD TEXT BELOW IS SUPERSEDED —** Production values are `CCX_ARM_RESTARTS=20`,
`CCX_ARM_CYCLES=6`, into a dated `calibration/output/refit_20260830_*/` directory with a provenance
README, per the `refit_20260828_sigma_eff` template (which also stores its frozen driver alongside).

---

## 5. ⚠ A GATE THAT CAN NO LONGER FAIL (found during the smoke, NOT fixed)

`run_modefind_pump_arms.R`'s kink scan prints **"0 kink(s) in [30, 200]"** — correct, the C1 remap
removed all 26 — and then fires

    *** the kink count has CHANGED since diag_hess_eps_21par.R -- re-run it

**every single run**, because the check is `if (length(ARM_KINKS) != 3)`. A message that always fires
is noise, not a signal, and it will be ignored within a session or two.

**The substantive half is real and is OWED**: `diag_hess_eps_21par.R` chose its Hessian step against
a KINKED objective. The remap made that objective C1 — memory `ccx_hessian_is_the_blocker` already
records that the "not even C1" half of the no-posterior story is DISCHARGED — so the step study
should be re-run against the C1 objective before any covariance off this refit is trusted.
**Left unmodified for a ruling**, same discipline as the 7.

---

## 6. NON-OBVIOUS STATE

- ⚠ `INDEX_ccx.md` is at **17.6 KB against an 18 KB hard ceiling.** The previous handoff predicted it
  would need another split "within a session or two"; it is now one session later and closer.
- ⚠ Everything from §7 of the previous handoff still stands unchanged — `ccx_hold_climate()` does not
  freeze `aod_*` (architecture, not oversight); **never add an AOD → temperature term**; AOD pre-1850
  is zero so Tambora is absent; `diag_landed_gap_streams.R` is still QUARANTINED and hard-stops;
  `refit_20260828_sigma_eff` is RATIFIED "do not adopt"; the pinned-96 successor is undecided and is
  NOT a config change; two diagnostic-only authorizations stand.
- The driver emits ~10 harmless `rm(): object not found` warnings on the UNPINNED arm (locals that
  only the pinned path creates). Cosmetic, pre-existing.
- Nothing was quarantined this session. Nothing at a canonical path was overwritten — the smoke wrote
  only to scratch.

## 7. COMMITS

    6639e3f  Rule on the 7 -- and fix a THIRD one-core-only default they uncovered
    58f434e  Measure all 7 failures -- and 2 of the 5 handoff sketches are wrong
