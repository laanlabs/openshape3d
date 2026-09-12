# Manual circle diameter label positioning — September 9, 2026

Baseline7945b18 pushed. Native Front freecircle947517/Ø2000: drag label962374
(global1061453) to850450(global949529) rotates outside leader; circlecenter and
size unchanged. Blank/reselect resets free label to vertical. Clone Top driven
circle514620/Ø1: label500487 drag toward390540 leaves label fixed (no keypad or
geometry mutation). Paired difference captured via Peekaboo; logs and screenshots
under workspace report transform-controls.

Native typed1000 inspected/committed, circlecenter947517 stays; first drag after
commit only dismissed unselected readout, excluded. Reselect then drag label
962390→850450 rotates leader, sizeØ1000 unchanged. Blank/reselect retains moved
position. CmdZ/reselect restores vertical without changingØ1000; CmdShiftZ/reselect
restores diagonal. ExitSketch/Home/reopen/refit/Front/reselect retains diagonal
leader andØ1000, center964529. Trial skipped via AX; first Cmd2 ignored, second
works as in earlier reopen samples. No new input-delivery blanket claim.

Implementation: free candidate offset transient/cleared on selection change;
stored diameter has optional Codable labelOffset relative to circle center in
sketch-plane units. Stored placement uses independent UpdateSketchDimensionCommand
without solving/rebuilding geometry. Numeric commit inherits transient offset;
project merge preserves metadata. Missing field decodes nil for older files.
Head-on label drag uses matching annotation target/preview and projected basis
inversion; tapped label still opens editor. Manual rotated leader retains full
diameter/external arrowheads. Oblique/manual placement and other dimension kinds
remain outside this scoped change, not silently passed.

Serial13794 owns simulator: /tmp/os3d-circle-label-drag-20260909.log/.xcresult.
Layout4 + ConstraintApply20 + circle/near-railUI2 requested. Tests/live/publication
pending; no implemented-only success claim. No duplicate desktop/build/watchdog.

Initial13794: 24 unit + existingcircleUI passed; newdragUI passed movement,
unchangedØ1, noautoeditor and independentUndoRedo, then failed top-rim reselection
at logical804.96825.6. Exactvideo frame39 confirms unselected state (earlier
nonzero-tolerance extracted frames misleadingly returned preceding keyframe).
Live gallery reopen retained movedØ1label; top514580 and left475620 reselect both
worked. No selection-code change supported. Focused test now uses inspectedleft
rim (.715,.65), away from radial control region; keep original failure explicit.
Native diagnosis images inserted into illustrated Doc; export verification pending.

Focused2679 also failed left-rim reselection after passing drag/history. Live
left/top stillwork. Diagnostic now requires label disappearance and1second
settle before reselect, with before/after captures; no pass assumption.

Settled81814 target passed1/1: require label disappearance +1second before left
reselect, then moved label/keypad pass. No selection-code change.26distinctpass
across initial/targetedruns, not one clean run; rapid successive touch selection
not signed off by this settled sequence. No temporary trace code introduced.

Final fresh live clone Front check (01:50–01:53): circle center430450 Ø0.992.
Label450438 dragged toward350350 rotates leader without geometry/keypad changes;
blank249702, settle1sec, left390450 reselect resets free placement. Redrag then
explicit label tap opens pad; inspected1 then commit inherits moved placement.
Driven label358343 dragged to300470 leaves center/Ø1 unchanged. Toolbar237118
Undo restores previous diagonal placement;280118Redo plus blank/reselect retains
new nearly-horizontal placement. Gallery51,118→firstcard260210→Items→Sketch1icon
487222→close→left390450: Ø1 and moved leader retained. Paired native final reopen
already retains Ø1000 and driven diagonal leader. Different zoom/unit scales.
Screenshots os3d-circle-label-fresh-{drag,reset,driven,driven-moved,undo,redo-reselected,reopen-final}.png
retained in report transform-controls. No runner active. Postfix publication underway.

Final publication: illustrated121 embedded images, all3 new postfix PNG hashes
match anonymous DOCX export; master38 final gallery-reopen addendum verified.
Local DOCX evidence retained. No running build/test/desktop child worker.
