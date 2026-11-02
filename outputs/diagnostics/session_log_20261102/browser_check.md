# Session log: local browser check, 2026-11-02 (CHANGELOG 2026-11-02 a)

Local app (`ccx-app`, port 7788) in the built-in browser at 1440 x 900. Opened http://localhost:7788/, then
`location.href = 'http://127.0.0.1:7788/'` (a cross-origin hop, so the second page has a referrer), clicked
Isotope fingerprints, clicked the NH radio of `i_hemi`, then closed the socket.

Browser side, second page: `document.referrer` = "http://localhost:7788/"; the input `ccx_referrer` = "localhost"
(host only); `location.search` = "?_inputs_&tabs=%22Isotope%20fingerprints%22&i_years=%5B1940%2C2024%5D&i_hemi=%22both%22"
(no referrer in the shareable address).

Server log (`preview_logs`, search CCX_SESSION):

    CCX_SESSION {"event":"start","id":"f6c2358b","start":"2026-11-02T13:35:22Z","client":"desktop"}
    CCX_SESSION {"event":"end","id":"f6c2358b","start":"2026-11-02T13:35:22Z","client":"desktop","dur_s":13,"ref":"none","tabs":["The Keeling Curve"],"n_changes":0,"changed":[]}
    CCX_SESSION {"event":"start","id":"beffa0f5","start":"2026-11-02T13:35:35Z","client":"desktop"}
    CCX_SESSION {"event":"end","id":"beffa0f5","start":"2026-11-02T13:35:35Z","client":"desktop","dur_s":26,"ref":"localhost","tabs":["The Keeling Curve","Isotope fingerprints"],"n_changes":1,"changed":["i_hemi"]}
