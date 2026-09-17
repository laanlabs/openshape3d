//
//  SampleDesignsTests.swift
//  openshape3dTests
//
//  The bundled sample designs and the welcome screen's launch decision —
//  pure values only (no ModelContainer; see CLAUDE.md).
//

import XCTest
@testable import openshape3d

final class SampleDesignsTests: XCTestCase {

    // MARK: Bundle contents

    func testEveryCatalogEntryShipsAnArchiveAndThumbnail() {
        let available = SampleDesigns.available()
        XCTAssertEqual(available.map(\.id), SampleDesigns.catalog.map(\.id),
                       "every catalogued sample should have its .os3d in the bundle")
        for sample in available {
            XCTAssertNotNil(SampleDesigns.thumbnailURL(for: sample), "\(sample.id) thumbnail")
        }
    }

    func testEveryArchiveDecodesWithGeometryAndHistory() {
        for sample in SampleDesigns.available() {
            guard let archive = SampleDesigns.archive(for: sample) else {
                XCTFail("\(sample.id).os3d did not decode"); continue
            }
            XCTAssertLessThanOrEqual(archive.version, ProjectArchive.currentVersion, sample.id)
            XCTAssertFalse(archive.bodies.isEmpty, "\(sample.id) has no bodies")
            XCTAssertFalse(archive.features.isEmpty, "\(sample.id) has no feature history")
            XCTAssertTrue(archive.bodies.allSatisfy { $0.brep != nil },
                          "\(sample.id): a bundled sample should stay analytic")
            XCTAssertNotNil(archive.thumbnail, "\(sample.id) card thumbnail")
        }
    }

    // MARK: Install decision

    func testMissingSkipsSamplesAlreadyInTheFolder() {
        let all = SampleDesigns.catalog
        XCTAssertEqual(SampleDesigns.missing(from: [], available: all).map(\.id), all.map(\.id))
        let installed: Set<String> = [all[0].name, all[2].name]
        XCTAssertEqual(SampleDesigns.missing(from: installed, available: all).map(\.id),
                       [all[1].id, all[3].id])
        XCTAssertTrue(SampleDesigns.missing(from: Set(all.map(\.name)), available: all).isEmpty)
    }

    // MARK: Welcome at launch

    func testWelcomeShowsOnceUnlessForcedOrSuppressed() {
        XCTAssertTrue(ProjectGalleryView.wantsWelcomeAtLaunch(hasSeenWelcome: false, environment: [:]))
        XCTAssertFalse(ProjectGalleryView.wantsWelcomeAtLaunch(hasSeenWelcome: true, environment: [:]))
        // Automation hooks start under no sheet, and never mark it seen.
        for hook in ["OS3D_FRESH", "OS3D_AUTO_OPEN", "OS3D_RESET_STORE"] {
            XCTAssertFalse(ProjectGalleryView.wantsWelcomeAtLaunch(
                hasSeenWelcome: false, environment: [hook: "1"]), hook)
        }
        // Staging a screenshot forces it even after it was seen.
        XCTAssertTrue(ProjectGalleryView.wantsWelcomeAtLaunch(
            hasSeenWelcome: true, environment: ["OS3D_WELCOME": "1", "OS3D_RESET_STORE": "1"]))
    }
}
