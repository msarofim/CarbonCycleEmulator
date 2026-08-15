# Handoff — CarbonCycleEmulator, 2026-08-15: the fertilisation form changed, and both failing gates now pass

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit` at
**`0cd9fbb`**, still **not merged**. Working tree clean. Suite **8 fail** (was 11).
Tag `checkpoint/pre-phase1-2026-08-13` still marks the pre-13i state.

**Supersedes `handoff_2026-08-14b_review_items_1_3_4.md`.** Its three waiting decisions were
all taken; items 2, 4 and 7 of the review's ordering are discharged, and 5c with them.
**`notes/review_2026-08-14_architecture.md` is still the authoritative statement of WHAT was
wrong and WHY — but its §0 headline is now out of date, and this note says how.**

---

## 0. START HERE

1. **The review's headline has MOVED.** It opened: *"the shipped default fails two of DESIGN
   §6's own hard gates"* (7, sinks; 12, Joos IRF). **At the MAP mode both now pass**, along
   with the Pulse Lab's Revelle lesson. §3 below. Do not quote review §0's table as current.
2. **The cause was structural, and the fix was structural.** `beta` is gone. The CO₂
   fertilisation form is now Michaelis–Menten in (`beta_max`, `fert_k`). The log form is kept
   and reachable — `p$fert_form <- CCX_FERT_LOG` — because every result before 2026-08-14 was
   produced under it.
3. **Four test failures are FLAGGED FOR MARCUS AND DELIBERATELY NOT FIXED** (§5). Three are
   stale fixtures on an improved model; one is a test whose own comment predicted it. None
   was re-baselined, because re-baselining a failing assertion is how a real regression gets
   absorbed.
4. **Three new findings are not good news** (§4): `sigma_co2` is a spectator, the ocean
   presses two parameters to implausible values, and `luc_scale` turns out to be
   near-degenerate with `fert_k`.
5. **The refit (item 8) is still NOT unblocked.** Items 5 and 5b remain. §7.

---

## 1. The three decisions, taken

| | decision | taken | consequence |
|---|---|---|---|
| 1 | deep-Δ¹⁴C σ | **10.3 ‰** (spread ÷ √n_eff, n_eff = 20); **KEEP the kz bracket** | `9c773b4` |
| 2 | β default | **flip to MM**, `fert_k` 120 | `a9d74ce` |
| 3 | `sigma_d13c` | **stays free** | no-op, recorded |

### 1.1 Decision 1 found a layer mismatch (`9c773b4`)

`data-raw/build_glodap_deep_targets.R` measured GLODAPv2 over **2627–3700 m** and asserted
that `diagnostics$d14c_deep_by_hemi` *is* that layer. **It is not** — that diagnostic takes
`tail(aux$idx[[h]]$oc, 3)`, the bottom **three** interior boxes, **1313.6–3700 m**, which runs
13.5–20.4 ‰ enriched. Scoring the target against it would have baked a ~1.6 σ mismatch
permanently into the objective.

`diagnostics$d14c_bottom_box` was added for the target. **The 3-box diagnostics are
unchanged** — the kz bracket and every earlier result came from them. **Use
`d14c_bottom_box` against anything GLODAP-derived.**

Handoff 14b §4.1's "runaway at 6.1 σ" is the mismatched pairing; like for like it is **5.3 σ**.
*The decision survives* — the σ table's verdict column is identical either way.

Measured, not assumed: the bottom box drifts **+0.01 to +0.10 ‰** over 1750→2024, so scoring
the *spinup steady state* against 1972–2021 bottle data is legitimate and the term costs no
transient integration. The term is univariate in `kz` (5.3 ‰ across the whole `h_ml` prior
against the 57 ‰ the bracket spans). Receipts: `calibration/diag_deep_d14c_term.R`.

**Why the bracket stayed, and where it and the term disagree.** On the bottom box the bracket
[3830, 6200] is a hard box of half-width **28.4 ‰** — tighter than the σ — so deleting it
would **loosen** `kz`. But it is centred **16.7 ‰ below** the sourced target: the term's own
optimum is `kz` 5525 against the shipped 5000, and it puts the bracket's lower end at −4.40 σ.
`kz` was **not** re-centred by hand.

---

## 2. The fertilisation form (`554b5c1`, `a9d74ce`)

**The defect as arithmetic.** `NPP = NPP₀(1 + β ln(χ/χ₀))` locks the *enhancement* at today's
CO₂ and the *slope* at today's CO₂ into the fixed ratio χ/χ₀. β slides along it. The CO₂
record wants 0.75; gate 12 and the Revelle lesson independently want ≤ 0.50.

**The replacement.** `CCX_FERT_MM`: `NPP = NPP₀(1 + β_max·Δχ/(K + Δχ))`, Δχ = χ − χ₀.
`beta_max` = fractional enhancement at infinite CO₂; `fert_k` = ppm above preindustrial
delivering half of it. Chosen over a bounded exponential because carboxylation **is** an
enzyme reaction — the saturation has a one-sentence undergraduate explanation.

**NOT a reparameterisation.** As `fert_k → ∞`, MM goes **linear**, not logarithmic. No
substitution carries a `beta` posterior across. Any pre-flip posterior belongs to a different
model — which is why `mode_fit.rds` was quarantined (§6).

`CCX_PARAM_TABLE`: **17 → 18**. `beta` out, `beta_max` + `fert_k` in. Both priors uniform and
wide (`beta_max` [0, 3.0], `fert_k` [20, 2000]) because **nothing in the literature set pins
either at the ECOSYSTEM scale** — leaf-level Rubisco kinetics do not transfer, and FACE
experiments and CMIP6 models disagree by more than any prior width would encode.

**The default was set by gate 12, not the likelihood**, and that is stated as a choice:
`fert_k` 120 passes Joos at all three horizons with margin, while the 1-D likelihood on the
design-target locus preferred 171, which fails. **The MAP mode then dissolved that tension —
see §3.**

---

## 3. THE MAP MODE (`58b4a03`) — the headline

`calibration/run_modefind.R`, 18 parameters, **293.6 min / 291,832 evaluations** at 0.060
s/eval. Log-post **−3774.0 → −2221.3** (gain 1552.8, of which 1532 in restart 1). Hessian
**positive-definite**, condition 6.8e5. **No parameter beyond 3 prior sds.**

| | review §0 (β 0.75) | MM default | **MAP mode** |
|---|---|---|---|
| **gate 7** land | **+4.57σ** | +2.28σ | **+1.54σ** (3.13 GtC/yr) |
| **gate 7** ocean | −2.13σ | −1.52σ | **−0.35σ** (3.08) |
| **gate 12** Joos IRF | **10.4/19.9/31.2 FAIL×3** | 12.4/25.6/41.9 | **12.6/26.0/43.0 INSIDE×3** |
| Revelle lesson | **−0.113 REVERSED** | +0.566 | **+0.515 HOLDS** |

**Gate 7 had never passed.** Paired sanity suite at the mode: zero-pulse max|ΔCO₂| **exactly
0**; sign-flip +19.78 / −18.71 ppm; halving ratio **0.4931** (correctly sublinear).

**`fert_k` 120 → 153 did NOT break gate 12.** `beta_max` moved with it (0.4913 → 0.5087), so
the marginal slope at 388 ppm went 0.0662 → **0.0669**. The fit slid *along* the decoupled
direction the log form does not have. **The likelihood-vs-gate tension recorded at the flip
was an artefact of scanning a one-parameter locus** and does not survive an 18-parameter fit.

Mode, natural scale: `beta_max` 0.5087, `fert_k` 153.1, `q10` 2.098, `k_w` 1648, `h_ml` 184.0,
`kz` 6119, `tau_ex` 0.807, `npp_frac_NH` 0.464, `seas_amp_NH` 19.66, `seas_amp_SH` 4.64,
`seas_phase_NH` 4.00, `seas_phase_SH` 11.07, `gamma_enso` 0.555, `bomb_total` 113.97,
`luc_scale` 1.0049, `sigma_co2` 0.223, `sigma_d13c` 0.336, `sigma_d14c` 5.54.

---

## 4. THREE FINDINGS THAT ARE NOT GOOD NEWS

### 4.1 `sigma_co2` is a spectator — and the framing matters

The MLO residual RMS at the mode is **0.642 ppm** and `sigma_co2` fits to **0.223** (z −2.56),
so RMS/σ = 2.88 — which *reads* like the AR(1) collapse this repo has history with. **It is
not.** The likelihood uses `sqrt(sigma_co2² + LIK_CO2_REP_ERR²)` and **`LIK_CO2_REP_ERR` is a
fixed 1.0 ppm**, giving an effective sd of 1.025 — larger than the residual it explains.
Confirmed by profile: set the constant to 0 and `sigma_co2` peaks at **0.65**, the residual
RMS to two decimals; at 1.0 it is squeezed to 0.05.

**So `sigma_co2` → 0 is the CORRECT inference, not a pathology: the model now fits CO₂ better
than the assumed station-vs-box representation error.**

*I initially called the 1.0 ppm constant "too large and needing re-deriving". The measurement
does not support that.* Co-located independent programmes at MLO disagree by **0.39–0.59 ppm
RMS** (MLO in-situ vs SIO flask, n = 702), a floor on measurement error alone; a
station-vs-hemisphere term should exceed it. **1.0 ppm is plausible.**

What is actually true, and is what the next session should act on:
- `sigma_co2` is unidentified and pinned at a boundary — it will hurt MCMC mixing and
  covariance conditioning. **Fix it or drop it; do not sample it.**
- The constant still has **no receipt**, same class as the 0.9 GtC/yr land σ corrected on
  2026-08-14.
- **Reducing it would give the CO₂ stream MORE leverage**, worsening the 40:1 imbalance the
  whole review is about. It is a stream-weight change, not housekeeping.

**Also flagged:** `MLO` and `MLO_NOAA` in `data/obs_co2_monthly.rds` agree to **0.002 ppm RMS**
over 189 months. That is not two measurements — it looks like one series under two names.
Unchecked.

### 4.2 The ocean presses two parameters to implausible values

`kz` = **6119** (96.6 % of the way up its bracket) and `h_ml` = **184.0 m** (a global-mean
mixed layer against an observed ~50–75 m). The deep-Δ¹⁴C term is overridden to get there —
the bottom box lands at −157.8 ‰, **z +1.70** against its own target.

**The cheapest competing hypothesis was tested and REFUTED.** `h_ml` is not a bound artefact:
profiling past its prior gives an **interior optimum at ~184 m**, log-post falling off on both
sides (163 → −2209.9, 184 → −2194.0, 200 → −2201.8, 260 → −2384.9, 500 → −5350.4). The
[30, 200] bound is not binding. The data genuinely want a deep mixed layer.

**`kz` bracket is demonstrably load-bearing** — without it this mode would have run `kz` away
again, which is exactly what decision 1 preserved.

**The pump case is now better motivated than review §4.2 had it — but its pre-registered test
has EXPIRED.** That test was "does the ocean sink rise from 2.63 toward 3.22?" **The sink
already lands (3.08, z −0.35).** The problem is not a sink that is too small; it is a sink
that is right for implausible reasons.

The mechanism story that fits: `k_w` is pinned to **±2 %** by bomb-¹⁴C, so the model cannot get
carbon *in* faster; to absorb more it must get carbon *down* faster, and its only levers are a
deeper mixed layer and higher `kz`. A biological pump is exactly the missing downward export.

**Two competing readings survive and the pump must be tested against them, not assumed:**
1. `h_ml` may be doing **capacity** work (a bigger surface reservoir absorbs more before its
   pCO₂ rises), not **export** work. A pump only helps in the second case. *Distinguishing
   test: hold the mixed-layer carbon inventory fixed while varying its depth.*
2. A single global column has no horizontal transport, so `h_ml` = 184 m may be emulating
   **high-latitude deep winter mixing and subduction**. If so, neither a pump nor a conveyor
   fixes it and the honest move is to document `h_ml` as an effective parameter.

**Replacement pre-registered test, if the pump is built:** *does `h_ml` relax below ~163 m and
`kz` off the top of its bracket, while the ocean sink holds near 3.1?* Not "does the sink
rise".

**The conveyor is still NO.** Falsified in-repo twice — it moves the MLO−SPO δ¹³C gradient the
wrong way (13c §2c), and reversing a closed vertical loop is provably invisible to the
atmosphere. Review §4.3: keep off, do not ship.

### 4.3 `luc_scale` is near-degenerate with `fert_k`

At the mode `luc_scale` = 1.0049, which *looks* like an unused parameter. **The point estimate
is uninformative** — for a nuisance parameter with a symmetric prior that is exactly what you
expect. The Laplace covariance says otherwise:

- prior sdlog 0.28 → **posterior sd 0.050**, tightened **5.6×**
- **r(`luc_scale`, `fert_k`) = −0.907**, r with `beta_max` = −0.481

It is absorbing input uncertainty that would otherwise be assigned as **false confidence** to
`fert_k`. Deleting it narrows `fert_k`'s posterior on the assertion that E_LUC is known
exactly, which it is not (±28 %). **Keep it.**

The real cost is different: **r = −0.907 is a sampling hazard.** Manage it by
reparameterising or by accepting slower mixing — not by dropping the parameter.

Independently, at *fixed* fertilisation parameters `luc_scale` does **not** help gate 7: at
0.70 the CO₂ bias goes +0.14 → **+15.5 ppm** and z_land gets *worse*. **The handoff's β 0.55 /
`luc_scale` 0.70 settlement does not carry over to this form.**

---

## 5. THE 8 FAILING TESTS — 4 of them are FOR MARCUS

Was 11. **Six resolved by the flip** — `test-climate.R:121,:122` and `test-pulse.R:83,:100,
:101,:112`, i.e. **the whole Pulse Lab**, including the Revelle lesson that was teaching the
opposite of what the tab says.

```
test-likelihood.R:114, :117     CO2-bias cost -- FIXTURE, see below      <- FOR MARCUS
test-likelihood.R:135           sigma_co2 profile -- FIXTURE             <- FOR MARCUS
test-luc-scale.R:125            gross-vs-net gap 8.7, wants > 10         <- FOR MARCUS
test-luc-permanence.R:88        the FOSSIL reference arm, 0.151 vs > 0.2
test-luc-permanence.R:104       needs f_luc_perm = 0 AND f_luc_wood = 1; sets only the first
test-mechanisms.R:32            ENSO switch weak (0.30 vs > 0.5)
test-pulse.R:113                ssp119 airborne fraction 0.213 vs > 0.3
```

**The four marked ones are all the same cause: the model now fits the CO₂ record so much
better that fixtures assuming an unbiased start no longer hold.** MLO residual RMS
**3.04 → 0.99 ppm**, mean residual −1.49 → +0.80.

- `:114/:117` — `cost(1)` is **−69.4**: shifting the model up 1 ppm moves it *toward* the
  observations. The AR(1)-pathology content they guard is intact and emphatic —
  `cost(50)` = **61,206** against the 10,000 threshold.
- `test-luc-scale.R:125` — **that test's own comment predicted this**: the gross-vs-net gap is
  large *because the model over-absorbs* (4.57 vs GCB 2.36); under MM it is 3.50, so the gap
  shrinks. *"Do not fix this test by asserting gross beats net; that holds only for a model
  whose sink is right."*
- `:135` — the `sigma_co2` profile peaks near the residual RMS, which moved.

**NONE was edited to pass.** They are stale fixtures on an improved model, but that is a
judgement and Marcus's is the one that counts.

`test-pulse.R:113` is worth a separate look: it is an *unbenchmarked* ballpark check on a
declining SSP1-1.9 background, while gate 12 — the properly protocol-matched Joos comparison
at a held 389 ppm — now passes. Different protocols.

---

## 6. THREE SILENT-INERTNESS BUGS, all the same shape

Flipping the default made `beta` inert, so **every caller that set `beta` without setting
`fert_form` silently became a no-op.** All three were caught by **suspicious uniformity** —
identical rows where there should have been a spread — not by anything failing loudly.

1. **`R/mechanisms.R`, the app's "CO₂ fertilisation (the land sink)" switch.** `p$beta <- 0`
   moved CO₂ at 2100 by **exactly 0.00 ppm** while still rendering as a live control.
   `test-mechanisms.R`'s "every switch changes the answer" caught it. Now zeroes **both**.
2. **`calibration/diag_fert_pulse_gates.R`** — its own log-form reference rows printed the MM
   answer for every β, identical to three decimals.
3. **`calibration/diag_joos_beta_scan.R`** — `CCX_JOOS_BETA` would have returned the MM answer.
   Now implies `CCX_FERT_LOG`.

**Nine legacy diagnostics are pinned to `CCX_FERT_LOG`** (`diag_recentre_beta`,
`diag_beta_luc_profile`, `diag_luc_scale`, `diag_luc_prorata`, `diag_d13c_suess`,
`diag_d13c_partition_refit`, `diag_emission_scale_degeneracy`, `diag_1900_deficit`,
`diag_which_stream_pays`). Verified: their log-reference rows are bit-identical pre- and
post-flip. **The pin does not make them current** — anything there that fed a live decision
must be re-run under the saturating form.

**Quarantined:** `calibration/output/mode_fit.rds` →
`calibration/output/quarantine/20260814_pre_mm_fertilisation/` with a README. Not a bug — a
model-structure change. `app/global.R`'s `identical(md$param_names, CCX_PARAM_NAMES)` guard had
already rejected it. The canonical path now holds the **new** mode, and the app reports
"posterior mode / single best fit".

---

## 7. ITEM 5c, DONE (`0cd9fbb`) — and it is a bias correction, not a fit improvement

Both emission inputs reached the model with **no within-year cycle at all**.

| | dataset | period |
|---|---|---|
| fire | GFED4.1s monthly 0.25° (van der Werf et al. 2017, ESSD 9:697–720) | 2001–2016 |
| fossil | EDGAR v4.3.2 monthly by country × IPCC sector (Crippa et al. 2020, Sci Data 7:121) | 1970–2012 |

**THE LOAD-BEARING DECISION: E_LUC is not fire.** GFED DEFO+PEAT is **0.367 PgC/yr** against
GCB's E_LUC of **1.699 GtC/yr** — **only 21.6 % of E_LUC burns**. The land-use weight is damped
by that measured `f_fire`; the raw fire shape would have overstated the correction **~4.6×,
in the direction that looks like success**. Fossil is not damped.

**What it bought:** `seas_amp_NH` **19.66 → 18.65** GtC/yr, **−5.1 %**, in the predicted
direction. (The OFF value reproduces the mode-find's fit exactly.) The 14b bounding test
predicted ≤8 % from an *undamped* plausible size; 5.1 % is the damped answer.

**The log-posterior is 1.3 units WORSE.** The model fitted the seasonal cycle better when it
could pour all the seasonality into one free parameter. The gain is that `seas_amp_NH` now
means what its name says. **Do not expect 5c to raise the log-posterior.**

Conservation exact: max |Δ annual total| **1.8e-15** GtC/yr. `cum_luc` is now integrated **per
hemisphere from the seasonalised flux**.

**Bonus, waiting for item 5:** the EDGAR aggregation measures the **NH fossil share at 0.9201**
against `FORC_FOSS_NH_SHARE = 0.95`, which has carried a "PROVISIONAL" comment since it was
written. **Not changed** — 14b §2.2 prices 0.90 → 0.97 at 0.84 ppm of MLO−SPO for 5.1
log-units, so it is item 5's decision.

---

## 8. THE ORDERING, amended

| # | task | status |
|---|---|---|
| ~~1~~ | ~~fix the objective~~ | **DONE** `304386a` |
| ~~2~~ | ~~re-take the β default~~ | **DONE** `a9d74ce` — `beta` is gone |
| ~~3~~ | ~~`luc_scale`~~ | **DONE** `304386a`; and see §4.3, it is NOT unused |
| ~~4~~ | ~~GLODAPv2~~ | **DONE** `3d923ef` + `9c773b4` |
| **5** | **interhemispheric-gradient terms (CO₂ + δ¹³C)** | **NEXT.** Priced at 0.84 ppm for 5.1 log-units; the 0.9201 fossil share is measured and waiting |
| **5b** | **time-varying LUC hemispheric share** | do it *with* 5 — 5 is what would score it |
| ~~5c~~ | ~~sourced input seasonality~~ | **DONE** `0cd9fbb` |
| **6** | `LIK_EXCESS_C14_TARGET` | **NOT a blocker** — see §9 |
| ~~7~~ | ~~saturating fertilisation~~ | **DONE** `554b5c1` + `a9d74ce` |
| **8** | **THE REFIT**, 18 parameters | blocked on 5 + 5b. ~2 h wall-clock, 4 chains, 0.060 s/eval |
| **9** | **pump** | test replaced — see §4.2. Do the cheap `h_ml` decomposition FIRST |

**Still do NOT:** hand-tune stream weights; delete `excess_c14_ocean` or `d14c_intcal`; free
any land turnover parameter; delete the `kz` bracket (§4.2 makes this worse, not better);
re-baseline the four flagged tests without Marcus; splice any pre-flip posterior into a new
chain; build the pump before the `h_ml` decomposition test.

---

## 9. A REPO CLAIM THAT DID NOT SURVIVE CHECKING

`R/likelihood.R` asserted that choosing between the two published excess-¹⁴C reconstructions
"would put **~130 log-units** of leverage on a choice of paper". **No receipt anywhere, and it
does not reproduce.** At the default and swept across `bomb_total` 80–130 kmol,
`table4_obs_range` and `table2_peacock` differ by **0.7–1.4 log-units** — the model's own
excess inventory sits between them and both terms are weak there (−6 to −10). The *direction*
survives (`table2_peacock` is ~3× tighter and constrains harder as a fit moves away); the
*magnitude* was pattern-matched. The comment now says so and asks for a receipt or a
correction. **Consequence: item 6 is not a blocker on the refit.**

---

## 10. Non-obvious state

- **`FORC_USE_EMIS_SEASONALITY`** (TRUE) switches 5c off; FALSE reproduces every pre-2026-08-15
  result bit for bit. **`fert_form`** likewise: `CCX_FERT_LOG` reproduces every pre-2026-08-14
  result. Both are the reason nothing had to be deleted.
- **`ccx_loglik()` now reads `(out, obs, err, luc, deep, by_stream)`.** Every caller passes
  `by_stream =` by name so nothing broke, but a positional 5th argument means `by_stream` and a
  positional 4th means `luc`. **Name them.** Second instance of this hazard.
- **`data-raw/downloads/gfed/` holds 1.2 GB** of GFED HDF5 and `EDGARv432_CO2_1970-2012m.xlsx`
  26 MB, both gitignored. The two ~30 KB extracts **are** committed, so
  `data-raw/build_emission_seasonality.R` runs on a fresh clone without re-downloading. Only
  `data-raw/extract_emission_seasonality.py` needs the bulk inputs (and `h5py` + `openpyxl`
  from `~/climate-env`).
- **Every "at default parameters" number in this repo is at `gamma_enso` = 0**, i.e. ENSO OFF,
  while `app/global.R` overrides it to 0.5. Unchanged, still a live provenance hazard.
- `calibration/output/recentre_beta_scan.rds` was overwritten on 2026-08-14 at then-current
  defaults; numbers quoted from the old file no longer correspond to it. Now doubly stale — it
  is a log-form artefact.
- New diagnostics: `diag_deep_d14c_term.R`, `diag_fert_saturating.R`, `diag_fert_pulse_gates.R`.
  `diag_joos_beta_scan.R` takes `CCX_FERT_FORM` / `CCX_FERT_BETA_MAX` / `CCX_FERT_K`.
  Raw outputs under `calibration/output/fert7/`.
- New tests: `test-fertilisation.R` (25), `test-emission-seasonality.R` (41).
- `DESIGN.md` §6 **gates 7, 10 and 12** now carry measured status lines. **Gate 12's was stale
  since β 0.38, which is why its failure at β 0.75 stayed invisible for two re-centrings** —
  it now says to re-measure on any fertilisation default change.

---

## 11. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-15_mm_flip_map_mode_and_5c.md`, and behind it
> `notes/review_2026-08-14_architecture.md` §§0 and 7 — **but note that review §0's headline
> is superseded: both hard gates now pass at the MAP mode.** Items 1–4, 5c and 7 are done.
> **Four test failures are waiting on Marcus (§5) and should be resolved before the refit.**
> The next work is **item 5 + 5b together** — the interhemispheric-gradient terms and the
> time-varying LUC hemispheric share — for which the measured NH fossil share (0.9201 against
> the shipped 0.95) is already in hand. Do **not** start the refit before them, and do **not**
> build the pump before the cheap `h_ml` capacity-vs-export decomposition test in §4.2.
