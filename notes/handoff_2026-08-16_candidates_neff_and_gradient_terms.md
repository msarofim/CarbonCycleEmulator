# Handoff — CarbonCycleEmulator, 2026-08-16: the ocean candidates are scored, `n_eff` is measured, and Marcus has put the DIC and δ¹³C gradient terms INTO the next round

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`, still
**not merged**, working tree clean at **`8f78095`**. Suite **4 failing**, unchanged all session,
none flagged for Marcus.

**Supersedes `handoff_2026-08-15d_dic_gradient_and_candidate_list.md`** for the candidate list
and the ordering. 15d's pump result stands unchanged.

---

## 0. START HERE

1. **MARCUS' NEW DECISION, and it is the reason for the next round's shape: the DIC and δ¹³C
   gradient terms GO INTO THE OBJECTIVE.** §4 is the whole design, including the two traps.
2. **Their parameter leverage is EXACTLY ZERO — measured, machine precision, all 19.** So they
   add a **constant ~384 log-units** and cannot bias the current posterior. §4.2. That is a
   clean property and it should be gated with a test, not assumed to persist.
3. **Which forces an ordering conclusion: add the terms AND build the pump in the SAME round.**
   Terms-first is harmless but useless; pump-first means the pump gets fitted against an
   objective that cannot see it. §4.5.
4. **Candidate B1 (outcrop) is DEAD.** Every configuration moves deep Δ¹⁴C the wrong way. Do
   not re-propose it. §2.
5. **Candidate A (`K_z(z)`) works on its own row and only its own row** — deep Δ¹⁴C z +1.70 →
   −0.17 at matched sink for +0.9 logL and one parameter, but `h_ml` does not budge. §2.
6. **`LIK_D14C_DEEP_NEFF` = 20 is now MEASURED-CONSISTENT, not asserted**, and it has quietly
   become load-bearing on a structural decision. §3.
7. **My error rate this session was high and the gates are what caught it.** §7. Weight the
   tables over the prose, including the prose in this note.

---

## 1. What was built

| file | what | runtime |
|---|---|---|
| `calibration/diag_dic_gradient.R` | the pump, zero fitted parameters (15d) | ~15 min |
| `calibration/diag_ocean_candidates.R` | candidates A and B1 on the same five rows | ~40 min |
| `calibration/diag_deep_d14c_neff.R` | `n_eff` measured seven ways | ~1 min |
| `calibration/diag_deep_d14c_sigma_choice.R` | point σ vs marginalized σ | <5 s |

**DESIGN.md §3.4a** is the canonical candidate list and carries every measured result.
**No model file was changed** except `R/likelihood.R`'s comment block for
`LIK_D14C_DEEP_NEFF` (documentation only, no behavior change).

---

## 2. The candidates, scored on one fixed row set

| candidate | clause 1 `h_ml` | clause 2 sink | clause 3 deep Δ¹⁴C | rows 4–5 DIC/δ¹³C |
|---|---|---|---|---|
| **A** `K_z(z)` | **fails** (184 m) | matched by construction | **z +1.70 → −0.17**, +0.9 logL | cannot, ever |
| **B1** outcrop | fails | rises | **fails**, +1.70 → +2.26 | cannot, ever |
| **C** pump | **184 → 100 m** | 3.052 | +1.70 → +1.08 | **only candidate** |

**A's form:** `K(z) = kz·exp(−(z − h_ml)/z_K)`, anchored `f` = 1 at the ML base so `kz` keeps a
NATRE-comparable meaning. Best at `z_K` = 5000, `kz` = 6404 — a very gentle decay, K falling
only to 0.61·`kz` at the bottom.

**Compare ISO-SINK or not at all.** The incumbent sits at its own fitted `kz` = 6119.2 and a
grid challenger does not; the *same constant-K model* at `kz` = 5000 scores **309 log-units
worse**. A first pass on a coarse grid produced two "findings" that were both artifacts of
exactly that. Solve `kz` per `z_K` to carry the incumbent's sink, then read the row you care
about.

**B1 closes a general statement, which is worth more than the candidate.** `kz`, `w_up`
(CHANGELOG 2026-08-13) and `w_out` all buy ocean sink by moving surface water down, and all
three pay the same deep-Δ¹⁴C bill. **The model does not have an uptake problem it can solve by
ventilating harder** — it already over-ventilates the abyss. The escapes are changing
ventilation's *depth distribution* (A) or adding an *interior source* (C).

**The conservation result, which is a proof and not a measurement.** DIC and ¹³C are conserved
with no interior source, so *any* steady state of *any* transport operator has a uniform
interior ratio; ¹⁴C differs only because decay is an interior sink. Measured: A and B1 move the
DIC gradient by **0.00e+00** µmol/kg and δ¹³C by **2.2e-13** ‰. **Ocean circulation explains
the age of the deep ocean; only biology explains why it is carbon-rich.** That sentence is a
v1 app claim, not a v2 backlog item.

**Your B2 gate ran and did not fire.** A single diffusive column reaches |z| = 0.17, so the
argument that would have *forced* HILDA is measured false. B2 is not excluded — clause 1 is
unmet by everything except the pump — but it is not earned.

---

## 3. `n_eff` measured, and what it now costs

Correlogram: ρ < 0.5 by **~5,500 km**, ρ < 0 by **~9,000 km**, −0.37 beyond 15,000 km.

**Admissible set** (the judgment call, written down): **6.4** (correlogram, ρ floored),
**11.9** (60° blocks), **26.0** (30° blocks), **110.1** (correlogram, empirical ρ). Excluded
with reasons: Kish 3408 (assumes an independence the correlogram refutes), 10°/20° blocks
(block ≪ decorrelation scale, biased high).

median **18.9**, geometric mean **21.6**, incumbent **20** — all within **8 %**. `n_eff` known
to a factor of **3.4**; σ to a factor of **1.85**.

**The value did not move.** 20 → 19 buys a 2.7 % σ change and costs comparability with every
logL in the repo. The defect was provenance; the receipt fixes it.

**But the constant has changed job.** It was chosen for a 62.6 ‰ question where four of five
candidates agreed. It now arbitrates a structural decision: **candidate A flips at σ > 16.3 ‰,
and the conservative end of the measured range is 18.15 ‰.** Representation error, still zero,
adds in quadrature and pushes exactly that way.

**Marginalizing was measured and I was wrong about it.** ν = 2.12 from the measured spread.
It changes *neither* decision — still holds `kz` (4.67 against a 4.50 threshold), still adopts
A (+0.82). What it costs is margin: the runaway penalty falls **4.3×**, from a 4× margin to a
4 % one, so under it this term **could never replace the `kz` bracket.** The trade is *honest
error model* vs *retiring the bracket*.

---

## 4. THE NEXT ROUND — the DIC and δ¹³C gradient terms (Marcus, 2026-08-16)

### 4.1 Why this is the right call

Two of the five discriminating rows were **not in the objective**, and they are the two only a
pump can move. That meant the refit could never arbitrate the pump *no matter how long it ran*,
and the pump diagnostic had **zero fitted parameters** precisely because there was nothing to
fit them against. **These terms are what make a fittable pump possible at all.** This is also
the sanctioned direction: the architecture review's rule is add missing constraints, do not
reweight existing ones.

### 4.2 Their leverage on the current 19 parameters is EXACTLY ZERO

Measured: perturb each of `beta_max, fert_k, q10, k_w, h_ml, kz, tau_ex, npp_frac_NH,
seas_amp_*, gamma_enso, sst_scale` by 10 % and the deep-box DIC and δ¹³C move by
**≤ 5.3e-12**, i.e. machine noise. Baseline deep DIC **1996.2555 µmol/kg**, deep δ¹³C
**1.55953 ‰**, both parameter-independent — the ML value is set by carbonate equilibrium at
fixed `ALK_SURFACE` and SST, and the interior is uniform by conservation.

**Consequences, all of which follow from that one fact:**

- The terms add a **pure constant**, so **no posterior distortion and no parameter hijacking.**
  (The hazard they *would* have posed is a term with a −23σ miss and *weak* leverage on some
  parameter, which would then hijack it for reasons unrelated to its meaning. Measured absent.)
- **logL becomes incomparable with every prior run** by ~384 units. Expected, not a bug.
- **GATE THIS.** Zero leverage is a property of the *current* structure, and the pump breaks it
  on purpose. Add a test asserting it holds with the pump off, so the day it stops being true
  is visible.

At n_eff = 20: deep DIC z **−23.0** (penalty 264), deep δ¹³C z **+15.5** (penalty 120),
**total constant ≈ 384 log-units**.

### 4.3 LEVELS or GRADIENTS — and they differ for δ¹³C

Marcus said "gradient terms" and that is right, but for a reason worth recording:

- **DIC:** the model's surface is *correct* — 1986.3 µmol/kg against a GLODAP 0–75 m mean of
  2028.9 **modern**, ≈1979 preindustrial. So a level term and a gradient term are numerically
  near-identical (~7 µmol/kg apart). Either works.
- **δ¹³C:** the model's uniform ocean value is **+1.560 ‰**, and a preindustrial surface
  observation is nearer **+2.0 ‰**. So the model's ocean δ¹³C *level* is off by ~0.4 ‰ for
  reasons that have nothing to do with the pump — air–sea fractionation constants and the
  preindustrial atmospheric value. **A level term would conflate that with the pump signal; a
  gradient term is immune to it.** Use the gradient for δ¹³C. This is the substantive argument
  for Marcus' phrasing, not just deference to it.

### 4.4 THE TRAP: the observed surface is anthropogenically contaminated, both fields

The model's preindustrial gradient must be scored against a *preindustrial* observed gradient,
and GLODAP's surface is modern:

| | observed modern gradient | contamination in the surface |
|---|---|---|
| DIC | **+244.7** µmol/kg | ~+50 µmol/kg anthropogenic ⇒ true gradient LARGER |
| δ¹³C | **−0.938 ‰** | Suess-depleted ⇒ true gradient LARGER in magnitude |

**Using the raw modern gradient is a LOWER BOUND on both, and it biases against the pump.**
Three options, none resolved here:

1. Raw modern gradient, documented as a lower bound. Cheapest; understates the pump's target.
2. Correct the surface for anthropogenic carbon and Suess. **`data-raw/downloads/eide2017_c13_suess_effect.nc`
   IS ALREADY IN THE REPO** and is exactly the δ¹³C correction; DIC needs a Cant estimate the
   repo does not carry.
3. Score the model's *transient* 2010s gradient against the modern observation, dodging the
   correction entirely at the cost of making the term depend on the transient run.

**This is a target-definition choice and it is Marcus'.** Option 2 for δ¹³C looks cheap given
the file is already downloaded.

**Related, and found by a gate this session:** the existing deep-Δ¹⁴C target is *everything
below 2627.2 m*, not the model's 2627–3700 m box — the build script passes `zmax = 1e5`.
Restricting to the model's actual box moves it −175.26 → **−177.81 ‰ (0.25σ)**. The new terms
should not inherit that inconsistency without a decision.

### 4.5 THE ORDERING CONCLUSION

Because the terms are unfittable until a pump exists:

> **Add the terms and build the pump in the SAME round, then refit once against the complete
> objective.**

Terms-first is harmless (constant offset) but buys nothing. Pump-first means the pump is fitted
against an objective that cannot see its two signature rows — which is the exact failure the
terms are being added to prevent.

### 4.6 Their sigmas need the same treatment `n_eff` just got

`sd_w` is **53.9 µmol/kg** for deep DIC and **0.327 ‰** for deep δ¹³C. At n_eff = 20 that is
σ = 12.05 and 0.0732. **But n_eff was measured for Δ¹⁴C, not for these fields** — DIC and δ¹³C
have their own spatial structure. `diag_deep_d14c_neff.R` generalizes to them with a field
argument; that is a ~1 min re-run and it should happen before the terms ship.

---

## 5. The ordering, amended

| # | task | status |
|---|---|---|
| ~~1–7, 6b~~ | objective, β, `luc_scale`, GLODAPv2, gradient, shares, seasonality, MM fertilization, `sigma_co2` | **DONE** |
| **6** | `LIK_EXCESS_C14_TARGET` | NOT a blocker |
| **9** | the pump | all three clauses PASS, via the background state not export (15d) |
| **10** | depth-dependent `K_z` | **scored.** Owns clause 3 only |
| **11** | outcrop `w_out_*` | **DEAD.** Do not re-propose |
| **12** | **DIC + δ¹³C gradient terms** | **TAKEN by Marcus 2026-08-16.** §4 |
| **8** | **THE REFIT** | **after 12 + 9, once, against the complete objective** |

---

## 6. Open decisions, in dependency order

1. **§4.4's target definition** — raw modern gradient, Suess/Cant-corrected, or transient-scored.
   Blocks the terms.
2. **`n_eff` for DIC and δ¹³C** — measure per field (§4.6). Cheap, blocks the terms.
3. **Representation error in or out.** Still zero. At σ 18.15 candidate A stops being adopted.
4. **Point σ vs Student-t** (§3). Honest error model vs ever retiring the `kz` bracket.
5. **Is A's `kz` = 6404, outside [3830, 6200], a blocker or a re-derivation?** Note the coupling:
   the Student-t option makes this *harder* by removing the term's ability to stand in for the
   bracket.
6. **Does A ship at all**, given it fixes clause 3 and nothing else, and turns on (3).

---

## 7. Non-obvious state, and a caution

- **My error rate this session was high.** Retracted: "A lets C be built at a defensible export"
  (false — A wants a *larger* `kz`); the unconditioned "2.6× export" headline (it is a strong
  function of `kz` AND `h_ml`, 4.8–35 GtC/yr); "the objective prefers deep Δ¹⁴C at −9.75σ" (a
  coarse-grid artifact). Failed predictions: the Revelle/surface-buffer channel (does not
  exist), the *direction* of the pump's deep-Δ¹⁴C effect (it depletes, not enriches), and
  "marginalising breaks the `kz` hold" (it does not). Two bugs in one verdict block.
  **Every one was caught by a gate or control written before the answer was known.** Trust the
  tables; check the prose.
- **The decision-block bug worth remembering:** a name looked up in the wrong list returns
  `NULL`, `abs(NULL$x)` is `numeric(0)`, and **`min()` silently drops it** — the rule then
  scored one candidate instead of two and fired the opposite way. Assert `length(x) == 1L` on
  anything a decision rule reads.
- **The C++ core does not know about `K_z(z)` or the pump.** Both are shims over `ccx_deriv()`
  in their diagnostics, which is why those files cost 40 and 15 minutes. `w_out_*` IS in the
  core, which is why B1 was free. Porting is a shipping decision.
- **`calibration/output/mode_fit.rds` is still EMPTY.** The app has no mode. Every "at the mode"
  number comes from the quarantined pre-gradient one.
- **19 parameters.** The two OPPOSITE absence conventions in `err` still stand: gradient offsets
  absent → streams SKIPPED; `sigma_co2` absent → tighter sd.
- **`luc-veg-debit` has never been merged** and is now a long way from `main`.

**Still do NOT:** hand-tune stream weights (adding the §4 terms is *adding a missing
constraint*, which is the sanctioned move — do not let it become a license to reweight);
delete `excess_c14_ocean` or `d14c_intcal`; free any land turnover parameter; delete the `kz`
bracket bare; build the conveyor; splice any pre-2026-08-15 posterior; quote a logL from a
diagnostic not given the gradient offsets; lower `LIK_CO2_REP_ERR` as housekeeping; quote the
defaults-parameter clause-3 verdict as the answer; or quote the free validations (ocean
inventory, ¹⁴C production) as if the likelihood had rewarded them.

---

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-16_candidates_neff_and_gradient_terms.md`. Candidates A and B1
> are scored (B1 dead, A owns deep Δ¹⁴C only), `n_eff` is measured and 20 survives, and
> **Marcus has put the DIC and δ¹³C gradient terms into the next round — §4.** Their parameter
> leverage is exactly zero, so they are a constant ~384 log-units and the ordering conclusion
> is **terms + pump in the same round, then one refit.** Start on §6's decisions 1 and 2, which
> block the terms. Suite 4 failing, none flagged.
