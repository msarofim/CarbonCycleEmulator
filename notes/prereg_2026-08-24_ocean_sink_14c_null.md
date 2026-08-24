# PRE-REGISTRATION — the artificial mid-century sink, routed into the ocean box

**Written 2026-08-24, BEFORE any arm was run.** Required by
`handoff_2026-08-23c_ocean_box_next.md` §4d.5. Code state: the ocean routing is
built in `R/model.R` + `src/ccx_core.cpp` and gated, but no scoring run has been
executed at the time of writing. Commit that carries this file also carries the
build; the arms come after.

---

## What is being tested

Three arms remove the **same 2.5 GtC/yr over 1942–1949 (20 GtC total)** and
differ ONLY in what the removed carbon's isotopic signature is:

| arm | destination | δ¹³C of the removed carbon | ¹⁴C |
|---|---|---|---|
| `foss` | never emitted | −28 ‰ (fossil) | **¹⁴C-FREE** |
| `luc` | stays in the WOOD pool | wood's emergent ratio, ~−25 ‰ | near-atmospheric |
| `ocean` | atmosphere → **mixed layer** | atmospheric × `alpha_as_down` (−2 ‰) | **atmospheric, unfractionated** |

`foss` is the 2026-08-23 incumbent and the pre-bomb Δ¹⁴C record **rejected** it
(NH residual 1950–56 +0.64 → +13.52 ‰, ~52 log-units).

---

## P1 — THE ¹⁴C NULL (the discriminating prediction)

**Prediction:** the `ocean` arm's pre-bomb Δ¹⁴C excursion relative to sink-OFF
will be **at least 5× smaller** than the `foss` arm's, and in absolute terms
**|ΔΔ¹⁴C| < 1 ‰** in every pre-bomb era-hemisphere cell.

**Why, from first principles.** `add_flux` carries ¹⁴C at the *source* box's
ratio with no fractionation, so an atmosphere → mixed-layer flux removes ¹⁴C and
C in exactly the proportion the atmosphere already has. To first order the
*ratio* — which is what Δ¹⁴C measures — is untouched. The `foss` arm instead
removes carbon with **zero** ¹⁴C, so it undoes Suess dilution:
1000 × (airborne share of 20 GtC) / (atmospheric C ≈ 662 GtC at 311 ppm)
≈ 1000 × 11 / 662 ≈ **+17 ‰** at an airborne fraction of ~0.55, against the
+10 to +13.5 ‰ measured. Order of magnitude confirmed.

**Falsifier:** an `ocean`-arm Δ¹⁴C excursion within 2× of the `foss` arm's would
mean the routing is not carrying isotopes at the source ratio, i.e. an
implementation bug, not a physical result.

## P2 — δ¹³C

**Prediction:** the `ocean` arm's atmospheric δ¹³C excursion will be **at least
5× smaller** than the `foss` arm's. The removed carbon is 2 ‰ depleted relative
to the atmosphere (`alpha_as_down`), against ~21 ‰ depleted for fossil
(−28 ‰ against an atmosphere near −7 ‰) — a ratio of ~10.

## P3 — CO₂ LEVERAGE, AND WHY THE ARMS ARE *NOT* CO₂-MATCHED

**This one is a prediction against the handoff's own framing** and it is the
reason it is written down here rather than discovered afterwards.
§4e says "same CO₂ trajectory by construction, so any logL difference is purely
isotopic." **That is true of `foss` vs `luc` and FALSE of `ocean`**, because
`ocean` is the only arm where the carbon stays in the system and the mixed layer
can hand it back.

**The buffered-capacity algebra (MEASURED inputs, `/tmp/cap2.R`):**

- mixed-layer carbon `ml_C0` = **665.41 GtC** (NH 284.28 + SH 381.13), `h_ml` = 75 m
- Revelle at the preindustrial state ≈ **9.6** (NH 9.47, SH 9.79)
- ML capacity per ppm = 665.41 / (9.6 × 276.88) = **0.2503 GtC/ppm**
- atmospheric capacity = `GtC_PER_PPM` = **2.1240 GtC/ppm**
- equilibrium ML share of an atmosphere → ML transfer
  = 0.2503 / (0.2503 + 2.1240) = **0.1054**

⇒ **of the 20 GtC pushed into the mixed layer, ~2.1 GtC stays there and
~17.9 GtC comes straight back**, on the ~1–2 yr air-sea equilibration time,
plus whatever interior diffusion and the pump carry below the mixed layer
during the window.

**Prediction:** the `ocean` arm's atmospheric CO₂ drawdown at the end of the
window will be **8–25 %** of the `foss` arm's, and `rep_dC` will move by
**< 1 σ** at 2.5 GtC/yr (against `foss`'s 5.57 → 5.13 and pinned 4.10).

**This is a result about the HYPOTHESIS, not only about the instrument.** A
mid-century *surface* ocean uptake anomaly cannot hold carbon out of the
atmosphere; only the fraction ventilated below the mixed layer stays down. If
P3 holds, then "an artificial short-term ocean sink" of the literature's 2–3
GtC/yr magnitude does not by itself produce the plateau in this model, and the
choice of what "matched" means in §4e becomes explicit:

- **(a) matched REMOVAL** — 2.5 GtC/yr into the ocean. Physically the stated
  hypothesis; ~10× weaker on atmospheric CO₂ than `foss`.
- **(b) matched ATMOSPHERIC EFFECT** — requires ~10× the rate (~25 GtC/yr),
  which is an order of magnitude outside the literature's sizing and is not a
  plausible ocean sink.

**Both will be run and reported. Which one Marcus wants as the headline is his
call, not mine** (standing rule: methodological choices are explicit).

## P4 — what would make me withdraw the ocean hypothesis

If P1 and P2 hold (the isotopes are near-silent, as ¹⁴C wants) **and** P3 holds
(the CO₂ leverage is ~10× too weak), then the surviving hypothesis explains the
isotopes and fails to explain the plateau, and the honest statement is that
**no arm of this three-arm family explains the 1940s plateau in this model** —
which agrees with Bastos 2016 ("no model reproduces it") rather than resolving
it. That is a null result and it will be reported as one.

---

## Mechanical gates, also pre-registered (§4d.1–4)

1. **Rate 0 reproduces bit-identically**, in all three modes.
2. **Conservation**: total C, ¹³C, ¹⁴C closed to ~1e-10 with the flux on.
3. **The ocean gains exactly what the atmosphere loses**, same tolerance — the
   property the negative-emission version could not have.
4. **R ↔ C++ parity** with the flux on, at the existing tolerances.

`tests/testthat/test-artificial-sink.R`.
