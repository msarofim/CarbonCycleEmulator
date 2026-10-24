# Deploying the app

```bash
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

## The name and the URL (ruling R3, 2026-09-22)

The app is **CarboTope**. `APP_TITLE` in `app/global.R` is the one constant every
label derives from, so the rename is that line and nothing else in the code.

⭐ **The deployed URL (2026-10-15): https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/** on Posit Connect Cloud, account `saraphreport`
(Marcus chose Connect Cloud Basic over shinyapps.io; see "Posit Connect Cloud" below). The URL is
tied to the content id and survives republishing; a vanity name or custom domain would change it. The
shinyapps.io target `carbotope.shinyapps.io/carbotope` (ruling R3) is now the documented fallback. This is the
part that is expensive to undo — renaming after the post circulates breaks every link
anyone has shared — so set the account/app name at the FIRST deploy, not after.

**The short address (2026-10-21): https://carbotope.org** is a registrar FORWARD to the URL above, not
a custom domain: Connect Cloud maps an owned domain only on Enhanced and up, and the account is on Basic.
Registered by Marcus at Porkbun (2026-10-21, expires 2028-10-21; Porkbun nameservers). Apex and `www`
send a 302 to the app over http and https (Let's Encrypt certificate for `carbotope.org` and
`*.carbotope.org`, issued by Porkbun). Rules for the forward:
- **302, never 301.** A browser caches a 301 indefinitely, so moving the app (say to the shinyapps.io
  fallback) would strand every past visitor; with a 302, editing the forward moves everyone.
- **Never masked or framed.** Inside a frame, `updateQueryString()` rewrites the frame's address, so a
  copied link loses its view (`app/R/links.R`).
- **Include path is ON** (2026-10-21), destination without a trailing slash: `carbotope.org/?<settings>` opens that
  view; a mistyped path gets the app's 404. Wildcard is on, so any subdomain forwards too.
- **To move the app:** edit the forward's destination at Porkbun. The banner's "Short link: CarboTope.org"
  (`APP_SHORT_URL`, `app/global.R`) names the domain, not the host, so it needs no change.

**Deliberately NOT renamed** (Marcus's scoping of R3): the repository stays
`CarbonCycleEmulator` and the code keeps its `ccx_` prefix. Neither is public-facing.

## ⚠ BEFORE THE PUBLIC BETA GOES OUT

The app ships as **BETA v1.1 CarboTope** (`APP_RELEASE_NAME`), cut on mode **`hilda31fl`**
(`APP_RELEASE_MODE`; Marcus 2026-10-24: "Bump the version", "BETA v1.1 CarboTope (Recommended)").
`tests/testthat/test-app-version.R` requires `APP_RELEASE_MODE` to be the mode the app
loads, so the next adoption fails the suite until someone decides whether the release moves too.
Earlier cuts: BETA v1.0 on `hilda31w` (10-15: "Beta v1.0 is fine, because this is the first public
version"), `hilda29e` 10-08, `hilda33p` 10-06, `hilda34g` 10-03, `hilda33d` 10-01.
Its "Known issues" tab is the point of the release: it puts each remaining flaw to the reader and
asks whether it is a deal-breaker, fixable or acceptable.

**The posting plan (Marcus 2026-10-15):** (1) make the GitHub repo public; (2) post on Substack with
the CarboTope link; (3) push CarboTope with the Substack link. Before the link is posted:

1. **The repository must be public.** ✅ Public since 2026-10-15 (CHANGELOG 2026-10-15 z). `APP_REPO_URL` is set (2026-10-15) to
   `https://github.com/msarofim/CarbonCycleEmulator`, which 404s for everyone else until it is.
   The pre-public scan's decisions (CHANGELOG 2026-10-15 (a)) are Marcus's to make first.
