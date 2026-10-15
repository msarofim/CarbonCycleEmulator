# PRE-REGISTRATION — ROUND 3: the HILDA structure WITH the HS pump, 30 parameters, a literature prior, objective #11 (HS-surface rows), corrected gradient rows. Written 2026-09-07f BEFORE launch; binding.

**Ruling (Marcus, 2026-09-07f):** (1) a literature prior on the HS export; (2) the HS-surface observations as SCORED
rows; (3) launch on Torch after a sweep of the model and launch code. Supersedes the 09-07e DRAFT (its history is
in git: the probe's gate failed by its letter — P3 +18.9 of 20, P6 wrong-signed — and the launch was a judgment
call; this is the judgment).

## What is fitted / declared
- Fitted (30): round 2's 29 + **`pump_hs_gcm2`** (HS export per unit area, gC m⁻² yr⁻¹, remineralized in HD), box
  [0.5, 200]. **Prior: lognormal, median 22.9, log-sd 0.6** (2.5–97.5 %: 7–74) — `data-raw/build_hs_export_prior.R`
  from the polar-Antarctic-zone float export of Liniger et al. 2025 (2.01 molC m⁻² yr⁻¹, doi:10.1029/2024GB008193)
  and Arteaga et al. 2019 (1.80, doi:10.1029/2019GB006236); the width carries the NH half of the box and the export
  horizon. init = the prior median. Round-2 ancestors ran 0 → seeded at 22.9 (`ccx_seed_unencodable()`).
- Declared: `hs_frac` 0.16, `u_hs` 38, `tau_q` 538, `sst_hs` 2, `q_attach_from` 1, `kz_zscale` 253 (unchanged).
- Objective: #8 + #10 + **#11** (`LIK_USE_HS_SURFACE`): `hs_surf_dic` (SH high-latitude surface, GLODAP 2163 at
  epoch 2008) and `hs_surf_d13c` (both hemispheres, +1.31 at 2011), σ_eff = √(sd² + sd_cluster²) = 24.0 µmol/kg /
  0.31 ‰ (`data-raw/build_hs_surface_targets.R`). **On the CORRECTED gradient rows** (`ccx_column_area`, 09-07d).
  ⚠ **The #11 rows are WEAK by construction** (09-07f code sweep): with σ_eff derived from the bottle spread they
  move ~2 log-units across the WHOLE `pump_hs_gcm2` box (DIC 0.03, δ¹³C 2.1) against the δ¹³C gradient row's +27,
  so they RECORD the surface, they do not arbitrate the export. A tighter σ would be a ruling (the physical
  representation error — a one-box annual-mean surface vs summer-biased bottles — is real and of this size).
  ⚠ The #11 rows exist only with the structure ON; `ent26` (column) has no HS box and scores no such rows, so every
  "vs ent26" comparison below is on the COMMON rows, stated as such.
- Harness as round 2 (46 starts, `--array=0-45%10`, wall 180 min, 3 restarts, 6 cycles); out
  `multistart_20260907f_hilda30/`; port targets re-cut at the launch commit.

## Baselines under the round-3 objective, nothing refitted (probe `diag_hs_pump_probe_20260907_obj11.log`)
Round-2 winner (id 44) at `pump_hs_gcm2` 0: **−1475.1** (the two #11 rows cost 6.1: HS δ¹³C +1.96 vs +1.31 is 2.1σ).
At 60 gC m⁻² yr⁻¹: −1458.8 (+16.3); the scan optimum is unchanged by the rows. `ent26` on the common rows: −1652.6.

## Predictions (the run is judged on these)
| | prediction | falsified if |
|---|---|---|
| R1 | `pump_hs_gcm2` interior and in **[10, 120]** (0.6–7 GtC/yr) | at a bound or outside |
| R2 | level, A−B, B−deep inside **2σ** | any \|z\| > 2 |
| R3 | `ocean_grad_d13c` within **5** of `ent26`'s (round 2: −27.6; probe at 60: −8.6) | worse by > 5 |
| R4 | `pump_grad` inside **±2** prior-z (round 2: +3.24) AND the LS net export below round 2's 73.6 GtC/yr | either fails |
| R5 | `ocean_grad_alk` better than round 2's **−13.8** vs `ent26` | not |
| R6 | total on the COMMON rows beats `ent26` by MORE than the three profile rows' own gain (round 2: rest −47.8) | rest still negative |
| R7 | `h_ml` in **[60, 180]**, `h_hs` interior | not |
| R8 | sink and both bomb streams within **2** of `ent26` | worse by > 2 |
| R9 | `hs_surf_d13c` at the mode no worse than the probe's z 2.5 (HS δ¹³C ≤ +2.08); `hs_surf_dic` inside 1σ — RECORDED rows (weak, above), so R9 is a report on the surface, not a verdict on the pump | either fails |
| R10 | the prior and the data DISAGREE on the export: the mode sits above the prior median (z > +1) — the probe's 60 was +1.6σ | mode ≤ prior median |
| R11 | the survey is UNIMODAL at the top (best basin from ≥ 10 starts; no basin within 5 log-units differing in `pump_hs_gcm2` by > 20) | not |

**Read R10 as the finding, not a defect**: if the export the deep gradients want is 2–3× the float-based polar export,
that is the `u_hs` = 38 m/yr flush (declared, HILDA's) or the horizon, and the next ruling is about those.
**Adoption**: nothing here adopts; if R1–R3, R6, R9 pass, the mode is a CANDIDATE for `ccx_mode_file()` and the
DESIGN-gate sweep, for Marcus.

## SCORED 2026-09-08 (job 17150003, 46/46 COMPLETED, none failed) — `calibration/diag_hilda30_predictions.R`
Winner **−1481.27 from 24 starts** (+6 in a near-twin at `h_ml` 43.8): `pump_hs_gcm2` **137.5** (7.94 GtC/yr, prior-z
+2.99), f 0.0247 (K_deep 224), `hs_asx_frac` 0.818, `h_ml` **39.8**, `h_hs` 400, `kz` 9047, `pump_grad` **276** (+0.68),
LS net export **29.9** GtC/yr (round 2: 73.6). Second family (12 starts, −1486) at `h_ml` 180–199, f 0.07–0.09. EVERY basin
puts the export at 136–142. Profile z **−0.50 / +1.05 / +0.68**. Common-row gain vs `ent26` +225.0 = profile rows +234.0,
rest **−9.0** (round 2: −47.8): δ¹³C row −7.0 (was −27.6), DIC −3.2, ALK **−0.14** (was −13.8), `d14c_NH` −1.6.
HS surface: DIC 2149 (z −0.6), δ¹³C **+2.46 (z +3.8)**. Sink 3.03.
**R1 FAIL, R2 PASS, R3 FAIL (by 2), R4 PASS, R5 PASS, R6 FAIL, R7 FAIL, R8 PASS, R9 FAIL (recorded), R10 PASS, R11 PASS.**
Collect: 40 dispersed starts reproduced and did not beat the best re-converged known basin (bound 0.5 log-units).
Reading: the HS pump supplies the deep biology (R4, R5, the δ¹³C row's 20-unit recovery, rest −48 → −9) and pays with a
cold-box export 4× the float prior and a cold surface δ¹³C 0.4 ‰ heavier still — the same lever: the declared `u_hs` = 38
m/yr over 16 % of the ocean is a **70 Sv** two-way flush (38 × 5.78e13 m² / 3.156e13 m³ yr⁻¹ Sv⁻¹), and the export that
holds the observed deep enrichment scales with it. ⛔ Nothing adopted; the ruling is Marcus's.
