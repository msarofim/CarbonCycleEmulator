# Handoff — CarbonCycleEmulator, 2026-08-13 (e)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
at **`20cd9cd`** (still **not merged**). Suite **490 pass / 4 fail / 2 skip** — the same
four pre-existing failures as 12d/13/13b/13c, plus 28 new assertions.

Supersedes nothing. It **discharges** the four directives Marcus gave in response to
`notes/expertpanel_2026-08-13_structure_for_pedagogy.md`. Handoff 13c's three ocean
decisions are **still open and still Marcus'**; 12d §§2–8 and §10 continue to apply.

---

## 0. START HERE

1. **`mode_fit.rds` IS STALE.** The historical forcing changed under it (pre-1850 LUC,
   §3), independently of anything to do with the conveyor. **Every "posterior mode" number
   quoted anywhere in this repo predates the emissions the model is now driven with.**
   A refit is due regardless of how the ocean decisions land.
2. **Everything measured this session is at `ccx_default_params()`, not the mode.**
   The mode has `h_ml` 179 m and `kz` 6031, both pushing toward more uptake and a shorter
   adjustment time. **Recompute the pedagogical curves at the mode before anything ships.**
3. **The three ocean decisions from 13c §5 are unchanged**: `sigma_d13c`, the deep-Δ¹⁴C
   target for a now-bipolar ocean, and whether Quay's ml Suess rate / the SHCal
   interhemispheric ¹⁴C offset become likelihood terms. **Do not start a refit until the
   deep-Δ¹⁴C target is chosen** — unless §6's biological-pump route is taken, which
   supplies a constraint that does not depend on that choice.
4. **A NEW, UNDIAGNOSED MISFIT was found in passing (§3): the model is ~6.5 ppm low at
   1900**, under *every* pre-1850 LUC option including the old one. It is larger than the
   question that surfaced it and nobody has looked at it.
5. **The MCMC has still never been run.** There is no `posterior_draws.rds`; only the MAP
   mode exists. This is the largest single gap between the repo and DESIGN §5.4, and it is
   what stands between the app and showing any uncertainty at all.

---

## 1. What this session settled

| | result |
|---|---|
| §2 | The flux trace is BUILT and is a tap inside `ccx_deriv`, not a second derivation. |
| §2 | It corrected a deliverable: turnover is **4.69 yr**, not the 4.32 the panel note reported. |
| §2 | `gamma_enso` was absent from the defaults — an R-vs-C++ divergence, now closed. |
| §3 | Pre-1850 LUC: **74.1 invented GtC → 41.8 sourced**, and **zero is excluded by the ice core**. |
| §3 | …but every option is **~6.5 ppm low at 1900**. New, unexplained. |
| §4 | Joos gate added. The model is **inside** the 5–95 % integrated-IRF range, on the low side. |
| §4 | The panel note's "decays too fast" **overstated it** and has been corrected. |
| §5 | DESIGN gains the fifth goal, tabs 5–6, appendix §7a, and the "no emissions" switch. |
| §6 | The ocean's DIC and δ¹³C are **exactly uniform with depth** — measured, and it matters. |

---

## 2. The flux trace (R1) — `R/fluxes.R`, `tests/testthat/test-fluxes.R`

`ccx_run(fluxes = TRUE)` returns monthly gross and net fluxes plus derived
`land_net` / `ocean_net` / `atm_out` / `tau_turn`. `ccx_flux_annual()` aggregates.

**The design decision that matters:** the recorder is a **tap inside `ccx_deriv`'s own**
`add_flux` / `add_source` / `add_diffusion`, so the reported fluxes are by construction the
integrated ones. `test-fluxes.R` asserts **`boxnet == dy[, "C"]` exactly** — completeness
check and a free extra conservation check in one. Edges are classified by the **reservoir
type of their endpoints**, so a flux added later is captured automatically; explicit labels
exist only where one endpoint pair carries two processes (`seas` vs GPP, `luc` vs `ra`,
`enso` vs `rh`). **`ccx_run_fast()` — the C++ core the sampler calls — is untouched**, and
`fluxes` defaults `FALSE`.

