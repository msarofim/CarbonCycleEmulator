# Handoff — CarbonCycleEmulator, 2026-08-27b: §7a and §7b are DONE, §7c is HALF DONE,
# and the SEASONAL AMPLITUDES are now the model's biggest flags

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
**Nothing is running.** **Supersedes** `notes/handoff_2026-08-27_post_fix_model_quality.md`
for §7a/§7b/§7c-1/§7c-2; that file's §0–§6 (the bug, the guard, the quarantine, the refit,
the reparametrization null, the non-obvious state) all still stand and are NOT repeated here.

Detail: `notes/collect_2026-08-27_post_fix_model_quality.md`. CHANGELOG entry 2026-08-27.
Commits `aa1c5e1` (7a), `2779463` (7b), `b5d482d` (7c.1–2).

---

## 0. STATE IN SEVEN LINES

1. **§7a DONE.** `ccx_mode_file()` (`R/paths.R`) is the ONE place the canonical mode is
   named. 38 sites converted + `app/global.R`; a LINT stops the literal coming back. §1
2. **§7b DONE.** All of DESIGN §6 re-measured at `from90` and `pin90` and rewritten. §2
3. **GATE 12 NOW PASSES 2 OF 3 — the first pass at any fitted mode.** §2
4. **GATE 4's DECADAL AF TREND HAD THE WRONG SIGN AND NOW HAS THE RIGHT ONE.** §2
5. **§7c.1 DONE:** the rank-one d¹³C finding tightened **150×**, and the COMMON-MODE d¹³C
   bias is **gone** — which kills a standing design recommendation. §3
6. **§7c.2 DONE, AND IT REDIRECTS THE PHASE:** `rep_dC` is no longer the biggest flag.
   **Three SEASONAL AMPLITUDES are, and the fix INVERTED their hemispheric asymmetry.** §4
7. **THREE THINGS ARE OWED A DECISION FROM MARCUS.** §6

---

## 1. §7a — the canonical mode is named once, and three traps are now in the CODE

`CCX_MODE_CANONICAL` = `"from90"`. `ccx_mode_file(name_or_path)` resolves it;
`ccx_load_mode()` defaults to it; `tests/testthat/test-mode-file.R` lints the literal out
of `R/`, `calibration/`, `app/` with five DECLARED exemptions.

- **`N`/`D`/`ref` ERROR WITH THE REASON**, not file-not-found. The dangerous failure was
  never a missing file — that is loud — it is a diagnostic that still RESOLVES to a
  pre-fix vector and prints its numbers as current. `app/global.R` is the proof: an
  unresolvable path fails **SILENTLY** there by design.
- **`ref` is refused deliberately** — its mode file is the PRE-FIX SEED.
- **`CCX_MODE_PINNED`**, because `pin90`'s stored **−1544.50** reads HIGHER than the
  canonical **−1544.615** and is really **−1556.17** once the +11.6698 pin offset is out.

Two live-path defects surfaced only by doing it: `diag_design_gates_at_mode.R`'s τ_ex
profile read `V$N` and **crashed**, and ten sites wrapped `ccx_path()` around an
already-absolute path.

---

## 2. §7b — DESIGN §6, re-measured. THREE OF FOUR GATES MOVED.

| gate | pre-fix | **`from90`** | `pin90` | |
|---|---|---|---|---|
| 4 AF level | 0.434 | **0.413** | 0.391 | GCB 0.431 — **worse** |
| 4 decadal sd | 0.019 | **0.026** | 0.036 | obs 0.051 — still ~2× smooth |
| **4 trend/dec** | **−0.0007** | **+0.0080** | +0.0137 | obs +0.0148 — **SIGN FIXED**, r +0.41 |
| 5 NH→SH lag | 0.92 | **0.97** | 0.97 | obs 1.34 — **FAILS** |
| 5 NH peak | +33 ‰ | **+18 ‰** | +20 ‰ | overshoot **halved** |
| 5 NH e-fold | — | **15.0** | 15.1 | obs 15.5 — **PASSES** (newly reported) |
| 7 land σ | +2.12 | **+2.46** | +3.03 | **FAILS, further out** |
| 7 ocean σ | −0.64 | **−0.67** | −0.55 | **PASSES** |
| 12 TH 20/50/100 | ✗✗✗ | **✗✓✓** | ✓✓✓ | 12.14 / 24.98 / 41.11 |
| 12b tail ratio | 0.707 | 0.709 | 0.716 | Joos 0.787 |