2. **`APP_FEEDBACK_URL` must be set in `app/global.R`** to the Substack post the
   comments live under. ✅ Set 2026-10-15 to
   `https://thesaraphreport.substack.com/p/the-debut-of-carbotope-beta-a-new` (the bare post address;
   the share link's referral and utm_* parameters were removed, and the test now rejects them). Until it is, every card renders a visible "the comment
   link is not set in this build" warning instead of a link, and the tab's header
   says so too — deliberately, because a dead link costs exactly the feedback
   this release exists to collect. `tests/testthat/test-review-cards.R` asserts the
   placeholder machinery is wired; **update that test when you set the URL, do not delete it.**
   ⚠ **Steps (2) and (3) need each other's URL.** The app's URL is fixed in advance
   (Connect Cloud, above; it is live since 2026-10-15), so the post can link it now. On shinyapps.io
   the URL was fixed in advance but the post's first readers would have hit a 404 until the deploy. Either deploy FIRST with the placeholder (the cards say
   "comment link not set" until step 3) and check it live, then post, then redeploy with
   `APP_FEEDBACK_URL`; or, if Substack shows the post's final URL before publishing, set it and
   deploy before posting.
3. **Start-up: re-timed 2026-10-15** (see below). It is no longer the app's worst number.
4. **The hosting plan** (see "Hosting limits" below): on Free or Starter every visitor shares ONE
   R process, and Free stops serving after 25 active hours a month.

## Start-up cost — the number a visitor actually pays

Until 2026-10-20, start-up compiled the C++ core, ran the 1750 spin-up, one historical
integration and the box diagram's one-year flux trace, all before the first page was served.

⭐ **Since 2026-10-20 (CHANGELOG 2026-10-20 c) none of that is on the path to the first page:**
- the spin-up, the historical run and the flux trace are READ from `data/app_startup_precompute.rds`;
- the pulse lab's default (vvM, 100 GtC, 2050) is read from `data/pulse_default_precompute.rds` and drawn when the
  tab is opened, with no click (Marcus 2026-10-20, CHANGELOG 2026-10-20 d); changing a pulse setting grays the result
  out until "Release the pulse" computes the new one live;
- the C++ core compiles in a background R process started by `global.R` (`ccx_cpp_prebuild()`, `R/cpp.R`); the
  first live run waits for it, and any failure falls back to compiling in the app's own process.

Both products are refused unless built at the canonical's mode-file md5 AND at the build's run inputs (parameter
vector, forcing parameters, spin-up, years, pulse settings; compared identical). A refused product is not an error:
the app computes those values live, as before, and logs "precomputed ... values refused". Timed from deploy bundles
on the M4 (`outputs/diagnostics/app_precompute_timing_20261020/`, three fresh processes each):

| | before (`9cb7701`) | after (`1838885`) |
|---|---|---|
| process start → serving | 5.3–5.6 s | 1.5 s |
| process start → first plot drawn | 6.0–6.3 s | 2.3 s |
| default "Release the pulse", click → partition drawn | 3.7–3.8 s | 0.5 s |
| a non-default pulse (200 GtC, live in both) | 3.8–4.0 s | 3.8–3.9 s |
| Futures tab's first draw, opened right after the first plot | 1.8 s | 2.4–2.6 s (waits for the background compile) |
| peak memory of the process tree, first 8 s | 458–485 MB | 616–623 MB (the compile overlaps the loaded app) |

⚠ **Connect Cloud is not re-timed** (no redeploy was made). Its 18–27 s loading page also includes the container
start and package loading, which this does not touch.
⚠ **The products are computed on the Mac.** On Connect Cloud the live runs use Linux's compiler and libm, so a live
value there can differ from a stored one at roundoff. `data/review_precompute.rds` has always been in the same
position. Not measured.

### ⛔ REBUILD AT EVERY ADOPTION (and whenever a precompute test fails)

```bash
Rscript calibration/build_app_precompute.R
```

```bash
Rscript calibration/build_review_precompute.R
```

