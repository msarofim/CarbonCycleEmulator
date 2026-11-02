"""Watch one page's Shiny connection while another CDP client drives it (CHANGELOG 2026-11-02 c). Every 0.5 s it
reads: connected, session id, the busy class, Shiny's disconnected overlay, the host's reconnect dialog, the address;
it prints a line whenever any of them changes. Run beside check_live_pointer.py on the same Chrome.
CDP client copied from check_live_pointer.py.
Usage: python3 -I monitor_session.py <debug_port> <seconds>"""
import sys, json, time, socket, base64, os, struct, urllib.request
port, DUR = int(sys.argv[1]), float(sys.argv[2])
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
STATE = """(() => { const a = window.Shiny && Shiny.shinyapp; const d = document.getElementById('ss-connect-dialog');
  return {conn: !!(a && a.isConnected()), sid: (a && a.config && a.config.sessionId || '').slice(0, 8),
          busy: document.documentElement.classList.contains('shiny-busy'),
          overlay: !!document.getElementById('shiny-disconnected-overlay'),
          ss_dialog: d ? (d.offsetParent !== null ? d.textContent.trim().slice(0, 60) : 'hidden') : null,
          tab: (document.querySelector('.navbar a.active') || {}).textContent || null,
          href: location.href.split('?')[0].slice(-40)}; })()"""
t0 = time.time(); last = None
while time.time() - t0 < DUR:
    try: x = json.dumps(js(STATE), ensure_ascii=False)
    except Exception as e: x = f"evaluate failed: {e}"
    if x != last:
        print(f"{time.strftime('%H:%M:%S', time.gmtime())} +{time.time() - t0:6.1f} s {x}", flush=True); last = x
    time.sleep(0.5)
