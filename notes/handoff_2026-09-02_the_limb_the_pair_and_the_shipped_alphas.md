# Handoff — CarbonCycleEmulator, 2026-09-02
# **THREE ARCS CLOSED. ONE MODEL CHANGE SHIPPED, AND IT CHANGED THE OBJECTIVE.**
# **NEXT SESSION: (1) CODE-REVIEW the ENSO split and the T-dependent alphas,**
# **THEN (2) REFIT. Marcus's instruction, in that order.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at **`6263bf6`**
plus one uncommitted follow-up (§6). ⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in
`CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Reads before this one:** `handoff_2026-09-01f_prior_screen_width_and_alpha.md` (what this session
was asked to do). Memory: **`INDEX_ccx_seas.md` first** — it was re-cut today and its LIVE STATE now
leads with the reversal below.
**Suite 1457 PASS / 6 FAIL / 2 skip** — the standing six (the `kz` bracket bound + the 21-vs-25
parameter-set failures that clear on refit). ⚠ It was **7** at the start of today; see §5.

---

## 0. STATE IN EIGHT LINES

1. ⛔ **09-01f §4 ANSWERED AND IT REVERSED.** The land PARAMETER closed; the land **LIMB** went
   1.92× → **2.55×** obs and the overshoot grew **+42 % → +62 %**. §1
2. ⭐ **The lever is `npp_frac_NH`, not `seas_T_amp_SH`** — +0.600 against −0.228, outvoted 2.6 : 1. §1
3. ⛔ **09-01f §5 ANSWERED: the T-dependence is NOT the explanation** — 9–16 % of the two
   `d13c_seasonal_*` rows' residual, pointing the wrong way. §2
4. ⭐ **But it found a REAL defect: the INVASION limb was 2.4× too large**, and Marcus's
   boiling-point anchor was vindicated (the `1/T` form was the error). §2
5. ✅ **SHIPPED: both air-sea ¹³C alphas are TEMPERATURE-DEPENDENT** (Zhang 1995), with GATE Q. §3
6. ⛔ **THAT CHANGED THE OBJECTIVE: −4.84 log-units, δ¹³C streams only. EVERY FITTED VECTOR
   PREDATES IT.** §3
7. ⭐ **¹⁴C needs NOTHING: it INHERITS the dependence**, being defined as α₁₃². §4
8. ⇒ **NEXT: code review (§6), then refit (§7).** Marcus's order.

---

## 1. ⛔ THE 2×2 RE-PRICED — AND THE LAND HALF DID NOT CLOSE (`3f7fd6f`)

`calibration/diag_2x2_repriced_at_enso25.R` on the new `calibration/lib_seas_limbs.R`.
Full detail: `notes/collect_2026-09-02_the_2x2_repriced_and_the_land_limb_got_worse.md`,
memory [[ccx_land_limb_worse_at_enso25]].

| | 27q INCUMBENT | 27q JOINT_hi | **enso25 A/B** | obs |
|---|---|---|---|---|
| SH-land limb | 1.312 (1.92×) | 0.861 (1.26×) | **1.743 (2.55×)** | 0.683 |
| SPO total / obs | 0.981 | 1.187 | **0.927** | 1.000 |
| required ocean / obs | 0.326 | 0.894 | **0.567** | 1.000 |
| ocean AT obs ⇒ total/obs | 1.582 | **1.424** | **1.621** | 1.000 |

⭐ **A PARAMETER INSIDE ITS BRACKET IS NOT THE OBSERVABLE INSIDE ITS BRACKET.** Both cluster
representatives agree to three decimals on every limb.
⛔ **Do NOT reach for `npp_frac_NH` as the fix**: matching the observed land limb by share alone needs
≈0.81, **outside its [0.4, 0.8] bounds**, and its own prior centre makes the limb worse — which is
[[sh_land_undercancels]] reproducing. The SIZE was already exonerated; the missing piece is CANCELLATION.
⚠ **These are PRE-alpha-change numbers** and the file says so; re-running reproduces every CO₂ number
exactly but moves the d¹³C ratios (`r_SPO` 2.063 → 2.172). `alpha_as_tdep` is now recorded in its output.

---

## 2. ⛔ `alpha_as_up` PRICED — REAL PHYSICS, NOT THE ANSWER (`7cfa030`, `d009ecd`)

`calibration/diag_alpha_as_up_precheck.R`. Memory [[alpha_as_up_priced_not_the_answer]].
Marcus supplied **`ClaudeDocs/Papers/zhangquaywilbur1995.pdf`** and the 2003 Quay GBC paper mid-session.

* ⛔ **The paper prints its own fit TWICE with different coefficients** — abstract (0.014, −0.105),
  conclusions (0.0144, −0.107) — **exactly one stated sigma apart**. Both are carried; nothing in the
  text prefers one.
* ⭐ **Marcus's boiling-point anchor is RIGHT; the `1/T` form was the error.** Measured +0.113 ‰/K
  (kinetic limb included); boiling+`1/T` +0.137 (+22 %), boiling+**LINEAR** +0.106 (−6 %); Zhang's fit
  crosses ε = 0 at **374.5 K, 1.4 K from boiling**, from data that knew nothing about the anchor.
* ⛔ **Not the explanation**: 9–16 % of the two rows' residual and moves both the wrong way ~5 %.
  ⚠ The phase is DERIVED; the SH sign is robust, the **NH is 0.51 mo from flipping**.

---

## 3. ✅ SHIPPED (`6263bf6`) — AND THE OBJECTIVE MOVED

Memory [[alpha_as_t_dependent_shipped]]. **ε_down = ε_k(T), ε_up = ε_k(T) − ε_DIC−g(T)**, applied at
the **LOCAL SEASONAL SST**, R and C++. Eleven constants registered. `alpha_as_tdep = 0` reproduces the
pre-09-02 model **BIT FOR BIT**.

* Invasion limb **−2.00 → −0.84**; evasion −10.00 → −9.50/−9.72.
* **GATE Q** (`calibration/lib_design_gates.R`, beside gates 4/5/7): Quay 2003's air-sea δ¹³C
  disequilibrium 0.60 ± 0.10 ‰ — **legacy 6.4σ FAIL → shipped 1.0σ PASS**, discrimination asserted
  as a test. ⛔ I built it self-referential first (it read the target off the model's own alphas and
  PASSED the retired pair); caught only because BOTH settings passed.
* ⛔ **OBJECTIVE: −4.84 log-units at the un-refitted mode, and ONLY δ¹³C streams move**
  (`d13c_level_MLO` **+7.77**, `d13c_seasonal_SPO` −4.73, `d13c_seasonal_MLO` −3.19,
  `d13c_level_SPO` −3.97). CO₂ untouched to machine precision — the correct signature.

---

## 4. ⭐ ¹⁴C INHERITS IT — DO NOT ADD A TERM

Marcus, 09-02: **the ¹⁴C fractionation is DEFINED by its relationship to the ¹³C one, so it inherits
the temperature dependence.** The model carries **Δ¹⁴C** and `add_flux` applies no fractionation to
it, which is exact precisely when **α₁₄ = α₁₃²** — so a T-dependent α₁₃ makes the assumed α₁₄
T-dependent with **no code and nothing to keep in sync**.
⛔ Adding a ¹⁴C term would DOUBLE-COUNT by ~17 ‰, ≈3× `sigma_d14c`. The residual from the square law
being ~1.9 not 2 on the kinetic limb is **~0.001 ‰/K** — three orders below the noise floor.
Recorded at `add_flux`, whose comment used to say "NO fractionation -- see header" while the header
did not say.

---

## 5. ⚠ THE SUITE WAS AT SEVEN, NOT SIX

`handoff_2026-09-01f` opens "1365 / 6 FAIL / 2 skip, the same six, unchanged". Measured, it was
**1364 / 7**: `900f90b` shipped `diag_prior_screen_enso25.R` with the `from90` ancestor as a **path
literal**, failing `test-mode-file.R:71`'s hardcoded-path lint since it landed. Fixed
(`ccx_mode_file("from90")`, same file). **The count had been quoted rather than read.**

---

## 6. ⇒ NEXT SESSION, STEP 1: THE CODE REVIEW (Marcus's instruction)

⚠ **There is ONE UNCOMMITTED CHANGE to review and commit first**: `alpha_as_tdep` is now declared in
`ccx_default_params()`. It shipped as a `p$alpha_as_tdep` read inside `ccx_prepare()` only, so a
**misspelled switch** (`alpha_as_tdp <- 0`) would have been absent, defaulted to 1, and run the WRONG
MODEL while printing numbers. Found by auditing my own change, not by a failure. **Re-run the suite
before committing it.**

**⛔ THE TWO MECHANISMS TO REVIEW, AND WHY EACH IS RISKY.**

**(a) The ENSO split** (`71155ad`, `53ef03d`, 09-01 — NOT reviewed by anyone since).
* `ccx_gamma_enso()` HARD-ERRORS on a list carrying both names; `ccx_migrate_par_set()` is the
  migration contract. ⚠ Check every call site actually goes through one of them —
  [[split_name_must_hard_error]] records ~110 lines that once ran with a mechanism OFF.
* ⚠ **`ccx_seas_lag_p()` still uses a PRECEDENCE rule (split wins) where `ccx_gamma_enso()` uses a
  hard error.** Two split contracts, two behaviours, one repo. Worth ruling on.
* ⚠ The fitted coefficients are **strongly ANTIsymmetric** — ocean −0.950 (NH) / +1.187 (SH) — where
  both seeds assumed symmetric. Nobody has asked whether that is physical.
* ⚠ The four sit at **|z| ≤ 0.68** and moved nothing in the prior screen; the ENSO limb contributes
  only **0.003–0.006 ppm** to the SPO seasonal harmonic. Is the mechanism earning its parameters?
* ⛔ **I changed the ENSO ocean limbs today** (they now take `a_as$down`/`a_as$up`). Check the
  per-direction sign logic survived: `ge_ocn > 0` must be UPTAKE carrying the invasion alpha.

**(b) The temperature-dependent alphas** (`6263bf6`, today).
* **R ↔ C++**: `ccx_alpha_as()` exists in both (`R/model.R`, `src/ccx_core.cpp:114`). Same formula,
  same units, same legacy branch.
* **Marshalling — audit it FIELD BY FIELD, and mind the trap.** ⚠ I ran this audit twice and got a
  false "uninitialised memory" both times, once from `tr -d 'a["]'` eating every letter `a` and once
  from a character class `[a-zA-Z_]` that excluded the digit in `fco3`. The correct form:
  ```
  grep -o 'a\["alpha_as_[A-Za-z0-9_]*"\]' src/ccx_core.cpp | sed 's/^a\["//; s/"\]$//' | sort -u
  ```
  compared against `grep("^alpha_as_", names(ccx_cpp_aux(...)))`. **Verified clean both ways today**
  — but the C++ reads every field into a fixed struct, so a field the R side stops sending is
  whatever was in that memory before.
* **The four application sites**: gross invasion/evasion, the two ENSO ocean limbs, the prescribed
  sink. ⚠ Confirm `sst` at each is the **SEASONAL** one, not `aux$sst` — that is the mechanism.
* ⚠ **GATE Q uses `aux$sst[[h]]` (the box MEAN), while the deriv uses the seasonal SST.** Deliberate
  for an annual gate, but it is an inconsistency a reviewer should rule on rather than discover.
* **The spinup** must see the pair (it does — `ccx_spinup` calls `ccx_prepare`), or the run starts at
  the wrong preindustrial isotopic equilibrium.
* ⚠ **`fCO3` is HELD, not solved** (`ALPHA_AS_FCO3` = 0.082, provisional). Priced at 0.020 ‰ of an
  ~8.7 ‰ offset and 1 % of the slope. Confirm you accept that before the refit bakes it in.
* **Three tests were re-pointed today**, none loosened: `test-artificial-sink.R`,
  `test-enso-split.R`, `test-constants.R`'s provisional ledger. Each asserts the retired value now
  FAILS. ⚠ The sink test needed `seas_drivers = 0` so the box SST is exactly `aux$sst`.

**Suggested method:** this is a >5-file read — spawn an Explore/general-purpose subagent per
`~/.claude/CLAUDE.md`'s context-hygiene rule rather than reading it all into the main window.

---

## 7. ⇒ NEXT SESSION, STEP 2: THE REFIT

⛔ **Only after the review.** Every fitted vector predates the objective change.

* **What it is**: the 25-parameter set, arm N, from the 09-01 survey's basin. The survey established
  **ONE basin at 25 parameters, −1495.795, all ten starts** ([[ccx_one_basin_at_25_par]]), so a
  dispersed multi-start is probably NOT needed again — a polish from `start_000.rds` / `start_005.rds`
  may be enough. ⚠ That is a judgement to make explicitly, not to assume.
* **Cost**: the 09-01 survey ran **151 min per start** on Torch (job 16732800). ⭐ **Say the Torch
  verdict out loud before launching anything locally** ([[consider_torch_first]]); submission is
  Marcus's call.
* **Torch traps that already cost a session**: [[sourced_rc_clobbers_your_name]] (fixed in
  `multistart.sbatch`, `CCX_PROJ_DIR` + `readonly` + asserted outdir),
  [[torch_rscript_e_eats_dollar]] (run R from a FILE), [[torch_qos_is_the_real_cap]] (`cpu_short` =
  6 h / cpu=32), [[pymagicc_temp_dir_leak]].
* **Expected direction**: the change costs **−4.84** at the un-refitted mode, of which
  `d13c_level_MLO` is **+7.77** — so the fit has a real trade to make and the streams disagree.
  ⚠ **Do not predict the sign of the refit's move from that.**
* **Acceptance**: GATE Q must still PASS (it is not scored, so the fit cannot chase it), the DESIGN
  gates re-priced in the new basin, and the prior screen re-run — `diag_prior_screen_enso25.R`
  points at paths, so it will need the new mode's path.
* ⛔ **Quarantine on adoption**: when the refit lands, the pre-09-02 vectors go to
  `calibration/output/quarantine/20260902_alpha_as_tdep/` with a README naming the cause, per
  `~/.claude/CLAUDE.md`. `CCX_MODE_RETIRED` in `R/paths.R` is the registry for the reason string.

---

## 8. ⚠ NON-OBVIOUS STATE

* **`CCX_MODE_CANONICAL` is STILL `from90`, a 21-parameter vector**, and 5 of the 6 standing suite
  failures are that mismatch. It is not repointed because there is no adopted 25-parameter mode yet.
* `alpha_as_tdep` **defaults ON**, so the LEGACY path is now the untested one; `test-alpha-as.R`
  asserts both. If you would rather ship it off until the refit lands, that is one line.
* `calibration/lib_seas_limbs.R` is new and **`diag_admissible_2x2_land_ocean.R` deliberately does
  NOT use it** — that file is a pre-registered artefact whose gates may not move under a refactor.
  GATE R re-scoring its stored arms is what binds them.
* **Memory consolidated**; snapshot `../memory_backup_20260902/`. `INDEX_ccx_seas.md` had breached its
  HARD ceiling (17.6 KB) — the closed 08-27 sub-arc moved to `INDEX_ccx_arch.md`, now 11.6 KB.
  ⚠ **Measure CONTENT, not the file**: `MEMORY.md` is 29 % comment and was compliant all along. I
  nearly repeated the mistake its own footer records.
* **Still owed, unrelated to the above**: the four observed SPO constants (total 1.168 / land 0.683 /
  ocean 0.522 / phase 8.52) are **not in `R/constants.R`** and are replicated across ~10 diagnostics.

---

## 9. WHAT LANDED

`3f7fd6f` the 2×2 re-pricing + `lib_seas_limbs.R`; `7cfa030` the `alpha_as_up` pricing;
`d009ecd` the primary-source pass (both printings, the kinetic limb, §5a, GATE Q's first form);
`b70c901` the adoption test; **`6263bf6` the shipped change**. Plus one uncommitted follow-up (§6).

**Memory:** [[ccx_land_limb_worse_at_enso25]], [[alpha_as_up_priced_not_the_answer]],
[[alpha_as_t_dependent_shipped]] (all new); `INDEX_ccx_seas.md` re-cut, `INDEX_ccx_arch.md` extended,
root `MEMORY.md` carries the objective-change banner.

**Three errors of mine this session, all caught by output contradicting an expectation rather than by
review:** GATE Q built self-referentially; the §4 diagnostic's stored ratios nearly drifting under my
own change (a 3-byte file difference); and the marshalling audit's two false positives. ⚠ The pattern
is that **the checks I wrote were wrong more often than the code was** — weigh that when reviewing §6.
