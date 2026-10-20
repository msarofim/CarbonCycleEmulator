"""Deep-link round trip on every CarboTope tab (2026-10-20; app/R/links.R).

For each view: open the app in one browser context, set the view through its controls (clicks on the tab, the
pill and the radio/checkboxes; the sliders' and menus' own JavaScript APIs), wait for the address bar to change,
and record what the page shows. Then open that address in a FRESH browser context (own cookies and storage,
like a second person) and require the same tab, pill and settings. Also checked there: the address stays the
same after the restore; the chart's CSV download carries the link in its header; which button a restored link
presses (APP_LINK_AUTORUN as drafted: "Build your own" yes, "Pulse lab" no).
CONTROLS give the comparison its power: a link with one setting changed by hand, and the bare address with no
settings, must each come back DIFFERENT from the view that was set, on exactly the settings changed. Stdlib only.

Usage:  roundtrip.py <debug_port> <app_url> <out_csv> [<screenshot_dir>]
Needs a headless Chrome listening on <debug_port>. The app must be the LOCAL one (never the live host).
"""
import sys, json, time, socket, base64, os, struct, urllib.request, urllib.parse, csv

port, app_url, out_csv = int(sys.argv[1]), sys.argv[2], sys.argv[3]
shot_dir = sys.argv[4] if len(sys.argv) > 4 else None
TIMEOUT_S = 120
POLL_S = 0.25
assert urllib.parse.urlparse(app_url).hostname in ("127.0.0.1", "localhost"), "local app only"


