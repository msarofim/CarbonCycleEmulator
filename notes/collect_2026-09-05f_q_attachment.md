# COLLECT — 2026-09-05f. **THE OUTCOME IS CONFIRMED AND THE MECHANISM I PRE-REGISTERED IS REFUTED.**
# **⛔ P1 FAILED: `kz` goes UP, not down. My predicted route was backwards.**
# **⭐ P2 PASSES AND BEATS THE STRETCH: mean|z| 2.048 → 1.739, under the reduced form's 1.81.**
# **⛔ TWO ERRORS OF MINE, BOTH CAUGHT BY MY OWN TESTS — read §4 before quoting P3 or P4.**

Scores `notes/prereg_2026-09-05f_q_attachment_depth.md`. `calibration/diag_q_attachment.R`,
`tests/testthat/test-q-attachment.R`. **Nothing adopted, nothing fitted.** `hs_frac` stays **0**;
`ent26` untouched; `q_attach_from` defaults to **1** = HILDA's depth-independent `q`, bit for bit.

**Marcus's ruling (2026-09-05):** *"We don't need to stay true to HILDA, but we should stay true to
the conceptual way that the simplified model's ocean works."*

---

## 0. SCORECARD

| | prediction | result |
|---|---|---|
| **P0a** | `q_attach_from` = 1 and ABSENT reproduce the 09-05 structure bit-exactly | ✅ **max\|d\| 0.000e+00** |
| **P0a2** | conservation + parity at a SUBSET | ✅ closure **1.08e-16**; R vs C++ **3.55e-14** (incumbent's own 1.14e-13) |
| **P0b** | MUTATION: one layer moves the deep | ✅ **−113.20 → −116.07** |
| **P1** | **bottom attachment RELIEVES `kz`** (< 1900) | ⛔ **FAIL — `kz` RISES to 2686** |
| **P2** | scored mean \|z\| < 2.048 | ✅ **1.739**, and it beats the 1.81 stretch |
| **P3** | the youngening at the scored depths is removed | ✅ on both FREE layers (**−4.1**, **−8.5**); ⚠ my test was mis-built — §4.1 |
| **P4** | HD ages (the pre-check's own risk) | ⛔ **direction WRONG, and I first measured it CONFOUNDED** — §4.2 |
| **P5** | LS mixed layer inside GEOSECS −40 ± 20 | ✅ **−32.6, inside** |

## 1. ⛔ THE PRE-REGISTERED MECHANISM IS REFUTED

The prereg's §1 argued: CCX's interior is pure diffusion, `kz` is forced to ventilate both the upper
ocean and the deep, so giving the deep its own pathway should let `kz` **fall** — as it did in
09-04k2's reduced form (**6356 → 3177, 0.50×**).

**It does the opposite.** Under the same iso-deep control:

| arm | `kz` | `kz`/`kz₀` | HS | HD | LS ml | **mean \|z\|** |
|---|---|---|---|---|---|---|
| attach layer 1 — HILDA, depth-independent | **1900** | 0.299 | −80.3 | −109.2 | −29.3 | **2.048** |
| attach layer 10 — **BOTTOM ONLY** | **2686** | 0.423 | −72.5 | −98.7 | −32.6 | **1.739** |

⇒ **Bottom attachment gets LESS `kz` relief, not more.** The reason is the design choice made
deliberately and pinned by a test: **`tau_q` is NOT renormalised over the subset**, so attaching to
one layer instead of ten is **less total exchange**, not the same exchange concentrated. Less
ventilation ⇒ `kz` must do more, not less.

⚠ **BOTH arms still relieve `kz` against the incumbent** (0.299× and 0.423×). P1 was written against
the *depth-independent* arm, and that is the comparison that fails.

## 2. ⭐ THE OUTCOME HOLDS, AND IT IS ATTRIBUTABLE TO THE ATTACHMENT

⚠ **The decomposition below is POST HOC** — written after P1 failed. It needs its own prereg before
anything is built on it.

Hold `kz` FIXED and vary only the attachment (off the iso-deep control):

| `kz` | attach | bottom box | 1622 m | 2268 m | 3172 m | mean \|z\| |
|---|---|---|---|---|---|---|
| 1900 | indep | **−156.1** ✅ on target | −134.7 | −148.3 | −156.1 | 2.048 |
| 1900 | bottom | −171.7 ⛔ off control | −162.1 | −180.9 | −171.7 | *0.377* |
| 2686 | indep | −143.3 ⛔ off control | −120.9 | −134.6 | −143.3 | *3.092* |
| 2686 | bottom | **−156.1** ✅ on target | −138.7 | −156.7 | −156.1 | 1.739 |

GLODAP at those depths: **−165.2 / −175.6 / −177.6**.

⭐ **At MATCHED `kz` the bottom attachment dominates at BOTH values** (0.377 vs 2.048; 1.739 vs
3.092). So the P2 gain **is** the attachment — the prereg's "if P2 improves while P1 fails the gain
came from somewhere else" clause does **not** apply here, and the decomposition is what shows it.
⛔ **But the two italicised scores are OFF the iso-deep control and are NOT comparable scores** —
they are reported to decompose, never to quote.

⇒ **THE MECHANISM, RESTATED FROM THE MEASUREMENT.** Removing the youngening ages the whole column
hard; the iso-deep control then claws part of it back by **raising** `kz`; the residual is a real
improvement. That is a different route from the one predicted, and the prediction's sign was wrong.

**`tau_q` scan, bottom-only** (HILDA's own prior 538 ± 510): **28 and 100 hit the CEILING** — no `kz`
holds the deep age; **200 → 1.783**, **538 → 1.739**, **1048 → 2.204**. ⭐ **HILDA's own central
`tau_q` is the best arm — nothing was tuned to get it.**

## 3. ⛔ WHAT THIS IS NOT

- **NOT "HILDA's model".** Every number above is *HILDA HS/HD boxes with `q` attached at the BOTTOM*,
  a deliberate departure from HILDA's depth-independent Interior exchange.
- **NOT an adoption.** `hs_frac = 0` ships; no refit was run; `ent26` is untouched.
- **NOT a `kz` relief result.** That is P1 and P1 failed. Do not carry the 09-04k2 framing forward.

## 4. ⛔ TWO ERRORS OF MINE, BOTH CAUGHT BY MY OWN TESTS

### 4.1 P3 as pre-registered COULD NOT PASS — I put the control inside the test
P3 required *every* scored layer to age. The scored band is **1622 / 2268 / 3172 m**, and **3172 m is
the bottom box, pinned to −156.145 in every arm by the iso-deep control**. Requiring it to move is
requiring the control to move. It duly read **+0.0** and the gate printed FAIL.
⇒ Scored on the **FREE** layers it PASSES (−4.1, −8.5, both toward GLODAP).
⭐⭐ **And the same fact is a POWER statement worth more than the fix:** that layer contributes an
**identical \|z\| to every arm**, so **one third of the scored statistic has NO POWER to discriminate
between attachments.** `mean|z|` is nonetheless left on the full band — changing the statistic would
break comparability with 2.55 / 2.048 / 1.81 across this entire arc.

### 4.2 P4 WAS MEASURED ACROSS A `kz` CHANGE — a like-for-like violation
I first read HD off the two **iso-deep** arms — **−98.7 vs −109.2** — and called the 10.5 ‰ the
attachment's doing. **The iso-deep control solves a DIFFERENT `kz` per arm**, so that difference
confounds attachment with `kz`. Deconfounded at `kz` = 1900:

| term | HD moves |
|---|---|
| **attachment alone** | **+2.92 ‰** |
| **`kz` alone** (1900 → 2686) | **+8.90 ‰** |

⇒ **HD is set by `kz`, not by the attachment (3.1×).** And the pre-check's predicted *direction* —
HD should AGE once it loses the young upper interior — is **wrong**: at matched `kz` HD gets
*younger*, by a couple of permil.
⭐ **The test caught it, not me.** `test-q-attachment.R` asserted "bottom-only HD is younger" at
`ccx_default_params()` and **FAILED at −94.57 vs −94.14** — the sign REVERSES between bases, because
the true effect is ~1–3 ‰ and has no robust sign. The test now asserts the thing that *is* robust:
**attachment ≪ `kz`/3**.
⇒ ⭐⭐ **THE ISO-DEEP CONTROL LICENSES EXACTLY ONE COMPARISON — the intermediate PROFILE, which is
what it equalises the deep age FOR. Every quantity it does not pin must be read at MATCHED `kz`.**

## 5. WHAT IS OWED BEFORE THIS COULD BE ADOPTED

1. ⭐ **Pre-register the matched-`kz` decomposition** (§2). It carries the attribution and it is post hoc.
2. **The attachment BOUNDARY is unexplored by design** — only 1 and 10 were run, because the prereg
   refused a tunable boundary. A declared scan (e.g. every layer) is a separate question with its
   own prereg, and it must not be scored by picking the best.
3. **A refit.** Every number here is at `ent26`, whose 26 parameters were fitted with `hs_frac = 0`.
   `kz` = 2686 is an iso-deep SOLVE, not a fit.
4. **The 3172 m no-power finding (§4.1)** should be checked against the other gates that use this
   band — it may not be unique to this diagnostic.
