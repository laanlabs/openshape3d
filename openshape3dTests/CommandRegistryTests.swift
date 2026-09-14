//
//  CommandRegistryTests.swift
//  openshape3dTests
//
//  Spec §8.4 — hotkeys and Command Search. The spec names two exact launcher
//  behaviours ("p3" → "Add Plane - 3 Points", "snu" → "Scale - Non-uniform")
//  and one pair of commands that must NOT collapse into each other (import into
//  the current project vs import as a new one). Those are the tests that matter;
//  the rest guard the catalog against ambiguity.
//

import XCTest
@testable import openshape3d

final class CommandRegistryTests: XCTestCase {

    private let registry = CommandRegistry()

    // MARK: Command Search — the spec's own examples

    func testFuzzySearchFindsAddPlaneThreePointsFromP3() throws {
        let hit = try XCTUnwrap(registry.search("p3").first)
        XCTAssertEqual(hit.title, "Add Plane - 3 Points")
    }

    func testFuzzySearchFindsScaleNonUniformFromSnu() throws {
        let hit = try XCTUnwrap(registry.search("snu").first)
        XCTAssertEqual(hit.title, "Scale - Non-uniform")
    }

    func testWordStartMatchesOutrankMidWordOnes() throws {
        // "sb" hits two word starts in "Split Body"; in "Subtract" the b is
        // buried mid-word. Initials are how people actually type here.
        let hit = try XCTUnwrap(registry.search("sb").first)
        XCTAssertEqual(hit.title, "Split Body")
    }

    func testEquallyScoringMatchesPreferTheMoreSpecificTitle() throws {
        // "ex" opens both "Export" and "Extrude" at the very start, so the
        // scores tie; the shorter title has less unmatched text.
        let hits = registry.search("ex").prefix(2).map(\.title)
        XCTAssertEqual(Set(hits), ["Export", "Extrude"])
        XCTAssertEqual(hits.first, "Export")
    }

    func testAQueryThatIsNotASubsequenceReturnsNothing() {
        XCTAssertTrue(registry.search("zzqq").isEmpty)
    }

    func testSearchIsCaseInsensitive() {
        XCTAssertEqual(registry.search("FILL").first?.title,
                       registry.search("fill").first?.title)
    }

    // MARK: Recents

    func testEmptyQueryShowsRecentsMostRecentFirst() {
        var registry = CommandRegistry()
        registry.markUsed("model.fillet")
        registry.markUsed("sketch.circle")

        XCTAssertEqual(registry.search("").map(\.id),
                       ["sketch.circle", "model.fillet"])
    }

    func testReusingACommandMovesItToTheFrontWithoutDuplicating() {
        var registry = CommandRegistry()
        registry.markUsed("model.fillet")
        registry.markUsed("sketch.circle")
        registry.markUsed("model.fillet")

        XCTAssertEqual(registry.recentIDs, ["model.fillet", "sketch.circle"])
    }

    func testRecentsAreCapped() {
        var registry = CommandRegistry()
        for command in CommandRegistry.all.prefix(20) { registry.markUsed(command.id) }
        XCTAssertEqual(registry.recentIDs.count, CommandRegistry.recentsLimit)
    }

    func testEmptyQueryWithNoHistoryShowsNothingRatherThanEverything() {
        XCTAssertTrue(CommandRegistry().search("").isEmpty)
    }

    // MARK: Scoping

    func testPreSelectionScopesResults() {
        let all = registry.search("m")
        let sketchOnly = registry.search("m", scope: .sketch)
        XCTAssertLessThan(sketchOnly.count, all.count)
        XCTAssertTrue(sketchOnly.allSatisfy { $0.category == .sketch })
    }

    // MARK: Hotkeys

