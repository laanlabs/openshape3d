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
