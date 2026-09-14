//
//  CommandDispatchTests.swift
//  openshape3dTests
//
//  Guards the routing table in CommandDispatch.swift. Pure statics only — no
//  `EditorViewModel`, because that owns a `DocumentSession` and an in-process
//  `ModelContainer` crashes XCTest (STATUS_AND_NEXT_STEPS gotcha 1). The
//  switch itself is covered by the UI suite.
//

import XCTest
@testable import openshape3d

final class CommandDispatchTests: XCTestCase {

    /// Every routable id must name a real catalog entry — a typo here would
    /// otherwise register a shortcut that dispatches to `default:` and does
    /// nothing.
    func testEveryRoutableIDExistsInTheCatalog() {
        for id in CommandRegistry.routableIDs {
            XCTAssertNotNil(CommandRegistry.command(inCatalog: id),
                            "routableIDs names \(id), which is not in the catalog")
        }
    }

    /// The whole point of the change: the tutorials' sketch hotkeys reach the
    /// editor. C/A/L/R/T/G were dead before CommandDispatch existed.
    func testTutorialSketchHotkeysAreRoutable() {
        let expected: [String: String] = [
            "c": "sketch.circle",
            "a": "sketch.arc",
            "l": "sketch.line",
            "r": "sketch.rectangle",
            "t": "sketch.text",
            "g": "sketch.polygon",
        ]
        for (key, id) in expected {
            let command = CommandRegistry.command(inCatalog: id)
            XCTAssertEqual(command?.chord, KeyChord(key), "\(id) should be bare '\(key)'")
            XCTAssertTrue(CommandRegistry.routableIDs.contains(id), "\(id) should be routable")
        }
    }

    /// Chorded commands split cleanly into routable and not; nothing is both,
    /// and together they account for every chord in the catalog.
    func testChordedCommandsPartitionIntoRoutableAndUnrouted() {
        let chorded = Set(CommandRegistry.all.filter { $0.chord != nil }.map(\.id))
        let routable = Set(CommandRegistry.routableChordedCommands.map(\.id))
        let unrouted = Set(CommandRegistry.unroutedChordedCommands.map(\.id))

        XCTAssertTrue(routable.isDisjoint(with: unrouted))
        XCTAssertEqual(routable.union(unrouted), chorded)
    }

    /// Pins the known gaps so adding a chord without routing it fails loudly
    /// rather than shipping a key that quietly does nothing. Update this list
    /// deliberately — shrinking it is the goal.
    func testUnroutedChordsAreTheKnownGaps() {
        XCTAssertEqual(CommandRegistry.unroutedChordedCommands.map(\.id), [
            // app.commandSearch / app.commandSearchAlt left this list on
            // 2026-08-29 — the launcher exists now and X / ⌘F open it.
            "edit.selectAll",             // no select-all entry point yet
            "project.importAsNew",
            "project.importIntoCurrent",
            "project.new",
            "sketch.image",               // Insert Image is not a sketch tool here
        ])
    }

    /// No two routable commands may claim the same chord — duplicates would
    /// make which one fires an ordering accident.
    func testRoutableChordsAreUnique() {
        let chords = CommandRegistry.routableChordedCommands.compactMap(\.chord)
        XCTAssertEqual(Set(chords).count, chords.count)
    }

    /// Single Key Action gating is what keeps a bare letter from firing when
    /// the user has chosen the launcher reading (spec §8.4).
    func testBareKeysAreSuppressedUnderCommandSearchPreference() {
        let hotkeys = CommandRegistry(singleKeyAction: .hotkeys)
        let launcher = CommandRegistry(singleKeyAction: .commandSearch)

        XCTAssertEqual(hotkeys.command(for: KeyChord("c"))?.id, "sketch.circle")
        XCTAssertNil(launcher.command(for: KeyChord("c")))

        // Modified chords are unaffected either way.
        XCTAssertEqual(launcher.command(for: KeyChord("z", .command))?.id, "edit.undo")
    }
}
