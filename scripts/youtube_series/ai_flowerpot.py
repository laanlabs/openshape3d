#!/usr/bin/env python3
""""Design a 3D-printable flowerpot with Claude or ChatGPT" — setup, test, build, print.

    python3 ai_flowerpot.py [--take-only | --compose-only]

The modelling on screen is `ai_flowerpot_session.json`: the tool calls one real
Claude session made for the prompt (captured with OS3D_MCP_LOG through
scripts/mcp_openshape3d.py), replayed over the bridge at narration pace. Ids
are re-mapped as the replay mints new ones, and the take fails if the
replayed solids do not land on the recorded volumes. The setup chapters are
slides over the (idle) recording; the camera moves between calls are ours.
"""
import argparse, json, os, subprocess, sys, textwrap, time
from common import *

NAME = "ai-flowerpot"
SESSION = json.load(open(os.path.join(S, "ai_flowerpot_session.json")))
CALLS = SESSION["calls"]
TAKE_DIR = os.path.join(S, "take-" + NAME)
SLIDES = os.path.join(TAKE_DIR, "slides")

# ---- narration ----------------------------------------------------------------------

SCRIPT = [
 {"id": "intro", "chapter": "Intro", "slide": "hero", "title": "Model by asking", "sub": "Claude or ChatGPT + OpenShape 3D",
  "lines": ["Set up the AI tools", "Test that they work", "One sentence in, a flowerpot out", "STL files ready to print"],
  "say": "What if you could describe a part, and have it modelled for you? This flowerpot and its saucer were designed by an AI assistant driving OpenShape 3D, a free, open-source CAD app for iPad. In this video we'll set that up with Claude or ChatGPT, test that it really works, and then go from one sentence to files that are ready for a 3D printer."},
 {"id": "how", "chapter": "How it works", "slide": "how", "title": "How it works", "sub": "A local bridge, an MCP server, a skill",
  "lines": ["Bridge: debug builds only, this machine only", "Server: one Python file, no dependencies", "Tools: read, model, check, export", "Skill: units, axes, recipes, verify loop"],
  "say": "Here's how it fits together. OpenShape 3D has a small control bridge built into its debug builds. It only listens on your own machine, and it's off unless you switch it on. A tiny server, one Python file with no dependencies, turns that bridge into tools an AI assistant can call over M C P, the Model Context Protocol. The assistant gets tools to read the design, run modelling operations, check the solid, and export it. It also gets a skill: a short guide that teaches it the app's conventions, like millimetres, which way is up, and how to verify its own work."},
 {"id": "setup_app", "chapter": "Setup 1: run the app", "slide": "setup_app", "title": "1 · Run the app with the bridge on", "sub": "Mac + Xcode, simulator or a USB iPad",
  "lines": ["Clone the repo and build for a simulator", "Launch with OS3D_AGENT=1", "Health check answers on port 8787"],
  "say": "Step one: run the app with the bridge on. Clone the repository from GitHub, build it for an iPad simulator, and launch it with the environment variable O S 3 D agent set to one. A quick health check should answer with the app's name, and tell you that a design is open. It works with a real iPad over U S B too; the setup guide in the repo covers that."},
 {"id": "setup_claude", "chapter": "Setup 2: Claude", "slide": "setup_claude", "title": "2 · Connect Claude", "sub": "Claude Desktop or Claude Code",
  "lines": ["Desktop: Settings › Developer › Edit Config", "Command: python3, argument: the script's path", "Claude Code: automatic inside the repo"],
  "say": "Step two: connect your assistant. For the Claude desktop app, open Settings, Developer, Edit Config, and add the server. The command is Python, and the argument is the path to the script inside your clone. Restart Claude, and the OpenShape tools appear. If you use Claude Code, there's nothing to do: open the repository, and the server and the modelling skill are picked up automatically."},
 {"id": "setup_chatgpt", "chapter": "Setup 3: ChatGPT", "slide": "setup_chatgpt", "title": "3 · Connect ChatGPT", "sub": "Codex, in the ChatGPT app or the CLI",
  "lines": ["Three lines in ~/.codex/config.toml", "Same server, same twelve tools", "The guide travels with the server"],
  "say": "For ChatGPT, the route is Codex, which is built into the ChatGPT desktop app, and is also a command line tool. Add these three lines to the Codex config file, and it starts the same server and sees the same twelve tools. Any other M C P client works the same way, because the modelling guide travels with the server."},
 {"id": "test", "chapter": "Test the tools", "slide": "test", "title": "Test before you trust", "sub": "scripts/test_mcp_openshape3d.py",
  "lines": ["Offline: protocol, errors, export", "--live: models a pot through the tools", "Volume vs the exact formula", "STL watertight and upright"],
  "say": "Before trusting an AI with your design, test the tools. The repo includes a test script. Without the app, it checks the protocol, the error handling and the export. With the live flag, it models a flowerpot through the very same tools, compares the volume with the exact formula, and checks that the exported mesh is watertight and standing upright. All green. So let's make something."},
 {"id": "prompt", "chapter": "The prompt", "title": "One request, in plain English", "sub": "An empty design on the iPad",
  "lines": ["What you'll see: Claude's real tool calls", "Replayed at the pace of the narration", "The session itself took 73 seconds"],
  "say": "Here's an empty design on the iPad, and here's the whole request, in plain English. Design a flowerpot I can 3D print: about a hundred and ten millimetres across the top, a hundred tall, tapered sides, three millimetre walls, a drainage hole, and a matching saucer. Round over the rim, make it look like terracotta, check that both parts are valid solids, and export each one as its own S T L. What you'll see next are the actual tool calls Claude made for this prompt, replayed at the pace of my voice. The real session took seventy-three seconds."},
 {"id": "reads", "chapter": "Claude builds the pot", "title": "First, look around", "sub": "health · guide · state",
  "lines": ["Is the app there? Is a design open?", "Read the modelling guide once", "The design is empty"],
  "say": "Claude starts by checking that the app is there, reads the modelling guide, and looks at the current state of the design, which is empty."},
 {"id": "profile", "title": "Half a cross-section", "sub": "A vertical sketch, six lines",
  "lines": ["u is the radius, v is the height", "Starts 6 mm off the axis: the drain hole", "Wall 3 mm, measured square to the taper"],
  "say": "A pot is a turned shape, so Claude follows the guide's recipe: a vertical sketch plane, and on it, half of the wall's cross-section, drawn as six lines. The bottom edge starts six millimetres away from the axis. That gap becomes the drainage hole. The outer wall leans out from forty-two to fifty-five millimetres of radius, and the inner wall runs parallel to it, three millimetres in."},
 {"id": "revolve", "title": "One revolve", "sub": "Then check the number, not the picture",
  "lines": ["Revolve 360° about the vertical axis", "App: 103,429 mm³", "Claude's hand calculation: the same"],
  "say": "Then one revolve around the vertical axis, and there's the pot. Notice what Claude does next. It doesn't trust a picture. It works out the volume by hand, and compares it with what the app reports: a hundred and three thousand, four hundred and twenty-nine cubic millimetres. They match, so the wall, the floor and the hole are all really there."},
 {"id": "rim", "title": "Round the rim", "sub": "List the edges, fillet two of them",
  "lines": ["Edges come with midpoints and lengths", "The two circles at the top", "1.4 mm on a 3 mm wall: a full round"],
  "say": "To round the rim, it lists the pot's edges, picks out the two circles at the top, and fillets both with a radius of one point four millimetres. On a three millimetre wall, that makes a fully rounded lip."},
 {"id": "saucer", "chapter": "The saucer", "title": "A matching saucer", "sub": "Same recipe, 130 mm to the side",
  "lines": ["18 mm tall, 3 mm walls", "Floor wider than the pot's 84 mm base", "Sketch · revolve · edges · fillet"],
  "say": "The saucer is the same idea on a second sketch, placed a hundred and thirty millimetres to the side, so the two parts don't overlap. It's eighteen millimetres tall, with a floor wide enough for the pot's base to sit in, with room to spare. Revolve, list the edges, and round the rim."},
 {"id": "material", "title": "Terracotta", "sub": "One call, both bodies",
  "lines": ["A colour, or a preset like Steel or Wood", "Shown in the app only", "STL files carry no colour"],
  "say": "One call paints both bodies terracotta. That colour lives in the app. An S T L file doesn't carry colour, so for the real thing you'll want terracotta filament."},
 {"id": "verify", "chapter": "Check and export", "title": "Is it really a solid?", "sub": "Geometry check, self-intersection pass on",
  "lines": ["2 bodies checked, 0 invalid", "Each is one closed solid", "No findings"],
  "say": "Now the part that matters for printing. Claude runs the geometry check, with the self-intersection pass switched on. Both bodies come back as valid, closed solids, with no findings."},
 {"id": "export", "title": "Export for the slicer", "sub": "One STL per part, Z up",
  "lines": ["The app is Y-up, slicers are Z-up", "up: z stands the part on the bed", "Millimetres, about 30,000 triangles each"],
  "say": "And it exports each body to its own S T L, with the up axis set to Z. The app's world is Y up, and slicers are Z up, so this stands each part on the print bed exactly the way it stands on the ground here. About thirty thousand triangles each, in millimetres."},
 {"id": "look", "title": "A last look", "sub": "Frame, screenshot, tidy up",
  "lines": ["Isometric view, fit", "A screenshot of its own work", "Hide the two sketches", "21 tool calls, no errors"],
  "say": "Finally it frames the view, takes a screenshot to look at its own work, and hides the two sketches to tidy up. Twenty-one tool calls, and no errors."},
 {"id": "editable", "chapter": "It's a real CAD model", "title": "Not a dead mesh", "sub": "Every call is a feature in the history",
  "lines": ["Revolve · Fillet · Revolve · Fillet", "Undo, edit, or keep modelling by hand", "Ask for changes: taller, more holes…"],
  "say": "And this is not a dead mesh. Every step was recorded as a normal parametric feature, so it's all here in the history: both revolves and both fillets, each with its numbers. You can undo it, keep modelling by hand, or just ask for changes: make it a hundred and fifty tall, or add three more drainage holes."},
 {"id": "print", "chapter": "Printing it", "slide": "print", "title": "Printing it", "sub": "Two STL files, no supports",
  "lines": ["Any slicer: Cura, PrusaSlicer, Bambu Studio", "PETG or ASA for damp soil and sun", "3–4 walls, 15% infill", "Walls lean 7° and 18°: no supports"],
  "say": "To print it, drop the two S T L files into your slicer. Cura, PrusaSlicer, Bambu Studio, any of them. Neither part needs supports, because the walls lean only a few degrees. For a pot that holds damp soil and sits in the sun, use P E T G or A S A rather than P L A, with three or four wall loops and about fifteen percent infill."},
 {"id": "outro", "chapter": "Wrap-up", "slide": "hero", "title": "Try it yourself", "sub": "docs/AI_MODELING_SETUP.md",
  "lines": ["Server, skill and tests are in the repo", "Free · open source · no account", "Tell us what you made"],
  "say": "That's modelling with an AI assistant in OpenShape 3D. The setup guide, the server, the skill and the tests are all in the GitHub repository, free and open source. Try it with your own idea, and tell us in the comments what you made. Thanks for watching."},
]

