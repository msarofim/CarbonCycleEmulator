# PRE-REGISTRATION (DRAFT — NOT BINDING UNTIL MARCUS RULES) — ROUND 3: the HILDA structure WITH the HS pump, 30 parameters, corrected gradient rows

**Why a draft.** The probe's pre-registered "plausible fix" gate (prereg 09-07d, amended) **FAILED by its letter**:
at the observation-sized point (60 gC m⁻² yr⁻¹ = 3.47 GtC/yr) P1, P2, P4, P5, P7 PASS, **P3 +18.9 of the required 20**,
**P6 wrong-signed** (HS surface δ¹³C +1.96 → +2.08, observed +1.31). The likelihood gains **+17.2** with nothing
refitted and the δ¹³C row recovers 69 % of its −27.6. That is a mechanism that does what it should at the observed
magnitude, one row short of its own gate, with one new defect surfaced — a launch is a judgement call, so it is
yours. Everything below is ready to run.

## What is fitted / declared
- Fitted (30): round 2's 29 + **`pump_hs_gcm2`** on [0.5, 200] gC m⁻² yr⁻¹ (0.03–11.6 GtC/yr), uniform prior on
  the box, init 60. Ancestors (the round-2 start files) ran 0 → seeded at 60 by `ccx_seed_unencodable()`.
- Declared: `hs_frac` 0.16, `u_hs` 38, `tau_q` 538, `sst_hs` 2, `q_attach_from` 1, `kz_zscale` 253 (unchanged).
- Objective: #8 + #10, **on the CORRECTED gradient rows** (`ccx_column_area`, 09-07d). Harness as round 2;
  out `multistart_20260907e_hilda30/`.

## OPEN CHOICES (methodological — need a ruling, not a default)
1. **Prior on `pump_hs_gcm2`.** Uniform on the box as drafted, or a literature prior on Southern-Ocean +
   subpolar export? My recollection is 1–3 GtC/yr south of ~50 °S (UNSOURCED); the observation-matched probe
   point is 3.5 GtC/yr over 16 % of the ocean. A prior centred on the probe point would be a centre off the code
   under test ([[derived_must_mean_computed]]) — not proposed.
2. **Objective change #11: HS-surface rows.** GLODAP high-latitude surface DIC (SH 2163) and δ¹³C (+1.31), and/or
   the deep − HS-surface contrast (+116 SH / +185), as scored rows or as out-of-sample gates. The probe shows the
   existing rows already respond (+17), so this is about pricing the P6 defect, not about power.
3. **Launch** (Torch; [[consider_torch_first]] — say the verdict out loud: 46 starts × 30 parameters is a Torch job).

## Predictions (drafted; binding once ruled)
| | prediction | falsified if |
|---|---|---|
| R1 | `pump_hs_gcm2` interior and in **[20, 120]** (1.2–7 GtC/yr) | at a bound or outside |
| R2 | level, A−B, B−deep inside 2σ | any \|z\| > 2 |
| R3 | `ocean_grad_d13c` within **5** of `ent26` (round 2: −27.6; probe at 60: −8.6) | worse by > 5 |
| R4 | `pump_grad` back inside **±2** prior-z (round 2: +3.24) and the LS net export falls below round 2's 73.6 GtC/yr | not |
| R5 | `ocean_grad_alk` improves on round 2's **−13.8** | not |
| R6 | total gain over `ent26` exceeds the profile rows' own (round 2 failed: rest −47.8) | rest still negative |
| R7 | `h_ml` in **[60, 180]**, `h_hs` interior | not |
| R8 | sink and bomb within 2 of `ent26` | worse by > 2 |
| R9 | HS surface δ¹³C (unscored unless #11) does NOT move further from +1.31 than the probe's +2.08 | > +2.1 |
