# Group B bundle, local checks (2026-11-15)

Bundle `~/ccx_frozen/bundle_20261115_8ba6c320` (`app/make_deploy_bundle.sh`, commit `8ba6c320`, 117 files, 7.4 MB),
served locally on port 7791 through a temporary `.claude/launch.json` entry (reverted), checked in headless Chrome.

- **Against the live bundle** (`~/ccx_frozen/bundle_20261111_64d91397`, `diff -rq`, `rsconnect` excluded): seven files
  differ, `app/R/{params_meta,plots,plots_review,review}.R`, `app/{global,server,ui}.R`, plus `FROZEN_FROM_COMMIT.txt`.
  The same seven as `git diff --name-only 64d91397 8ba6c320` over the ship list. No `data/` file changed.
- **Every tab draws** (`check_live_pointer.py`, 1440 × 900 and 375 × 812): both Known-issue pointers open their card;
  the CSV names `8ba6c32`; every tab and sub-tab draws with no output errors, except Futures → Build your own, which
  draws nothing until "Run it" (by design, as in batch A). Logs `check_live_pointer_{1440,375}.log`.
- **Download links** (`check_dl_links.py`, both sizes): ALL OK. Logs `check_dl_links_{1440,375}.log`.
- **Phone** (`cdp_shoot.py` with `groupb_build_20261115/phone_check.json`, 375 × 812, touch): banner and takeaway
  edges 12–363; download links 32 px; the share link on one line; the three readout numbers at 442 px; the takeaway
  20 px from the top after Run it and after Release the pulse; the chart at opacity 0.35 with "Calculating…" 300 ms
  after each press. Values in `shots_phone/values_phone_check.json`.
- **Card 4a's caption** (`shots_1440/card4a_rv_variance.png`): "…averaged over the twelve months to each January,
  where both peak, r is +0.73 for the model and +0.51 for the measurements (n = 45)…".