VIDEO = {
 "series": "AI-assisted modelling",
 "title": "Design a 3D-Printable Flowerpot with Claude or ChatGPT | OpenShape 3D",
 "title_card": "Model by Asking", "title_sub": "A 3D-printable flowerpot with Claude or ChatGPT",
 "outro_foot": "Setup guide: docs/AI_MODELING_SETUP.md",
 "description": """Describe a part in plain English and have an AI assistant model it in a real CAD app. This tutorial connects Claude (Claude Desktop or Claude Code) or ChatGPT (Codex) to OpenShape 3D, the free, open-source CAD app for iPad, tests that the tools work, and then goes from one sentence to a flowerpot and saucer exported as STL files for a 3D printer.

What you'll see
• How it works: a loopback-only bridge in debug builds, a dependency-free MCP server, and a modelling skill
• Setup for Claude Desktop, Claude Code and ChatGPT/Codex
• Testing the tools: protocol, errors, and a live flowerpot held to its exact volume and a watertight STL
• Claude's real tool calls for the prompt, replayed at narration pace (the session took 73 seconds): sketch, revolve, fillet, material, geometry check, STL export
• Why the result is a normal parametric model you can keep editing by hand
• Slicer settings for a pot that lives outdoors

The prompt: "Design a flowerpot I can 3D print. About 110 mm across the top and 100 mm tall, tapered sides, 3 mm walls, a drainage hole in the bottom, and a matching saucer to sit under it. Round over the rim so it's comfortable to pick up. Make it look like terracotta. Check that both parts are valid solids, then export each one as its own STL, ready for my slicer."

Setup guide: https://github.com/laanlabs/openshape3d/blob/main/docs/AI_MODELING_SETUP.md""",
 "footer": "OpenShape 3D is free and open source: https://github.com/laanlabs/openshape3d\n#3dprinting #cad #claude #chatgpt #mcp #ipad",
 "tags": ["OpenShape 3D", "AI CAD", "Claude", "ChatGPT", "Codex", "MCP", "Model Context Protocol", "3D printing", "flowerpot", "STL",
          "iPad CAD", "open source CAD", "parametric modeling", "Claude Code", "Claude Desktop", "text to CAD"],
 "thumb": "“Make me a flowerpot” → STL  ·  terracotta pot and saucer beside a chat bubble",
}

