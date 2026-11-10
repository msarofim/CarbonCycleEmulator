# Landing page: browser check, 2026-11-10 (CHANGELOG 2026-11-10 b)

`docs/` served locally (`python3 -m http.server 7796 --directory docs`, a temporary `.claude/launch.json` entry, reverted),
read in the built-in browser.

| check | result |
|---|---|
| 1440 x 900 | title "CarboTope: a carbon-cycle model built for students"; preview image loads (1200 px); no horizontal scroll |
| 375 x 812 | no horizontal scroll (scroll width 375); the button is 343 px wide at 16 px from the edge; lead text 16.8 px |
| No interaction after load | 0 requests to the app (Resource Timing entries for `posit.cloud`) |
| Pointer move, then scroll | exactly 1 request to the app, from the first event |
| `window.scrollTo` alone on a fresh load | the scroll event fired; 1 request to the app |
| `localhost:7796/?_inputs_&tabs="Futures"&f_mode="Pulse lab"` | landed on the app's address with that query; Futures -> Pulse lab active; connected. The socket was closed at 20:42:43 UTC, so the visit log has one short "desktop" session from this check |

A first attempt at the scroll check sent no request: the pane's simulated wheel did not move the page (no scroll
event in that run). Re-run with the event listeners logged, the scroll event and the request both came.

`preview.png` is the local app (`ccx-app`, port 7788, code as deployed at `54e9ef8`) at 1440 x 756, headless Chrome,
after both Keeling charts drew, resized to 1200 x 630 with `sips`.

Mutation test of `tests/testthat/test-landing-page.R`: `mutate_landing_page.sh`, log beside it; the unmutated copy
passes and each of seven mutations fails its block.
