"""Save the PNG each named plot output was sent (its own image, not a page clip; 2026-11-11)\nCapture named plot outputs of a running CarboTope at a given viewport (2026-11-11, axis-title / caption overlap).
Usage: python3 -I shoot_plots.py <port> <app_url> <W> <H> <out_prefix> <tab label>:<output id> [...]"""
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
app_url, W_, H_, out = sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
call("Page.enable")
call("Emulation.setDeviceMetricsOverride", width=W_, height=H_, deviceScaleFactor=1, mobile=False)
call("Page.navigate", url=app_url); time.sleep(1.0)
wait_for("!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())", what="connect")
for spec in sys.argv[6:]:
    tab, oid = spec.split(":")
    js(f"""Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).find(a => a.textContent.trim() === {json.dumps(tab)}).click()""")
    wait_for(f"!!document.querySelector('#{oid} img') && document.querySelector('#{oid} img').complete", timeout=90, what=oid)
    time.sleep(1.5)
    uri = js(f"document.querySelector('#{oid} img').src")
    w = js(f"document.querySelector('#{oid} img').naturalWidth"); h = js(f"document.querySelector('#{oid} img').naturalHeight")
    f = f"{out}_{oid}_{W_}x{H_}_img.png"; open(f, "wb").write(base64.b64decode(uri.split(",", 1)[1])); print("saved", f, w, "x", h)
