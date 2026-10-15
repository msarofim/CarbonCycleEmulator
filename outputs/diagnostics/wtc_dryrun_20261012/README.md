# WTC landing tools: dry run on a SYNTHETIC file (2026-10-12, CHANGELOG ff)

**Not a result.** The file is `hilda29e` relabeled under `hilda_csl3v0kaidgbemwtc` at bomb_share_NH 0.90 / seas_T_lag 2.0.
Its logpost is the wave's port target (−1062.9494406). Its stored rows were set to the pricing's `streams_all` before
`check2`. This tests the PLUMBING of the tools that need only a mode file, at `c3514fb`, in `~/ccx_frozen/20261012ff_wtc_dryrun`.

| step | outcome |
|---|---|
| `hessian` | runs; reproduces the logpost to 2.2e-11; NOT negative-definite there (3 positive eigenvalues: kz_deep_frac, beta_max/fert_k, npp_frac_NH). Expected: under the new objective hilda29e is a start, not a maximum |
| `read` | runs; REF vs the port target 2.2e-11; the pricing's rows to 0; the label alone +106.9490 = the pricing's; WTC − REF exactly 0 (identity control) |
| `check` | FAILED at GATE 0 (rows off by 97): the synthetic file then carried hilda29e's OLD-objective rows. An artifact of the synthetic file, not of the tool |
| `check2` | after the rows were set: GATE 0 4.9e-6 (tol 1e-5); L −0.001σ, s −0.001σ, w +0.029σ; verdict STOP at the RULED 0.1σ |
| `ocean` | runs |
| `scorecard` | runs; the WTC arm is scored (its "does not reproduce" line is the same old-rows artifact as `check`) |

collect / basins / promote need the wave's start files. The armed chain's dry run exercises them on the first finished starts.
