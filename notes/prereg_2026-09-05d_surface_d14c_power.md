# PRE-REGISTRATION — does the preindustrial LS-surface Δ¹⁴C have POWER as a gate,
# BEFORE any target is sourced for it?
# Written 2026-09-05d, before `calibration/diag_surface_d14c_power.R` existed.

Marcus, 09-05: *"Score GEOSECS LS-surface Delta14C as a gate first."*

## 0. WHY POWER COMES BEFORE THE TARGET

⛔ **THE TARGET IS NOT SOURCED YET AND I AM NOT GOING TO PRETEND IT IS.** The value in play,
**−40 ± 20 ‰**, is **prescribed in HILDA's Table 2** — a model calibration paper — attributed there
to GEOSECS. **I have not read the primary.** Searching found the right product (GLODAP's mapped
**natural / pre-bomb Δ¹⁴C**, Key et al. 2004 *GBC* 18:GB4031 via the Rubin & Key 2002 potential-
alkalinity separation) but it is a gridded field that is **not in this repo and would have to be
downloaded**, and coral compilations give REGIONAL values (e.g. −58 ‰ at 18 °S in the early 1950s),
not the area-weighted 0–134 m mean over 84 % of a hemisphere that this model's box actually is.

**So this note deliberately measures the thing that needs no target.** A gate on a quantity with no
power is worthless however well its threshold is sourced, and the standing rule is to **measure a
test's POWER before believing its null**. If the power is there, the target becomes worth acquiring;
if it is not, nothing is lost by not acquiring it.

⚠ **SCOPE: the SHIPPED model, `hs_frac = 0`, 32 boxes.** A gate is for the model that ships, not for
the experimental structure. `ent26`, all 26 parameters at the mode except the two being scanned.

## 1. WHAT IS BEING MEASURED

The preindustrial **low-latitude mixed-layer Δ¹⁴C**, area-weighted across NH and SH, over a 2-D scan
of the two parameters the 09-05c result implicated:

* **`k_w`** across **±2σ of its OWN prior** (lognormal, median 1500, σ_log 0.40) ⇒ **674 … 3338 m/yr**.
  ⚠ **HILDA's gas exchange corresponds to `k_w` = 906, which is −1.26σ — INSIDE our own prior.** The
  arm GEOSECS excluded is not exotic.
* **`kz`** across its shipped bracket **[4379.1, 8109.9]** (the 09-01 re-bisection).

## 2. THE PREDICTIONS

### P1d — RANGE: does the quantity move at all across the prior support?
**PREDICT: the preindustrial LS-surface Δ¹⁴C spans more than 20 ‰** across that box — i.e. more
than the width a ±20 ‰ target would assert.
**FALSIFIER: it spans less than 20 ‰** ⇒ the observable cannot discriminate anything the prior
already allows, and **no target is worth acquiring.**

### P2d — INDEPENDENCE, which is the one that decides whether it is NEW information
A quantity that moves only where the likelihood already objects carries nothing new. So:
**PREDICT: there exists a direction in (`k_w`, `kz`) along which the surface Δ¹⁴C moves by more than
20 ‰ for a logpost cost of LESS THAN 2 units** — i.e. inside the region the existing objective
treats as roughly equivalent.
**FALSIFIER: every 20 ‰ of surface Δ¹⁴C costs more than 2 logpost units** ⇒ the existing streams
already pin this quantity, the gate would be **redundant**, and it should not be built.
⚠ **This is the whole question.** The likelihood already scores atmospheric zonal Δ¹⁴C, the bomb
inventory (Naegler & Levin) and the deep bottom box — but **NOTHING on the ocean surface**, which is
why the quantity is a candidate at all. Whether that absence is real or only apparent is what P2d
measures.

### P3d — DIRECTION, reported not gated
**PREDICT: surface Δ¹⁴C rises (gets younger) with `k_w` and falls (gets older) with `kz`**, because
gas exchange pulls the surface toward the atmosphere and vertical mixing supplies old water. This is
the mechanism the 09-05c pair (−29.8 at `k_w` 1788 / `kz` 1900 vs −78.5 at 906 / 5334) implies, and
if it does not hold, that reading was a coincidence of two moves rather than a coupling.

## 3. WHAT IS NOT CLAIMED

- **No gate is built here, and no threshold is asserted.** ⚠ The 20 ‰ in P1d/P2d is a **stand-in for
  a target width**, taken from HILDA's stated ±20 so that the power question has a scale at all. It
  is NOT a sourced sigma and must not become one by being used here.
- **No fit, no adoption.** `hs_frac = 0` throughout; the HILDA boxes are not involved.
- **Nothing about the modern surface.** GLODAP's measured surface Δ¹⁴C is bomb-dominated at every
  bottle epoch in the file (1972–2021) and is a different observable with a different sigma; it is a
  separate question, not this one.
