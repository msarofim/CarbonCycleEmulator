# Handoff — 2026-09-09s. **Round 6 (the seasonal mixed layer, option A) IS BUILT IN BOTH CORES, parity holds, suite 2381 / 3 / 4. ⛔ THE NEXT SESSION DOES A FULL CODE REVIEW FIRST (Marcus) — bugs, and anything inconsistent with physical understanding or PEDAGOGICAL usefulness. THE REFIT COMES ONLY AFTER THE CODE IS JUDGED CLEAN.**

Read first: **CHANGELOG 09-09g → 09-09r** (ten entries, this session), then
`notes/prereg_2026-09-09g_round6_seasonal_ml.md` (P1–P12, the live prediction list),
`notes/options_2026-09-09l_p1_yardstick.md` and `notes/options_2026-09-09p_p1c_rulings.md` (the two
rulings and their reasoning).
Memory: [[ccx_seasonal_h_ml_option]] (the whole arc, now long — read it end to end),
`INDEX_ccx_seas.md`, [[ccx_pedagogical_not_emulator]] (the standard the review must apply),
[[runnable_is_not_encodable]], [[amp_definition_mismatch]], [[verify_the_quantity_not_the_word]].

---

## 0. ⛔ THE INSTRUCTION FOR THE NEXT SESSION, IN ORDER
1. **FULL CODE REVIEW FIRST** (§5). Not a diff review of this session — **the whole model**, against
   two standards: (a) correctness, and (b) **is every element physically defensible and
   PEDAGOGICALLY useful?** CCX is a teaching model, not an emulator
   ([[ccx_pedagogical_not_emulator]]) — a term that is merely fitted and unexplainable is a defect
   here even when it improves the likelihood.
2. **Only when the code is judged clean: THE REFIT** (§4). It is a 30-parameter Torch array, not a
   laptop job, and §4 states exactly what it must achieve.
3. ⛔ **Nothing is adopted in between.** `hilda31` remains canonical; `seas_ml` remains DEFAULT 0.

---

## 1. STATE OF THE TREE
- **`main`, 10 commits this session**, `8916e16` at the tip, **tree clean, NOT pushed** (there is no
  remote — this repo is local only).
- **Suite: 2381 pass / 3 fail / 4 skip.** The three are the **pre-existing** set:
  `test-alpha-as.R:116,117` (gate Q, deliberate) and `test-seas-lag-split.R:199` (error). ⚠ **They
  were failing before this session and are unrelated to it.**
- **Canonical unchanged: `hilda31`** (31 par, struct hilda, logpost −1478.66). **No stored logpost
  moved this session.** ⭐ Every change is either gate-side, diagnostic-side, or behind
  `seas_ml = 0`.
- **`seas_ml` DEFAULT 0**, at which the derivative is **bit-identical** to the pre-round-6 model —
  asserted with `expect_identical` against a parameter list that lacks the field entirely.

