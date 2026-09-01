# Handoff — CarbonCycleEmulator, 2026-09-01e
# **THE SURVEY RAN ON TORCH AND FOUND *ONE* BASIN. −1495.795, ALL TEN STARTS.**
# **The 08-31e "two basins, +52.0 apart" was a property of the 22-PARAMETER space.**
# **NOTHING IS ADOPTED. Two code fixes are OWED and UNCOMMITTED — §5, read before the next round.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at **`8808daa`**.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use
`git -C <abspath>`.

**Reads before this one:** `handoff_2026-09-01d_torch_survey_redesign.md` (why the array had the
shape it did) and `calibration/torch/README.md`. Memory: [[ccx_one_basin_at_25_par]].
**Suite 1365 / 6 FAIL / 2 skip**, the same six.

---

## 0. STATE IN SEVEN LINES

1. ⭐ **ONE BASIN.** All 10 completed starts converge to **−1495.795**, total spread **0.0022**. §1
2. ⭐ **And they are the SAME POINT, checked** — pairwise u-distance ≤0.0005. Not different points
   sharing a value. §1
3. ⛔ **The 22-parameter two-basin structure does not exist at 25 parameters.** §2
4. ✅ **Both sub-questions answered**: ENSO seeding bought **0.0000**; the observation-implied
   partition converged to the same mode. §3
5. ⚠ **36 dispersed tasks CANCELLED by Marcus** once the answer was clear. The bound is 4 dispersed
   starts at ONE dispersion — not a proof. §4
6. ⛔ **TWO FIXES OWED AND UNCOMMITTED.** A clobbered `PROJ` wrote round 1 into the SLR-RFF-BRICK
   tree; a collector threshold prints a false verdict. §5
7. ⚠ **NOT ADOPTED**, and the prior-z screen at the mode is unexamined. §6

---

## 1. ⭐ THE RESULT

Job **16732800**, `--array=0-45%10`, `cpu_short`, 180 min budget. **10 COMPLETED, 11 CANCELLED.**

| id | start | start log-post | final |
|---|---|---|---|
| 0 | COLD hand-set init | −19,205 | **−1495.795019** |
| 1 | incumbent, migrated (unseeded control) | −1551.12 | **−1495.795019** |
| 2 | new basin, migrated (unseeded control) | −1500.05 | **−1495.795019** |
| 3 | incumbent + ocean ENSO +0.10 each | −1550.83 | **−1495.795014** |
| 4 | new basin + ocean ENSO +0.10 each | −1498.14 | **−1495.795019** |
| 5 | **observation-implied** partition | −1507.69 | **−1495.797205** |
| 6 | dispersed | −316,554 | **−1495.795019** |
| 7 | dispersed | — | **−1495.795018** |
| 8 | dispersed | −181,947 | **−1495.797219** |
| 9 | dispersed | −2,113,779 | **−1495.797216** |

**Total spread: 0.0022 log-units**, from starts spanning six orders of magnitude.

⛔ **"ALL THE SAME VALUE" IS THE SUSPICIOUS-UNIFORMITY PATTERN, SO IT WAS CHECKED RATHER THAN
BELIEVED.** The question is whether these are one point or several points sharing a value (a flat
direction / non-identifiability would produce the latter). **They are one point:**

* pairwise Euclidean distance in 25-dim `u` is **≤0.0005** within the main group {0,1,2,3,4,6,7};
* a second micro-cluster {5,8,9} sits **0.069** away — 140× the within-cluster scatter but still
  tiny against the 5.2 that separated the old basins;
* **the ONLY coordinate with meaningful spread is `h_ml`** (range 0.065 in u), then `rep_dC` (0.017)
  and `kz` (0.013). Every other coordinate agrees to 4–5 decimals.
* Collector: **1 DISTINCT BASIN**.

⇒ **The micro-split is the documented `h_ml` step-instability, reproducing.** That is corroboration
of a known pathology (the untrustworthy Laplace row), not a new defect.

## 2. ⛔ WHAT THIS DOES TO THE 08-31e READING

`ccx_two_basins_not_a_bracket` measured **two basins, +52.0 apart, a 21.53-log-unit barrier on the
straight `u`-path**. That measurement is **correct in the 22-parameter space and scope-limited to
it.** Adding the four ENSO coordinates connects them.

⇒ **A barrier on the straight `u`-path in a smaller space is not a barrier in a larger one.** Both
memory files that asserted the old structure now carry the scope limit in their **own description**
(recall surfaces descriptions, so a stale one keeps being resurfaced).

