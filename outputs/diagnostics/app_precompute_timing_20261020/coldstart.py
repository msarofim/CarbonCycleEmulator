"""Cold start of CarboTope from a deploy bundle, timed the way a first visitor pays it (2026-10-20).

For each repetition: start a FRESH R process serving the bundle (so the C++ core compiles cold), time
process start -> HTTP 200 ("serving"), then open the app in a new headless-Chrome browser context and time
process start -> first plot drawn. Then Futures -> Pulse lab -> "Release the pulse" with the default settings
(timed from the click to the partition panel drawn), then one NON-default pulse (pulse size set to
NONDEFAULT_GTC through Shiny.setInputValue, same timing). Records the R process's resident memory at each
point. Stdlib only; the DevTools client is the one in ../loadtest_20261020/loadtest.py.

Usage:  coldstart.py <chrome_debug_port> <bundle_dir> <app_port> <reps> <out_csv> <label>
Needs a headless Chrome already listening on <chrome_debug_port>. Local only: never point it at the live app.
"""
import sys, json, time, socket, base64, os, struct, urllib.request, csv, subprocess

STEP_TIMEOUT_S = 300
POLL_S = 0.05                 # fine polling: the numbers being measured are ~1 s
NONDEFAULT_GTC = 200          # a pulse size off the default (100), so the live path runs
chrome_port, bundle, app_port, reps, out_csv, label = (int(sys.argv[1]), sys.argv[2], int(sys.argv[3]),
                                                       int(sys.argv[4]), sys.argv[5], sys.argv[6])
app_url = f"http://127.0.0.1:{app_port}/"


