# Handoff — 2026-09-08i. THE CHEAP PROBES (Marcus: "do the cheap probes; do not use Joos as a scoring mechanism: the long lifetime is meant to be an emergent property, not something we fit to"). Three probes, one ruling applied, one retraction propagated, one gate statistic found to have no power.
# **Every number GENERATED at `hilda31` by `calibration/diag_{d13c_ocean_level, td0b_martin_kz_scan, nh_bomb_levers, gate5_bimodal}.R` (`outputs/diagnostics/*_20260908.{log,rds}`); observations generated from the data files by the same scripts. Nothing adopted.**

Read first: `notes/handoff_2026-09-08h_phase1_results.md` (Phase 1), CHANGELOG 2026-09-08i. Memory:
[[ccx_cheap_probes_20260908h]], [[ccx_gate5_argmax_on_bimodal]], [[ccx_pedagogical_not_emulator]] (the ruling).

## 0. The ruling, applied
GATE L is a COMPARISON: `dg_gateL_verdict()` errors by name, `dg_compareL()` reports (canonical +1.15 ensemble-sd at
1000 yr; land-off −1.14; ent26 +0.98). Nothing derived from Joos passes or fails the model. No probe here reads the IRF.

## 1. The ocean δ¹³C level — and a retraction
Like-for-like at the bottles' epoch: model surface +0.24 heavy, deep +0.73 heavy, **surface−deep 0.40 vs 0.89 observed —
too SMALL**. T-D0's sentence "the gradient is already too large (1.24 vs 0.86)" compared the PI model with modern bottles
and is RETRACTED at every site that quoted it (the 09-08g CHANGELOG entry, `handoff_2026-09-08h` §1.1, two memory
files). What stands: the deep lacks light carbon relative to the surface; the pump depletes it 1.71 ‰ where 2.20 is
needed; the warm surface sits at the Zhang equilibrium to 0.2 ‰ with the pump on or off; the T-independent legacy alphas
shift every box by −0.9 / −1.5 (a level shift overshooting by −0.75). ⇒ the LEVEL is between the two alpha pairs (a
constant); the GRADIENT is the pump's deep delivery. **D's prereg goes on the modern gradient and the deep level.**

## 2. K(z) has no room; D needs E
kz_deep_frac above the canonical pays immediately (0.02: −16; 0.1: −142; 1: −6440 on the CO₂ levels and the Δ¹⁴C profile);
kz ×0.5 / ×2 cost −1265 / −1394. Below ~1000 m diffusion on the observed deep DIC excess can return 0.004 GtC/yr; a Martin
pump at the literature 10.2 GtC/yr export sends 0.84 through that interface — 204× short. A Martin D that puts light carbon
in the deep needs an advective return (option E); the profile form at a held gradient starves the export instead.
**Round 6 = C alone is the honest refit unless E is built first; "C + D" as a profile change does not deliver D's physics.**

## 3. Gate 5's NH statistic has no power on this curve
| | peak 1 | trough | peak 2 | drop | argmax |
|---|---|---|---|---|---|
| observed | 853 @ 1963.71 | 742 @ 1964.12 | 840 @ 1964.54 | 111 | 1963.68 |
| model | 796 @ 1963.71 | 745 @ 1964.04 | 864 @ 1964.62 | 51 | 1964.64 |

The "+2.17σ late" carried since 09-02 is the argmax choosing different lumps; **the model's first-peak timing matches
the observation to 0.00 yr**, and a +2 %/yr tilt flips the observed series' own argmax by 0.9 yr (the two observed
lumps differ by 1.5 % against a 6.2 % zonal spread — the 0.44 yr nh_t spread was recording this). T-I's 1:1 input
sensitivity and the levers' zero sensitivity (τ_ex, k_w, h_ml, bomb share: none moves either peak's time) are both this.
The real miss is the trough: the model holds too much of the 1963 delivery into 1964 (drop 51 vs 111; k_w ×3 → 72,
peak2−peak1 +68 → +14, never flipping). Candidates: the delivery series' 1963-Q4/1964-Q1 share (25 % of the total is
delivered after 1965.5, 14.6 % after 1969.5 — `build_bomb_c14_source.R`, a data question), or the NH land's fast pools.
T-I's "faster early NH removal" is WITHDRAWN.

## 4. Rulings owed
(1) Gate 5's NH statistic: first-peak time, trough depth, or drop the time bound and let the `d14c_NH` stream carry it.
(2) The bomb delivery series' tail (a data-provenance question). (3) Round 6 as C alone vs building E first. (4) The
alpha pair's mean equilibrium (the level) — a constant between the two shipped pairs, or leave it to the pump refit.
(5) Still open from 09-08h: GL's form, the σ_rep table, B's box.
