#!/usr/bin/env python3
"""Record, compose and write metadata for one of the ten project tutorials.

    project_tutorial.py mug|chess|brick|keychain|vase|bolt|gear|spinner|tray|hinge
        [--dry]            build the model on the running app (bridge only, no video)
        [--take-only | --compose-only]

The model comes from projects.py, the narration and YouTube text from
projects_text.py. Output: marketing/youtube/openshape3d-<slug>.mp4, its
-metadata.md and a -thumbnail.png (1280×720).
"""
import argparse, json, os, subprocess, sys, time, urllib.request
import common
from common import *
from projects import BUILDERS, M
from projects_text import VIDEOS

OUT = os.environ.get("OS3D_VIDEO_OUT", OUT_DIR)


def hero_shot(path, w=1600, h=1200):
    X("item.setHidden", {"allSketches": True})
    cmd("view.isometric", 0.8); cmd("view.fit", 0.8)
    urllib.request.urlretrieve(f"{BASE}/v1/screenshot?w={w}&h={h}&format=png", path)


def make_take(name):
    def take(t):
        tl = t.tl
        m = M(t)
        for cid in BUILDERS[name](m):
            if tl.cur:
                tl.hold(0.3)
            tl.begin(cid)
        tl.hold(1.0)
    return take


def relaunch_fresh(label):
    udid = udid_for()
    env = dict(os.environ, SIMCTL_CHILD_OS3D_AGENT="1", SIMCTL_CHILD_OS3D_AGENT_PORT=BRIDGE_PORT,
               SIMCTL_CHILD_OS3D_RESET_STORE="1", SIMCTL_CHILD_OS3D_FRESH="1", SIMCTL_CHILD_OS3D_FRESH_NAME=label)
    subprocess.run(["xcrun", "simctl", "launch", "--terminate-running-process", udid, BUNDLE], env=env, capture_output=True)
    wait_document()
    time.sleep(1.0)


def dry(name, out):
    relaunch_fresh(name)
    t0 = time.time()
    m = M(None, dry=True)
    for cid in BUILDERS[name](m):
        log(f"-- {cid}")
    log(f"built in {time.time() - t0:.1f}s")
    for b in bodies():
        log(f"body {b['id'][:8]} vol={b['volumeMM3']:.0f} brep={b.get('brep')} "
            f"bounds={[[round(v, 1) for v in p] for p in b['bounds']]}")
    bad = [b for b in call("/v1/check")["bodies"] if not b["health"].get("valid")]
    log("check: " + ("ALL VALID" if not bad else f"INVALID {[b['id'][:8] for b in bad]}"))
    hero_shot(os.path.join(out, "dry.png"))


def fit_font(d, text, width, start, bold=True):
    size = start
    while size > 20 and d.textlength(text, font=font(size, bold)) > width:
        size -= 2
    return font(size, bold)


def thumbnail(video, hero, path):
    """1280×720: the finished model on the right, big title in a dark column on the left."""
    from PIL import Image, ImageDraw
    W_, H_ = 1280, 720
    bg = Image.new("RGB", (W_, H_), BG)
    im = Image.open(hero).convert("RGB")
    cw, ch = int(im.width * 0.86), int(im.height * 0.86)          # the model sits mid-frame
    im = im.crop(((im.width - cw) // 2, (im.height - ch) // 2, (im.width + cw) // 2, (im.height + ch) // 2))
    im = im.resize((int(cw * H_ / ch), H_), Image.LANCZOS)
    x0 = 880 - im.width // 2                      # model centre ~x 880
    bg.paste(im, (x0, 0))
    shade = Image.new("L", (W_, H_), 0)
    sd = ImageDraw.Draw(shade)
    for x in range(W_):
        sd.line([(x, 0), (x, H_)], fill=max(0, min(255, int(255 * (1.0 - (x - 480) / 150)))))
    bg = Image.composite(Image.new("RGB", (W_, H_), BG), bg, shade)
    d = ImageDraw.Draw(bg)
    ic = icon(84)
    bg.paste(ic, (56, 56), ic)
    d.text((156, 76), "OpenShape 3D", font=font(36, True), fill=FG)
    title, *rest = video["thumb"].split("\n")
    y = 220
    words, lines = title.split(), []
    # one or two lines of title, as big as fits 540 px
    if d.textlength(title, font=font(92, True)) <= 450 or len(words) == 1:
        lines = [title]
    else:
        k = max(range(1, len(words)), key=lambda k: -abs(len(" ".join(words[:k])) - len(" ".join(words[k:]))))
        lines = [" ".join(words[:k]), " ".join(words[k:])]
    f = min((fit_font(d, l, 450, 92) for l in lines), key=lambda f: f.size)
    for l in lines:
        d.text((56, y), l, font=f, fill=FG); y += int(f.size * 1.08)
    y += 14
    for l in rest:
        f2 = fit_font(d, l, 450, 46)
        d.text((56, y), l, font=f2, fill=ACCENT); y += int(f2.size * 1.2)
    d.rounded_rectangle([56, H_ - 116, 396, H_ - 56], radius=14, fill=ACCENT)
    d.text((80, H_ - 106), "iPad CAD · free", font=font(36, True), fill=(255, 255, 255))
    bg.save(path)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("video", choices=list(VIDEOS))
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--compose-only", action="store_true")
    ap.add_argument("--take-only", action="store_true")
    ap.add_argument("--thumb-only", action="store_true")
    a = ap.parse_args()
    v = VIDEOS[a.video]
    take_dir = os.path.join(S, "take-" + a.video)
    os.makedirs(take_dir, exist_ok=True)
    if a.dry:
        dry(a.video, take_dir)
        sys.exit(0)
    if a.thumb_only:
        thumbnail(v, os.path.join(take_dir, "hero.png"), os.path.join(OUT, f"openshape3d-{v['slug']}-thumbnail.png"))
        sys.exit(0)
    if not a.compose_only:
        def take(t, _f=make_take(a.video)):
            _f(t)
            hero_shot(os.path.join(take_dir, "hero.png"))
        run_take(a.video, v["script"], take, take_dir)
    if not a.take_only:
        synthesize(a.video, v["script"])
        os.makedirs(OUT, exist_ok=True)
        hero = os.path.join(take_dir, "hero.png")
        v = dict(v, hero=hero if os.path.exists(hero) else None)
        out = os.path.join(OUT, f"openshape3d-{v['slug']}.mp4")
        compose(a.video, v["script"], take_dir, v, out, v["series"])
        write_metadata(os.path.join(OUT, f"openshape3d-{v['slug']}-metadata.md"), v, v["script"], take_dir)
        if v.get("hero"):
            thumbnail(v, v["hero"], os.path.join(OUT, f"openshape3d-{v['slug']}-thumbnail.png"))
