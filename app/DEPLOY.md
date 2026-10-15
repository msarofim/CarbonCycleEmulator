# Deploying the app

```bash
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

## The name and the URL (ruling R3, 2026-09-22)

The app is **CarboTope**. `APP_TITLE` in `app/global.R` is the one constant every
label derives from, so the rename is that line and nothing else in the code.

⭐ **The deployed URL moves with it: `carbotope.shinyapps.io/carbotope`.** This is the
part that is expensive to undo — renaming after the post circulates breaks every link
anyone has shared — so set the account/app name at the FIRST deploy, not after.

**Deliberately NOT renamed** (Marcus's scoping of R3): the repository stays
`CarbonCycleEmulator` and the code keeps its `ccx_` prefix. Neither is public-facing.

## ⚠ BEFORE THE PUBLIC BETA GOES OUT

The app ships as **BETA v1.0 CarboTope** (`APP_RELEASE_NAME`), cut on mode **`hilda31w`**
(`APP_RELEASE_MODE`; Marcus 2026-10-15: "Beta v1.0 is fine, because this is the first public
version"). `tests/testthat/test-app-version.R` requires `APP_RELEASE_MODE` to be the mode the app
loads, so the next adoption fails the suite until someone decides whether the release moves too.
Earlier cuts: `hilda29e` 10-08, `hilda33p` 10-06, `hilda34g` 10-03, `hilda33d` 10-01.
Its "Known issues" tab is the point of the release: it puts each remaining flaw to the reader and
asks whether it is a deal-breaker, fixable or acceptable.

**The posting plan (Marcus 2026-10-15):** (1) make the GitHub repo public; (2) post on Substack with
the CarboTope link; (3) push CarboTope with the Substack link. Before the link is posted:

1. **The repository must be public.** `APP_REPO_URL` is set (2026-10-15) to
   `https://github.com/msarofim/CarbonCycleEmulator`, which 404s for everyone else until it is.
   The pre-public scan's decisions (CHANGELOG 2026-10-15 (a)) are Marcus's to make first.
2. **`APP_FEEDBACK_URL` must be set in `app/global.R`** to the Substack post the
   comments live under. Until it is, every card renders a visible "the comment
   link is not set in this build" warning instead of a link, and the tab's header
   says so too — deliberately, because a dead link costs exactly the feedback
   this release exists to collect. `tests/testthat/test-review-cards.R` asserts the
   placeholder machinery is wired; **update that test when you set the URL, do not delete it.**
   ⚠ **Steps (2) and (3) need each other's URL.** The app's URL is fixed in advance
   (`carbotope.shinyapps.io/carbotope`, below), so the post can link it before the app is up — but
   then the post's first readers hit a 404. Either deploy FIRST with the placeholder (the cards say
   "comment link not set" until step 3) and check it live, then post, then redeploy with
   `APP_FEEDBACK_URL`; or, if Substack shows the post's final URL before publishing, set it and
   deploy before posting.
3. **Start-up: re-timed 2026-10-15** (see below). It is no longer the app's worst number.
4. **The hosting plan** (see "Hosting limits" below): on Free or Starter every visitor shares ONE
   R process, and Free stops serving after 25 active hours a month.

## Start-up cost — the number a visitor actually pays

Start-up compiles the C++ core, runs the 1750 spin-up, one historical
integration and the box diagram's one-year flux trace.

⭐ **Re-timed 2026-10-15, from the deploy bundle itself** (`make_deploy_bundle.sh`, commit `556f4a4`,
a fresh process each time, so the C++ compile is cold; M4, load average 2.8–3.0 on 10 cores):

| | run 1 | run 2 |
|---|---|---|
| process start → serving | 8.1 s | 6.0 s |
| navigate → first plot drawn (first visitor) | — | 0.78 s |
| the C++ compile alone (cold, separately) | 2.0 s | |

- **The old numbers were 73 s idle, 2.8 min under load, 148 s contended (09-22).** They predate the
  2026-10-12 pre-beta code review. Before it, start-up traced fluxes over the whole 1750–2024 record
  on the pure-R path (~110 s at the canonical, per the `APP_FLUX` comment in `global.R`); since then
  only the last year is traced.
