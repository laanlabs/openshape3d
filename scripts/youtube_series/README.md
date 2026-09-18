# YouTube tutorial series

Three narrated tutorials — **sketching**, **shapes**, **materials** — recorded
from the live app on a dedicated landscape iPad simulator and composed at
1920×1080 with a chapter panel, a neural-voice narration and a music bed.

    python3 tutorial.py sketching      # take + compose + metadata
    python3 tutorial.py shapes --compose-only
    python3 tutorial.py materials --take-only

Outputs land in `marketing/youtube/`: `openshape3d-tutorial-<name>.mp4` and
`openshape3d-tutorial-<name>-metadata.md` (title, description with chapter
timestamps, tags, thumbnail text). Takes and build products stay in
`take-<name>/` here (gitignored).

A fourth video, **"Design a 3D-printable flowerpot with Claude or ChatGPT"**,
has its own script:

    python3 ai_flowerpot.py [--take-only | --compose-only]

Its setup chapters are slides over the idle recording; the modelling is
`ai_flowerpot_session.json` — the tool calls a real Claude session made
through `scripts/mcp_openshape3d.py` (captured with `OS3D_MCP_LOG`) —
replayed over the bridge at narration pace, one panel per call. To re-record
the session, see `docs/AI_MODELING_SETUP.md` and rebuild the JSON from the log.

A fifth, **"Ask Claude for a 3D-printable part — no CAD needed"**, is for people
who installed the Mac app from the store. It is cut after the fact from real
material rather than paced live: `python3 ask_claude.py <material-dir>` (the
docstring lists the stills, the `screencapture -V -l` window recording and the
timed `claude -p … --output-format stream-json` transcripts it expects).

## Ten project tutorials

Ten follow-along projects, the classics of CAD tutorials on YouTube: coffee
mug, chess pawn & rook, LEGO-style brick, name keychain, twisted vase, bolt &
nut with threads, spur gears, fidget spinner, ice cube tray and a
print-in-place hinged box.

    python3 project_tutorial.py mug --dry     # build it on the running app, no video
    python3 project_tutorial.py mug           # take + compose + metadata + thumbnail
    ./batch.sh chess vase bolt                # several in a row, one log each
    python3 contact.py mug <video.mp4> sheet.png   # one frame per chapter, for review

`projects.py` holds one builder per video: a generator that yields a chapter
id, then performs that chapter's steps. The dry run and the recorded take run
the same builder, so the geometry in the video is the geometry that was
checked (`--dry` ends with `/v1/check` on every body). Modelling goes over the
bridge; the touches are real — Start a Blank Design, tap a sketch region and
type the height on the keypad, the Text tool (keychain), a Material preset,
Export ▸ STL/3MF through the save panel, History. Each touch has a bridge
fallback, so a missed gesture shows the same result instead of derailing the
take. `projects_text.py` has the narration, chapter panels and YouTube text.
Outputs: `openshape3d-<slug>.mp4`, `-metadata.md` and a 1280×720
`-thumbnail.png`; the title card shows the finished model (a `/v1/screenshot`
taken at the end of the take). Set `OS3D_VIDEO_OUT` to write them somewhere
other than this checkout's `marketing/youtube/`.

Gotchas met on the way:

- `view.<orientation>` animates; a `view.fit` sent straight after cancels the
  turn. `M.view` waits 0.8 s between them.
- A body built by touch stays selected (gizmo, blue tint over its material)
  until a tap on empty grid.
- The save panel loads out of process for a few seconds, and a second export
  of `Untitled.stl` raises "Replace Existing Items?" — `save_sheet` waits for
  Save, then answers Replace.
- A take that dies mid-way must stop `recordVideo` and the test, or the next
  take cannot record on that device (`run_take` now does it in `finally`).
- The mug handle's sweep fails ("tool solid is invalid") with a 48-segment
  path; 30 segments builds.
- The bridge has no text op: the keychain's letters come from the Text tool by
  touch, and their extrude seeds from rasterising the glyph loops
  (`glyph_seeds`).

## How a take works

- **Touches** are performed by `openshape3dUITests/TutorialTakeUITests`
  (skipped unless `TEST_RUNNER_OS3D_TUTORIAL_TAKE=1`), remote-controlled over
  HTTP on port 8930: palette taps by element identity, viewport taps/drags
  by normalised window coordinates, keypad entry for dimensions. The host
  turns world millimetres into screen positions with `GET /v1/project`.
- **Modelling and camera** go over the DEBUG bridge (port 8931).
- **Pacing**: each chapter starts a `Timeline` segment and holds until its
  narration clip (edge-tts, `common.VOICE`) has played; `compose()` places
  the clips at those offsets.
- **Recording**: `simctl io recordVideo` on the simulator; the framebuffer is
  portrait-framed with rotated content, `compose()` transposes it upright.

## Simulator

`os3d-video` (an iPad Pro 13-inch (M5), iOS 26.5), created with `simctl create`
and switched to **Full Screen Apps** by `VideoSimSetupUITests`
(`TEST_RUNNER_OS3D_SIM_SETUP=1`): a fresh iPadOS 26 simulator opens apps in
floating windows. Build into a private DerivedData (`OS3D_VIDEO_DD`) so runs
never collide with the UI suite's builds on the shared simulators.

## Files

- `common.py` — bridge, control server, timeline, TTS, compose, metadata
- `scripts_text.py` — narration, chapter panels, titles/descriptions/tags
- `tutorial.py` — the three takes
- `ask_claude.py` — the store-user video, cut from real screenshots and a Mac window recording
- `ai_flowerpot.py`, `ai_flowerpot_session.json` — the AI-modelling video and the session it replays
- `probe*.py` — the touch-flow probes used while writing the takes
- `project_tutorial.py`, `projects.py`, `projects_text.py`, `batch.sh`, `contact.py` — the ten project tutorials
