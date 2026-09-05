# COLLECT — 2026-09-05. **THE HILDA HS/HD STRUCTURE IS BUILT, IN BOTH CORES.**
# **⭐⭐ THE 09-04k2 CEILING WAS THE MISSING BOX — HILDA'S OWN `u` IS NOW FEASIBLE.**
# **⛔ AND THE `q` LIMB HAS THE WRONG SIGN IN THE SCORED BAND, WHICH IS WHY P4 FAILS.**

Scores `notes/prereg_2026-09-05_hilda_boxes.md`. `calibration/diag_hilda_boxes.R`.
**Nothing fitted, nothing adopted.** `ent26` is untouched and `hs_frac` defaults to 0.

---

## 0. SCORECARD — P0 ✅, P1 ✅ (at the window's edge), P2 ✅, P3 ✅, **P4 ❌**, P5 reported, N1 ✅ but compromised

| | prediction | result |
|---|---|---|
| **P0** | no-op, conservation, parity | ✅ `hs_frac = 0` **bit-exact, 32 boxes**; 0.16 bites (deep −156.145 → −110.287); closure **1.33e-15**; R-vs-C++ **5.70e-14**, *smaller than the incumbent's own 1.14e-13* |
| **P1** | HS under-equilibrates on its own, ∈ [−160, −80] | ✅ **−80.3 ‰** against an LS mixed layer at −29.8 — a **50.5 ‰ split**, and the falsifier (< 20 ‰) is survived. ⚠ **BUT SEE §2: it clears the pre-registered window by 0.3 ‰ and sits OUTSIDE HILDA's own −120 ± 30.** |
| **P2** | a `kz` exists at HILDA's own `u` = 38 | ✅ **kz = 1900.** The 09-04k2 ceiling was an artefact of the missing box, exactly as pre-registered |
| **P3** | `kz` falls below the shim's 3177 | ✅ **1900 = 0.299×** the incumbent, against the shim's 0.500× |
| **P4** | scored mean \|z\| below the shim's 1.81 | ⛔ **2.05.** Better than the incumbent's 2.55, **worse than the reduced form** |
| **P5** | HD near −136, and not warmer than the LS ML | −109.2; the falsifier is survived. Model-to-model, reported not gated |
| **N1** | upper ≤ 500 m does not degrade by > 1 z | ✅ 4.54 → **3.98**, it IMPROVES. ⚠ **The control is compromised — see §4** |

**Iso-deep, `ent26`, only `kz` re-solved, preindustrial steady state, scored band > 1500 m** —
the same protocol as 09-04k2, so the numbers are comparable to that note's by construction.

## 1. ⭐⭐ THE HEADLINE: THE CEILING WAS THE MISSING BOX

09-04k2 measured a hard ceiling — **at a whole-column-equivalent `u` ≳ 2, NO `kz` holds the deep
age** — and the prereg turned that into a falsifiable fork, because HILDA's own fitted `u` = 38 m/yr
over 16 % of the area is **6.08 m/yr** in that convention, i.e. **~3× beyond the ceiling**. Either
the real box relaxes it or our column and HILDA's cannot both be right about the deep.

✅ **It relaxes it.** At `u` = 38 the solve returns `kz` = 1900, and the ladder is smooth and
monotone all the way to `u` = 76:

| arm | `kz` | `kz`/`kz`(0) | HS Δ¹⁴C | HD Δ¹⁴C | LS ML | scored mean \|z\| |
|---|---|---|---|---|---|---|
| incumbent (no HS) | 6356 | 1.000 | — | — | −49.3 | **2.55** |
| `u` = 0 (HD + q only) | 6410 | 1.009 | **+1.4** | −141.5 | −57.9 | **2.23** |
| `u` = 9.5 | 3376 | 0.531 | −49.5 | −120.4 | −40.8 | 2.21 |
| `u` = 19 | 2530 | 0.398 | −66.3 | −114.0 | −34.8 | 2.14 |
| **`u` = 38 (HILDA)** | **1900** | **0.299** | **−80.3** | −109.2 | −29.8 | **2.05** |
| `u` = 76 | 1502 | 0.236 | −90.1 | −106.4 | −26.3 | 1.96 |
| `u` = 38, τ_q = 268 | 765 | 0.120 | −94.6 | −128.8 | −23.9 | 1.46 |
| `u` = 38, τ_q = 28 | 139 | 0.022 | −112.4 | −153.2 | −17.1 | **1.32** |
| `u` = 38, τ_q = 1048 | 3153 | 0.496 | −68.9 | −93.8 | −34.5 | 2.43 |

