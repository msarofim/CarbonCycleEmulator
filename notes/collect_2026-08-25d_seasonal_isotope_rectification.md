# Collection — the seasonal NEP flux discriminates on BOTH halves of its cycle. 2026-08-25d.

Following Marcus's instruction to *"double check that the fossil, land-use, and ocean exchange
isotopic compositions are correct"*, and his framing that an AF-trend-vs-seasonal-partition
conflict is **a failure in model structure**, both observables being real.

`calibration/diag_seas_isotope_rectification.R`. **Nothing in `R/` or `src/` has been changed.**

---

## 1. The audit Marcus asked for: three of four are fine, one is not

| signature | verdict |
|---|---|
| **fossil** | **CORRECT.** Not a constant — built per year in `data-raw/build_calibration_data.R` [5b] as an emission-weighted mean over GCB's own by-fuel split, endmembers coal −24 / oil −26.5 / gas −44 / cement 0 / flaring −44 ‰ (Graven, Keeling & Rogelj 2020 GBC; Tans 1981; Andres et al. 2000 via Bush, Pataki & Ehleringer 2007). Cement is correctly separated as calcined carbonate at ~0 ‰. |
| **land-use** | **CORRECT BY CONSTRUCTION.** No prescribed value: LUC is a transfer out of the vegetation box, carrying that box's own emergent ¹³C ratio (`d13c_bio` removed 2026-08-12). |
| **ocean exchange** | **UNVERIFIED.** `alpha_as_down = 1 − 2/1000` (kinetic, invasion) and `alpha_as_up = 1 − 10/1000` (equilibrium, evasion), both hardcoded at `R/model.R:1532-1533`, both labelled "provisional", and both **temperature-independent** while the model has a seasonal SST cycle. The implied equilibrium offset is +8.08 ‰ ocean-over-atmosphere. **Not chased further — see §3, the ocean channel is not the culprit.** Still owed a citation and a T-dependence decision. |
| **photosynthesis** | `alpha_photo = 1 − 18/1000`, also "provisional". **The value is defensible; its APPLICATION is not.** |

## 2. THE BUG — `R/model.R:1040`

```r
add_flux(iatm, ilef, seas, alpha13 = aux$alpha_photo, lab = "seas")
```

`seas` is **zero-mean by construction** (`npp * (insol/n − 1)`), so it is negative for half of
every year. `add_flux` handles a negative flux by swapping the source box — *"for a negative flux
the source is `to`"* (`model.R:825`) — **but keeps applying `alpha13`.** The carbon coming back out
of the leaf pool in autumn is discriminated a **second** time.

**Photosynthesis discriminates. Respiration does not.** The rest of the file already knows this:
twelve lines earlier, `model.R:980-983` emits GPP down *with* α and autotrophic respiration back up
*without* it, commented "at leaf's ratio"; air-sea uses two one-way gross limbs with two separate
αs. **`seas` is the only α-carrying flux in the model that changes sign, and it is the only one
that did not get the two-limb treatment.**

### The receipt needs no model and no parameters

A closed two-box system, one 60 GtC/yr zero-mean sinusoid, nothing else, 50 cycles:

| | ΔC_atm | δ¹³C_atm | δ¹³C_leaf |
|---|---|---|---|
| **as shipped** | +9e−13 GtC | **−6.221 ‰** | −5.558 |
| α on uptake only | +9e−13 GtC | −0.094 ‰ | −17.813 |

**Carbon closes to machine precision; δ¹³C does not.** The atmosphere is pumped light at
**−0.124 ‰ per cycle**, forever. No reading of the flux permits that:

- as real bidirectional **NEP** → the autumn limb is respiration, `add_flux` gets the source ratio
  right and there must be **no α**;
- as a modulation of gross **photosynthesis** → α is right but the source ratio must be the
  **atmosphere's**, which `add_flux` does not use.

The two corrections coincide to first order (the leaf sits at `r_atm · α` anyway) and differ only
by the leaf's own Suess disequilibrium, ~1 ‰ today. **Which to adopt is Marcus's.**

### Why nothing caught it

- **¹³C conservation is structurally blind.** `add_flux` is antisymmetric, so total ¹³C is
  conserved for *any* α. This is a mis-partition, not a leak.
- **R↔C++ parity is blind.** `src/ccx_core.cpp:258-264` and `:370` implement the same rule; both
  cores are wrong together.
- **And both suites switch the flux off** — `test-conservation.R:82`, `test-parity.R:72/151` all set
  `seas_drivers <- 0`. The two tests with any claim to power over the seasonal isotope path disable
  it. [[no_power_null]], [[two_statistics_can_be_blind]]

