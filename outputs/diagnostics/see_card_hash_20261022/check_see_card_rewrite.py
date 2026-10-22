"""Headless check of the see-card pointer under the live host's href rewrite (CHANGELOG 2026-10-22 c, e).
Connect Cloud's shiny-server-client binds a click handler on `body` that, for a link without `data-toggle`,
writes the resolved href (full page URL, query and hash kept) back into `href` before our `document`-delegated
handler runs. Locally there is no such script, so this check injects a stand-in with the same effect and runs
four arms on a fresh page each:
  A  served handler, no rewrite      (control)          must pass
  B  served handler, rewrite         (the fix)          must pass
  C  pre-fix handler, rewrite        (mutation)         must FAIL
  D  pre-fix handler, no rewrite     (mutation control) must pass
Pass = the Known issues tab is active and card 1's top is within 2 px of the viewport top, 2.5 s after the click.
The CDP client is copied from outputs/diagnostics/scan_items_20261021/check_scan_ui.py.
Usage: python3 -I check_see_card_rewrite.py <debug_port> <app_url> <W> <H>"""
import sys, json, time, socket, base64, os, struct, urllib.request

port, app_url = int(sys.argv[1]), sys.argv[2]; W_, H_ = int(sys.argv[3]), int(sys.argv[4])
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
# the pre-fix handler (app/ui.R at 3f8256b9)
OLD_HANDLER = """
  $(document).on('click', 'a.ccx-see-card', function (e) {
    var card = document.getElementById(this.getAttribute('href').slice(1));
    if (!card) return;
    e.preventDefault();
    var pane = card.closest('.tab-pane');
    var link = pane && Array.prototype.find.call(document.querySelectorAll('.navbar a[data-bs-toggle=tab]'),
      function (a) { return a.getAttribute('href') === '#' + pane.id; });
    var go = function () { card.scrollIntoView({block: 'start'}); };
    if (!link || link.classList.contains('active')) { go(); return; }
    $(link).one('shown.bs.tab', function () { setTimeout(go, 0); });
    link.click();
  });"""
# stand-in for the host's fixupUrl: full resolved URL, query and hash kept, links with data-toggle skipped
REWRITE = """jQuery('body').on('click', 'a', function () {
  if (!this.hasAttribute('data-toggle')) this.href = location.origin + location.pathname + location.search + this.hash; });"""
ARMS = [("A", False, False, True), ("B", False, True, True), ("C", True, True, False), ("D", True, False, True)]

call("Page.enable")
call("Emulation.setDeviceMetricsOverride", width=W_, height=H_, deviceScaleFactor=1, mobile=False)
all_ok = True
for name, old, rewrite, expect in ARMS:
    call("Page.navigate", url=app_url)
    time.sleep(1.0)
    wait_for(CONNECTED, what="shiny connect")
    time.sleep(4)
    if old:
        js("$(document).off('click', 'a.ccx-see-card'); " + OLD_HANDLER + "; true")
    if rewrite:
        js(REWRITE + "; true")
    pre = js("document.querySelector('a.ccx-see-card').getAttribute('href')")
    js("document.querySelector('a.ccx-see-card').click(); true")
    time.sleep(2.5)
    r = js("({active: document.querySelector('.navbar a.active').textContent.trim(), scrollY: Math.round(window.scrollY),"
           " cardTop: Math.round(document.getElementById('issue-1').getBoundingClientRect().top),"
           " href: document.querySelector('a.ccx-see-card').getAttribute('href'),"
           " handlers: (jQuery._data(document, 'events').click || []).filter(h => h.selector === 'a.ccx-see-card').length})")
    passed = r["active"] == "Known issues" and abs(r["cardTop"]) <= 2
    ok = passed == expect
    all_ok &= ok
    print(f"arm {name} old_handler={old} rewrite={rewrite}: href before {pre!r} after {r['href']!r}; "
          f"active {r['active']!r}, scrollY {r['scrollY']}, cardTop {r['cardTop']}, handlers {r['handlers']} -> "
          f"{'pass' if passed else 'FAIL'} (expected {'pass' if expect else 'FAIL'}) {'OK' if ok else 'WRONG'}")
print("ALL ARMS AS EXPECTED" if all_ok else "CHECK FAILED")
sys.exit(0 if all_ok else 1)