## 2. WHAT WAS BUILT
**The seasonal mixed layer (option A), in BOTH cores.** `h_ml(t)` is the Holte MLD climatology scaled
so its **annual mean is exactly the fitted `h_ml`** (Marcus's mean-preserving ruling), and the mixed
layer **entrains real water** — carbon and both isotopes — from layer 1.
- `R/model.R`: `ccx_mld_fourier` / `ccx_mld_eval` / `ccx_mld_shape` / `ccx_grid_at_h_ml` /
  `ccx_seas_ml_on` / `ccx_seas_ml_guard`; the per-hemisphere local geometry in `ccx_deriv`; the two
  entrainment limbs; the substep bound; and a `record = TRUE` stash of `pco2_ml` / `sst_ml`.
- `src/ccx_core.cpp`: `mld_eval()`, the local `dzl`/`dzml`/`ml_mass`, the two limbs, `Aux.seas_ml`
  plus the Fourier harmonics (zero-filled when off).
- `R/cpp.R`: the marshalling; **the STOP guard is GONE** now that parity covers the mechanism.
- `tests/testthat/test-seas-ml.R` (new, ~90 assertions) and three new blocks in `test-parity.R`.

**Design facts worth not re-deriving:**
- ⭐ **The interior grid does NOT move.** Only the ML/layer-1 boundary does; layer 1 absorbs the whole
  excursion, so `dz_ML + dz_1` is conserved, `dz_mid[1]` is invariant, and `kz_int` stays at its
  annual-mean values.
- ⭐ **No periodic spinup is needed** — confirmed twice, by construction (`R/spinup.R:227` sets
  `seas_drivers <- 0`, and the C++ guard's first firing proved the spinup runs through that path) and
  by measurement (P10: the quiet-window rectification is settled).
- ⭐ **`alpha13 = 1` on the entrainment limbs is the point**: entrainment is transport, so `add_flux`
  carries ¹³C **and** Δ¹⁴C from the source box for free. ⛔ Adding a ¹⁴C fractionation would
  double-count ~17 ‰ ≈ 3× `sigma_d14c`.

## 3. WHAT THE MEASUREMENTS SAY (all committed, all reproducible)
| check | result |
|---|---|
| **P1** (retired band, reported only) | NH 10.23, SH 9.79 µmol/kg |
| **P1a** below the undamped moving-boundary bound (a LAW) | ✅ 0.72 / 0.65 of bound |
| **P1b** anomaly peaks at `h_max` (a LAW) | ✅ NH mo 2, SH mo 8, exact |
| **P9** substep convergence | ✅ 0.38 % over 4 → 16 substeps |
| **P10** rectification settles (quiet window) | ✅ 3.84 / 3.07 % per century; ⚠ NH margin THIN |
| **P11** C++ parity at `seas_ml = 1` | ✅ co2 6.4e-15 |
| **P12** compensator becomes redundant | ✅ argmax `ent` **21 → 8**, G **715.5 → 116.6** (0.163) |
| **P1c** ΔpCO₂ vs observation | ⛔ see below |

⭐⭐ **THE TWO RESULTS THAT SHOULD DRIVE THE NEXT SESSION'S THINKING:**
1. **P12's stream split.** The retired shim is a **genuine seasonal-SPO compensator** (99.4 % of its
   +715 is `co2_seasonal_SPO` alone), and **the mechanism buys +518 on that same stream — 73 % of
   what the FITTED shim buys — with NO fitted amplitude.** It **pays −514 on the two CO₂ LEVEL rows**,
   which is the whole of its net −48.7. ⇒ **it is NOT failing at the seasonal cycle; it succeeds there
   and pays on the LEVEL**, which is the most refittable kind of error.
2. **P1c's ΔpCO₂ comparison.** SH air-sea ΔpCO₂: model **40.76 µatm @ month 6.83** (`seas_ml` 0:
   20.57) against **OBS A1 (0–90 °S) 4.47 @ 1.61** and **OBS A2 (40–90 °S) 15.46 @ 7.39**.
   ⇒ against A1 the model is **9.11×** and **5.22 months** out; against A2 only **0.57 months** out.
   **The LOW-latitude box (84 % of SH ocean) is carrying the HIGH-latitude regime**, because its MLD
   driver is an SH-wide mean dominated by high-latitude winter mixing. ⛔ **A box-structure statement,
   NOT a falsification of entrainment** — which is why A1 was run as a COMPARISON with no verdict.
   ⛔⛔ **AND THE MODEL OVER-SWINGS AGAINST BOTH BANDS**: 1.33× at `seas_ml` 0, **2.64×** with it on.
   The unrefitted canonical carries the fitted solubility compensator **and** the mechanism, and they
   **ADD** — P12's "one mechanism, not two" in an observable.

