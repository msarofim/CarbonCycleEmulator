"""Load test of the live CarboTope app (Marcus 2026-10-20: "Run the load test").

Simulates N students who open the app at the same moment and do the classroom sequence: load the app, open
Futures -> Pulse lab, press "Release the pulse", then open the Known issues tab. Each student is a separate Chrome
browser context (own cookies and connection pool, like a separate person), driven over the DevTools protocol from
its own thread. Stdlib only.

Usage:  loadtest.py <debug_port> <app_url> <out_csv> <N> [<N> ...]
Needs a headless Chrome already listening on <debug_port>. One warm-up visit runs first and is not scored.
"""
import sys, json, time, socket, base64, os, struct, threading, urllib.request, csv

STEP_TIMEOUT_S = 900          # per step; a serialized queue of 20 pulses at ~12 s each is ~240 s
POLL_S = 0.5
PAUSE_BETWEEN_N_S = 30        # let the previous sessions close before the next step
KI_PLOTS = 9                  # Known issues draws nine plots (2026-10-16 live check)
port, app_url, out_csv = int(sys.argv[1]), sys.argv[2], sys.argv[3]
NS = [int(a) for a in sys.argv[4:]]


class WS:
    """Minimal client-side websocket for one DevTools endpoint."""
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


browser_path = json.load(urllib.request.urlopen(f"http://127.0.0.1:{port}/json/version"))["webSocketDebuggerUrl"]
browser_path = browser_path.split(f":{port}", 1)[1]
blk = threading.Lock()
BROWSER = WS(browser_path)

def bcall(method, **p):
    with blk: return BROWSER.call(method, **p)


CONNECTED = "!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())"
DISCONNECTED = ("!!(document.getElementById('shiny-disconnected-overlay') || "
                "(window.Shiny && Shiny.shinyapp && !Shiny.shinyapp.isConnected()))")
FIRST_PLOT = ("(function(){var p=document.querySelector('.tab-pane.active .shiny-plot-output img');"
              " return !!p && p.naturalWidth>0;})()")
PULSE_READY = ("(function(){var o=document.getElementById('f_partition'); if(!o) return false; var i=o.querySelector('img');"
               " return !!i && i.naturalWidth>0 && !o.classList.contains('recalculating')"
               " && !document.documentElement.classList.contains('shiny-busy');})()")
KI_READY = ("(function(){var a=[...document.querySelectorAll('.navbar a')].find(x=>x.textContent.trim()==='Known issues');"
            " if(!a) return false; var pane=document.querySelector(a.getAttribute('href')||a.dataset.bsTarget); if(!pane) return false;"
            " var o=[...pane.querySelectorAll('.shiny-plot-output')]; var d=o.filter(x=>{var i=x.querySelector('img');"
            " return i && i.naturalWidth>0 && !x.classList.contains('recalculating');});"
            f" return o.length>={KI_PLOTS} && d.length===o.length && !document.documentElement.classList.contains('shiny-busy');}})()")
ERRORS = "document.querySelectorAll('.shiny-output-error:not(.shiny-output-error-validation)').length"