**THE NUMBER THAT CHANGED, AND WHY.** τ_turn = M_atm ÷ gross outflux = **4.69 yr (1750),
5.32 (2024)**. The panel note and `diag_pedagogy.R` originally said **4.32**, from a
one-month ¹⁴C-label slope. Seasonal NEP is a real atm→leaf flux that integrates to zero
annually, so it is **excluded from the gross outflux** — right for the annual mean, wrong
for a January finite difference, which the January drawdown biases fast. **Tested, not
argued:** with seasonality off the two independent routes agree to **0.2 %** (4.700 vs
4.692). Both facts are pinned in `test-fluxes.R`.

**GOTCHA now closed:** `gamma_enso` was **absent** from `ccx_default_params()`, so
`ccx_deriv()` died with "argument is of length zero" on default parameters while
`ccx_cpp_par()` silently substituted 0 — an **R-vs-C++ divergence about what the defaults
mean**. Now `0`, which is behavior-preserving. **Not** the table's init of 0.5: that would
have silently changed every existing default-parameter result.

**App:** `APP_FLUX` / `APP_FLUX_NOW` in `app/global.R` (~2 s at startup, R path);
`app/server.R`'s box diagram now labels every arrow and the land boxes admit to four pools.

---

## 3. Pre-1850 land-use emissions (R3)

**GCB's LUC column is empty before 1850** — verified in the raw CSV, its fossil column
starts 1750 and its LUC column does not. `approx(rule = 2)` held the 1850 value flat
backwards, **inventing 74.1 GtC across 1750–1849 — 23 % of the model's land-use carbon.**

**Replacement:** OSCAR v3.1 `E_luc`, Gasser et al. 2020 (*Biogeosciences* 17:4075,
doi:10.5194/bg-17-4075-2020; data doi:10.5281/zenodo.7313542, CC-BY), which runs from 1701
and reproduces that paper's headline **206 ± 57 PgC** for 1750–2018 exactly — the check
that the right column was read.

**Rescaled, not spliced raw.** OSCAR's 1850–2018 total is **34 % below GCB 2025's**, so
grafting absolute values on would put a **62 % step** at the join. OSCAR supplies the shape
and the pre/post share, rescaled over an **1850–1900** overlap adjacent to the splice.
**Ratio 1.518 → 41.8 GtC, 6 % step.**

**Scored, not asserted** (`calibration/diag_pre1850_luc.R`, Law Dome, 1750–1850):

| option | cum GtC | RMSE ppm | bias |
|---|---|---|---|
| flat-hold (old) | 74.1 | 2.48 | +1.58 |
| OSCAR absolute | 27.5 | 2.77 | −1.80 |
| **OSCAR scaled — adopted** | **41.8** | **2.00** | **−0.90** |
| zero | 0.0 | 4.50 | −3.53 |

