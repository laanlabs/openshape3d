"""Contact sheet of a finished video: one frame per chapter (mid-chapter) plus title/outro."""
import json, os, subprocess, sys
from PIL import Image, ImageDraw
from common import TITLE_S, font
name, video = sys.argv[1], sys.argv[2]
tl = json.load(open(os.path.join("take-" + name, "timeline.json")))
times = [("title", 2.5)] + [(s["id"], TITLE_S + (s["start"] + s["end"]) / 2) for s in tl["segments"]]
times += [("end", TITLE_S + tl["total"] - 0.5), ("outro", TITLE_S + tl["total"] + 4)]
tiles = []
for label, t in times:
    p = os.path.join(os.environ.get('CS_TMP', '.'), f'cs-{name}-{label}.png')
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", f"{t:.2f}", "-i", video, "-frames:v", "1", "-vf", "scale=640:-1", p], check=True)
    tiles.append((label, t, Image.open(p).convert('RGB')))
cols = 3; w, h = 640, 360
sheet = Image.new("RGB", (cols * w, ((len(tiles) + cols - 1) // cols) * (h + 24)), (0, 0, 0))
d = ImageDraw.Draw(sheet)
for i, (label, t, im) in enumerate(tiles):
    x, y = (i % cols) * w, (i // cols) * (h + 24)
    sheet.paste(im, (x, y + 24)); d.text((x + 6, y + 2), f"{label} @ {t:.1f}s", font=font(18, True), fill=(255, 255, 0))
out = sys.argv[3] if len(sys.argv) > 3 else f"contact-{name}.png"
sheet.save(out); print(out)