- ⚠ **This is a laptop number.** shinyapps.io "does not make any guarantees regarding the number of
  CPU cores, or the speed of the CPUs" (Posit's applications guide), so re-time it on the FIRST
  deploy: a cold instance after the 15-minute idle timeout.
- ⚠ **`APP_WARMUP_NOTE` still says "allow up to three minutes"** — more than 20× the laptop number. Its
  wording is Marcus's; re-word it once the shinyapps.io number is known. The post should say the same.

Everything after start-up is live: a counterfactual rerun is ~60 ms, three
coupled SSP futures ~0.5 s, a matched pulse pair over 1750–2300 ~0.65 s (older measurements). The
pulse lab's "Release the pulse" drew both of its plots 4.0 s after the click (10-15, bundle).
Nothing is precomputed, so no cached figure can fall out of date with the model.
**The "Known issues" tab adds three runs the app does not otherwise make** (a gate
run to 2025, an ENSO knockout, a 1000-year pulse pair; the card that spun up a second mode was
retired 2026-10-01). They are memoised and computed on FIRST VIEW of that tab, not
at start-up — measured at about 6 s in total, contended (before 10-15) — so a visitor who never
opens the tab never pays for it.

## Hosting limits (shinyapps.io; checked 2026-10-15)

From Posit's applications guide (docs.posit.co/shinyapps.io/guide/applications/):
- **Free and Starter: 1 worker process and 1 instance.** Every simultaneous visitor shares ONE R
  process. R runs one computation at a time, so a visitor's 4-second pulse release delays everyone
  else's next click by up to that long. Basic and above allow up to 10 workers per instance and
  3–10 instances.
- **Memory:** the default "large" instance allows 1024 MB. Measured 2026-10-15: the app's R process
  held **204 MB** after one full session (every tab, all nine review-card plots, one pulse, one
  build-your-own run).
- **Bundle:** at most 1 GB on Free/Starter. This bundle is 4.1 MB (108 files).
- **Idle timeout:** 15 minutes by default, after which the next visitor pays a cold start.

From Posit's support article on the Free plan (seen through a search summary; the page itself
refused the fetch): **25 active hours a month, after which visitors see a notice that the app is not
available.** A launch post can use that up quickly. Current plan prices were NOT verified here; read
them off the shinyapps.io account page before choosing.

## Dependencies

`shiny`, `bslib`, `ggplot2`, `Rcpp`. Deliberately **not** plotly, DT or shinyWidgets —
shinyapps.io memory is the binding constraint and base ggplot covers every panel.

## What has to ship — build it with `app/make_deploy_bundle.sh`

```bash
app/make_deploy_bundle.sh /tmp/carbotope_bundle
```

The script holds the ship list ONCE and builds the bundle from a commit (default `HEAD`) with
`git archive`, so only tracked files ship. ⚠ Until 2026-10-15 this section named the mode file as a
literal path, and it was two adoptions old (`hilda33p`); a bundle built from it would have run on
uncalibrated defaults. The script never types that path: it asks `ccx_mode_file()` at that commit.

The app reads from the repository root, so the bundle is part of the tree, not just `app/`:

| Path | Why |
|---|---|
| `app.R` (bundle root, generated) | **shinyapps.io runs the app found at the bundle ROOT**, but the app lives in `app/`; this two-line file runs it with `shiny::shinyAppDir("app")` |
| `app/` | the app. ⚠ Everything in `app/www/` is served publicly at the app's URL, including `sarofim_essenhigh_comment_2011.doc`, which nothing in the app links to |
| `R/` | the model |
| `src/ccx_core.cpp` | compiled at startup |
| `data/*.rds` | observations, forcings, the FaIR climate module, the nuclear ¹⁴C source |
| the canonical mode file, wherever `ccx_mode_file()` points (`R/paths.R`, the ONE place its path is named) | **the parameter set the app runs on.** Omit it and the app falls back to uncalibrated defaults; the banner and the "Under the hood" provenance line are the only report |
| `DESIGN.md` | `.find_root()` locates the repo by looking for this file |
| `calibration/lib_design_gates.R` (+ `lib_seas_limbs.R`, `lib_glodap_obs.R`) | **the gate kernels the "Known issues" tab measures itself with.** Sourced lazily on first view of that tab, never at start-up. Omit them and the cards that need them render their reason in place of their number — a visible degradation, not a silent one, but the review tab is then half-useless. (`lib_glodap_obs.R` names a `data-raw/` file, but only `dg_gateG_obs()` reads it, and the app never calls that.) |

