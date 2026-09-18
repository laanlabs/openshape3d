#!/usr/bin/env python3
""""Ask Claude for a 3D-printable part — no CAD needed": the store-user video.

    python3 ask_claude.py <material-dir>

Unlike the simulator tutorials this one is cut AFTER the fact from real
material (see docs/AI_MODELING_SETUP.md for the flow it shows):

  <material-dir>/stills/*.png        real screenshots: the Mac app's Settings, Claude
                                     Desktop's install / pairing / enabled / permission dialogs
  <material-dir>/build.mov           `screencapture -V -l <window>` of the Mac app while a real
                                     Claude session built the part through the extension relay
  <material-dir>/session-timed.jsonl that session's stream-json, each event stamped `_t`
                                     (seconds from the start of the recording)
  <material-dir>/change.mov, change-timed.jsonl   optional: a follow-up request in the same chat

Each segment lasts as long as its narration; the build footage is sped up to
fit, and the panel shows Claude's own messages at the moments it sent them.
"""
import json, os, subprocess, sys, textwrap
from common import *

NAME = "ask-claude"
PROMPT = ("Make me a flowerpot I can 3D print in OpenShape 3D: about 11 cm wide at the top and 10 cm tall, "
          "with a hole in the bottom for water, and a saucer to go under it. Make it terracotta coloured. "
          "Save the files so I can print them.")
CHANGE = "Actually, make the pot 15 cm tall instead of 10, and save it again."

