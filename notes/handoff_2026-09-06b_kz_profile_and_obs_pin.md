# Handoff — 2026-09-06b. The obs-pinned arc: the column cannot flatten the deep, the conduit starves the thermocline, K(z) + conduit returns the sink.
# **✅ SUITE GREEN AND VERIFIED AFTER THE LAST COMMIT: 1887 pass / 0 FAIL / 4 skip / 70 warn.**
# **⛔ NOTHING ADOPTED. `kz_deep_frac` ships 1, `hs_frac` ships 0, `ent26` untouched.**
# **⇒ THE NEXT STEP IS A RULING, NOT A RUN: the design of a refit WITH the structure (§5).**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, no remote. Commits this
session: `a0e91f1` (the scan), `1bb1a45` (K(z) + conduit), and the handoff commit after it. `FaIRtoFrEDI/` untouched.
⚠ **Sessions launch from `FaIRtoFrEDI/`; all of this is in `CarbonCycleEmulator/`.** Use `git -C`.

**Read before this one:** `handoff_2026-09-06_session_close.md` (the state this session started
from) and the two collects: `collect_2026-09-06_q_attachment_scan.md`,
`collect_2026-09-06b_kz_profile_with_conduit.md`.

---

## 1. WHAT WAS ASKED, AND WHAT THE SESSION DID WITH IT

The brief: *a model that replicates observed atmospheric and oceanic carbon, hemispheric and
seasonal, with isotopic matching, in a physically plausible structure, for teaching.* The handoff's
ranked list put two debts first — a prereg for the post-hoc matched-`kz` decomposition and a declared
attachment-boundary scan. Both were paid (prereg `2026-09-06`, Parts A and B). The session then
added the two tests that the brief actually asks for and the arc had never run:

- **Part C — pin `kz` to the OBSERVATION.** The iso-deep control pinned the bottom box at the
  incumbent's own −156.1, which is z +1.85 against GLODAP and was a third of every arm's score.
  The sourced target (−175.3) exists; `~/.claude/CLAUDE.md` says use it.
- **Part D — the transient at matched parameters.** A steady-state profile cannot discriminate
  structures (any column hits one deep number with `kz` free). What the incumbent could not do is
  hold the deep AND the decadal ocean streams with one `kz`; D measures that on every arm.
- **Prereg 09-06b — K(z) WITH the conduit.** D pointed at it; DESIGN §3.4a had named it the last
  untested candidate. Built in both cores, tested, measured the same day.

## 2. ⭐⭐ THE THREE STRUCTURAL STATEMENTS (each rests on observations, not on fit)

1. **The pure-diffusion column cannot match the deep Δ¹⁴C profile's SHAPE at any `kz`.** Obs-pinned
   (`kz` 5267), 1622 m stays **+2.28σ** young. GLODAP is flat below 1600 m (−165 / −176 / −178);
   a no-flux-bottom column is curved (−135 / −157 / −175). Lowering `kz` slides the profile down
   its curve without changing the curve. ⇒ [[ccx_column_cannot_flatten_deep]].
2. **A conduit with uniform `K` gets the deep right only by starving the thermocline.** Obs-pinned
   bottom-attached `kz` 1747: sink 3.07 → 2.54 GtC/yr, CO₂-level rows −2217, bomb −306, total
   **−2849** against the pure column's −333. HILDA's mechanism failed 7× with a uniform `K`.
   ⇒ [[ccx_conduit_starves_thermocline]].
3. **Fast thermocline + slow deep + bottom-attached conduit returns the modern sink with the deep
   right.** `K(z)` at HILDA's `z_K` 253, `kz` held at 6356, f = **0.166** (K_deep 1058): 1622 m z
   **−0.03**, CO₂ rows **−28**, gate 7 z −0.52. ⇒ [[ccx_kz_profile_conduit_result]].

And one that reframes 09-05f: **the attachment ranking is control-dependent.** Pinned to the
observation, BOTH attachments put every scored layer inside |z| < 1 and HILDA's edges the bottom
(0.461 vs 0.551). Part A's attribution survived its prereg; the ranking did not survive the pin.
⇒ [[ccx_q_attach_control_dependent]].

## 3. ⛔ WHAT IS STILL WRONG, AND IT IS ONE ORGAN

