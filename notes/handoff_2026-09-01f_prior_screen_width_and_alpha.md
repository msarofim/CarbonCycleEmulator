# Handoff — CarbonCycleEmulator, 2026-09-01f
# **THE TWO OWED FIXES ARE PAID. THE PRIOR SCREEN IS DONE AT BOTH CLUSTER REPS.**
# **AND MEASURING THE `sst_seas_amp` WIDTH MADE THE FLAG *BIGGER*, NOT SMALLER —
# −4.71 → −12.2. The judgement width was GENEROUS to the fit.**
# **NEXT: the SEASONAL FLUX re-pricing (§4) and `alpha_as_up` (§5). NOTHING ADOPTED.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at **`023a2c9`**.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use
`git -C <abspath>`.

**Reads before this one:** `handoff_2026-09-01e_torch_survey_result.md` (the survey that produced
the mode). Memory: `INDEX_ccx_seas.md` **first** — §4 and §5 below are both inside that arc and
neither is answerable from the root index's one-liner.
**Suite 1365 / 6 FAIL / 2 skip**, the same six, unchanged by everything here.

---

## 0. STATE IN EIGHT LINES

1. ✅ **Both 09-01e §5 fixes are paid** (`c4bd650`), mutation-tested, no round-1 number moved. §1
2. ✅ **The prior screen ran at BOTH cluster representatives** (`900f90b`) and they are the SAME
   screen — max |B−A| = **0.02**. The `h_ml` micro-split costs nothing. §2
3. ⭐ **THE LAND HALF OF THE SEASONAL-AMPLITUDE PROBLEM HAS CLOSED.** Both `seas_T_amp_*` are now
   INSIDE their measured brackets; the 08-27 "NH at 131 % of the high end, SH at 29 % of the low
   end" no longer holds. §2
4. ⛔ **THE OCEAN HALF HAS NOT, AND MEASURING ITS WIDTH MADE IT WORSE** (`023a2c9`).
   `sst_seas_amp_SH` −4.71 → **−12.2** under the measured bracket. §3
5. ⛔ **THE ENSO SPLIT MOVED NOTHING IN THE SCREEN** — every parameter within 0.08 of the 08-31e
   basin; the four new coordinates sit at |z| ≤ 0.68. §2
6. ⚠ **TWO SEASONAL OCEAN MECHANISMS ARE IMPLEMENTED AND BOTH ARE OFF AT THE MODE.** §4
7. ⇒ **NEXT CHECK 1: re-price the 08-27q 2×2 verdict**, which was measured against an SH land limb
   that has since moved. §4
8. ⇒ **NEXT CHECK 2: `alpha_as_up`** — preindustrial isotopic ratios, and the temperature
   dependence, anchored on α → 1 at the boiling point (Marcus). §5

---

## 1. ✅ THE TWO OWED FIXES (`c4bd650`)

**1a. The clobbered `PROJ`.** Torch's `~/.bashrc` exports `PROJ=/scratch/ms17839/SLR-RFF-BRICK`;
`multistart.sbatch` set `PROJ`, `cd`-ed, sourced the rc, and only then built `CCX_MS_OUTDIR` from
it — so round 1's ten files landed in another project's tree with nothing erroring. ⚠ **The `cd`
was correct only because it happened to precede the source.** Three structural fixes, not a
re-ordering: renamed **`CCX_PROJ_DIR`**; **`readonly`** so a clobber is a hard error; outdir
computed **before** the source and **asserted** under the project **after** it, with a
`CCX_MS_OUTDIR_EXTERNAL=1` escape and an idempotent re-`cd`. Mutation-tested in all three states.
`setup_torch.sh` got the same rename — no live bug there, but the shape next door is how the class
returns. Memory: [[sourced_rc_clobbers_your_name]].

**1b. The collector's verdict bound.** Was `1e-8` — right for the PORT GATE's *evaluation identity*,
wrong for comparing two *optimiser outputs*; it printed "did NOT reach" for **−0.0000**. Now keyed
to the driver's own `MS_CYCLE_TOL`, **recorded** by the driver (`cycle_tol`, `restart_tol` in every
`start_*.rds`) and **read** by the collector, printed with the verdict, hard-erroring on
disagreement. Absence asserts: a directory mixing pre- and post-fix files names the ids that carry
no opinion. Six states mutation-tested. Memory: [[gate_bound_matches_its_claim]] (third instance).

---