class WS:
    """Minimal client-side websocket for one DevTools endpoint (as loadtest_20261020/loadtest.py)."""
    def __init__(self, path):
        self.s = socket.create_connection(("127.0.0.1", port))
        key = base64.b64encode(os.urandom(16)).decode()
        self.s.sendall((f"GET {path} HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nUpgrade: websocket\r\n"
                        f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        self.buf = b""
        while b"\r\n\r\n" not in self.buf:
            self.buf += self.s.recv(4096)
        self.buf = self.buf.split(b"\r\n\r\n", 1)[1]
        self.i = 0

    def _exact(self, n):
        while len(self.buf) < n:
            c = self.s.recv(1 << 20)
            if not c: raise EOFError("devtools socket closed")
            self.buf += c
        d, self.buf = self.buf[:n], self.buf[n:]
        return d

    def _send(self, obj):
        data = json.dumps(obj).encode(); n = len(data); h = bytes([0x81])
        if n < 126: h += bytes([0x80 | n])
        elif n < 65536: h += bytes([0x80 | 126]) + struct.pack(">H", n)
        else: h += bytes([0x80 | 127]) + struct.pack(">Q", n)
        m = os.urandom(4)
        self.s.sendall(h + m + bytes(b ^ m[k % 4] for k, b in enumerate(data)))

    def _recv(self):
        p = b""
        while True:
            b0, b1 = self._exact(2); n = b1 & 0x7F
            if n == 126: n = struct.unpack(">H", self._exact(2))[0]
            elif n == 127: n = struct.unpack(">Q", self._exact(8))[0]
            p += self._exact(n)
            if b0 & 0x80: return json.loads(p)

    def call(self, method, **params):
        self.i += 1; i = self.i
        self._send({"id": i, "method": method, "params": params})
        while True:
            m = self._recv()
            if m.get("id") == i:
                if "error" in m: raise RuntimeError(f"{method}: {m['error']}")
                return m.get("result", {})

    def close(self):
        try: self.s.close()
        except OSError: pass


bpath = json.load(urllib.request.urlopen(f"http://127.0.0.1:{port}/json/version"))["webSocketDebuggerUrl"]
BROWSER = WS(bpath.split(f":{port}", 1)[1])

CONNECTED = "!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())"
IDLE = "!document.documentElement.classList.contains('shiny-busy')"

# What the page SHOWS: the active tab and pill, and each control's widget state (not Shiny's copy of it).
STATE_JS = r"""
(function () {
  var nav = document.querySelector('.navbar .nav-link.active, .navbar li.active > a');
  var pill = document.querySelector('#f_mode .nav-link.active, #f_mode li.active > a');
  var s = {tab: nav ? nav.getAttribute('data-value') : null, pill: pill ? pill.getAttribute('data-value') : null};
  document.querySelectorAll('input.js-range-slider').forEach(function (el) {
    var r = $(el).data('ionRangeSlider'); if (!r) return;
    s[el.id] = r.options.type === 'double' ? [r.result.from, r.result.to] : r.result.from;
  });
  ['k_hemi', 'i_hemi', 'f_yvar', 'cm_level'].forEach(function (id) {
    var c = document.querySelector('input[name="' + id + '"]:checked'); s[id] = c ? c.value : null;
  });
  ['k_obs', 'f_fair'].forEach(function (id) { var c = document.getElementById(id); s[id] = c ? c.checked : null; });
  ['c_mech', 'f_scen'].forEach(function (id) {
    s[id] = [].slice.call(document.querySelectorAll('input[name="' + id + '"]:checked')).map(function (c) { return c.value; });
  });
  ['s_kind', 's_bg', 'p_bg'].forEach(function (id) { var c = document.getElementById(id); s[id] = c ? $(c).val() : null; });
  s.f_fair_label = (function () { var l = document.querySelector('#f_fair'); l = l && l.closest('label'); return l ? l.textContent.trim() : null; })();
  return s;
})()
"""

# The controls, driven as a reader drives them.
def click_tab(v):  return f"[...document.querySelectorAll('.navbar a')].find(a => a.getAttribute('data-value') === {json.dumps(v)}).click(); true"
def click_pill(v): return f"document.querySelector('#f_mode a[data-value={json.dumps(v)}]').click(); true"
def slider(id_, v):
    if isinstance(v, list): return f"$('#{id_}').data('ionRangeSlider').update({{from: {v[0]}, to: {v[1]}}}); $('#{id_}').trigger('change'); true"
    return f"$('#{id_}').data('ionRangeSlider').update({{from: {v}}}); $('#{id_}').trigger('change'); true"
def radio(id_, v): return f"document.querySelector('input[name=\"{id_}\"][value={json.dumps(v)}]').click(); true"
def check(id_, on): return f"(function(){{var c=document.getElementById('{id_}'); if (c.checked !== {str(on).lower()}) c.click(); return true;}})()"
def group(id_, vals): return (f"(function(){{var w={json.dumps(vals)}; document.querySelectorAll('input[name=\"{id_}\"]').forEach(function(c){{"
                              f"if (c.checked !== (w.indexOf(c.value) >= 0)) c.click();}}); return true;}})()")
def select(id_, v): return f"(function(){{var e=document.getElementById('{id_}'); if (e.selectize) e.selectize.setValue({json.dumps(v)}); else $(e).val({json.dumps(v)}).trigger('change'); return true;}})()"

# Each view: steps to set it, the settings that must come back, the first chart's download, the button checks.
VIEWS = [
    ("Keeling", [click_tab("The Keeling Curve"), slider("k_years", [1980, 2010]), radio("k_hemi", "NH"), check("k_obs", False)],
     ["tab", "k_years", "k_hemi", "k_obs"], "k_plot", None),
    ("Where does the carbon go", [click_tab("Where does the carbon go?"), slider("w_years", [1900, 2000])],
     ["tab", "w_years"], "w_partition", None),
    ("What if, two switches", [click_tab("What if…?"), group("c_mech", ["enso", "volcanic"]), slider("c_years", [1950, 2020])],
     ["tab", "c_mech", "c_years"], "c_plot", None),
    ("What if, nothing switched off", [click_tab("What if…?"), group("c_mech", [])],
     ["tab", "c_mech", "c_years"], "c_plot", None),
    ("Isotopes", [click_tab("Isotope fingerprints"), slider("i_years", [1950, 2000]), radio("i_hemi", "SH")],
     ["tab", "i_years", "i_hemi"], "i_d13c", None),
    ("Futures, Scenarios", [click_tab("Futures"), click_pill("Scenarios"), group("f_scen", ["vvVL", "vvH"]),
                            radio("f_yvar", "gmst"), check("f_fair", True)],
     ["tab", "pill", "f_scen", "f_yvar", "f_fair", "f_fair_label"], "f_plot", None),
    ("Futures, Build your own", [click_tab("Futures"), click_pill("Build your own"), select("s_kind", "to_zero"),
                                 slider("s_zero_year", 2080), select("s_bg", "vvH"), radio("f_yvar", "co2_ppm")],
     ["tab", "pill", "s_kind", "s_zero_year", "s_bg", "f_yvar"], "f_plot", ("s_go", True)),
    ("Futures, Pulse lab", [click_tab("Futures"), click_pill("Pulse lab"), select("p_bg", "vvH"), slider("p_gtc", 200),
                            slider("p_year", 2070), radio("f_yvar", "gmst")],
     ["tab", "pill", "p_bg", "p_gtc", "p_year", "f_yvar", "f_fair_label"], None, ("p_go", False)),
    ("Known issues", [click_tab("Known issues")], ["tab"], "rv_repdc", None),
    ("What pins down what", [click_tab("What pins down what?"), radio("cm_level", "parameter")],
     ["tab", "cm_level"], "cm_map", None),
    ("Under the hood", [click_tab("Under the hood")], ["tab"], "h_diagram", None),
]


def open_page():
    ctx = BROWSER.call("Target.createBrowserContext")["browserContextId"]
    tgt = BROWSER.call("Target.createTarget", url="about:blank", browserContextId=ctx)["targetId"]
    pg = WS(f"/devtools/page/{tgt}")
    pg.call("Emulation.setDeviceMetricsOverride", width=1440, height=900, deviceScaleFactor=1, mobile=False)
    pg.call("Page.enable")
    return ctx, tgt, pg


def close_page(ctx, tgt, pg):
    pg.close()
    BROWSER.call("Target.closeTarget", targetId=tgt)
    BROWSER.call("Target.disposeBrowserContext", browserContextId=ctx)


def js(pg, e):
    r = pg.call("Runtime.evaluate", expression=e, returnByValue=True, awaitPromise=True)
    if "exceptionDetails" in r: raise RuntimeError(f"js error: {r['exceptionDetails'].get('text')} in {e[:80]}")
    return r.get("result", {}).get("value")


def wait(pg, expr, what):
    t = time.time()
    while time.time() - t < TIMEOUT_S:
        if js(pg, expr): return time.time() - t
        time.sleep(POLL_S)
    raise TimeoutError(f"{what} not done in {TIMEOUT_S} s")


def settle(pg, s=1.0):
    time.sleep(s); wait(pg, IDLE, "idle")


def csv_header(pg, out_id):
    """The chart's CSV, fetched through its own download link (the page's session), header lines only."""
    return js(pg, f"""(async function(){{ var a = document.getElementById('{out_id}_csv');
        if (!a || !a.href || a.href.endsWith('#')) return null;
        var t = await (await fetch(a.href)).text(); return t.split('\\n'); }})()""")


# (view, how the link is altered, the settings that must then differ)
CONTROLS = [
    ("Keeling", lambda u: u.replace("k_hemi=%22NH%22", "k_hemi=%22SH%22"), {"k_hemi"}),
    ("Futures, Pulse lab", lambda u: u.split("?", 1)[0], {"tab", "pill", "p_bg", "p_gtc", "p_year", "f_yvar", "f_fair_label"}),
    ("What if, nothing switched off", lambda u: u.replace("c_mech=null", ""), {"c_mech"}),
]

rows = []
for name, steps, keys, dl_id, button in VIEWS:
    row = {"view": name, "ok": False, "failure": ""}
    try:
        # --- context A: set the view
        A = open_page()
        A[2].call("Page.navigate", url=app_url)
        wait(A[2], CONNECTED, "connect"); settle(A[2], 2.0)
        for st in steps:
            js(A[2], st); settle(A[2], 0.6)
        settle(A[2], 1.5)
        url = js(A[2], "location.href")
        want = js(A[2], STATE_JS)
        close_page(*A)
        row["url"] = url
        q = urllib.parse.unquote(urllib.parse.urlparse(url).query)
        row["query"] = q
        row["n_settings_in_link"] = q.count("&")
        # --- context B: a fresh browser opens the link
        B = open_page()
        B[2].call("Page.navigate", url=url)
        wait(B[2], CONNECTED, "connect"); settle(B[2], 2.5)
        got = js(B[2], STATE_JS)
        row["url_after_restore_same"] = js(B[2], "location.href") == url
        bad = [k for k in keys if got.get(k) != want.get(k)]
        row["checked"] = ";".join(f"{k}={json.dumps(want.get(k), ensure_ascii=False)}" for k in keys)
        if bad:
            row["failure"] = "; ".join(f"{k}: set {json.dumps(want.get(k), ensure_ascii=False)}, restored {json.dumps(got.get(k), ensure_ascii=False)}" for k in bad)
        if button:
            bid, pressed = button
            v = js(B[2], f"(function(){{var b=document.getElementById('{bid}'); return b ? +($(b).data('val') || 0) : null;}})()")
            drawn = js(B[2], "(function(){var o=document.getElementById('f_plot'); var i=o&&o.querySelector('img'); return !!i && i.naturalWidth>0;})()")
            row[f"{bid}_pressed"] = (v or 0) > 0
            row["f_plot_drawn"] = drawn
            if row[f"{bid}_pressed"] != pressed or drawn != pressed:
                row["failure"] += f" {bid}: pressed {row[f'{bid}_pressed']}, chart drawn {drawn}, expected {pressed}"
        if dl_id:
            h = csv_header(B[2], dl_id)
            row["csv_link_line"] = bool(h) and any(l.strip("﻿") == f"# Link to this view: {url}" for l in h[:12])
            row["csv_data_rows"] = sum(1 for l in (h or []) if l and not l.lstrip("﻿").startswith("#")) - 1
            if not row["csv_link_line"] or row["csv_data_rows"] < 1:
                row["failure"] += f" CSV of {dl_id}: link line {row['csv_link_line']}, {row['csv_data_rows']} rows"
        if not row["url_after_restore_same"]:
            row["failure"] += " the address changed after the restore"
        for cname, alter, must_differ in CONTROLS:
            if cname != name: continue
            u2 = alter(url)
            if u2 == url: row["failure"] += " control: the alteration did not change the link"; continue
            Cc = open_page()
            Cc[2].call("Page.navigate", url=u2)
            wait(Cc[2], CONNECTED, "connect"); settle(Cc[2], 2.5)
            got2 = js(Cc[2], STATE_JS)
            close_page(*Cc)
            diff = {k for k in keys if got2.get(k) != want.get(k)}
            row["control"] = f"{u2[len(app_url):] or '(bare address)'} -> differs on {sorted(diff)}"
            if diff != must_differ:
                row["failure"] += f" control: expected to differ on {sorted(must_differ)}, differed on {sorted(diff)}"
        if shot_dir:
            png = B[2].call("Page.captureScreenshot", format="png")["data"]
            with open(os.path.join(shot_dir, "restored_" + name.lower().replace(", ", "_").replace(" ", "_") + ".png"), "wb") as f:
                f.write(base64.b64decode(png))
        close_page(*B)
        row["ok"] = not row["failure"]
    except Exception as e:
        row["failure"] = f"{type(e).__name__}: {e}"[:300]
    rows.append(row)
    print(f"{'PASS' if row['ok'] else 'FAIL'}  {name}: {row.get('query', '')}  {row['failure']}", flush=True)

fields = ["view", "ok", "query", "n_settings_in_link", "checked", "url_after_restore_same", "s_go_pressed", "p_go_pressed",
          "f_plot_drawn", "csv_link_line", "csv_data_rows", "control", "failure", "url"]
with open(out_csv, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
    w.writeheader()
    for r in rows: w.writerow(r)
print(f"{sum(r['ok'] for r in rows)}/{len(rows)} views passed; wrote {out_csv}", flush=True)
