#!/usr/bin/env python3
"""Input-to-screen latency of OpenShape3D while a person (or a test driver)
uses it. Stdlib only.

  python3 scripts/latency_report.py                 # 60 s of use, then the report
  python3 scripts/latency_report.py --seconds 0     # wait for Enter instead
  python3 scripts/latency_report.py --port 8790 --json out.json

Turns the recorder on through the agent channel (POST /v1/diagnostics/latency),
clears it, lets you work, then prints, per kind of input:
  handled   input -> the main thread finished with it (Core Animation committed)
  presented input -> the first viewport frame after it was on screen
plus the pace between actions and the main-thread hitches (stutters/freezes).
The app must run with the agent channel on (OS3D_AGENT=1); launching it with
OS3D_DIAGNOSTICS=1 records from the first frame instead.
"""
import argparse, json, sys, time, urllib.request

ap = argparse.ArgumentParser()
ap.add_argument("--port", type=int, default=8787)
ap.add_argument("--seconds", type=float, default=60, help="0 = wait for Enter")
ap.add_argument("--events", type=int, default=200, help="inputs listed one by one")
ap.add_argument("--json", help="also save the full report here")
ap.add_argument("--keep", action="store_true", help="leave the recorder on afterwards")
a = ap.parse_args()
B = f"http://127.0.0.1:{a.port}/v1/diagnostics/latency"

def call(method, url, body=None):
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=30))

call("POST", B, {"enabled": True, "reset": True})
if a.seconds > 0:
    print(f"Recording for {a.seconds:.0f} s — use the app now.", flush=True); time.sleep(a.seconds)
else:
    input("Recording — use the app, then press Enter. ")
r = call("GET", f"{B}?events={a.events}")
if not a.keep: call("POST", B, {"enabled": False})
if a.json: json.dump(r, open(a.json, "w"), indent=1)

def fmt(s): return "      -" if not s else f"{s['p50']:7.1f} {s['p95']:7.1f} {s['max']:8.1f}  (n={s['n']})"
print(f"\n{r['recordingSeconds']:.0f} s recorded · {r['framesDrawn']} viewport frames drawn, {r['framesPresented']} presented")
print(f"{'input':8} {'count':>6}   handled ms: p50     p95      max          presented ms: p50     p95      max")
for name in ("press", "drag", "release", "key"):
    p = r["phases"].get(name)
    if p: print(f"{name:8} {p['inputs']:6}   {fmt(p['handledMS']):38} {fmt(p['presentedMS'])}")
g = r["gapBetweenActionsMS"]
if g: print(f"\ntime between actions (press/key to the next): p50 {g['p50']:.0f} ms, p95 {g['p95']:.0f} ms, max {g['max']:.0f} ms")
h = r["hitches"]
print(f"main-thread hitches: {h['count']} (total {h['totalMS']:.0f} ms" + (f", worst {h['worst']['max']:.0f} ms)" if h['count'] else ")"))
slow = sorted((e for e in r["events"] if e.get("presentedMS") or e.get("handledMS")),
              key=lambda e: -max(e.get("presentedMS") or 0, e.get("handledMS") or 0))[:8]
if slow:
    print("\nslowest inputs:")
    for e in slow:
        print(f"  t={e['tMS']/1000:8.2f} s  {e['phase']:7} at ({e['x']},{e['y']})  handled {e['handledMS']} ms  presented {e['presentedMS']} ms")