⭐ **AND THE `u` = 0 ARM IS A FINDING IN ITS OWN RIGHT.** An HD reservoir exchanging with the
interior at τ_q = 538 and NO conduit at all improves the scored band **2.55 → 2.23 at essentially
unchanged `kz`** (6356 → 6410). That is not the conduit; it is the reservoir.

## 2. ⚠ P1 PASSES, AND THE HONEST READING IS THAT IT PASSES BY 0.3 ‰

HS emerges at **−80.3 ‰** with nothing prescribed — no HS observable is in the likelihood and no
parameter was fitted to one. That is the physics the 09-04k2 shim could not carry, and it is real.
**But −80.3 clears the pre-registered [−160, −80] window by 0.3 ‰ and is OUTSIDE HILDA's own
−120 ± 30.** Quoting this as "HILDA's HS reproduced" would be wrong.

> ⛔⛔ **§2 IS HALF RETRACTED, 2026-09-05b/c — SEE `collect_2026-09-05bc_hs_endmember.md`.**
> **THE THICKNESS TERM DOES NOT EXIST.** Measured: HS moves **0.2 ‰ across a 2.7× change in
> thickness** (134.1 → 50 m), because in steady state both the HS↔HD limbs (`u / h_hs`) and air-sea
> equilibration (`gx / (A · h_hs)`) carry the same `1/h_hs` and **the ratio is independent of it** —
> thickness sets the box's INVENTORY, not its steady state. **Only the 1.97× gas-exchange term is
> real, and it is sufficient on its own**: at HILDA's own 15.1 mol m⁻² yr⁻¹ HS lands at **−107.5**
> against their −111. The table below is kept for provenance; read the ratio row as retracted.

⭐⭐ **AND THE SHORTFALL IS EXPLAINED QUANTITATIVELY, BY THE TWO DEPARTURES THE PREREG FLAGGED —
BOTH PUSHING THE SAME WAY.**

| | ours | HILDA | ratio |
|---|---|---|---|
| gross air-sea invasion at 280 ppm | **29.80** mol m⁻² yr⁻¹ (`k_w` = 1787.8 at `ent26`, K0(2 °C) = 0.05808) | **15.1 ± 1.2** (their Table 1) | **1.97×** |
| HS thickness (choice C2: = `h_ml`) | **134.1 m** | 75 m | 1.79× |
| HS residence at `u` = 38 | **3.53 yr** | 1.97 yr | 1.79× |

⛔ **THE ARITHMETIC IN THIS PARAGRAPH WAS WRONG AND IS RETRACTED (see the box above).** It read:
*"equilibration goes as thickness / gas exchange, so 1.79 / 1.97 = 0.91 while residence is 1.79×
longer, hence a ratio ≈ 1.97× HILDA's."* **Both timescales are linear in the thickness, so the h
cancels and 1.79 was never a term.** The conclusion that C6 alone explains −80 against −111 is the
one that survives, and it is now MEASURED rather than argued.
⇒ ⭐ **A RATIO OF TWO TIMESCALES THAT SHARE A FACTOR IS NOT A LEVER.**

## 3. ⛔⛔ WHY P4 FAILS, AND IT IS A MECHANISM RESULT, NOT A SHORTFALL

**`q` INJECTS WATER THAT IS YOUNGER THAN THE INTERIOR EVERYWHERE BELOW ~1000 m — i.e. it ventilates
exactly the layers the model already over-ventilates.** At `u` = 38, HD = −109.2 ‰ against the
interior:

| depth | interior Δ¹⁴C | HD − interior | what `q` does there |
|---|---|---|---|
| 67–831 m | −29.3 … −101.0 | −79.8 … **−8.2** | **AGES** it |
| **1160 m** | −118.1 | **+8.9** | **YOUNGENS** it |
| **1622 m** | −134.7 | **+25.5** | **YOUNGENS** it |
| **2268 m** | −148.3 | **+39.1** | **YOUNGENS** it |
| 3172 m | −156.1 | +46.9 | YOUNGENS it |

