# Red team — conveyor configurations, before anything is built

**CarbonCycleEmulator, 2026-08-13, branch `luc-veg-debit` at `7db1a5a`.** Marcus approved
building the conveyor and asked for a red-team review of the available configurations,
through four lenses: **ocean**, **atmosphere**, **isotope**, **reduced-complexity
modeling**. He also asked that the review cover the *refit* — "once it is in properly,
the other constants might all shuffle around into a new equilibrium and I would like to
test that" (§6 below, and it is the best part of the proposal).

Everything numeric here is computed from the model's own constants
(`scratchpad/rt.R`, folded into `calibration/scoping_conveyor_arithmetic.R`), not
transcribed from handoff 13b.

---

## 0. The four findings that should change the plan

1. **§4.3's headline arithmetic is computed on a volume that §4.2's plumbing does not
   traverse.** §4.3 divides by `V_deep` = the whole sub-mixed-layer ocean, 1.309e18 m³.
   Under §4.2's own four limbs the water path is NH bottom → SH bottom → up the SH column
   → SH ml → NH ml, which is **9.13e17 m³, 70 % of `V_deep`**. **NH `oc1`–`oc9` — 30 % of
   the deep ocean — receives no advective flux at all.** (§1, Ocean.)

2. **Correcting that, and §4.3's own source-water caveat, the two errors nearly cancel.**
   Sv needed for a deep Δ¹⁴C of −170 ‰: 27.1 on `V_deep` ignoring source water (§4.3's
   headline), 37.7 with §4.3's own correction, **18.9 on the real path, and 26.3 with
   both.** So §4.3's headline number survives — but by cancellation, and **its own hedge
   ("moves the −170 point to ~37 Sv") is too pessimistic by 11 Sv.** The conveyor's
   strongest selling point is in better shape than the handoff thinks.

