# PREREG — 2026-09-05f. **`q`'s ATTACHMENT DEPTH: THE BOXED ANALOG OF THE ML↔BOTTOM CONDUIT.**

Scores nothing yet. Written **before** the branch exists and before any run.
Follows `handoff_2026-09-05_hilda_boxes_arc.md` §7, which put this decision to Marcus.

**MARCUS'S RULING (2026-09-05):** *"We don't need to stay true to HILDA, but we should stay true to
the conceptual way that the simplified model's ocean works."*
⇒ The departure from HILDA is **authorized**. The constraint is **coherence with CCX's own ocean**,
and that constraint — not the score — has to carry the choice.

---

## 1. THE CONCEPTUAL ARGUMENT, FROM CCX'S OCEAN AND NOTHING ELSE

CCX's ocean is a per-hemisphere **PURE-DIFFUSION column** (DESIGN §3.4):
`∂C/∂t = ∂/∂z(K_z ∂C/∂z)` on a 10-layer grid. Every non-local limb — `w_up`, `w_out_*`, the
conveyor, and now HS/HD — is an explicit switch **defaulting to 0**, and each encodes a specific
claim about **where** water moves non-locally. `w_out` is **DEAD** (handoff 2026-08-16: every
configuration moves deep Δ¹⁴C the wrong way — do not re-propose).

**THE MEASURED DEFECT** (09-04k2, P1/P3 both confirmed): `kz` is forced to ventilate **both** the
upper ocean **and** the deep. Give the deep its own pathway and `kz` **halves** (6356 → 3177), and
the intermediate water ages toward GLODAP as a consequence.

**THE MEASURED FAILURE OF DEPTH-INDEPENDENT `q`** (09-05 §3): HD sits at **−109.2 ‰**, and the
model's interior crosses −109 at **~1000 m**. So a single-endmember bulk exchange **necessarily**
ages everything above that crossing and **youngens** everything below it. The scored band lies
**entirely below**, and is already too young against GLODAP.
⭐ **THIS IS ARITHMETIC, NOT TUNING.** A single-endmember reservoir exchange with a stratified
column matches its endmember at exactly **one depth** and must fight the profile on **both** sides
of it. Nothing about that is specific to HILDA, to our fit, or to the residual.

⇒ **THE READING.** Depth-independence asserts that *every* interior layer communicates **directly**
with the high-latitude deep box. In CCX's column the interior is reached **by diffusion from above**;
no such direct path exists except the one being added. What HS/HD represents physically is **deep
water formation** — dense water sinking at high latitude to **fill the deep**, with the water above
reached by mixing. **Attaching `q` at depth is therefore what CCX's ocean concept already says.**
It is a departure from **HILDA**, which is authorized; it is *not* a departure from **CCX**.

⚠ **WHY THIS IS NOT `w_out` COMING BACK.** `w_out`'s distributed return injects **mixed-layer**
water (−29.8 ‰) into every interior layer. This injects **HD** water (−109 ‰) into the **deep
only**. Same family of wiring, different endmember **and** different attachment — and `R/model.R`'s
own comment at the `tau_q` block already draws the first half of that distinction.

## 2. ⛔ THE HONEST RISK, STATED BEFORE THE RUN

**The conceptually-coherent attachment is also the better-scoring one, and I formed the argument
AFTER seeing that the reduced form scored 1.81 against the structure's 2.05.** That is the exact
shape of a physics rationalization. Two guards, both binding:

1. **The attachment set is declared from a NON-SCORE criterion** (§3) and there is **no free
   boundary to tune**.
2. **The quantitative pre-check below is computed NOW, and it predicts the mechanism is WEAKER here
   than in the reduced form.** P1 can fail, and the pre-check says how it would.

### ⭐ QUANTITATIVE PRE-CHECK (computed before the run, from already-measured numbers)

The conduit's job is to hold the deep at its target while `kz` falls. Supply ∝ rate × (C_source −
C_deep):

| form | source | source Δ¹⁴C | bottom | contrast |
|---|---|---|---|---|
| reduced (09-04k2) | mixed layer | **−29.8** | −156.1 | **126.3 ‰** |
| boxed, deep-attached | **HD** | **−109.2** | −156.1 | **46.9 ‰** |

