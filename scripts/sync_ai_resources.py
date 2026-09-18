#!/usr/bin/env python3
"""Keep the three copies of the AI-modelling text identical, and build the
Claude Desktop extension.

Single sources:
  .claude/skills/model-openshape3d/SKILL.md   the modelling guide (minus frontmatter)
  openshape3d/Agent/MCPTools.json             the tool catalog the app serves

Derived (checked in, never edited by hand):
  openshape3d/Agent/ModelingGuide.md                      bundled in the app
  integrations/claude-desktop/server/tools.json           offline tool list for the extension
  openshape3d/Agent/OpenShape3D.mcpb                      the extension (a zip), bundled in the app

    python3 scripts/sync_ai_resources.py            # rewrite the derived files
    python3 scripts/sync_ai_resources.py --check    # exit 1 if any is stale (CI / tests)
"""
import io, os, sys, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXT = os.path.join(ROOT, "integrations", "claude-desktop")


def read(path, mode="r"):
    with open(os.path.join(ROOT, path), mode, **({} if "b" in mode else {"encoding": "utf-8"})) as f:
        return f.read()


def guide():
    text = read(".claude/skills/model-openshape3d/SKILL.md")
    if text.startswith("---"):
        text = text.split("---", 2)[2]
    return text.strip() + "\n"


def mcpb():
    """A deterministic zip (fixed timestamps, sorted names) so --check can compare bytes."""
    files = {"manifest.json": read("integrations/claude-desktop/manifest.json", "rb"),
             "icon.png": read("integrations/claude-desktop/icon.png", "rb"),
             "server/index.js": read("integrations/claude-desktop/server/index.js", "rb"),
             "server/tools.json": read("openshape3d/Agent/MCPTools.json", "rb")}
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for name in sorted(files):
            info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            z.writestr(info, files[name])
    return out.getvalue()


def derived():
    bundle = mcpb()
    return {"openshape3d/Agent/ModelingGuide.md": guide().encode("utf-8"),
            "integrations/claude-desktop/server/tools.json": read("openshape3d/Agent/MCPTools.json", "rb"),
            "openshape3d/Agent/OpenShape3D.mcpb": bundle}


if __name__ == "__main__":
    stale = []
    for path, want in derived().items():
        full = os.path.join(ROOT, path)
        have = open(full, "rb").read() if os.path.exists(full) else None
        if have != want:
            stale.append(path)
            if "--check" not in sys.argv:
                os.makedirs(os.path.dirname(full), exist_ok=True)
                with open(full, "wb") as f:
                    f.write(want)
    if "--check" in sys.argv and stale:
        sys.exit("stale: " + ", ".join(stale) + " — run scripts/sync_ai_resources.py")
    print("up to date" if not stale else "rewrote " + ", ".join(stale))