3. **But 27 Sv is far above the measured AMOC.** RAPID at 26°N gives **16.9 ± 1.2 Sv**
   (Apr 2004–Dec 2020, [Moat et al./RAPID](https://pmc.ncbi.nlm.nih.gov/articles/PMC10590663/)).
   §4.3's "27 Sv is squarely inside the observed overturning range" is defensible only for
   *global* overturning including the AABW cell, not for the quantity with the error bar.
   At 16.9 Sv on the real path with no diffusion, the deep goes to **−229 ‰**, outside the
   model's own [−150, −200] bracket. **So the honest target is a joint (Q, kz) result, not
   "transit alone"** — and that is a *weaker and much more achievable* claim. (§1.)

4. **The preindustrial ocean column is exactly uniform in DIC** — 2.0379 mol/m³ at all 11
   levels, verified. The conveyor is therefore **exactly neutral for preindustrial ¹²C**
   and does its work only on isotopes and on the anthropogenic transient. It **cannot**
   fix the ~14 % low ocean carbon inventory and **cannot** create deep carbon storage.
   Anyone selling the conveyor as "putting the biological pump's job into the model"
   should be stopped. (§3, Isotope.)

---

## 1. THE OCEAN EXPERT

**The single strongest argument for building this, and it is not δ¹³C.** `kz` = 5000 m²/yr
is **~9× the measured thermocline diapycnal diffusivity**: Ledwell's NATRE tracer release
at ~300 m in the subtropical NE Atlantic gives **(1.7 ± 0.2) × 10⁻⁵ m² s⁻¹ = 536 m²/yr**.
The model's interior diffusivity is not an eddy diffusivity; it is a fiction standing in
for ventilation, exactly as §4.3 says. A conveyor is the mechanism that lets `kz` fall
toward a number an oceanographer would recognize. **That is worth doing on its own, and it
is independent of whether δ¹³C improves.**

**Against Config A as specified — the mid-depth dead zone.** Sending the NH mixed layer
straight to `oc10` (2628–3700 m) leaves NH `oc1`–`oc9` fed by `kz` alone. Today `kz` = 5000
papers over that. **Under the conveyor `kz` is supposed to fall a long way (§4.5 step 3),
and then the NH interior becomes genuinely stagnant while the NH bottom box is directly
ventilated** — young bottom water underneath anomalously old mid-depth water. **The
Atlantic does not look like that.** It is well ventilated top to bottom; the inversion the
model would produce is an artifact of a non-local pipe past nine boxes.

**Also: the depth is wrong for the water mass being named.** `oc10` is bottom water. NADW
occupies roughly 1500–3000 m — the model's `oc8` (1314–1861 m) and `oc9` (1861–2628 m).
The *bottom* is AABW territory, and AABW forms in the **Southern** Hemisphere. Config A
therefore labels its limb "NADW" while plumbing it to the depth of the water mass formed
at the opposite end of the world. In a two-column model that conflation may be tolerable —
but it should be a stated simplification, not an accident of picking the last box in the
array.

**The advective limb is a first-order term, not a perturbation.** At 27 Sv it carries
**20.8 GtC/yr** of DIC around the loop, against **27.1 GtC/yr** of gross air–sea exchange.
Expect the spinup, the substep controller and the stability bound all to notice. §4.2's
claim that a uniform column remains an exact fixed point is correct and is what keeps
`ccx_spinup()` intact — but "neutral at the fixed point" is not "small".

**Verdict:** build it, but not Config A. Distribute the descending limb, or sink to NADW
depth, or both (Configs B/C, §5).

---

## 2. THE ATMOSPHERE EXPERT

**The conveyor's one genuinely independent, already-scored prediction is the
interhemispheric gradient — and it is the thing most likely to break.** The model's
MLO−SPO δ¹³C gradient is **−0.218 ‰ against an observed −0.074 ‰, 3× too large**, and
nothing in the §3 advection work moved it (−0.226 at `w_out_SH` = 4). §4.4 predicts the
conveyor shrinks it. **It should — and it may sail straight past zero.**

Here is why the risk is real. Today the *only* interhemispheric coupling is atmospheric
(`tau_ex` ≈ 1.3 yr, fitted 0.86). The conveyor adds a **second** interhemispheric channel,
in the ocean, moving ~21 GtC/yr of DIC directly from the SH mixed layer into the NH mixed
layer. That surface return limb is a large, direct, hemisphere-to-hemisphere carbon flux
that the model has never had. **`tau_ex` was fitted to carry the whole gradient by itself.**
Adding a parallel channel and *not* refitting `tau_ex` would be a straightforward
misattribution — which is exactly Marcus' "the other constants shuffle" point, and it makes
`tau_ex` the parameter to watch first (§6).

**The atmospheric misfit this is all meant to fix is 21–25 %, and it is the *rate*, not a
level.** From `diag_oceanic_suess.R`: the model's atmospheric δ¹³C declines
0.282 ‰/decade against 0.226 observed (Law Dome), reproduced against Scripps flask
(0.291 vs MLO 0.256 / SPO 0.233). A mechanism that shifts the level without slowing the
decline will not close this.

**And the gate that already exists.** The ml Suess rate is now scoreable and the model is
**at** the observation (0.156 vs Quay's 0.160 ± 0.020). The conveyor's δ¹³C mechanism *is*
a cut in ml depletion: **−2.2 σ at 15 Sv, −3.2 σ at 27 Sv** (upper bounds — a falling `kz`
pushes back the other way). **The atmosphere expert's summary: this proposal spends a
constraint that currently passes, to fix one that fails, and both are now measured.**

---

## 3. THE ISOTOPE EXPERT

**The decoupling on offer is real, and it is the cleanest thing in the whole proposal.**
Because the preindustrial column is *exactly* uniform in DIC (2.0379 mol/m³ everywhere)
but strongly graded in Δ¹⁴C (−51 ‰ at the ml → −187 ‰ at the bottom), **advection is a
pure isotope operator in the preindustrial state.** It moves ¹⁴C age and δ¹³C and moves
zero net carbon. That is precisely the separation `kz` cannot provide, and it is why the
deep age could become *derived* rather than bounded.

**The corollary, which is a limitation and must be said out loud:** the same uniformity
means **the conveyor cannot fix the ocean's ~14 % low carbon inventory** (model ≈ 32,700
GtC against ~38,000 observed) and cannot produce the real ocean's vertical DIC gradient,
which is biological-pump + Suess, not circulation. The model has no biological pump. **A
conveyor is not a soft-tissue pump wearing a hat.**

**On the "compensating errors" caveat from `diag_oceanic_suess.R`, sharpened.** I inferred
there that an atmosphere 25 % too fast driving a mixed layer exactly on observation implies
air–sea ¹³C transfer ~20 % too weak. **That inference is now in tension with a number I
should have checked: the model's isotopic equilibration time is τ_eq = C_ml/F_gross =
10.5 yr (NH), 10.0 (SH) — which is the textbook mixed-layer ¹³C equilibration timescale,
not obviously 20 % wrong.** Isotopes ride the *gross* flux and are unbuffered, so this is
one of the model's better-grounded quantities. **If τ_eq is right, the 20 % has to live
somewhere else** — the most likely candidates being `h_ml` (179 m at the mode, 88 % of the
way up its [30, 200] bound — a large ml is exactly how a model buys isotopic inertia it
cannot get from ventilation) or the interior `kz` export. **This is a live question, not a
settled one, and it is a reason to build: the refit is what distinguishes them.**

**A diagnostic the isotope lens demands and §4.5 half-asks for.**
`ccx_spinup()$diagnostics$d14c_deep_ocean` averages *both* hemispheres' bottom three
layers. Under any conveyor that is meaningless — the ventilated end comes out young and
the far end old, which is the observed young-North-Atlantic / old-deep-Pacific pattern and
would be a structural *win*. **Split the diagnostic per hemisphere before reading it, and
before the reverse-conveyor gate, or the gate will be read off an average that hides the
signal it is testing for.**

---

## 4. THE REDUCED-COMPLEXITY MODELING EXPERT

**The communications case is the strongest part of the proposal and it survives this
review — but only in its honest form.** "Water sinks in the North Atlantic, crosses the
world at depth, and comes back up in the Southern Ocean about a thousand years later" is
one number and one sentence, and it is the single piece of ocean circulation the target
undergraduate has already met. Against DESIGN §2's rejection of HILDA ("too many parameters
to communicate"), **one Q is not HILDA.**

**What I will not let it be sold as.** §4.3's "27 Sv reproduces the observed −170 ‰ from
transit alone" is the seductive version and it should be **retired**, for three separate
reasons now established: the volume is wrong (§0.1), the honest figure with source water
is 26.3 Sv not 27 (§0.2), and 26 Sv is still ~8σ above the AMOC that actually has an error
bar (§0.3). **The claim that survives is: "an overturning in the observed range, plus a
defensible eddy diffusivity, together put the deep ocean at the observed age."** That is
weaker, true, and *still* a large improvement on "we bounded `kz` until the deep age came
out right."

**Parameter accounting, which is the real cost.** 16 → 17 parameters, and **`kz`'s
[3830, 6200] bracket must be deleted, not carried across** — 12d §6 derives it by bisection
on the pure-diffusion column, and it is conditional on that structure. So the honest count
is *one parameter added and one constraint removed*, which is a bigger change to the
posterior than "+1 parameter" suggests. **Q and `kz` are a degenerate pair — both ventilate
the interior** — and freeing both without a new constraint will produce a ridge, not a
mode. **The deep-Δ¹⁴C likelihood term that 12d §0 step 2 already calls for is now a
prerequisite, not a nice-to-have**, and Quay's ml Suess rate is the second leg.

**Cost realism.** §4.2's "half a day" covers the plumbing. It does not cover: the
per-hemisphere deep diagnostic, the reverse-conveyor gate, the new likelihood terms, the
`kz` bracket re-derivation, and **~4 h per `run_modefind.R` refit** — of which this needs
at least two (off and on) and realistically four. **Budget 2–3 days, not half a day.**

**The v2-backlog question is now live.** DESIGN §2/§10 put ocean advection in the v2
backlog. This review does not overturn that; it says the v2 item has become cheap enough
and well-motivated enough to promote. **That is a DESIGN decision and it should be recorded
as one**, not arrived at by a diagnostic's momentum.

---

## 5. THE CONFIGURATIONS

| | shape | params | pro | con | verdict |
|---|---|---|---|---|---|
| **A** | §4.2 as written: NH ml → NH `oc10` (non-local), `oc10`→SH `oc10`, SH distributed upwelling, SH ml → NH ml | +1 (Q) | cheapest; §4.2's conservation and spinup arguments hold exactly; breaks §2's symmetry on both premises | **NH `oc1`–`oc9` unventilated (30 % of the deep ocean)**; inverted NH profile once `kz` falls; "NADW" plumbed to AABW depth | **No** — not as the only build |
| **B** | A, but the descending limb is **distributed** (NH ml→`oc1`→…→`oc10`) instead of a non-local pipe | +1 (Q) | removes the dead zone; NH column advectively ventilated top to bottom; still one number | NADW really *is* a narrow fast plume — distributed descent is the less physical of the two; slower NH deep ventilation | **Build alongside A** as the A/B pair |
| **C** | Sink to **NADW depth** (`oc8`/`oc9`), interhemispheric limb at that level, SH upwelling above it, deepest boxes diffusive | +1 (Q), +1 structural choice | physically the most defensible single cell; keeps a genuinely old abyss | the abyss is then still `kz`-ventilated, so `kz` falls less — weakens the headline win | **Strong candidate**; the ocean expert's preference |
| **D** | **Two cells**: NADW (NH ml→`oc8`) + AABW (SH ml→`oc10`), two interhemispheric limbs | +2 (Q_N, Q_A) | the actual global structure; would give young NH deep *and* old deep Pacific *and* a cold abyss | 2 correlated params on top of a `kz` that is already degenerate with them; DESIGN §2's HILDA objection starts to bite | **Not now** — revisit only if C succeeds |
| **E** | **Second surface box** (outcrop / HILDA-lite) — the *other* thing §2's theorem permits, since it changes the ml's own budget | +2–3 | attacks the ml disequilibrium directly, which is where the δ¹³C mechanism actually lives; no interhemispheric plumbing | DESIGN §2 rejected HILDA on communicability, and this is HILDA's thin end; more params, less story | **No** — but it is the fallback if C fails |
| **F** | **Null**: build nothing, set `sigma_d13c` = 0.45 ‰ as model-structural error, make `kz`'s fiction explicit in the docs | 0 | free; already argued and supported | leaves the deep age bounded rather than derived, and `kz` at 9× NATRE | **The baseline every other config must beat** |

---

## 6. THE REFIT — Marcus' actual question, and the best part of the proposal

> *"once it is in properly, the other constants might all shuffle around into a new
> equilibrium and I would like to test that"*

**This is right, and it is what converts the compensating-errors caveat from an objection
into an experiment.** The δ¹³C benefit estimated in §4.3 (0.15–0.25 ‰) and the ml-Suess
cost estimated in `diag_oceanic_suess.R` (−2.2 to −3.2 σ) are both **single-parameter
perturbations of a fitted model**, and neither is what the model will actually do once
every other parameter is free to move. **Do not decide the conveyor on either number.**

**The design:**

1. **Prerequisites before any refit.** Per-hemisphere deep-Δ¹⁴C diagnostic (§3);
   deep-Δ¹⁴C likelihood term (12d §0 step 2) to replace the `kz` bracket; Quay's ml Suess
   rate as a second ocean term. **Without these, Q and `kz` are degenerate and the refit
   finds a ridge.**
2. **The reverse-conveyor gate first** (§4.5 step 1), before any fitting. By §2's theorem
   the reversed conveyor **must** give a different atmosphere. If it ties, the wiring is
   wrong — and read it per hemisphere, not off the averaged diagnostic.
3. **Four refits, not one:** baseline off; A; B; C. Same likelihood, same terms.
4. **Compare parameter vectors, not just log-posterior.** A better fit bought by driving
   `k_w` or `h_ml` somewhere indefensible is not a better model — that is the `k_w` lesson
   from the 2026-08-13 entry.

**Four falsifiable predictions the refit should be scored against, stated now so they
cannot be retrofitted:**

| parameter | now | prediction under a working conveyor | why |
|---|---|---|---|
| `kz` | 6031 (mode), bracket [3830, 6200] | **falls a long way**, toward 500–2000 | the conveyor takes over ventilation; NATRE says 536 |
| `h_ml` | **179 m**, 88 % of the way up its [30, 200] bound | **falls** | a too-deep ml is how the model currently buys isotopic inertia it cannot get from ventilation |
| `tau_ex` | 0.856 yr | **rises** (weaker atmospheric coupling needed) | the ocean now carries part of the interhemispheric transport |
| MLO−SPO δ¹³C | −0.218 ‰ vs −0.074 observed | **shrinks — and watch for overshoot past zero** | §4.4's claim, and §2's risk |

**If `kz` does not fall and `h_ml` does not come down, the conveyor is not doing the job it
was proposed to do**, whatever happens to the log-posterior.

---

## 7. RECOMMENDATION

**Build C, with B as the cheap comparison, and keep F as the scored baseline.** Skip A as a
final answer (build it only as the intermediate that B and C are diffed against, since it
is what §4.2 already specifies). Defer D and E.

**Do not touch `CCX_PARAM_TABLE` before the σ decision** — that is still open and still
blocking, and this review does not change the 0.45 ‰ argument.

**Retire the "27 Sv reproduces −170 ‰ from transit alone" headline.** Replace it with the
joint (Q, `kz`) claim, and use RAPID's 16.9 ± 1.2 Sv as the prior's anchor with an explicit
note that global overturning exceeds the 26°N AMOC.
