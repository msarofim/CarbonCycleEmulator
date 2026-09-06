# Declared parameters — the caveat register for the web tool

**Marcus 2026-09-06:** *"if we need to use some pre-defined parameters from HILDA or other models,
make sure those are documented to go into the webtool as caveats on the 'just defined from what we
see'."* This file is that register. One row per number the model uses that is **neither fitted to
our observations nor a physical constant** — a value taken at one remove, from another model's fit
to (its own) observations. The app's "what is fitted, what is assumed" panel is generated from it.

**Convention.** *Status* is one of FITTED (a member of the parameter table, constrained by our
likelihood), DECLARED-OBS (pinned to an observation we hold, with the dataset named), DECLARED-LAW
(follows from a physical law or an identity), DECLARED-REMOVE (taken from another model's fit —
carries a caveat), NOT-A-PARAMETER (measured to have no power; the value is a convention). *Caveat
text* is the sentence the app shows verbatim.

## Ocean structure (HILDA HS/HD boxes and depth-dependent K, 2026-09-05 to 09-06)

| parameter | value | status | source / vintage | caveat text for the app |
|---|---|---|---|---|
| `hs_frac` | 0.16 | DECLARED-OBS (**MEASURED 2026-09-06d: 0.160** on ERSST v5 1981–2010; NH 0.123 / SH 0.190, the model uses 0.16 in both) | HILDA's definition: ocean area with annual-mean SST < 5 °C (Siegenthaler & Joos 1992, §2); `data-raw/build_hs_exchange_factor.R` | "The cold-surface box covers 16 % of the ocean — the area colder than 5 °C on an annual mean, measured from ERSST. The 5 °C cut follows HILDA (1992)." |
| `sst_hs` | 2 °C | DECLARED-OBS / chemistry floor | the box's annual-mean SST; 2 °C is also the carbonate constants' validity floor (Lueker et al. 2000) | "The cold box is held at 2 °C, the coldest temperature the carbonate chemistry is validated for; its true annual mean is near that." |
| `h_hs` | follows `h_ml` (134 m at `ent26`) | DECLARED (weakly identified: 09-05b steady-state cancellation, but 09-06c found transient power via the bomb curve, marginal sd 0.36) | HILDA uses 75 m for both surface boxes | "The cold box's thickness follows the fitted mixed-layer depth; it barely changes the results." |
| `u_hs` | 38 m/yr (± 17) | DECLARED-REMOVE (09-06c: not separately identifiable; trades with the HS exchange at r −0.94). **Scan 09-06d** (`diag_declared_param_scans.R`): halved → the deep needs f 0.136 and the transient loses **517** (CO₂ rows −551, sink 2.97 → 2.78); doubled → **no deep floor holds the deep** (1.2 ‰ too young at every f) | HILDA Table 1, fitted to GEOSECS ¹⁴C (1970s data, 1992 fit) | "The rate at which cold surface water sinks into the high-latitude deep box is HILDA's (1992) value, fitted to 1970s radiocarbon — not derived here. Halving it weakens the modern ocean sink by 0.2 GtC/yr; doubling it leaves the deep ocean too young at any mixing rate." |
| `tau_q` | 538 yr (± 510) | DECLARED-REMOVE (09-06c: a free fit runs it to its bound to remove the conduit; the contrast row is what holds it). **Scan 09-06d**: halved → **no deep floor holds the deep** (33 ‰ too young); doubled → f re-solves to 0.313 and the transient GAINS 93 (CO₂ rows +67) while the profile contrast fails at **+4.3σ** — the CO₂ rows reward the column the contrast rejects | HILDA Table 1, as above | "The exchange time between the high-latitude deep box and the ocean interior is HILDA's (1992) value — not derived here, and uncertain by a factor of two in their own fit. Halving it leaves the deep too young at any mixing rate; doubling it fits the atmosphere slightly better but flattens the deep profile the wrong way." |
| `q_attach_from` | **every layer (HILDA's), 1** | DECLARED-OBS (09-06c: the observed B − deep contrast, −0.4 ± 4 ‰, rejects bottom attachment at −3σ and every column at +4σ; HILDA's is the only structure inside 2σ) | GLODAPv2.2023 vertical contrast, measured 2026-09-06 | "High-latitude deep water enters the interior at every depth, which is what keeps the deep ocean uniformly old below 2000 m — the observed profile rules out filling it only from the bottom." |
| `kz_zscale` (z_K) | 253 m | DECLARED-REMOVE (09-06c: weakly identified, marginal sd 1.8; a free fit trades it against f and h_ml). **Scan 09-06d**: 150 → f re-solves to 0.112, transient **−223** (CO₂ rows −201, sink 2.97 → 2.87); **500 → no deep floor holds the deep** (8.8 ‰ short) | HILDA Table 1, K(z) = 465 + 7096·exp(−(z−75)/253) | "The depth over which mixing slows from its surface value is HILDA's (1992) 253 m — not derived here. Shallower costs the modern sink; deeper leaves the deep ocean too young at any mixing rate." |
| `kz_deep_frac` (f) | 0.05–0.10 at HILDA's attachment (K_deep 300–600, HILDA's 465) | FITTED (planned): pinned by the deep row + contrast once the attachment is HILDA's | our GLODAP deep and intermediate rows | — (fitted, no caveat) |
| `hs_asx_frac` | 0.65–0.8 wherever freed | FITTED (planned): the one structural parameter the data support directly (bomb rows; marginal sd ≤ 0.10). **CROSS-CHECK MEASURED 09-06d: 0.653** = ice × wind **1.064** (HILDA's cancellation, real) × Schmidt **0.549** (`data/obs_hs_exchange_factor.rds`; NH 0.32 / SH 0.78; windows 0.61–0.66); the fitted value is within 1 sd of it | Wanninkhof (2014) k ∝ ⟨U²⟩ Sc^−½ over open water; HadISST1 ice, NCEP R1 winds, ERSST v5 SST | "The cold box exchanges gas about 35 % more slowly per unit area than the warm ocean: sea ice cancels the stronger polar winds almost exactly (as HILDA assumed), but CO₂ diffuses more slowly through cold water. Fitted, and checked against ice, wind and temperature observations." |

## Older declared values this register should absorb (owed)

The pump's carbonate share (pinned by GLODAP's alkalinity gradient — DECLARED-OBS), the seasonal
`SPO_SEAS_*` targets (observations inverted through the model — provisional), and `sst_scale` 0.8
(DECLARED-REMOVE?) are candidates for rows here. Not yet audited.

## How this feeds the app

`app/` reads this file's table into the "what is fitted, what is assumed" collapsible (DESIGN §7).
Every DECLARED-REMOVE row also carries its sensitivity, reported WHOLE and never scored by its best,
from the diagnostic that scanned it (e.g. `diag_kz_profile_conduit.R`'s `z_K` scan), so the caveat
has a number attached: "if HILDA's value were 2× larger, the modern sink would move by …".
