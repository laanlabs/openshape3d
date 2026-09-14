# QA54 Command Search Escape priority — September12,2026

Baselinec25e9d5/source1cb2c54. Native preference Hotkeys→Command Search
observed; bare l opens Search, settings reopen retains preference. Restored
Hotkeys, foreground keycode l activates Line. Text-only l injection did not arm
Line; foreground keycode did. Unknown `press l` invocation rejected before
input, excluded. Native foreground Escape dismisses Search and keeps Sketch12.

Clone Command Search selected through global Settings, foreground l opens
Search. Foreground Escape leaves Search/keyboard while exiting sketch, a
confirmed scope mismatch. Before-source real-key XCTest0/1 reproduces failure
at Search dismissal. New UI workflow preserves a one-line Undo step and checks
sketch remains active after Search Escape. No assertion relaxed.

Scoped correction suppresses editor Escape registration while Search active;
overlay close button retains its existing cancel shortcut. Focused five Search
UI tests currently running exclusively, /tmp/os3d-qa54-escape-focused-20260912.
No changed-build live claim yet. Native restoredHotkeys; clone CommandSearch.
Evidence folder keyboard/qa54-live-2026-09-12 in September8 milestone reports.
QA54 partial, inventory31/0/1/24. Reports1208/master38, publication pending.

Disk exhaustion resolved without removing evidence: eighteen byte-identical
DOCX duplicates replaced with hash-verified APFS copy-on-write copies, preserving
all paths/content. Free space327876608→5879795712bytes. Durable operation receipt
under constraint-types/qa37-anchor-live-2026-09-12/lock-closure. No Mac restart or
security changes. Immutable05be744/iPad unchanged.

## Changed-build reconciliation

Foreground Escape now closes Search and keyboard while remaining in the same
sketch with the same line (fixed-search-before/fixed-escape-after PNGs). The
field handles Escape directly and editor Escape routes to Search while active.
XCTest synthesized Escape still fails delivery: priority0/1 and field0/1 are
retained, not claimed as product success. The new test is explicitly renamed
testClosingSearchPreservesSketchAndGeometryHistory and uses the close control;
live foreground input supplies Escape proof. First all-Search run was2/5,
including Fillet and unavailable-Circle result failures still under diagnosis.
A fresh five-case control run is active in os3d-qa54-search-controls-20260912.

## Result-tap diagnosis

Search controls3/5: close/history, scrim and empty-results passed; Fillet and
unavailable Circle failed. Isolated Fillet0/1 retained result frame
(286,222.5,460,37.5), actual tap516/241.25, query fil, and screenshot.
Foreground desktop tap of the same visible row also dismissed Search without
arming Fillet. This is not a stale test coordinate. Native comparison ongoing.
Background Peekaboo type produced aaa; foreground typing into a fresh launcher
correctly produced fil. Those failed input attempts are excluded.

Native Search row Chamfer/Fillet - Auto enters the tool with no selection,
paired before/after captured. Clone equivalent row dismissed without entering
Fillet. Converted row to Button with combined accessibility and plain styling;
UI tests now address that button, retaining all original behavior assertions.
Focused five-case result-button run active; changed live and final gate pending.
New screenshots copied to durable QA54 folder; publication not yet attempted.

Button-only correction did not resolve result taps (five-case3/5 again).
NSLog trace run0/1 yielded no retained handler messages. A temporary file trace
is now diagnosing the closing handler; it must be removed before final gate.
No assertion changes beyond real Button query type; no acceptance promotion.

## Root cause corrected (supersedes hit-routing hypothesis)

Temporary file trace recorded `command sketch.circle`, proving the row handler
executed. CommandDispatch.runCommand then honored Single Key Action and opened
Search for the selected result's bare chord, returning true without performing
the command. runCommandFromSearch immediately closed it. Thus both failures
were dispatch defects under Command Search preference, not row hit interception.
Removed the unsuccessful Button experiment and all temporary trace code.
Explicit Search result execution now passes honoringSingleKeyAction:false;
hardware dispatch keeps its existing preference behavior. Existing five UI
workflows explicitly launch with Command Search via process-local defaults,
so this regression cannot hide behind a persisted Hotkeys preference again.
Current focused runner5951, os3d-qa54-dispatch-focused-20260912.

Corrected focused five Search UI cases pass5/5 on7b0e033 with CommandSearch
explicitly selected. Result dispatch, unavailable-command refusal, scrim, empty
results and close/history all passed together. Full combined keyboard gate
now running; changed-build paired repeat/publication still pending.

## Numeric regression uncovered by combined gate

Combined84/85; isolated numericUI0/1. Invalid12+ warning/recovery passed, valid
12+1 commit was falsely refused. Saved geometry has no constraints/dimensions,
A(-1.1494557857513428,1.0198372602462769),
B(0.3819158971309662,1.0198373794555664). New exact model0/1 reproduces;
direct solvertrace gives nonconverged200iterations/residual4.202656 and huge
transverse motion. The tiny Y derivative is amplified by diagonal damping.
Native exact13mm resize succeeded and toolbar-menu Undo restored original;
second attempted tiny edit did not open a field, excluded.
Fallback retries only stalled solves from original input with isotropic damping
and retains only a lower residual; successful original solves stay untouched.
Focused exactmodel/SolverCore/numericUI run active; no final solver pass yet.

Stalled-solver correction focused8/8 passed: exact arithmetic/model/history,
six solver-core cases and the full numericUI workflow. Expanded near-axis
matrix1/1 passed across horizontal/vertical, both tiny-slope signs, three scales
and free/fixed-start states. Existing conflict/refusal tolerances unchanged;
no diagnostic source remains. Final broad regression and changed live pending.

## Final current-source gate and changed live

Final broad serial run on43bbf06 passes252/252, zero failures/skips, exit0:
`/tmp/os3d-qa54-broad-final-20260912.xcresult` and summary/log siblings.
No runner. Earlier84/85 and focused8/8 plus1/1 are separate receipts, not
combined with this terminal count.

Changed build: Command Search selected, foreground letter opens Search;
Circle result executes and arms Circle. Foreground Escape closes only Search
and keyboard, retaining sketch and Circle. Unavailable Fillet in an empty
design leaves Search open with explicit feedback. Initial plane-entry sample
clicked a moving top bar before settling and left sketch; excluded from the
active-sketch comparison. The settled repeat passes.

Fresh free line2.236mm: keypad12+ refuses with syntax warning; append1 commits
13mm. Undo restores2.236; Redo restores13; gallery reopen and reselection show
the13mm expression annotation. Native exact13mm and Undo were observed at a
different scale; not a viewport/pivot parity claim. Command Search preference
persists across gallery reopen; Hotkeys restoration verified after the sheet
stops scrolling. First restoration click missed during settling and is excluded.

Nineteen hash-distinct screenshots inserted into illustrated report, one dated
note appended to master. Export verification pending against1208/master38.
Physical key/Pencil delivery remains QA52; XCTest synthetic Escape remains an
undelivered-input limitation, not counted as live proof. Inventory31/0/1/24.

## Publication verified and finite acceptance closed

Anonymous exports verify illustrated1227 unique media, nineteen new hashes each
exactly once, zero loss from1208; master38 unchanged, one heading in each report.
Durable `keyboard/qa54-live-2026-09-12/publication-verification.json` retains
export SHA256s, complete media inventories and predecessor proof; XML retained.
QA54 finite desktop recipe closes, inventory32/0/1/23. PhysicalQA52 remains open.
