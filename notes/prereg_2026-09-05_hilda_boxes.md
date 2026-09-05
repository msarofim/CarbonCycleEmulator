# PRE-REGISTRATION + STRUCTURAL SPEC — building HILDA's HIGH-LATITUDE BOXES
# (HS / HD) properly, and what they must predict.
# Written 2026-09-05 BEFORE any line of the structure exists.

Follows `notes/prereg_2026-09-04k_hilda_conduit.md` and its collect
`notes/collect_2026-09-04k2_hilda_conduit_works.md`, which measured the conduit's **GEOMETRY** in
reduced form and got 3/3. That note's own closing line is the mandate for this one: *"the honest
next step is to build the conduit properly and re-measure, not to treat 1.81 as the answer."*

⚠ **NOTHING HERE IS ADOPTED, FITTED, OR ON THE TABLE FOR ADOPTION.** This registers a structure and
the numbers it must produce. Whether it ships is a separate decision, on separate evidence
(the ocean sink, the CO₂ record, the gates), none of which is tested here.

---

## 1. THE SOURCE, READ NOT RECALLED

Siegenthaler & Joos (1992), *Tellus* **44B**:186–207, doi:10.3402/tellusb.v44i3.15441.
PDF at `~/Documents/2010/Essenhigh/siegenthaler92tel.pdf` (scanned; `pdftotext` returns nothing —
it must be read as images). **Fig. 1 (p.187) and Table 1 (p.188) are the spec.**

**Geometry (Fig. 1).** Two surface boxes at 0–75 m: **LS = 84 %** of ocean area, **HS = 16 %**.
Under LS, the **Interior**, 75–3800 m, advective-diffusive. Under HS, **HD**, 75–3800 m, well mixed.
Four transport parameters: **K** (eddy diffusivity in the Interior), **w** (upwelling in the
Interior, downwelling in the high latitudes), **u** (HS↔HD exchange), **q** (HD↔Interior exchange,
*assumed independent of depth*).

**Table 1 — HILDA's own fitted values, K(z) version:**

| quantity | value |
|---|---|
| HS area share | **16 %** of the global ocean surface (Antarctic south of ~52 °S + parts of the N. Atlantic) |
| HS definition | annual-mean surface temperature **< 5 °C** |
| gas exchange at 280 ppm | **15.1 ± 1.2** mol m⁻² yr⁻¹, and **g_l = g_h** — the same per-area coefficient in HS as in LS |
| **u** (HS↔HD) | **38 ± 17 m/yr** |
| **w** (interior upwelling) | **0.44 ± 0.56 m/yr** |
| **q⁻¹** (Interior–HD, relative to interior volume) | **538 ± 510 yr** |
| K(z) | `K = 465 + 7096·exp(−(z − 75)/253)` m²/yr |
| ocean surface area | 3.62·10¹⁴ m² (ours: 1.55 + 2.06 = **3.61·10¹⁴** — the same ocean) |

**Table 2 — the preindustrial Δ¹⁴C the boxes are supposed to carry** (prescribed from GEOSECS
where given, model where not): **HS −120 ± 30 ‰**, **HD −136 ‰ (model)**, **LS −40 ± 20 ‰**.
⭐ **The 80 ‰ HS–LS split is the physics the 09-04k2 shim could not represent**, and it is the
reason for building boxes rather than tuning a rate: HS water sinks **before it equilibrates**.

⚠ **THE GAS-EXCHANGE EQUALITY IS THEIR ASSUMPTION, NOT A MEASUREMENT** — they justify it by sea ice
suppressing exchange in winter and roughly cancelling the stronger high-latitude winds, citing
Shaffer & Sarmiento. It is inherited here as an assumption and labelled as one.

## 2. WHAT WE ARE BUILDING — and where it DEPARTS from HILDA, deliberately

Per hemisphere `h ∈ {NH, SH}`, two new boxes `h_hs` and `h_hd`, appended after the interior:
**16 → 18 boxes/hemisphere, 32 → 36 boxes, 96 → 108 states.** The C++ core hard-codes the stride
and the order (`src/ccx_core.cpp:39`), so this is a twin change with a parity test, not an R patch.

