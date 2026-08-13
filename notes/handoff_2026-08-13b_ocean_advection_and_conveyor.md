# Handoff — CarbonCycleEmulator, 2026-08-13 (b)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
(= `2ea1009`, **still not merged**). Suite **426 pass / 4 fail / 2 skip** — the same four
failures as 12d and 13, plus 26 new guard assertions.

Supersedes nothing. It **adds** to `handoff_2026-08-13_d13c_structural_misfit.md`: that
note's §3b ended with "the cheapest structural candidate is a single prescribed upwelling
velocity... Nothing here has costed that; it is a suggestion, not a plan." **It is now
costed, in two configurations, and both fail — the second one provably.** Everything else
in the 13 note stands, including **§5, which is still open and still blocking** (§5 below).
12d §§2–8 and §10 continue to apply.

---

## 0. START HERE

1. **`sigma_d13c` is still the blocker.** Nothing this session changed the argument, and
   nothing in `CCX_PARAM_TABLE` was touched. See §5 — the recommendation is unchanged
   (0.45 ‰, documented as model-structural error) and is now better supported, because the
   ventilation gap has been shown to be *not cheaply removable*.
2. **Do not re-propose "just add advection".** It is built, gated, measured, and it does
   not work — §§1–3. The reason is a symmetry, not a tuning failure, so re-parameterising
   it will not help.
3. **The one live structural idea is the CONVEYOR** — NH sinking, deep interhemispheric
   flow, SH upwelling (Marcus, 2026-08-13). It is the *first* configuration that escapes
   the symmetry in §2, and its arithmetic pre-check is promising but short of a closure.
   §4 is a full design spec with the numbers, the gotchas, and the falsification test to
   run **before** building. **Not started. Not decided.**

---

## 1. What this session settled

| | result |
|---|---|
| §2 | **Reversing a closed vertical circulation is invisible to the atmosphere.** A theorem, verified to 4e-17. This is the durable finding. |
| §3 | Two advective ocean configurations built, defaulted OFF, gated, and measured. Neither closes the δ¹³C overshoot. |
| §4 | The conveyor designed and costed on paper; **27 Sv reproduces the observed deep-ocean ¹⁴C age from transit time alone**. |
| — | A timescale argument I made mid-session was **overstated and is corrected** (§3, last para). |

---

## 2. THE RESULT: reversing a closed loop is invisible to the atmosphere

Two configurations were built (§3). At equal velocity they give **identical** CO₂, δ¹³C,
Δ¹⁴C, ocean carbon and land carbon — to **~1e-10**, at every `kz` from 10 to 5000. Not
similar. Tied.

They are the same closed loop traversed in opposite directions, so their transport
operators satisfy

> **A_out = D · A_upᵀ · D⁻¹**,  D = diag(dz)  — verified to **1.7e-18**

and interior diffusion is self-adjoint in the same weighting (**2.2e-16**), so it does not
break the relation. A transpose preserves the **diagonal** elements of every matrix power,
hence of the propagator. And **the mixed layer is the only box through which the ocean
touches the rest of the model** — air-sea exchange acts at `iml` and nowhere else. So the
atmosphere, the land and the sink partition see the column *exclusively* through an ml→ml
response that is invariant under reversing the circulation:

```
100-yr propagator   |ml -> ml difference|      4e-17
                    largest difference anywhere 0.27
                    |deep -> ml difference|     0.74
```

**The off-diagonals are not tied**, which is why the interior profile and the deep-ocean
age *do* differ between the two.

**Why this matters more than the negative result it explains.** It converts "one advection
scheme failed" into "**no reversal or rerouting of a closed vertical loop can change what
the atmosphere sees**". Only something that changes the **mixed layer's own budget** can:
a second surface box, an open column (→ §4), or the air-sea flux itself. It is held as a
test (`test-ocean-advection.R`, last two cases), stated on the operators so that a failure
says *which limb* was mis-wired rather than only that some output moved.