## 2. ✅ THE PRIOR SCREEN (`900f90b`) — `calibration/diag_prior_screen_enso25.R`

**Representatives are the best CONVERGED member of each micro-cluster: ids 0 and 5.**
⚠ **Three of the ten starts are `out_of_time` — ids 3, 7, 8 — and ids 3 and 7 are the two BEST
logposts overall.** So "1 DISTINCT BASIN" was computed over SEVEN starts, not ten, and the
collector's benchmark and best-dispersed are both non-converged points. (Inert under the new 0.5
bound. It also means round 2's stated purpose — resuming timed-out tasks — *does* have targets;
they simply timed out AT the answer, within 0.0022 of the converged ones.)

**The instrument had to change before the answer meant anything.** `SST_SEAS_LOGSD` = 0.25 and
`NPP_FRAC_NH_SD` = 0.04 are widths `R/calibrate.R` itself labels as JUDGEMENTS; `seas_T_amp_*` get
`ccx_bracket_lnorm()`, a MEASURED ambiguity. Sorting them together ranks an invented width above a
measured one. Every z now prints its provenance — **BRACKET / JUDGEMENT / UNLABELLED**, where
UNLABELLED means *the code does not say*, not *measured* — derived by deparsing each prior closure.

| | from90 (08-27) | now | width |
|---|---|---|---|
| `seas_T_amp_SH` | −4.64, 29 % of bracket LOW end | **−0.64, INSIDE [3.59, 7.10]** | BRACKET |
| `seas_T_amp_NH` | +2.20, 131 % of bracket HIGH end | **+0.29, INSIDE [11.4, 17.9]** | BRACKET |
| `sst_seas_amp_SH` | −6.32, ratio 0.21 | −4.71, ratio **0.308** | JUDGEMENT |
| `sst_seas_amp_NH` | −3.48, ratio 0.42 | −2.95, ratio **0.478** | JUDGEMENT |
| `npp_frac_NH` | +1.25 | **−2.28** (crossed zero AGAIN) | JUDGEMENT |
| `q10` | −2.26 | −2.64 | UNLABELLED |

⭐ **The two MEASURED-bracket parameters are both inside their brackets.** The remaining two worst
flags are the two whose width nobody measured — which is what §3 went after.

**Gates that earned their place.** Stored `prior_z` is recomputed from `par_mode` under today's
table: both reps agree to **1e-11**. The ancestor comparison is gated per parameter on the same
recompute, and it FIRES — `kz`'s prior has moved against all three ancestors, `h_ml`'s against
from90 — so those rows are excluded rather than compared. My recomputation reproduces the 08-27
memory table exactly (−6.32, −4.64, −3.48, +3.38, +1.25), which validates memory and script against
each other.

⚠ **ATTRIBUTION IS BLOCKED BY A CONFOUND, and the file says so.** Everything moves in the
08-30 → 08-31e column, and that column moves **two things at once**: the `seas_lag_p` split AND the
basin. The only post-lag-split ancestor on disk is also the new basin. So this does **not** show the
lag split did it, which is what `INDEX_ccx_seas` predicted. Separating them needs a lag-split refit
in the OLD basin, which does not exist.

⛔ **The ENSO split moved nothing**: every parameter within 0.08 of the 08-31e basin. The four
coordinates sit at |z| ≤ 0.68 against N(0, 2) — not running to the prior, not relieving anything.
⚠ Their fitted values are worth a look: ocean **−0.950 (NH) / +1.187 (SH)**, strongly ANTIsymmetric,
where both seeds assumed a symmetric +0.10 or +0.326 each.

**Two errors of mine, both caught by output contradicting a label I wrote.** I labelled
`refit_20260831_seas_lag_split/` as the 22-par post-split refit from its DIRECTORY NAME — it holds a
**21-parameter vector with the scalar `seas_lag_p`**. And the attribution header was typed, then
went stale within the hour. Counts, lag/ENSO field names and the header are now READ or DERIVED.

---

## 3. ⛔ THE WIDTH IS MEASURED, AND IT GOES THE WRONG WAY (`023a2c9`)

`data-raw/build_sst_seas_amp_bracket.R`. **Marcus's constraint governs the design: the amplitude
factors are NOT true observables.** That rules out recomputing a flux-weighted number and recentring
on it as truth. What can be measured is the SPREAD across defensible weightings — the LAND pair's
idiom exactly.

