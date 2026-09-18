# YouTube tutorial video

`take.py` records the tutorial on the landscape iPad simulator (`os3d-parity-sept7`,
bridge port 8921, taps via Peekaboo using `taps.json`, modelling over `/v1/exec`)
and writes `raw.mp4` + `timeline.json`. `compose.py` lays the take out at
1920x1080 beside a chapter panel, adds the title/outro cards, the Samantha
narration (`say -v Samantha -r 172`, one clip per `script.json` entry into
`tts/<id>.aiff`, lengths in `tts/durations.json`) and a music bed
(`music-bed.wav`, three Apple Loops from Chillwave "Dream State" layered and
looped with ffmpeg), ducked under speech.

    python3 take.py --out take
    python3 compose.py take/raw.mp4 take/timeline.json ../../marketing/youtube/openshape3d-cad-basics-tutorial.mp4

Needs the homebrew ffmpeg run with
`DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/Cellar/x265/4.1/lib` (the linked
libx265.215 is missing), and the simulator rotated to landscape (Simulator >
Device > Rotate Left with that window frontmost; the dev iPad sim ignores
rotation, the parity sim honours it). The framebuffer stays portrait-framed
with rotated content; `compose.py` transposes it upright. `simctl recordVideo`
is variable-frame-rate and ends at the last screen change, so `compose.py`
clones the last frame out to the timeline's end.

## Glass Bottle tutorial (real touch interactions)

`bottle/bottle_take.py` drives `openshape3dUITests/BottleTakeUITests` over a
tiny HTTP loop (port 8897): the test performs every gesture by element
identity or normalised window coordinate (line-chain taps, keypad entry,
palette buttons), the host paces the narration, reads the bridge (port 8921)
for camera moves and geometry, and measures tap targets from rotated
`simctl io screenshot`s (largest solid blue region = the front-plane tile /
the bottle in the top view; the selected orange centreline gives the pt/mm
scale after "Fit View"). Narration is Microsoft neural TTS via `edge-tts`
(`en-US-AndrewMultilingualNeural`, `--rate=-4%`), text in `bottle/script.json`.

    xcodebuild build-for-testing -scheme openshape3d -destination "platform=iOS Simulator,id=<parity sim>"
    python3 bottle/bottle_take.py bottle/take
    TUT_SCRIPT=bottle/script.json TUT_TTS=bottle/tts TUT_TTS_EXT=mp3 TUT_BUILD=bottle/build \
      TUT_TRANSPOSE=2 TUT_TITLE="Model a glass bottle" TUT_HEADER="Glass bottle tutorial" \
      python3 compose.py bottle/take/raw.mp4 bottle/take/timeline.json ../../marketing/youtube/openshape3d-glass-bottle-tutorial.mp4

Gotchas met on the way: `XCUIDevice.orientation = .landscapeLeft` rotates the
framebuffer the OTHER way from the Simulator menu (`transpose=2` / PIL
`ROTATE_90`); closing a line chain leaves the closing segment selected (do not
tap it again, that deselects); a tap 2 pt inside a filled profile picks the
fill, not its edge line, so the revolve-axis tap goes 1 pt outside and 40 pt
off the fill's centre; one typed dimension only stretches that line, so draw
and dimension the centreline first, Fit View, then draw the outline at the
measured scale; the view cube's blue face beats a bounding-box detector.

## Phone Stand tutorial (3D-printable)

`stand/stand_take.py` reuses the bottle host (same `BottleTakeUITests` loop, plus
its `drag:` and `key:` actions): base line dimensioned to 90, back line with the
`ConstraintRail-vertical` constraint dimensioned to 60, Fit View, then the
outline tapped at the measured pt/mm (the base line is re-measured as the
densest sketch-blue row after the second Fit View — the selected-line bbox is
shortened by the endpoint markers), extrude 70 via the Distance keypad, Plastic
Gloss, a 3 mm fillet on three long edges picked from the top view, a cable
slot sketched on the floor face (plane picker + face tap, rectangle drag,
Subtract, Distance −15 — the keypad's minus is the ± key), the Export menu,
History. The body detector for the top view masks out the top bars, palette
and constraints panel: the blue "Exit Sketching" pill otherwise skews the box.
