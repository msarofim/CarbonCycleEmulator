# Band copy: DRAFTS for Marcus to edit, 2026-10-15

Drafted on Marcus's request ("Draft all four for me to edit"). Facts: `notes/ship_copy_facts_2026-10-14_hilda31w.md`,
plus the band artifact re-read on 2026-10-15 (`data/futures_ribbons.rds`, spans 1750-2150): max CO₂ width 22.95 ppm,
max GMST width 0.0847 °C (both vvH 2150). The four lift `APP_RIBBONS_HOLD` in one commit.

## A. The band's caption (Futures tab, CO₂ view)

> Shaded: the 5–95% range of 17,000 model runs, each with a different plausible set of the fitted carbon-cycle
> parameters. The climate response, the non-CO₂ forcing and the model's structure are held fixed, so the full
> uncertainty is likely wider.

- The frame changes too: the count gets a thousands separator and the em-dash frame ("— a <label>.") goes.
- "Plausible" stands in for "posterior draw". It leaves out that the draws also reflect the priors.

## B. Issue 6 (`app/R/review.R`, id 6, class "gap", unchanged)

**Title:** The uncertainty band covers only the carbon-cycle parameters

**Plain:** Each line in this app is a single best fit. On the Futures tab, the CO₂ view also shades how much the
projection changes when the carbon-cycle parameters vary within their plausible range. The band leaves out other
sources of uncertainty, so the full range is likely wider.

**Detail:** The band comes from a Markov chain Monte Carlo sampler: four chains of 200,000 steps each, from which
17,000 parameter sets were run through the full model. It varies the 31 fitted carbon-cycle parameters. Fourteen other
parameters are held at fixed values, and the climate response (fitted to FaIR), the non-CO₂ forcing and the model's
structure are not varied. Temperature therefore changes only through CO₂, by less than 0.1 °C, and no band is drawn
for it. The sampler has not fully converged. Three parameters that set how far plant growth and respiration lag behind
the seasons can compensate for one another, and one chain sampled a different combination of them for part of its
run. This has less effect on the projections: bands computed from each chain separately agree to within about 5 ppm,
at most about a fifth of the band's width. The depth of the ocean's mixed layer is cut off at about 75 m by a limit in
the model's time-stepping, so its sampled range may be narrower than the data allow. A faster method, which treats the
fit as a bell curve around the best fit, was tried first and failed its check: along the direction that trades the
strength of CO₂ fertilisation against its shape, the fit falls off much faster than a bell curve assumes. In an
earlier version of the model, that method gave a CO₂ band more than twice as wide as the sampler's.

**Ask:** Does a band that covers only the carbon-cycle parameters help you read the projections, or would you want
the climate response included before relying on it?

## C. Parameter panel (`app/global.R`, `app_params()`)

> Best fit of 31 parameters to CO₂, δ¹³C, Δ¹⁴C and Global Carbon Budget sinks, with 14 further values held at stated
> numbers. Each line is this single best fit. On the Futures tab, the CO₂ view also shades the range across runs that
> vary the fitted parameters. The fit constrains the shape of these curves more tightly than their absolute height.

- Only the middle two sentences are new. The counts stay computed. The last sentence is the approved text, not
  re-checked at hilda31w.

## D. Temperature view (`APP_RIBBON_NOTE_TEMP`)

> No uncertainty band is drawn for temperature. The runs vary only the carbon-cycle parameters, which change the
> warming by less than 0.1 °C. How strongly the climate responds to CO₂ is held fixed, so a band would understate the
> uncertainty in future warming.

## On applying (not copy)

- Each typed number in B and D (200,000; 17,000; 31; 14; 0.1 °C; 5 ppm; a fifth; 75 m; twice) is derived from its
  artifact or pinned by a test against it, as `test-review-card-numbers.R` does for the other issues.
- The label goes in through `calibration/promote_futures_ribbons.R --label=`, with `label_ruled = TRUE`.
- The banner on every tab ("BETA v1.0 — single best fit.") stays true of the lines and is left alone.