Run from the repo root, after the adoption's code is committed (the products record the commit), then commit the
products. Then run the two gates; both recompute every stored value live and require identity, so they also catch a
code or data change that moves a value at the same mode file:

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-app-precompute.R"); testthat::test_file("tests/testthat/test-review-precompute.R")'
```

Run them before building a deploy bundle too: a stale product at an unchanged mode file is accepted by the app, and
only these tests notice it.

The rest of this section is the 2026-10-15 record.

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
- The start-up note (`APP_WARMUP_NOTE`) was deleted 2026-10-20 (Marcus), once the first page stopped waiting on
  the compile and the spin-up (CHANGELOG 2026-10-20 c, h).

Everything after start-up is live, except the stored values named above: a counterfactual rerun is ~60 ms, three
coupled SSP futures ~0.5 s, a matched pulse pair over 1750–2300 ~0.65 s (older measurements). The
pulse lab's "Release the pulse" drew both of its plots 4.0 s after the click (10-15, bundle). Since 2026-10-20 the
default is drawn 0.5 s after the tab is opened, with no click; other settings take 3.7 s after the click (M4).
**The "Known issues" tab needs three runs the app does not otherwise make** (a gate
run to 2025, an ENSO knockout, a 1000-year pulse pair; the card that spun up a second mode was
retired 2026-10-01). Since 2026-10-15 (bb) their results are PRECOMPUTED in `data/review_precompute.rds`,
which is refused unless built at the canonical's mode-file md5 (the tab then computes them live, as before).
**Rebuild it at every adoption** with `calibration/build_review_precompute.R` (see "REBUILD AT EVERY ADOPTION"
above); `test-review-precompute.R` fails until it is. First view on Connect Cloud: 30.7 s live, 4.0 s precomputed (10-15 bb; again 10-16 j).
Everything else on that tab is still computed on first view, not at start-up.

## Hosting limits (shinyapps.io; checked 2026-10-15)

From Posit's applications guide (docs.posit.co/shinyapps.io/guide/applications/):
- **Free and Starter: 1 worker process and 1 instance.** Every simultaneous visitor shares ONE R
  process. R runs one computation at a time, so a visitor's 4-second pulse release delays everyone
  else's next click by up to that long. Basic and above allow up to 10 workers per instance and
  3–10 instances.
- **Memory:** the default "large" instance allows 1024 MB. Measured 2026-10-15: the app's R process
  held **204 MB** after one full session (every tab, all nine review-card plots, one pulse, one
  build-your-own run).
- **Bundle:** at most 1 GB on Free/Starter. This bundle is 7.2 MB (113 files; `1838885`, with the two
  2026-10-20 precompute products, 3 MB of it).
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
| `app/` | the app. ⚠ Everything in `app/www/` is served publicly at the app's URL. Since 2026-10-15 that is only `sarofim_essenhigh_comment_2011.pdf`. Nothing in the app links to it (corrected 2026-10-16; this line said it did): it is hosted for the Substack contrarians post's link to the 2011 comment (the unlinked `.doc` was removed: Marcus, "Delete the .doc file: the pdf is good enough") |
| `R/` | the model |
| `src/ccx_core.cpp` | compiled at startup, in a background R process since 2026-10-20 (`R/cpp.R` `ccx_cpp_prebuild()`) |
| `data/*.rds` | observations, forcings, the FaIR climate module, the nuclear ¹⁴C source, and the three precompute products (`app_startup_precompute.rds`, `pulse_default_precompute.rds`, `review_precompute.rds`) |
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

## Posit Connect Cloud (test deploy 2026-10-15)

Posit is moving shinyapps.io apps to Connect Cloud: automatic migration begins in early 2027, old URLs
redirect, and existing plans keep their price until 2029 (Posit blog, 2026-07-21, "Migrating to Connect
Cloud"). So Connect Cloud was tried first, on the free plan (Marcus: "Prepare the Connect Cloud files and
try the free plan").

**No repository files are needed.** `rsconnect` (≥ 1.11.2 here) publishes the same bundle directly and
writes its own manifest (47 packages, R 4.5.3). Nothing is deployed from GitHub, so the repository can
stay private.

```r
rsconnect::connectCloudUser()      # once, by the account owner (browser sign-in)
```

```bash
app/make_deploy_bundle.sh /tmp/carbotope_bundle
Rscript -e 'rsconnect::deployApp("/tmp/carbotope_bundle", appName = "carbotope", appTitle = "CarboTope", account = "saraphreport", server = "connect.posit.cloud")'
```

**Redeploying to the SAME content** from a fresh bundle directory (it has no deployment record, so name
the content or rsconnect creates a second app):

```bash
Rscript -e 'rsconnect::deployApp("<bundle_dir>", appId = "01a14244-5cc3-1951-7b06-9e2fb07beae3", account = "saraphreport", server = "connect.posit.cloud", forceUpdate = TRUE)'
```

- ⚠ **Set up the account in the browser BEFORE `connectCloudUser()`.** With a Posit login that has no
  Connect Cloud account yet, rsconnect 1.11.2 fails with "`serverName` must be a single string, not
  `NULL`". The account-list request is refused, and the token-refresh handler in `connectCloudClient()`
  intercepts that before `selectCloudAccount()`'s new-user branch, then calls `registerAccount()` with
  no server name.
- Test deploy: account `saraphreport`, content `01a14244-5cc3-1951-7b06-9e2fb07beae3`, built from
  `187a6da` (the release tag minus the `.doc`). Public, because the free plan has no private content.
  The app URL is `https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/` (no vanity
  name set). The management page is `connect.posit.cloud/saraphreport/content/<id>`.
- The deploy took about 20 s, with no package compilation visible.

**Results (free plan, 1 CPU / 4 GB; checked in a 1440×900 browser window):**

| check | Connect Cloud free | laptop bundle, 10-15 |
|---|---|---|
| C++ core compiles at start-up | yes | yes |
| first plot after opening | 3.0 s (probably already running after publish); **27.0 s cold** (first visit to the 1 GB revision) | 6–8 s cold |
| all eight tabs, all plots, no output errors | yes (25 plots incl. nine Known-issues cards) | yes |
| Build your own, "Run it" | 5.0 s; 701 ppm in 2150 | 5.4 s (load ~30) |
| Pulse lab, "Release the pulse" | 11.8 s; 50 % at +100 yr, 41 % at +250 yr | 14.6 s (load ~30); 4.0 s (10-15, idle) |
| Known issues, first view | 30.7 s (4 GB); 4.2 s (1 GB revision); 4.0 s precomputed (10-15 bb, 10-16 j) | memoized in the test; ~6 s contended (pre-10-15) |
| provenance line | posterior mode, 31 fitted, 14 held | same |
| page sub/superscripts; plot δ¹³C and ‰ glyphs | render | render |
| `/sarofim_essenhigh_comment_2011.pdf`; the `.doc` | 200; 404 | 200; 404 |

**Plan and settings (Marcus, 2026-10-15): upgraded to Basic ($190/yr: 8 GB / 2 CPU max, 100 usage credits a
month, 25 apps, private-repo deploys); memory set to 1 GB on the app's own settings page, then republished.**
The API confirms 1 CPU / 1024 MB on the live revision. Credits per hour = 0.75 × CPU + 0.25 × GB
(docs.posit.co/connect-cloud/user/usage.html), so 1.0 credit an hour of serving, about 100 hours a
month. A setting change applies only after a republish, and only if made on the content itself. At 1 GB
everything ran with no disconnects: pulse 11.8 s, Build your own 4.6 s. Paid-plan credit limits are not
enforced until 2027; Free-plan limits start with the first period beginning on or after 2026-11-01.

Still not known: how many R processes serve simultaneous visitors, and whether the connection timeout
(3600 s, the Posit Connect default) keeps an abandoned browser tab billing for an hour.

## How to deploy to shinyapps.io (the fallback; never done)

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
