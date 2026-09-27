# CarbonCycleEmulator — Project Context for Claude Code

> Universal Marcus-Sarofim conventions live in `~/.claude/CLAUDE.md` (auto-loads) and the
> skills in `~/.claude/skills/` — notably `climate-modeling` (sanity-test framework,
> paired pulse discipline) and `obs-model-comparisons` (canonical obs choices: IGCC
> temperature, multi-year baselining). This file adds project specifics.

## Memory: this repo SHARES the FaIRtoFrEDI keyspace (symlinked 2026-09-25)

Claude Code keys its memory store by the **launch directory**, so a session started here
would historically have had an EMPTY memory — no `MEMORY.md`, no `INDEX_ccx*.md`, none of
the 800-odd files, all of which live under the `FaIRtoFrEDI` key because that is where
sessions have always been launched from.

**As of 2026-09-25 the two keys share ONE store**, via a symlink:

```
~/.claude/projects/-Users-…-CarbonCycleEmulator/memory
  -> ~/.claude/projects/-Users-…-FaIRtoFrEDI/memory
```

Verified: same inode, 803 files readable through the link, and a write through this key
lands in the shared store. Session transcripts are deliberately NOT shared — only `memory`
and the `memory_backup_*` snapshots are linked.

⚠ **Launch from `FaIRtoFrEDI/`, then move here with the `change_directory` tool.** Whether
the harness follows the symlink at session start was never verified, and the test was
dropped (Marcus, 2026-09-27). Launch-then-move is verified to keep the root `MEMORY.md` and
to load BOTH `CLAUDE.md` files — strictly more than a launch from here would get.

⛔ **The store is SHARED, not this repo's.** It also serves FaIR, FrEDI, SLR/BRICK and the
vehicle / SC-CO₂ work, the root `MEMORY.md` routes to all of them, and the sub-index budgets
(soft 14 KB, hard 18 KB, root soft 12 KB) are global. A CCX finding belongs in its own
sub-index — `INDEX_ccx*.md` — never in the root. Read `MEMORY.md`'s own "READ FIRST" block
for the routing, and `INDEX_conv.md` before editing the memory tree.

⚠ **Two `CLAUDE.md` files do NOT both load.** Launched here, you get THIS file and
`~/.claude/CLAUDE.md` — **not** `FaIRtoFrEDI/CLAUDE.md`, which carries the tiered
memory-index rules, the FrEDI/FaIR environment notes and the cross-repo branch discipline.
If you need those, read that file explicitly:
`~/Documents/2026/CodeProjects/FaIRtoFrEDI/CLAUDE.md`.

## What this project is

Simple calibrated global carbon cycle model (2 hemispheres, monthly, 4-pool land,
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
