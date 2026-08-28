# PREREG 2026-08-28 — **THE UNBOUND `h_ml` PROFILE, WITH THE UPTAKE PARAMETERS FREE**
# The one configuration never run, and the one that decides whether the [85,120]
# bound is LOAD-BEARING or merely harmless. Committed BEFORE the driver exists.

**State:** repo clean at `ef3f2df`, suite **1164 / 0**, all quarantined outputs regenerated.
**Marcus 2026-08-28: "I would profile h_ml, but lean towards option 5 as being more
scientifically appropriate."** This profile is the evidence that either supports that lean or
upgrades it from *preferable* to *necessary*.

---

## 1. WHY THIS IS THE DECISIVE MEASUREMENT

Two measurements disagree, and neither settles it:

- **08-16g:** the objective's argmax over `h_ml` is **32 m** — the prior bound — with a **236
  log-unit** pull against a **10.0 log-unit** cliff, **24×**. Deleting the three ocean-gradient
  rows moves that argmax **not at all** (32 → 32). ⚠ **Measured with 19 parameters FROZEN.**
- **The refit:** with all 20 free (but `h_ml` BOUNDED), `h_ml` landed **96.47 m, prior z −0.28** —
  **11.47 m clear of the lower edge, not pinned to it.** Had the 236 survived, it would have pinned
  at 85.00, which is exactly what the truncated 16f arms did do.

**The second is strong evidence the pull evaporates when the uptake parameters are free — but it
cannot be conclusive, because the bound was in force and `h_ml` could not have gone below 85
regardless.** "Not pinned at the wall" is weaker than "would not cross the wall".

⚠ **AND THERE IS A NEW REASON TO DOUBT THE REASSURANCE.** The refit's answer was that `kz`, `k_w`
and `beta_max` absorb the CO₂-level misfit `h_ml` was patching. **`kz` now rails at 6332 against a
bracket top of 6528 — 92.4 % of the way up.** That absorptive capacity may be close to exhausted,
in which case `kz` and the `h_ml` bound are propping each other up and neither is free.

## 2. THE DESIGN

Profile `h_ml` across the **SHIPPED** band [30, 200] — the model's own support, *not* the refit's
[85, 120] — re-optimising the uptake set at every point:

    FREE : beta_max, fert_k, k_w, kz, pump_grad          (5)
    FIXED: h_ml (the profiled coordinate) and the other 15

- `beta_max`, `k_w`, `kz` are the three 08-16g named as moving uptake directly and therefore
  serving exactly the CO₂-level streams that pay the 236.
- **`fert_k` is included because it is `beta_max`'s ρ = +0.998 partner** — pinning one coordinate
  of that pair does not hold the pair, and a `beta_max` that moves with `fert_k` frozen is
  uninterpretable. [[fert_shape_is_the_common_cause]]
- **`pump_grad` is free ON PURPOSE**, so that the consequence of the rows switching off is VISIBLE
  rather than suppressed. It is the quantity those rows exist to constrain.

⚠ **5 FREE IS A CONSERVATIVE TEST, AND THE DIRECTION IS ONE-WAY.** The pull exists because `h_ml`
patches a misfit the uptake parameters serve directly; freeing more of them can only reduce it.
**So if `h_ml` stays interior with 5 free, it stays interior with 20.** A null here is therefore
strong; a positive (it runs out) would still need the full-vector check.

⚠ **Encoding.** `u_mode` is band-dependent. The profile re-encodes `h_ml` under the **SHIPPED**
table from `md$par_mode`, leaving the other 20 components untouched (they are band-independent).
The h_ml **prior is the un-narrowed one** — that is the honest comparison, and it means these
logposts are NOT comparable with the bounded runs' (the +1.5805 constant is absent).
[[ccx_hml_band_decode]]

## 3. PRE-REGISTERED PREDICTIONS

- **H1 — the cliff is still there.** The profile is DISCONTINUOUS at 85 and 120, by **≥ 5
  log-units** at 85. *Falsifier:* a jump below 2 means the cliff has changed since 08-16g and
  nothing below is comparable to it.
- **H2 — THE HEADLINE. The conditional argmax over `h_ml` lands INSIDE [85, 120].** *Rationale:*
  the bounded refit sat 11.47 m clear of the edge rather than pinned to it. *Falsifier:* an argmax
  below 85 means **the bound is LOAD-BEARING** — it is holding `h_ml` somewhere the data does not
  want it — and **option 5 becomes NECESSARY, not merely preferable**, because a hard bound would
  then be doing the fit's work.
- **H3 — `kz` comes OFF its rail below the band.** *Rationale:* if `kz` and the bound prop each
  other up, removing the bound should release `kz`. *Falsifier:* `kz` stays ≥ 90 % up its bracket
  at every `h_ml` ⇒ the rail is independent of `h_ml` and is its own separate problem.
- **H4 — `pump_grad` runs above 900 wherever the rows are off**, reproducing 08-16g's 963.6 /
  1431.0. *Falsifier:* it stays constrained with the rows off ⇒ something OTHER than those rows is
  identifying it, and the case for the band weakens further.

## 4. WHAT THIS RUN DOES AND DOES NOT DECIDE

- **It does NOT implement either option.** No objective is changed, no constant or prior is edited,
  nothing in `R/` or `src/` is touched, and no refit is owed by anything it prints.
- **It does not price σ-inflation.** 08-16g's 21 % recovery is **observation-side only** — it has
  never been measured with the model's own gradient included. That remains open whichever way this
  lands.
- ⚠ **A null (H2 holds) does NOT argue against option 5.** It says the bound is *harmless at the
  mode*, not that it is *right*: truncating the softest direction of the posterior at a depth the
  shipped model allows is a claim about belief, not about fit, and this profile cannot speak to it.