Three **fixed** spatial weightings of the same ERSSTv5 climatology, 1975–2024: **AREA** cos(lat),
the incumbent anchor; **FLUX** cos(lat) × |CT2022 ocean flux|; **SOLU** cos(lat) × K0(SST) × pCO₂.
Every number is the harmonic fit **OF the weighted-mean monthly series** — never a weighted mean of
local amplitudes, because the SH hemispheric mean is a ~76 % cancellation between two limbs ~6
months apart and those are VECTORS.

| | LO | HI | implied log-sd | incumbent |
|---|---|---|---|---|
| NH | 2.2374 | 3.0813 | **0.160** | 0.25 |
| SH | 1.6577 | 2.0104 | **0.097** | 0.25 |

| | fitted | z now | z, new WIDTH | z, WIDTH + CENTRE |
|---|---|---|---|---|
| `sst_seas_amp_NH` | 1.069 | −2.95 | −4.62 | −5.62 |
| `sst_seas_amp_SH` | 0.538 | −4.71 | **−12.22** | −12.68 |

⇒ **The measured ambiguity is NARROWER than the judgement it replaces and the flux weighting moves
the anchor UP, away from the fitted value. 0.25 was GENEROUS to the fit.** The width can no longer
be the explanation for −4.71. ⚠ Replacing the WIDTH and moving the CENTRE are **two decisions**; the
second asserts something new about where a non-observable should sit and is **not taken**.
`R/constants.R` is unedited.

**A gate had to be rewritten mid-run.** I gated the finite fraction, and MPI-ULB's `pco2` returned
*"100.0 % finite, range [−999, 693]"*. ⚠ **−999 IS FINITE** — the gate passed on poisoned data.
[[fillvalue_not_applied]] reproducing itself one gate short. Every read now declares a PHYSICAL
range; a read declaring none is refused if anything sentinel-shaped is present. GATE 1 reproduces
the registry's area-weighted anchor to **1.1e-05**, reading the target from the registry.

⛔ **The month-varying flux weight is computed, reported, and EXCLUDED**: it collapses the amplitude
62 % (NH) / 84 % (SH), but the box model cannot represent the rectification a time-varying weight
implies, and |flux| carries ΔpCO₂ whose seasonality is partly the SST cycle being measured —
circular. In the log so nobody recomputes it and believes it.

⚠ **WHAT NONE OF THE THREE WEIGHTS CARRIES IS `k`.** Gas transfer goes as wind², and **no wind field
is on disk**. Same gap as §4.

---

## 4. ⇒ NEXT CHECK 1 — THE SEASONAL FLUX, AND A VERDICT THAT IS NOW OUT OF DATE

**What IS seasonal in the air-sea flux, per hemisphere** (verified in source, not recalled):
* seasonal SST → `pco2_from_dic(dic_ml, ALK, sst)`, so ΔpCO₂ and both gross limbs cycle
  (`R/model.R:1419-1423`);
* the SAME SST → `carb_constants(sst)` → `k$K0` → `gx = asx · k_w · K0` (`R/model.R:1464`), so the
  exchange COEFFICIENT is seasonal through solubility.

**What is NOT:**
* **`k_w`** — fitted (1786.6 m/yr at the mode) but a SCALAR. No wind seasonality. Same missing-`k`
  gap as §3; the two are one gap.
* `alpha_as_up` / `alpha_as_down` — constants. See §5.

**⚠ IMPLEMENTED, DEFAULTED TO ZERO, AND NOT IN THE FITTED SET** — verified against
`start_000.rds`'s 25 names:

| knob | state | what it does |
|---|---|---|
| `tau_ex_seas_amp` | default 0, NOT fitted | seasonal interhemispheric exchange; `ccx_tau_ex_rate()` returns exactly `1/tau_ex` when absent — the pre-08-31 model |
| `ent_seas_amp_SH` | default 0, NOT fitted | the SH entrainment channel, perturbing mixed-layer DIC seasonally |

[[default_off_hides_the_bug]]. ⛔ **DO NOT re-propose "switch `ent` on" as a new idea** — the arc
priced it and it was blocked: P3 FAILED (re-optimised, the fit picked `ent` = 4.16, **below** the
5–30 physical band), and 08-27q's admissible 2×2 concluded that rotating the ocean into phase
**removes** the SH cancellation and **overshoots the total by 18 %**.

