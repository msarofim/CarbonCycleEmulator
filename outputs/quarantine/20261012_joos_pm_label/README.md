# Quarantine 2026-10-12: Joos 2013 split labeled "±1 sd" (it is ±2 s.d.)

Marcus, 2026-10-12: "Quarantine + README (Recommended)".

## The bug (label only)
`calibration/diag_pulse_land_attribution.R` printed Joos et al. 2013's pulse split (ocean 20 ± 7 /
33 ± 12 / 59 ± 12, land 19 ± 16 / 23 ± 20 / 16 ± 14 GtC at 20 / 100 / 1000 yr) as
"sec.3.2 … multi-model mean +/- 1 sd", and its comparison row as "(+/- 1 sd)".
The section is **§4.3** (pp. 2806–2807). The ± are **±2 s.d. half-widths**: they match Fig. 3's
"multi-model mean +/- 2σ" band, as measured from the figure's vector paths.
Fixed in `3c45224` / `55206e3` (CHANGELOG 2026-10-12 (n)).

**Every NUMBER in these logs is right.** Only the two label strings are wrong. They are quarantined
because a ±2 s.d. half-width labeled "±1 sd" is the 10-02 halved-z bug class (CHANGELOG 10-02 w):
read at face value, it doubles the apparent spread a model's partition is judged against.
One s.d. is half of each printed ±: ocean 3.5 / 6 / 6, land 8 / 10 / 7 GtC.

## Files
| file | what it ran |
|---|---|
| `pulse_land_attribution_20260927d.log` | arm `hilda29l`, commit `447f8de` |
| `pulse_land_attribution_phi0_refit_20260928.log` | φ = 0 warm-start refit (scratch mode, not registered) |
| `pulse_land_attribution_phi0_basin2_20260928.log` | φ = 0 Torch array, basin 2 (scratch mode) |
| `pulse_land_attribution_v0k_basin1_20260928.log` | shape-prior `hilda_csl3v0k`, Torch 18729847, basin 1 (scratch mode) |
| `pulse_land_attribution_v0k_basin2_20260928.log` | the same array, basin 2 (scratch mode) |

## Canonical replacement
**None.** All five arms are retired or scratch modes. The script is also a HELD-ERA RECORD (its
header, 2026-10-12): it builds PD100 with the climate held, which is no longer the live protocol.
So a re-run at today's canonical (`hilda29e`) would be a new result, not a replacement, and it was
not made. The live pulse partition is card 5b's, from `R/joos_irf.R` `ccx_pd100()`.

Referenced from CHANGELOG 2026-09-27 / 09-28 (old paths, left as written: the log is append-only)
and from `outputs/quarantine/20260927_joos_release_shift/README.md` (pointer added).
