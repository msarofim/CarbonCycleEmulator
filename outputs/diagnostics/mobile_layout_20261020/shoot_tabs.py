"""Visit every tab of a running CarboTope at WxH, wait for its plots, save the first screen and measure the layout.

Minimal Chrome DevTools client, stdlib only (the transport is shoot_app.py's from pulse_ocean_depth_20261016/).
Start Chrome first:  "Google Chrome" --headless=new --remote-debugging-port=<p> --user-data-dir=<tmp>

Usage: shoot_tabs.py <debug_port> <app_url> <out_dir> <tag> <W> <H> [--mobile] [--plots <dir>] [--full <dir>] [--extras]
  --mobile   emulate a phone (touch, mobile viewport); used for the 375 px runs
  --extras   then the charts that only appear after a click: the pulse lab's partition (Futures -> Pulse lab ->
             Release the pulse, defaults) and a What-if driver chart (El Nino / La Nina switched off alone)
  --plots    also write every drawn plot's PNG (the image Shiny sent) to <dir>, for the clipping check
  --full     also write a full-page screenshot per tab to <dir>
Writes <out_dir>/<tag>_<W>x<H>_<n>_<slug>.png (the first screen) and appends one JSON line per tab to
<out_dir>/<tag>_<W>x<H>_layout.jsonl.
"""
import sys, json, time, socket, base64, os, re, struct, urllib.request

args = sys.argv[1:]
flag = lambda f: (f in args) and (args.remove(f) or True)
def opt(f):
    if f in args:
        i = args.index(f); v = args[i + 1]; del args[i:i + 2]; return v
    return None
MOBILE = flag("--mobile"); EXTRAS = flag("--extras"); PLOTS = opt("--plots"); FULL = opt("--full")
port, app_url, out_dir, tag = int(args[0]), args[1], args[2], args[3]
W_, H_ = int(args[4]), int(args[5])
for d in (out_dir, PLOTS, FULL):
    if d: os.makedirs(d, exist_ok=True)

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
    hdr = bytes([0x81]); n = len(data)
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
    if "exceptionDetails" in r: raise RuntimeError(json.dumps(r["exceptionDetails"])[:500])
    return r.get("result", {}).get("value")

def wait_for(expr, timeout=120, what=""):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if js(expr): return time.time() - t0
        time.sleep(0.5)
    raise TimeoutError(what or expr)

# The active pane is found from the NAVBAR's active link: the Futures pills nest their own
# .tab-content > .tab-pane.active, which precedes later tabs in document order.
# Every visible plot in the active tab has an image and nothing is recalculating -- held for 1.5 s, because a
# uiOutput (the imbalance and regrowth panels) inserts its plotOutput only after its own render.
SETTLED = """(function(){
  var a = document.querySelector('.navbar .nav-link.active[data-bs-toggle=tab]');
  var p = a && document.querySelector(a.getAttribute('href')); if (!p) return false;
  if (document.documentElement.classList.contains('shiny-busy')) return false;
  // a hidden output (the pulse lab's, under conditionalPanel) stays .recalculating until shown
  if (Array.from(p.querySelectorAll('.recalculating')).some(function(e){ return e.offsetParent !== null; })) return false;
  var ps = Array.from(p.querySelectorAll('.shiny-plot-output')).filter(function(o){ return o.offsetParent !== null; });
  return ps.every(function(o){ var i = o.querySelector('img'); return i && i.naturalWidth > 0; });
})()"""