    func testSketchAndModelingHotkeysMatchTheSpec() {
        let expected: [String: String] = [
            "a": "Arc", "c": "Circle", "g": "Polygon", "l": "Line",
            "o": "Offset", "r": "Rectangle", "t": "Text",
            "e": "Extrude", "f": "Fillet", "h": "Shell", "m": "Move / Rotate",
            "n": "Chamfer", "p": "Project", "s": "Sweep", "v": "Revolve",
            "w": "Loft",
        ]
        for (key, title) in expected {
            XCTAssertEqual(registry.command(for: KeyChord(key))?.title, title,
                           "hotkey \(key.uppercased())")
        }
    }

    func testBooleanAndEditChords() {
        XCTAssertEqual(registry.command(for: KeyChord("u", .command))?.title, "Union")
        XCTAssertEqual(registry.command(for: KeyChord("b", .command))?.title, "Subtract")
        XCTAssertEqual(registry.command(for: KeyChord("z", .command))?.title, "Undo")
        XCTAssertEqual(registry.command(for: KeyChord("z", [.command, .shift]))?.title, "Redo")
        XCTAssertEqual(registry.command(for: KeyChord("a", .command))?.title, "Select All")
    }

    /// Undo and Redo differ only by Shift — a modifier-blind lookup would make
    /// Redo unreachable.
    func testModifiersArePartOfTheChordIdentity() {
        XCTAssertNotEqual(registry.command(for: KeyChord("z", .command))?.id,
                          registry.command(for: KeyChord("z", [.command, .shift]))?.id)
    }

    /// The spec calls these out as DISTINCT commands.
    func testImportIntoCurrentAndImportAsNewAreSeparateCommands() {
        let intoCurrent = registry.command(for: KeyChord("i", [.command, .shift]))
        let asNew = registry.command(for: KeyChord("i", [.command, .option]))
        XCTAssertEqual(intoCurrent?.id, "project.importIntoCurrent")
        XCTAssertEqual(asNew?.id, "project.importAsNew")
    }

    func testViewChordsCoverCommandOneThroughSeven() {
        for digit in 1...7 {
            XCTAssertNotNil(registry.command(for: KeyChord("\(digit)", .command)),
                            "Cmd+\(digit) should be a view command")
        }
    }

    func testSpaceIsBoundToZoomToSelection() {
        XCTAssertEqual(registry.command(for: KeyChord("space"))?.id,
                       "sketch.onHoveredPlane")
    }

    func testNoTwoCommandsShareAChord() {
        let chords = CommandRegistry.all.compactMap(\.chord)
        XCTAssertEqual(Set(chords).count, chords.count,
                       "a duplicated chord makes one of the two unreachable")
    }

    func testCommandIDsAreUnique() {
        let ids = CommandRegistry.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    // MARK: Single Key Action

    func testSingleKeyActionCommandSearchDisablesBareLetterHotkeys() {
        let searchMode = CommandRegistry(singleKeyAction: .commandSearch)
        XCTAssertNil(searchMode.command(for: KeyChord("e")),
                     "a bare letter is launcher input in this mode, not a hotkey")
        XCTAssertEqual(searchMode.command(for: KeyChord("z", .command))?.title, "Undo",
                       "chords WITH modifiers still fire")
    }

    func testSingleKeyActionHotkeysIsTheDefault() {
        XCTAssertEqual(CommandRegistry().singleKeyAction, .hotkeys)
        XCTAssertEqual(CommandRegistry().command(for: KeyChord("e"))?.title, "Extrude")
    }

    // MARK: Cheat sheet + labels

    func testCheatSheetGroupsOnlyBoundCommands() {
        let sheet = CommandRegistry.cheatSheet
        XCTAssertFalse(sheet.isEmpty)
        for (_, commands) in sheet {
            XCTAssertTrue(commands.allSatisfy { $0.chord != nil })
        }
    }

    func testChordLabelsReadLikeAMenu() {
        XCTAssertEqual(KeyChord("z", [.command, .shift]).label, "⇧⌘Z")
        XCTAssertEqual(KeyChord("i", [.command, .option]).label, "⌥⌘I")
        XCTAssertEqual(KeyChord("e").label, "E")
        XCTAssertEqual(KeyChord("space").label, "Space")
    }
}
