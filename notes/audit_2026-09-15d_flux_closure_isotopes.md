# AUDIT — 2026-09-15 (d): every flux's RETURN LEG, and every term's THREE ISOTOPES

**Asked by Marcus 09-15 (d): "look for anything in the model where there is a flux in one direction without a return flux, or
anything that touches only one isotope rather than all three (with the exception of radioactive decay)." Scope: `ccx_deriv()`
(`R/model.R:1819–3151`) and `deriv()` (`src/ccx_core.cpp:405–1051`) plus the `ccx_prepare()` geometry they read. Line numbers
are as of HEAD `c36c52a`, BEFORE the D1 fix below shifted `R/model.R` by a few lines. Method: a subagent enumerated every `dy`
write path and every limb in both cores; the one DEFECT it reported was verified by hand against the code, then reproduced by a
test that FAILED before the fix (125 GtC/yr) and passes after, and mutation-tested (forcing the pre-fix gate: 376 GtC/yr).**

## 1. Isotopes — structurally clean
Every write to `dy` in BOTH cores goes through one of five paths (R `:1973–1978, 1992–1993, 2001–2003, 3136–3143`; C++
`:442–450, 694–695, 958–959, 1046–1050`):

| path | C | ¹³C | ¹⁴C |
|---|---|---|---|
| `add_flux` (R :1907, C++ :426) | ±F | ±F·r13(source)·α13 | ±F·r14(source) — no ¹⁴C fractionation (the Δ¹⁴C convention) |
| `add_diffusion` / the inline loops | own gradient | own gradient | own gradient (`for tr in CCX_TRACERS`) |
| `add_source` (R :1999, C++ :447) | +F | +F·R13(1+δ/1000) | +F(1+Δ/1000); fossil passes Δ = −1000 ⇒ exactly 0 |
| ¹⁴C production (bomb / nuclear / cosmogenic) | — | — | atmosphere only, by design |
| ¹⁴C decay (R :3143, C++ :1050) | — | — | −λ·C14, every box — the one legitimate isotope-only sink |

⇒ **No term moves C without ¹³C and ¹⁴C, and none uses a different coefficient, sign, area or source box for one isotope.**
Worth stating: (a) `ent_seas_amp_SH` moves NO tracer — it perturbs `dic_ml` inside the pCO₂ calculation only (R :2381, C++ :640),
so its "entrained deep water" carries no ¹⁴C depletion; PINNED at 0 in `hilda30c`. (b) Option B (`seas_ml = 2`, the seasonal HS)
exists in R only (R :2739–2801); `ccx_seas_ml_marshal_check()` refuses it on C++ — a live, guarded asymmetry. (c) `add_flux`
moves C with zero isotopes if the source box's C ≤ 0 (R :1939, C++ :438) — reachable only in a diverging RK4 stage that
`ccx_run_fast()` rejects.

## 2. Return legs — every water limb closes; the pumps are one-way by design and carbon-conserving
| limb | forward | return | closes |
|---|---|---|---|
| `w_up` | R :2650 / C++ :764 | R :2652 / :766 | yes — up every interface, ML → bottom in one step |
| `w_out_*` | R :2683 / :775 | R :2685 / :779 | yes |
| conveyor `q_conv` | R :2708, :3121 / C++ :792, :1036 | R :2718, :3128 / :800, :1040 | yes (see I1, I2) |
| HILDA `q` (`tau_q`) | R :2849 / :868 | R :2851 / :869 | yes — `a_ls·dz_k/τ·conc_hd` vs `y_k/τ`, seasonal `dz` on both legs |
| `u_hs` | R :2787 / :839 | R :2788 / :840 | yes |
| HS entrainment (option B) | R :2798 | R :2800 (+ HD thickness :2744) | yes, R only |
| `w_eq` (cell) | R :2893 / :887 | R :2901–2907 / :891–895 | yes — one W, three legs, closes through ml or tr |
| `q_tr` | R :3002 / :965 | R :3003 / :966 | yes |
| `w_vent` (E) | R :3028 / :980 | R :3029 / :981 | yes, pairwise per layer |
| seasonal ML entrain / detrain | R :2527 / :713 | R :2530 / :716; volume via `ccx_grid_at_h_ml` :981 / C++ :496 | yes with the cell on or both off; **NO for tr-only — the defect** |
| LS / HS biological pumps | R :2592–2610, :2811 / C++ :738, :849 | none upward | carbon yes, by design: export arrives in the interior through `add_flux`; the field (diffusion, or diffusion + `w_vent` under "martin") returns it |

Cosmetic, both cores identically, `q_conv = 0` in every registered mode: **I1** the conveyor books its volume on `a_oc`
(R :2700, :3121–3129) not the LS column's `a_ls`, so `q_conv` in Sv is mislabelled by (1 − f_hs) under HILDA — all four legs
scale together, so it still closes; **I2** its deep interhemispheric leg reads the ANNUAL-MEAN grid (`grid$dz[cg$s + 1]`) while
the within-column legs read the seasonal `gr$dz` — matters only at `conv_sink = 1` with `seas_ml` on. **I4** under `eq_on` the
solved pump field is solved with `kappa ∝ a_ls` (R :3302) while the deriv's top interface carries `a_ml` — off by a_eq/a_ls
(~4 %) at S₁; "pump_grad means the PI gradient" is approximate with the cell on. Not a conservation defect.

## 3. THE DEFECT — `tr` without the cell (fixed this session; CHANGELOG 09-15 d)
`ccx_tr_on()` licenses the tropical box with the cell OFF ("a passive warm surface box"), and `ccx_prepare()` shrinks
`a_ml = a_ls − a_eq − a_tr` under `eq_on || tr_on` — but the three sites that correct for `a_ml ≠ a_ls` tested **`eq_on` alone**:
the ML/layer-1 diffusion thickness (R :2492, C++ :685), the seasonal-ML excursion share (R :2038, C++ :496), entrainment
(R :2528, C++ :714). With `tr_frac > 0, eq_frac = 0`: the seasonal ML created `a_tr·dh/dt` of water each half-year, and a
uniform column was NOT flux-free (a permanent oc1 → ml diffusive flux ∝ K·conc·(a_ls − a_ml)/dz_mid: **125 GtC/yr** at the
annual-mean ML, 595 at a mid-excursion instant, both cores). Carbon stayed conserved (the paths are antisymmetric), so no
conservation gate could see it and the Newton would have converged on a wrong equilibrium without error. **No registered mode
is affected** — `hilda_tr` has eq AND tr on, and P0g tested only that pair. **Fix:** one flag `aux$d1_on = eq_on || tr_on`, set in
`ccx_prepare()` next to `a_ml` and derived in C++ `unpack_aux()` from the two marshalled switches (so the cores cannot disagree);
the three sites read it. **Test:** `test-tr-box.R` "P0g-tr" — the uniform tr-only column is flux-free at the annual-mean ML
(< 1e-12) and at a seasonal instant the ONLY ocean tendency is the entrainment pair at exactly conc × a_ml × dh/dt (< 1e-9),
both cores, parity 1e-10; POWER: forcing `d1_on = 0` on the same state gives 376 GtC/yr. Every registered mode is bit-exact
(the flag is 0 wherever eq and tr are both off, and equals `eq_on` wherever the cell is on).