# ---- what a tool call looks like on the panel ------------------------------------------

def short(v):
    if isinstance(v, str) and len(v) == 36 and v.count("-") == 4:
        return v[:8] + "…"
    if isinstance(v, list):
        return "[" + ", ".join(short(x) for x in v) + "]"
    if isinstance(v, float):
        return f"{v:g}"
    return json.dumps(v) if isinstance(v, (dict, bool)) else str(v)


def call_lines(call, width=40):
    """Panel text for one recorded call: the tool, its arguments, then what came back."""
    a = call["arguments"]
    out = ["> " + call["name"]]
    if call["name"] == "os3d_exec":
        out.append("op: " + a["op"])
        for k, v in a.get("args", {}).items():
            if k == "entities":
                for e in v:
                    out.append("  line " + short(e["a"]) + " → " + short(e["b"]) if e["kind"] == "line"
                               else "  " + e["kind"])
            else:
                out += textwrap.wrap(f"{k}: {short(v)}", width, subsequent_indent="   ")
    else:
        for k, v in a.items():
            out += textwrap.wrap(f"{k}: {short(v)}", width, subsequent_indent="   ")
    if call.get("volumes") and a.get("op", "").startswith("feature."):
        out.append("✓ volume " + " · ".join(f"{v:,.0f}" for v in call["volumes"]) + " mm³")
    if call.get("check"):
        out.append(f"✓ checked {call['check']['checked']}, invalid {call['check']['invalid']}")
    if call.get("export"):
        out.append(f"✓ {call['export']['triangles']:,} triangles, {call['export']['bytes'] / 1e6:.1f} MB")
    if call["name"] == "os3d_guide":
        out.append("✓ the modelling skill (7.7 k chars)")
    if call["name"] == "os3d_state" and not call.get("volumes"):
        out.append("✓ bodies: []  sketches: 0")
    if call["name"] == "os3d_health":
        out.append('✓ app "openshape3d", hasDocument')
    return out[:24]