| # | choice | default taken | why, and the alternative |
|---|---|---|---|
| **C1** | HS area | **`f_hs` = 0.16 of EACH hemisphere's ocean area** | gives 16 % globally, HILDA's number, with no extra assumption. ⚠ **Physically the real HS is SH-heavy** (Antarctic ≫ N. Atlantic). The SH-weighted allocation is the pre-registered sensitivity, not the default. |
| **C2** | HS thickness | **= `h_ml` (134.15 m at `ent26`)** | HILDA uses 75 m for both surface boxes; our LS mixed layer is a FITTED 134 m already doing extra duty. Making HS a *different depth* would add a parameter and confound the test. Alternative: pin HS at HILDA's 75 m. |
| **C3** | HD | **one well-mixed box, `h_ml` → 3700 m, over the HS area** | HILDA exactly. |
| **C4** | `q` (HD↔Interior) | **exchange with EVERY interior layer in proportion to its volume**, total flux `V_interior / τ_q`, `τ_q` = 538 yr | HILDA's Interior is one advective-diffusive continuum and `q` is *"assumed independent of depth"*; volume-proportional is the discretisation of that. ⚠ **This DOES reach the intermediate layers — and that is the point.** It injects **HD water (−136 ‰), not surface water (−40 ‰)**, which is exactly how it differs from `w_out`, whose distributed return injected the mixed layer and over-ventilated the middle. |
| **C5** | `w` | **NOT built** | HILDA's own `w` = 0.44 ± 0.56 m/yr is **consistent with zero**, and our `w_up`/`q_conv` already exist, sit at 0 at `ent26`, and were measured dead (`+0.11010` derivative, wrong sign for Fix B, 09-04i). Adding a third advective lever would confound. |
| **C6** | HS air-sea | **same per-area gas-exchange coefficient as LS** | HILDA's `g_l = g_h`, §1. Inherited as an assumption. |
| **C7** | HS temperature | **a new constant `SST_HS`, ≥ 2 °C** | ⚠ **HARD CONSTRAINT FOUND BEFORE BUILDING:** `data-raw/build_carbonate_tables.R` fits K0/K1/K2/Kb/Kw on `T_GRID = seq(2, 35, 0.25)`, so **below 2 °C the carbonate polynomials extrapolate**. HILDA says "< 5 °C" and nothing more. ⇒ the value must be **derived from an observation** (area-weighted SST over the HS region) and the tables **re-fitted down to −2 °C** if that lands below 2. Provisional 2.0 °C is a placeholder, NOT a source. |
| **C8** | HS alkalinity / salinity | **same `ALK_SURFACE`, same `SALINITY_REF`** | a known simplification, stated: the real Southern Ocean is fresher and lower-alkalinity. Deferred, not denied. |
| **C9** | biological pump in the HS column | **OFF** | the pump's `pump_grad` is FITTED against the observed DIC gradient in the LS column; giving HS its own export would move a fitted quantity inside a structural test. Southern-Ocean export is real and this is a deferral. |
| **C10** | the OFF switch | **`f_hs = 0` ⇒ every HL flux ∝ HS area ⇒ HS/HD hold zero carbon and pass zero flux, LS gets the full area** | the incumbent must be **bit-reproduced**, the same contract `pump_grad = 0` and `alpha_as_tdep = 0` already carry. |

**Protocol for scoring, identical to 09-04k2 so the numbers are comparable:** preindustrial steady
state only; all 26 parameters at `ent26`; **only `kz` re-solved**, iso-deep, to hold the bottom box
at **−156.145 ‰**; scored band **> 1500 m** (bomb addition ≤ 4.5 ‰); `n_eff = LIK_D14C_DEEP_NEFF`.

⭐⭐ **THE QUANTITATIVE PRE-CHECK, AND IT IS THE SHARPEST THING IN THIS NOTE.**
HILDA's `u` = 38 m/yr acts over **16 %** of the area; the 09-04k2 shim's `u` acted over the **whole**
column. Global-area-equivalent, **HILDA's own conduit is 38 × 0.16 = 6.08 m/yr** — and the shim
measured a hard **ceiling at u ≳ 2**, above which *no* `kz` holds the deep age at all.
⇒ **HILDA's own fitted conduit is ~3× beyond our reduced form's feasibility ceiling.** Either the
real HS box relaxes that ceiling (because the water it sends down is old, not surface-fresh), or the
structure as specified is inconsistent with our column. **That is a falsifiable fork and P2 scores it.**

## 3. THE PREDICTIONS

