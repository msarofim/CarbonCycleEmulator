# Handoff — 2026-09-23 (a). **T1 and T2 are BOTH DONE and neither points at a labelling fix. The products move sub-σ but move TWO FAILING GATES toward their observations; and the offset is held by TWO PARTIALLY REDUNDANT anchors whose stated weighting UNDERSTATES them — arm A refuted its own hypothesis and inverted (3.06×, not a collapse). R2 is now waiting on one thing only: T4, which needs the objective change.**

> Self-contained for this session. **Read first, in this order:** handoff **(q)** 09-22 (the marine
> arm + T3, which set this menu) · CHANGELOG **09-23 (a)** and **(b)** ·
> `outputs/diagnostics/rep_dc_product_ladder_20260923/` · `outputs/diagnostics/rep_dc_release_test_20260923/`
> · `outputs/quarantine/20260923_t2_infeasible_guard/README.md`.
> ⚠ `~/.claude/CLAUDE.md` execution rules apply. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY — read
> `INDEX_ccx_ref.md` before answering anything about `rep_dC`, N5 or the app.

## 1. The model is untouched, a fifth time
`v1.0-hilda29l` at `3d1b0c0` is still the tag. **No model code, objective, mode file, parameter or
prior was modified.** Everything here is `calibration/`, two artifact directories, one quarantine
directory and `CHANGELOG.md`. Commits `3edcd33` · `1c88049` · `422e473` · `93dc266` · `657aed5` ·
`62ac59b` · `5348228` · `93b91a1`.

## 2. T1 — the product ladder. **The products MOVE.**
`calibration/diag_rep_dc_product_ladder.R` + `lib_rep_dc_ladder_report.R`; 12 jobs, all `conv 0`.
`rep_dC` HARD-PINNED at 9 rungs **3.516 → −0.215**, the other **28 names fully re-optimised** at each.

- ⭐ **THE LADDER SPANS BOTH CANDIDATE TARGETS ON PURPOSE.** The menu predates T3 and said
  "3.52 → 0.78"; T3 moved the target to the mass-weighted **−0.215**. Which is right IS the ruling,
  so the ladder covers **+0.776** (measured offset) *and* **−0.215** rather than pre-empting it.
- ⭐⭐ **THE NOISE FLOOR IS ZERO — MEASURED, THEN DISPROVED AS AN ARTEFACT.** Three replicates
  started **156 log-units away** and all returned to **−1425.3620 exactly**, within **1.9e-3** in
  parameter space. All-zero is the suspicious-uniformity signature, so it was checked: the
  replicates took **122.6 / 128.8 / 123.0 min** against the canonical's **44.6**. They travelled.
- ⛔ **WHICH MAKES `/floor` DEGENERATE — ratios of 135–6317 say "the floor is zero", not "6317 σ".
  READ `/obs sigma`.**
- ⭐⭐⭐ **EVERY PRODUCT WITH AN OBSERVATIONAL σ MOVES SUB-σ**: CO₂ gradient **0.91 σ**, gate D
  asymmetry **0.46 σ**, δ¹³C gradient **0.24 σ**, 1000-yr partition **0.05–0.13 σ**. In absolute
  terms **IRF(100) +6.0 %** (0.2833 → 0.3005), 1000-yr land share **−1.81 pts** (33.53 → 31.72),
  land sink **3.091 → 2.959** GtC/yr. ⚠ **Airborne fraction does not care: +0.2 %.**
- ⭐⭐ **THE DIRECTION IS THE FINDING.** Releasing `rep_dC` moves **gate D** (z −6.60 → **−6.14**)
  and **gate GL** (z −10.03 → **−8.26**) **TOWARD their observations**; both still FAIL. The strain
  `rep_dC` absorbs is partly the strain those gates report ⇒ **R2 is NOT a pure labelling decision.**
- ⛔ **`co2_pi` AND `part1000_close` ARE IDENTITIES, NOT PRODUCTS** — the spinup is *solved* to
  `CO2_PI_PPM`, and the closure is the partition's own mass residual. Both read exactly 0.0000
  movement against an exactly 0.0000 floor. They are reported under CHECKS; **never count them as
  evidence of flatness.**

## 3. T2 — the release test. **Both holders release it, and arm A INVERTED.**
`calibration/diag_rep_dc_release_test.R` + `lib_rep_dc_release_report.R`; 16 jobs, every arm with a
measured floor (shipped 0.000, `ice_sigma` 0.375, `ice_dropped` 0.000, `bomb_dropped` 0.000).