**Tested 2026-10-15:** a bundle built this way from `556f4a4` (4.1 MB, 108 files) ran with
`shiny::runApp(<bundle>)`. Every tab drew all its plots, the pulse lab and build-your-own ran, all
nine Known-issues card plots drew, and the server log was clean. Its provenance line read "posterior
mode (single best fit) … 31 parameters … 14 further values held", which is `hilda31w`.

`data-raw/` is **not** needed at runtime and is large. The script excludes it.
⚠ **True only since 2026-10-14.** Until then the app summed `data-raw/downloads/nuclear14c/` at run time, so a
bundle built from this line ran with the industrial ¹⁴C source silently at ZERO (Δ¹⁴C NH −3.9 ‰ by 2024;
`outputs/diagnostics/deploy_nuclear_absent_20261014/`). The source is now `data/forcing_nuclear_c14.rds`
(covered by `data/*.rds` above), and the loader STOPS without it, so an incomplete bundle fails at start-up.

## How to deploy (never done yet as of 2026-10-15)

`carbotope.shinyapps.io/carbotope` returned 404 on 2026-10-11: the app has never been deployed.
The account and token are Marcus's; nobody else should type the token.

```r
install.packages("rsconnect")      # not installed on the M4 as of 2026-10-15
# once, with the token and secret from the shinyapps.io dashboard's Tokens page:
rsconnect::setAccountInfo(name = "carbotope", token = "<token>", secret = "<secret>")
```

```bash
app/make_deploy_bundle.sh /tmp/carbotope_bundle
Rscript -e 'rsconnect::deployApp("/tmp/carbotope_bundle", appName = "carbotope", account = "carbotope")'
```

- The account name and the app name are BOTH `carbotope`; that is what makes the URL
  `carbotope.shinyapps.io/carbotope` (ruling R3, above). Set them right at the FIRST deploy.
- **What only the first deploy can test:**
  - whether the shinyapps.io instance compiles `src/ccx_core.cpp` at RUN time. Posit's guide says
    the service compiles packages at DEPLOY time and says nothing about compiling at run time;
  - the cold start on their CPUs;
  - the memory once several sessions share the process.
- After it deploys, open every tab once, press "Run it" and "Release the pulse", open the Known-issues
  tab, and check the "Under the hood" provenance line names the canonical mode, not "uncalibrated
  defaults".

## The parameter banner

`app/global.R:app_params()` resolves the parameter set in this order, and the banner
at the top of every tab reports which one it landed on:

1. `calibration/output/posterior_draws.rds` → "calibrated posterior"
2. the first of `ccx_mode_file(CCX_MODE_CANONICAL)` (its path is named only in `R/paths.R`;
   `make_deploy_bundle.sh` prints it), then
   `calibration/output/mode_fit.rds` (which has never existed), that exists AND carries this build's
   parameter set (`ccx_mode_carries_build()`; a pinned canonical's held names
   come back through `ccx_mode_par_with_pins()`) → "posterior mode" (so a stale
   fit from an older parameter table is ignored rather than silently misaligned)
3. otherwise → "uncalibrated defaults", with the warning styling

**Two of the fitted names are FORCING parameters** (`bomb_total`,
`luc_scale`), not model parameters, and `ccx_default_params()` has no slot for
them. `app_build_forcing()` and `app_run_coupled()` in `global.R` exist to carry
them onto every forcing the app builds; call those, never `ccx_build_forcing()`
or `ccx_run_coupled()` directly. Skipping them is worth ~5.8 ppm at 2024 and
nothing would report it. See `calibration/diag_app_params.R`.

Do not remove the banner. What the model is fitted to changes what every number on
every tab means.
