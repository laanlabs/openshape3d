import XCTest
import simd
@testable import openshape3d

final class SketchParityFoundationTests: XCTestCase {
    func testAnnotationVisibilityFiltersUnrelatedGeometryAndPointRoles() {
        let a = UUID(), b = UUID()
        let refs = [ConstraintRef(entityID: a, role: .endpointA)]
        XCTAssertFalse(SketchAnnotationVisibility.shows(refs: refs, alwaysShow: false,
            selectedEntities: [b], selectedPoints: []))
        XCTAssertTrue(SketchAnnotationVisibility.shows(refs: refs, alwaysShow: false,
            selectedEntities: [a], selectedPoints: []))
        XCTAssertFalse(SketchAnnotationVisibility.shows(refs: refs, alwaysShow: false,
            selectedEntities: [], selectedPoints: [.init(entityID: a, role: .endpointB)]))
        XCTAssertTrue(SketchAnnotationVisibility.shows(refs: refs, alwaysShow: false,
            selectedEntities: [], selectedPoints: refs))
        XCTAssertTrue(SketchAnnotationVisibility.shows(
            refs: [.init(entityID: a, role: .whole)], alwaysShow: false,
            selectedEntities: [], selectedPoints: refs))
    }

    func testSelectedGlyphAndAlwaysShowDoNotNeedGeometrySelection() {
        let refs = [ConstraintRef(entityID: UUID(), role: .whole)]
        XCTAssertFalse(SketchAnnotationVisibility.shows(refs: refs, alwaysShow: false,
            selectedEntities: [], selectedPoints: []))
        XCTAssertTrue(SketchAnnotationVisibility.shows(refs: refs, alwaysShow: true,
            selectedEntities: [], selectedPoints: []))
        XCTAssertTrue(SketchAnnotationVisibility.shows(refs: refs, alwaysShow: false,
            selectedEntities: [], selectedPoints: [], explicitlySelected: true))
    }

    func testOutlineSelectionUsesDepthAndSkipsHiddenSketches() {
        let far = Sketch(plane: .ground, entities: [
            .line(id: UUID(), a: SIMD2(0, 0), b: SIMD2(10, 0))])
        let near = Sketch(plane: .offsetGround(y: 2), entities: [
            .line(id: UUID(), a: SIMD2(0, 0.1), b: SIMD2(10, 0.1))])
        let ray = Ray(origin: SIMD3(5, 10, 0), direction: SIMD3(0, -1, 0))
        XCTAssertEqual(SketchHitTester.nearestEntity(along: ray, in: [far, near],
            tolerance: 0.4)?.entity.id, near.entities[0].id,
            "Nearer sketch wins even if farther sketch is exactly under pointer")
        XCTAssertNil(SketchHitTester.nearestEntity(along: ray, in: [far, near],
            tolerance: 0.4, maximumDepth: 7), "Body/image in front occludes the sketch")
        var hidden = near
        hidden.isHidden = true
        XCTAssertEqual(SketchHitTester.nearestEntity(along: ray, in: [far, hidden],
            tolerance: 0.4)?.entity.id, far.entities[0].id)
    }

    func testProfileInteriorIsNotAnOutlineHit() {
        let rectangle = Sketch(plane: .ground, entities: [
            .rect(id: UUID(), min: .zero, max: SIMD2(10, 10))])
        let ray = Ray(origin: SIMD3(5, 10, -5), direction: SIMD3(0, -1, 0))
        XCTAssertNil(SketchHitTester.nearestEntity(along: ray, in: [rectangle], tolerance: 0.4))
    }

    func testAllSnapsOffPreservesPointerExactly() {
        let sketch = Sketch(plane: .ground, entities: [
            .line(id: UUID(), a: .zero, b: SIMD2(10, 0))])
        let p = SIMD2(0.13, 0.09)
        let result = SnapEngine.snap(p, in: sketch,
            faceLoops: [[.zero, SIMD2(10, 0), SIMD2(10, 10), SIMD2(0, 10)]],
            options: SnapOptions(grid: false, sketchGuidepoints: false, faceGuidepoints: false))
        XCTAssertEqual(result.kind, .free)
        XCTAssertEqual(result.point, p)
    }

    func testGuidepointCategoriesAreIndependentOfGrid() {
        let sketch = Sketch(plane: .ground, entities: [
            .line(id: UUID(), a: SIMD2(0.17, 0.17), b: SIMD2(10, 0))])
        let p = SIMD2(0.2, 0.2)
        XCTAssertEqual(SnapEngine.snap(p, in: sketch,
            options: SnapOptions(grid: false)).kind, .endpoint)
        XCTAssertEqual(SnapEngine.snap(p, in: sketch,
            options: SnapOptions(sketchGuidepoints: false)).kind, .grid)
    }

    func testFaceEdgeDoesNotQuantizeWhenGridIsOff() {
        let loop = [SIMD2<Double>(0, 0), SIMD2(10, 0), SIMD2(10, 10), SIMD2(0, 10)]
        let p = SIMD2(2.13, 0.1)
        let result = SnapEngine.snap(p, in: nil, faceLoops: [loop],
            options: SnapOptions(grid: false))
        XCTAssertEqual(result.kind, .edge)
        XCTAssertEqual(result.point.x, 2.13, accuracy: 1e-10)
        XCTAssertEqual(result.point.y, 0, accuracy: 1e-10)
        let free = SnapEngine.snap(p, in: nil, faceLoops: [loop],
            options: SnapOptions(grid: false, faceGuidepoints: false))
        XCTAssertEqual(free.point, p)
        XCTAssertEqual(free.kind, .free)
    }
}