**The within-run gains are the comparable statement**: the incumbent lineage gained **55.3**, the
new-basin lineage **4.26**. ⚠ **−1495.795 is NOT comparable to −1496.01** — different parameter
count AND a different `kz` bracket. Do not quote them side by side.

⇒ This is exactly why the baseline had to be **produced by the survey**
([[ccx_survey_needs_its_own_baseline]]). Ranking anything against the imported −1496.01 would have
been meaningless.

## 3. ✅ THE TWO SUB-QUESTIONS, BOTH ANSWERED NEGATIVELY — WHICH IS THE USEFUL OUTCOME

* **ENSO seeding bought 0.0000.** Seeded and unseeded reach the same point; Nelder-Mead finds the
  ocean direction unaided within one restart, so the **+1.91 conditional advantage does not survive
  re-optimising.** ⭐ **This is measurable ONLY because ids 1/2 were kept as unseeded controls.**
  Watch the ordering flip mid-run: at restart 1 the controls led; at restart 2 the seeded led; both
  gaps were sub-log-unit. **Sub-noise differences that swap sign between restarts are noise, and
  reading a winner off either snapshot would have been wrong.**
* **The observation-implied partition (ocean +0.326 each, land ×1.734) converged to the same mode.**
  Its conditional score of **−7.72** was therefore a FROZEN-SLICE ARTIFACT — the third time this arc
  has paid for that lesson ([[ccx_gates_priced]] measured 253 log-units of it).

## 4. ⚠ WHAT THE SURVEY DOES *NOT* SHOW

**4 dispersed starts at ONE dispersion** (sd 1.0466 about the cold init). 36 more were cancelled
deliberately, on the reasoning that they would repeat the answer. That is a **bound, not a proof**
([[no_power_null]]). If a reviewer asks "could there be a better basin?", the honest answer is that
4 random starts spanning −10⁵ to −2×10⁶ all found this one, and no wider search was run.

## 5. ⛔ TWO FIXES OWED AND UNCOMMITTED — DO THESE BEFORE ANY ROUND 2

Both were diagnosed and drafted; local repo access was lost to a macOS TCC revocation before they
could be written. **Neither affects the round-1 numbers.**

### 5a. `multistart.sbatch` — a clobbered variable wrote the results into ANOTHER PROJECT'S TREE

Torch's `~/.bashrc` exports **`PROJ=/scratch/ms17839/SLR-RFF-BRICK`**. The script's order was:

```
PROJ=...CarbonCycleEmulator      # correct
cd "$PROJ"                       # correct -- the job RAN in the right repo
source ~/.bashrc                 # ⇐ SILENTLY CLOBBERS PROJ
CCX_MS_OUTDIR="${...:-$PROJ/...}"    # ⇐ now SLR-RFF-BRICK
```

Every task used the right repo, objective and port targets; only the write path was wrong. **Nothing
errored.** The logs printed the wrong path once per task, in a line nobody reads until they go
looking for outputs.

**Fix:** rename to **`CCX_PROJ_DIR`** (a script may not name a variable the environment it sources
also owns), compute `CCX_MS_OUTDIR` **before** the `source`, and **ASSERT** the outdir is under the
project (allow an explicit `CCX_MS_OUTDIR_EXTERNAL=1` escape). **An ordering that works is not an
ordering that is SAFE** — the `cd` was correct only because it happened to precede the source.

✅ **Already cleaned up**: files moved to
`/scratch/ms17839/CarbonCycleEmulator/calibration/output/multistart_20260901_enso25/`, and the two
empty directories my job created in SLR-RFF-BRICK removed with `rmdir` (which refuses a non-empty
directory, so the deletion could only succeed on genuinely empty targets). That tree is otherwise
untouched.

### 5b. `collect_dispersed_multistart.R` — a bound that does not match its claim

The verdict gates at **`1e-8`**, which is the right bound for an **evaluation identity** (port gate
a) and the wrong one for comparing two **optimiser outputs**. It printed *"4 dispersed starts did
NOT reach the best re-converged known basin"* for a difference of **−0.0000**. Key it off the
optimiser's convergence tolerance instead. ⚠ This is [[gate_bound_matches_its_claim]], reproduced by
me in the same session that cited it.

## 6. ⚠ THE OPEN DECISIONS

