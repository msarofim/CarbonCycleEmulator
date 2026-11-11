"""The width the box diagram is drawn at, for a list of viewport widths (2026-11-11, diagram font fix).
Usage: python3 -I diagram_widths.py <debug_port> <app_url> <W> [W ...]   (viewport height 900; phone emulation below 576)"""
import sys, json, time, socket, base64, os, struct, urllib.request
port, app_url = int(sys.argv[1]), sys.argv[2]; widths = [int(w) for w in sys.argv[3:]]
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
call("Page.enable")
for W in widths:
    call("Emulation.setDeviceMetricsOverride", width=W, height=900, deviceScaleFactor=1, mobile=W < 576)
    call("Page.navigate", url=app_url); time.sleep(1.0); wait_for(CONNECTED, what="shiny connect"); time.sleep(2)
    r = js("""(async () => {
      const nav = Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).find(a => a.textContent.trim() === 'Under the hood');
      if (nav.offsetParent === null) { const sel = document.getElementById('ccx-tab-select'); sel.value = sel.querySelector('option[value]') && Array.from(sel.options).find(o => /hood/i.test(o.text)).value; sel.dispatchEvent(new Event('change')); } else nav.click();
      for (let i = 0; i < 60; i++) { await new Promise(r => setTimeout(r, 500)); const im = document.querySelector('#h_diagram img'); if (im && im.naturalWidth) break; }
      const el = document.getElementById('h_diagram'), im = el.querySelector('img'), box = el.parentElement;
      return {output_px: el.getBoundingClientRect().width, img: im ? [im.naturalWidth, im.naturalHeight] : null,
              clientData: Shiny.shinyapp.$inputValues['.clientdata_output_h_diagram_width'], scroller: box.scrollWidth > box.clientWidth};
    })()""")
    print(f"viewport {W}: diagram output {r['output_px']:.0f} px, image {r['img']}, clientData {r['clientData']}, scrolls sideways {r['scroller']}")
