//
//  DismissibleSheetSourceTests.swift
//  openshape3dTests
//
//  Every sheet in the app goes through `dismissibleSheet` (#117): on the Mac
//  a plain `.sheet` whose content has toolbar buttons does not close from its
//  own Done or Cancel. The fault cannot be shown in a simulator, and the
//  Mac's UI tests need a password to run, so this reads the source instead.
//

import XCTest

final class DismissibleSheetSourceTests: XCTestCase {

    private static let uiSources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("openshape3d", isDirectory: true)

    func testNoPlainSheetModifierInTheApp() throws {
        let files = try XCTUnwrap(FileManager.default.enumerator(at: Self.uiSources, includingPropertiesForKeys: nil))
        var checked = 0
        var offenders: [String] = []
        for case let url as URL in files where url.pathExtension == "swift" {
            // The wrapper itself is the one place that calls `.sheet`.
            if url.lastPathComponent == "DismissibleSheet.swift" { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            checked += 1
            for (index, line) in text.components(separatedBy: "\n").enumerated() {
                // A modifier starts its line; `paper.sheet(point)` and the
                // like are calls on a value and do not.
                if line.trimmingCharacters(in: .whitespaces).hasPrefix(".sheet(") {
                    offenders.append("\(url.lastPathComponent):\(index + 1)")
                }
            }
        }
        XCTAssertGreaterThan(checked, 100, "the app's sources were not found at \(Self.uiSources.path)")
        XCTAssertEqual(offenders, [], "use .dismissibleSheet(…) so the sheet also closes on the Mac (UI/DismissibleSheet.swift)")
    }
}
