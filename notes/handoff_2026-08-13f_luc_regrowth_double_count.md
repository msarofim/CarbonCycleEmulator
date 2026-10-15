# Handoff — CarbonCycleEmulator, 2026-08-13 (f)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
(still **not merged**). Suite **490 pass / 4 fail / 2 skip** — the same four pre-existing
failures as 12d/13/13b/13c/13e, unchanged; this session added no tests and touched no
model code.

Supersedes nothing. It **discharges handoff 13e §0.4** — the "NEW, UNDIAGNOSED MISFIT ...
larger than the question that surfaced it and nobody has looked at it." It is now
diagnosed, and it is larger than 13e thought. 13e §§0.1–0.3 and §0.5 still apply; 13c §5's
three ocean decisions are still open and still Marcus'.

---

## 0. START HERE

1. **LAND-USE EMISSIONS HAVE AN AIRBORNE FRACTION OF 0.002 AT 100 YEARS.** The land takes
   back every tonne deforestation releases. A fossil emission is permanent in this model
   (AF 0.262 at 100 yr); an LUC emission is a transient that decays on ~37 yr. **Measured
   on a flat background with no observation and no fit involved** (§2).
2. **IT IS A REGRESSION, and it is dated.** `98c1783`, 2026-08-12, "LUC debits the
   vegetation box". Noticed 2026-08-13 as a "19th-century deficit" and mis-attributed to
   the pre-1850 LUC question, which cannot touch it.
3. **DO NOT REVERT IT.** The 2026-08-12 change was right on its own terms — `add_source()`
   created ¹⁴C ex nihilo, ~28 kmol by 1995. The transfer is carbon-conservative. What is
   missing is that **the debit must be permanent**. §4 lays out the routes; **the choice is
   Marcus'** — it changes the land's structure, on a model the expert panel just called
   correctly sized.
4. **IT IS INSIDE THE LIKELIHOOD.** Scanning β against the CO₂ record: the transfer path
   prefers **β = 0.30**, a permanent LUC prefers **β = 0.70**. **`mode_fit.rds` is not just
   stale, it is fitted to the defect.** No refit should start until this is settled — that
   is now a *third* reason the refit is blocked, and unlike the other two it is not an open
   question of judgment but a bug.
5. **IT MAKES THE δ¹³C PROBLEM WORSE, and every δ¹³C result dated 2026-08-13 was measured
   on the defective model** (§3). Land-use carbon is isotopically light, so the model has
   been running with part of its Suess forcing switched off. The ocean conclusions of
   13b/13c have to be re-measured after the fix.

**Everything here is at `ccx_default_params()`, not the mode**, and the mode is stale for
three reasons now. `calibration/diag_1900_deficit.R`, ~5 s, carries its results in its
header.

---

## 1. The clue was inside `diag_pre1850_luc.R`'s own table

Four pre-1850 LUC options spanning **0 → 74.1 GtC** of cumulative emissions land within
**0.38 ppm** of each other at 1900 — having been **6.09 ppm** apart at 1850. Fifty years
erased 94 % of a 74 GtC forcing difference, against the model's own 50-yr point IRF of
**0.397** (`diag_joos_irf.R`). Expected ≥ 10 ppm of separation at 1900; observed 0.38.

That invariance was written down on 2026-08-13 and read as *reassuring* — evidence the
pre-1850 choice did not matter much. **It was the symptom.** Suspicious uniformity is a
code path until disproven (standing rule, `~/.claude/CLAUDE.md`), and here it was.

---

## 2. The mechanism, and the test that settles it

LUC is a transfer out of the **wood** pool (`R/model.R`, `add_flux(iwod, iatm, ...)`). Wood
has a restoring fixed point, so what deforestation removes, the model **regrows**:

```
d(δW)/dt = φ(1−f)·npp0/veg0 · δW − δW/tau_wood
         = 0.5·0.4/8.6 − 1/20 = 0.02326 − 0.05 = −0.0267 /yr   →   37.4 yr
```

**THE DECISIVE TEST depends on no historical forcing, no observation and no fit.** 100 GtC
in 1760, zero-emission background, **GMST and ENSO frozen** — control flat to +0.027 ppm
over 275 yr. (Left free, a zero-emission run moves +8.34 ppm: that is the prescribed-warming
carbon-climate feedback, not drift. It nearly cancels in the difference, but freezing it
makes the control a genuine flat line, which is what the gate wants.)

