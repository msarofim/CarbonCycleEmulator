# PRE-REGISTRATION — the `u_hs` / `h_ml` tests T1–T7 (2026-09-08c). Written BEFORE T1, T2, T5, T6 were run; binding for those four.

**Standing:** `notes/handoff_2026-09-08b_u_hs_h_ml_literature.md` §1–2 designed seven tests for a ruling on the two
declared-or-railed quantities round 3 left (`u_hs` 38 m/yr = a 70 Sv flush; `h_ml` 39.8 m in every HILDA round).
Marcus (2026-09-08): "continue work, including downloading the Holte climatology." **Nothing is adopted by any of
this; canonical `ent26`; the ruling (free / pin / leave) stays Marcus's.**

## What was ALREADY READ before this note (reported as results, not predictions)
Honesty line. Three of the seven are single reads of stored state, and they were taken while assembling this note:
- **T3** (conduit net interior→HD carbon flux at the round-3 winner's spinup) and **T4** (LS remineralization below
  1000 m) were computed from the winner's spinup state (`calibration/output/multistart_20260907f_hilda30/`, id 24,
  logpost −1481.27) while timing the run. They are reported in the diag log with no prediction attached.
- **T7** (the 40 m vs 180–200 m family per stream) is a diff of the round-3 scorer's own saved streams
  (`outputs/diagnostics/hilda30_predictions_20260908.rds`), no new run.
- **The MLD observation** (`data/obs_mld.rds`, built by `data-raw/build_mld_targets.R` from the Holte 2017 product,
  manifest `holte_mld_argo_clim`) was computed before this note, because T5/T6 need its number: LS (|lat| < 57.14°,
  the boundary DERIVED from `hs_frac` 0.16) annual-mean threshold MLD **59.7 m** (sd across cells 30.3; algorithm 53.2),
  annual-maximum **118.1 m** (sd 83.3); HS 115 (strict) / 75 (any-month) — a bracket, not a value.

## The runs (`calibration/diag_u_hs_h_ml_tests.R`; every run 0.5 s locally, so Torch is not considered)
All at the round-3 winner's vector (id 24), structure `hilda`, objective #10 + #11 as round 3 (the multistart's own
`ccx_make_logpost`, priors included; the likelihood alone reported beside it). "Profile in `pump_hs_gcm2`" = a 1-D
optimum in log(`pump_hs_gcm2`) on [0.5, 200] with everything else held at the winner.
- **T1**: `u_hs` ∈ {38, 30, 24, 18} m/yr, profile in `pump_hs_gcm2`.
- **T2**: `h_hs` ∈ {400 (winner), 75 (HILDA's)}, profile in `pump_hs_gcm2`, `u_hs` 38.
- **T5**: `h_ml` pinned at the observed LS annual mean (59.7), nothing refitted; every stream re-read.
- **T6**: the same at the observed LS annual maximum (118.1).

## Predictions (the runs are judged on these)
| | prediction | falsified if |
|---|---|---|
| P1 | T1: the conditional optimum in `pump_hs_gcm2` scales with `u_hs`: at 24 m/yr it lies in **[74, 100]** (137.5 × 24/38 = 86.8 ± 15 %); at 18 in [55, 75] | outside either band |
| P2 | T1: the HS surface δ¹³C at the conditional optimum falls MONOTONICALLY as `u_hs` falls (toward the observed +1.31) | any rise between consecutive `u_hs` values |
| P3 | T1: the net conduit delivery HD→interior at the conditional optimum stays in **[0.7, 1.4] GtC/yr** at every `u_hs` (it is set by the interior–HD concentration gap, not by the flush) | outside at any `u_hs` |
| P4 | T1: the objective (logpost) at the conditional optimum FALLS as `u_hs` falls below 38 — the 09-06d scan lost 517 at half `u_hs` without the HS pump; with it the loss at 24 is predicted **< 100**, concentrated in the Δ¹⁴C profile rows | the objective RISES at any `u_hs` < 38 (then the declared 38 was itself the defect and pinning is free), OR the loss exceeds 100 |
| P5 | T2: the conditional optimum at `h_hs` 75 is within **±10 %** of the one at 400 (thickness cancels in the steady ratio, [[ccx_hs_endmember_is_kw]]) | outside ±10 % — the horizon does work the algebra says it cannot |
| P6 | T5: pinning `h_ml` at 59.7 costs **< 10** log-units unrefitted (the 40/44 twins differ by 0.3; the 184 m family is 5 behind), and the row that pays most is `ocean_grad_d13c` (the 09-07c lever) | cost ≥ 10, OR the largest-paying row is a bomb, seasonal or CO₂ row |
| P7 | T6: pinning at 118.1 costs more than T5 but **< 30**; the sink and bomb rows (`gcb_ocean_sink`, `d14c_NH/SH`) each move < 2 | cost ≥ 30, OR a sink/bomb row moves ≥ 2 |

## What each verdict means for the ruling (written now so the reading is not fitted to the result)
- P1 ∧ P4 ⇒ H1 holds (the flush is the lever): option (b) for `u_hs` — free it with a prior centered on the
  observation (18–26 m/yr, [[overturning_and_mld_literature]]) — and expect the export to land near 60–90 at the
  prior's center. P4's cost says what the profile rows will charge for it.
- ¬P5 ⇒ the horizon (H2) is doing work; re-state the export prior at the 400 m-flux meaning before round 4.
- P6 ⇒ the 40 m buys the δ¹³C gradient row only: `h_ml` can be observation-pinned at the annual mean at small cost;
  ¬P6 with a bomb/seasonal row paying ⇒ the 40 m is a real capacity statement and the mean-vs-max choice matters.

## Post-hoc (written AFTER the first run, 2026-09-08c — all seven of P1–P7 FAILED)
Every failure was charged by the same rows: `co2_level_MLO` / `co2_level_SPO` (σ 1 ppm on ~800 months) and the bomb
rows. A 1-D profile or an unrefitted pin is read by the CO₂-level rows before any deep row can speak, so P1–P4 and
P6–P7 tested the CO₂ rows' sensitivity to the perturbation, not the hypotheses they were written for
([[no_power_null]]). Three reads were ADDED, and one prediction — written now, after P1's failure was seen:
- **T1(i)** the flush at FIXED export (u_hs alone); **T1(ii)** the export optimum against the 8 deep rows
  (`ocean_grad_*`, `hs_surf_*`, `d14c_profile_*`) alone — the powered H1 test; **T2(0)** HILDA's 75 m at the SAME
  export — the steady-state HD−HS must not move if the thickness algebra holds (it is the "implausible = bug" check
  on P5's failure).
- **P1b** (post-hoc): the deep-rows-only optimum at `u_hs` 24 lies in P1's band [74, 100] and the ratio
  g_opt/`u_hs` is constant to ±10 % across {38, 30, 24, 18}. Falsified if either fails. ⚠ Written after the T1(ii)
  scratch run had been seen; it is a REGISTRATION of the reading, not a prediction, and is labeled so in the log.
