"""Seconds from a tab click until every visible chart in it has drawn, on a fresh page (CHANGELOG 2026-11-02 c).
check_live_pointer.py uses fixed waits (4 s + 3 or 6 s); this times each tab and sub-tab instead, up to LIMIT_S,
and records whether the page is still connected. Futures -> Build your own is skipped (it waits for "Run it").
CDP client copied from check_live_pointer.py.
Usage: python3 -I time_tab_draws.py <debug_port> <app_url> <W> <H>"""
import sys, json, time, socket, base64, os, struct, urllib.request
port = int(sys.argv[1])

targets = json.load(urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list"))
page = next(t for t in targets if t["type"] == "page")
ws_path = page["webSocketDebuggerUrl"].split(f":{port}", 1)[1]

s = socket.create_connection(("127.0.0.1", port))
key = base64.b64encode(os.urandom(16)).decode()
s.sendall((f"GET {ws_path} HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nUpgrade: websocket\r\n"
           f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
buf = b""
while b"\r\n\r\n" not in buf:
    buf += s.recv(4096)
buf = buf.split(b"\r\n\r\n", 1)[1]

def recv_exact(n):
    global buf
    while len(buf) < n:
        chunk = s.recv(1 << 20)
        if not chunk: raise EOFError
        buf += chunk
    d, buf = buf[:n], buf[n:]
    return d

def send(obj):
    data = json.dumps(obj).encode()
    hdr = bytes([0x81])
    n = len(data)
    if n < 126: hdr += bytes([0x80 | n])
    elif n < 65536: hdr += bytes([0x80 | 126]) + struct.pack(">H", n)
    else: hdr += bytes([0x80 | 127]) + struct.pack(">Q", n)
    mask = os.urandom(4)
    s.sendall(hdr + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

def recv_msg():
    payload = b""
    while True:
        b0, b1 = recv_exact(2)
        n = b1 & 0x7F
        if n == 126: n = struct.unpack(">H", recv_exact(2))[0]
        elif n == 127: n = struct.unpack(">Q", recv_exact(8))[0]
        payload += recv_exact(n)
        if b0 & 0x80: return json.loads(payload)

_id = [0]
def call(method, **params):
    _id[0] += 1; i = _id[0]
    send({"id": i, "method": method, "params": params})
    while True:
        m = recv_msg()
        if m.get("id") == i:
            if "error" in m: raise RuntimeError(f"{method}: {m['error']}")
            return m.get("result", {})

def js(expr):
    r = call("Runtime.evaluate", expression=expr, returnByValue=True, awaitPromise=True)
    return r.get("result", {}).get("value")

def wait_for(expr, timeout=120, what=""):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if js(expr): return time.time() - t0
        time.sleep(0.5)
    raise TimeoutError(what or expr)

def shot(name):
    png = base64.b64decode(call("Page.captureScreenshot", format="png")["data"])
    open(f"{out}_{name}.png", "wb").write(png); print("saved", f"{out}_{name}.png", len(png), "bytes")


app_url =  sys.argv[2]; W_, H_ = int(sys.argv[3]), int(sys.argv[4])
LIMIT_S = 90
SKIP = {"Build your own"}
CONNECTED = "!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())"
call("Page.enable")
call("Emulation.setDeviceMetricsOverride", width=W_, height=H_, deviceScaleFactor=1, mobile=False)
t0 = time.time(); call("Page.navigate", url=app_url); time.sleep(1.0)
print(f"connect {wait_for(CONNECTED, what='shiny connect') + 1.0:.1f} s after navigate", flush=True)
STATE = """(() => { const pane = document.querySelector(%s);
  const vis = Array.from(pane.querySelectorAll('.shiny-plot-output')).filter(e => e.offsetParent !== null);
  const drawn = vis.filter(e => e.querySelector('img'));
  const errs = Array.from(pane.querySelectorAll('.shiny-output-error')).filter(e => e.offsetParent !== null && e.textContent.trim().length);
  return {plots: vis.length, drawn: drawn.length, errors: errs.length, busy: document.documentElement.classList.contains('shiny-busy'),
          connected: !!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())}; })()"""
def timed(pane_sel, label):
    t = time.time(); x = None
    while time.time() - t < LIMIT_S:
        x = js(STATE % json.dumps(pane_sel))
        if x["plots"] and x["drawn"] == x["plots"]: break
        if not x["connected"]: break
        time.sleep(0.25)
    dt = time.time() - t
    good = bool(x["plots"]) and x["drawn"] == x["plots"] and not x["errors"] and x["connected"]
    print(f"  {label}: {x['drawn']}/{x['plots']} drawn after {dt:.1f} s, errors {x['errors']}, connected {x['connected']} -> {'OK' if good else 'FAIL'}", flush=True)
    return good
ok = True
navs = js("Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).map(a => [a.textContent.trim(), a.getAttribute('href')])")
for t, href in navs:
    js(f"Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).find(a => a.getAttribute('href') === {json.dumps(href)}).click()")
    subs = js(f"Array.from(document.querySelector({json.dumps(href)}).querySelectorAll('a[data-bs-toggle=tab], a[data-bs-toggle=pill]')).map(a => a.textContent.trim())")
    if not subs:
        ok &= timed(href, t); continue
    for k, sub in enumerate(subs):
        if sub in SKIP: print(f"  {t} / {sub}: skipped (waits for its button)"); continue
        js(f"document.querySelector({json.dumps(href)}).querySelectorAll('a[data-bs-toggle=tab], a[data-bs-toggle=pill]')[{k}].click()")
        ok &= timed(href, f"{t} / {sub}")
print(f"total {time.time() - t0:.0f} s; " + ("ALL OK" if ok else "CHECK FAILED"))