## 3. The two configurations, and what they cost

Both are in `R/model.R` + `src/ccx_core.cpp`, **default 0**, **absent from
`CCX_PARAM_TABLE`**, mutation-tested for inertness. Diagnostic:
`calibration/diag_ocean_upwelling.R` (~10 s, 9 parts, carries its results in its header).

| | `w_up` | `w_out_NH` / `w_out_SH` |
|---|---|---|
| shape | distributed upwelling, **non-local sinking** (ml → bottom) | **non-local upwelling** (bottom → ml), distributed descent |
| i.e. | classical upwelling–diffusion (Hoffert 1980; Harvey & Schneider 1985) | a Southern Ocean outcrop, per hemisphere |
| δ¹³C at 4 m/yr | +0.548 → **+0.455** | +0.548 → **+0.455** (SH-only: +0.499) |
| deep Δ¹⁴C at 4 m/yr | −100 ‰ | **−108 ‰** (SH-only −135) |

**Neither closes δ¹³C, and both are worse than `kz` at the trade they make.** Per ‰ of
deep-ocean Δ¹⁴C spent: `kz` **−0.00220**, `w_up` −0.00107 (0.5×), `w_up` at low `kz`
−0.00052 (0.2×). Over the whole (`w_up`, `kz`) surface, the best δ¹³C bias among cells whose
deep ocean is still inside −150/−200 ‰ is **+0.501 ‰, at `w_up` = 0**. Hold the deep age
fixed by bisecting `kz` and *both* configurations make δ¹³C **worse** (+0.628 at `w_up` = 1;
+0.608 at `w_out_SH` = 4) — the compensating `kz` stops burying the depleted carbon faster
than the advective limb removes it.

Cheap to carry: the advective limbs go through `add_flux`, so conservation is structural; a
uniform column is still an exact fixed point, so **`ccx_spinup()` needed no change at all**
(its analytic ¹²C equilibrium and both isotope solves stand); and the substep controller
does not move at physical values (`ccx_advection_eigbound()` is exactly 0 when off).

**A CORRECTION, recorded because I got it wrong first.** Mid-session I wrote that the
mechanism fails because overturning cannot outrun air-sea exchange — measured gross
exchange 27.1 GtC/yr against a 284 GtC NH mixed layer = **10.5 yr** equilibration, versus
**18.8 yr** to flush at 4 m/yr. That ratio bounds how *fast* the mixed layer is renewed,
**not how much good the renewal does**, and the two come apart when the arriving water is
very different from the ml. Renewing with fully preindustrial water leaves the ml at
τ_flush/(τ_flush + τ_eq) = **0.64** of full equilibrium at 4 m/yr — a 36 % cut. So that
argument did **not** rule out a non-local deep-to-surface path. §2 is what rules it out.
**Keep the distinction: renewal rate ≠ renewal contrast.** §4 lives on the second one.

## 4. THE CONVEYOR — design spec, arithmetic, and what to test first

Marcus, 2026-08-13: *"sinking in northern hemisphere, deep water interaction between
hemispheres, upwelling in southern hemisphere."* **Not built. Not decided.** This section
is what a next session needs to decide it.

### 4.1 Why it is not just a third parameterisation

§2's theorem has two premises, and the conveyor **breaks both**:

- *The loop is closed within one column.* It is not: each column becomes an **open** system
  with a net carbon throughflow, sustained by the interhemispheric limbs. The reason the
  outcrop tied classic UD is that whatever old water arrived at the ml was balanced by
  depleted water leaving into the layer directly below, which diffusion handed straight
  back. Here the NH ml exports its depleted water to **the other hemisphere's deep ocean**,
  where no diffusive path returns it.
- *The ocean touches the atmosphere at one box.* It would touch it at **two**. A transpose
  preserves diagonal elements but **swaps** the off-diagonals, so `NH→SH` and `SH→NH`
  responses exchange rather than being preserved: **the conveyor is distinguishable from
  its own reverse.** That is a free, decisive implementation check — see 4.5.