- **HILDA's own attachment has NO solution at any `z_K`**: its deep floor is HD − 54 ≈ −171 ‰
  because our HS is −86 against HILDA's −120 (our HD −117 vs their −136). The floor is `ent26`'s
  `k_w` (1788, 2× HILDA's 906-equivalent) — [[ccx_hs_endmember_is_kw]] as a hard ceiling.
- **Bomb ¹⁴C still pays −163 on the arm that works**: the atmosphere is 21 ‰ below `ent26` by 1975
  in both hemispheres; the cold box, flushed at 38 m/yr into ~50× its volume at `ent26`'s `k_w`, is
  a stronger bomb sink than the 32-box fit ever had to accommodate.
- **2268 m is 1.48σ too OLD** on that arm — the mid-depth minimum overshoots; and the window is
  narrow (`z_K` 500 misses the deep by 3.3 ‰).
- `ocean_grad_d13c` −195 and `d13c_level_SPO` −60 are matched-parameter artifacts (pump δ¹³C fitted
  at uniform K; HS ¹³C fractionation never seen by the fit).

⇒ **The HS air–sea exchange is the one thing every residual points at**, and it was pinned by a
posterior fitted with ONE surface box.

## 4. ⚠ ERRORS OF MINE THIS SESSION — read before quoting the 09-06b numbers

1. **The first run's solver reported a physical ceiling that was a bracket assumption.** An
   endpoint-sign bisection on f said "no f holds the deep" for BOTH conduit arms. A probe showed the
   bottom-attached deep going −116 → −187 → −156 as f → 0: the layer above the bottom box dies while
   the conduit holds the bottom near HD − 60, so the deep is NON-MONOTONE in f and has TWO roots. The
   solver now scans every sign change and uses the largest f, printing the dead-intermediate root
   (0.0097) without using it. The first log is kept as `..._run1_endpoint_bracket.log`.
2. **The first run printed E6 PASS on zero conduit arms** — `all(diff(empty))` is TRUE. Now
   VACUOUS. Same family as the 09-05f "control inside its own test".
3. **B1 (kz monotone in attachment) failed by 0.6 %** — HD is not a fixed endmember; it gets younger
   with fewer old partners. Small, mechanistic, on the record.

## 5. ⇒ NEXT — A RULING, THEN A RUN

⭐⭐ **A refit WITH the structure is indicated, and its DESIGN is Marcus's call**
([[handoff_open_item_is_not_a_ruling]]; [[consider_torch_first]] — the 26-par refit was 46 Torch
tasks). The questions, in the order they bind:
1. **Which of {f, `z_K`, `u_hs`, `tau_q`, an HS-specific air–sea exchange factor, `h_hs`} are FREE**,
   and which are declared at HILDA's values. An HS exchange factor is the one every residual points
   at; HILDA's own justification is winter ice cover cancelling stronger high-latitude winds.
2. **Attachment and `hs_frac` as DECLARED choices** (bottom, 0.16), not fitted — the profile cannot
   rank the attachment (§2) and the scan showed it is a step, not a slope.
3. **The `kz` bracket re-bisected on the 36-box structure** — [4379, 8110] was bisected for the
   column and obs-pinned conduit arms sit at 1061–1747.
4. Priors for the new parameters from HILDA's Table 1 (`u_hs` 38 ± 17, `tau_q` 538 ± 510, K₀ 465,
   z₀ 253), labelled model-derived, vintage 1992.
Then, in the old order: DESIGN §6 rewritten at `ent26`; `INDEX_cmp_pulse.md` at 17,736 B.

## 6. ⚠ NON-OBVIOUS STATE

* **Torch: nothing running. Nothing running locally.** Both diagnostics ~2 min; suite ~13 min.
* **New base parameters `kz_deep_frac` (1) and `kz_zscale` (253)** in `ccx_default_params()`; `aux$kz_int`
  is sent to C++ UNCONDITIONALLY and `ccx_cpp_aux()` errors by name if an aux lacks it. Any hand-built
  aux from before today must go through `ccx_prepare()`.
* **The carbonate code warns when `sst_hs` + anomaly dips below 2 °C** ("Temperature outside fitted
  range … extrapolating"); the HS transients reach 1.62 °C. Visible, not fixed.
* **Memory:** new `ccx_q_attach_control_dependent`, `ccx_column_cannot_flatten_deep`,
  `ccx_conduit_starves_thermocline`, `ccx_kz_profile_conduit_result`; `ccx_q_attach_bottom` carries an
  in-place 09-06 note and every site quoting its 1.739 verdict was updated in the same edit
  ([[retraction_in_place_does_not_propagate]]). `INDEX_ccx_ocean_struct` has a new live block;
  `INDEX_ccx_ocean` notes the `kz` switch and that the bracket is structure-specific; the root line
  was rewritten inside its 12,288 B budget.
* **Logs:** `outputs/diagnostics/diag_q_attachment_scan_20260906.log`,
  `diag_kz_profile_conduit_20260906.log` (+ `_run1_endpoint_bracket`).

## 7. ⇒ STANDING RULES THIS SESSION ADDED

* ⭐⭐ **PIN A CONTROL TO THE OBSERVATION WHEN IT EXISTS, AND RE-RANK.** A control pinned to the code
  under test's own value ranks arms by how well they cope with that value's ERROR. If the ranking
  moves when the pin moves to the observation, the first ranking was about the error.
* ⭐⭐ **A STEADY-STATE PROFILE CANNOT DISCRIMINATE STRUCTURES.** With one rate free, any column
  hits one deep number. The discriminating test is the TRANSIENT at matched parameters — what the
  structure does to the streams the rate also serves.
* ⭐ **A "PHYSICAL CEILING" ON THE FIRST RUN OF A NEW SOLVER IS A BRACKET ASSUMPTION** until a scan
  of the whole axis says otherwise. Scan for sign changes; report every root; use the one continuous
  with the incumbent and say why.
* ⭐ **A VERDICT ON AN EMPTY SET IS VACUOUS, NOT A PASS.** `all()` of nothing is TRUE. Count the arms
  before printing a monotonicity verdict.
