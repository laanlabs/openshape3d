# QA-53 — compact layout: extrude bar vs tool palette (2026-09-13)

Found while running CompactWidthBarUITests on an iPhone 17 Pro (iOS 26.5,
402×874 pt) for QA-45: `testExtrudeBarIsUsableAtCompactWidth` failed on the
branch — "The extrude bar is covering the tool palette's last entry" (Delete
not hittable). Three earlier runs today reproduced it.

## Measured geometry at failure (logged from the test)

- window 402×874; palette top entry at y 140; Delete at y 652–704 (44×52).
- Extrude button at y 738.7 (bar top ≈ 730); selection info strip (Area /
  Perimeter, a horizontal scroll view) at y 643–662, x 36–366, capsule ≈ 627–678.
- The bottom stack (strip + bar) measures ≈ 247 pt, so the palette's inset
  clips it at y ≈ 611. Nine model-mode entries at 52 pt each need 468 pt plus
  padding; only ≈ 487 pt are available above the stack — they cannot fit at
  any spacing. `ViewThatFits` therefore falls to the scrolling palette and
  Delete sits just below the clip edge: reachable by scrolling, not directly.

So the bar no longer *covers* the palette (the original 2026-09 defect: the
palette was overlapped and no scroll could reveal Delete); the branch's two
new palette entries (Axis, Material) simply pushed the column past what a
phone can show at once.

## Change

- `ToolPaletteView`: `ViewThatFits` now tries a tighter column (spacing 6,
  padding 10) before scrolling, so a compact screen shows every entry
  whenever it can (e.g. under the shorter primitive bar); iPad keeps its
  layout because the normal column still fits there. The scrolling variant
  carries the accessibility identifier `ToolPalette` — on the plain column the
  identifier collapsed the VStack into one accessibility element and hid every
  tool button (10/10 iPad UI failures, the a11y-container gotcha), so it lives
  on the scroll view only.
- `testExtrudeBarIsUsableAtCompactWidth`: when Delete is not directly
  hittable, the palette must exist as a scroll view and one swipe must make
  Delete hittable — the requirement is reachability, not a no-scroll fit.

Gate: CompactWidthBarUITests on iPhone 17 Pro 3/3 (extrude compact, extrude
landscape, primitive bar), one clean run
(/tmp/os3d-qa53-iphone2-20260913.xcresult); iPad smoke PlanesUITests +
ItemsUITests 8/8 before the identifier, PlanesUITests + SketchTransformUITests
10/10 after it moved to the scroll view. Fixed at 0cb0a2a.

## Open

- The compact check of the sketch Move/Rotate pills is now in place
  (testSketchTransformControlsAreUsableAtCompactWidth, 5/5): the earlier
  failures were the test's own extra tap deselecting the freshly drawn line.
- Native has no compact (phone) layout; this lane is clone-only by nature.
- Whether nine entries should instead reflow (two columns) on phones is a
  design choice not taken here.

Partial; no promotion. 32/0/1/23; iPad unchanged.