# which recorded calls play in which chapter (indices into CALLS)
CHAPTER_CALLS = {"reads": [0, 1, 2], "profile": [3, 4], "revolve": [5], "rim": [6, 7], "saucer": [8, 9, 10, 11, 12],
                 "material": [13], "verify": [14], "export": [15, 16], "look": [17, 18, 19, 20]}
for seg in SCRIPT:
    if seg["id"] in CHAPTER_CALLS:
        seg["steps"] = [call_lines(CALLS[i]) for i in CHAPTER_CALLS[seg["id"]]]
    if seg["id"] == "prompt":
        seg["code"] = ["# you"] + textwrap.wrap(SESSION["prompt"], 40)


# ---- replay ----------------------------------------------------------------------------

class Replay:
    """Send the recorded calls to the live bridge, re-mapping the ids each reply mints."""

    def __init__(self, out_dir):
        self.ids, self.out_dir, self.bodies = {}, out_dir, []

    def remap(self, v):
        if isinstance(v, str):
            return self.ids.get(v, v)
        if isinstance(v, list):
            return [self.remap(x) for x in v]
        if isinstance(v, dict):
            return {k: self.remap(x) for k, x in v.items()}
        return v

    def play(self, rec):
        name, a = rec["name"], self.remap(rec["arguments"])
        log(f"replay {name} {json.dumps(a)[:120]}")
        if name == "os3d_exec":
            r = X(a["op"], a.get("args", {}))
            for old, new in zip(rec.get("ids", {}).get("producedBodyIDs", []), r.get("producedBodyIDs", [])):
                self.ids[old] = new
            if rec.get("ids", {}).get("sketchID") and r.get("sketchID"):
                self.ids[rec["ids"]["sketchID"]] = r["sketchID"]
            if rec.get("volumes") is not None:
                got = [round(b["volumeMM3"], 2) for b in r["bodies"]]
                if len(got) != len(rec["volumes"]) or any(abs(g - w) > 0.5 for g, w in zip(got, rec["volumes"])):
                    sys.exit(f"replay diverged from the recorded session: volumes {got} != {rec['volumes']}")
        elif name == "os3d_run_command":
            cmd(a["id"])
        elif name == "os3d_edges":
            edges(a["body"])
        elif name == "os3d_check":
            r = call("/v1/check?bop=1", timeout=300)
            if r.get("invalid") != 0:
                sys.exit(f"geometry check failed in the replay: {r}")
        elif name == "os3d_export":
            os.makedirs(self.out_dir, exist_ok=True)
            path = os.path.join(self.out_dir, os.path.basename(a["path"]))
            url = f"{BASE}/v1/export?format={a['format']}&up={a['up']}&body={','.join(a['body'])}"
            with urllib.request.urlopen(url) as resp, open(path, "wb") as f:
                f.write(resp.read())
            log(f"   wrote {path}")
        else:                                     # health, guide, state, screenshot: reads
            call("/v1/state" if name == "os3d_state" else "/v1/health")


