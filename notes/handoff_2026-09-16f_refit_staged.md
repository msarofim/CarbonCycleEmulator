# Handoff — 2026-09-16 (f). **The hygiene-batch REFIT is staged and launchable on the Mac side; NOT submitted — the Torch channel needs Marcus's authentication. Objective #12 is live, every registered mode is restamped, `hilda30c` stays canonical.**

> Self-contained for a cold start. HEAD = `d758f5b`. The full session record (O5b refuted, the martin arc parked with O2 in DESIGN §6, the
> whole-model review, fixes 2/3/6/7, objective #12 priced and restamped, the `h_ml` floor) is `handoff_2026-09-16e_hygiene_batch.md` —
> read it §2–3 for the numbers; this note is the LAUNCH state. Memory: [[ccx_objective_12_hygiene_batch_0916e]],
> [[ccx_whole_model_review_0916d]]; `INDEX_ccx.md` (15.0 KB, merge before adding). CHANGELOG 09-16 (f) is the last entry.
> Nothing is running on the Mac; the working tree is clean apart from the disposable `_smoke` outputs and `port_gate_id1_20260914.log`.

## 1. What the refit IS
- **Question**: on objective #12 (the deep/slab Δ¹⁴C rows reading every box; land-sink σ at GCB's 0.5 with no ×3; Naegler's net-uptake
  correction; the pre-1850 SST baseline; `h_hs` under its Holte prior) and the `hilda_c` constants (`hs_frac` 0.128, whole-LS SSTs
  22.3/18.7, `alpha_photo_eps` 15.6), where does the mode go — and in particular does the land sink come down toward GCB (it sits
  +1.0 GtC/yr over; item (ii) cost the canonical −27.0 unrefitted), and what pays for it?
- **Configuration** (recorded in `calibration/torch/multistart.sbatch`'s header and `calibration/torch/port_targets.csv`):
  `CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1 CCX_MS_PIN=ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0`,
  pump field solved (unset). The pin set = the canonical's pin + the six names inert under this structure/field ⇒ **30 free = the
  canonical's set**. Incumbent start `hilda30c` (id 1), new-basin `hilda31p` (id 2), cold id 0, 21 dispersed.
- **Port targets** (`19be01f`, 30 names, host MacBook-Pro-2, commit `dfb52a7`): cold −34412.4104, incumbent −1755.4527 (offset −304.77 vs
  its stored −1450.6873 = the constants' + the batch's UNREFITTED price — not a port defect), new_basin −1951.8484 (−495.85).
- **Mac preflight**: id 1 port gate PASSED rel 2.8e-14 (floor 2.4e-5, bound 7.2e-5), 0.167 s/eval; id 2 PASSED rel 4.1e-15, 0.187 s/eval.
- **Bundle**: `/tmp/ccx_torch_bundle.tar.gz` (3.0 MB; registry 6/6; ships `nuclear14c`, the restamped mode files, `data/obs_h_hs_prior.rds`,
  the port targets). ⚠ `/tmp` may not survive a reboot — rebuild with `bash calibration/torch/make_bundle.sh` (10 s) if absent.

## 2. What to do (in order; Torch verdict said aloud: 24 starts × 6 h is a Torch array)
1. Marcus opens the Torch channel (VPN + gateway password + Duo + device code; BatchMode ssh exits 255 until then). Check
   `ssh torch 'squeue -u ms17839'` is empty of stale jobs.
2. `scp /tmp/ccx_torch_bundle.tar.gz torch:/scratch/ms17839/` then
   `ssh torch 'mkdir -p /scratch/ms17839/CarbonCycleEmulator && tar xzf /scratch/ms17839/ccx_torch_bundle.tar.gz -C /scratch/ms17839/CarbonCycleEmulator && rm /scratch/ms17839/ccx_torch_bundle.tar.gz'`.
3. PREFLIGHT array from `/scratch/ms17839/CarbonCycleEmulator`:
   `CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1 CCX_MS_PIN=ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0 CCX_MS_PREFLIGHT=1 sbatch --array=0-23 --time=00:15:00 calibration/torch/multistart.sbatch`.
   Read all 24 logs: `PORT GATE (a) PASSED` and `LAUNCHABLE` on every id (id 1 is the noisiest point: its floor-scaled bound is the
   09-15 ruling A; a FAIL there is diagnosed, never loosened). ~5 h queue on `(Priority)` was the 09-14 experience.
4. THE WAVE: the same command without `CCX_MS_PREFLIGHT=1 … --time`, with `--array=0-23%24` (6 h wall, `cs`). Outdir (derives from
   struct + date now): `calibration/output/multistart_<YYYYMMDD>_hilda_c_seasml1_pin_…_sd<spread>`. A round-2 resume passes
   `CCX_MS_TAG=<round-1 date>` so it lands in the same directory.
5. Pull the start files + checkpoints to the Mac (`rsync` from the outdir), run `calibration/collect_dispersed_multistart.R`, then read
   (in this order): `gcb_land_sink` and what paid (β_max / q10 / the CO₂ level rows); kz under the every-box Δ¹⁴C rows (review finding 1
   was a directional pull on exactly this); `h_hs` under its prior (canonical 393 m is z +1.9); `u_hs` at the converted center 27.3 m/yr;
   the scorecard's 7 / H / GL / Q; `sst_seas_amp_SH`'s z; whether the `seas_ml`-0 control still loses. Promotion = a NEW label via
   `promote_multistart_mode.R` (never an in-place edit of `CCX_STRUCT_HILDA`); nothing to restamp — a fitted mode is stamped.
6. After the read: prereg the layer-2 ENSO limb as a REFIT (review avenue 1; rule in the physical unit; W0 pinned to Meinen 2001's
   51–64 m/yr; γ prior 14–25 Sv/index).

## 3. Non-obvious state
- The driver now REFUSES free `w_eq`/`gamma_eq` under a structure without the cell, and `ccx_pins_extend_canonical()` takes `struct`
  (env default) so the canonical is the incumbent under the six inert pins. The E array (09-15) had fitted them free.
- Every stored logpost is in the FILE'S OWN coordinates (own names, recorded band); `ccx_mode_start()`'s shift carries the seeding + the
  h_ml band term. Every number quoted before 09-16 (e) is on objective #11; the five switches (`LIK_D14C_EVERY_BOX`,
  `LIK_LAND_SINK_INFLATE`, `LIK_EXCESS_C14_UPTAKE_CORR`, `FORC_SST_PRE1850_MEAN`, the `h_hs` prior) reproduce it.
- Suite on the batch tree 3703/3/6+1 = the standing reds + `test-gate-bounds:235` (fixed, `fd88650`). A frozen copy MUST carry
  `data-raw/downloads/nuclear14c/`.
- Open by design: review F4 (the gradient rows' σ-inflation, the 08-28 ruling — a two-line alternate scorer decides whether it matters);
  `pump_mode` N/D never ruled; `ccx_default_params()` is the inverse of the canonical on `seas_ml` and the shim (never run a
  bare-defaults column).
- Over-soft memory indexes: `INDEX_ccx` 15.0, `INDEX_cmp_pulse` 17.1, `INDEX_diag` 16.3, `INDEX_slr` 16.3, `INDEX_ais` 15.0, `INDEX_ccx_arch`
  14.6 KB (all under 18 hard) — split, don't trim.