⇒ **HD is a 2.69× WEAKER ventilation source per unit exchange volume than the mixed layer.** To
reproduce the reduced form's `kz` relief, deep-attached `q` needs **~2.7× the volumetric exchange**
the reduced form used.

⚠⚠ **AND THAT 2.69× IS OPTIMISTIC.** HD's −109.2 was measured **with depth-independent `q`** — i.e.
while HD was exchanging with the young **upper** interior. Removing that limb should drive HD
**older**, weakening the source further and pushing the required rate **above** 2.7×. Hence **P4**,
which measures exactly this and is the number that tells us whether the pre-check held.

## 3. WHERE `q` ATTACHES — DECLARED NOW, WITH NO FREE PARAMETER

⛔ **REJECTED: "attach below the crossover (~1000 m)".** The crossover is **where the defect is**,
and choosing a boundary there violates the standing rule that **a control band must be chosen where
the comparison is VALID, not where the defect is** (`handoff_2026-09-05` §8). It would also be a
tunable boundary, i.e. geometry fitted to the residual.

✅ **DECLARED: the BOTTOM BOX ONLY** — `kk = grid$nl`. It is the **direct boxed analog of the
ML↔bottom reduced form that was actually tested**, it has **no free boundary**, and it cannot be
accused of being fitted. If and only if it works, the boundary becomes a **separate, later,
declared** question — not a knob inside this test.

**Scan:** `tau_q` over HILDA's own prior **538 ± 510 yr** (and below it, since the pre-check demands
~2.7× more exchange = shorter `tau_q`). Report **whether the `tau_q` that works is inside that
prior** — an arm that only works outside HILDA's prior is a different claim and must be labeled so.
`u_hs` held at HILDA's **38 m/yr**. `kz` re-solved per arm to hold the bottom box at **−156.145**,
the same iso-deep protocol as 09-04k2 — so `kz` relief and profile shape stay comparable.

## 4. PREDICTIONS

| | prediction | falsifier |
|---|---|---|
| **P0a** | attachment set = ALL layers reproduces the 09-05 depth-independent structure **BIT-EXACTLY**; `tau_q = 0` still bit-exact off (32-box unchanged) | any non-zero difference |
| **P0b** | **MUTATION:** moving the attachment set by ONE layer moves deep Δ¹⁴C detectably | it does not — the switch is not wired |
| **P1** | **the mechanism:** at HILDA's `u_hs`, bottom-attached `q` relieves `kz` **below the 1900** the depth-independent structure needed | `kz` ≥ 1900 |
| **P2** | **the scored band:** mean \|z\| **< 2.05** (the depth-independent structure). *Stretch, not required:* beats the reduced form's **1.81** | ≥ 2.05 |
| **P3** | **the diagnosis:** the youngening at 1160 / 1622 / 2268 m is **REMOVED** — those layers **age** relative to the depth-independent arm | they youngen |
| **P4** | **the pre-check's own risk:** HD sits **OLDER than −109.2**. Not pass/fail on the mechanism — it is the number that says whether the 2.69× was optimistic | (diagnostic, no falsifier) |
| **P5** | **control:** LS mixed layer stays inside GEOSECS **−40 ± 20** (−29.8 at the depth-independent arm; the `k_w` = 906 arm broke it at −78.5) | outside |

⚠ **P2 IS NOT THE POINT AND MUST NOT BE READ AS THE POINT.** P1 and P3 test the **mechanism** —
`kz` relief without the youngening penalty. If P2 improves while P1/P3 fail, the gain is coming from
somewhere else and the arm is **not** what this prereg claims. That combination is a **FAIL**,
not a win.

## 5. SCOPE, AND WHAT THIS IS NOT

- **Nothing is adopted, fitted or refit here.** `hs_frac` stays **0** in the shipped configuration;
  `ent26` is untouched. This is a diagnostic, exactly as 09-04k and 09-05 were.
- **The preindustrial steady-state protocol**, as throughout this arc. `sst_hs`'s 2 °C floor and the
  Lueker validity range are therefore not in play (`handoff_2026-09-05` §6).
- ⛔ **If this passes, the result is NOT "HILDA's model".** Every number carries the label: *HILDA
  HS/HD boxes with `q` attached at the BOTTOM, a deliberate departure from HILDA's depth-independent
  Interior exchange.*
