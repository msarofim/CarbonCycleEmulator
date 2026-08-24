# PRE-REGISTRATION — the ocean probe as a LEVERAGE instrument, rate scan

**Written 2026-08-24, BEFORE any of the four refits was launched.**
Marcus, this session: *"I was worried that fitting to the plateau was making the pre- and
post-plateau model worse. It seems like some combination of reducing emissions or artificially
injected atmospheric carbon into the oceans should be able to take the tension off of that
decade."*

---

## The design

Four refits, arm N, `luc_scale` **FREE** (Marcus's call), `CCX_SINK_MODE=ocean`, at rates
**0 / 2.5 / 9.434 / 15 GtC/yr** over 1942–49. Scoping `RESTARTS=8, CYCLES=2` — **identical to the
two 2026-08-23 sink runs on disk**, so the scan is like-for-like with them. Warm-started from the
adopted mode. **The rate-0 arm is the matched zero point** and exists so the scan is not compared
against a run made at different scoping.

**Why the ocean routing and not the fossil one.** The `foss` probe does two jobs at once:
a plateau-decade correction AND a permanent level shift (its CO₂ signature is still 42 % of its
1950 value at 2024). The second job is `luc_scale`'s and `rep_dC`'s, which is why `luc_scale`
routed around it twice. The ocean probe's signature is **3.3 %** of its 1950 value by 2024 — it is
the first **temporally local** instrument in this arc, and a global emissions rescale (whose
signature *grows*, to 196 % by 2024) cannot imitate it.

**Its implausible magnitude is not a defect.** As a physical ocean sink 9.4 GtC/yr is absurd
(today's whole global ocean sink is ~3). As a *probe* it is prescribed, unfitted, carries no free
parameter and is labelled artificial — it asks a counterfactual, not a mechanism.

---

## P1 — THE PREDICTION THAT MATTERS

**`rep_dC` will barely move.** `rep_dC` is a common-mode CO₂ level offset across the whole record
(97 % common-mode), and a probe whose CO₂ effect is 96.7 % gone by 2024 has almost nothing to
offer it. **Predicted |Δ`rep_dC`| < 0.5 σ at every rate**, against the `foss` probe's 5.57 → 5.13
(free) and 5.57 → 4.10 (pinned).

**If P1 holds it is the decisive result of this arc**, because it separates two things the `foss`
probe had welded together:
- *"the plateau decade is distorting the fit"* — local, and this probe tests it cleanly;
- *"the model has a century-long CO₂ level drift"* — real, already traced to GCB's own budget
  imbalance (r = 0.771), and **not the plateau's fault**.

**If P1 FAILS** — `rep_dC` falls substantially on a probe that is 97 % gone by 2024 — then my
account of `rep_dC` as a common-mode level offset is wrong, and that is worth more than the
plateau question.

## P2 — the decade itself

The ice-core residual over 1942–1950 will move **monotonically more negative with rate**, and the
`co2_icecore` stream will **not** improve monotonically, because at the mode the model is already
1.67 ppm BELOW the ice there (era table, 2026-08-24). A local probe therefore **overshoots** the
window it is meant to relieve. Predicted: `co2_icecore` peaks at low rate and degrades by 15.

## P3 — does it route around?

`luc_scale` moved **+5.52 σ** against the `foss` probe. Predicted here: **|Δ`luc_scale`| < 1 σ**,
because the shape test says it has nothing to gain — its signature is nearly orthogonal.
**If `luc_scale` moves > 2 σ anyway, the shape argument is wrong** and the escape route is not the
one I identified. That is a real falsifier and it is why the runs are FREE rather than pinned.

## P4 — the isotopes stay quiet

`sigma_d14c` will **not** inflate (the `foss` probe pushed it +3.85 σ, 6.13 → 8.96, absorbing a
Suess artefact). Predicted |Δ`sigma_d14c`| < 1 σ at every rate. At the mode the ocean probe pays
**+0.90** on Δ¹⁴C and **+0.68** on δ¹³C, against `foss`'s −66.89 / −6.62.

---

## Gates and known offsets

- **The env-var gate was run before launch**: `CCX_SINK_RATE=9.434 CCX_SINK_MODE=ocean` moves the
  objective at the adopted mode by **−27.9866**, matching the at-mode diagnostic's −27.99 to 4
  decimals. The switch reaches the sampler; the four runs are four different objectives.
- **KNOWN CONSTANT OFFSET, does not affect the scan.** `ccx_make_logpost()` at default bounds
  gives −1858.2676 at the adopted mode where the file says −1859.3225. The refit driver
  renormalises the `h_ml` prior over its [85, 120] band; this offset is the same in all four arms
  and cancels in every comparison below. **Do not compare these logposts to the arm files'.**
- Runs are 4-way PARALLEL with BLAS pinned to one thread each (`OMP_NUM_THREADS=1`,
  `VECLIB_MAXIMUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`) — ~158 MB RSS per arm on a 10-core /
  16 GB machine. Unpinned BLAS has cost this project 11 h against 2 h17 before.
- Output: `calibration/output/ocean_probe_scan/rate_*/`. **SCRATCH — never the shipped mode.**

---

# ADDENDUM — the PINNED arms (written 2026-08-24, before launch)

## Why this addendum exists: P3 was FALSIFIED

I predicted `luc_scale` would move < 1 σ against this probe and named **2 σ as the
falsifier**, on the argument that the probe's time-shape (3.3 % of its 1950 effect left by 2024)
is nearly orthogonal to a `luc_scale` rescale's (196 % by 2024), so the escape route was closed
**by construction**.

**Measured: +0.52 / +1.90 / +2.94 σ at rates 2.5 / 9.434 / 15. The falsifier is crossed.**

The argument was wrong in a specific way worth recording: **a fit does not need to MATCH a
perturbation's shape to route around it — it only needs to trade enough likelihood elsewhere.**
Orthogonality bounds how *efficiently* a lever can absorb a perturbation, not *whether* it can.
Measured efficiency at matched window-end CO₂ effect: `luc_scale` moves **+5.52 σ** against `foss`
and **+1.90 σ** against `ocean` — 0.34×. Narrowed, not closed.

**Consequence: the free runs cannot settle Marcus's question.** `rep_dC` stays put (+0.16 / +0.32 /
+0.21 σ), but with `luc_scale` free at ~3 σ I cannot separate *"the plateau does not drive
`rep_dC`"* from *"`luc_scale` absorbed the relief before `rep_dC` saw it."* Marcus's call
(2026-08-24): **pin `luc_scale` and rerun 9.434 and 15.**

## Design

Two refits, arm N, `CCX_SINK_MODE=ocean`, rates **9.434** and **15**, `CCX_PIN_LUC_SCALE` at the
**rate-0 converged value 0.8983759151** (the sink-OFF value — the same logic as 23c's 0.8984 pin,
but taken from this scan's own matched zero rather than a rounded literal). Scoping and warm start
as before; each dir seeded with the **rate-0 mode**, whose `luc_scale` already sits exactly at the
pin so the warm start is admissible under the near-delta prior.

**A pinned run's Laplace evidence is NOT comparable to an unpinned one** — its `luc_scale` prior
has been replaced. Read parameters and per-stream logL, never evidence.

## P5 — THE PREDICTION

**`rep_dC` will still not fall.** Predicted **|Δ`rep_dC`| < 0.5 σ** at both rates, against the
`foss` probe's pinned **5.566 → 4.102 (−1.46, ≈ −21 σ in these units)** at matched CO₂ effect.

**The falsifier is sharp and I want it on the record after getting P3 wrong:** if pinned `rep_dC`
falls by **more than 1 σ** at either rate, then relieving the plateau decade DOES relax the level
offset, my account of `rep_dC` as a century-scale common-mode drift is wrong, and Marcus's original
worry is confirmed rather than redirected.

## P6 — where the relief will go instead

With `luc_scale` shut, I expect the **(`beta_max`, `fert_k`) ridge** (ρ = +0.997) to take over —
it already moved −0.84 / −1.12 σ at rate 15 with `luc_scale` free, and it was the route the pinned
`foss` run used (0.93 → 2.70 and 423 → 1738). Predicted **> 1.5 σ on both** at rate 15.

If BOTH `rep_dC` and the ridge stay quiet, then the probe's cost is simply not recoverable, which
is itself informative: it would mean the plateau window carries no leverage over any fitted
parameter, and the ~15 log-units the free run recovered were bought entirely by `luc_scale`.

## P7 — the isotopes, again

`sigma_d14c` stays within **1 σ** (it was −0.15 free). The pin cannot change that: the probe's
Δ¹⁴C excursion is 0.12–0.16 ‰ by construction and there is no Suess artefact to absorb.
