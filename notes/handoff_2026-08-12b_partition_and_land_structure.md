# Handoff — CarbonCycleEmulator, 2026-08-12 (b)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`.
Supersedes `handoff_2026-08-12_excess_c14_closed.md`, **whose §7 step 2 was based on a stale
fact** (see §1). Its §5 open decision is now **resolved** (§3).

**Branches.** `main` = `0b7371c`, suite **384 pass / 0 fail / 2 skip**, carries the partition
finding only. **`luc-veg-debit` = `4e589e3`, NOT MERGED**, suite **380 pass / 4 fail / 2 skip**
— four red tests with **three distinct causes**, all deliberate (§5). Everything below about the
model refers to the branch.

---

## 1. Headline — and a correction to read before doing anything

The previous handoff sent the next session to the **bomb delivery shape**, "starting at the
Part A / Part B join at 1963.04, where a 4.5× one-month step survives."

**That fact was two days out of date.** The join step was reduced **4.5× → 1.59×** on 2026-08-10
by the sub-annual rebuild, and `DATA.md` §9 plus `notes/handoff_2026-08-10b` both record what
remains as *defensible real acceleration*, not a method artefact. `Rscript
data-raw/build_bomb_c14_source.R` prints the live value. **Check a caveat against the script that
produces it before building a work plan on it** — this one survived two handoffs after being fixed.

The shape question was then re-opened on its merits, and the answer is different:

**The ¹⁴C defect is a reservoir PARTITION error, not a delivery-shape error. The land is the
culprit, and it needs a multi-pool structure — no parameter setting will do it.**

---

## 2. The partition test (`calibration/diag_bomb_partition.R`) — on `main`

Run at N&L's own citable total (**102 kmol**) the model receives the same bomb input as their
Table 4, so the partition is like-for-like and **independent of `bomb_total`**.

**Compare like with like.** `R/model.R` has no stratospheric box and the bomb source is a
*delivery rate to the troposphere*, so the model's atmosphere box **is** a troposphere and N&L's
stratosphere must come out of their atmosphere **and their total**. Scoring against
troposphere+stratosphere inflates the deficit −40 % → −54 %.

Paired bomb-only, kmol:

| | model 1975 / 1995 | N&L | rel |
|---|---|---|---|
| troposphere | 16.13 / 9.82 | 26.80 / 17.50 | **−40 % / −44 %** |
| biosphere | 32.80 / 29.88 | 21.70 / 18.90 | **+51 % / +58 %** |
| ocean | 48.73 / 63.34 | 42.10 / 60.00 | +16 % / +6 % |
| SUM delivered | 97.67 / 103.04 | 90.60 / 96.40 | +8 % / +7 % |

Model troposphere is **outside** its observational bracket (26–28, 16–18) at both years; the ocean
is **inside** its bracket (39.6–48.2, 54.0–59.0) at both.

**Two errors an order of magnitude apart.** The SUM error is +7–8 % — real, and the *ceiling* on
what a re-shaped source could ever repair. The partition error is 40–58 %, **in the same
direction at both reference years, twenty years apart**. Re-timing moves ¹⁴C between years; it
cannot move it between reservoirs. This is why `bomb_total` rails at +4.5σ.

**The land is the wrong shape, not the wrong size:** 1678 GtC against N&L's 2200 PgC — a
*smaller* pool holding *51–58 % more* bomb ¹⁴C.

The **paired** part of the LUC ¹⁴C leak is only **0.52 / 1.22 kmol**, so it does not contaminate
this test (measured in `[C]`, not assumed).

---

## 3. Marcus' two decisions, and what each cost

**(i) LUC debits the vegetation box** (commit `98c1783`). `add_source(iatm, e_luc, …)` →
`add_flux(iveg, iatm, e_luc)` in both cores. Fossil stays a source — geology *is* outside the
modelled system; LUC never was. `d13c_bio` removed from both cores and `ccx_cpp_par()`:
`add_flux` carries veg's own emergent ¹³C ratio.

**The model is now carbon-conservative and was not.** Total change 1750→2024 = **503.79 GtC**
against **504.67 GtC** cumulative fossil, residual **−0.88 GtC**. It had been creating **321.6
GtC** of land carbon from nothing, alongside the ~28 kmol of ¹⁴C.