**Zero is excluded by the data.** The flat-hold was not absurd — right integral, wrong
shape, too big too early (+3.8 ppm at 1775 against the adopted series' +1.0).

**THE ~6.5 ppm 1900 DEFICIT.** Every option is ~6.5 ppm below Law Dome at 1900, and none
reproduces the full 18th-century rise (Law Dome +8.44 ppm 1750→1850; best option +5.10).
**This is a separate misfit, larger than the whole pre-1850 LUC question, and untouched by
it.** Candidates not yet tested: the 19th-century LUC *level* (but GCB's is already higher
than OSCAR's, so that pushes the wrong way), the land sink strength at default `beta`, or
the ocean uptake. **Do not read the RMSE column as "the forcing is now right."**

`ccx_build_forcing()` now **warns** on any NA emissions year inside the requested window.

---

## 4. Joos et al. 2013 (R7) — DESIGN §6 gate 12, `calibration/diag_joos_irf.R`

Benchmark: ACP 13:2793–2825, doi:10.5194/acp-13-2793-2013; PDF in `ClaudeDocs/Papers/`.

**Two answers pointing different ways, and the second is the headline:**

| | 20 yr | 50 | 100 | 300 |
|---|---|---|---|---|
| point IRF, model | 0.531 | 0.397 | **0.313** | 0.212 |
| point IRF, Joos Table 5 | 0.596 | 0.487 | **0.409** | 0.322 |
| integrated IRF, model | 12.6 | 26.2 | **43.6** | — |
| integrated IRF, Joos 5–95 % | 12.2–16.3 | 24.0–36.6 | **39.5–65.2** | — |

**Inside the range at all three horizons, below the best estimate at all three.** The panel
note's flat "decays too fast" **overstated it** and has been corrected: the model is on the
*low side of the literature but within it*, which is the **conservative** direction for the
app's argument and must be stated rather than left for a reader to find.

Also reproduces Joos's **PI < PD ordering** (39.2 vs 46.3 yr against his 34–47 / 45–62) —
a Revelle result — and on **coupled** SSP backgrounds IRF@100 rises monotonically
**0.342 (ssp126) → 0.512 (ssp585)**, with IRF@20 of 0.62–0.71 against Joos's "~70 % within
two decades in every scenario".

### Three method failures, recorded because two looked correct

1. **An online controller** for Joos's diagnosed compatible emissions needs `ccx_deriv`
   inside the stepping loop: ~60k pure-R evaluations per run, minutes each, eight runs.
2. **A Newton step on the monthly drift DIVERGES** — to 2e34 ppm in 40 iterations. The step
   looks exact and is not: an emission in month *i* raises CO₂ in **every later month**, so
   the response operator is **lower-triangular, not diagonal**, and per-month correction
   compounds. **What works:** least squares on a basis of relaxation exponentials, holding
   the background to 0.26 % in 0.3 s. **A polynomial basis must NOT be added back** —
   ill-conditioned, diverges (562 → 2364 → 37221 ppm).
3. **The SSP emissions table is DECADAL.** Adding the pulse to the 2050 row let
   interpolation spread it over 2046–2054 and deliver **1000 GtC for a nominal 100**,
   giving an IRF of **6.9** — impossible by inspection, since an IRF cannot exceed 1. The
   table is now densified to annual and **the delivered mass is asserted**.
4. Separately: **`sprintf()` with a zero-length argument returns `character(0)` and `cat()`
   prints nothing**, so a mistyped field name (`r$gmst` for `r$climate$gmst`) dropped the
   entire table **silently, with exit status 0**. Guarded.

---

## 5. DESIGN and the app (R2, R4, R5, R6)

**DESIGN §1 gains a fifth scientific goal** naming the two conflations — it was the
project's original motivation and had never been written down as a specification.

**Marcus' framing, and it shapes everything:** *"concentrate on the positive learning and
not on the debunking."* So DESIGN §7 gains **tab 5 "How long does it last?"** and **tab 6
"What drives CO₂?"**, and the fallacious arguments become a **short signposting appendix
inside "Under the hood" (§7a)**, not a tab — *published claim → published response → which
panel bears on it*, naming arguments rather than characterizing people.
**NEITHER TAB IS IMPLEMENTED. The §7a wording is Marcus' call before it ships.**

**All four references verified against Crossref, not recalled.** Essenhigh (2009)
doi:10.1021/ef800581r ↔ **Cawley (2011)** doi:10.1021/ef200914u; Harde (2017)
doi:10.1016/j.gloplacha.2017.02.009 ↔ **Köhler et al. (2018)**
doi:10.1016/j.gloplacha.2017.09.015; Salby and Spencer as non-peer-reviewed links.
**Cawley (2011) is the anchor for tab 5** — its point is that a short residence time and a
long adjustment time are *both consequences of the same model*, which is exactly what the
paired ¹⁴C-label and mass pulses demonstrate here, independently and with a real ocean.
**Spencer's is the subtle one** (Marcus): not wrong arithmetic but a **fixed-equilibrium
assumption**, and this model's equilibrium point is not a parameter — it emerges from
carbonate chemistry, which the `revelle` switch already isolates.

**R2 built:** a **"no emissions"** switch. Every existing switch turned off a *sink*; none
the *source*, which made tab 6's comparison unmakeable. Over 1750–2024 it gives **−134 ppm**
(back to 285, essentially preindustrial) against the warming feedback's **−10 ppm**. Pinned
by a test in `test-mechanisms.R`.

---

## 6. THE OCEAN HAS NO VERTICAL STRUCTURE IN DIC OR δ¹³C — measured 2026-08-13

Marcus asked whether a **biological pump** would help the remaining science questions.
Measured first (`ccx_spinup()`, default parameters, NH column; SH identical in kind):

| layer | dz m | DIC µmol/kg | δ¹³C ‰ | Δ¹⁴C ‰ |
|---|---|---|---|---|
| ml | 75 | 1986.3 | +1.560 | −51.2 |
| oc1 | 52 | 1986.3 | +1.560 | −56.0 |
| … | … | **1986.3** | **+1.560** | … |
| oc10 | 1073 | 1986.3 | +1.560 | −187.1 |

**DIC and δ¹³C are EXACTLY uniform through 3700 m. Only Δ¹⁴C has a gradient** — because
that one is built by decay plus diffusion, and needs no biology.

**1986 µmol/kg is a realistic SURFACE value applied to the whole ocean.** Total ocean
carbon 32,827 GtC. To reach the ~38,000 GtC canonical figure the model would need a
volume-weighted mean DIC of **2299 µmol/kg** — i.e. **the ~14 % inventory deficit and the
missing vertical DIC gradient are the same number**, and that number is the soft-tissue
pump. *(Deep-ocean observed values here are recollection, not a checked source — GLODAPv2
would be the one to pull. The 2299 figure is the model's own arithmetic and is solid.)*

**The δ¹³C result is new and was not on anyone's list:** the model's deep ocean is
**~1–1.5 ‰ too enriched** in DIC δ¹³C, in the tracer this project has spent a fortnight
fighting. Nothing has ever scored it.

**What follows structurally, and it constrains what a pump could do here.** The model's
interior carries **no carbonate chemistry at all** — `pco2_from_dic()` is called only for
the mixed layer, and the interior boxes are pure tracer reservoirs. And in steady state the
mixed layer's DIC is **chemistry-pinned**: given ALK, SST and pCO₂ = the spinup's 276.88
ppm target, DIC_ml is determined. **So a pump cannot change surface DIC, cannot change the
Revelle factor, and cannot change the IRF to first order. It changes the interior, and the
interior reaches the atmosphere only through what ventilation brings back up.**

**Hence the real conclusion: a pump alone is mostly bookkeeping; a pump plus a return path
is a mechanism.** See §7 for the ordering.

---

## 7. Where this leaves the open questions

| open question | pump alone | pump + conveyor | note |
|---|---|---|---|
| ocean inventory ~14 % low | **fixes it** | fixes it | arithmetic above is exact |
| deep δ¹³C ~1–1.5 ‰ too enriched | **fixes it** | fixes it | new; currently unscored |
| `kz` = 9× NATRE / deep age bounded not derived | no | **yes — a NEW independent constraint** | see below |
| atmospheric δ¹³C 21–25 % too fast | unlikely alone | **plausible, direction UNTESTED** | do not assert a sign |
| MLO−SPO δ¹³C 3× too large | no | only if the pump is hemispherically asymmetric | speculative |
| ~6.5 ppm low at 1900 | no route | no route | diagnose on its own |
| point IRF low vs Joos | no — interior has no chemistry | no | would need interior carbonate chemistry |

**The prize is the third row.** The observed surface-to-deep DIC gradient (~300 µmol/kg)
and δ¹³C gradient (~1–1.5 ‰) are **currently exactly zero in the model and therefore
entirely unused as constraints.** A pump turns both into observables. And because a pump's
gradient is set by **export ÷ ventilation**, those observables constrain ventilation
*directly* — which is exactly what handoff 13c §5 says the refit needs and cannot get,
**and it does not depend on choosing a deep-Δ¹⁴C target first.** That makes it a candidate
route *around* blocking decision #2 rather than through it.

**The honest costs.** +2 parameters at least (export production, remineralization depth
scale) on top of the conveyor's Q, against a panel that has just concluded the model is at
the right complexity. A pump also injects surface-¹⁴C carbon into the deep non-locally,
which makes the deep **younger** — working *against* the deep-age constraint, magnitude
unmeasured. **And nothing here is measured: §6's table is, §7's rows are not.**

**Pedagogically the pump passes the test the conveyor failed.** "Plankton grow at the
surface, die, and sink, which is why the deep ocean is rich in carbon and the surface is
poor" is one sentence, is famous, and explains the 50× ocean:atmosphere stock ratio the app
already displays. The conveyor bought nothing a student would see (panel §2); this would.

---

## 8. Non-obvious state

- **`mode_fit.rds` predates the forcing.** See §0.1.
- **`data/forcing_emissions_historical.rds` changed.** Anything cached against it is stale.
- **`data-raw/downloads/oscar_gcb2020_eluc.xlsx` is tracked**, and
  `build_calibration_data.R` now needs **`readxl`**.
- **`ccx_default_params()` gained `gamma_enso = 0`.** Behavior-preserving; see §2.
- **`ccx_run()` gained `fluxes = FALSE`; `ccx_deriv()` gained `record = FALSE`.**
  `add_flux()` gained `lab = NULL`. All default to the old behavior.
- **`ccx_run(fluxes = TRUE)` is the PURE-R path and is slow** (~60k deriv calls over
  275 yr). Fine for a diagnostic or app startup, **never** in a sampler loop.
- `calibration/diag_joos_irf.R` defines `ccx_hold_forcing()`, `ccx_pulse_state()`,
  `ccx_irf()` and `ccx_set_emissions()` **locally**. If a second file needs them they
  should move to `R/`, not be copied.
- The four suite failures are **unchanged and pre-existing**: `test-climate.R:122`
  (carbon-climate feedback on GMST at 2100, 0.092 against a 0.1 threshold — **marginal,
  looks like a threshold to re-derive rather than a bug**), `test-likelihood.R:114/117`
  (**stale AR(1)-era fixture**; AR(1) was retired 2026-08-11), `test-mechanisms.R:32`
  (ENSO switch moves CO₂ 0.28 ppm against a 0.5 threshold). **None investigated.**
- Everything in 12d §10 still applies.

## 9. Commits

| | |
|---|---|
| `3040dad` | Expert panel: the pedagogical spec, and the structure it actually demands |
| `636dfd0` | The flux trace: the gross fluxes the model already computed, made readable |
| `c40a567` | Pre-1850 land-use emissions, sourced: 74.1 invented GtC replaced by 41.8 |
| `63800fe` | Joos et al. 2013 IRF: a pulse-response gate, and pulses on future backgrounds |
| `20cd9cd` | DESIGN: the fifth goal, the two learning tabs, and the "no emissions" switch |

## 10. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-13e_marcus_directives.md`, then
> `notes/expertpanel_2026-08-13_structure_for_pedagogy.md` for the structural argument and
> `notes/handoff_2026-08-13c_conveyor_built.md` §5 for the three open ocean decisions, on
> branch `luc-veg-debit`. **`mode_fit.rds` is stale — the historical forcing changed under
> it — so a refit is due regardless of the ocean questions.** Three decisions remain
> Marcus': `sigma_d13c`, the deep-Δ¹⁴C target, and which new likelihood terms to adopt;
> a fourth is now live — **whether to add a biological pump** (§6–7), which would supply a
> ventilation constraint that does *not* require the deep-Δ¹⁴C target to be settled first.
