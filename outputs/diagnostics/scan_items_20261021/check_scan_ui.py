"""Headless check of the 2026-10-21 scan items (CHANGELOG 2026-10-21 m): the Keeling pointer opens Known issues at
card 1; Copy link copies the short address + view (clipboard stubbed); at 375 x 812 a tap on the first unit gloss
shows its meaning inline. Built on outputs/diagnostics/pulse_ocean_depth_20261016/shoot_app.py (its stdlib DevTools
client). Usage: python3 -I check_scan_ui.py <debug_port> <app_url> <out_prefix> <W> <H>
Start Chrome first: Google Chrome --headless=new --remote-debugging-port=<port> --user-data-dir=<tmp> about:blank"""
import sys, json, time, socket, base64, os, struct, urllib.request

port, app_url, out = int(sys.argv[1]), sys.argv[2], sys.argv[3]; W_, H_ = int(sys.argv[4]), int(sys.argv[5])
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

CONNECTED = "!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())"
res = {}
call("Page.enable")
# 1. desktop: Copy link, then the Keeling pointer
call("Emulation.setDeviceMetricsOverride", width=W_, height=H_, deviceScaleFactor=1, mobile=False)
call("Page.navigate", url=app_url)
wait_for(CONNECTED, what="shiny connect")
time.sleep(4)
res["share"] = js("""(async () => {
  window.__copied = null; window.prompt = (m, u) => { window.__copied = 'PROMPT ' + u; return null; };
  if (navigator.clipboard) navigator.clipboard.writeText = (u) => { window.__copied = u; return Promise.resolve(); };
  const a = [...document.querySelectorAll('a.ccx-share')].find(x => x.offsetParent !== null);
  a.click(); await new Promise(r => setTimeout(r, 300));
  return {copied: window.__copied, label: a.textContent, search: location.search};
})()""")
js("document.querySelector('a.ccx-see-card').click(); true")
time.sleep(2.5)
res["see_card"] = js("({active: document.querySelector('.navbar a.active').textContent.trim(), scrollY: Math.round(window.scrollY), cardTop: Math.round(document.getElementById('issue-1').getBoundingClientRect().top)})")
shot("desktop_after_see_card")
# 2. phone: scroll the first visible gloss into view (a separate step: the tap must land inside the viewport), tap it
call("Emulation.setDeviceMetricsOverride", width=375, height=812, deviceScaleFactor=2, mobile=True)
call("Emulation.setTouchEmulationEnabled", enabled=True)
call("Page.navigate", url=app_url)
wait_for(CONNECTED, what="shiny connect (phone)")
time.sleep(4)
GLOSS = "[...document.querySelectorAll('abbr.gloss')].find(x => x.offsetParent !== null)"
js(f"(() => {{ const a = {GLOSS}; window.scrollTo(0, a.getBoundingClientRect().top + window.scrollY - 300); return true; }})()")
time.sleep(1.0)
r = js(f"(() => {{ const b = {GLOSS}.getBoundingClientRect(); return {{x: b.left + b.width / 2, y: b.top + b.height / 2}}; }})()")
call("Input.synthesizeTapGesture", x=r["x"], y=r["y"], duration=50, gestureSourceType="touch")
time.sleep(1.0)
res["phone_gloss"] = js(f"(() => {{ const a = {GLOSS}, m = a.nextElementSibling; return {{open: a.classList.contains('gloss-open'), shown: getComputedStyle(m).display, meaning: m.textContent, sideways: document.documentElement.scrollWidth > window.innerWidth}}; }})()")
shot("phone_gloss_open")
ok = (res["share"]["copied"] or "").startswith("https://carbotope.org/?") and res["see_card"]["active"] == "Known issues" \
     and abs(res["see_card"]["cardTop"]) <= 2 and res["phone_gloss"]["shown"] == "inline" and not res["phone_gloss"]["sideways"]
print(json.dumps(res, indent=1, ensure_ascii=False)); print("ALL OK" if ok else "CHECK FAILED")
