# PLAN 2026-08-29 — **THE ORDER TO IMPLEMENT THE CHANGES**
# Recommendation, with the reasoning and the dependencies. **Marcus's call to approve or reorder.**

## ⇒ APPROVED (Marcus, 2026-08-29), WITH ONE CHANGE

**"Then go ahead with volcanic diffuse-light followed by the objective C1 and the seasonal tau_ex.
Hold off on four-box."**

⇒ **① → ② → ③ approved and in flight. ④ (four-box) is HELD — do not start it.** ⑤ (per-box NPP lag)
is unchanged in position and therefore also waits on ③. The hemispheric TAB is likewise deferred
until the component is fixed.

**STATUS: ① IS DONE** (2026-08-29, `328cdb8`) — see
`notes/collect_2026-08-29g_diffuse_light_landed.md`. Mechanism wired R+C++ with tests, `gamma_diff`
defaults to 0 so nothing existing moved, and **r rises 0.571 → 0.625**. ⚠ Not adopted: the frozen
cost needs a CONDITIONAL profile first. **② is next.**

## 0. THE SEQUENCING PRINCIPLE

**Every structural change makes every fitted vector non-comparable and costs an ~18 h refit** (this
is what `2153bd6` did on 08-28 and it is still costing us). So the order is chosen to:

1. do **ADDITIVE** changes (new mechanism, new parameter) before **RESTRUCTURING** ones;
2. never do a change whose ANSWER would be rewritten by a later one;
3. do the cheap TEST of a structural hypothesis before its expensive IMPLEMENTATION;
4. fix the things that make refits themselves better-behaved EARLY.

## 1. THE RECOMMENDED ORDER

### ① VOLCANIC DIFFUSE-LIGHT FERTILISATION — *do this first*
**Why first.** It is the only change that adds a **MISSING MECHANISM** rather than re-partitioning
an existing one; it is additive (one forcing + one parameter, no restructure); the defect is the
largest single miss in the record (**Pinatubo: model +0.04 vs observed −1.94 ppm/yr, ~0 %
reproduced**); the thermal path is measured to be capable of at most ~7 %, so nothing already in the
model can be tuned to cover it; **the AOD series now exists** (`data/forcing_volcanic_aod.rds`,
08-29); and **the tool needs it** — tab 1's volcano checkbox and input graph cannot be built without
it. It also interacts with nothing else on this list.

### ② MAKE THE OBJECTIVE C1 IN `h_ml` — *do this second, before any refit*
**Why here.** `h_ml` is the softest direction of a Hessian conditioned **1.11e6** and its objective
is **not even C1** (pump `1/eps` kinks) — that is why there is no posterior
([[ccx_hessian_is_the_blocker]]). **Every refit after this point is better-behaved if it is fixed
first, and every refit before it re-inherits the problem.** It is a code fix, not a science change,
and it is independent of ①③④⑤.

### ③ SEASONAL `tau_ex` — *the CHEAP test of the transport hypothesis*
**Why before the box rebuild.** Gate 5 measured the structural tension today: the gradients pin
`tau_ex` at **1.159 yr** (sharp interior optimum) while the bomb-¹⁴C lag needs **~2.3 yr**, and the
gradient outvotes it by three orders of magnitude. A **seasonally varying** exchange rate broadens
the effective transit-time distribution — a pulse injected in March and one in September see
different transports — which is the same mean-vs-shape separation a box rebuild buys, **at 2
parameters instead of a restructure**. It is physically motivated (ITCZ migration), and it would
also modulate the SPO seasonal NH-import (0.821 ppm at month 6.5) in **both amplitude and phase**,
which touches the θ problem. **If it resolves the tension, ④ is not needed.**

### ④ FOUR-BOX ATMOSPHERE — *only if ③ fails*
N-extratropics / N-tropics ‖ S-tropics / S-extratropics, with the slow step at the ITCZ.
**Marcus is right that one tropical box is wrong**: a single box straddling the equator mixes across
it instantaneously, putting the model's fastest mixing exactly where the barrier belongs. Observed
interhemispheric exchange is ~1.3–1.4 yr against ~1–2 months for intra-hemispheric meridional
mixing — a ~10× error in the wrong place.
**Second payoff, and it may be the larger one:** the current SH box averages two ANTIPHASE regimes
(subtropical limb month 1.4, Southern Ocean month 7.5) and matches the residual, **neither regime**
([[sh_ocean_weighting_not_phase]]); SPO's observed ocean limb at **8.52 months** is the Southern
Ocean, which the model cannot currently represent. ⚠ **To get that second payoff the OCEAN surface
must be split too, not just the atmosphere** — that is the expensive part, and it is why this is ④
and not ①.

### ⑤ PER-BOX NPP LAG — *after the box structure is settled, not before*
`seas_lag_p` → per-box. **Deliberately demoted from where it sat this morning.** It is cheap and it
has a registered prediction (the NH's −788 disappears, leaving ~−35 to −50 against SH land
1.308 → ~1.07), **but ③/④ change what "per hemisphere" means** — with four boxes you want four
lags, not two. Doing it first means doing it twice.

### ⑥ GATE 7 LAND SINK — *independent; slot where convenient*
Land **+2.30 σ** (3.56 vs GCB 2.410 ± 0.50). Confirmed **independent of the seasonal defect**
(08-29e: the seasonal fix moves it by +0.001 where it needs −1.148, and the path is structurally
absent). ⚠ **New and untested link:** `gcb_land_sink` is also the largest single objector to more
ENSO (−21.72 of −62.63, 08-29f). Two arcs now touch this row.

### ⑦ ENSO RESPONSE SHAPE — *lowest fit priority, and NOT what the tool needs*
08-29f settles it: **r ≈ 0.57 at every amplitude from γ = 0.4 to 4.0**, so turning ENSO up makes the
model louder, not righter, and the missing 2/3 of the variance is not ENSO amplitude. Any real
improvement is a change to the RESPONSE SHAPE (lags, hydrology, fire), which is a research project.
**The tool's ENSO checkbox needs a forcing decomposition, not a model change** — see the spec note.

## 2. WHAT RUNS IN PARALLEL

**The app work is mostly plumbing and does not wait on ①–⑦**, with one exception: **tab 1's
checkboxes need an attributable decomposition of observed GMST** (see
`notes/spec_2026-08-29_app_six_tabs.md` §3), and that is a data/method job that can start now.
The volcanic AOD input graph is available immediately.

## 3. THE ONE THING I WOULD CHANGE IF PUSHED

If the goal is the **TEACHING TOOL** rather than the fit, ① and the forcing decomposition are the
whole critical path, and ②–⑦ can wait. If the goal is the **MODEL**, ② and ③ are the highest value
per unit of work. **They disagree, and that is a real choice about what this project is for.**
