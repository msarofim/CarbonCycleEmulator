"""Drive a running CarboTope through a list of actions in headless Chrome and save screenshots (group B sheet, 2026-11-11).

Usage: python3 -I cdp_shoot.py <cdp_port> <app_url> <W> <H> <mobile 0|1> <out_dir> <actions.json>

actions.json is a list of steps, run in order:
  {"url": "?_inputs_&tabs=..."}      load a bookmark URL: sets the widgets themselves (setInputValue does not move them)
  {"tab": "Futures"}                 click a navbar tab by its label (on a phone the select menu is set instead)
  {"pill": "Pulse lab"}              click a pill by its label
  {"set": {"input_id": value}}       Shiny.setInputValue for each pair
  {"click": "#p_go"}                 click a CSS selector
  {"wait": 3000}                     milliseconds
  {"waitimg": "#f_plot"}             wait until that output's <img> has loaded
  {"scroll": "#f_plot", "block": "start"|"center"|"end"}   scrollIntoView, or {"scrolly": 0} for an absolute scroll
  {"shot": "name"}                   the viewport
  {"shot": "name", "el": "#id", "pad": 8}   one element's box (page coordinates), padded
  {"shot": "name", "full": true}     the whole page
  {"js": "expression", "as": "key"}  evaluate; the value is printed and saved in <out_dir>/values.json under key
The Chrome is the caller's: start one per job, kill it by PID.
"""
import sys, json, time, socket, base64, os, struct, urllib.request

port, app_url = int(sys.argv[1]), sys.argv[2]
W, H, mobile, out_dir = int(sys.argv[3]), int(sys.argv[4]), sys.argv[5] == "1", sys.argv[6]
steps = json.load(open(sys.argv[7]))
os.makedirs(out_dir, exist_ok=True)

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
        b0, b1 = recv_exact(2); n = b1 & 0x7F
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
    if "exceptionDetails" in r: raise RuntimeError(f"js: {expr[:80]}: {r['exceptionDetails'].get('text')}")
    return r.get("result", {}).get("value")

def wait_for(expr, timeout=120, what=""):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if js(expr): return
        time.sleep(0.4)
    raise TimeoutError(what or expr)

def save_png(name, data):
    f = os.path.join(out_dir, f"{name}.png"); open(f, "wb").write(base64.b64decode(data)); print("saved", f)

call("Page.enable")
call("Emulation.setDeviceMetricsOverride", width=W, height=H, deviceScaleFactor=1, mobile=mobile)
if mobile: call("Emulation.setTouchEmulationEnabled", enabled=True, maxTouchPoints=5)
call("Page.navigate", url=app_url); time.sleep(1.0)
wait_for("!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())", what="connect")
time.sleep(2.0)
values = {}
for st in steps:
    if "tab" in st:
        lab = json.dumps(st["tab"])
        js(f"""(() => {{ const a = Array.from(document.querySelectorAll('.navbar a[data-bs-toggle=tab]')).find(a => a.textContent.trim() === {lab});
                 if (a) {{ a.click(); return true; }}
                 const sel = document.querySelector('select.ccx-tab-select, .navbar select');
                 if (sel) {{ const o = Array.from(sel.options).find(o => o.textContent.trim() === {lab}); sel.value = o.value; sel.dispatchEvent(new Event('change', {{bubbles: true}})); return true; }}
                 throw new Error('no tab ' + {lab}); }})()""")
        time.sleep(2.5)
    elif "pill" in st:
        js(f"Array.from(document.querySelectorAll('ul.nav-pills a')).find(a => a.textContent.trim() === {json.dumps(st['pill'])}).click()")
        time.sleep(2.0)
    elif "set" in st:
        for k, v in st["set"].items():
            js(f"Shiny.setInputValue({json.dumps(k)}, {json.dumps(v)}, {{priority: 'event'}})")
        time.sleep(0.5)
    elif "url" in st:          # a bookmark URL (?_inputs_&...): sets the widgets themselves, as a reader's link does
        call("Page.navigate", url=app_url.rstrip("/") + "/" + st["url"].lstrip("/")); time.sleep(1.0)
        wait_for("!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected())", what="connect")
        time.sleep(2.5)
    elif "click" in st:
        js(f"document.querySelector({json.dumps(st['click'])}).click()")
    elif "wait" in st:
        time.sleep(st["wait"] / 1000)
    elif "waitimg" in st:
        sel = json.dumps(st["waitimg"] + " img")
        wait_for(f"!!document.querySelector({sel}) && document.querySelector({sel}).complete && document.querySelector({sel}).naturalWidth > 0",
                 timeout=180, what=st["waitimg"])
        time.sleep(1.2)
    elif "scroll" in st:
        js(f"document.querySelector({json.dumps(st['scroll'])}).scrollIntoView({{block: {json.dumps(st.get('block', 'start'))}}})")
        time.sleep(0.8)
    elif "scrolly" in st:
        js(f"window.scrollTo(0, {int(st['scrolly'])})"); time.sleep(0.6)
    elif "js" in st:
        v = js(st["js"]); values[st.get("as", f"js{len(values)}")] = v; print(st.get("as", "js"), "=", json.dumps(v)[:400])
    elif "shot" in st:
        if st.get("el"):
            r = js(f"(() => {{ const e = document.querySelector({json.dumps(st['el'])}); const b = e.getBoundingClientRect();"
                   f" return [b.left + window.scrollX, b.top + window.scrollY, b.width, b.height]; }})()")
            p = st.get("pad", 8)
            clip = dict(x=max(0, r[0] - p), y=max(0, r[1] - p), width=r[2] + 2 * p, height=r[3] + 2 * p, scale=1)
            save_png(st["shot"], call("Page.captureScreenshot", format="png", clip=clip, captureBeyondViewport=True)["data"])
        elif st.get("full"):
            h = js("document.documentElement.scrollHeight")
            clip = dict(x=0, y=0, width=W, height=h, scale=1)
            save_png(st["shot"], call("Page.captureScreenshot", format="png", clip=clip, captureBeyondViewport=True)["data"])
        else:
            save_png(st["shot"], call("Page.captureScreenshot", format="png")["data"])
json.dump(values, open(os.path.join(out_dir, "values_" + os.path.splitext(os.path.basename(sys.argv[7]))[0] + ".json"), "w"), indent=1)
