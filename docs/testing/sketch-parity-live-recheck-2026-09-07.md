# Live recheck — September 7, 2026, 21:33 EDT onward

In-progress receipt; not iPad readiness or full parity sign-off.

## Environment

Branch `fix/sketch-parity-foundations`, starting clean at `5689ce6`. No competing Peekaboo/xcodebuild process found. Native Shapr3D and dedicated `os3d-parity-sept7` simulator operated serially via Peekaboo GUI bridge. Screenshots inspected after each interaction.

Installed clone executable SHA-256 matches `/tmp/os3d-parity-derived/Build/Products/Debug-iphonesimulator/openshape3d.app/openshape3d`: `21552e2f2939be35b9a9b01cacbfeb1d1df975e9280017269a3be9e85fc09e94`. This is the build used by the last anchor regression receipt; no source changes since that build.

## Completed line: paired live result

- Native: armed Line, dragged a horizontal line in existing test sketch. Release retains `350 mm` readout with no keypad. Explicit badge click opens numeric keypad displaying 350.
- Clone: armed Line, dragged a horizontal line in existing ground sketch. Release retains `3 mm` badge with no keypad. Explicit badge click opens numeric keypad displaying 3. Different zoom scales; this compares interaction lifecycle, not equal geometry size.
- Tested horizontal mouse-drag path passes retained-readout/no-auto-keypad behavior. Tap chain, other orientations, physical Pencil/touch and all placement cases are not covered by this result.
- Both keypads overlap nearby canvas in these placements; this alone does not establish an obstruction mismatch. Rectangle automatic opening and edge placement remain under investigation.

Evidence directory: `/Users/thelodgestudio/.openclaw/workspace/reports/openshape3d-live-comparison-2026-09-07/recheck-2133/` (paired `reference-line-release`, `reference-line-keypad`, `clone-line-release`, `clone-line-keypad` PNG and observation JSON).

## Status

Implemented: existing line/anchor changes. Regression-tested: prior receipts only, no new run this session. Live-compared: horizontal line release and explicit keypad opening. Documented: this local receipt. Google Docs publication: pending. Device readiness: not reached.

Next: fresh diagonal and center rectangle sequential width/height edits, paired reference captures; confirmed remaining keypad/two-axis workflow gaps.

## Fresh rectangle evidence and confirmed fixes in progress

- Diagonal: native 350 → 175 mm width keeps first corner at window pixel (1071,582); clone 3 → 1.5 mm keeps first corner at (180,698). Paired screenshots confirm the tested down/right quadrant. Other quadrants and sequential height remain separate acceptance.
- Native diagonal release exposes width and height without a keypad. Clone automatically opens width. Native keypad first digit changes selected 350 to 1; clone changes 3 to 31. Evidence `reference-first-digit` and `clone-diagonal-typed`.
- Native center height 180 → 90 mm retains center at approximately (532,187). Clone center release opens width automatically. After committing width unchanged, opening the right height badge places the keypad behind the constraint rail; its right keys and commit are hidden. Evidence `clone-center-height-keypad`. Clone center-height sign-off is blocked until this fix is verified.
- Implemented corrections awaiting tests/live recheck: axis-aligned drag/tap rectangle release retains both badges without auto editor; dimension-pad initial digit replaces seed (operator can extend seed for arithmetic); editor fits full measured card between side chrome instead of using a point-only system-keyboard clamp. Each edit gets a distinct UI session identity to reset input state.
- Initial build failed before tests due to a Swift Binding default initializer; corrected before second build/test attempt. Do not count it as a clean test run.

## Regression diagnosis and publication update

Combined v2 run: 18 passed, 2 failed (diagonal width badge opening, right-side height badge opening); all 11 geometry checks and 7 other UI checks passed. Diagnostic screenshot rerun repeats both failures. Native XCTest default taps chose padded badge edges; captured UI then enters new rectangle placement. Live Peekaboo center tap opens the width editor correctly. Outer control contentShape alone did not resolve either failure; rendered target surface is under test. This is not a successful regression batch.

Illustrated existing Doc updated with interim recheck prose and five images (paired line release, paired diagonal half-width, clone pre-fix height obstruction). Anonymous DOCX export verifies recheck prose and 21 inline images (16 original + 5 new). Local published-recheck.docx and publication.json retained in evidence directory. Post-fix live result publication remains pending.

## Corrected result — 22:08 EDT

Two explicit-center UI tests passed in `/tmp/os3d-keypad-center-target-20260907.xcresult`, zero skips/failures. Together with 18 unaffected passes in the combined run, 20 distinct checks passed across runs. NOT one clean combined run. Two diagnostic shape changes (outer contentShape, nearly transparent padded background) did not fix XCTest inferred-point taps and were removed; live Peekaboo center and padded-edge taps both opened the field. Tests now use visible badge-center coordinates. Broader hit-target/device verification remains open, not declared fixed by the test adjustment.

Fresh final-source live clone recheck: center rectangle release shows both badges with no keypad. Right height badge opens full keypad clear of the rail. First digit replaces 1 with 0; entering 0.5 and committing halves height; then width 2 → 1 produces 1 × 0.5 mm. Center remains approximately window pixel (462,336). Native paired new center rectangle 180 × 100 → 180 × 50 → 90 × 50 mm retains center (751,732). Native width readout needed reselection/tool interaction after the first commit; clone retains both badges. This is geometric/touch-keypad workflow agreement in tested cases, not identical command lifecycle or keyboard Tab/two-axis placement parity.

Final post-fix images: clone-fixed-center-release, clone-fixed-height-keypad, clone-fixed-first-digit, clone-fixed-center-half-height, clone-fixed-center-two-axis; native reference-center-two-axis-start, reference-center-second-halfheight, reference-center-two-axis-final. Ground plane, portrait clone, mouse-driven simulator only. Landscape/compact/left-handed/system keyboard placement and physical Pencil still pending. Three-point auto-keypad/height coverage is the next issue.

Post-fix publication verified: anonymous DOCX export has24 inline images (16 original +8 new), including native/clone center results and corrected height keypad. Saved post-fix prose verified. Local published-recheck.docx and publication.json updated. Final simulator executable SHA256: `9f07455e7d9a91fee48acec6302fc09c1b84eb680fb3c77467cd5509e906fa45`.