**(ii) The land restructure** (commit `4e589e3`) — two parameters, both cores, parity 4.5e-13:

- **`npp_veg_frac` (φ)**, default 0.5 — `NPP = npp0 · [(1−φ) + φ·veg/veg0] · (1 + β ln(χ/χ₀))`.
- **`ra_ratio`**, default **0** (reproduces the previous model exactly) — `GPP = NPP·(1+ra_ratio)`
  down, `Ra = NPP·ra_ratio` back up **at veg's own ratio**.

`ra_ratio` encodes Marcus' GPP caution directly (2026-08-12): respiring carbon fixed days ago
returns the *atmosphere's* ratio and is a **null loop**; respiring from the pool returns the
*pool's* ratio and is the **ocean-gross-exchange analogue**. It is the fraction of GPP that
cycles **through the pool**, and his two regimes are its endpoints. Leaf growth-and-decay is not
this flux — it is the veg → soil → atm cascade, lagged rather than equilibrating.

---

## 4. Three predictions tested; two of mine were wrong

`calibration/diag_land_structure.R` reproduces all of this.

**✗ "φ cannot be 1."** The decoupled algebra gives a veg coefficient `(φ·f − 1)/tau_veg`, so
`φ·f > 1` should diverge. **It does not** — φ up to **1.10 (φ·f = 1.25) is stable**, because χ is
*not exogenous*: growing veg draws CO₂ down, which lowers `f`. CO₂ @2024 falls monotonically
413.7 → 322.2 ppm across the scan; that column **is** the feedback. The false bound has been
removed from the comments in both cores. **Do not reinstate it from algebra.**

**✓ `ra_ratio` is isotopes-only.** `max|ΔCO₂| ≤ 2.3e-13 ppm`, `max|Δland C| ≤ 9.1e-13 GtC` across
`ra_ratio` ∈ [0, 1.5], while Δ¹⁴C moves. Anything above ~1e-9 there is an implementation bug.

**✗ "the GPP loop shrinks the biosphere's bomb ¹⁴C."** It **rises** at 1975 (39.74 → 44.12 across
`ra_ratio` 0 → 1.5) and the troposphere barely moves (21.04 → 21.09). **Why:** in 1975 the
atmosphere is still far above natural, so a *lagging* veg pool is still **catching up** and holds
*less* than equilibrium; equilibrating harder closes that gap **upward**. Equilibrating faster is
the wrong lever while the source is still elevated. **Marcus' caution was right.** `ra_ratio`
stays — correct physics, defaulted to 0 — but it is not what closes the partition gap.

**What the lever actually is.** N&L: 21.7 / 18.9 kmol on 2200 PgC = **0.986 / 0.859 kmol per
100 GtC**.

| tau_veg | tau_soil | bio 1975 | bio 1995 | land C 1975 | kmol/100 GtC |
|---|---|---|---|---|---|
| 10 | 25 | 39.74 | 42.55 | 2095 | 1.897 |
| 10 | 3 | 30.49 | 23.69 | 786 | 3.880 |
| 3 | 3 | 19.69 | 11.53 | 367 | 5.363 |
| 20 | 50 | 42.52 | 52.01 | 4184 | **1.016** |

Strongly **sub-linear** in pool size — a bigger, slower pool dilutes the bomb signal faster than
it accumulates it. N&L's *ratio* is reached only at a pool **twice** theirs; their *absolute
inventory* only at a pool **six times too small**. **One responsive soil pool cannot match their
carbon stock and their ¹⁴C inventory at the same time.** That is the multi-pool signature: fast
pools cycle the bomb ¹⁴C, a large slow pool holds carbon while barely seeing it.

---

## 5. The four red tests — three different causes. Do not "fix" them blind.

