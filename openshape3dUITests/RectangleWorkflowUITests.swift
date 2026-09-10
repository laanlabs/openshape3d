import XCTest

final class RectangleWorkflowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }
    private func start() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["OS3D_FRESH"] = "1"
        app.launchEnvironment["OS3D_RESET_STORE"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        p(app, 0.8, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2) // automatic camera flight after choosing the plane
        XCTAssertFalse(app.buttons["Look at Sketch"].exists,
                       "Sketch entry should align the camera without a second action")
        return app
    }
    private func p(_ app: XCUIApplication, _ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
    }
    private func type(_ app: XCUIApplication, _ name: String) {
        app.buttons["RectangleTypeMenu"].tap()
        app.buttons["RectangleType-" + name].tap()
        sleep(1) // menu dismissal completes before the first canvas point
    }
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    private enum AxisSide { case top, left, right }

    /// Tap the painted midpoint of an axis-aligned rectangle edge. Each corner
    /// is exposed once per incident entity, so deduplicate the point markers
    /// before choosing the side; this stays valid after resize and history.
    private func tapAxisEdge(_ app: XCUIApplication, side: AxisSide) {
        let window = app.windows.firstMatch
        let centers = app.descendants(matching: .any)
            .matching(identifier: "SketchPointMarker").allElementsBoundByIndex
            .map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
        var unique: [CGPoint] = []
        for point in centers where !unique.contains(where: {
            hypot($0.x - point.x, $0.y - point.y) < 3
        }) { unique.append(point) }
        XCTAssertTrue(unique.count == 2 || unique.count == 4,
                      "Expected two rect bounds or four rendered line corners")
        guard unique.count == 2 || unique.count == 4 else { return }
        let minX = unique.map(\.x).min()!, maxX = unique.map(\.x).max()!
        let minY = unique.map(\.y).min()!, maxY = unique.map(\.y).max()!
        let midpoint: CGPoint
        switch side {
        case .top: midpoint = CGPoint(x: (minX + maxX) / 2, y: minY)
        case .left: midpoint = CGPoint(x: minX, y: (minY + maxY) / 2)
        case .right: midpoint = CGPoint(x: maxX, y: (minY + maxY) / 2)
        }
        window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: midpoint.x - window.frame.minX,
            dy: midpoint.y - window.frame.minY
        )).tap()
    }

    func testGalleryReopenedDesignCanUndoNewRectangle() {
        let app = start()
        p(app, 0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(app, 0.55, 0.48))
        app.buttons["Exit Sketching"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Designs"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "OS3D_FRESH")
        app.launchEnvironment.removeValue(forKey: "OS3D_RESET_STORE")
        app.launch()
        let card = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Untitled'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        XCTAssertTrue(app.buttons["SketchGroup"].waitForExistence(timeout: 10))
        startSketchTool(app, "Rect")
        p(app, 0.8, 0.78).tap()
        XCTAssertTrue(app.staticTexts["Sketching on ground plane"].waitForExistence(timeout: 3))
        sleep(2)
        p(app, 0.35, 0.65).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.82))
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        XCTAssertTrue(labels.firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(labels.count, 2)
        sleep(3) // allow the same autosave window as manual live interaction
        let undo = app.buttons["UndoButton"]
        XCTAssertTrue(undo.isEnabled)
        undo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(labels.firstMatch.waitForNonExistence(timeout: 3),
                      "Undo in a gallery-reopened project must remove the newly drawn rectangle")
        attach(app, "gallery-undo-before-profile-check")
        app.buttons["Exit Sketching"].tap()
        p(app, 0.5, 0.74).tap()
        XCTAssertFalse(app.buttons["Extrude"].exists,
                       "Undo must remove the profile, not only clear selection")
        app.buttons["RedoButton"].tap()
        p(app, 0.5, 0.74).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3),
                      "Redo must restore the usable profile; selection badges need not return")
        attach(app, "gallery-redo-restored-profile")
    }

    func testRectangleCenterDragTranslatesWithoutOrbitAndRestoresHistory() throws {
        let app = start()
        type(app, "diagonal")
        p(app, 0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(app, 0.60, 0.52))
        app.buttons["Rect"].tap()
        let center = app.descendants(matching: .any)["RectangleCenterControl"].firstMatch
        XCTAssertTrue(center.waitForExistence(timeout: 3))
        func bounds() throws -> CGRect {
            let points = app.descendants(matching: .any).matching(identifier: "SketchPointMarker")
                .allElementsBoundByIndex.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
            XCTAssertEqual(points.count, 4, "All four rectangle corners must be visible")
            let minX = try XCTUnwrap(points.map(\.x).min()), maxX = try XCTUnwrap(points.map(\.x).max())
            let minY = try XCTUnwrap(points.map(\.y).min()), maxY = try XCTUnwrap(points.map(\.y).max())
            return CGRect(x: minX, y: minY, width: maxX-minX, height: maxY-minY)
        }
        let before = try bounds()
        let start = center.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.15, thenDragTo: start.withOffset(CGVector(dx: 60, dy: 35)))
        let after = try bounds()
        XCTAssertEqual(after.width, before.width, accuracy: 2)
        XCTAssertEqual(after.height, before.height, accuracy: 2)
        XCTAssertEqual(after.minX-before.minX, 60, accuracy: 5)
        XCTAssertEqual(after.minY-before.minY, 35, accuracy: 5)
        attach(app, "rectangle-center-translated-no-orbit")
        app.buttons["Undo"].tap()
        let undone = try bounds()
        XCTAssertEqual(undone.minX, before.minX, accuracy: 2)
        XCTAssertEqual(undone.minY, before.minY, accuracy: 2)
        app.buttons["Redo"].tap()
        let redone = try bounds()
        XCTAssertEqual(redone.minX, after.minX, accuracy: 2)
        XCTAssertEqual(redone.minY, after.minY, accuracy: 2)
        p(app, 0.72, 0.72).tap() // clear the center selected by the preceding drag
        center.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertEqual(app.buttons.matching(identifier: "DimensionLabel").count, 0,
                       "Center selection must not select the whole rectangle")
        let centerLock = app.buttons["RectangleCenterLockToggle"]
        XCTAssertTrue(centerLock.waitForExistence(timeout: 3))
        func expectCenterLock(_ label: String) {
            let transition = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label == %@", label), object: centerLock)
            XCTAssertEqual(XCTWaiter.wait(for: [transition], timeout: 3), .completed,
                           "Each direct padlock tap must perform one scoped toggle")
        }
        func reselectAfterDirectLock() {
            let finished = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"), object: centerLock)
            XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 3), .completed,
                           "Direct Lock must finish the center selection")
            center.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(centerLock.waitForExistence(timeout: 3))
            expectCenterLock("Unlock center")
        }
        expectCenterLock("Lock center")
        centerLock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        reselectAfterDirectLock()
        attach(app, "rectangle-center-direct-lock-after-tap")
        centerLock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        expectCenterLock("Lock center")
        centerLock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        reselectAfterDirectLock()
        XCTAssertEqual(app.buttons["ConstraintRail-fixed"].label, "Unlock")
        attach(app, "rectangle-center-only-locked")
        let lockedCenter = center.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        lockedCenter.press(forDuration: 0.15,
            thenDragTo: lockedCenter.withOffset(CGVector(dx: 60, dy: 35)))
        XCTAssertTrue(app.staticTexts["Locked or constrained sketch parts can't be moved."].waitForExistence(timeout: 3))
        XCTAssertEqual(try bounds().minX, after.minX, accuracy: 2)
        app.buttons["Undo"].tap()
        XCTAssertEqual(app.buttons["ConstraintRail-fixed"].label, "Lock",
                       "Undo after a refused drag must remove the lock, not a no-op movement")
        app.buttons["ConstraintRail-fixed"].tap()
        XCTAssertEqual(app.buttons["ConstraintRail-fixed"].label, "Unlock")
        tapAxisEdge(app, side: .top)
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        attach(app, "rectangle-center-lock-edge-selected")
        let width = try XCTUnwrap(app.buttons.matching(identifier: "DimensionLabel").allElementsBoundByIndex
            .min { $0.frame.midY < $1.frame.midY })
        width.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let field = app.textFields["DimensionField"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let original = try XCTUnwrap(Double((field.value as? String) ?? ""))
        for c in String(format: "%.4f", original / 2) { app.buttons["Keypad-\(c)"].tap() }
        app.buttons["KeypadCommit"].tap()
        let resized = try bounds()
        XCTAssertEqual(resized.midX, after.midX, accuracy: 2)
        XCTAssertEqual(resized.midY, after.midY, accuracy: 2)
        XCTAssertEqual(resized.width, after.width / 2, accuracy: 2)
        XCTAssertEqual(resized.height, after.height, accuracy: 2)
        attach(app, "rectangle-center-lock-symmetric-width")
        app.buttons["Undo"].tap()
        XCTAssertEqual(try bounds().width, after.width, accuracy: 2)
        app.buttons["Redo"].tap()
        XCTAssertEqual(try bounds().width, resized.width, accuracy: 2)
    }

    func testReverseDiagonalWidthEditKeepsProfileAtLeftSide() throws {
        let app = start()
        type(app, "diagonal")
        // Reverse drag distinguishes native's left-side anchor from the old
        // first-corner assumption (which incorrectly held the right edge).
        p(app, 0.65, 0.60).press(forDuration: 0.15, thenDragTo: p(app, 0.35, 0.35))
        let field = app.textFields["DimensionField"].firstMatch
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(field.exists, "Rectangle release must not open the keypad")
        XCTAssertEqual(app.buttons.matching(identifier: "DimensionLabel").count, 2)
        attach(app, "diagonal-before-badge-tap")
        // Use the visible badge center, matching the paired Peekaboo input;
        // XCTest's inferred hit point can select an overlapping canvas point.
        app.buttons["DimensionLabel"].firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        attach(app, "diagonal-after-badge-tap")
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let original = try XCTUnwrap(Double((field.value as? String) ?? ""))
        for _ in 0..<24 where !((field.value as? String) ?? "").isEmpty {
            app.buttons["KeypadDelete"].tap()
        }
        let half = String(format: "%.4f", original / 2)
        for c in half { app.buttons["Keypad-\(c)"].tap() }
        app.buttons["KeypadCommit"].tap()
        attach(app, "reverse-diagonal-half-width-left-side")
        app.buttons["Exit Sketching"].tap()
        // Inside the resized rectangle near the left side. Center-based or
        // first-corner/right-anchored shrinking leaves this point outside.
        p(app, 0.39, 0.47).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3),
                      "Reverse-drag width editing must preserve the left side")
    }


    func testRightSideHeightKeypadIsReachableAndReplacesSeed() throws {
        let app = start()
        type(app, "center")
        p(app, 0.68, 0.76).press(forDuration: 0.15, thenDragTo: p(app, 0.78, 0.82))
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        XCTAssertTrue(labels.firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        // Native height leader sits left of the rectangle, not on its right edge.
        let height = try XCTUnwrap(labels.allElementsBoundByIndex.min { $0.frame.midX < $1.frame.midX })
        attach(app, "height-before-badge-tap")
        height.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        attach(app, "height-after-badge-tap")
        let field = app.textFields["DimensionField"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let commit = app.buttons["KeypadCommit"]
        XCTAssertTrue(commit.isHittable)
        let rail = app.buttons["ConstraintRail-Horizontal"]
        if rail.exists { XCTAssertFalse(commit.frame.intersects(rail.frame)) }
        // A first digit replaces the measurement, then subsequent digits append.
        app.buttons["Keypad-1"].tap()
        XCTAssertEqual(field.value as? String, "1")
        app.buttons["Keypad-."] .tap()
        app.buttons["Keypad-5"].tap()
        XCTAssertEqual(field.value as? String, "1.5")
        attach(app, "right-height-keypad-clear-of-rail")
        commit.tap()
        XCTAssertFalse(field.exists)
        XCTAssertTrue(labels.matching(NSPredicate(format: "label == '1.5 mm'")).firstMatch.waitForExistence(timeout: 3))
    }

    func testCenterRectangleExtendsAcrossItsStartingPoint() {
        let app = start()
        type(app, "center")
        p(app, 0.52, 0.48).press(forDuration: 0.15, thenDragTo: p(app, 0.66, 0.60))
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        attach(app, "center-rectangle")
        let centerLock = app.buttons["RectangleCenterLockToggle"]
        XCTAssertTrue(centerLock.waitForExistence(timeout: 3))
        XCTAssertEqual(centerLock.label, "Lock center")
        centerLock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(NSPredicate(format: "exists == false").evaluate(with: centerLock)
            || XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: centerLock)], timeout: 3) == .completed)
        XCTAssertEqual(app.buttons.matching(identifier: "DimensionLabel").count, 0)
        attach(app, "released-center-locked")
        app.buttons["Exit Sketching"].tap()
        // This is inside the reflected quadrant, not a diagonal rectangle
        // starting at (.52, .48).
        p(app, 0.45, 0.42).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3))
    }

    func testThreePointRectangleDragCreatesRotatedExtrudableProfile() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.38).press(forDuration: 0.15, thenDragTo: p(app, 0.64, 0.46))
        XCTAssertTrue(app.staticTexts["Draw the perpendicular height"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        p(app, 0.64, 0.46).press(forDuration: 0.15, thenDragTo: p(app, 0.58, 0.65))
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons.matching(identifier: "DimensionLabel").count, 2)
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        attach(app, "three-point-rectangle")
        app.buttons["Exit Sketching"].tap()
        p(app, 0.46, 0.515).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3))
    }

    func testThreePointHeightCanBeEditedWithoutLosingBaselineBadge() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.38).press(forDuration: 0.15, thenDragTo: p(app, 0.64, 0.46))
        p(app, 0.64, 0.46).press(forDuration: 0.15, thenDragTo: p(app, 0.58, 0.65))
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        XCTAssertTrue(labels.firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(labels.count, 2)
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        labels.element(boundBy: 1).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let field = app.textFields["DimensionField"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        let previousHeight = field.value as? String
        XCTAssertNotEqual(previousHeight, "1")
        app.buttons["Keypad-1"].tap()
        XCTAssertEqual(field.value as? String, "1")
        app.buttons["KeypadCommit"].tap()
        XCTAssertTrue(labels.matching(NSPredicate(format: "label == '1 mm'")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(labels.count, 2, "Editing height must keep the baseline accessible")
        attach(app, "three-point-height-edited-both-badges")
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(labels.count, 2)
        XCTAssertFalse(labels.matching(NSPredicate(format: "label == '1 mm'")).firstMatch.exists,
                       "Undo must restore the pre-edit height, not merely retain two labels")
        app.buttons["RedoButton"].tap()
        XCTAssertTrue(labels.matching(NSPredicate(format: "label == '1 mm'")).firstMatch.waitForExistence(timeout: 3))
    }

    func testSingleEdgeGizmoMoveRetainsClosedRectangleProfile() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.4))
        p(app, 0.65, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.6))
        app.buttons["Rect"].tap()
        sleep(1)
        p(app, 0.2, 0.7).tap()
        sleep(1)
        p(app, 0.45, 0.4).tap()
        sleep(1)
        XCTAssertTrue(app.buttons["SketchCopyBadge"].exists)
        app.buttons["SketchTransformMode"].tap()
        attach(app, "single-rectangle-edge-before-gizmo")
        p(app, 0.5, 0.4).press(forDuration: 0.3, thenDragTo: p(app, 0.5, 0.35))
        sleep(1)
        attach(app, "single-rectangle-edge-after-gizmo")
        app.buttons["Exit Sketching"].tap()
        p(app, 0.5, 0.5).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3),
                      "Moved baseline must remain connected to an extrudable closed profile")
    }

    func testAxisRectangleSideLockLeavesOppositeEdgeFree() {
        let app = start()
        type(app, "diagonal")
        p(app, 0.35, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.6))
        sleep(1)
        app.buttons["Rect"].tap()
        sleep(1)
        p(app, 0.2, 0.7).tap()
        sleep(1)
        tapAxisEdge(app, side: .right)
        sleep(1)
        app.buttons["ConstraintRail-fixed"].tap()
        tapAxisEdge(app, side: .left)
        sleep(1)
        let handle = app.descendants(matching: .any).matching(identifier: "SketchRectangleEdgeHandle").firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 3))
        let before = handle.frame.midX
        let center = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.3, thenDragTo: center.withOffset(CGVector(dx: -40, dy: 0)))
        XCTAssertLessThan(handle.frame.midX, before - 25)
        app.buttons["UndoButton"].tap()
        let restored = NSPredicate { _, _ in abs(handle.frame.midX - before) <= 2 }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: restored, object: nil)], timeout: 3), .completed)
        app.buttons["RedoButton"].tap()
        XCTAssertLessThan(handle.frame.midX, before - 25)
        tapAxisEdge(app, side: .right)
        sleep(1)
        let fixedX = handle.frame.midX
        let lockedCenter = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        lockedCenter.press(forDuration: 0.3, thenDragTo: lockedCenter.withOffset(CGVector(dx: 40, dy: 0)))
        XCTAssertEqual(handle.frame.midX, fixedX, accuracy: 2)
        attach(app, "axis-side-lock-opposite-free-selected-fixed")
        XCTAssertEqual(app.buttons["ConstraintRail-fixed"].label, "Unlock")
        app.buttons["ConstraintRail-fixed"].tap()
        XCTAssertEqual(app.buttons["ConstraintRail-fixed"].label, "Lock")
        let freeCenter = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        freeCenter.press(forDuration: 0.3, thenDragTo: freeCenter.withOffset(CGVector(dx: 30, dy: 0)))
        XCTAssertGreaterThan(handle.frame.midX, fixedX + 20)
        attach(app, "axis-side-unlock-frees-selected-edge")
    }

    func testAxisRectangleEdgeHandleResizesAndChangesSelectedSide() {
        let app = start()
        type(app, "diagonal")
        p(app, 0.35, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.6))
        sleep(1)
        app.buttons["Rect"].tap()
        sleep(1)
        p(app, 0.2, 0.7).tap()
        sleep(1)
        tapAxisEdge(app, side: .top)
        sleep(1)
        let handle = app.descendants(matching: .any).matching(identifier: "SketchRectangleEdgeHandle").firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 3))
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        XCTAssertEqual(labels.count, 2)
        XCTAssertLessThan(labels.element(boundBy: 0).frame.maxY, app.frame.height * 0.4,
                          "Selected top edge must put width leader outside that edge")
        let before = handle.frame.midY
        let center = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.3, thenDragTo: center.withOffset(CGVector(dx: 0, dy: -45)))
        XCTAssertLessThan(handle.frame.midY, before - 20)
        attach(app, "axis-before-undo")
        app.buttons["UndoButton"].tap()
        let restored = NSPredicate { _, _ in abs(handle.frame.midY - before) <= 2 }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: restored, object: nil)], timeout: 3), .completed,
                       "Undo must restore the original handle position after rendering settles")
        attach(app, "axis-after-undo")
        app.buttons["RedoButton"].tap()
        XCTAssertLessThan(handle.frame.midY, before - 20)
        tapAxisEdge(app, side: .right)
        sleep(1)
        XCTAssertGreaterThan(handle.frame.midX, app.frame.width * 0.65)
        XCTAssertGreaterThan(labels.element(boundBy: 1).frame.minX, app.frame.width * 0.65,
                             "Selected right edge must put height leader on its right")
        app.buttons["SketchTransformMode"].tap()
        XCTAssertFalse(handle.exists)
        app.buttons["SketchTransformMode"].tap()
        XCTAssertTrue(handle.waitForExistence(timeout: 3),
                      "Leaving Move/Rotate restores the selected edge handle")
        attach(app, "axis-rectangle-right-edge-handle")
    }

    func testDisconnectRemovesRectangleHandleAndUndoRestoresConnection() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.4))
        p(app, 0.65, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.6))
        app.buttons["Rect"].tap()
        sleep(1)
        p(app, 0.2, 0.7).tap()
        sleep(1)
        p(app, 0.45, 0.4).tap()
        let handle = app.descendants(matching: .any).matching(identifier: "SketchRectangleEdgeHandle").firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 3))
        let disconnect = app.buttons["ConstraintRailDisconnect"]
        XCTAssertTrue(disconnect.isEnabled)
        disconnect.tap()
        sleep(1)
        p(app, 0.45, 0.4).tap()
        XCTAssertTrue(handle.waitForNonExistence(timeout: 3))
        XCTAssertFalse(disconnect.isEnabled)
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.exists,
                      "Disconnect must retain the edge's length readout")
        attach(app, "disconnected-edge-no-rectangle-handle")
        app.buttons["UndoButton"].tap()
        XCTAssertTrue(handle.waitForExistence(timeout: 3))
        XCTAssertTrue(disconnect.isEnabled)
        app.buttons["RedoButton"].tap()
        XCTAssertTrue(handle.waitForNonExistence(timeout: 3))
        XCTAssertFalse(disconnect.isEnabled)
        attach(app, "disconnect-redo-restores-detached-topology")
    }

    func testRectangleNormalHandleMovesAndRefusesSavedLock() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.4))
        p(app, 0.65, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.6))
        app.buttons["Rect"].tap()
        sleep(1)
        p(app, 0.2, 0.7).tap()
        sleep(1)
        p(app, 0.45, 0.4).tap()
        sleep(1)
        let handle = app.descendants(matching: .any).matching(identifier: "SketchRectangleEdgeHandle").firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 3))
        let before = handle.frame.midY
        let center = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.3, thenDragTo: center.withOffset(CGVector(dx: 0, dy: -45)))
        XCTAssertLessThan(handle.frame.midY, before - 20)
        app.buttons["UndoButton"].tap()
        XCTAssertEqual(handle.frame.midY, before, accuracy: 2)
        app.buttons["RedoButton"].tap()
        XCTAssertLessThan(handle.frame.midY, before - 20)
        app.buttons["ConstraintRail-fixed"].tap()
        let lockedPosition = handle.frame.midY
        let lockedCenter = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        lockedCenter.press(forDuration: 0.3, thenDragTo: lockedCenter.withOffset(CGVector(dx: 0, dy: -45)))
        XCTAssertEqual(handle.frame.midY, lockedPosition, accuracy: 2)
        XCTAssertTrue(app.staticTexts["Locked or constrained sketch parts can't be moved."].waitForExistence(timeout: 3))
        attach(app, "rectangle-normal-handle-saved-lock-refusal")
    }

    func testShortThreePointHeightEdgeCanBeSelectedAtItsMiddle() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.4))
        p(app, 0.65, 0.4).press(forDuration: 0.15, thenDragTo: p(app, 0.65, 0.428))
        sleep(1)
        let labels = app.buttons.matching(identifier: "DimensionLabel")
        XCTAssertEqual(labels.count, 2)
        let height = labels.element(boundBy: 1).label
        app.buttons["Rect"].tap()
        sleep(1) // separate palette dismissal from canvas tap delivery
        p(app, 0.2, 0.7).tap()
        sleep(1) // single-tap recognizer waits for the double-tap interval
        XCTAssertEqual(labels.count, 0, "Blank canvas must clear the previous rectangle selection")
        attach(app, "short-edge-before-midpoint-tap")
        tapAxisEdge(app, side: .right)
        XCTAssertTrue(labels.matching(NSPredicate(format: "label == %@", height))
            .firstMatch.waitForExistence(timeout: 3), "Middle must select the height edge, not an endpoint")
        labels.matching(NSPredicate(format: "label == %@", height)).firstMatch
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.textFields["DimensionField"].firstMatch.waitForExistence(timeout: 3))
        attach(app, "short-height-edge-dimension-editor")
    }

    func testThreePointTapsAndCancelDoNotLeaveStrayBaseline() {
        let app = start()
        type(app, "threePoint")
        p(app, 0.35, 0.38).tap()
        XCTAssertTrue(app.buttons["CancelRectangle"].waitForExistence(timeout: 3))
        p(app, 0.64, 0.46).tap()
        XCTAssertTrue(app.staticTexts["Draw the perpendicular height"].waitForExistence(timeout: 3))
        app.buttons["CancelRectangle"].tap()
        XCTAssertFalse(app.buttons["CancelRectangle"].exists)
        // A fresh three-tap construction is one completed rectangle.
        p(app, 0.35, 0.38).tap()
        XCTAssertTrue(app.buttons["CancelRectangle"].waitForExistence(timeout: 3))
        p(app, 0.64, 0.46).tap()
        XCTAssertTrue(app.staticTexts["Draw the perpendicular height"].waitForExistence(timeout: 3))
        p(app, 0.58, 0.65).tap()
        XCTAssertTrue(app.buttons["DimensionLabel"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        app.buttons["Exit Sketching"].tap()
        app.buttons["UndoButton"].tap()
        p(app, 0.46, 0.515).tap()
        XCTAssertFalse(app.buttons["Extrude"].exists, "One undo removes the whole rectangle")
        app.buttons["RedoButton"].tap()
        p(app, 0.46, 0.515).tap()
        XCTAssertTrue(app.buttons["Extrude"].waitForExistence(timeout: 3))
    }

    func testArmedCircleDrawsAtExistingRectangleCornerInsteadOfMovingIt() {
        let app = start()
        p(app, 0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(app, 0.60, 0.60))
        startSketchTool(app, "Circle")
        p(app, 0.35, 0.35).press(forDuration: 0.15, thenDragTo: p(app, 0.44, 0.35))
        let diameter = app.buttons.matching(NSPredicate(format:
            "identifier == 'DimensionLabel' AND label BEGINSWITH 'Ø'")).firstMatch
        XCTAssertTrue(diameter.waitForExistence(timeout: 3),
                      "The circle draw must not become a rectangle control-point edit")
        XCTAssertFalse(app.textFields["DimensionField"].firstMatch.exists)
        diameter.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["KeypadCommit"].waitForExistence(timeout: 3))
        app.buttons["KeypadCommit"].tap()
        attach(app, "circle-at-rectangle-corner")
    }
}
