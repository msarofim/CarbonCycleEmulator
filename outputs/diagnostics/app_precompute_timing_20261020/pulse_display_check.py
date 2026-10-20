"""The pulse lab's display in a real browser (Marcus 2026-10-20: the default drawn with no click; "Grey out, wait
for the click" when a pulse setting changes).

Per repetition, in a fresh R process serving <app_dir>: open the app, open Futures and wait until it is idle (its
own scenario runs), then open Pulse lab and time until the partition panel is drawn WITHOUT pressing the button
(pulse_auto_s); move the pulse-size slider to NONDEFAULT_GTC
(the slider's own API, so the control shows the new value) and time until every result output carries the
`pulse-stale` class AND the note is shown (stale_s), saving a screenshot; press "Release the pulse" and time until a
new partition is drawn and nothing is grayed (pulse_nondefault_s); move the slider back to the default and time
until a new partition is drawn and nothing is grayed (back_s). Stdlib only (DevTools client from coldstart.py).

Usage:  pulse_display_check.py <chrome_port> <app_dir> <app_port> <reps> <out_csv> <screenshot_png>
Local only.
"""
import sys, json, time, socket, base64, os, struct, urllib.request, csv, subprocess

STEP_TIMEOUT_S = 120
POLL_S = 0.05
NONDEFAULT_GTC = 200
DEFAULT_GTC = 100
RESULT_IDS = ["f_takeaway", "f_plot", "f_fair_note", "f_partition", "f_pulse_permanence", "f_notes"]  # global.R
chrome_port, app_dir, app_port, reps, out_csv, shot = (int(sys.argv[1]), sys.argv[2], int(sys.argv[3]),
                                                       int(sys.argv[4]), sys.argv[5], sys.argv[6])
app_url = f"http://127.0.0.1:{app_port}/"


