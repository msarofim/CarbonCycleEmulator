# Handoff — 2026-09-14 (j) → 09-15. **The E array is ON TORCH: setup gate PASSED; preflight 17818291 RAN after 4.7 h queued — 23/24 LAUNCHABLE at 0.48–0.55 s/eval, id 1 FAILED port gate (a) at the INCUMBENT by rel 2.16e-8 vs 1e-8. DIAGNOSED (HEAD `f66449f`): NOT a broken port — the objective's own roundoff floor at that point is 20–40× the other references' and the 5.7e-5 diff sits inside it. Marcus RULED option A (built `bf03507`, mutation-tested); id 1 re-preflight PASSED; **THE WAVE IS SUBMITTED: Torch job 17839702**. Nothing adopted; `hilda30c` canonical.**

> Self-contained. HEAD = `efeaaaa` + this note. CHANGELOG 09-14 (i). Memory: [[ccx_option_e_built_probe]] (in `INDEX_ccx_ocean_cell`).
> ⚠ root `MEMORY.md` is 18.28 KB of an 18.43 KB hard ceiling: RESTRUCTURE THE ROOT before adding a line.
> Previous: `handoff_2026-09-14i_e_array_launchable.md`.

## 1. Done this session
1. Torch verdict said aloud (36 names × 24 starts × 3 restarts → Torch). On arrival: queue EMPTY, eq-cell wave 17769990 COMPLETED
   24/24 exit 0 (already read 09-14 c), FairShare **0.193**, login-node load 52.
2. `make_bundle.sh`: ⛔ the column control's mode file (`CCX_MODE_COLUMN_CONTROL`, ent26, quarantined 09-08) had NEVER been in the
   tar list; the "registry check" tested Mac existence, not tarball membership. Added the dir + a `tar tzf` membership gate,
   MUTATION-TESTED. `COPYFILE_DISABLE=1` (480 xattr warnings per extract on Torch). Commit `efeaaaa`.
3. Bundle shipped and extracted to `/scratch/ms17839/CarbonCycleEmulator` (tree = `99ec0ba`'s R/src/data; `port_targets.csv` md5
   `64636af1…` matches the Mac). `setup_torch.sh` under the four env vars: Rcpp 1.1.0, C++ 30.8 s, **GATE PASSED rel 3.46e-11**,
   32 parameters, `hilda_c`. Login-node 1.91 s/eval = contention (load 52), NOT a sizing number.
4. Preflight submitted verbatim from the sbatch's 09-14 (h) block → **job 17818291**, `--array=0-23 --time=00:15:00`, `cs`.

## 1b. THE PREFLIGHT RESULT AND ITS DIAGNOSIS (09-15, `f66449f`; CHANGELOG 09-14 (i) last three bullets)
- 23/24 exit 0, port rel 1.5e-11…3.5e-11, 0.48–0.55 s/eval on cs734/735/737 (id 0 on cs670 0.96) ⇒ a 6000-eval restart ≈ 50 min of the 300-min budget.
- id 1 (the only task that tests the INCUMBENT target): Torch −2666.7197790059 vs Mac −2666.7197215373 → rel 2.16e-8 > 1e-8, `stop()`.
- Tests run (Mac AND Torch, `calibration/diag_port_gate_id1_20260914.R`): substeps 4 on both; Newton 6 iterations with the identical
  residual history on both; Torch self-reproduces to 1e-14 ⇒ NO discrete flip. Roundoff-scale perturbation (u·(1±1e-12)) moves the
  logpost by max 3.5e-5 (Mac) / 8.7e-5 (Torch) at the incumbent vs 2e-6 / 6e-6 at the other two points — FLAT across ε 1e-12…1e-8
  (a floor). Carried by the δ¹³C level rows (MLO 2.5e-5, SPO 1.2e-5); the periodic spinup STATE moves ≤ 3e-11 (not the source).
  WHY this point is 20–40× noisier is OPEN.
- ⇒ the gate's fixed 1e-8 (2.7e-5 absolute here) is below the objective's measured floor at that point. RULING OWED: (A, recommended)
  measure the floor at the reference point in the driver and gate on max(1e-8·|tgt|, 3×floor) with a ~1e-6 relative ceiling,
  mutation-tested against a real break (nuclear14c absent); (B) re-rule the incumbent reference; (C) raise MS_EVAL_TOL — no.
- After the ruling: patch driver → re-ship (make_bundle → scp → extract) → re-run the preflight for id 1 only
  (`--array=1`) → then the wave (§3). `port_targets.csv` needs NO regeneration (the targets are right; the tolerance is the question).

## 2. STATE ON TORCH (check first)
```
ssh torch 'sacct -j 17818291 -X --noheader -o JobID,State,ExitCode,Elapsed,NodeList -P; squeue -u ms17839'
ssh torch 'grep -h -E "port|PER-EVAL|LAUNCHABLE|FAIL|Error" /scratch/ms17839/CarbonCycleEmulator/logs/ccx_multistart_17818291_*.out | head -60'
```
Expected when done: 24/24 COMPLETED 0:0, each log with a port line rel < 1e-8 and a PER-EVAL line (compute nodes 0.43–0.94 s
on the cell array; size the wave's wall on THIS). ⚠ Reason it queued: `cs` had 387 pending / 1603 running and 44 nodes in maint;
PriorityTier 1000; our fairshare 0.19 after the cell wave's 108 CPU-h. This morning's jobs started in 1 s. `--exclude` is refused
by the site; `cpu_short` puts serial jobs on GPU nodes at 13–18 % of a core (measured 09-10) — stay on `cs`.

## 3. THE WAVE — SUBMITTED 09-15 as job 17839702 (24 tasks, cs, 6 h wall). Collect when `sacct -j 17839702` shows 24 COMPLETED:
```
cd /scratch/ms17839/CarbonCycleEmulator
CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1 CCX_MS_PUMP_FIELD=martin CCX_MS_PIN=ent_seas_amp_SH=0,pump_grad=314.1031,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0 sbatch --array=0-23%24 calibration/torch/multistart.sbatch
```
(Option offered to Marcus, undecided at writing: chain it now with `--dependency=afterok:17818291`.) Wall 6 h on `cs` (our
choice, no QoS cap); the cell wave's max was 5:04; the driver checkpoints per id. Outdir:
`calibration/output/multistart_20260913_eqcell_hilda_c_seasml1_martin_pin_ent_seas_amp_SH=0_pump_grad=314.1031_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452`.
After: pull the outdir to the Mac, `collect_dispersed_multistart.R`, `promote_multistart_mode.R` (carries `pump_field`), then
PE-1 kz < 4,000 with the bomb rows within 2; PE-2 gradient 233 ± 29 at export in 6.8–12.1; PE-4 δ¹³C gradient 0.40 → 0.89;
then E5 the cell re-read (compose a `hilda_eq` + batch label; none exists).

## 4. Owed / open (unchanged from 09-14 i)
- The σ-audit three; whether DESIGN §6 stands. The root `MEMORY.md` restructure. `hilda_c` carries the batch for `hilda` only.

## 5. Non-obvious state
- `port_targets.csv` is the E arm's (hilda_c/martin/4 pins); any other array must regenerate it first.
- Standing reds: GATE Q pair (`test-alpha-as`) and `test-seas-lag-split:205`. Suite last run 09-14 h2: 3349/3/2.
- `/scratch/ms17839/tmp/ccx_setup_*` dirs are the login-node R container's /tmp; trap-removed, but check for strays.