| airborne fraction at lag | 10 | 25 | 50 | 100 | 150 | 264 |
|---|---|---|---|---|---|---|
| external source | 0.605 | 0.445 | 0.337 | **0.262** | 0.226 | 0.180 |
| wood transfer | 0.577 | 0.260 | 0.072 | **0.002** | −0.003 | −0.001 |
| ratio | 0.95 | 0.58 | 0.21 | **0.01** | −0.01 | −0.01 |

**Why it is structurally wrong, argued from the budget's own layout rather than from
recollection.** GCB reports **E_LUC** (bookkeeping) and **S_LAND** (the residual land sink)
as *separate* terms — `data/gcb_budget.rds` carries them as separate columns. The model's
β-fertilization uptake is the analog of S_LAND. So regrowing what E_LUC removed adds a
**second, unbudgeted land sink** on top of the one already parameterized. And whatever share
of regrowth E_LUC does or does not net out, **full recovery to the preindustrial stock is
not defensible: converted land is farmed, not left to reforest.**

### How big, over the whole record

Residual vs observations (Law Dome before 1958, MLO after), default parameters. The
"permanent" column routes `e_luc` into `e_foss` on the forcing table: **mass-exact, and
isotopically meaningless — nothing isotopic may be read off it except §3's sign check.**

| | 1900 | 1930 | 1960 | 1990 | 2010 | 2024 |
|---|---|---|---|---|---|---|
| shipped (LUC = transfer) | −6.51 | −9.08 | −4.01 | −5.65 | −5.37 | −6.02 |
| LUC permanent | +1.62 | +3.22 | +13.44 | +19.02 | +24.29 | +27.44 |

**The regrowth path accounts for 125 % of the 1900 deficit — handled permanently the model
overshoots — so this is not a missing source, and no amount of extra 19th-century LUC
fixes it.**

Cumulative partition 1750–2024 (GtC):

| | atm | land | ocean |
|---|---|---|---|
| shipped | +300.5 | **+29.4** | +169.1 |
| LUC permanent | +371.5 | +195.4 | +220.7 |
| **GCB 2025** | +311.8 | **−57.4** | +209.8 |

**The model's land is a net SINK of +29 GtC where the budget says a net SOURCE of −57.**
(GCB's own LUC is 247.5 GtC — it has no pre-1850 column — so the model burns 41.8 GtC more
than GCB inventories. Even crediting *all* of that to the land, the sign is still wrong.)

### It is in the likelihood

β scanned at fixed everything-else, scored on the CO₂ record 1850–2024:

| β | transfer: RMSE / 2024 res | permanent: RMSE / 2024 res |
|---|---|---|
| 0.30 | **4.79** / +2.64 | 17.76 / +39.51 |
| 0.38 (default) | 6.14 / −6.02 | 13.18 / +27.44 |
| 0.70 | 14.80 / −34.14 | **3.16** / −11.09 |

**The treatment biases β down by ~2.3×.** Stated with its limit: `mode_fit.rds` has
**β = 0.088**, *below* even the 0.30 the transfer path prefers here, so the LUC defect is a
**contributing** bias and not the whole story — the other 15 parameters and the δ¹³C/¹⁴C
streams are not in a 1-D scan. **Do not read this as attributing the mode.** It does mean a
refit run today would spend its freedom absorbing a bug.

---

## 3. What it did to the δ¹³C work — and the sign is the bad one

`98c1783` landed **2026-08-12**. Every δ¹³C result in this repo dated **2026-08-13** — the
oceanic Suess measurement, the "atmosphere 21–25 % too fast" headline, the conveyor's
evaluation, the re-argued `sigma_d13c` call — was measured **after** it, on a model that
gives land-use carbon back to the land. Land-use carbon is **isotopically light**, so a
large part of the model's Suess forcing has been quietly switched off since.

| atmospheric δ¹³C ‰ | 1900 | 1950 | 1980 | 2000 | 2020 |
|---|---|---|---|---|---|
| shipped | −6.814 | −7.083 | −7.850 | −8.366 | −9.023 |
| LUC permanent | −6.959 | −7.333 | −8.167 | −8.686 | −9.312 |
| difference | −0.145 | −0.250 | −0.318 | −0.320 | −0.289 |

Suess decline 1900→2020: **−2.209 ‰ shipped, −2.353 ‰ permanent — 6.5 % faster.**

**The model's decline is already ~25 % too fast. Fixing the carbon defect makes the δ¹³C
misfit worse, not better.** That is not a reason to leave the bug in; it is a reason to
expect the ocean argument to move, and to re-measure §3 of 13c before any of its
conclusions are used.