| arm | at +0.776 | at −0.215 | share of the cost |
|---|---|---|---|
| shipped | −50.89 | −95.71 | — |
| `ice_sigma` | −155.58 (**3.06×**) | −294.13 (**3.07×**) | — |
| `ice_dropped` | −16.30 (**0.32×**) | −39.29 (**0.41×**) | 68.0 % / 58.9 % |
| `bomb_dropped` | −11.82 (**0.23×**) | −33.38 (**0.35×**) | 76.8 % / 65.1 % |

- ⛔⛔ **ARM A REFUTES ITS OWN HYPOTHESIS.** The menu said *"if the cost collapses at the measured
  ice σ, `rep_dC` is standing in for a MIS-SET ICE WEIGHT."* **It triples.** Re-weighting from the
  stated **median 4.100 ppm** to the **re-measured 1.055 ppm** makes each residual ~15× heavier ⇒
  **the stated σ UNDERSTATES how hard the anchor demands the offset.** A correctly weighted ice term
  would make `rep_dC` **more** load-bearing.
  ⭐ The σ was **RE-MEASURED, not quoted**: ice−SPO overlap, **n = 47**, 1962–96, scatter **1.055**,
  bias **−0.307** — independently reproducing both numbers in handoff 08-23 (which is our own note,
  not a citation). The driver **refuses to run arm A** if the two ever disagree by > 0.35 ppm.
- ⭐⭐ **THE TWO HOLDERS ARE PARTIALLY REDUNDANT.** The shares **sum to 145 % and 124 %** ⇒ ice and
  bomb constrain overlapping directions and pull `rep_dC` the same way. **Neither is "the" cause and
  the shares MUST NOT BE ADDED.**
- ⛔⛔ **THE TWO COLLAPSES DIFFER IN KIND — and this is the part that matters for the ruling.** For
  the drop arms `attr(, "loglik")` passes through UNCHANGED from the shipped objective, so it is
  directly comparable. At its canonical rung **`ice_dropped` sits −3.6** from the shipped optimum;
  **`bomb_dropped` sits −3996.2**, *entirely* in its two dropped rows (`d14c_SH` −2134.4, `d14c_NH`
  −1870.7; every other stream within ±6). The bomb arm has not become a different model — it has let
  the ¹⁴C directions **run free because nothing scores them**. **Its collapse is priced on a model
  whose ¹⁴C behaviour is unconstrained; the ice arm's is not.**
  ⚠ **`ice_sigma`'s loglik is on its OWN modified σ and is NOT comparable to either.**
- ⭐⭐ **A STREAM'S DEBIT UNDERSTATES ITS HOLD.** T1's decomposition charged the ice **56 %** and the
  bomb pair **41 %**; the release test gives **59 %** and **65 %**. The ice agrees; the bomb nearly
  doubles — **because releasing a row also frees the parameters it was constraining**, which a
  per-stream debit cannot see. ⇒ **read a release test, not a decomposition**, for "what holds this up".

## 4. WHERE R2 STANDS, and what is left
**Nothing is adopted and R2 is still a ruling.** What has changed is that three of the four menu
items are now measured and **none of them supports a labelling fix**:

- **T3 (09-22 aa)** — the mass-weighting term makes the residue **36 % LARGER** (+2.67 → +3.62).
- **T1** — the products move, sub-σ, but **toward** two failing gates.
- **T2** — two overlapping anchors hold it, and the ice σ **understates** its own hold.

**T4 is the only one left and it is BLOCKED on the objective change:** a full refit under the
candidate prior, registered as an ARM (like `hilda32f`), scored on the 26 rows and the gates.
⛔ Freeze record **§4.1** — a ruling, then a restamp of every mode. **Nothing else in the menu can
answer "what would the model look like".**

⛔ **The standing constraint is unchanged:** >1/3 of `rep_dC`'s value is ISOTOPIC, so R2 is never a
CO₂-only ruling.

## 5. Failures this session — all four recorded, none smoothed over
1. ⛔ **An INFEASIBLE POINT IS NOT A MISSING STREAM.** The drop closure ran
   `setdiff(drop, names(NULL))` off-support and stopped **8 of 16** jobs, 65–145 min in. **Every gate
   had passed** because all evaluated only at `u0`. Fixed; **GATE INFEASIBLE** added (probes at
   `k_w`/`h_ml`/`tau_ex` +60, names *measured* to go off-support — `kz` +60 does NOT and is excluded),
   **mutation-tested** and reproduces the 8-of-16 pattern exactly. Pre-fix artifacts quarantined at
   `outputs/quarantine/20260923_t2_infeasible_guard/`.