### 4.2 The four limbs, and why volume still conserves

Parameterise by the **volume flux Q (Sv)**, not a velocity: the two hemispheres have
different ocean areas (NH 1.55e14, SH 2.06e14 m²), so one velocity would not conserve
volume across the basin.

| limb | from → to | flux (GtC/yr) |
|---|---|---|
| NH sinking (narrow plume, non-local) | NH ml → NH bottom box | Q · C_ml,NH / (A_NH · h_ml) |
| deep interhemispheric | NH bottom → SH bottom | Q · C_deep,NH / (A_NH · dz_deep) |
| SH upwelling (broad, distributed) | SH oc_{k+1} → SH oc_k, every interface | Q · C_{k+1} / (A_SH · dz_{k+1}) |
| surface return | SH ml → NH ml | Q · C_ml,SH / (A_SH · h_ml) |

Every box gains Q and loses Q of water, so **a uniform-concentration ocean is still an
exact fixed point** and `ccx_spinup()`'s analytic ¹²C equilibrium survives untouched — the
same property that made §3 cheap. The 13C/14C solves invert whatever operator `ccx_deriv()`
presents, so they need nothing either. Non-local sinking in the NH and *distributed*
upwelling in the SH is the physically right asymmetry: NADW forms in a narrow region and
sinks fast; the return is broad and slow.

**Implementation note that will bite:** this is the **first ocean–ocean coupling in the
model**. `ccx_deriv()`'s ocean block is inside the per-hemisphere loop, and the two columns
are currently independent — the only interhemispheric term is atmospheric (`tau_ex`),
emitted *outside* the loop. The deep and surface interhemispheric limbs must be emitted
outside the loop too, in the same place. In `ccx_core.cpp` the same applies (after the
`for (hi...)` block, next to the existing `add_flux(0, NPH, ...)`).

### 4.3 The arithmetic pre-check — promising, and short of a closure

Computed from the model's own constants (`scratchpad/conveyor_scoping.R`; deep volume
1.309e18 m³):

| Sv | w_NH (m/yr) | w_SH | NH ml flush | SH ml flush | deep transit | Δ¹⁴C from transit |
|---|---|---|---|---|---|---|
| 10 | 2.04 | 1.53 | 36.8 yr | 49.0 yr | 4147 yr | −396 ‰ |
| 15 | 3.05 | 2.30 | 24.6 | 32.6 | 2765 | −286 |
| 20 | 4.07 | 3.06 | 18.4 | 24.5 | 2073 | −223 |
| **27** | 5.50 | 4.14 | 13.6 | 18.1 | **1536** | **−170** |
| 30 | 6.11 | 4.60 | 12.3 | 16.3 | 1382 | −155 |

**The headline number: 27 Sv reproduces the observed deep-ocean Δ¹⁴C of −170 ‰ from
transit time alone**, with no eddy diffusivity involved — and 27 Sv is squarely inside the
observed overturning range. That is the decoupling the single-column loops provably could
not deliver: the deep age would come from *circulation* (a number a reader can be told —
"the deep ocean has not touched the surface for about 1500 years") and `kz` would be freed
to be a small, honest eddy diffusivity instead of a fiction standing in for ventilation.

**Do not quote −170 at 27 Sv as if it were the answer.** It is idealised plug flow: it
ignores the source water's own preindustrial Δ¹⁴C (≈ −50 ‰, which alone would take 27 Sv
to about −211 ‰ and move the −170 point to ~37 Sv) and it ignores diffusion, which mixes
the profile the other way. The honest claim is **order-right: the transit-time arithmetic
puts the deep age in the observed bracket for overturning in the 20–40 Sv range.** The real
number needs the run.

