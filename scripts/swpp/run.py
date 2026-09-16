#!/usr/bin/env python3
"""Run SOLIDWORKS practice problems against the live app.

    python3 scripts/swpp/run.py 1.1 1.9          # by number
    python3 scripts/swpp/run.py level:1          # every registered problem of a level
    python3 scripts/swpp/run.py all
    OS3D_KEEP_DOC=1 …                            # build into the open document

Problems register themselves in `levelN.py` modules via `PROBLEMS[pid] =
(meta, build)`; `meta` carries the sheet's volume and unit. Later rounds
that ran as parallel agents keep their recipes in `roundN_x.py` modules,
loaded after the levels.
"""
import glob, importlib, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kit  # noqa: E402

PROBLEMS = {}
_modules = [f"level{n}" for n in range(1, 19)]
_modules += sorted(os.path.splitext(os.path.basename(p))[0] for p in glob.glob(os.path.join(HERE, "round*.py")))
for name in _modules:
    try:
        mod = importlib.import_module(name)
    except ModuleNotFoundError as e:
        if e.name == name:   # the level module doesn't exist (there is no level9/level17)
            continue
        raise
    for pid in mod.PROBLEMS:
        if pid in PROBLEMS:
            raise SystemExit(f"problem {pid} is registered twice (again in {name}.py)")
    PROBLEMS.update(mod.PROBLEMS)


def _key(pid):
    a, b = pid.split(".")
    return (int(a), int("".join(ch for ch in b if ch.isdigit())), b)


def main():
    args = sys.argv[1:] or ["all"]
    selected = []
    for a in args:
        if a == "all":
            selected += sorted(PROBLEMS, key=_key)
        elif a.startswith("level:"):
            lv = int(a.split(":")[1])
            selected += sorted((p for p in PROBLEMS if int(p.split(".")[0]) == lv), key=_key)
        else:
            selected.append(a)
    fresh = os.environ.get("OS3D_KEEP_DOC") != "1"
    rows = []
    for pid in selected:
        if pid not in PROBLEMS:
            print(f"[SKIP] {pid}: no recipe registered")
            continue
        meta, build = PROBLEMS[pid]
        rows.append(kit.run_problem(pid, meta, build, fresh=fresh))
    passed = sum(1 for r in rows if r["status"] == "pass")
    print(f"\n{passed}/{len(rows)} passed")


if __name__ == "__main__":
    main()
