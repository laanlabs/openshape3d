//
//  RenderFlagsTests.swift
//  openshape3dTests
//
//  Phase B render-pipeline depth: uniform struct layout guards, ViewportScene
//  flag defaults (which must preserve the pre-mode output), section-plane
//  math, and image-quad texture cache revision invalidation.
//

import XCTest
import Metal
import simd
import UIKit
import Euclid
@testable import openshape3d

@MainActor
final class RenderFlagsTests: XCTestCase {

    // MARK: - Uniform struct layout (Swift ↔ MSL shared via ShaderTypes.h)

    func testFrameUniformsStride() {
        // 1 float4x4 (64) + 12 float4 (192) + 4 floats (16) = 272,
        // rounded to the imported C struct's 16-byte tail alignment (288).
        // MSL compiles the same header, so a drift here means the GPU reads
        // garbage — update both sides together.
        XCTAssertEqual(MemoryLayout<FrameUniforms>.stride, 288)
        XCTAssertEqual(MemoryLayout<FrameUniforms>.stride % 16, 0)
    }

    func testBodyUniformsStride() {
        // float4x4 (64) + float4 (16) + uint + 2 floats + pad (16) = 96.
        XCTAssertEqual(MemoryLayout<BodyUniforms>.stride, 96)
        XCTAssertEqual(MemoryLayout<BodyUniforms>.stride % 16, 0)
    }

    func testUniformDefaultsPreserveLegacyShading() {
        // Zero-initialized C structs are the defaults the renderer relies on:
        // clip off, legacy highlight (roughness 0), dielectric (metallic 0).
        let frame = FrameUniforms()
        XCTAssertEqual(frame.clipEnabled, 0)
        XCTAssertEqual(frame.clipPlane, SIMD4<Float>.zero)

        let body = BodyUniforms()
        XCTAssertEqual(body.metallic, 0)
        XCTAssertEqual(body.roughness, 0)
    }

    // MARK: - ViewportScene flag defaults (today's output must be unchanged)

    func testSceneDefaultsMatchLegacyRendering() {
        let scene = ViewportScene()
        XCTAssertNil(scene.sectionPlane)
        XCTAssertEqual(scene.displayMode, .shaded)
        XCTAssertFalse(scene.showHiddenEdges)
        XCTAssertTrue(scene.imageQuads.isEmpty)
        XCTAssertFalse(scene.groundShadow)
    }

    func testBodyDrawableDefaultsHaveNoMaterial() {
        let drawable = BodyDrawable(
            id: BodyID(),
            renderMesh: RenderMesh(positions: [], normals: [], indices: []),
            edges: nil,
            meshRevision: 1,
            modelMatrix: matrix_identity_float4x4,
            baseColor: SIMD4(1, 1, 1, 1)
        )
        XCTAssertNil(drawable.material)
        XCTAssertEqual(drawable.selectionState, 0)
        XCTAssertFalse(drawable.isTranslucent)
    }

    // MARK: - Section plane math

    func testSectionClipVectorKeepsNormalSide() {
        let section = SectionPlaneState(
            point: SIMD3(0, 2, 0),
            normal: SIMD3(0, 3, 0) // non-unit on purpose
        )
        let plane = section.clipVector
        // Unit normal.
        XCTAssertEqual(simd_length(SIMD3(plane.x, plane.y, plane.z)), 1, accuracy: 1e-6)
        // Point on the plane evaluates to 0.
        XCTAssertEqual(simd_dot(SIMD3<Float>(0, 2, 0), SIMD3(plane.x, plane.y, plane.z)) + plane.w,
                       0, accuracy: 1e-6)
        // The side the normal points to is kept (positive), the other clipped.
        let above = simd_dot(SIMD3<Float>(5, 3, -1), SIMD3(plane.x, plane.y, plane.z)) + plane.w
        let below = simd_dot(SIMD3<Float>(5, 1, -1), SIMD3(plane.x, plane.y, plane.z)) + plane.w
        XCTAssertGreaterThan(above, 0)
        XCTAssertLessThan(below, 0)
    }

    func testSectionClipVectorDegenerateNormalIsZero() {
        let section = SectionPlaneState(point: SIMD3(1, 2, 3), normal: .zero)
        XCTAssertEqual(section.clipVector, .zero)
    }

    // MARK: - Image quad texture cache

    private func makePNGData(side: CGFloat = 4) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    private func makeQuad(id: UUID, data: Data, revision: UInt64) -> ImageQuadDrawable {
        ImageQuadDrawable(
            id: id,
            origin: .zero,
            xAxis: SIMD3(1, 0, 0),
            yAxis: SIMD3(0, 0, -1),
            width: 10,
            height: 10,
            opacity: 0.8,
            textureData: data,
            textureRevision: revision
        )
    }