SCRIPT = [
 {"id": "hook", "chapter": "Intro", "title": "Ask for it. Print it.", "sub": "No CAD experience needed",
  "lines": ["One sentence to Claude", "A real CAD model on your Mac", "STL files ready for your printer"],
  "visual": ("still", [("hero", None)]),
  "say": "Nobody drew this flowerpot. I asked for it, in one sentence, and an A I assistant modelled it in a real CAD app on my Mac, ready to 3D print. You don't need to know any CAD to do this. Here's the setup. It takes about two minutes, and you only do it once."},
 {"id": "need", "chapter": "What you need", "title": "What you need", "sub": "Three apps, no terminal",
  "lines": ["OpenShape 3D for Mac (free)", "Claude Desktop", "Your printer's slicer"],
  "visual": ("still", [("need", None)]),
  "say": "You need three things. OpenShape 3D on your Mac, which is free. The Claude desktop app. And your 3D printer's slicer, the app that turns a model into a print."},
 {"id": "step1", "chapter": "Step 1: switch it on", "title": "1 · Switch it on", "sub": "OpenShape 3D › Settings › AI Assistant",
  "lines": ["Click the gear", "Turn on Let AI Assistants Build Here", "It says Ready. Off again any time"],
  "visual": ("still", [("settings-off", (16, 108, 488, 46)), ("settings-on", (16, 108, 488, 90))]),
  "say": "Step one. In OpenShape 3D, click the gear to open Settings. Right at the top is A I Assistant. Switch on Let A I Assistants Build Here. It turns green and says Ready. It stays off until you turn it on, and you can turn it off whenever you like."},
 {"id": "step2", "chapter": "Step 2: add it to Claude", "title": "2 · Add it to Claude", "sub": "One button, then Install",
  "lines": ["Click Add to Claude Desktop…", "Claude opens the OpenShape 3D extension", "Click Install, and confirm"],
  "visual": ("still", [("settings-on", (16, 240, 488, 44)), ("claude-install", (510, 94, 82, 36)), ("claude-confirm", None)]),
  "say": "Step two. Click Add to Claude Desktop. Claude comes to the front, showing the OpenShape 3D extension. Click Install, and confirm. Claude warns you, as it does for every extension, to only install things you trust."},
 {"id": "pair", "title": "Paste the pairing code", "sub": "Already copied for you",
  "lines": ["Paste, then Save", "Switch the extension to Enabled", "Only your Claude, on your Mac, can connect"],
  "visual": ("still", [("claude-code", None), ("claude-enabled", (20, 402, 150, 44))]),
  "say": "Claude asks for a pairing code. OpenShape already copied it for you, so just paste, and click Save. Then flip the extension to Enabled. That's the whole setup. The pairing code means that only your Claude, on your Mac, can talk to your OpenShape."},
 {"id": "ask", "chapter": "Ask for a part", "title": "Now just ask", "sub": "In your own words",
  "lines": ["Start a blank design in OpenShape 3D", "Tell Claude what you want", "First time: choose Always allow"],
  "visual": ("still", [("claude-permission", None)]),
  "chat": [("You", PROMPT)],
  "say": "Now just ask. Start a blank design in OpenShape, and tell Claude what you want, in your own words. Make me a flowerpot I can 3D print, about eleven centimetres wide and ten tall, with a hole in the bottom for water, and a saucer to go under it. Terracotta coloured. Save the files so I can print them. The first time Claude uses each OpenShape tool, it asks. Choose Always allow."},
 {"id": "build", "chapter": "Watch it build", "title": "Watch it build", "sub": "Real session, sped up",
  "lines": [],
  "visual": ("video", "build", "session"),
  "say": "And then you watch. This is a real session, sped up a little. Claude reads a short guide to the app, then draws half of the pot's outline and spins it around into a solid, with a rim at the top, and a hole in the floor for drainage. It even adds little feet, so the water can get out. Then the saucer, beside it. It colours them both. And all the way through, it does something I like: it checks its own work, comparing each volume with its own arithmetic, and running the app's test that every part is a closed, printable solid. Last, it saves the files."},
 {"id": "files", "chapter": "Your files", "title": "Your files are in Downloads", "sub": "STL and 3MF, one per part",
  "lines": ["Standing upright for the print bed", "Sizes in millimetres", "Claude lists exactly what it made"],
  "visual": ("still", [("files", None)]),
  "say": "When it's finished, Claude tells you exactly what it made: the sizes, the wall thickness, how it checked it. And the print files are waiting in your Downloads folder, an S T L and a 3 M F of each part, already standing upright for the print bed."},
 {"id": "change", "chapter": "Change it", "title": "Not quite right? Say so", "sub": "It's a real, editable CAD model",
  "lines": ["Taller, wider, thicker walls", "More drainage holes", "Or edit it yourself in OpenShape 3D"],
  "visual": ("video", "change", "change"),
  "chat": [("You", CHANGE)],
  "say": "And if it's not quite right, just say so. Here I've asked for a taller pot, fifteen centimetres instead of ten. Claude rebuilds it at the new height, checks it again, and saves new files next to the old ones. It's a real CAD model underneath, not a frozen mesh, so Claude can change it, and so can you, with every tool in OpenShape 3D."},
 {"id": "print", "chapter": "Print it", "title": "Print it", "sub": "Open the STL in your slicer",
  "lines": ["Bambu Studio, Cura, PrusaSlicer…", "No supports needed for this pot", "PETG or ASA if it lives outdoors", "3–4 wall loops help it hold water"],
  "visual": ("still", [("hero", None)]),
  "say": "To print it, open the S T L in your slicer: Bambu Studio, Cura, PrusaSlicer, whichever came with your printer. This pot needs no supports. If it's going to live outside, P E T G or A S A holds up better than P L A, and three or four wall loops help it hold water."},
 {"id": "safe", "chapter": "Is it safe?", "title": "Is it safe?", "sub": "Your Mac only, and only when you say",
  "lines": ["Off until you switch it on", "Only apps with your pairing code", "Web pages are refused outright", "OpenShape 3D itself sends nothing online"],
  "visual": ("still", [("settings-on", None)]),
  "say": "A word on safety. OpenShape only listens on your own Mac, only while that switch is on, and only to an app that has your pairing code. Web pages can't reach it at all. OpenShape itself sends nothing to the internet. What you type to Claude goes to Claude, the same as any other chat."},
 {"id": "outro", "chapter": "Wrap-up", "title": "What will you ask for?", "sub": "A hook, a box, a bracket, a planter…",
  "lines": ["Free on the Mac App Store", "Open source on GitHub", "Tell us what you made"],
  "visual": ("still", [("hero", None)]),
  "say": "That's it. Switch it on, add it to Claude, and ask. A coat hook, a box for your electronics, a bracket for a shelf. OpenShape 3D is free and open source. Tell us in the comments what you asked for. Thanks for watching."},
]

