# App Store readiness audit

**Last verified: 2026-09-03** against `main` @ `f341924`. The ship-configuration
blockers from the original (2026-08-25 → 08-31) audit are **closed and verified
in a real signed archive**; what remains is listed under "Still open" and
"Untested". Re-verify with the commands in "How this was checked" before any
future submission — a build setting that was right once is not right forever.

## 1.2 update — verified 2026-09-14

- **iOS:** Release build of main (1.2 build 1) installed on the paired iPad
  and run by Jason through the week's fixes; the earlier upload was 1.1 (1)
  from the 2026-09-05 archive (set in Xcode, never committed — fixed in
  PR #33). Persisted schema unchanged since that archive's commit, so
  existing stores open without a migration. Full serial suite on the
  merged tree: unit 1613/1613 (1 skipped), UI 187 executed, 4 skipped,
  0 failures; a further run with the gizmo-test coordinates followed.
- **Mac (Catalyst):** `xcodebuild archive` for `generic/platform=macOS,
  variant=Mac Catalyst` succeeds with no flags once the project excludes
  x86_64 for macOS (the kernel's Catalyst slice is arm64-only; PR #34):
  arm64, `app-sandbox` + `files.user-selected.read-write`, category
  `public.app-category.graphics-design`, `LSMinimumSystemVersion` 14.0.
  The archived Release app runs sandboxed on this Mac: gallery → new
  design → Sketch → plane picker → rectangle by drag → Exit → Extrude by
  typing 3 + Return → a 15 mm³ body. Numeric fields on the Mac now start
  with the real keyboard, focused, and never raise the on-screen keypad
  (`AppSettings.prefersSystemKeyboard`).
- **Mac screenshots (2026-09-14):** three 1440 × 900 captures of the Debug
  Catalyst app (UI identical to Release) in `marketing/mac-screenshots/`
  (gitignored): the plate with its History panel, its dimensioned sketch
  head-on, and an extrude preview. Made by scripting the geometry over the
  bridge (`sketch.create` / `sketch.addEntities` / `feature.extrude` /
  `feature.fillet`), sizing the window to 1440 × 900 with AppleScript and
  capturing it with `peekaboo see --app openshape3d` (this Mac's display is
  1×, so 2880 × 1800 would need a Retina Mac). A Mac quirk seen on the way —
  the window title stayed "Settings" after the Settings sheet closed
  (Catalyst adopts a sheet's navigation title) — is fixed: the gallery and
  the editor own the window title (`MacWindowTitle`) and every sheet puts
  it back as it disappears.
- **iPad / iPhone screenshots (2026-09-14):** framed, captioned App Store
  images in `marketing/app-store/<device>/` (gitignored), made in two steps.
  `scripts/marketing_scenes.py wheel|plate|bottle` builds and colours each
  model over the DEBUG bridge (launch with `OS3D_FRESH_NAME` so the title
  is a real name); the touch-only states (dimensioned sketch, push/pull
  preview, History panel, Export menu) are posed by hand on top, captured
  with `simctl io screenshot` into `marketing/raw/<device>-<slug>.png`.
  `scripts/marketing_compose.py` then frames each on the icon's navy
  blueprint ground at the native size — iPad Pro 13-inch 2064 × 2752,
  iPhone 17 Pro Max 1320 × 2868, RGB — and writes `overview.png`. Shot
  list: hero (wheel + tyre), sketch, push/pull, history (mounting plate),
  revolve (bottle), export (wheel face-on under the Export menu). Both sets
  are done. On the iPhone, Zoom to Fit overfills the narrow screen (it
  sizes from the vertical FOV only), so each shot is re-framed by pinch and
  a two-finger pan, aimed with `GET /v1/project`; History and Export live
  under the toolbar's "…" menu. Shooting the iPhone wheel found the pinch
  zoom-out bug fixed alongside (STATUS, 2026-09-14). New bridge ops for
  this: `body.setMaterial`, `item.setHidden` (docs/AGENT_CONTROL.md).
- **Still to do by hand:** the App Store Connect listing (screenshots at the
  required sizes for iPad and Mac, what's new, privacy label = no tracking,
  no collection); the Mac upload needs a Mac App Store distribution
  profile in Organizer. Document types (below) remain undeclared.

## Verdict

**The build is submittable.** `xcodebuild archive` for `generic/platform=iOS`
succeeds, signs with the team's automatic profile, and produces a correct
33 MB arm64 bundle. The unit suite is green. The one genuine risk left is that
the app — a **custom Metal renderer** — has still never run on real hardware.

## Closed since the original audit (verified 2026-09-03)

All four ship-config items landed in `9a34aca` ("Ship config: privacy manifest,
iOS 17.0 floor, display name, encryption key"). Verified by reading the
`Info.plist` out of the signed archive, not from the project file:

| Was | Now | Verified how |
| --- | --- | --- |
| **BLOCKER: no `PrivacyInfo.xcprivacy`** | `openshape3d/PrivacyInfo.xcprivacy` declares `NSPrivacyTracking=false`, empty collected-data/tracking-domain arrays, and `UserDefaults` ▸ `CA92.1` | present in the archived bundle (924 B). It is picked up by the target's file-system-synchronized group — there is no `pbxproj` reference to break, but also none to protect it |
| **`MinimumOSVersion = 26.2`** — excluded essentially the whole installed base | `MinimumOSVersion = 17.0` | shipped `Info.plist`. (The 26.2 value survives on the *test* targets only, which never ship) |
| **No `CFBundleDisplayName`** — installed as "openshape3d" | `CFBundleDisplayName = "OpenShape 3D"` | shipped `Info.plist`. `CFBundleName` is still lowercase `openshape3d`; the display name is what the home screen and listing use |
| **No export-compliance key** — ASC asked the encryption question every upload | `ITSAppUsesNonExemptEncryption = false` | shipped `Info.plist` |

Two more original findings are also closed:

- **§5 "Debug hooks ship in the release binary" — closed.** `OS3D_DEBUG_SEED*`,
  `OS3D_FRESH`, `OS3D_AUTO_OPEN`, `OS3D_GIZMO_DEBUG` and the destructive
  `OS3D_RESET_STORE` are each inside `#if DEBUG`. Confirmed empirically:
  `strings` over the shipped binary finds **zero** `OS3D_*` symbols.
- **§1b "iPhone layout is broken" — closed.** `openshape3d/UI/AdaptiveBar.swift`
  gives the bottom bars a compact-width layout (horizontally scrollable rows,
  labels at natural width); 18 call sites across `EditorView` and
  `NumericInputBar` cover every contextual bar. `CompactWidthBarUITests` guards
  it, and `docs/screenshots/iphone-*.jpg` show the result. `TARGETED_DEVICE_FAMILY`
  stays `1,2` — the iPad-only fallback (option B) was not needed.

The **DEBUG agent bridge does not ship.** `openshape3d/Agent/*.swift` are each
wrapped in a single file-level `#if DEBUG`, both call sites
(`openshape3dApp.init`, `EditorView.onAppear/onDisappear`) are gated, and
`ENABLE_INCOMING_NETWORK_CONNECTIONS = YES` is set on the **Debug**
configuration only. Confirmed empirically: `strings` over the shipped binary
finds **zero** `AgentServer` / `AgentBridge` / `AgentRouter` / `v1/…` symbols.
Outside that bridge the app makes **no network calls at all** — no `URLSession`
anywhere in the target.

## Still open

### 1. No document type declarations (unchanged — not a blocker, real UX cost)

The app has its own `.os3d` format and imports STEP / STL / OBJ / DXF, but
declares no `CFBundleDocumentTypes`, `UTExportedTypeDeclarations` or
`UTImportedTypeDeclarations`. Consequences today:

- A user cannot open a `.os3d`, `.step` or `.dxf` file from Files or Mail into
  the app, and none of those types is registered to it.
- `UTType(filenameExtension:)` returns a **dynamic** type for each, and a picker
  filtered to a dynamic type matches no file. The importers work around it by
  also allowing `.data` (`EditorView.swift:208-219`,
  `ProjectGalleryView.swift:133`), so **the STEP, DXF and `.os3d` pickers show
  every file on the device** rather than the ones they can read.

**Sequencing:** this cannot be added while `GENERATE_INFOPLIST_FILE = YES` —
Xcode then ignores `INFOPLIST_FILE` and the keys never reach the bundle. Moving
the app target to a checked-in `Info.plist` is the actual first step. That is
why it is still open: it is a project-structure change, not a one-line key.

### 2. Fillet on a twisted solid (status unconfirmed)

The original audit found fillet tearing curved solids — failing destructively
instead of refusing. Blend work has landed since (`33baa83` stop the crash /
silent no-op, `de02de9` blends on a B-spline wall "build or refuse cleanly",
`88cf0dd` a TraceParts wheel fillet/chamfer stress test found no bug), so this
is **probably** fixed, but **the specific twisted-solid case was not re-run for
this audit**. Reproduce before relying on it: twist a solid, then fillet a
corner edge, and confirm it either blends or refuses — never tears.

### 3. App Store Connect material is not prepared

Nothing in the repo covers the listing side, and it is all still to do:
screenshots at ASC's required sizes, description, keywords, category, age
rating, and the privacy "nutrition label" (which must agree with the manifest:
no tracking, no collection). Note `docs/screenshots/*.jpg` are **README-sized**
(iPad 900×1200, iPhone 420×912) — usable as a shot list, not as submission
assets. `marketing/` is gitignored and does not exist in this checkout.

## Untested — read before submitting

| Untested | Why it matters |
| --- | --- |
| **Any real device** | Still the single biggest risk. The renderer is custom **Metal**; the Simulator's Metal is a different implementation, so shader behaviour, precision and performance all differ. A `Laan iPad Pro (11-inch, 3rd gen)` is paired and available on this machine — installing the archive on it is the highest-value remaining check. |
| **Export from the archive** | `archive` now verified; `-exportArchive` with a distribution profile, and the ASC upload itself, are not. |
| **iOS 17 at runtime** | 17.0 is compile- and archive-verified only. An API that compiles but is unavailable at runtime would crash on a real 17.x device. |
| **Import / export on device** | STEP was exercised end-to-end on the Simulator (2026-08-29). STL/OBJ/DXF/3MF/GLB have only had their menu entries opened, and nothing has been through a real device's file providers. |
| **Apple Pencil** | Implemented; the Simulator cannot test it. |
| **AR Quick Look** | Needs a device. |
| **Performance / memory on a heavy model** | Never profiled. |
| **Persistence across cold launch** | Testing leans on `OS3D_FRESH`, which starts empty and bypasses stored projects and any SwiftData migration path. Note `openshape3dApp.swift:43` still `fatalError`s if the `ModelContainer` fails to open — acceptable for 1.0 (no prior schema to migrate from), but it means a corrupted store is an unrecoverable launch crash. |

## Verified good (2026-09-03)

- **`ARCHIVE SUCCEEDED`** for `generic/platform=iOS`, Release, with automatic
  signing against team `34FWY7G2HB` and a real provisioning profile embedded.
- **Bundle**: 33 MB, single-arch **arm64**, `_CodeSignature` present,
  `default.metallib` compiled, `PrivacyInfo.xcprivacy` and `Assets.car`
  included, `embedded.mobileprovision` present.
- **Unit suite: 1263 tests, 0 failures, 1 skipped by design** (24 s, iPad Pro
  13-inch (M5) simulator, `-parallel-testing-enabled NO`).
- **App icon set complete**, and the 1024×1024 marketing icon has **no alpha
  channel** (`sips -g hasAlpha` → `no`) — the usual silent ASC rejection.
- **OCCT.xcframework has all three slices** — `ios-arm64`,
  `ios-arm64-simulator`, `ios-arm64-maccatalyst` — and all three static libs
  are **materialized through Git LFS** (~147 MB each), not left as pointers.
- **One third-party SPM dependency**: Euclid, MIT, pinned in a tracked
  `Package.resolved` to `0.8.18` / `be1096bc`.
- **No privacy usage strings needed.** `PhotosPicker` and `QLPreviewController`
  both run out-of-process.
- Only 6 `print(` calls in the whole target; one `fatalError` (above).

### Not a defect: the x86_64 simulator link failure

A Release build for `generic/platform=iOS Simulator` **fails to link x86_64**
("symbol(s) not found for architecture x86_64"). OCCT ships an arm64-only
simulator slice. The arm64 simulator slice and the arm64 device slice both link
fine, and nothing ships x86_64 — Apple Silicon simulators are arm64 and the
store build is device-only. Build simulator Release with
`-destination 'platform=iOS Simulator,name=<an arm64 sim>'` rather than
`generic/…` if you need it.

## How this was checked

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer   # this machine

xcodebuild -project openshape3d.xcodeproj -scheme openshape3d \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/openshape3d.xcarchive archive

plutil -p /tmp/openshape3d.xcarchive/Products/Applications/openshape3d.app/Info.plist
strings   /tmp/openshape3d.xcarchive/Products/Applications/openshape3d.app/openshape3d \
  | grep -E 'AgentServer|AgentBridge|OS3D_'        # must be empty
sips -g hasAlpha openshape3d/Assets.xcassets/AppIcon.appiconset/icon-ios-1024x1024.png

xcodebuild test -project openshape3d.xcodeproj -scheme openshape3d \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -parallel-testing-enabled NO -only-testing:openshape3dTests
```

The **UI suite was not re-run for this audit**. Its last full measurement is
2026-09-02 (`docs/STATUS_AND_NEXT_STEPS.md`): 104 executed, 2 skipped, 46m19s,
1 failure (`DragSolveUITests.testDragTopCornerKeepsHorizontalEdgeAndCoalesces`)
that passed clean in isolation — the documented long-run-flake pattern. That
predates the commits on `main` from 2026-09-03, so run it once more before
submitting.