    func testTextureCacheRevisionInvalidation() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal unavailable")
        }
        let cache = ImageQuadTextureCache()
        let id = UUID()
        let png = makePNGData()

        cache.sync(quads: [makeQuad(id: id, data: png, revision: 1)], device: device)
        let first = cache.texture(for: id)
        XCTAssertNotNil(first)
        XCTAssertEqual(cache.entryCount, 1)

        // Same revision: the decoded texture is reused, not re-created.
        cache.sync(quads: [makeQuad(id: id, data: png, revision: 1)], device: device)
        XCTAssertTrue(cache.texture(for: id) === first)

        // Bumped revision: the texture is re-decoded.
        cache.sync(quads: [makeQuad(id: id, data: png, revision: 2)], device: device)
        let second = cache.texture(for: id)
        XCTAssertNotNil(second)
        XCTAssertFalse(second === first)

        // Removed quad: the entry is evicted.
        cache.sync(quads: [], device: device)
        XCTAssertEqual(cache.entryCount, 0)
        XCTAssertNil(cache.texture(for: id))
    }

    func testTextureCacheToleratesUndecodableData() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal unavailable")
        }
        let cache = ImageQuadTextureCache()
        let id = UUID()
        cache.sync(quads: [makeQuad(id: id, data: Data([0x00, 0x01]), revision: 1)],
                   device: device)
        // The failed decode is cached (no retry storm) and returns nil.
        XCTAssertEqual(cache.entryCount, 1)
        XCTAssertNil(cache.texture(for: id))
    }

    // MARK: - Offscreen render smoke tests (thumbnail path honors the flags)

    /// Shared across tests and deliberately never deallocated: tearing down a
    /// MainActor-isolated class inside XCTest currently trips a Swift-runtime
    /// malloc fault in swift_task_deinitOnExecutorImpl (same issue that made
    /// ImageQuadTextureCache nonisolated).
    private static var sharedRenderer: Renderer?

    /// A renderer looking at one 4×4×4 cube sitting on the ground plane.
    private func makeCubeRenderer() throws -> Renderer {
        if let renderer = Self.sharedRenderer {
            return renderer
        }
        guard let context = RenderContext() else {
            throw XCTSkip("Metal unavailable")
        }
        let body = Body(
            name: "Cube",
            euclidMesh: .primitive(.box(width: 4, depth: 4, height: 4)),
            revision: 1
        )
        let renderer = Renderer(context: context)
        var scene = ViewportScene()
        scene.bodies = [BodyDrawable(
            id: body.id,
            renderMesh: body.render,
            edges: body.edges,
            meshRevision: body.meshRevision,
            modelMatrix: matrix_identity_float4x4,
            baseColor: SIMD4(0.72, 0.75, 0.79, 1)
        )]
        renderer.scene = scene
        if let bounds = renderer.scene.worldBounds {
            renderer.camera.fit(boundsMin: bounds.min, boundsMax: bounds.max)
        }
        Self.sharedRenderer = renderer
        return renderer
    }

    func testDisplayModesAndFlagsChangeOffscreenOutput() throws {
        let renderer = try makeCubeRenderer()

        func png(_ mutate: (inout ViewportScene) -> Void) -> Data? {
            var scene = renderer.scene
            mutate(&scene)
            let before = renderer.scene
            renderer.scene = scene
            defer { renderer.scene = before }
            return renderer.makeThumbnailPNG(width: 160, height: 120)
        }

        guard let shaded = png({ _ in }) else {
            return XCTFail("shaded render failed")
        }
        // Every non-default flag must change the offscreen capture — this is
        // the screenshot/thumbnail path, so it proves item 5 end to end.
        let variants: [(String, Data?)] = [
            ("shadedNoEdges", png { $0.displayMode = .shadedNoEdges }),
            ("wireframe", png { $0.displayMode = .wireframe }),
            ("xray", png { $0.displayMode = .xray }),
            ("hiddenEdges", png { $0.showHiddenEdges = true }),
            ("groundShadow", png { $0.groundShadow = true }),
            ("section", png {
                $0.sectionPlane = SectionPlaneState(
                    point: SIMD3(0, 2, 0), normal: SIMD3(0, -1, 0)
                )
            }),
        ]
        for (name, data) in variants {
            guard let data else {
                XCTFail("\(name) render failed"); continue
            }
            XCTAssertNotEqual(data, shaded, "\(name) should alter the capture")
        }

        // A DISABLED section plane must leave the default output untouched.
        let disabledSection = png {
            $0.sectionPlane = SectionPlaneState(
                point: SIMD3(0, 2, 0), normal: SIMD3(0, -1, 0), enabled: false
            )
        }
        XCTAssertEqual(disabledSection, shaded)
    }

    func testImageQuadRendersIntoOffscreenCapture() throws {
        let renderer = try makeCubeRenderer()
        guard let plain = renderer.makeThumbnailPNG(width: 160, height: 120) else {
            return XCTFail("baseline render failed")
        }
        var scene = renderer.scene
        scene.imageQuads = [ImageQuadDrawable(
            id: UUID(),
            origin: SIMD3(0, 2, 0),
            xAxis: SIMD3(1, 0, 0),
            yAxis: SIMD3(0, 1, 0),
            width: 12,
            height: 12,
            opacity: 1,
            textureData: makePNGData(side: 8),
            textureRevision: 1
        )]
        let before = renderer.scene
        renderer.scene = scene
        defer { renderer.scene = before }
        let withQuad = renderer.makeThumbnailPNG(width: 160, height: 120)
        XCTAssertNotNil(withQuad)
        XCTAssertNotEqual(withQuad, plain, "textured quad should be visible")
    }
}