MEASURE = """(function(){
  var a = document.querySelector('.navbar .nav-link.active[data-bs-toggle=tab]');
  var p = document.querySelector(a.getAttribute('href'));
  var top = function(e){ return e ? Math.round(e.getBoundingClientRect().top + window.scrollY) : null; };
  var nav = document.querySelector('.navbar');
  var vis = function(e){ return e.offsetParent !== null; };
  var plots = Array.from(p.querySelectorAll('.shiny-plot-output')).filter(vis).map(function(o){
    var i = o.querySelector('img'), r = o.getBoundingClientRect();
    return {id: o.id, top: Math.round(r.top + window.scrollY), w: Math.round(r.width), h: Math.round(r.height),
            img: i ? [i.naturalWidth, i.naturalHeight] : null};
  });
  var tk = Array.from(p.querySelectorAll('.takeaway')).filter(vis)[0];
  var ctl = Array.from(p.querySelectorAll('.well')).filter(vis)[0];
  var vw = document.documentElement.clientWidth;
  var wide = Array.from(document.querySelectorAll('body *')).filter(function(e){
    if (!vis(e)) return false; var r = e.getBoundingClientRect(); return r.width > 0 && r.right > vw + 1; })
    .slice(0, 8).map(function(e){ return e.tagName + (e.id ? '#' + e.id : '') + '.' + (e.className || '').toString().slice(0, 40)
      + ' right=' + Math.round(e.getBoundingClientRect().right); });
  return {vw: window.innerWidth, vh: window.innerHeight, client_w: vw,
          scroll_w: document.documentElement.scrollWidth, doc_h: document.documentElement.scrollHeight,
          nav_h: Math.round(nav.getBoundingClientRect().height), takeaway_top: top(tk),
          first_plot_top: plots.length ? plots[0].top : null, controls_top: top(ctl), plots: plots,
          wider_than_viewport: wide,
          errors: Array.from(p.querySelectorAll('.shiny-output-error')).filter(function(e){
            return !e.classList.contains('shiny-output-error-validation'); })
            .map(function(e){ return e.id + ': ' + e.textContent.slice(0, 160); })};
})()"""

def shot(path, full=False):
    if full:
        h = js("document.documentElement.scrollHeight")
        png = call("Page.captureScreenshot", format="png", captureBeyondViewport=True,
                   clip={"x": 0, "y": 0, "width": W_, "height": h, "scale": 1})["data"]
    else:
        png = call("Page.captureScreenshot", format="png")["data"]
    open(path, "wb").write(base64.b64decode(png))

call("Emulation.setDeviceMetricsOverride", width=W_, height=H_, deviceScaleFactor=1, mobile=MOBILE)
if MOBILE: call("Emulation.setTouchEmulationEnabled", enabled=True, maxTouchPoints=5)
call("Page.enable")
call("Page.navigate", url=app_url)
print("connected after %.1f s" % wait_for("!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())",
                                           what="shiny connect"))