def take(t):
    tl = t.tl
    replay = Replay(os.path.join(TAKE_DIR, "stl"))

    def chapter(id, before=0.8, spans=None, after=None):
        """Play the chapter's calls spread across its narration; `after(k)` moves the camera.
        `spans` fixes the seconds given to the first calls (the rest share what is left)."""
        tl.begin(id)
        calls = CHAPTER_CALLS[id]
        time.sleep(before)
        spans = list(spans or [])
        rest = max(2.5, (tl.remaining() - 1.0 - sum(spans)) / max(1, len(calls) - len(spans)))
        for k, i in enumerate(calls):
            span = spans[k] if k < len(spans) else rest
            started = time.time()
            tl.mark()
            time.sleep(0.9)                       # the call is on the panel before the model changes
            replay.play(CALLS[i])
            if after:
                after(k)
            time.sleep(max(0.0, span - (time.time() - started)))
        tl.hold(0.4)

    # setup chapters: slides cover the recording; the app sits on a blank design underneath
    tl.begin("intro"); time.sleep(1.0)
    t.touch("new_design"); wait_document(); time.sleep(1.5)
    cmd("view.isometric", 1.0)
    tl.hold(0.3)
    for id in ("how", "setup_app", "setup_claude", "setup_chatgpt", "test"):
        tl.begin(id); tl.hold(0.3)
    tl.begin("prompt"); tl.hold(0.3)

    chapter("reads")
    chapter("profile", before=3.0, spans=[4.0], after=lambda k: (cmd("view.front", 1.4), cmd("view.fit", 0.8)) if k == 1 else cmd("view.front", 1.2))
    chapter("revolve", before=6.0, after=lambda k: (time.sleep(1.2), cmd("view.isometric", 1.4), cmd("view.fit", 0.8)))
    chapter("rim")
    chapter("saucer", after=lambda k: cmd("view.fit", 0.8) if k in (1, 2) else None)
    chapter("material")
    chapter("verify")
    chapter("export")
    chapter("look")
    open(os.path.join(TAKE_DIR, "hero.png"), "wb").write(
        urllib.request.urlopen(f"{BASE}/v1/screenshot?w=2880&h=2160").read())

    tl.begin("editable")
    time.sleep(2.0)
    t.touch("toolbar:HistoryButton"); time.sleep(1.0)
    tl.hold(0.6)
    t.touch("toolbar:HistoryButton"); time.sleep(0.5)
    for id in ("print", "outro"):
        tl.begin(id)
        if id == "print":
            cmd("view.front", 1.6); cmd("view.isometric", 1.4); cmd("view.fit", 0.4)
        tl.hold(0.6 if id == "print" else 1.2)