| test | cause | what it means |
|---|---|---|
| `test-likelihood.R:114` | LUC debit | `cost(1) = −862.4`: at `ccx_default_params()` a +1 ppm CO₂ bias now *improves* the fit |
| `test-likelihood.R:117` | LUC debit | same fixture, monotonicity |
| `test-pulse.R:112` | **φ = 0.5** | airborne fraction @20 yr = 0.402, bound 0.45–0.80 |
| `test-pulse.R:113` | **φ = 0.5** | airborne fraction @100 yr = 0.243, bound 0.30–0.60 |

**The two likelihood failures are a stale fixture, not a loophole.** The AR(1) pathology they were
written to catch has **not** returned. `ccx_default_params()`'s `beta = 0.40` now leaves CO₂
~12 ppm low. Resolving them = re-centring the defaults, which is a **decision**, not a fix.

**The two pulse failures are a physical benchmark and are more serious.** Against recalled Joos
et al. (2013) IRF values (0.59 / 0.41 at 20 / 100 yr):

| φ | AF @20 yr | AF @100 yr |
|---|---|---|
| **0.00** | **0.597** | **0.423** |
| 0.25 | 0.517 | 0.344 |
| 0.50 | 0.402 | 0.243 |

**φ = 0 reproduces Joos almost exactly.** The capacity term is doing **two jobs and only one was
asked for**: clearing reduces productivity (wanted), but it also amplifies CO₂ fertilisation on
the way up (more veg → more NPP → more veg), and that positive feedback over-drains the pulse.

None of the four has been modified or skipped, per the standing rule.

---

## 6. Re-centring `ccx_default_params()` — what it does and does not touch

Established by inspection, worth not re-deriving:

- **It does not touch the calibration.** `R/calibrate.R:126` builds from the defaults then
  overwrites every name in `CCX_PARAM_NAMES`, and **`beta` is calibrated**. Only five defaults are
  *not*: **`tau_veg`, `sst_NH`, `sst_SH`, `sst_scale`, `revelle_frozen`** — changing one of those
  *would* move the posterior. (`npp_veg_frac` and `ra_ratio` are currently in that uncalibrated
  set too.)
- **It does touch ten test files**, which use the defaults as fixture. Re-baselining them in one
  commit moves the whole regression surface at once — do it in a commit that changes nothing else.
- **It does touch the app's uncalibrated state** (`app/global.R:70`). Related bug: `app/global.R:74`
  hardcodes *"reads about 27 ppm high against the observed CO₂ record."* That string is now wrong
  in **sign as well as magnitude**. It is a label not derived from a computed value — fix it
  regardless of what happens to β.

**Recommendation: do not re-centre until the land layout is final**, or it gets done twice.

---

## 7. What to do next, in order

1. **Multi-pool land.** The minimal change that can work: split the single responsive soil pool
   into **fast** (τ ~1–3 yr, cycles bomb ¹⁴C straight back) and **slow** (τ centuries, holds
   carbon and barely sees the bomb). N&L's biosphere has four pools and 2200 PgC. Gate it on
   **both** targets at once — land carbon **and** kmol/100 GtC — because §4 shows a single pool
   trades one against the other. Re-run `diag_land_structure.R [4]` and `diag_bomb_partition.R`.
2. **Settle φ at the same time.** Options: leave φ = 0 (matches Joos, but then LUC costs no
   capacity — i.e. Marcus' request is not implemented); or clamp the capacity factor at
   `min(veg/veg0, 1)` so clearing costs capacity while growth does not add it. **The clamp was not
   implemented** because at defaults the land pool stays *above* veg0 all century, so it would be
   inert historically — whether it bites depends on a calibrated β and on the new pool layout.
3. **Then re-centre `ccx_default_params()`** (§6), in a commit that changes nothing else, recording
   every expected value that moves. Fix `app/global.R:74` here.
4. **Then one mode-find** covering the LUC debit + the new land together (~2 h at 0.047 s/eval).
   Expect **β to fall from 0.883 to ~0.25–0.30** — a scan already puts CO₂ @2020 at 413.7 ppm
   against ~414 observed for β ≈ 0.30. That β = 0.883 existed only to absorb 321.6 GtC of phantom
   carbon; **the fix removes an implausible parameter rather than breaking a good one.**
5. **Then merge `luc-veg-debit` to `main`** — and at that point **quarantine every pre-fix
   calibration output** to `calibration/output/quarantine/YYYYMMDD_luc_c14_and_carbon_leak/` with
   a `README.md`, per the standing rule. `mode_fit.rds`, `profile_bomb_total.rds` and the Hessian
   were all produced by a model that created carbon and ¹⁴C from nothing.
6. **Only then** the ocean's single ventilation timescale (previous handoff §7 step 4 — deep ocean
   ~600 yr too young, −105 ‰ vs an observed −150 to −200). The ocean row is *inside* its
   observational bracket at both reference years, so it has less leverage on ¹⁴C than the land.