**The crossover sits at ~1000 m, and the whole scored band is below it.** The scored rows are too
YOUNG already (z +2.28 / +2.01 at 1622 / 2268 m; GLODAP −165.2 / −175.6 against the model's
−134.7 / −148.3), so every unit of `q` there is spent in the wrong direction.

⇒ **THE IMPROVEMENT COMES ENTIRELY FROM THE `kz` RELIEF, AND `q` IS FIGHTING IT.** That is exactly
why the reduced form beat the structure: the 09-04k2 shim exchanged **mixed layer ↔ bottom box ONLY,
with no distributed return**, so it collected the `kz` relief and paid **none** of the youngening
penalty. Adding HILDA's own geometry back puts the penalty back.
⚠ **Note what this does NOT say.** It is not that `w_out`'s failure has recurred: `w_out` injected
SURFACE water (−40) and this injects HD water (−109), which is 70 ‰ older. The endmember is right;
its DEPTH OF ATTACHMENT is wrong for our column.

## 4. ⚠ N1 IS COMPROMISED, AND I BUILT IT THAT WAY

N1 compares the ≤ 500 m band against GLODAP, and the prereg treated its LEVEL as meaningful. It is
not: at a **preindustrial** steady state the upper ocean carries no bomb ¹⁴C, so the incumbent's own
upper-band mean |z| is **4.54**, essentially all missing bomb spike (67 m: model −48.3 against an
observed +50.5). This is the ⚠⚠ TRAP that `handoff_2026-09-04_ocean_structure_arc.md` §5 states in
so many words, and I walked into it while writing the control.
✅ **The DELTA is still interpretable** — the bomb deficit is common to every arm — and it improves
(4.54 → 3.98). **The LEVEL is not, and the "< 1 z" threshold was measuring an artefact.**
⇒ **A control band must be chosen where the comparison is valid, not where the defect is.**

## 5. ⭐ AN UNPLANNED OUT-OF-SAMPLE CHECK THAT DISCRIMINATES ARMS

HILDA's Table 2 carries **LS = −40 ± 20 ‰** from GEOSECS, and nothing in our likelihood scores the
surface ocean's Δ¹⁴C. Reading it across the arms: incumbent −49.3 ✅, `u` = 38 −29.8 ✅, `u` = 76
−26.3 ✅, **τ_q = 28 −17.1 ⛔ OUTSIDE**. So the arm with the best scored mean |z| in the whole table
(**1.32**) is **excluded by an observation** — and independently needs `kz` = 139, a **46×**
reduction that sits far outside the 09-01 bracket [4379.1, 8109.9]. **Exploratory, not
pre-registered, and reported as such.**

## 6. ⇒ WHAT THIS LICENSES, AND WHAT IT DOES NOT

- ✅ **The structure is real, cheap to run, and correct**: bit-exact off, conservative to 1.3e-15,
  parity better than the incumbent's own, and every mechanism prediction (P1, P2, P3) confirmed.
- ⛔ **It does NOT license adoption.** P4 is the row that mattered and it failed, and nothing here
  touched the ocean sink, the CO₂ record, the bomb transient, gate H, or the Joos gap.
- ⇒ **The next two tests are named by the diagnosis, not by taste**, and both are cheap now that the
  boxes exist: (a) **HS at HILDA's 75 m** (choice C2's declared alternative), which §2 predicts
  deepens HS toward −120, ages HD, and pushes `q`'s crossover DEEPER; (b) **the attachment depth of
  `q`**, which §3 identifies as the thing costing the scored band. ⚠ (b) is a departure from HILDA's
  Fig. 1 and must be labelled as one.
  > **BOTH HALVES OF (a) ARE NOW RUN — see `collect_2026-09-05bc_hs_endmember.md`.** Thickness is
  > **not a term** (0.2 ‰ over 2.7×, analytically), and the endmember reached through the gas
  > exchange **does** move the crossover 1160 → 1622 m but **buys 0.025 of mean |z| while giving
  > back the entire `kz` relief (1900 → 5334) and putting the LS surface 2σ outside GEOSECS**.
  > ⇒ **(b) IS NOW THE ONLY CANDIDATE THE DIAGNOSIS NAMES, AND IT NEEDS A DECISION, NOT A RUN.**
