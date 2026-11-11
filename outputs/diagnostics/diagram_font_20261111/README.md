# Box diagram on the host's font, 2026-11-11 (CHANGELOG 2026-11-11 n)

Marcus: "Yes, fix the box diagram" (after the live checks, CHANGELOG 11-11 m, found the litterfall arrowhead hidden on
the host and two labels touching their arrows at 565 px).

## Which font the host draws in

- `render_diagram.R` draws the diagram as the app does (ragg, 72 dpi) on this machine's "sans" (Helvetica) or on DejaVu
  Sans registered as "sans" (from matplotlib's copy in the miniforge package cache). ggplot's text uses the default
  family "", which ragg resolves without the registry, so the script points the text and label geoms at "sans".
- `compare.py` (zlib only; no PIL or R `png` here): on the diagram area (top 270 px at 565, 395 px at 815), the DejaVu
  render differs from the live image in 102 of 152,550 pixels at 565 px (max 2/255) and the Helvetica render in 15,201;
  the Helvetica render matches this machine's app exactly (0 pixels). At 815 px both pairs differ by the same 1.4 %.
  So the host draws in DejaVu Sans. Bold "Vegetation (leaves + wood)" is 234.8 pt wide in DejaVu and 192.9 pt in
  Helvetica at 15 pt (+22 %).
- `{system,dejavu}_h_diagram_{424,565,815}.png`: the diagram BEFORE the fix. 424 px is `APP_PANEL_PX["diagram"]`, which
  is no longer drawn: `diagram_widths.py` / `diagram_widths_local.log` measured the drawn width at 375 to 1920 px
  viewports (565 on a phone, then 552 at the narrowest panel, 744 at 768, 573 at 1024, 815 at 1440, 1095 at 1920).
- `measure_boxes.R`: each box's drawn size before the fix, on both fonts (DejaVu half-widths 0.54 to 1.02 data units).
  It reads the old geom_label() boxes and does not run on the fixed code.

## The gate and the fix

- The checks are `tests/testthat/helper-diagram-pixels.R`, on pixels: each element drawn alone into ragg's in-memory
  device. `check_diagram.R` and `iterate.R` run them at chosen widths in both fonts (`iterate.R` also saves the
  images). Before the fix at 565 px (first version of the checks, without the shaft and name checks): DejaVu 14
  problems (litterfall head hidden, land-use arrow on Soil, the air-to-warm-sea and air-to-cold-sea heads inside their
  boxes, three more heads partly covered, respiration / warm-sea-to-air / land-use / mixing labels on arrows,
  respiration against air-to-warm-sea). Helvetica (its list was cut off in the session's output): the same two hidden
  heads and several labels on arrows, but not the litterfall, land-use or partial-head faults.
- `iter/i01_*`: fixed-size boxes and edge-placed arrows at the old positions (8 label problems left in each font).
  `iter/i04_*`: the final layout at 552, 565, 815, 904 and 1095 px, 0 problems in either font.
- `app/local_*`: the fixed diagram as the running app draws it on this machine (815 x 696 at 1440 px, 565 x 482 on a
  phone).
- `mutate_diagram.sh` / `.log`: 8 mutations of app/R/plots.R, each caught by test-diagram-pixels.R (a narrower Soil box
  fails the DejaVu block only).
