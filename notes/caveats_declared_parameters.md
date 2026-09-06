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
| `hs_frac` | 0.16 | DECLARED-OBS | HILDA's definition: ocean area with annual-mean SST < 5 °C (Siegenthaler & Joos 1992, §2); the area is an observation, the 5 °C cut is their convention | "The cold-surface box covers 16 % of the ocean — the area colder than 5 °C on an annual mean. The 5 °C cut follows HILDA (1992)." |
| `sst_hs` | 2 °C | DECLARED-OBS / chemistry floor | the box's annual-mean SST; 2 °C is also the carbonate constants' validity floor (Lueker et al. 2000) | "The cold box is held at 2 °C, the coldest temperature the carbonate chemistry is validated for; its true annual mean is near that." |
| `h_hs` | follows `h_ml` (134 m at `ent26`) | NOT-A-PARAMETER | 09-05b: both HS timescales carry 1/`h_hs`, so its value cancels (0.2 ‰ over 2.7×) | "The cold box's thickness does not change the results; it follows the fitted mixed-layer depth." |
| `u_hs` | 38 m/yr (± 17) | DECLARED-REMOVE — status pending 09-06c | HILDA Table 1, fitted to GEOSECS ¹⁴C (1970s data, 1992 fit) | "The rate at which cold surface water sinks into the high-latitude deep box is HILDA's (1992) value, fitted to 1970s radiocarbon — not derived here." |
| `tau_q` | 538 yr (± 510) | DECLARED-REMOVE — status pending 09-06c | HILDA Table 1, as above | "The exchange time between the high-latitude deep box and the ocean interior is HILDA's (1992) value — not derived here, and uncertain by a factor of two in their own fit." |
| `q_attach_from` | bottom layer | DECLARED (structural choice, Marcus 2026-09-05) | departure from HILDA's depth-independent exchange; 09-06: the profile cannot rank it once the deep age is right | "Deep water from the high-latitude box enters the interior at the bottom, filling the abyss from below. HILDA let it enter at every depth; with the deep age right, the observations cannot tell the two apart." |
| `kz_zscale` (z_K) | 253 m | DECLARED-REMOVE — status pending 09-06c | HILDA Table 1, K(z) = 465 + 7096·exp(−(z−75)/253) | "The depth over which mixing slows from its surface value is HILDA's (1992) 253 m — not derived here. A refit may move it." |
| `kz_deep_frac` (f) | solved 0.166 at the working arm | FITTED (planned) — status pending 09-06c | our GLODAP deep and intermediate rows | — (fitted, no caveat) |
| `hs_asx_frac` | 1 | DECLARED-REMOVE — status pending 09-06c; an observational pin (annual open-water fraction over the HS area) is OWED | HILDA's assumption: winter ice cover cancels the stronger high-latitude winds | "The cold box exchanges gas with the air at the same rate per unit area as the rest of the ocean — HILDA's assumption that sea ice cancels the stronger polar winds. Not measured here." |

## Older declared values this register should absorb (owed)

The pump's carbonate share (pinned by GLODAP's alkalinity gradient — DECLARED-OBS), the seasonal
`SPO_SEAS_*` targets (observations inverted through the model — provisional), and `sst_scale` 0.8
(DECLARED-REMOVE?) are candidates for rows here. Not yet audited.

## How this feeds the app

`app/` reads this file's table into the "what is fitted, what is assumed" collapsible (DESIGN §7).
Every DECLARED-REMOVE row also carries its sensitivity, reported WHOLE and never scored by its best,
from the diagnostic that scanned it (e.g. `diag_kz_profile_conduit.R`'s `z_K` scan), so the caveat
has a number attached: "if HILDA's value were 2× larger, the modern sink would move by …".