def student(vu, n, t0_barrier, rows):
    row = {"n": n, "vu": vu, "connect_s": None, "first_plot_s": None, "pulse_s": None, "known_issues_s": None,
           "errors": None, "disconnected": False, "failure": ""}
    ctx = target = page = None
    try:
        ctx = bcall("Target.createBrowserContext")["browserContextId"]
        target = bcall("Target.createTarget", url="about:blank", browserContextId=ctx)["targetId"]
        page = WS(f"/devtools/page/{target}")
        page.call("Emulation.setDeviceMetricsOverride", width=1440, height=900, deviceScaleFactor=1, mobile=False)
        page.call("Page.enable")
        js = lambda e: page.call("Runtime.evaluate", expression=e, returnByValue=True,
                                 awaitPromise=True).get("result", {}).get("value")

        def wait(expr, what):
            t = time.time()
            while time.time() - t < STEP_TIMEOUT_S:
                if js(expr): return time.time() - t
                if js(DISCONNECTED) and what != "connect":
                    row["disconnected"] = True; raise RuntimeError(f"disconnected while waiting for {what}")
                time.sleep(POLL_S)
            raise TimeoutError(f"{what} not done in {STEP_TIMEOUT_S} s")

        t0_barrier.wait()                                  # every student starts together
        page.call("Page.navigate", url=app_url)
        row["connect_s"] = wait(CONNECTED, "connect")
        row["first_plot_s"] = row["connect_s"] + wait(FIRST_PLOT, "first plot")
        js("document.querySelector('a[data-value=\"Futures\"]').click(); true")
        wait("(function(){var a=document.querySelector('a[data-value=\"Pulse lab\"]'); return !!a && a.offsetParent!==null;})()",
             "pulse pill")
        js("document.querySelector('a[data-value=\"Pulse lab\"]').click(); true")
        wait("(function(){var b=document.getElementById('p_go'); return !!b && b.offsetParent!==null;})()", "pulse button")
        js("document.getElementById('p_go').click(); true")
        row["pulse_s"] = wait(PULSE_READY, "pulse partition")
        js("[...document.querySelectorAll('.navbar a')].find(x=>x.textContent.trim()==='Known issues').click(); true")
        row["known_issues_s"] = wait(KI_READY, "known issues plots")
        row["errors"] = js(ERRORS)
    except Exception as e:                                  # recorded, never raised: one student failing is a result
        row["failure"] = f"{type(e).__name__}: {e}"[:200]
        try: row["errors"] = js(ERRORS)
        except Exception: pass
    finally:
        if page: page.close()
        try:
            if target: bcall("Target.closeTarget", targetId=target)
            if ctx: bcall("Target.disposeBrowserContext", browserContextId=ctx)
        except Exception: pass
        rows.append(row)


def run_step(n, rows):
    bar = threading.Barrier(n)
    th = [threading.Thread(target=student, args=(k + 1, n, bar, rows)) for k in range(n)]
    t = time.time()
    for x in th: x.start()
    for x in th: x.join()
    return time.time() - t


all_rows = []
print(f"{time.strftime('%Y-%m-%d %H:%M:%S')} target {app_url}", flush=True)
warm = []; run_step(1, warm)
print(f"warm-up (not scored): {warm[0]}", flush=True)
for n in NS:
    time.sleep(PAUSE_BETWEEN_N_S)
    rows = []; wall = run_step(n, rows)
    for r in rows: r["step_wall_s"] = round(wall, 1)
    all_rows += rows
    ok = [r for r in rows if not r["failure"]]
    q = lambda k: sorted(r[k] for r in ok if r[k] is not None)
    med = lambda v: v[len(v) // 2] if v else float("nan")
    print(f"N={n:3d}: ok {len(ok)}/{n}; first plot median {med(q('first_plot_s')):.1f} max {max(q('first_plot_s') or [float('nan')]):.1f} s;"
          f" pulse median {med(q('pulse_s')):.1f} max {max(q('pulse_s') or [float('nan')]):.1f} s;"
          f" known issues median {med(q('known_issues_s')):.1f} max {max(q('known_issues_s') or [float('nan')]):.1f} s;"
          f" disconnects {sum(r['disconnected'] for r in rows)}; wall {wall:.0f} s", flush=True)
    for r in rows:
        if r["failure"]: print(f"   vu {r['vu']}: {r['failure']}", flush=True)

with open(out_csv, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["n", "vu", "connect_s", "first_plot_s", "pulse_s", "known_issues_s", "errors",
                                      "disconnected", "failure", "step_wall_s"])
    w.writeheader()
    for r in sorted(all_rows, key=lambda r: (r["n"], r["vu"])):
        w.writerow({k: (round(v, 2) if isinstance(v, float) else v) for k, v in r.items()})
print(f"wrote {out_csv}", flush=True)