1. **ADOPTION.** `run_post_refit_adoption.R` refuses anything not on this parameter set. This mode
   is a converged 25-parameter optimum reached independently by ten starts — but **look at the
   prior-z screen first**: `sst_seas_amp_SH` **−4.71**, `rep_dC` **+3.60** (the known CO₂-level
   bias), `sst_seas_amp_NH` −2.95, `q10` −2.64, `npp_frac_NH` −2.28. Several parameters run well
   past their priors and none of that has been examined.
2. **RATIFY THE ENSO PRIOR** — each of the four keeps N(0, 2), widening the implied prior on the
   land TOTAL by **√2**. Still the only methodological choice open from before this session.
3. **A profile or Hessian on the four**, which turns structural identifiability into demonstrated
   precision.
4. **Whether to run a wider survey at all**, given §4.

## 7. ⚠ NON-OBVIOUS STATE, AND THE TORCH LESSONS

* **Data:** `/scratch/ms17839/CarbonCycleEmulator/calibration/output/multistart_20260901_enso25/`
  — 10 `start_*.rds`, 10 checkpoints, `summary.csv`. Checkpoints for the cancelled ids 10–19 are
  partial and harmless (the collector reads only `start_*.rds`).
* ⭐ **`Rscript -e` EATS `$` ON TORCH** [[torch_rscript_e_eats_dollar]]. The r/4.5.1 module is a
  Singularity wrapper that re-quotes argv into a **double-quoted** `bash -c`. `bp$pump_mode <- "N"`
  became `bp <- "N"`, and `setup_torch.sh` reported **`log-post at the cold init = -Inf`** — which
  reads exactly like a broken port and is not one. **The tells: 0.024 s/eval is far too FAST** (an
  early-return path, not a different answer), and R warned `Coercing LHS to a list` once per call.
  **Run R from a FILE.** `multistart.sbatch` was never at risk — it runs a script file.
* ⭐ **The QoS is the real cap** [[torch_qos_is_the_real_cap]]. `sinfo %l` says `infinite` and
  misleads: `cpu_short` is **6 h** (not the 4 h in older notes) with **`cpu=32` per user**, so `%10`
  is a choice and not the ceiling. `cs` has **no partition QoS**. ⚠ Untested — no job has run with
  `--qos`. **Round 2 could use a 6 h wall and save a round.**
* **Measured eval rate on compute nodes: 0.245–0.455 s/eval, median 0.33** — essentially the 0.37
  the design assumed, so `CCX_MS_MAXIT = 6000` stands. The **login node gave 0.808**; size on a
  job's number.
* The R container needs a writable `/tmp` bind source; on a login node export `SLURM_TMPDIR`
  yourself. `setup_torch.sh` does this and now **GATES** the cold init at 1e-8 rather than printing
  it (the −Inf was printed, read, and very nearly believed).
* **Fairshare** was 1.000000 before the run and **0.26** after — we are the only user in
  `torch_pr_1041_general`, so any usage snaps `EffectvUsage` to 1.0. Recovers with a ~7-day
  half-life. It did not delay wave one.
* ⚠ **Torch sessions die with the ControlMaster.** A denial listing `password,keyboard-interactive`
  is a dead socket, **not** the 09-01 account lockout (which offered gssapi ONLY, and cleared itself
  the same day with no ticket). One interactive `ssh torch` restores it.
* ⚠ **macOS TCC can revoke Documents/Desktop access mid-session.** Tell: `~/Documents` and
  `~/Desktop` give EPERM while `~/`, `~/.claude` and `/private/tmp` work, and a harness folder-grant
  does not help. Fix is relaunching the app (or Privacy & Security → Files and Folders), not a
  reboot.

## 8. WHAT LANDED THIS SESSION

`95b872f` survey re-design (fixed head 3→6 ids, dispersion pool fix 0.9592→1.0466, round-2-is-a-
subset), `7509f6a` handoff 09-01d, `a465577` login-node `/tmp` for the R container, `5edcea4` never
use `Rscript -e` + gate the cold init, `8808daa` preflight results recorded.

**Memory:** [[ccx_one_basin_at_25_par]] (the result), [[ccx_survey_needs_its_own_baseline]] (the
method lesson, now in `INDEX_diag`), [[torch_rscript_e_eats_dollar]], [[torch_qos_is_the_real_cap]].
A consolidation pass on 2026-09-01 rehomed the SLR/AIS and method entries out of the root, archived
the superseded 21-param refit, corrected the suite count (1275→1365) and the stacked-changes count
(FOUR→**FIVE**, the ENSO split had been missing from its own list).
