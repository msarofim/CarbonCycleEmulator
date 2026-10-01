# Mode-start chains, 2026-10-01 (CHANGELOG 10-01 q)

Two 1000-iteration chains of the MCMC check, started AT the mode of `hilda33d` rather than
overdispersed. They were run to see where the posterior's typical set lies in log-posterior,
because the Torch smoke's chains had stalled at −1433 to −1447.

**How they were made.** The driver is `calibration/run_mcmc_check.R` at `c631e50` with one line changed,
`MC_OVERDISP <- 2` → `0`, run from the extracted Torch bundle on the Mac:

```
Rscript --vanilla calibration/run_mcmc_modestart.R --chain=<1|2> --n=1000 --adapt=999 --t0=998 \
  --ckpt=100 --thin=20 --out=outputs/modestart --commit=c631e50-modestart
```

- `adapt 999` with `t0 998` means no checkpoint ever falls in [t0, adapt]. The proposal therefore stays the
  Laplace one (× 2.38²/33) throughout.
- The seeds are 20261002 and 20261003. Each file's provenance records them, along with `overdispersion = 0`.

**What they show.** Over iterations 301–1000 the chains averaged −1420.7 (sd 3.6) and −1419.0 (sd 2.8).
Their trends were +0.4 and −1.0 per 100 iterations, and acceptance was 0.076 and 0.080.
- A Gaussian posterior would put a converged chain at mode − χ²₃₃/2: median −1421.6, 95 % [−1430.8, −1414.9].
- So the typical set lies near the Gaussian level. The smoke's stall was not the posterior.
- Stage 1 of production then showed the stall was the smoke's EARLY ADAPTATION (`t0 = 100`), not slow burn-in.
  With the same seeds and starts, the Laplace proposal reached −1416 to −1426 by iteration 500.
- The low acceptance under the Laplace proposal (0.08, where ~0.23 is expected for a Gaussian target) is the
  10-01 (l) ridge seen from the sampler's side. Near the mode the posterior is tighter than the Gaussian along
  `beta_max` / `fert_k` / `ndep_ret`.
