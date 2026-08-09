# CarbonCycleEmulator — Project Context for Claude Code

> Universal Marcus-Sarofim conventions live in `~/.claude/CLAUDE.md` (auto-loads) and the
> skills in `~/.claude/skills/` — notably `climate-modeling` (sanity-test framework,
> paired pulse discipline) and `obs-model-comparisons` (canonical obs choices: IGCC
> temperature, multi-year baselining). This file adds project specifics.

## What this project is

Simple calibrated global carbon cycle model (2 hemispheres, monthly, 2-pool land,
box-diffusion ocean, ¹²C/¹³C/¹⁴C) + public RShiny communication app for an
undergrad-environmental-studies audience. **DESIGN.md is the authoritative spec** — read
it before touching model structure, and log spec changes in CHANGELOG.md.

Separate project from FaIRtoFrEDI — no FaIR/FrEDI/BRICK dependencies.

## Hard rules

1. **Stack is R end-to-end.** Model, MCMC, Shiny all in R. Rcpp core allowed only with a
   bit-parity test against the pure-R reference implementation.
2. **Number provenance:** every physical constant lives in `data-raw/constants.R` with a
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
6. **Temperature forcing is IGCC**, per standing obs conventions.
7. App text is written for undergrads: every panel has a one-sentence takeaway; ‰, GtC,
   ppm get tooltips; advanced material goes in collapsibles.

## Environment

- R: system R 4.5-arm64 (arm64 Mac), same as FaIRtoFrEDI R work.
- No Python/Julia in this repo.
- Deployment target: shinyapps.io (public). Keep app memory small; precompute posterior
  ribbons, live-run only the central parameter set.
