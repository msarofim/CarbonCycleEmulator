"""Minimal Chrome DevTools client (stdlib only): open a running CarboTope at WxH, run the pulse lab with its
default settings, and save viewport screenshots. Usage: shoot_app.py <debug_port> <app_url> <out_prefix> <W> <H>"""
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

call("Emulation.setDeviceMetricsOverride", width=W_, height=H_, deviceScaleFactor=1, mobile=False)
call("Page.enable")
call("Page.navigate", url=app_url)
print("connected after %.1f s" % wait_for("!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())", what="shiny connect"))
time.sleep(3)
js("document.querySelector('a[data-value=\"Futures\"]').click(); true")
wait_for("!!document.querySelector('a[data-value=\"Pulse lab\"]') && document.querySelector('a[data-value=\"Pulse lab\"]').offsetParent !== null", what="pulse pill")
js("document.querySelector('a[data-value=\"Pulse lab\"]').click(); true")
wait_for("!!document.getElementById('p_go') && document.getElementById('p_go').offsetParent !== null", what="p_go")
time.sleep(2)
js("document.getElementById('p_go').click(); true")
print("partition drawn after %.1f s" % wait_for(
    "(function(){var o=document.getElementById('f_partition'); if(!o) return false; var i=o.querySelector('img');"
    " return !!i && i.naturalWidth>0 && !o.classList.contains('recalculating') && !document.documentElement.classList.contains('shiny-busy');})()",
    what="partition img"))
time.sleep(2)
info = js("(function(){var i=document.querySelector('#f_partition img'); var p=document.querySelector('#f_plot img');"
          " return {part:[i.naturalWidth,i.naturalHeight,i.clientWidth,i.clientHeight], main:p?[p.naturalWidth,p.naturalHeight]:null,"
          " vw:window.innerWidth, vh:window.innerHeight};})()")
print("sizes", info)
js("document.getElementById('f_plot').scrollIntoView({block:'start'}); window.scrollBy(0,-60); true"); time.sleep(1); shot("pulse_main")
js("document.getElementById('f_partition').scrollIntoView({block:'center'}); true"); time.sleep(1); shot("pulse_partition")
errs = js("Array.from(document.querySelectorAll('.shiny-output-error')).map(e=>e.id+': '+e.textContent.slice(0,200))")
print("shiny output errors:", errs)
