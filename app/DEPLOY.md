# Deploying the app

```bash
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

Startup compiles the C++ core (~20 s cold, cached after), runs the 1750 spinup and
one historical integration. Everything after that is live: a counterfactual rerun is
~60 ms, three coupled SSP futures ~0.5 s, a matched pulse pair over 1750–2300 ~0.65 s.
Nothing is precomputed, so no cached figure can fall out of date with the model.

## Dependencies

`shiny`, `bslib`, `ggplot2`, `Rcpp`. Deliberately **not** plotly, DT or shinyWidgets —
shinyapps.io memory is the binding constraint and base ggplot covers every panel.

## What has to ship

The app reads from the repository root, so deploy the whole tree, not just `app/`:

| Path | Why |
|---|---|
| `R/` | the model |
| `src/ccx_core.cpp` | compiled at startup |
| `data/*.rds` | observations, forcings, the FaIR climate module |
| `calibration/output/pump_arms/mode_fit_pumpN.rds` | **the parameter set the app runs on.** This is the adopted mode; `mode_fit.rds` has never existed. Omit it and the app falls back to uncalibrated defaults SILENTLY (the banner is the only report) |
| `DESIGN.md` | `.find_root()` locates the repo by looking for this file |

`data-raw/` is **not** needed at runtime and is large. Exclude it.

## The parameter banner

`app/global.R:app_params()` resolves the parameter set in this order, and the banner
at the top of every tab reports which one it landed on:

1. `calibration/output/posterior_draws.rds` → "calibrated posterior"
2. the first of `calibration/output/pump_arms/mode_fit_pumpN.rds`, then
   `calibration/output/mode_fit.rds`, that exists AND carries a matching
   21-name parameter vector → "posterior mode" (so a stale 18-parameter fit is
   ignored rather than silently misaligned)
3. otherwise → "uncalibrated defaults", with the warning styling

**Two of the 21 fitted parameters are FORCING parameters** (`bomb_total`,
`luc_scale`), not model parameters, and `ccx_default_params()` has no slot for
them. `app_build_forcing()` and `app_run_coupled()` in `global.R` exist to carry
them onto every forcing the app builds; call those, never `ccx_build_forcing()`
or `ccx_run_coupled()` directly. Skipping them is worth ~5.8 ppm at 2024 and
nothing would report it. See `calibration/diag_app_params.R`.

Do not remove the banner. What the model is fitted to changes what every number on
every tab means.