⭐ **BUT THAT VERDICT WAS MEASURED AGAINST AN SH LAND LIMB AT 1.26× OBSERVED, AND THAT LIMB HAS
MOVED.** §2: `seas_T_amp_SH` is now inside its measured bracket and `seas_T_amp_NH` likewise. The
18 % overshoot was an ARITHMETIC verdict about two limbs ADDING, and one addend has changed.

⇒ **THE CHECK: re-price the 08-27q 2×2 at the current mode**, exactly as
`diag_gates_in_the_new_basin.R` re-priced the DESIGN gates when the basin moved — every gate status
was measured in the old state. Cheap, local, needs no wind field and no Torch. ⚠ Do it as a
RE-PRICING that reports the old numbers beside the new, not as a fresh 2×2 whose result would have
nothing to be compared against.

---

## 5. ⇒ NEXT CHECK 2 — `alpha_as_up`, THE PREINDUSTRIAL RATIOS, AND THE TEMPERATURE DEPENDENCE

**What it is.** `R/model.R:2023-2024`, the ¹³C fractionation on the two GROSS air-sea limbs:

```r
alpha_as_down = 1 -  2 / 1000,   # provisional, kinetic     (atm -> ocean)
alpha_as_up   = 1 - 10 / 1000,   # provisional, equilibrium (ocean -> atm)
```

Applied at `R/model.R:1469-1472`, mirrored at `src/ccx_core.cpp:477-478`. Two limbs, two alphas,
because a single net alpha cannot represent two-way exchange.

⚠ **THEY ARE NOT IN THE CONSTANTS REGISTRY.** `grep` finds no `alpha_as_*` in `R/constants.R` — they
are hardcoded literals carrying the word "provisional" without being in the provisional-constant
LEDGER that exists to track exactly this. `alpha_photo` sits on the same line and HAS a note.
**Registering them is a prerequisite, not a side task**: an unregistered constant cannot be found by
the audit that is supposed to find it.

### 5a. Preindustrial isotopic ratios — the anchor at the MEAN

At steady state with the gross limbs balanced, `F·α_down·R_atm = F·α_up·R_ml`, so

> δ_ml − δ_atm ≈ (α_down − α_up) × 1000 = (−2) − (−10) = **+8 ‰**

⇒ **The 8 ‰ GAP between the pair — not either value alone — is what sets how much heavier surface
DIC sits than the atmosphere.** With preindustrial atmospheric δ¹³C near −6.4 ‰ that puts surface
DIC near **+1.6 ‰**, which is inside the range I believe is observed (~+1.5 to +2 ‰).
⚠ **BOTH of those numbers are my RECOLLECTION and neither is a citation.** The check:

1. Take preindustrial atmospheric δ¹³C from **the project's own forcing table**, not from memory —
   `data-raw/build_calibration_data.R [5b]` already builds a per-year d13c series.
2. Take observed surface-ocean DIC δ¹³C from **GLODAPv2.2023, which is already on disk**
   (`data-raw/downloads/GLODAPv2.2023_Merged_Master_File.csv`, 894 MB) — `build_glodap_*.R` and
   `diag_alk_gradient.R` are the existing machinery. ⚠ Preindustrial ≠ modern: the Suess effect has
   moved both members of the pair, so use a correction or a depth//region where it is small, and SAY
   WHICH.
3. ⇒ If the implied +8 ‰ reproduces the observed preindustrial offset, **the pair is calibrated at
   the mean and the defect is entirely in its TEMPERATURE DEPENDENCE (5b)** — which is the outcome I
   expect and which would sharpen the question rather than settle it.

### 5b. Temperature dependence — and Marcus's anchor

⛔ **The evasion limb carries the EQUILIBRIUM fractionation, and equilibrium fractionations are
temperature-dependent — but `alpha_as_up` is a scalar with no temperature argument anywhere**
(`A.alpha_as_up` is read once in the C++). So under a seasonal SST cycle the model omits a seasonal
δ¹³C term **whose amplitude scales with `sst_seas_amp`** — sitting on the same ocean limb as §3's
two flags, and feeding `d13c_seasonal_SPO` / `d13c_seasonal_MLO`, the rows `INDEX_ccx_seas` records
as carrying the veto against the ocean amplitude. **A mechanism that is ABSENT can force a PARAMETER
to absorb its job.** That is a candidate explanation for −4.71 that has nothing to do with the prior
width §3 just measured — and §3 is the reason it matters, because the width is no longer available
as an excuse.