## 3. The channel decomposition that found it

At the reference mode, zeroing one seasonal driver at a time (semi-amplitude √(a²+b²)):

| | SPO CO₂ | SPO δ¹³C |
|---|---|---|
| base | 0.636 (1.06× obs) | 0.0581 (2.60× obs) |
| ocean SST seasonal OFF | 0.820 (1.37×) | 0.0591 (2.64×) |
| land NPP seasonal OFF | 0.346 (0.58×) | 0.0087 (0.39×) |

**The ocean channel is exonerated**: removing it changes δ¹³C by 2 % while moving CO₂ by 29 %. The
SPO δ¹³C seasonal cycle is ~85 % land-NPP-driven. And the model was getting its SPO **CO₂**
amplitude right *by cancellation* — a too-large land signal partly offset by an ocean signal that
carries almost no δ¹³C — which is [[ccx_sst_seas_veto]]'s cancellation, seen from the other side.
δ¹³C is what exposes it.

## 4. What the fix does — AND WHAT IT DOES NOT

At the adopted mode, **frozen** (gated: CO₂ identical to 1e−10, δ¹³C differs by 0.917, so the patch
demonstrably ran and demonstrably moved no carbon):

| | δ¹³C amp vs obs | per-ppm vs obs |
|---|---|---|
| MLO shipped → fixed | 1.18× → **0.86×** | 1.28× → **0.93×** |
| SPO shipped → fixed | 2.60× → **1.68×** | 2.45× → **1.58×** |

Per-stream, **total −49.7**, and the composition is the whole story:

| stream | shipped | fixed | Δ |
|---|---|---|---|
| `d13c_seasonal_SPO` | 96.3 | 210.4 | **+114.1** |
| `d13c_seasonal_MLO` | 115.1 | 211.6 | **+96.6** |
| `d13c_level_MLO` | 54.8 | 29.3 | −25.5 |
| `d13c_level_SPO` | 62.6 | −171.3 | **−234.0** |

**The seasonal streams gain +210.7 and the annual LEVELS lose −259.5.** That is expected and is
**not a verdict**: the bug was a secular ¹³C pump, so removing it shifts the model's mean
atmospheric δ¹³C by ~0.16 ‰ at SPO, and every parameter in the old mode was fitted **around** that
pump. A frozen-vector cost is an upper bound — this session's own lesson, where the refit recovered
**15–19×** more than the frozen scan predicted. **Only a refit prices the fix.**

## 5. What it does to the ridge veto

Re-scoring both arms **under the patch, at bug-fitted parameters**: the pin90-vs-reference
likelihood gap goes **−90.07 → −25.28**, and its composition inverts —

| stream | shipped | patched |
|---|---|---|
| `d13c_seasonal_SPO` | −38.16 | −8.98 |
| `d13c_seasonal_MLO` | −24.22 | (out of the top six) |
| `gcb_land_sink` | −24.00 | **−24.00** |

**The isotopic objection to a saturating fertilisation largely dissolves, and what is left is the
GCB land sink — a carbon-budget objection, not an isotopic one.** Same caveat as §4: this is at
parameters fitted with the bug, both arms move under a refit, and the free arm has to be re-run
before anything about the ridge is claimed.

## ⇒ WHAT IS OWED, AND IT IS MARCUS'S CALL

1. **Adopt correction (1) or (2)** (§2). Second-order difference, but a real modelling statement.
2. **Fix BOTH cores** — `R/model.R:1040` and `src/ccx_core.cpp:370` — or parity will hide it again.
3. **THE OBJECTIVE CHANGES.** Nothing fitted before is comparable, same class as the 2026-08-22
   ice-hemisphere change. **Every fitted vector is invalidated, including the adopted arm-N mode.**
   Outputs go to `outputs/quarantine/20260825_seas_isotope_rectification/` with a README.
4. **A refit is owed** (~9 h), and the four ridge arms with it if the ridge question is to be
   re-answered rather than re-litigated.
5. **A regression test with power** — the closed-box receipt of §2 is the test, and it must run with
   `seas_drivers = 1`, which no current test does.
6. **Still open and untouched:** `alpha_as_up`/`alpha_as_down` need a citation and a decision on
   temperature dependence; and after the fix MLO sits at 0.93× and SPO at 1.58×, so the seasonal
   partition is much improved but **not closed** — Marcus's latitude-band / stratosphere /
   high-latitude-mixing candidates remain live for that residual, on a far smaller target.