**Expected δ¹³C benefit, and it is not a closure.** At 27 Sv the SH mixed layer would sit
at 18.1/(18.1 + 10.5) = **0.63** of full equilibrium — a 37 % cut in SH ml depletion (24 %
at 15 Sv). The empirical slope from the runs already done (`w_up` 4: ml depletion eased
0.204 ‰ → atmospheric bias eased 0.093 ‰) is **0.46 ‰ of atmospheric bias per ‰ of ml
depletion**. Combining, with the SH ml easing ~0.5 ‰ and the NH somewhat less, expect
roughly **0.15–0.25 ‰ of the 0.55 ‰ gap** — a third at best. **Real, physically earned,
and not a closure.** Plan for it to reduce the ventilation caveat, not retire it.

### 4.4 A prediction it makes that the likelihood already scores

An NH-sinking / SH-upwelling conveyor eases **both** mixed layers, and eases the **NH
faster** (flush 13.6 yr vs 18.1 at 27 Sv, because the NH ocean area is smaller): the NH ml
exports depleted water to depth *and* is refilled from the SH surface. So it should **shrink
the model's NH−SH δ¹³C gradient**, which is currently **too large by 3×**: model MLO−SPO
= **−0.218 ‰** against an observed **−0.074 ‰** (1993–2014, `diag_ocean_upwelling.R`
part 8). Nothing in §3 moved that number (−0.226 at `w_out_SH` = 4). **This is the
conveyor's falsifiable, independent claim, and it is scored by the existing likelihood** —
if the gradient does not shrink, the mechanism is not doing what this section says.

### 4.5 What to do, in order

1. **The reverse-conveyor check, immediately after implementing.** Run it backwards (SH
   sinking, NH upwelling). By 4.1 it **must** give a different atmosphere. If it ties, the
   implementation has accidentally closed the loop within a column, or the interhemispheric
   limbs are not wired to the boxes intended. This is a free, decisive gate — build it into
   the test file next to the existing symmetry tests.
2. **Then the deep age, per hemisphere.** `ccx_spinup()$diagnostics$d14c_deep_ocean`
   averages *both* hemispheres' bottom three layers. Under a conveyor that is the wrong
   diagnostic: the NH deep is directly ventilated and should come out **young**, the SH deep
   **old** — which is the observed pattern (young North Atlantic, old deep Pacific) and
   would be a structural improvement on anything the model has done so far. **Split the
   diagnostic before reading it**, or it will report a meaningless average.
3. **Then `kz`.** Its `[3830, 6200]` bracket in `CCX_PARAM_TABLE` was bisected on the
   pure-diffusion column and is **conditional on that structure** (12d §6). With a conveyor
   carrying the ventilation, `kz` should fall a long way and the bracket must be re-derived
   or, better, replaced by the deep-Δ¹⁴C likelihood term that 12d §0 step 2 already calls
   for. Do not carry the old bracket across.
4. **Only then judge δ¹³C**, against 4.3's stated expectation of 0.15–0.25 ‰.

**Cost:** comparable to §3 — ~40 lines in each of `R/model.R` and `src/ccx_core.cpp`, plus
the interhemispheric plumbing, plus a diagnostic that can extend
`diag_ocean_upwelling.R`. Half a day, and the spinup and stability machinery come free.
**One new parameter (Q), with a citable prior** — RAPID-era AMOC ~15–20 Sv, global
overturning ~20–30 Sv (*recollection; needs a citation before it becomes a prior*).

**The communications case is the strongest part.** DESIGN §2 rejected HILDA as "too many
parameters to communicate" and that judgment stands — but a conveyor is one number, and it
is the *one piece of ocean circulation an undergraduate has already heard of*. "Water
sinks in the North Atlantic, crosses the world at depth, and comes back up in the Southern
Ocean about 1500 years later" is easier to tell than an eddy diffusivity, and it would let
the deep-ocean ¹⁴C age be *derived* rather than bounded. **That is a DESIGN §2/§10 decision
(ocean advection is currently in the v2 backlog), not a diagnostic's call.**

## 5. The σ decision — STILL OPEN, STILL BLOCKING, unchanged