wait_for(SETTLED, what="first tab")
tabs = js("Array.from(document.querySelectorAll('.navbar .nav-link[data-bs-toggle=tab]')).map(a => a.dataset.value)")
log = open(os.path.join(out_dir, f"{tag}_{W_}x{H_}_layout.jsonl"), "w")
for n, tab in enumerate(tabs, 1):
    # A phone gets the navbar's <select> when it is the visible control; otherwise the tab's own link is clicked.
    used = js("""(function(v){
      var sel = document.getElementById('ccx-tab-select');
      if (sel && sel.offsetParent !== null) { sel.value = v; sel.dispatchEvent(new Event('change', {bubbles: true})); return 'select'; }
      document.querySelector('.navbar .nav-link[data-value="' + v.replace(/"/g, '\\\\"') + '"]').click(); return 'link';
    })(%s)""" % json.dumps(tab))
    time.sleep(1.0)
    t = 0.0
    try:
        t0 = time.time(); stable = None
        while True:
            if time.time() - t0 > 120: raise TimeoutError(tab)
            if js(SETTLED):
                stable = stable or time.time()
                if time.time() - stable >= 1.5: break
            else: stable = None
            time.sleep(0.25)
        t = time.time() - t0
    except TimeoutError:
        print("  TIMEOUT waiting for plots on", tab)
    js("window.scrollTo(0, 0); true"); time.sleep(0.4)
    slug = re.sub(r"[^a-z0-9]+", "_", tab.lower()).strip("_")[:28]
    base = f"{tag}_{W_}x{H_}_{n}_{slug}"
    shot(os.path.join(out_dir, base + ".png"))
    m = js(MEASURE); m.update(tab=tab, nav_used=used, settle_s=round(t, 1), width=W_, height=H_, tag=tag)
    if FULL: shot(os.path.join(FULL, base + "_full.png"), full=True)
    if PLOTS:
        srcs = js("""Array.from(document.querySelector(document.querySelector('.navbar .nav-link.active[data-bs-toggle=tab]')
          .getAttribute('href')).querySelectorAll('.shiny-plot-output'))
          .filter(o => o.offsetParent !== null && o.querySelector('img')).map(o => [o.id, o.querySelector('img').src])""")
        for pid, src in srcs:
            if src.startswith("data:image/png;base64,"):
                open(os.path.join(PLOTS, f"{tag}_{W_}_{pid}.png"), "wb").write(base64.b64decode(src.split(",", 1)[1]))
    log.write(json.dumps(m) + "\n"); log.flush()
    print(f"{n} {tab!r:32} via {used:6} settle {t:5.1f}s  nav {m['nav_h']:4}  takeaway {m['takeaway_top']}  "
          f"plot {m['first_plot_top']}  controls {m['controls_top']}  scrollW {m['scroll_w']}/{m['client_w']}  "
          f"plots {sum(1 for p in m['plots'] if p['img'])}/{len(m['plots'])}  errors {len(m['errors'])}")
log.close()

def open_tab(v):
    js("""(function(v){
      var sel = document.getElementById('ccx-tab-select');
      if (sel && sel.offsetParent !== null) { sel.value = v; sel.dispatchEvent(new Event('change', {bubbles: true})); return; }
      document.querySelector('.navbar .nav-link[data-value="' + v + '"]').click(); })(%s)""" % json.dumps(v))
    time.sleep(1.5)

def drawn(oid, timeout=120):
    return wait_for("""(function(){var o=document.getElementById(%s); if(!o) return false; var i=o.querySelector('img');
      return !!i && i.naturalWidth>0 && !o.classList.contains('recalculating')
             && !document.documentElement.classList.contains('shiny-busy');})()""" % json.dumps(oid), timeout, oid)

def extra(oid, name):
    time.sleep(1.5)
    js("var o=document.getElementById(%s); window.scrollTo(0, o.getBoundingClientRect().top + window.scrollY - 70); true"
       % json.dumps(oid)); time.sleep(0.6)
    shot(os.path.join(out_dir, f"{tag}_{W_}x{H_}_extra_{name}.png"))
    m = js(MEASURE); m.update(tab=name, extra_plot=oid, width=W_, height=H_, tag=tag)
    if PLOTS:
        src = js("document.querySelector('#%s img').src" % oid)
        open(os.path.join(PLOTS, f"{tag}_{W_}_{oid}.png"), "wb").write(base64.b64decode(src.split(",", 1)[1]))
    with open(os.path.join(out_dir, f"{tag}_{W_}x{H_}_layout.jsonl"), "a") as fh: fh.write(json.dumps(m) + "\n")
    print(f"extra {name}: {oid} drawn, scrollW {m['scroll_w']}/{m['client_w']}, errors {len(m['errors'])}")

if EXTRAS:
    open_tab("Futures")
    js("document.querySelector('a[data-value=Pulse\\\\ lab]').click(); true"); time.sleep(1.5)
    js("document.getElementById('p_go').click(); true")
    drawn("f_partition"); extra("f_partition", "pulse_partition")
    open_tab("What if\u2026?")
    js("""(function(){ Array.from(document.querySelectorAll('#c_mech input[type=checkbox]')).forEach(function(b){
            if (b.checked !== (b.value === 'enso')) b.click(); }); return true; })()""")
    drawn("c_driver_enso"); extra("c_driver_enso", "whatif_driver_enso")
