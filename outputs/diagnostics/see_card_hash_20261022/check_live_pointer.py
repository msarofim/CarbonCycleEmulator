"""Live checks after the see-card fix (CHANGELOG 2026-10-22 h): on the host itself, both Known-issue pointers
open their card while the host's real rewrite fires; the handler served is the fixed one; a CSV carries the
deployed commit; every tab draws its plots with no output errors. CDP client copied from check_see_card_rewrite.py.
Usage: python3 -I check_live_pointer.py <debug_port> <app_url> <W> <H> <expected_commit7>"""
import sys, json, time, socket, base64, os, struct, urllib.request

port, app_url = int(sys.argv[1]), sys.argv[2]; W_, H_ = int(sys.argv[3]), int(sys.argv[4]); COMMIT = sys.argv[5]
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
call("Emulation.setDeviceMetricsOverride", width=W_, height=H_, deviceScaleFactor=1, mobile=False)
def fresh():
    call("Page.navigate", url=app_url); time.sleep(1.0); wait_for(CONNECTED, what="shiny connect"); time.sleep(5)
ok = True
# 1-2. each pointer on a fresh page, from its own tab
fresh()
ptrs = js("Array.from(document.querySelectorAll('a.ccx-see-card')).map(a => a.getAttribute('href'))")
served = js("Array.from(document.scripts).some(s => s.textContent.includes('getElementById(this.hash.slice(1))'))")
old = js("Array.from(document.scripts).some(s => s.textContent.includes(\"getAttribute('href').slice(1)\"))")
base = js("(document.querySelector('base') || {}).href || null")
print(f"pointers {ptrs}; fixed handler served {served}; pre-fix line served {old}; <base> {base}")
ok &= bool(served) and not old
for k, h in enumerate(ptrs):
    if k: fresh()
    r = js(f"""(async () => {{
      const a = document.querySelectorAll('a.ccx-see-card')[{k}];
      const pane = a.closest('.tab-pane');
      const nav = Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).find(l => l.getAttribute('href') === '#' + pane.id);
      if (!nav.classList.contains('active')) {{ nav.click(); await new Promise(r => setTimeout(r, 2500)); }}
      a.scrollIntoView({{block: 'center'}}); await new Promise(r => setTimeout(r, 300));
      const before = a.getAttribute('href');
      a.click(); await new Promise(r => setTimeout(r, 2500));
      const card = document.getElementById(before.slice(1));
      return {{from: nav.textContent.trim(), before, after: a.getAttribute('href'),
               active: document.querySelector('.navbar a.active').textContent.trim(),
               cardTop: Math.round(card.getBoundingClientRect().top)}};
    }})()""")
    rewritten = r["after"] != r["before"] and r["after"].endswith(r["before"])
    good = r["active"] == "Known issues" and abs(r["cardTop"]) <= 2
    ok &= good
    print(f"pointer {k + 1} ({r['before']} from '{r['from']}'): host rewrote href: {rewritten} ({r['after'][:60]}...); "
          f"active '{r['active']}', card top {r['cardTop']} -> {'OK' if good else 'FAIL'}")
# 3. a CSV's commit stamp
fresh()
csv = js("""(async () => { const a = document.querySelector('a.shiny-download-link[href]');
  if (!a) return null; const t = await (await fetch(a.href)).text(); return {id: a.id, line: (t.split('\\n').find(l => l.includes('Code commit')) || '').slice(0, 160)}; })()""")
stamp = bool(csv) and COMMIT in csv["line"]
ok &= stamp
print(f"CSV {csv and csv['id']}: {csv and csv['line']!r} -> {'OK' if stamp else 'FAIL'}")
# 4. every tab and sub-tab draws
navs = js("Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).map(a => a.textContent.trim())")
for t in navs:
    r = js(f"""(async () => {{
      const nav = Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).find(a => a.textContent.trim() === {json.dumps(t)});
      nav.click(); await new Promise(r => setTimeout(r, 4000));
      const pane = document.querySelector(nav.getAttribute('href'));
      const subs = Array.from(pane.querySelectorAll('a[data-bs-toggle=tab], a[data-bs-toggle=pill]'));
      const res = [];
      const count = (label) => {{
        const vis = Array.from(pane.querySelectorAll('.shiny-plot-output')).filter(e => e.offsetParent !== null);
        const drawn = vis.filter(e => e.querySelector('img'));
        const alt = drawn.filter(e => (e.querySelector('img').getAttribute('alt') || '').length > 0);
        const errs = Array.from(pane.querySelectorAll('.shiny-output-error')).filter(e => e.offsetParent !== null && e.textContent.trim().length);
        res.push({{label, plots: vis.length, drawn: drawn.length, alt: alt.length, errors: errs.map(e => e.textContent.trim().slice(0, 80))}});
      }};
      if (!subs.length) {{ await new Promise(r => setTimeout(r, 3000)); count({json.dumps(t)}); }}
      for (const s of subs) {{ s.click(); await new Promise(r => setTimeout(r, 6000)); count(s.textContent.trim()); }}
      return res;
    }})()""")
    for x in r:
        good = x["plots"] == x["drawn"] == x["alt"] and not x["errors"]
        ok &= good
        print(f"  {t} / {x['label']}: {x['drawn']}/{x['plots']} drawn, alt {x['alt']}, errors {x['errors']} -> {'OK' if good else 'FAIL'}")
print("ALL OK" if ok else "CHECK FAILED")