VIDEO = {
 "series": "Ask an AI for a part",
 "title": "Ask Claude for a 3D-Printable Part — No CAD Needed | OpenShape 3D",
 "title_card": "Ask for It. Print It.", "title_sub": "3D-printable parts from one sentence, with Claude",
 "title_foot": "OpenShape 3D for Mac · free and open source",
 "outro_foot": "Setup guide in the description",
 "description": """You don't need to know CAD to design something for your 3D printer. With OpenShape 3D on your Mac and the Claude desktop app, you describe the part in one sentence, watch it get modelled in a real CAD app, and find print-ready STL files in your Downloads folder.

Setup (two minutes, once)
1. OpenShape 3D › Settings › AI Assistant › switch on "Let AI Assistants Build Here"
2. Click "Add to Claude Desktop…" › Install › paste the pairing code (already copied) › Save › Enabled
3. Start a blank design and ask Claude for what you want

Everything Claude builds is a normal, editable CAD model: ask for changes, or keep working on it yourself.

Is it safe? The app listens only on your own Mac, only while the switch is on, and only to an app that has your pairing code. OpenShape 3D itself sends nothing to the internet.

The build in this video is a real Claude session working in the OpenShape 3D Mac app, sped up to fit the narration. ChatGPT's desktop app (Codex) can connect too; the setup guide covers it.

Setup guide: https://github.com/laanlabs/openshape3d/blob/main/docs/AI_MODELING_SETUP.md""",
 "footer": "OpenShape 3D is free and open source: https://github.com/laanlabs/openshape3d\n#3dprinting #claude #cad #ai #mac",
 "tags": ["OpenShape 3D", "3D printing", "Claude", "Claude Desktop", "AI CAD", "text to CAD", "no CAD experience", "STL",
          "flowerpot", "Mac CAD", "MCP", "Claude extension", "beginner 3D printing", "AI 3D model", "ChatGPT"],
 "thumb": "“Make me a flowerpot” → a terracotta pot on a print bed  ·  ASK. PRINT.",
}

MAIN_W = VW                      # the 1440-wide stage left of the chapter panel
# `screencapture -l` pads a window capture with its shadow, more below than above:
# a 1440×900 window arrives as 1552×1012 with its content at (56, 38).
WINDOW_CROP = "crop=1440:900:56:38"


# ---- material ---------------------------------------------------------------------------

def transcript(path):
    """(seconds, who, text) for Claude's own messages in a timed stream-json session."""
    out = []
    if not os.path.exists(path):
        return out
    for line in open(path):
        ev = json.loads(line)
        if ev.get("type") != "assistant":
            continue
        for c in ev["message"]["content"]:
            if c.get("type") == "text" and c["text"].strip():
                out.append((ev["_t"], "Claude", c["text"].strip()))
    return out


def session_span(path, lead=2.0, tail=4.0):
    """Recording seconds worth showing: from just before the first OpenShape call to just after the last."""
    times = []
    for line in open(path):
        ev = json.loads(line)
        if ev.get("type") == "assistant" and any(
                c.get("type") == "tool_use" and "os3d_" in c.get("name", "") for c in ev["message"]["content"]):
            times.append(ev["_t"])
    return max(0.0, times[0] - lead), times[-1] + tail


# ---- drawing ------------------------------------------------------------------------------

