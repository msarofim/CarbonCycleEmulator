# What the public app would show if deployed as DEPLOY.md says (2026-10-14)

`app/DEPLOY.md:91` says to exclude `data-raw/` from the bundle ("not needed at runtime"). But
`ccx_nuclear_c14_annual()` (`R/forcing.R:370`) reads `data-raw/downloads/nuclear14c/*.csv` at run time,
through every `app_build_forcing()` call. When the directory is absent it WARNS and returns an empty
frame, so the industrial ¹⁴C source becomes zero. Nothing stops.

`nuc_zero_effect.R` sources `app/global.R` (canonical hilda31w), then reruns the app's own historical run
(`app_build_forcing()` + `ccx_run_fast()`, as `app_hist` does) with the loader returning the empty frame.
Log: `nuc_zero_effect.log`.

- The only outputs that move are the ¹⁴C columns. CO₂ and δ¹³C are unchanged, as they should be for a tracer.
- Δ¹⁴C NH annual mean: −0.38 ‰ (1980), −1.79 (2000), −2.53 (2010), −3.89 (2024); max 4.17 ‰ (2023).
  SH is similar: −3.70 ‰ in 2024.
- For scale, the canonical's fitted `sigma_d14c` is 5.37 ‰, so 2023 moves by ~0.8σ.

Nothing is changed here. The fix is Marcus's (handoff 10-14b §3 item 4, "a stop() under a flag").
