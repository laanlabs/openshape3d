---
name: drive-openshape3d
description: Drive the openshape3d CAD app from Claude — launch it on the iOS Simulator, Mac Catalyst, or a physical iPad, then read editor state, run named commands, and capture the viewport over its DEBUG loopback bridge. Use when asked to run, drive, control, or visually check openshape3d, to reproduce a modeling bug in the live app, or to confirm a change works outside the test suite.
---

# Driving openshape3d

The app ships a DEBUG-only HTTP control channel on `127.0.0.1:8787`
(`openshape3d/Agent/`). It is compiled out of Release entirely, binds loopback
only, and does nothing unless `OS3D_AGENT` is set. Protocol reference:
`docs/AGENT_CONTROL.md`.

You need no MCP server here — `curl` is the whole client.

## 1. Is it already running?

Always probe first. It costs nothing and tells you which environment is live.

```bash
curl -s -m 2 http://127.0.0.1:8787/v1/health
```

`{"ok":true,…,"platform":"simulator","hasDocument":true}` means you can go
straight to work. `hasDocument:false` means the project gallery is on screen and
the editor endpoints will answer 409 — open a project, or relaunch with
`OS3D_FRESH=1`. Connection refused means nothing is running: launch it.

## 2. Launching

### iOS Simulator (default — matches the rest of this repo's dev loop)

The simulator shares the Mac's network stack, so the app's loopback port is your
loopback port. Nothing to forward.