## 4. THE REFIT, WHEN THE CODE IS CLEAN
**31 → 30 parameters** (`ent_seas_amp_SH` retires; P12 supports it). ⇒ **comparable on LIKELIHOOD
only**, never on a logpost.
⭐ **The target is now specific, which it was not before today: cut the SH ΔpCO₂ amplitude ~2.6×
against A2 by relaxing the fitted solubility amplitude (`sst_seas_amp_SH`, and `sst_seas_amp_NH`,
whose prior-z −2.96 is P2's load-bearing prediction), WITHOUT giving back P12's +518 on
`co2_seasonal_SPO`, and recovering the −514 on the CO₂ LEVEL rows.**
- ⭐ **Say the Torch verdict out loud** ([[consider_torch_first]]): a 30-parameter multistart is a
  **Torch array, not a laptop job** — 24 starts, one wave, ~2.5 h on the 09-08e recipe. **Re-time one
  evaluation first**: the spinup is unchanged, so the cost should be near-flat, but the transient
  gains two limbs and a higher substep count.
- ⛔ **P8 is an ENFORCED GATE**: if the refit pushes `h_ml` past **76.1 m** the winter ML punches
  layer 1 and `ccx_seas_ml_guard()` STOPS. `ent26` sat at **134 m**, so this is reachable.
- ⛔ **NEVER re-ship the bundle mid-array** ([[never_reship_mid_array]]); port targets committed at
  the launch commit; preflight 8/8.

## 5. ⛔ THE CODE REVIEW — WHERE I WOULD LOOK, AND WHY
**This session found FOUR defects, three of them mine, and every one was in the same family: a
quantity that was plausible-looking but was not the quantity intended.** That is the review's best
prior.

**5a. Places this session already proved fragile — re-audit them, do not assume they are now right.**
- ⛔ **`ccx_substeps_for()`.** I changed it twice. The first version looked at the **wrong extreme**
  (the thin summer ML, which does not bind) and returned 4 substeps where ~19 were needed, silently
  under-resolving the integration in BOTH cores. **Now it takes the max over both extremes — check
  that reasoning independently.** ⚠ And note `CCX_SUBSTEPS_MIN = 4` is a floor that can MASK a
  rising requirement.
- ⛔ **`ccx_seas_ml_guard()` (P8).** Its bound is "the winter ML must stay inside layer 1". That is
  **necessary and NOT sufficient** — at `h_ml` 75 it does not fire while layer 1 is squeezed to
  **0.798 m, 1.5 % of its mean**. It is currently made safe only by the substep fix. **Ask whether
  the guard itself should carry a residual-thickness requirement rather than relying on the
  integrator to cope.**
- ⚠ **The `record = TRUE` stash of `pco2_ml`** (`R/model.R`). New, opt-in, C++ has no twin for it.
  Confirm it cannot be read from the ASEASONAL spinup state by mistake — that path gives 138 µatm
  instead of ~280 and looks like a physics result.
- ⚠ **`.ENT_SO_SST_AMP = 3.0 K`** — its per-cell-vs-area-mean convention **is not stated** in
  `constants.R`, and its partner `.ENT_SO_PCO2_AMP = 19.45` was proved this session to be the
  **phase-blind per-cell** reduction where a well-mixed box requires the **area-mean harmonic**
  (16.26). **Establish the SST leg's convention; do not fix one leg of a two-leg sum alone.**

**5b. The pedagogical standard, which is the part a bug hunt will miss.**
- ⭐ **The headline question the review should carry: does `ent_seas_amp_SH` still deserve to exist?**
  P12 says its marginal value collapses 715 → 117 with the mechanism on. It is a **fitted compensator
  with no physical link to mixed-layer depth**, which is precisely the kind of term a teaching model
  should not need. Retiring it is supported — **confirm that from the code, not from P12's number.**
- ⚠ **`sst_seas_amp_NH/SH` are doing compensator work too.** P1c shows the model over-swings by 1.33×
  *before* the mechanism is on. Ask what these parameters are physically, and whether their fitted
  values are defensible as SST amplitudes at all.
- ⚠ **The `ml` box's identity.** P1c's central finding is that a **low-latitude** box is being driven
  by an **SH-wide** MLD climatology. **Is `ml` low-latitude, hemispheric, or undefined?** The answer
  is not clearly written anywhere, and three separate rulings now depend on it.
- ⚠ **`h_hs = 401.1 m`** — a "high-latitude SURFACE" box four hundred metres thick. Defensible as a
  HILDA water mass; **hard to teach**. Worth an explicit look.
- ⚠ **`ALK` is a single constant** and `.ENT_DIC_SURF = 2150` is **uncited and ~5.6 % above** the
  GLODAP surface value gate G scores against (~2035) — flagged in `constants.R` and never resolved.

**5c. Generic sweeps worth running.**
- Every **default-off** mechanism: is it exercised anywhere at an explicit non-zero value?
  ([[default_off_hides_the_bug]]). `tau_ex_seas_amp` is one such, deliberately unfitted.
- Every **gate**: is it mutation-tested? ([[mutation_test_gates]]) — break what it guards and confirm
  it fails. The ledger is `INDEX_ccx_gates.md`.
- Every **"derived"** constant: is it COMPUTED or a typed copy? ([[derived_must_mean_computed]] —
  this exact bug moved 30 → 29.68 once already.)
- Any place two numbers claim to be the same quantity. **That is how the 19.45/16.26 split was
  found**, and it had been sitting in `constants.R` unremarked.

## 6. NON-OBVIOUS STATE
- **`seas_ml` is not in `CCX_PARAM_TABLE`** — it is a plain switch in `ccx_default_params()`, not a
  fitted parameter. It must NOT be freed.
- **`ent_seas_amp_SH` is `tr = "log"`**, so **0 is unrepresentable in the encoder and has prior
  probability zero**. ⭐ **But 0 IS representable in the MODEL** (the shim is skipped at exactly 0),
  which is why P12 is a **likelihood profile** and not a refit — a refit cannot reach the off state.
- **The pre-existing 3 test failures are NOT this session's** and were not investigated.
- **`INDEX_ccx_seas.md` was SPLIT this session** → `INDEX_ccx_seas_mech.md` (live arc state vs
  standing mechanics), registered in `CLAUDE.md`, straddlers named in both. `_seas` is now ~14.9 KB
  of content — **over the 14 KB soft target again after this session's additions**; it will need
  another split or a move to `INDEX_ccx_arch` once round 6 closes.
- ⛔ **Three obsolete pre-checks were ANNOTATED, NOT DELETED**, in `notes/options_2026-09-08d…` and
  `notes/handoff_2026-09-08j…` — including a **stale INSTRUCTION to build option B**, which is the
  dangerous class. Both files now carry status headers. **Do not act on their bodies.**
- **A `pgrep -f` wait-loop matches itself** — two of mine spun for an hour this session. Promoted to
  `~/.claude/CLAUDE.md` execution hygiene at Marcus's instruction; wait on the PID.

## 7. ⛔ WHAT I WOULD NOT DO NEXT
- **Do not refit before the review.** Marcus's instruction, and P1c gave the refit a specific target
  that a code defect could silently redefine.
- **Do not adopt option A on current evidence.** Unrefitted it is **647.7 log-units** worse at each
  arm's own optimum, and P1c says it doubles an already-too-large ΔpCO₂ cycle.
- **Do not turn P1c's A1 comparison into a gate.** It was ruled a comparison precisely because its
  expected failure is a structural statement, and a gate is the wrong instrument for that.
- **Do not "fix" the C14 conservation assertion in `test-seas-ml.R`** by adding ¹⁴C back — total ¹⁴C
  decays; the omission is measured and deliberate (1.2e-4 at `seas_ml` 0 vs 5.3e-5 at 1).