**Gate 12b moved 0.002 while 12a went from 0-of-3 to 2-of-3.** That is exactly the
division of labor 12b was added for: 12a reads the CALIBRATION, 12b reads the STRUCTURE,
which the isotope fix did not touch. Do not read 12a's improvement as structural.

Superseded blocks are kept in `<details>`, marked not-comparable, rather than deleted.
**Withdrawn:** `diag_joos_irf.R`'s header claim that the model is "INSIDE BOTH" of Joos
§4.4.1's PI/PD ranges is false at **every** vector on disk (PI 27.4 vs 34–47; PD 43.8 vs
45–62). The ORDERING passes; the LEVELS do not.

---

## 3. §7c.1 — the rank-one finding is now an IDENTITY, and a design recommendation DIES

```
d13c level bias MLO   +0.04215 permil        two station biases, in z: +0.84 / -0.86
d13c level bias SPO   -0.04299 permil        mean:  -0.00042 permil   (pre-fix: +0.175 z)
MLO - SPO             +0.08514 permil
fitted grad_off_d13c  +0.08512 permil   <--  DIFFERENCE 0.00002 permil (was 0.003)
```

**The residual d¹³C level misfit is now PURELY ANTISYMMETRIC — a GRADIENT error, not a
level error.** ⇒ [[ccx_fit_at_mode]]'s standing recommendation — "ONE shared
representation parameter generating BOTH species' level offsets by mass balance, priored
at 1.0 ppm" — **is unmotivated. DO NOT BUILD IT.** It existed to absorb a common mode that
no longer exists. Memory updated.

All 14 streams reproduce their stored logL. Nothing is grossly misfit.

---

## 4. §7c.2 — **THIS IS THE FINDING THAT SHOULD REDIRECT THE PHASE**

`rep_dC` fell **5.566 → 3.378** prior sd. Smaller, still flagged, **and now only FOURTH.**

| param | pre-fix | **`from90`** | Δ |
|---|---|---|---|
| **`sst_seas_amp_SH`** | −4.25 | **−6.32** | **−2.07 WORSE** |
| `seas_T_amp_SH` | −3.95 | −4.64 | −0.69 |
| `sst_seas_amp_NH` | **−6.22** | −3.48 | **+2.74 RELIEVED** |
| `rep_dC` | +5.57 | +3.38 | −2.19 |
| `npp_frac_NH` | −0.97 | +1.25 | +2.21, crossed zero |

**THE FIX TRADED THE NH OCEAN-SEASONAL FLAG FOR THE SH ONE.** Priced on RATIOS, which do
not depend on a prior width:

| param | fitted | observed | ratio |
|---|---|---|---|
| `sst_seas_amp_SH` | **0.360** | 1.746 | **0.21 — 4.9× TOO SMALL** |
| `sst_seas_amp_NH` | 0.937 | 2.237 | 0.42 — 2.4× too small |
| `seas_T_amp_SH` | **1.039** | bracket 3.59–7.10 | **29 % of the LOW end** |
| `seas_T_amp_NH` | 23.46 | bracket 11.45–17.92 | **131 % of the HIGH end** |

**The fit buys its seasonal cycle by cranking NH LAND far above any observed amplitude
while pushing SH land and BOTH oceans far below.** That is [[ccx_seas_partition]]'s "too
photosynthetic" result stated in the DRIVERS rather than in the δ¹³C-per-ppm observable,
and it now has a clean hemispheric direction.