Everything in the 2026-08-13 note's §5 stands verbatim. `sigma_co2` = 1.5 and `sigma_d14c`
= 5 are settled; **`sigma_d13c` is not, and `CCX_PARAM_TABLE` has not been touched.**

This session **strengthens the 0.45 ‰ recommendation** without changing its logic: the
ventilation gap is now demonstrated to be structural in a much stronger sense than before —
not merely "unfixed" but, for the whole family of closed vertical circulations, **unfixable**
(§2). The honest form remains 0.45 ‰ with the reason written into the table as *"model-
structural error from the missing ocean ventilation, measured at 0.55 ‰ by
`diag_d13c_levers.R` and shown irreducible by closed-loop circulation in
`diag_ocean_upwelling.R`"*. If the conveyor lands and buys 0.15–0.25 ‰, revisit the number
then — **do not block the σ decision on the conveyor.**

## 6. Non-obvious state

- **Three new parameters exist and are all 0:** `w_up`, `w_out_NH`, `w_out_SH`. They are in
  `ccx_default_params()` and in `ccx_cpp_par()`'s selection vector (positional contract with
  `unpack_par` in the C++ — same silent-garbage risk as `CCX_FORCING_COLS`). They are
  **not** in `CCX_PARAM_TABLE`, so the parameter count is still 16 and nothing samples them.
- **`ccx_advection_eigbound()`** is a Gershgorin *bound*, not a spectrum — the non-local
  limb makes the operator non-symmetrisable, so the `ccx_diffusion_eigmax()` trick does not
  transfer. It returns exactly 0 when every velocity is 0, which is what keeps the substep
  count identical to its pre-2026-08-13 value.
- **`test-ocean-advection.R` is 6 tests / 26 assertions**, including an inertness gate, its
  mutation test, a conservation check on the *derivative* (not the integrator), an R/C++
  parity gate for the new limbs, and the two symmetry tests from §2.
- **`diag_ocean_upwelling.R` takes ~10 s** and prints 9 parts. Its header holds the full
  result set; read that before re-running anything.
- The four suite failures are **unchanged and pre-existing** (`test-climate.R:122` γ_L
  structural; `test-likelihood.R:114/117` stale fixture; `test-mechanisms.R:32` `gamma_enso`
  pinned by the test). None is related to this work.
- **The oceanic-Suess lead from the 13 note is still unverified.** Model ml declines
  1.619 ‰ over 1750–2024 vs the atmosphere's 2.834 (ratio 0.57); my recollection of the
  observed ratio is 0.35–0.45. **No source in DATA.md, none in `~/Documents/2026/ClaudeDocs/
  Papers/`** — Quay et al. and Eide et al. (2017) are where to look. If it holds it is
  independent evidence for §4, and it would give the conveyor a target to be scored on.
- Everything in 12d §10 still applies — the `kz` default is **5000**, freezing a parameter
  is a `CCX_PARAM_TABLE` deletion, `beta` and `kz` are `logit` not `log`, and
  `run_modefind.R` costs ~4 h per refit.

## 7. Commits

| | |
|---|---|
| `40ca155` | The ventilation term, built and measured: upwelling does not close d13C |
| `2ea1009` | The outcrop configuration: deep water straight to the surface, and why it ties |

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-13b_ocean_advection_and_conveyor.md`, then
> `notes/handoff_2026-08-13_d13c_structural_misfit.md` for §5 and
> `notes/handoff_2026-08-12d_frozen_land_bounded_kz.md` for §§2–8 and §10, on branch
> `luc-veg-debit`. §5 is still open and blocking: get Marcus' call on `sigma_d13c` before
> touching `CCX_PARAM_TABLE`, and do NOT block it on the conveyor. If the conveyor is
> approved, build it to §4's spec and run 4.5's reverse-conveyor gate FIRST — by §2's
> theorem it must not tie, and if it does, the wiring is wrong.