class WS:
    def __init__(self, path):
        self.s = socket.create_connection(("127.0.0.1", chrome_port))
        key = base64.b64encode(os.urandom(16)).decode()
        self.s.sendall((f"GET {path} HTTP/1.1\r\nHost: 127.0.0.1:{chrome_port}\r\nUpgrade: websocket\r\n"
                        f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        self.buf = b""
        while b"\r\n\r\n" not in self.buf: self.buf += self.s.recv(4096)
        self.buf = self.buf.split(b"\r\n\r\n", 1)[1]; self.i = 0

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
PART_SRC = "(function(){var o=document.getElementById('f_partition'); var i=o&&o.querySelector('img'); return i?i.src:'';})()"
DRAWN_NEW = ("(function(prev){var o=document.getElementById('f_partition'); if(!o) return false; var i=o.querySelector('img');"
             " return !!i && i.naturalWidth>0 && i.src!==prev && !o.classList.contains('recalculating')"
             " && !document.documentElement.classList.contains('shiny-busy');})")
STALE_IDS = "JSON.stringify(%s.filter(function(id){var e=document.getElementById(id); return e && e.classList.contains('pulse-stale');}))" % json.dumps(RESULT_IDS)
NOTE = "(function(){var o=document.getElementById('p_stale_note'); return o?o.textContent.trim():'';})()"
IDLE = ("(function(){return !document.documentElement.classList.contains('shiny-busy') &&"
        " [...document.querySelectorAll('.recalculating')].every(x=>x.offsetParent===null);})()")
IDLE_HOLD_S = 0.5
SLIDE = "(function(v){$('#p_gtc').data('ionRangeSlider').update({from: v}); return true;})(%d)"


def one_rep(rep, browser):
    row = {"rep": rep}
    log = open(f"{out_csv[:-4]}_rep{rep}.log", "w")
    t0 = time.time()
    r = subprocess.Popen(["Rscript", "-e", f"shiny::runApp('{app_dir}', port = {app_port}, host = '127.0.0.1', "
                          "launch.browser = FALSE)"], stdout=log, stderr=subprocess.STDOUT)
    ctx = target = page = None
    try:
        while True:
            if r.poll() is not None: raise RuntimeError("R exited before serving")
            try:
                if urllib.request.urlopen(app_url, timeout=1).status == 200: break
            except Exception: pass
            if time.time() - t0 > STEP_TIMEOUT_S: raise TimeoutError("not serving")
            time.sleep(POLL_S)
        ctx = browser.call("Target.createBrowserContext")["browserContextId"]
        target = browser.call("Target.createTarget", url="about:blank", browserContextId=ctx)["targetId"]
        page = WS(f"/devtools/page/{target}")
        page.call("Emulation.setDeviceMetricsOverride", width=1440, height=900, deviceScaleFactor=1, mobile=False)
        js = lambda e: page.call("Runtime.evaluate", expression=e, returnByValue=True,
                                 awaitPromise=True).get("result", {}).get("value")

        def wait(expr, what):
            t = time.time()
            while time.time() - t < STEP_TIMEOUT_S:
                v = js(expr)
                if v: return time.time(), v
                time.sleep(POLL_S)
            raise TimeoutError(f"{what} not done in {STEP_TIMEOUT_S} s")

        page.call("Page.navigate", url=app_url)
        wait(CONNECTED, "connect"); wait(FIRST_PLOT, "first plot")
        js("document.querySelector('a[data-value=\"Futures\"]').click(); true")
        wait("(function(){var a=document.querySelector('a[data-value=\"Pulse lab\"]'); return !!a && a.offsetParent!==null;})()", "pill")
        # the Futures tab's own scenario runs first, as coldstart.py does: idle for IDLE_HOLD_S
        ts = time.time(); calm = None
        while True:
            if js(IDLE):
                calm = calm or time.time()
                if time.time() - calm >= IDLE_HOLD_S: break
            else: calm = None
            if time.time() - ts > STEP_TIMEOUT_S: raise TimeoutError("futures tab never settled")
            time.sleep(POLL_S)
        row["futures_settle_s"] = calm - ts
        tc = time.time()
        js("document.querySelector('a[data-value=\"Pulse lab\"]').click(); true")
        row["pulse_auto_s"] = wait(f"{DRAWN_NEW}('')", "partition drawn with no click")[0] - tc
        row["stale_at_open"] = js(STALE_IDS)
        prev = js(PART_SRC)
        tc = time.time()
        js(SLIDE % NONDEFAULT_GTC)
        t1, ids = wait(f"(function(){{var s={STALE_IDS}; return JSON.parse(s).length=={len(RESULT_IDS)} && {NOTE} ? s : '';}})()",
                       "every result output grayed and the note shown")
        row["stale_s"] = t1 - tc; row["stale_ids"] = ids; row["note"] = js(NOTE)
        row["partition_unchanged_while_stale"] = js(PART_SRC) == prev
        if rep == 1:
            png = page.call("Page.captureScreenshot", format="png")["data"]
            open(shot, "wb").write(base64.b64decode(png))
        prev = js(PART_SRC); tc = time.time()
        js("document.getElementById('p_go').click(); true")
        row["pulse_nondefault_s"] = wait(f"{DRAWN_NEW}({json.dumps(prev)})", "non-default pulse")[0] - tc
        time.sleep(0.3)
        row["stale_after_click"] = js(STALE_IDS); row["note_after_click"] = js(NOTE)
        prev = js(PART_SRC); tc = time.time()
        js(SLIDE % DEFAULT_GTC)
        row["back_s"] = wait(f"{DRAWN_NEW}({json.dumps(prev)})", "default shown again")[0] - tc
        time.sleep(0.3)
        row["stale_after_back"] = js(STALE_IDS)
        row["errors"] = js("document.querySelectorAll('.shiny-output-error:not(.shiny-output-error-validation)').length")
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
    row = one_rep(k, browser); rows.append(row)
    print({a: (round(b, 2) if isinstance(b, float) else b) for a, b in row.items()}, flush=True)
    time.sleep(2)
fields = ["rep", "futures_settle_s", "pulse_auto_s", "stale_at_open", "stale_s", "stale_ids", "note", "partition_unchanged_while_stale",
          "pulse_nondefault_s", "stale_after_click", "note_after_click", "back_s", "stale_after_back", "errors", "failure"]
with open(out_csv, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore"); w.writeheader()
    for r in rows: w.writerow({a: (round(b, 3) if isinstance(b, float) else b) for a, b in r.items()})
print(f"wrote {out_csv}", flush=True)