def stage(path, image_path, highlight=None):
    """A real screenshot on the stage: fitted, centred, soft shadow, optional accent box around a control."""
    from PIL import Image, ImageDraw, ImageFilter
    canvas = Image.new("RGBA", (MAIN_W, H), BG + (255,))
    shot = Image.open(image_path).convert("RGBA")
    if highlight:
        d = ImageDraw.Draw(shot)
        x, y, w, h = highlight
        for k in range(5):
            d.rounded_rectangle([x - k, y - k, x + w + k, y + h + k], radius=12 + k, outline=ACCENT + (255,))
    scale = min((MAIN_W - 160) / shot.width, (H - 160) / shot.height, 1.6)
    shot = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)
    x0, y0 = (MAIN_W - shot.width) // 2, (H - shot.height) // 2
    shadow = Image.new("RGBA", (MAIN_W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x0 - 6, y0 + 10, x0 + shot.width + 6, y0 + shot.height + 26],
                                             radius=24, fill=(0, 0, 0, 170))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(22)))
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.width - 1, shot.height - 1], radius=16, fill=255)
    canvas.paste(shot, (x0, y0), mask)
    canvas.save(path)


def need_card(path):
    from PIL import Image, ImageDraw
    im = Image.new("RGBA", (1100, 640), PANEL + (255,))
    d = ImageDraw.Draw(im)
    d.text((60, 50), "What you need", font=font(54, True), fill=FG)
    rows = [("OpenShape 3D for Mac", "Free on the Mac App Store. The CAD app the part is built in."),
            ("Claude Desktop", "The Claude app for Mac, from claude.ai/download."),
            ("Your printer's slicer", "Bambu Studio, Cura, PrusaSlicer… it turns the STL into a print.")]
    y = 160
    for k, (head, sub) in enumerate(rows):
        d.ellipse([60, y + 6, 116, y + 62], fill=ACCENT + (255,))
        d.text((78 if k else 80, y + 12), str(k + 1), font=font(36, True), fill=(255, 255, 255))
        d.text((150, y), head, font=font(38, True), fill=FG)
        d.text((150, y + 50), sub, font=font(26), fill=MUTED)
        y += 150
    im.save(path)