### P0 — CONSERVATION AND THE NO-OP, scored first and nothing below is read if it fails
**PREDICT: `f_hs = 0` reproduces `ent26` BIT-EXACTLY** (deep Δ¹⁴C identical to all printed digits),
**`f_hs = 0.16` moves it**, carbon closes to < 1e-9 relative, and **R and C++ agree to parity
tolerance** on the new state.
**FALSIFIER: any of the four.** ⇒ the structure is wrong and nothing below means anything.

### P1 — THE ENDMEMBER: does an HS box under-equilibrate on its own?
This is the physics the shim could not carry, and it must be **emergent, not prescribed**.
**PREDICT: preindustrial HS Δ¹⁴C lands in [−160, −80] ‰** — i.e. within HILDA's GEOSECS-based
−120 ± 30 broadened by one interval — against an LS mixed layer near **−40**.
**FALSIFIER: HS sits within 20 ‰ of LS** ⇒ our HS equilibrates too fast to be HILDA's HS, the
80 ‰ split is not reproduced, and the box adds nothing the 09-04k2 shim did not already have.
⚠ **This is a genuine out-of-sample check**: no HS observable is in the likelihood, and no
parameter here was fitted to one.

### P2 — THE CEILING: does a real HS box make HILDA's own `u` feasible?
**PREDICT: at `u` = 38 m/yr over the HS area (6.08 m/yr global-equivalent), a `kz` EXISTS that holds
the deep box at −156.145.**
**FALSIFIER: no `kz` holds it** ⇒ the 09-04k2 ceiling was NOT an artefact of the missing box, and
the conduit's usable strength in our column is ~6× below the strength HILDA fitted — which would
mean our column and HILDA's cannot both be right about the deep.

### P3 — THE MECHANISM: does `kz` fall further than the shim's?
**PREDICT: the solved `kz` at HILDA's `u` and `q` is BELOW the shim's 3177** (itself 0.50× the
incumbent's 6356), i.e. the real structure relieves the diffusivity at least as much as the reduced
form did.
**FALSIFIER: `kz` ≥ 3177** ⇒ the boxes add cost without adding ventilation, and P4 is a wash.

### P4 — THE RESULT: does the intermediate profile beat the reduced form?
**PREDICT: scored mean |z| over > 1500 m falls BELOW 1.81** (incumbent 2.55; DESIGN §3.4a's
benchmark is 1).
**FALSIFIER: it does not fall below 1.81** ⇒ the reduced form already captured everything the
geometry buys, the cold surface adds nothing measurable, and the case for the structure rests on
P1 alone — which would not be enough to carry new boxes.
⚠ **Reaching |z| < 1 is NOT predicted.** Saying so in advance: the honest expectation is partial
closure, and a result between 1 and 1.81 is a **confirmation**, not a disappointment.

### P5 — THE SHAPE, weakest and labelled so
**PREDICT: HD lands near −136 ‰** (HILDA's own model value, not an observation — so this is a
model-to-model comparison and is reported, never used as a gate), **and the unscored 1160 m peak
improves further than the shim's +1.98.**
**FALSIFIER: HD comes out warmer than the LS mixed layer**, which would mean `q` is ventilating HD
from the interior rather than the other way round.

### N1 — THE NEGATIVE CONTROL, because `q` reaches the intermediate layers
**PREDICT: the upper ocean (≤ 500 m, currently z +0.61 — the layer that MATCHES) does not degrade
by more than 1 z-unit.**
**FALSIFIER: it does** ⇒ `q` is injecting into the wrong place and C4's volume-proportional
discretisation is wrong, whatever P4 says.

## 4. WHAT IS EXPLICITLY NOT CLAIMED

- **No fit, no adoption, no posterior.** `kz` is the only quantity re-solved.
- **No transient.** Preindustrial steady state only, so **no bomb ¹⁴C, no ocean sink, no Joos IRF,
  no gate H, no ENSO.** Every one of those is a separate measurement and several of them could still
  kill the structure.
- **Nothing about the equatorial box.** The two candidates still have not been scored against each
  other on the same observable; this note advances one of them, it does not retire the other.
- ⚠ **`u` here IS HILDA's `u`** — unlike 09-04k2, where it explicitly was not. The area convention
  is now the same as theirs, so the numbers may finally be quoted side by side, and the note says so
  in both places so the earlier prohibition is not carried forward by habit.