class WS:
    """Minimal client-side websocket for one DevTools endpoint (copied from loadtest.py)."""
    def __init__(self, path):
        self.s = socket.create_connection(("127.0.0.1", chrome_port))
        key = base64.b64encode(os.urandom(16)).decode()
        self.s.sendall((f"GET {path} HTTP/1.1\r\nHost: 127.0.0.1:{chrome_port}\r\nUpgrade: websocket\r\n"
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


CONNECTED = "!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())"
FIRST_PLOT = ("(function(){var p=document.querySelector('.tab-pane.active .shiny-plot-output img');"
              " return !!p && p.naturalWidth>0;})()")
# the partition panel drawn, not recalculating, and Shiny idle; `token` guards against reading the PREVIOUS
# pulse's image: the img src must differ from the one recorded before the click
PULSE_READY = ("(function(prev){var o=document.getElementById('f_partition'); if(!o) return false; var i=o.querySelector('img');"
               " return !!i && i.naturalWidth>0 && i.src!==prev && !o.classList.contains('recalculating')"
               " && !document.documentElement.classList.contains('shiny-busy');})")
PULSE_SRC = "(function(){var o=document.getElementById('f_partition'); var i=o&&o.querySelector('img'); return i?i.src:'';})()"
TAKEAWAY = "(function(){var o=document.getElementById('f_takeaway'); return o?o.textContent:'';})()"
ERRORS = "document.querySelectorAll('.shiny-output-error:not(.shiny-output-error-validation)').length"


def rss_mb(pid):
    try:
        return round(int(subprocess.check_output(["ps", "-o", "rss=", "-p", str(pid)]).strip()) / 1024, 1)
    except Exception:
        return None


def one_rep(rep, browser):
    row = {"label": label, "rep": rep}
    log = open(f"{out_csv[:-4]}_rep{rep}.log", "w")
    t0 = time.time()
    r = subprocess.Popen(["Rscript", "-e", f"shiny::runApp('{bundle}', port = {app_port}, host = '127.0.0.1', "
                          "launch.browser = FALSE)"], stdout=log, stderr=subprocess.STDOUT)
    ctx = target = page = None
    try:
        while True:
            if r.poll() is not None: raise RuntimeError("R exited before serving")
            try:
                if urllib.request.urlopen(app_url, timeout=1).status == 200: break
            except Exception:
                pass
            if time.time() - t0 > STEP_TIMEOUT_S: raise TimeoutError("not serving")
            time.sleep(POLL_S)
        row["serving_s"] = time.time() - t0
        row["rss_serving_mb"] = rss_mb(r.pid)
        ctx = browser.call("Target.createBrowserContext")["browserContextId"]
        target = browser.call("Target.createTarget", url="about:blank", browserContextId=ctx)["targetId"]
        page = WS(f"/devtools/page/{target}")
        page.call("Emulation.setDeviceMetricsOverride", width=1440, height=900, deviceScaleFactor=1, mobile=False)
        js = lambda e: page.call("Runtime.evaluate", expression=e, returnByValue=True,
                                 awaitPromise=True).get("result", {}).get("value")

        def wait(expr, what):
            t = time.time()
            while time.time() - t < STEP_TIMEOUT_S:
                if js(expr): return time.time()
                time.sleep(POLL_S)
            raise TimeoutError(f"{what} not done in {STEP_TIMEOUT_S} s")

        page.call("Page.navigate", url=app_url)
        row["connect_s"] = wait(CONNECTED, "connect") - t0
        row["first_plot_s"] = wait(FIRST_PLOT, "first plot") - t0
        row["rss_first_plot_mb"] = rss_mb(r.pid)
        js("document.querySelector('a[data-value=\"Futures\"]').click(); true")
        wait("(function(){var a=document.querySelector('a[data-value=\"Pulse lab\"]'); return !!a && a.offsetParent!==null;})()",
             "pulse pill")
        js("document.querySelector('a[data-value=\"Pulse lab\"]').click(); true")
        wait("(function(){var b=document.getElementById('p_go'); return !!b && b.offsetParent!==null;})()", "pulse button")
        row["since_start_at_click_s"] = time.time() - t0
        for kind, prep in (("default", None), ("nondefault", f"Shiny.setInputValue('p_gtc', {NONDEFAULT_GTC}); true")):
            if prep: js(prep); time.sleep(0.2)
            prev = js(PULSE_SRC) or ""
            tc = time.time()
            js("document.getElementById('p_go').click(); true")
            row[f"pulse_{kind}_s"] = wait(f"{PULSE_READY}({json.dumps(prev)})", f"{kind} pulse") - tc
            row[f"takeaway_{kind}"] = js(TAKEAWAY)
            row[f"rss_after_{kind}_mb"] = rss_mb(r.pid)
        row["errors"] = js(ERRORS)
    except Exception as e:
        row["failure"] = f"{type(e).__name__}: {e}"[:200]
    finally:
        if page: page.close()
        try:
            if target: browser.call("Target.closeTarget", targetId=target)
            if ctx: browser.call("Target.disposeBrowserContext", browserContextId=ctx)
        except Exception: pass
        r.terminate()
        try: r.wait(10)
        except subprocess.TimeoutExpired: r.kill(); r.wait()
        log.close()
    return row


bp = json.load(urllib.request.urlopen(f"http://127.0.0.1:{chrome_port}/json/version"))["webSocketDebuggerUrl"]
browser = WS(bp.split(f":{chrome_port}", 1)[1])
rows = []
for k in range(1, reps + 1):
    row = one_rep(k, browser)
    rows.append(row)
    print({k: (round(v, 2) if isinstance(v, float) else v) for k, v in row.items() if not k.startswith("takeaway")},
          flush=True)
    time.sleep(2)
fields = ["label", "rep", "serving_s", "connect_s", "first_plot_s", "since_start_at_click_s", "pulse_default_s",
          "pulse_nondefault_s", "rss_serving_mb", "rss_first_plot_mb", "rss_after_default_mb", "rss_after_nondefault_mb",
          "errors", "failure", "takeaway_default", "takeaway_nondefault"]
with open(out_csv, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
    w.writeheader()
    for r in rows:
        w.writerow({k: (round(v, 3) if isinstance(v, float) else v) for k, v in r.items()})
print(f"wrote {out_csv}", flush=True)
