//
//  openshape3dApp.swift
//  openshape3d
//

import SwiftUI
import SwiftData

@main
struct openshape3dApp: App {
    init() {
        #if DEBUG
        // Opt-in control channel for the MCP bridge; no-op unless OS3D_AGENT is
        // set, so an ordinary debug run is unaffected. Release has neither this
        // code nor the sandbox entitlement it needs.
        AgentServer.shared.startIfRequested()
        #endif
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
            ProjectFolder.self,
            PersistedBody.self,
            PersistedSketch.self,
            PersistedPlane.self,
            PersistedAxis.self,
            PersistedImage.self,
            PersistedSymbol.self,
            PersistedFeature.self,
            PersistedVariable.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        #if DEBUG
        // Must run BEFORE the container opens — and this closure is the only
        // place that is true. A struct's stored-property initialisers run
        // ahead of `init()`, so wiping from there would be too late.
        Self.resetStoreIfRequested(at: modelConfiguration.url)
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    #if DEBUG
    /// Debug hook (`OS3D_RESET_STORE=1`): delete the SwiftData store before it
    /// is opened, so the app starts with ZERO projects.
    ///
    /// This exists for the UI suite. Every test launches with `OS3D_FRESH`,
    /// which creates a new document and never removes it, so the store grew by
    /// ~95 projects per full run — it was past 400 when this was written. That
    /// is not just clutter: a bigger store slows launch and save, which shifts
    /// focus and gesture timing, which is what turned fixed `sleep()`s and
    /// caret races into "only fails in the long serial run" flakes.
    ///
    /// It is DESTRUCTIVE and deliberately awkward to reach: `#if DEBUG` (so it
    /// cannot ship, matching the seed hooks) plus an explicit env var. Do not
    /// set it in a shell profile or a scheme you also use for real modelling —
    /// it deletes every saved design in that simulator or device.
    static func resetStoreIfRequested(at url: URL) {
        guard ProcessInfo.processInfo.environment["OS3D_RESET_STORE"] != nil else { return }
        // The sidecars are `<store>-wal` / `<store>-shm` (a suffix, not a path
        // extension), and leaving them behind next to a deleted store is how
        // you get a container that opens onto half-migrated garbage.
        let base = url.path
        for path in [base, base + "-wal", base + "-shm", base + "-journal"] {
            try? FileManager.default.removeItem(atPath: path)
        }
        print("[OS3D] OS3D_RESET_STORE: deleted the store at \(base)")
        // The UI suite shares one app container across launches, so a
        // preference one test flips — circular annotations, snap-to-grid,
        // the anchored-entity order, the palette side — leaks into every
        // later launch and makes the long serial run fail in ways the same
        // test passes alone (2026-09-13: "R1 mm" for "Ø1 mm", a symmetry
        // rail disabled). Start from the shipped defaults as well. Launch
        // arguments (`-os3d.snapToGrid NO`) live in the argument domain and
        // still apply; a test that relaunches WITHOUT this flag keeps what it
        // set, which is what the persistence tests check.
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            print("[OS3D] OS3D_RESET_STORE: reset the \(domain) defaults")
        }
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ThemedRoot()
                .macWindowSizing()
        }
        .modelContainer(sharedModelContainer)
    }
}

private extension View {
    /// Mac Catalyst: give the window a sensible floor and opening size.
    ///
    /// A Catalyst window is freely resizable, and this is a CAD app — squeezed
    /// below iPhone width the bottom bars collapse into their stacked compact
    /// layout and the tool palette starts scrolling, which on a desktop reads
    /// as breakage rather than adaptation. The floor is just above the compact
    /// breakpoint so the regular-width layout always holds.
    @ViewBuilder
    func macWindowSizing() -> some View {
        #if targetEnvironment(macCatalyst)
        onAppear {
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene,
                      let restrictions = windowScene.sizeRestrictions
                else { continue }
                // Floor only — `maximumSize` is left at its default so the
                // window can still be zoomed to fill a large display.
                restrictions.minimumSize = CGSize(width: 900, height: 620)
            }
        }
        #else
        self
        #endif
    }
}

/// Applies the user's theme preference app-wide; a separate view so the
/// `@Observable` settings read is tracked and re-themes live.
private struct ThemedRoot: View {
    private var settings = AppSettings.shared

    var body: some View {
        ProjectGalleryView()
            .preferredColorScheme(settings.theme.colorScheme)
    }
}

#if DEBUG
/// Wall-clock marks for the document-open path (2026-09-13 iPad report:
/// "any drawing takes a second or two to open"). Prints only; read them
/// over `devicectl device process launch --console`.
enum OpenTiming {
    nonisolated(unsafe) static var t0: CFAbsoluteTime = 0
    /// Quiet unless OS3D_OPEN_TIMING is set, so ordinary Debug runs and the
    /// UI suite's logs stay as they were.
    nonisolated(unsafe) static let enabled = ProcessInfo.processInfo.environment["OS3D_OPEN_TIMING"] != nil
    static func reset(_ label: String) {
        guard enabled else { return }
        t0 = CFAbsoluteTimeGetCurrent()
        print("[OS3D][open]     0.0 ms  \(label)")
    }
    static func mark(_ label: String) {
        guard enabled else { return }
        let now = CFAbsoluteTimeGetCurrent()
        if t0 == 0 { t0 = now }
        print(String(format: "[OS3D][open] %7.1f ms  %@", (now - t0) * 1000, label))
    }
}
#endif