def stl_preview(stl_path, size=(440, 360), colour=(205, 96, 60)):
    """A shaded picture of a binary STL: orthographic, painter's algorithm, one light. (Quick Look's
    `qlmanage -t` would do, but it hangs on some Macs.)"""
    import math, struct
    from PIL import Image, ImageDraw
    data = open(stl_path, "rb").read()
    n = struct.unpack("<I", data[80:84])[0]
    az, el = math.radians(-35), math.radians(-30)
    ca, sa, ce, se = math.cos(az), math.sin(az), math.cos(el), math.sin(el)

    def view(p):                                   # Z-up model → screen x, y and depth
        x, y, z = p
        x1, y1 = x * ca - y * sa, x * sa + y * ca
        return x1, z * ce - y1 * se, y1 * ce + z * se

    tris = []
    for i in range(n):
        f = struct.unpack("<12f", data[84 + 50 * i: 132 + 50 * i])
        pts = [view(f[3:6]), view(f[6:9]), view(f[9:12])]
        ux, uy, uz = (pts[1][k] - pts[0][k] for k in range(3))
        vx, vy, vz = (pts[2][k] - pts[0][k] for k in range(3))
        nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
        length = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
        light = abs((nx * -0.35 + ny * 0.55 + nz * -0.75) / length)
        tris.append((sum(p[2] for p in pts) / 3, pts, 0.38 + 0.62 * light))
    xs = [p[0] for _, pts, _ in tris for p in pts]; ys = [p[1] for _, pts, _ in tris for p in pts]
    scale = min((size[0] - 24) / (max(xs) - min(xs)), (size[1] - 24) / (max(ys) - min(ys))) * 2
    im = Image.new("RGBA", (size[0] * 2, size[1] * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ox = size[0] - (max(xs) + min(xs)) / 2 * scale
    oy = size[1] + (max(ys) + min(ys)) / 2 * scale
    for _, pts, shade in sorted(tris, key=lambda t: -t[0]):          # far to near
        d.polygon([(ox + p[0] * scale, oy - p[1] * scale) for p in pts],
                  fill=tuple(int(c * shade) for c in colour) + (255,))
    return im.resize(size, Image.LANCZOS)


def files_card(path, folder):
    """The exported files as they sit in Downloads: real names, real sizes, rendered from the real STLs."""
    from PIL import Image, ImageDraw
    files = sorted(f for f in os.listdir(folder) if f.lower().endswith((".stl", ".3mf")))
    im = Image.new("RGBA", (1200, 700), PANEL + (255,))
    d = ImageDraw.Draw(im)
    d.text((60, 44), "Downloads", font=font(50, True), fill=FG)
    stls = [f for f in files if f.lower().endswith(".stl")][:2]
    x = 60
    for f in stls:
        d.rounded_rectangle([x, 130, x + 520, 560], radius=18, fill=BG + (255,))
        t = stl_preview(os.path.join(folder, f))
        im.alpha_composite(t, (x + (520 - t.width) // 2, 140 + (350 - t.height) // 2))
        d.text((x + 24, 496), f, font=font(24, True), fill=FG)
        size = os.path.getsize(os.path.join(folder, f))
        d.text((x + 24, 528), f"STL · {size / 1000:.0f} KB · millimetres · Z up", font=font(20), fill=MUTED)
        x += 560
    others = [f for f in files if f not in stls]
    if others:
        d.text((60, 600), "Also saved: " + ", ".join(others), font=font(24), fill=MUTED)
    im.save(path)


def chat_panel(i, n, seg, chat, path):
    """The chapter panel with a conversation under it (the person's request, Claude's real messages)."""
    from PIL import Image, ImageDraw
    panel_png(i, n, seg, VIDEO["series"], path)
    im = Image.open(path).convert("RGBA")
    d = ImageDraw.Draw(im)
    x0, pad = VW, 30
    width = W - x0 - 2 * pad
    # lay the newest messages out bottom-up, above the progress bar
    y = H - 120
    f = font(23)
    for who, text in reversed(chat):
        text = " ".join(text.replace("**", "").replace("`", "").split())
        if len(text) > 260:
            text = text[:257].rsplit(" ", 1)[0] + "…"
        lines = wrap(d, text, f, width - 36)
        h = 40 + 29 * len(lines)
        if y - h < 430 and chat[-1][1] is not text:
            break
        y -= h
        mine = who == "You"
        d.rounded_rectangle([x0 + pad, y, x0 + pad + width, y + h - 10], radius=14,
                            fill=(38, 52, 74, 255) if mine else (30, 35, 44, 255))
        d.text((x0 + pad + 18, y + 8), who, font=font(17, True), fill=ACCENT if mine else (222, 140, 96))
        ty = y + 32
        for line in lines:
            d.text((x0 + pad + 18, ty), line, font=f, fill=FG); ty += 29
    im.save(path)


# ---- cutting ----------------------------------------------------------------------------------

def ff(*args):
    run(["ffmpeg", "-y", "-loglevel", "error", *args])


def cut(material, out_path):
    build = os.path.join(material, "build-" + NAME)
    os.makedirs(build, exist_ok=True)
    stills = os.path.join(material, "stills")
    durations = synthesize(NAME, SCRIPT)
    script = [s for s in SCRIPT if s["visual"][0] != "video" or os.path.exists(os.path.join(material, s["visual"][1] + ".mov"))]
    n = len(script)

    # generated stills
    need_card(os.path.join(stills, "need.png"))
    files_card(os.path.join(stills, "files.png"), os.path.join(material, "files"))
    hero_src = os.path.join(material, "build.mov")
    _, last = session_span(os.path.join(material, "session-timed.jsonl"))
    ff("-ss", f"{last:.2f}", "-i", hero_src, "-frames:v", "1",
       "-vf", WINDOW_CROP, os.path.join(stills, "hero.png"))

    clips, t, timeline = [], 0.0, []
    for i, seg in enumerate(script):
        dur = durations[seg["id"]] + 0.9
        clip = os.path.join(build, f"seg-{i:02d}.mp4")
        kind = seg["visual"][0]
        if kind == "still":
            shots = seg["visual"][1]
            parts = []
            for k, (name, highlight) in enumerate(shots):
                png = os.path.join(build, f"stage-{i:02d}-{k}.png")
                stage(png, os.path.join(stills, name + ".png"), highlight)
                parts.append(png)
            panel = os.path.join(build, f"panel-{i:02d}.png")
            chat_panel(i, n, seg, seg.get("chat", []), panel) if seg.get("chat") else panel_png(i, n, seg, VIDEO["series"], panel)
            each = dur / len(parts)
            ins, fc, prev = [], [], None
            for k, png in enumerate(parts):
                ins += ["-loop", "1", "-t", f"{each + (0.4 if k < len(parts) - 1 else 0):.2f}", "-i", png]
            ins += ["-loop", "1", "-t", f"{dur:.2f}", "-i", panel]
            # a slow push-in keeps a still alive; shots crossfade into each other
            for k in range(len(parts)):
                fc.append(f"[{k}:v]format=rgba,scale={MAIN_W * 2}:-1,zoompan=z='1+0.035*on/{int(each * 30) + 12}':"
                          f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s={MAIN_W}x{H}:fps=30[s{k}]")
            prev = "s0"
            for k in range(1, len(parts)):
                fc.append(f"[{prev}][s{k}]xfade=transition=fade:duration=0.4:offset={each * k:.2f}[x{k}]")
                prev = f"x{k}"
            fc.append(f"[{prev}]pad={W}:{H}:0:0:color=0x{BG[0]:02x}{BG[1]:02x}{BG[2]:02x}[bg]")
            fc.append(f"[bg][{len(parts)}:v]overlay=0:0,format=yuv420p,trim=duration={dur:.2f},setpts=PTS-STARTPTS[v]")
            ff(*ins, "-filter_complex", ";".join(fc), "-map", "[v]", "-r", "30", "-c:v", "libx264",
               "-preset", "medium", "-crf", "18", "-an", clip)
        else:
            _, src, session = seg["visual"]
            a, b = session_span(os.path.join(material, session + "-timed.jsonl"))
            speed = (b - a) / dur
            said = [(("You"), c[1]) for c in seg.get("chat", [])]
            events = [(max(0.0, (when - a) / speed), who, text)
                      for when, who, text in transcript(os.path.join(material, session + "-timed.jsonl")) if when <= b + 5]
            seg = dict(seg, sub=f"Real session, {speed:.1f}× speed" if speed > 1.15 else "Real session, real time")
            # one panel per message, each showing the conversation so far
            cuts = [0.0] + [e[0] for e in events if e[0] < dur] + [dur]
            ins = ["-ss", f"{a:.2f}", "-t", f"{b - a:.2f}", "-i", os.path.join(material, src + ".mov")]
            fc = [f"[0:v]{WINDOW_CROP},setpts=PTS/{speed:.4f},fps=30,"
                  f"scale={MAIN_W}:-2:flags=lanczos,pad={W}:{H}:0:(oh-ih)/2:color=0x{BG[0]:02x}{BG[1]:02x}{BG[2]:02x}[base]"]
            prev = "base"
            for k in range(len(cuts) - 1):
                panel = os.path.join(build, f"panel-{i:02d}-{k:02d}.png")
                chat_panel(i, n, seg, said + [(w, tx) for _, w, tx in events[:k]], panel)
                ins += ["-loop", "1", "-t", f"{dur:.2f}", "-i", panel]
                fc.append(f"[{prev}][{k + 1}:v]overlay=0:0:enable='between(t,{cuts[k]:.2f},{cuts[k + 1]:.2f})'[o{k}]")
                prev = f"o{k}"
            fc.append(f"[{prev}]format=yuv420p,trim=duration={dur:.2f},setpts=PTS-STARTPTS[v]")
            ff(*ins, "-filter_complex", ";".join(fc), "-map", "[v]", "-r", "30", "-c:v", "libx264",
               "-preset", "medium", "-crf", "18", "-an", clip)
        clips.append(clip)
        timeline.append({"id": seg["id"], "start": t, "end": t + dur})
        t += dur
    total = t
    json.dump({"segments": timeline, "total": total}, open(os.path.join(material, "timeline.json"), "w"), indent=1)

    card(VIDEO["title_card"], VIDEO["title_sub"], [VIDEO["title_foot"]], os.path.join(build, "title.png"))
    card("Thanks for watching", "github.com/laanlabs/openshape3d",
         ["Free · open source · no account", VIDEO["outro_foot"]], os.path.join(build, "outro.png"), big=False)
    for name, d in (("title", TITLE_S), ("outro", OUTRO_S)):
        ff("-loop", "1", "-i", os.path.join(build, name + ".png"), "-t", str(d),
           "-vf", f"fps=30,format=yuv420p,fade=t=in:st=0:d=0.8,fade=t=out:st={d - 0.8}:d=0.8",
           "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-r", "30", "-an", os.path.join(build, name + ".mp4"))
    with open(os.path.join(build, "concat.txt"), "w") as f:
        for part in [os.path.join(build, "title.mp4"), *clips, os.path.join(build, "outro.mp4")]:
            f.write(f"file '{part}'\n")
    ff("-f", "concat", "-safe", "0", "-i", os.path.join(build, "concat.txt"), "-c", "copy", os.path.join(build, "video.mp4"))

    full = TITLE_S + total + OUTRO_S
    ins = ["-i", os.path.join(build, "video.mp4"), "-i", music_bed(os.path.join(S, "music-bed.wav"))]
    af, mixes = [], []
    starts = {s["id"]: s["start"] for s in timeline}
    for k, seg in enumerate(script):
        ins += ["-i", seg["_clip"]]
        off = int((TITLE_S + starts[seg["id"]] + 0.35) * 1000)
        af.append(f"[{k + 2}:a]aformat=sample_rates=48000:channel_layouts=stereo,adelay={off}|{off}[n{k}]")
        mixes.append(f"[n{k}]")
    af.append(f"{''.join(mixes)}amix=inputs={len(mixes)}:normalize=0:dropout_transition=0,loudnorm=I=-16:TP=-1.5:LRA=11[voice]")
    af.append(f"[1:a]atrim=0:{full:.2f},volume='if(lt(t,{TITLE_S}),0.9,if(gt(t,{TITLE_S + total:.2f}),0.9,0.26))':eval=frame,"
              f"afade=t=in:st=0:d=1.5,afade=t=out:st={full - 3:.2f}:d=3[music]")
    af.append("[voice][music]amix=inputs=2:normalize=0:duration=longest,alimiter=limit=0.95[a]")
    ff(*ins, "-filter_complex", ";".join(af), "-map", "0:v", "-map", "[a]", "-t", f"{full:.2f}",
       "-c:v", "copy", "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-movflags", "+faststart", out_path)
    log(f"wrote {out_path} ({full:.0f} s)")
    return script


if __name__ == "__main__":
    material = os.path.abspath(sys.argv[1])
    os.makedirs(OUT_DIR, exist_ok=True)
    used = cut(material, os.path.join(OUT_DIR, "openshape3d-ask-claude.mp4"))
    write_metadata(os.path.join(OUT_DIR, "openshape3d-ask-claude-metadata.md"), VIDEO, used, material)