UDIDs are machine-specific — resolve by device name, never hardcode one. If
`xcrun` cannot find `simctl`, `xcode-select` points at CommandLineTools; set
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` for every call.

```bash
UDID=$(xcrun simctl list devices available | grep -F "iPad Pro 13-inch (M5) (" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
xcodebuild build -scheme openshape3d -destination "platform=iOS Simulator,id=$UDID" -quiet
xcrun simctl install "$UDID" ~/Library/Developer/Xcode/DerivedData/openshape3d-*/Build/Products/Debug-iphonesimulator/openshape3d.app
SIMCTL_CHILD_OS3D_AGENT=1 SIMCTL_CHILD_OS3D_FRESH=1 xcrun simctl launch "$UDID" com.laan.labs.openshape3d
```

**Do not launch with `--console-pty &` from a tool call.** When the call ends its
process group is killed, the pty closes, and the app dies with it — you get
"connection refused" a minute later and waste a turn thinking the bridge broke.
A plain `simctl launch` survives indefinitely. You rarely need the console
anyway: `/v1/state` is better than reading `print()` output.

Then poll for the listener rather than guessing a sleep — it takes ~2s:

```bash
for i in $(seq 1 20); do curl -sf -m 1 http://127.0.0.1:8787/v1/health >/dev/null && break; sleep 1; done
```

### Mac Catalyst

Two silent failure modes, both documented at length in `AgentServer.swift`:

```bash
launchctl setenv OS3D_AGENT 1 && open /path/to/openshape3d.app && launchctl unsetenv OS3D_AGENT
```

It **must** go through LaunchServices. Exec'ing `Contents/MacOS/openshape3d`
directly gives the app no entitlement context, `listen()` silently never takes
effect, and `NWListener` still reports `.ready`. Diagnostic:
`lsof -nP -iTCP -a -p <pid>` shows `(CLOSED)` instead of `(LISTEN)`.

### Physical iPad

The device's `127.0.0.1` is not the Mac's. Forward it over USB:

```bash
brew install libimobiledevice   # once
iproxy 8787 8787 &
```

`xcrun devicectl` has no port-forward verb — `iproxy` (usbmuxd) is the route.
Set `OS3D_AGENT` in the scheme's environment, since there is no `SIMCTL_CHILD_`
equivalent for a device launch.

## 3. Working

### Discover the vocabulary before guessing at it

```bash
curl -s http://127.0.0.1:8787/v1/commands | jq '.commands[] | {id, title}'
```

This lists only commands that actually reach the editor (38 of a wider ~60-entry
catalog). Ids you invent, or ids from the catalog that have no entry point yet,
are refused with distinct errors — see below.

### Read state

```bash
curl -s http://127.0.0.1:8787/v1/state | jq
```

Gives mode, selection, every body with `volumeMM3` and whether it is still
analytic (`brep`), undo/redo availability, `measurements` — the exact rows
the human sees in the bottom info bar — and, when any feature failed to
replay, `evalErrors` (feature name + error per failing node). **Assert on
`volumeMM3`, not on a screenshot.** A picture cannot tell you a boolean
silently produced a 0 mm³ body.

### Check geometry health / capture a repro

```bash
curl -s "http://127.0.0.1:8787/v1/check?bop=1" | jq '.invalid, .bodies[].health.findings'
curl -s -X POST http://127.0.0.1:8787/v1/capture -d '{"note":"what looks wrong"}'
```

`/v1/check` is the first move when a rebuild LOOKS wrong: named per-subshape
faults ("Face3: notClosed"), tolerances, free boundary loops, volumes; `bop=1`
adds the slow self-intersection pass. `/v1/capture` snapshots every analytic
body into a replayable bundle (failed kernel ops write one automatically);
pull bundles with `scripts/fetch_captures.sh`. Workflow:
`docs/KERNEL_DEBUG_TOOLING.md`.

### If the bridge answers nonsense

Port 8787 may be held by an unrelated local service (it is on this machine —
`curl -v` showing `Server: BaseHTTP/Python` is the tell; the app then binds
IPv6 only). Launch with `SIMCTL_CHILD_OS3D_AGENT_PORT=8899` and curl that
port instead.

### Run a command

```bash
curl -s -X POST http://127.0.0.1:8787/v1/command -d '{"id":"view.isometric"}'
```

Four outcomes, deliberately distinguishable — do not retry blindly on failure:

| Response | Meaning | What to do |
|---|---|---|
| `200 {"ran":true}` | It ran | Continue |
| `200 {"ran":false,"reason":"not_applicable"}` | Right id, wrong editor state | Read the `message` — it names the mode and selection count. Fix the state first |
| `400 unknown_command` | No such id | You typo'd. `GET /v1/commands` |
| `400 unrouted_command` | In the catalog, no entry point in this build | Not a bug and not fixable from here. Use another route |
| `409 no_document` | Gallery is on screen | Open a project |

### See it

```bash
curl -s "http://127.0.0.1:8787/v1/screenshot?w=900&h=700" -o /tmp/os3d.png
```

Renders the viewport straight out of the app, so it works identically on
Catalyst and on a device where `simctl io screenshot` does not exist. **Sleep
~1s after any camera command** (`view.*`) before capturing — standard views
animate, and a shot taken immediately catches the camera mid-flight, which looks
exactly like the command having failed.

## 4. Getting to a known state fast

Seeding beats driving the UI. All are `#if DEBUG`, prefix `SIMCTL_CHILD_` for
`simctl`, and the full table is in `docs/STATUS_AND_NEXT_STEPS.md`:

| Var | State it lands you in |
|---|---|
| `OS3D_FRESH=1` | A brand-new empty document (almost always want this) |
| `OS3D_DEBUG_SEED=1` | 4 mm box, selected — 64 mm³ |
| `OS3D_DEBUG_SEED_HOLE=1` | 10×10×6 box, Ø4 through-hole (524.62 mm³) — the only seed with a cylindrical face |
| `OS3D_DEBUG_SEED_STEP=1` | Stepped block — the parallel-face pair Replace Face needs |
| `OS3D_DEBUG_SEED_CYLINDER=1` | True analytic cylinder through OCCT |
| `OS3D_RESET_STORE=1` | **Destructive.** Wipes every saved project in that simulator |

## 5. Building geometry

`runCommand` only **arms** the interactive tools. To BUILD — "extrude this
profile 12 mm", "shell it", "fillet that edge", "export an STL" — use
`POST /v1/exec` and `GET /v1/export`: the `model-openshape3d` skill
(`.claude/skills/model-openshape3d/SKILL.md`) is the op reference, with the
coordinate conventions and the verify loop. Driving the simulator UI directly
(`mcp__Claude_Code_iOS_Simulator__control`) is for when the UI itself is what
you are testing.

Never suggest turning this on in Release. It is DEBUG-only by design, and the
sandbox entitlement it needs is set on the Debug configuration only.