⇒ **Two of the three worst-flagged parameters in the whole 21-parameter fit are SH
seasonal amplitudes. That is independent corroboration of the previous handoff's
*untested* §7c-3 suspicion — the SH residual is the larger, and a single SH land box at an
effective latitude is the obvious suspect.** It also puts a live flag on §7d's
`alpha_as_up`/`alpha_as_down` item: two of the four amplitude flags sit on the ocean limb.

**CARRY THE CAVEAT.** `SST_SEAS_LOGSD` = 0.25 is a **stated JUDGMENT** width (DESIGN §5.2:
"no bracket for it exists"), so the ocean pair's z is partly a statement about that width —
**the RATIO is the robust half.** The land pair's width IS a measured bracket.

---

## 5. NON-OBVIOUS STATE ADDED TODAY

- **`ccx_load_mode()` now returns `md$hml_bound`.** The canonical mode file records
  `[85, 120]`; older arm files do not. Assert on it before recomputing any logpost.
- **`diag_joos_irf.R` and `diag_fit_at_mode.R` take a MODE NAME**, not `N`/`D`:
  `Rscript calibration/diag_joos_irf.R from90`. `diag_design_gates_at_mode.R` runs
  `defaults`/`from90`/`pin90` in one pass (~7 min).
- **`INDEX_ccx.md` is 18.4 KB against its stated 14 KB budget.** It was already ~16.5 KB
  before today; two lines were compacted, three added. A consolidation pass is owed.
- **`test-fluxes.R:99/100` FAIL, and they failed at `5777955` too** — verified by
  stashing. The seasonal ¹⁴C label-turnover assertions (`on$tau_flux` == `off$tau_flux`,
  and the label shortening by > 0.2 yr). **Almost certainly the isotope fix acting on
  exactly the quantity those two lines assert.** NOT touched: a previously passing test
  that now fails is a finding, not a test to edit. **This belongs in §7c.**

---

## 6. ⇒ THREE DECISIONS OWED TO MARCUS, THEN THE REST OF §7c

### 6a. Gate 7's window ends on a TRUNCATED year — drop it, or run to 2025?
Land 2015–2024 reads **3.590 (+2.46σ)** in `diag_design_gates_at_mode.R` and **3.525
(+2.33σ)** in `diag_fit_at_mode.R`. Identical to 1e-4 for 2015–2023; **0.65 GtC/yr apart
in 2024**. The run ends at 2024, so neither has a 2025 state to difference the land stock
against — one extrapolates FLAT (`approx(rule = 2)`), the other LINEARLY. **Both are wrong
for 2024, differently.** Dropping it gives 3.514 / **+2.31σ**. The verdict does not change.

### 6b. `test-fluxes.R:99/100` — diagnose, or re-baseline against the fixed model?
See §5. My reading is that the fix changed the truth those two lines assert and the test is
now measuring the OLD behavior — but that is a hypothesis, and the discipline says
diagnose before re-baselining ([[stale_fixture_repair]]).

### 6c. Does §7c-3 become the SH LAND BOX, on the strength of §4?
The previous handoff listed latitude bands / stratosphere / high-latitude mixing as Marcus's
named structural candidates on a ~1.5× target. §4 says the strain is **specifically SH and
specifically in the seasonal amplitudes**. That is a much sharper target than "the partition
is 1.5× off" — but promoting it is a scoping call, not mine.

### Then, unchanged from the previous handoff §7c–§7d
d¹³C Suess overshoot re-check; whether `gcb_land_sink` **should** be decisive (it is the
surviving objection at −7.94 and +2.46σ, and carries `LIK_LAND_SINK_INFLATE` = 3.0 plus a
known GCB closure error); `kz` railing (unchanged, 6332 against a bracket top of 6528); the
pump's `alpha13_signed` (b) case; `alpha_as_*`; the Hessian condition number; **the sampler**.