**Caveat, and it is real:** the permanent config gives LUC the *fossil* δ¹³C (−24 → −28.3)
rather than the biosphere's (~−25), and no ¹⁴C at all. **The ¹⁴C is meaningless and is not
reported.** The δ¹³C is usable for sign and rough magnitude only because the two source
values sit within ~3 ‰ of each other — it is **not** a substitute for measuring this
properly once the fix is chosen, because the regrowth limb being removed carries
photosynthetic fractionation that no external source does.

---

## 4. THE DECISION — Marcus'

The fix is not reversion. It is to make the debit **permanent**, which means the land's
equilibrium stock must fall as land is converted. Three routes, honest costs:

| route | new params | new state | notes |
|---|---|---|---|
| **A. Shrink the land's capacity by cumulative LUC** — `npp0_eff = npp0·(1−c)`, `veg0_eff = veg0·(1−c)`, `c = f_perm · cumLUC / veg0` | **1** (`f_perm`) | none — `cumLUC` is a new **forcing column**, not a state, so the C++ state dimension is untouched | Cleanest. `f_perm` is needed because E_LUC includes product and soil losses, not only standing biomass: at `f_perm = 1`, `c(2024) = 0.56` and the model would clear 56 % of global vegetation |
| **B. Two-pool LUC** — a permanent share emitted as an external source carrying the *biosphere's* isotopes, the rest as the current transfer | 1 (the share) | none | Least invasive; keeps ¹⁴C honest if the source is given the wood pool's ratios. But "an external source with the biosphere's isotopes" is the thing `98c1783` removed, re-added with a knob |
| **C. Inert cleared-land pool** — debited wood goes to a pool with no return path | 0–1 | +1 pool | Physically the most explicit; largest change to a structure the panel just endorsed |

**Route A is my recommendation** — one parameter, no new state, no change to the C++ state
dimension, and `f_perm` is a quantity with a literature range rather than a fudge. **But it
is a DESIGN.md structural change and it is Marcus' call.**

**The gate to add with whichever route** is §2's pulse pair, promoted from a diagnostic to
a test: an LUC pulse's AF at 100 yr must be a defensible fraction of the fossil pulse's,
not 0.008 of it. **Do not add it now** — it would land as a fifth suite failure.

---

## 5. Non-obvious state

- **Nothing in the model, the app, or the data changed this session.** One new file,
  `calibration/diag_1900_deficit.R`, plus CHANGELOG and this note.
- **`mode_fit.rds` now has THREE reasons to be stale**: the pre-1850 LUC forcing changed
  under it (13e §0.1), the pedagogical curves were never recomputed at it (13e §0.2), and
  it is fitted to the LUC-regrowth defect (§2 here).
- **The suite's four failures are unchanged and pre-existing** and none relates to this:
  `test-climate.R:122` (0.092 against a 0.1 threshold, marginal), `test-likelihood.R:114/117`
  (stale AR(1)-era fixture, AR(1) retired 2026-08-11), `test-mechanisms.R:32` (0.28 against
  a 0.5 threshold). **Still uninvestigated.**
- **A zero-emission run is NOT flat unless GMST and ENSO are frozen** (+8.34 ppm over
  275 yr from the carbon-climate feedback). Any future "drift" gate must freeze them or it
  is measuring the wrong thing. This is also the −10 ppm warming-feedback number in 13e §5,
  seen from the other side.
- Everything in 12d §§2–8 and §10 still applies.

## 6. Commits

| | |
|---|---|
| *(this session)* | The 1900 deficit diagnosed: land-use carbon has an airborne fraction of zero |

## 7. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-13f_luc_regrowth_double_count.md`, then
> `notes/handoff_2026-08-13e_marcus_directives.md` for the rest of the open state, on branch
> `luc-veg-debit`. **Land-use emissions have an airborne fraction of 0.002 at 100 years —
> a regression from `98c1783` (2026-08-12) — so `mode_fit.rds` is fitted to a bug and no
> refit should start.** Four decisions are Marcus': `sigma_d13c`, the deep-Δ¹⁴C target for a
> bipolar ocean, which new likelihood terms to adopt, and now **how to make the LUC debit
> permanent** (§4, route A recommended). Fixing the LUC defect makes the δ¹³C misfit ~6.5 %
> worse, so the ocean conclusions of 13b/13c must be re-measured after it, not before.