**⭐ MARCUS'S ANCHOR: the isotope ratio at the BOILING POINT is 1.** That is a PHYSICAL-LAW anchor,
which [[threshold_from_obs_or_law]] ranks above anything taken from another model — and above the
"≈ −0.1 ‰/°C" I recalled and could not cite. Two anchors determine a one-parameter law:

* α → 1 (ε → 0) at T_b;
* ε at ambient T, from 5a.

Take the standard form `ln α = a·(1/T − 1/T_b)`, which satisfies the boiling-point anchor by
construction. With ε(288 K) ≈ −9 ‰ and T_b = 373.15 K: a ≈ **−11.36 K**, and

> dε/dT = −a/T² × 1000 ≈ **+0.137 ‰/K** at 288 K

⚠ **AND CHECK THE ANCHOR TEMPERATURE BEFORE TRUSTING THE SLOPE — it is the whole sensitivity.** If
α → 1 at the CRITICAL point (647 K) rather than the boiling point, the same algebra gives
**+0.056 ‰/K**, a factor of **2.4** difference. Marcus's anchor is the primary; I am flagging the
sensitivity, not disputing it.
⭐ **Corroboration, flagged as recollection:** I believe Mook gives ε(CO₂(g) − HCO₃⁻) = −9483/T +
23.89 ‰, which returns **−9.0 ‰ at 288 K**, crosses **zero at ≈ 397 K** (near boiling — independent
support for Marcus's anchor), and implies dε/dT = 9483/T² = **+0.114 ‰/K**. **FIND THE PAPER BEFORE
USING THE COEFFICIENT** — check `ClaudeDocs Papers` first ([[claudedocs_papers_folder]]).

**⚠ QUANTITATIVE PRE-CHECK BEFORE IMPLEMENTING ANYTHING.** At ~0.114–0.137 ‰/K and an SH seasonal
SST half-amplitude of ~1.75 K, the seasonal swing in ε is ~±0.20–0.24 ‰. **That is NOT the
atmospheric signal** — it acts only on the evasion limb and is diluted by the gross-flux ratio and
by the atmosphere's inventory. **Compute the expected atmospheric δ¹³C seasonal amplitude from first
principles and compare it to the observed SPO/MLO seasonal δ¹³C amplitudes BEFORE writing the term.**
If it comes out two orders below the observable, the term is real physics and still not the
explanation — and that is worth knowing in an afternoon rather than after a refit.

**⚠ AND IT IS A DEFAULT-OFF MECHANISM WHEN IT LANDS.** Ship it with an explicit non-zero test, a
behaviour-preserving default that reproduces the current model BIT FOR BIT at zero, and the
migration contract from [[split_name_must_hard_error]] / [[default_off_hides_the_bug]].

---

## 6. ⚠ NON-OBVIOUS STATE

* **The round-1 survey files are now LOCAL and committed**:
  `calibration/output/multistart_20260901_enso25/` (10 `start_*.rds`, 10 checkpoints,
  `summary.csv`), rsynced from `/scratch/ms17839/…` on 2026-09-01. No need to go back to Torch for
  the screen.
* **Torch was reachable this session** — the ControlMaster was live and `ssh torch` worked with no
  re-auth. Submission remains Marcus's call.
* `data-raw/downloads/sst_seas_amp_bracket.rds` holds every weighting, the bracket, and the
  climatologies. Not wired into anything.
* **`R/constants.R` and `CCX_MODE_CANONICAL` are UNTOUCHED.** Nothing in this session adopts.
* The §3 builder reads a **523 MB** NetCDF (`CT2022.flux1x1-monthly.nc`); the full run is ~90 s.
* Both 22-parameter intermediates used by the screen are on disk;
  **`refit_20260831_seas_lag_split/` does NOT contain a lag-split vector** — see §2.

---

## 7. WHAT LANDED

`c4bd650` the two owed fixes + mutation tests; `900f90b` the prior screen, the survey files, and
`calibration/output/prior_screen_20260901/`; `023a2c9` the width measurement and its log.

**Memory:** [[sourced_rc_clobbers_your_name]] (new), [[gate_bound_matches_its_claim]] (third
instance appended), plus the §2/§3 findings recorded this session.

**⚠ The root `MEMORY.md` is at ~14.3 KB against a 12 KB soft budget** (hard 18 KB). Over soft = merge
when convenient. A consolidation pass is owed and is Marcus's call to direct.