# ---- slides (VW × H, over the recording) ----------------------------------------------------

def slide(path, heading, sub, blocks, image=None):
    from PIL import Image, ImageDraw
    im = Image.new("RGBA", (VW, H), BG + (255,))
    d = ImageDraw.Draw(im)
    if image is not None:
        im.alpha_composite(image, (0, 0))
        d = ImageDraw.Draw(im)
    x, y = 90, 84
    d.rectangle([x, y, x + 56, y + 6], fill=ACCENT + (255,))
    y += 30
    d.text((x, y), heading, font=font(60, True), fill=FG); y += 80
    if sub:
        d.text((x, y), sub, font=font(30), fill=MUTED); y += 66
    for kind, body, *rest in blocks:
        if kind == "code":
            y = code_block(d, x, y, VW - 2 * x, body, size=rest[0] if rest else 25) + 34
        elif kind == "label":
            d.text((x, y), body, font=font(28, True), fill=FG); y += 46
        elif kind == "bullets":
            for line in body:
                d.ellipse([x, y + 14, x + 10, y + 24], fill=ACCENT + (255,))
                d.text((x + 30, y), line, font=font(30), fill=FG); y += 50
            y += 16
    im.save(path)
    return path


def how_slide(path):
    from PIL import Image, ImageDraw
    im = Image.new("RGBA", (VW, H), BG + (255,))
    d = ImageDraw.Draw(im)
    d.rectangle([90, 84, 146, 90], fill=ACCENT + (255,))
    d.text((90, 114), "How it works", font=font(60, True), fill=FG)
    d.text((90, 194), "Everything runs on your Mac. Only your chat goes to the assistant you chose.", font=font(28), fill=MUTED)
    boxes = [("You", "“Make me a flowerpot”", 300), ("Claude  ·  ChatGPT", "reads the skill, plans, calls tools", 440),
             ("mcp_openshape3d.py", "MCP server · stdlib Python · 12 tools", 600),
             ("OpenShape 3D", "DEBUG build · OS3D_AGENT=1 · 127.0.0.1 only", 760)]
    labels = ["prompt", "MCP tool calls (stdio)", "HTTP on loopback"]
    for k, (head, sub, y) in enumerate(boxes):
        d.rounded_rectangle([330, y, 1110, y + 110], radius=16, fill=PANEL + (255,), outline=(56, 64, 78, 255), width=2)
        d.text((360, y + 18), head, font=(mono(30, True) if k == 2 else font(34, True)), fill=FG)
        d.text((360, y + 64), sub, font=font(24), fill=MUTED)
        if k < 3:
            ny = boxes[k + 1][2]
            d.line([720, y + 110, 720, ny], fill=ACCENT + (255,), width=4)
            d.polygon([(708, ny - 14), (732, ny - 14), (720, ny)], fill=ACCENT + (255,))
            d.text((744, (y + 110 + ny) // 2 - 14), labels[k], font=font(22), fill=ACCENT)
    d.text((90, 930), "Tools: health · guide · state · exec · faces · edges · sketches · check · screenshot · commands · export",
           font=font(24), fill=MUTED)
    im.save(path)


def hero_image():
    """The finished pot and saucer from the end-of-take screenshot, framed in the right-hand
    part of the slide, with the left shaded for the text."""
    from PIL import Image
    p = os.path.join(TAKE_DIR, "hero.png")
    if not os.path.exists(p):
        return None
    im = Image.open(p).convert("RGBA")
    small = im.convert("RGB").resize((im.width // 8, im.height // 8))
    px = small.load()
    hits = [(x, y) for x in range(small.width) for y in range(small.height)
            if px[x, y][0] > 150 and px[x, y][0] > 1.6 * px[x, y][2] and px[x, y][0] > 1.3 * px[x, y][1]]
    if hits:                                            # terracotta bounding box, full-res
        x0, x1 = min(h[0] for h in hits) * 8, max(h[0] for h in hits) * 8
        y0, y1 = min(h[1] for h in hits) * 8, max(h[1] for h in hits) * 8
    else:
        x0, y0, x1, y1 = im.width * 0.3, im.height * 0.3, im.width * 0.7, im.height * 0.7
    # the parts fill ~48 % of the slide's width, centred at 70 % across
    cw = (x1 - x0) / 0.48
    ch = cw * H / VW
    if (y1 - y0) / 0.62 > ch:
        ch = (y1 - y0) / 0.62; cw = ch * VW / H
    cx, cy = (x0 + x1) / 2 - cw * 0.20, (y0 + y1) / 2
    box = [cx - cw / 2, cy - ch / 2, cx + cw / 2, cy + ch / 2]
    im = im.crop(tuple(int(v) for v in box)).resize((VW, H), Image.LANCZOS)
    ramp = Image.new("L", (VW, 1))
    ramp.putdata([int(255 * (0.96 if x < VW * 0.40 else max(0.0, 0.96 * (1 - (x - VW * 0.40) / (VW * 0.18))))) for x in range(VW)])
    shade = Image.new("RGBA", (VW, H), BG + (255,))
    shade.putalpha(ramp.resize((VW, H)))
    im.alpha_composite(shade)
    return im


def test_output():
    """The offline test run, verbatim, for the "test" slide."""
    r = subprocess.run(["/usr/bin/python3", os.path.join(ROOT, "scripts", "test_mcp_openshape3d.py")],
                       capture_output=True, text=True)
    lines = [l for l in r.stderr.splitlines() if l.strip()]
    tests = [l.replace(" (__main__.OfflineTests)", "").replace(" (__main__.UnreachableTests)", "")
              .replace(" ... ok", "  ok") for l in lines if l.endswith("... ok")]
    tail = [l for l in lines if l.startswith("Ran ") or l.startswith("OK")]
    return tests, tail


def make_slides():
    os.makedirs(SLIDES, exist_ok=True)
    P = lambda n: os.path.join(SLIDES, n + ".png")
    hero = hero_image()
    slide(P("hero"), "“Design a flowerpot", "I can 3D print.”", [
        ("bullets", ["Modelled by an AI assistant", "in OpenShape 3D, on an iPad", "Exported as print-ready STL"])], image=hero)
    how_slide(P("how"))
    slide(P("setup_app"), "1 · Run the app with the bridge on", "Terminal, in your clone of github.com/laanlabs/openshape3d", [
        ("code", ["# build for an iPad simulator",
                  "$ xcodebuild build -scheme openshape3d \\",
                  '    -destination "platform=iOS Simulator,id=$UDID" \\',
                  "    -derivedDataPath build/dd",
                  "$ xcrun simctl install $UDID build/dd/…/openshape3d.app",
                  "",
                  "# launch with the bridge on, in a fresh design",
                  "$ SIMCTL_CHILD_OS3D_AGENT=1 SIMCTL_CHILD_OS3D_FRESH=1 \\",
                  "    xcrun simctl launch $UDID com.laan.labs.openshape3d",
                  "",
                  "$ curl -s http://127.0.0.1:8787/v1/health",
                  '✓ {"app":"openshape3d","hasDocument":true,"ok":true,',
                  '✓  "platform":"simulator","port":8787,"protocol":1}'])])
    slide(P("setup_claude"), "2 · Connect Claude", None, [
        ("label", "Claude Desktop  ·  Settings › Developer › Edit Config"),
        ("code", ['{"mcpServers": {"openshape3d": {',
                  '   "command": "/usr/bin/python3",',
                  '   "args": ["/path/to/openshape3d/scripts/mcp_openshape3d.py"]',
                  "}}}"]),
        ("label", "Claude Code  ·  inside the repo: automatic (.mcp.json + the skill)"),
        ("code", ["# anywhere else",
                  "$ claude mcp add openshape3d -- /usr/bin/python3 \\",
                  "    /path/to/openshape3d/scripts/mcp_openshape3d.py"])])
    slide(P("setup_chatgpt"), "3 · Connect ChatGPT", "Codex, in the ChatGPT desktop app or the codex CLI", [
        ("label", "~/.codex/config.toml"),
        ("code", ["[mcp_servers.openshape3d]",
                  'command = "/usr/bin/python3"',
                  'args = ["/path/to/openshape3d/scripts/mcp_openshape3d.py"]']),
        ("label", "What Codex sees when it starts the server"),
        ("code", ["# codex-mcp-client → initialize, tools/list",
                  "✓ os3d_health   os3d_guide     os3d_state   os3d_exec",
                  "✓ os3d_faces    os3d_edges     os3d_sketches",
                  "✓ os3d_check    os3d_screenshot os3d_export",
                  "✓ os3d_list_commands  os3d_run_command"])])
    tests, tail = test_output()
    slide(P("test"), "Test before you trust", None, [
        ("code", ["$ python3 scripts/test_mcp_openshape3d.py"] + ["✓ " + t[5:] for t in tests][:15] + tail[-1:], 20),
        ("code", ["$ python3 scripts/test_mcp_openshape3d.py --live      # app running, empty design",
                  "✓ flowerpot_through_the_tools  ok",
                  "#   volume = 2π · centroid · area, to 0.001 mm³",
                  "#   STL watertight, Z-up, within 0.5 % of the solid"], 20)])
    slide(P("print"), "Printing it", "flowerpot.stl  ·  saucer.stl", [
        ("bullets", ["Cura, PrusaSlicer, Bambu Studio",
                     "No supports: walls lean 7° and 18°",
                     "PETG or ASA for damp soil and sun",
                     "3–4 wall loops, 15 % infill",
                     "0.2 mm layers, 0.4 mm nozzle",
                     "Bigger? Just ask for 150 mm tall"])], image=hero)
    for seg in SCRIPT:
        if seg.get("slide"):
            seg["slide"] = P(seg["slide"])


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--compose-only", action="store_true")
    ap.add_argument("--take-only", action="store_true")
    a = ap.parse_args()
    slide_names = {seg["id"]: seg.get("slide") for seg in SCRIPT}
    if not a.compose_only:
        for seg in SCRIPT:
            seg.pop("slide", None)               # run_take only needs the narration
        run_take(NAME, SCRIPT, take, TAKE_DIR)
        for seg in SCRIPT:
            if slide_names[seg["id"]]:
                seg["slide"] = slide_names[seg["id"]]
    if not a.take_only:
        synthesize(NAME, SCRIPT)
        make_slides()
        os.makedirs(OUT_DIR, exist_ok=True)
        out = os.path.join(OUT_DIR, "openshape3d-ai-flowerpot.mp4")
        compose(NAME, SCRIPT, TAKE_DIR, VIDEO, out, VIDEO["series"])
        write_metadata(os.path.join(OUT_DIR, "openshape3d-ai-flowerpot-metadata.md"), VIDEO, SCRIPT, TAKE_DIR)