7. **Then** the ocean carbon inventory (32,827 GtC vs ~38,000; DIC exactly uniform with depth;
   ¹⁴C production 382 mol/yr vs canonical ~545).
8. **Then** production MCMC: 50k × 4, gate on **R̂ < 1.05 AND ESS ≥ 400**, ~2.6 h. The app picks up
   `calibration/output/posterior_draws.rds` automatically.

---

## 8. Non-obvious state

- **`calibration/output/mode_fit.rds` is INVALID on the branch.** It was fitted to the pre-debit
  model and scores **−56,349.7** under the current one (was −2374.1). Diagnostics that load it
  still run — `diag_bomb_partition.R` deliberately **overrides its `bomb_total` to 102** — but
  **nothing from it may be quoted as a result.** Not yet quarantined because the branch is not
  merged; see §7 step 5.
- **Two older quarantine directories, not equivalent:**
  `20260811_ar1_pathology_and_solver_wall/` (18 parameters vs the current 17 — genuinely wrong)
  and `20260811b_pre_excess_c14/` (**more dangerous, it looks current**: same 17 parameters, same
  model; its `logpost` −2359.3 must not be quoted).
- `ccx_cpp_par()` now **defaults `npp_veg_frac` and `ra_ratio` to 0** if absent, so an older
  hand-built parameter list cannot reach the C++ with a missing name — which unpacks as garbage,
  not an error. `ccx_deriv()` (the R reference) has **no such guard** and will fail opaquely, the
  same pre-existing wart as `p$gamma_enso`.
- `aux$veg0 = npp0 * tau_veg` must keep matching `ccx_spinup()`'s land fixed point
  (`spinup.R:54`) exactly, or the spinup state stops being a fixed point of the derivative.
- `data/obs_excess_c14.rds` holds **both** candidate target sets; `LIK_EXCESS_C14_TARGET` picks by
  name. `LIK_EXCESS_C14_REP_FRAC = 0.15` is still the second undecided item from the previous
  handoff §6(ii) — **low stakes**: nothing changes anywhere in 0.02 ≤ rep_frac ≤ 0.20.
- Hand-transcribed manual CSVs carry their citation as a leading `#` block — read with
  `read.csv(comment.char = "#")`, **not** `fread`.
- The N&L PDF is at `~/Documents/2026/ClaudeDocs/Papers/Journal of Geophysical Research
  Atmospheres - 2006 - Naegler - Closing the global radiocarbon budget 1945 2005.pdf`;
  `pdftotext -layout` works on it.
- Everything from 2026-08-11 §8 still applies: `ccx_ll_ar1_SUPERSEDED()`, the
  `ccx_build_forcing()` flat-GMST warning, the FaIR export in `data-raw/downloads/fair_v145_ssp/`,
  the 1817 post-Tambora worst year, and the `SST_PCO2_SENSITIVITY` double-counting check open
  since 2026-08-09.

---

## 9. Commits

| branch | | |
|---|---|---|
| `main` | `0b7371c` | The ¹⁴C defect is a partition error, not a delivery-shape error |
| `luc-veg-debit` | `98c1783` | LUC debits the vegetation box; the model becomes carbon-conservative |
| `luc-veg-debit` | `4e589e3` | NPP capacity tie and a GPP/Ra loop; two predictions falsified |

New diagnostics, both runnable from the repo root:
`calibration/diag_bomb_partition.R`, `calibration/diag_land_structure.R`.

---

## 10. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-12b_partition_and_land_structure.md` and continue carbon cycle
> emulator development. Start on the branch `luc-veg-debit`.