2. ⛔ **AN `xargs` COMMAND LINE TOO LONG WROTE ZERO JOBS** while the launcher would have logged
   success. Caught by dry-running the construct with `echo` instead of `Rscript`. The launcher now
   uses a short runner (`t2_run_one.sh`) and **verifies its artifact COUNT**.
3. ⚠ **THE LAUNCHER WAS EDITED WHILE BASH WAS RUNNING IT** — bash reads incrementally too, not just
   Rscript. It **exited 2 AFTER every job had finished**; the artifacts, not the exit code, were the
   evidence. ⇒ [[never_edit_a_running_script]], extended.
4. ⚠ **THE PRE-LAUNCH CONTENTION CHECK WAS RUN AND STILL MISSED IT, THREE TIMES.** A clean `uptime`
   is a fact about the past (17 min was enough for a 4-chain MCMC to appear); grepping only
   `exec/R` is blind to julia; and at 15:42 I launched a **duplicate** T2 wave without checking
   whether the queue had already fired — it had, and its log said so. ⇒ [[eta_in_days_is_not_a_slow_run]],
   extended: **re-check in the SAME COMMAND as the launch, grep EVERY interpreter, and read your own
   queue log first.**

## 6. State to carry — non-obvious
- ⚠ **T1's artifacts were produced from a DIRTY TREE.** The driver carried uncommitted edits
  (`RPL_OUTDIR` override, the budget constant) through the whole wave, so they stamp a HEAD that
  does not fully describe them; the stamp is taken at SAVE time, which is why they name `422e473`
  rather than the `3edcd33` that was HEAD at launch. **Both drivers now record `tree_dirty`.**
- ⚠ **RUNTIMES IN BOTH SETS ARE MIXED-PROVENANCE AND MUST NOT BE QUOTED AS CLEAN-MACHINE FIGURES.**
  T1 ran contended with L32 (~53 % of a core each). T2 jobs 1–11 ran partly against
  `ic_ladrillo_vs_brick20`; jobs 12–16 ran at 75–80 %. Per-job 26–136 min.
- ⚠ **`t2_logs/job1.log` IS TRUNCATED** — the 15:42 duplicate wave clobbered it (the runner
  truncates on open) before being killed. **The RDS is the authority**, and it verifies: the
  `shipped` arm at the canonical rung reproduces **−1425.3620 / −1391.8032** exactly.
- **The app is RUNNING on `http://127.0.0.1:7788`** (HTTP 200), up since 09-22 20:27, and is
  **current** — `app/global.R` was written 31 s before it started, the mode file is unchanged since
  09-20, and the two obs products rebuilt on 09-22 are not read by the app. ⛔ Stop it via the
  process holding the RESOURCE (`lsof -nP -iTCP:7788 -sTCP:LISTEN -t`), **never `pkill -f`** on the
  runApp string — that is precisely the string-matching error that mislabelled 13 R processes today.
- ⚠ **`CarboTopeSubstack.docx` + its `~$` lock are still in the repo root.** Marcus's drafting — do
  not read, edit or commit. Untracked, left as found.
- ⚠ **`outputs/diagnostics/whole_model_scorecard_20260920_hilda29l.rds` still has an uncommitted
  modification PREDATING 09-22.** Still not touched, still not committed.
- **The SLR side ran beside this all day** (not ours, but it explains every contention note):
  **L32** 06:19→10:36 ALLDONE, **L33** 11:39→15:14 ALLDONE, then the IC comparison and
  `ic_hindcast_residuals`. ⚠ **`log_L32_bench_driver.txt` reports `ALLDONE` over TWO FAILED stages**
  (`model comparison` rc=1, `benchmark` rc=1) **and an INPUT CHECK that looks for
  `scope_slr_fairunc_draws_*_L32.csv` while the pipeline writes
  `..._L32_tap4p69K_V5p64m_tau800.csv`** — a permanent false MISSING. Flagged to Marcus, not touched.
- **Memory updated:** `ccx_rep_dc_prior` (T1 + T2 appended, description re-cut), `INDEX_ccx_ref`
  (the `rep_dC` line), `never_edit_a_running_script` (the bash variant),
  `eta_in_days_is_not_a_slow_run` (the shelf-life lesson).
