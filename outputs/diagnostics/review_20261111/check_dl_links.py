"""Every visible Download link works, on every tab and sub-tab (2026-11-11, review A11b).
The batch-A build (2bc18f62) hid each Download line until its chart drew (A11), and Shiny, which suspends an output it
sees as hidden, then never gave the links an address: every link stayed `disabled` with href "". This walks each tab and
sub-tab, waits for its charts, and requires of every Download line under a drawn chart that its links are visible, have
an address and are not disabled, and that the first CSV on the pane downloads with its provenance header. A Download line
under a chart that has not drawn must stay hidden (A11's purpose). CDP client copied from check_live_pointer.py.
Usage: python3 -I check_dl_links.py <debug_port> <app_url> <W> <H>"""
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
call("Page.enable")
call("Emulation.setDeviceMetricsOverride", width=W_, height=H_, deviceScaleFactor=1, mobile=W_ < 768)
call("Page.navigate", url=app_url); time.sleep(1.0); wait_for(CONNECTED, what="shiny connect"); time.sleep(3)
ok = True
navs = js("Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).map(a => a.textContent.trim())")
for t in navs:
    r = js(f"""(async () => {{
      const sleep = ms => new Promise(r => setTimeout(r, ms));
      const nav = Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).find(a => a.textContent.trim() === {json.dumps(t)});
      nav.click(); await sleep(1500);
      const pane = document.querySelector(nav.getAttribute('href'));
      const subs = Array.from(pane.querySelectorAll('a[data-bs-toggle=tab], a[data-bs-toggle=pill]'));
      const res = [];
      const settle = async () => {{   // until every chart on show has an image, or 60 s; then 1.5 s for the links
        for (let i = 0; i < 120; i++) {{
          const vis = Array.from(pane.querySelectorAll('.shiny-plot-output')).filter(e => e.offsetParent !== null);
          if (vis.length && vis.every(e => e.querySelector('img'))) break;
          await sleep(500);
        }}
        await sleep(1500);
      }};
      const count = async (label) => {{
        const plots = Array.from(pane.querySelectorAll('.shiny-plot-output')).filter(e => e.offsetParent !== null);   // on show
        const lines = plots.map(p => ({{p, dl: p.nextElementSibling && p.nextElementSibling.classList.contains('ccx-dl') ? p.nextElementSibling : null}}))
                           .filter(x => x.dl);
        const drawn = lines.filter(x => x.p.querySelector('img')), undrawn = lines.filter(x => !x.p.querySelector('img'));
        const links = drawn.flatMap(x => Array.from(x.dl.querySelectorAll('a.shiny-download-link')));
        const bad = links.filter(a => a.offsetParent === null || !a.getAttribute('href') || a.classList.contains('disabled'))
                         .map(a => a.id + (a.offsetParent === null ? ' hidden' : '') + (!a.getAttribute('href') ? ' no-href' : '') + (a.classList.contains('disabled') ? ' disabled' : ''));
        const shown_undrawn = undrawn.filter(x => x.dl.offsetParent !== null).map(x => x.p.id);
        let csv = null;
        const c = links.find(a => a.id.endsWith('_csv') && a.getAttribute('href'));
        if (c) {{ const txt = await (await fetch(c.href)).text();
                  csv = {{id: c.id, header: txt.replace(/^\\ufeff/, '').startsWith('# '), commit: (txt.split('\\n').find(l => l.includes('Code commit')) || '').slice(0, 90)}}; }}
        res.push({{label, lines: lines.length, drawn: drawn.length, links: links.length, bad, shown_undrawn, csv}});
      }};
      if (!subs.length) {{ await settle(); await count({json.dumps(t)}); }}
      for (const s of subs) {{ s.click(); await sleep(1000); await settle(); await count(s.textContent.trim()); }}
      return res;
    }})()""")
    for x in r:
        good = (not x["bad"] and not x["shown_undrawn"] and x["links"] == 2 * x["drawn"]
                and (x["drawn"] == 0 or (x["csv"] is not None and x["csv"]["header"])))
        ok &= good
        print(f"  {t} / {x['label']}: lines {x['lines']}, under drawn charts {x['drawn']}, links {x['links']}, "
              f"bad {x['bad']}, line shown under an undrawn chart {x['shown_undrawn']}, "
              f"CSV {x['csv'] and (x['csv']['id'], x['csv']['header'], x['csv']['commit'])} -> {'OK' if good else 'FAIL'}")
print("ALL OK" if ok else "CHECK FAILED")
