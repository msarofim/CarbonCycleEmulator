# CarbonCycleEmulator — Project Context for Claude Code

Local, untracked session notes: CLAUDE.local.md (if present).

## What this project is

Simple calibrated global carbon cycle model (2 hemispheres, monthly, 4-pool land,
box-diffusion ocean, ¹²C/¹³C/¹⁴C) + public R Shiny communication app (CarboTope) for an
undergrad-environmental-studies audience. **DESIGN.md is the authoritative spec** — read
it before touching model structure, and log spec changes in CHANGELOG.md.

Separate project from FaIRtoFrEDI, with no FrEDI or BRICK dependency and no FaIR code
dependency. It does use FaIR products: the climate module (future temperature) is a response
fitted to FaIR 2.2.4 (calib 1.6.0) runs, and those runs, like the other FaIR-derived inputs in
`data/`, come from the author's FaIRtoFrEDI repository.

## Hard rules

1. **Stack is R end-to-end.** Model, MCMC, Shiny all in R. Rcpp core allowed only with a
   roundoff-parity test against the pure-R reference implementation (the cores agree to
   roundoff, not bit for bit -- see the `src/ccx_core.cpp` header; measured <= 1.3e-16 relative
   on the canonical's final state, code review 2026-10-12).
2. **Number provenance:** every physical constant lives in `R/constants.R` with a
   citation (paper + table, or dataset + access date). DESIGN.md marks unverified working
   values as [VERIFY] — none of those may be used in code until cited. No literature
   numbers from memory.
3. **Data provenance:** every dataset is downloaded by a script in `data-raw/` recording
   URL, access date, and checksum; processed inputs are versioned `.rds` in `data/`.
4. **Sanity gates before headline claims:** DESIGN.md §6 list (conservation to ~1e-10,
   zero-emissions drift, paired pulse tests, bomb-curve/seasonal/sink/Suess checks).
   Conservation and pulse tests live in `tests/` and run in CI fashion, not ad hoc.
5. **¹⁴C gotchas:** decay uses the true half-life (5700 yr class), NOT Libby 5568 (which
   is an age-reporting convention); Δ¹⁴C observations are fractionation-corrected, so
   model ¹⁴C transport carries no fractionation. Both must be stated in code comments.
6. **Temperature forcing is IGCC** for historical runs, per standing obs conventions;
   futures use the FaIR-fitted climate module (above).
7. App text is written for undergrads: every panel has a one-sentence takeaway; ‰, GtC,
   ppm get tooltips; advanced material goes in collapsibles.

## Environment

- R: system R 4.5-arm64 (arm64 Mac), same as FaIRtoFrEDI R work.
- Model, calibration, app and tests are R. No Julia. 13 tracked Python files (2026-10-15,
  `git ls-files '*.py'`): five data-preparation scripts in `data-raw/`, seven one-off
  mutation/diagnostic scripts under `outputs/diagnostics/`, and `tools/palette_check.py`.
- Deployment target: shinyapps.io (public). Keep app memory small; precompute posterior
  ribbons, live-run only the central parameter set.
