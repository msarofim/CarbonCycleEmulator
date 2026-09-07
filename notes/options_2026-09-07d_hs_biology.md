# OPTIONS for the design ruling — 2026-09-07d: the deep ocean's biology under the HILDA structure

**Question (handoff 09-07c §3):** the structure holds the Δ¹⁴C profile and breaks the DIC/δ¹³C gradients. Give
HS a pump, give HS a preformed end-member, or stop? Marcus's lean: add mechanisms that exist rather than remove
the structure; a simpler approach is acceptable if it works for everything.

## 0. What changed before the options were priced
1. **A bug, not physics, in a third of the miss.** The gradient rows converted GtC → µmol/kg over `a_oc`; the
   boxes span `a_ls`. Fixed, mutation-tested, re-scored (CHANGELOG 2026-09-07d). Corrected losses at the
   round-2 winner vs ent26: δ¹³C **−27.6**, ALK **−13.8**, DIC **−4.0**, `d14c_NH` −4.1 ⇒ rest −47.8.
   The δ¹³C row is the problem; ALK second; DIC alone now inside R4's tolerance.
2. **The end-member was measured, not inferred** (`calibration/diag_hs_endmember_probe.R`). GLODAP high-latitude
   surface DIC is 2163 (SH) / 2069 (NH); the model's HS is **2169 = full air–sea equilibrium at 2 °C**. The
   observed deep is **2279**, i.e. +116 above the SH surface; the model's bottom is 2181, **+12** above HS.
   δ¹³C: observed high-lat surface +1.31, deep +0.44 (−0.87); model HS **+1.96**, bottom +1.96 (**0.00**).

## 1. The options, priced
| | mechanism | exists in nature? | what the probe says | cost | pre-check |
|---|---|---|---|---|---|
| **(a) HS pump** | export from HS, remineralised into HD (two limbs, `PUMP_EPS13_*` fractionation, rain ratio `pump_carb_frac`), so HD/deep carry regenerated DIC and light δ¹³C | yes — Southern-Ocean + subpolar N Atlantic export (magnitude: my recollection 1–3 GtC/yr south of ~50 °S; UNSOURCED, to be cited before it becomes a prior) | exactly the missing piece: deep − HS is +12 vs +116–185 observed, 0.00 vs −0.87 ‰ | ~30 lines per core (an `add_flux(ihs, ihd, …)` pair beside the conduit), one parameter, parity test, migration contract; C9 is a DEFERRAL, so this is paying it | HS export at the LS per-area rate = **3.64 GtC/yr** ⇒ HD **+135 µmol/kg** against the `u_hs` flush (1.90 ⇒ +70 at a real-ocean LS export). δ¹³C: ε_org × ΔDIC/DIC ≈ −1 ‰ at ΔDIC 135. Both inside the observed range without tuning. |
| (b) preformed end-member | pin HS DIC/δ¹³C to the observed high-lat surface | it is a NUDGE, not a mechanism | **REFUTED as the fix**: HS DIC already equals the observed SH surface; pinning δ¹³C to +1.31 fixes the HS level, not the deep − HS contrast (0.00 vs −0.87) | small | closes nothing the rows score |
| (b′) HS alkalinity (C8) | HS `ALK` from GLODAP (2256 vs 2309 low-lat) | yes (freshwater / N Atlantic) | moves HS equilibrium DIC ~−50 toward the NH's 2069; irrelevant to the deep − HS contrast | tiny, observation-pinned | secondary; only after (a) |
| (c) stop | record "ventilation yes, biology no", return to the column with #10 | – | the column fails the profile CONTRAST at +3.9σ ([[ccx_profile_contrast_is_the_observation]]) | 0 | gives up an observation the structure holds |
| (d) simpler: weaken the conduit | larger `tau_q` / attach `q` deeper | – | the CO₂ rows reward it (+93 at `tau_q` ×2) but the contrast fails (+4.3σ) — already scanned 09-06d | 0 | fails the profile |
| (e) simpler: conduit in the pump operator | solve the LS export against diffusion + conduit | consistency fix, owed anyway | cannot ADD deep enrichment: the LS pump's carbon is remineralised in layers the conduit flushes; the solve would demand even more export (57 GtC/yr is already 3× ent26, ~5× real) | small | no — do it, but it is not the fix |

**Recommendation: (a), with (e) done in the same change and (b′) queued.** It is the only option that adds a
mechanism that exists, targets the measured defect, and passes a first-principles magnitude check. (b) is dead
on the data; (c) and (d) trade the profile away; (e) is hygiene.

## 2. Protocol for (a) — for Marcus to rule on, not yet built
- **Parameter:** `pump_hs_rel` = HS per-area export ÷ LS per-area export. Declared **1** for the probe; for the
  refit either declared or fitted on [0, 3] with a prior centred where the sourced SO-export literature puts it.
  Enters `ccx_pump_export()` as a third element with area `a_hs` and sink HD (the profile question is moot: HD is
  one box); both limbs, both cores, `pump_hs_rel = 0` bit-exact (the C10 discipline).
- **New observation rows, so the mechanism is priced by data it does not fit:** HS-surface DIC and δ¹³C from the
  probe's GLODAP build (SH: 2163 ± sd/√n_eff; δ¹³C +1.31), and the deep − HS contrast — the statistic the probe
  shows is the defect. Hemispheric asymmetry (NH 2069) is a C8/(b′) matter; score the SH first.
- **Predictions to pre-register:** P1 HD − HS DIC lands in [+70, +185] at declared 1; P2 bottom − HS δ¹³C ≤ −0.5;
  P3 `ocean_grad_d13c` recovers ≥ 20 of its −27.6 at the winner's other parameters; P4 `pump_grad` falls toward
  its prior (the LS pump no longer fights the conduit alone) and the ALK row improves; P5 the Δ¹⁴C profile stays
  inside 2σ (the pump carries ¹⁴C unfractionated — no first-order effect); P6 HS δ¹³C moves toward +1.31 (the
  15 %-per-pass isotopic equilibration lets HD's light carbon set it).
- **Cheap first test (one spinup + one transient, no refit):** the handoff's probe — at the winner's vector, add
  the HS export at `pump_hs_rel` 1 and re-read the three gradient rows and the probe's box table.
- ⚠ Also owed: `pump_grad`'s solve and the ALK diagnostic must include the conduit and the HS limb in their
  operator (e), or the fitted "export" stops meaning export.

## 3. What the bug changes about rounds 1 and 2
Both fits optimised against DIC/ALK rows deflated by 0.84. The verdicts do not move, but `pump_grad` +3.2 prior-z
and the 57 GtC/yr export are partly the optimiser's compensation; the true ALK gradient at the winner is ~186 vs
+78.6 observed. Any refit — with or without (a) — must run under the corrected rows; the round-2 start files stay
where they are as the record of what the bugged objective found (README in the quarantine directory).
