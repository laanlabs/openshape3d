//
//  Renderer.swift
//  openshape3d
//
//  Frame orchestration. Pass order in one encoder:
//  background → opaque bodies → feature edges → grid → translucent bodies.
//  (Sketch overlay and gizmo join in later build steps.)
//

import Foundation
import Metal
import MetalKit
import simd
import UIKit
import CoreGraphics

final class Renderer: NSObject, MTKViewDelegate {
    let context: RenderContext
    var camera = TurntableCamera()
    /// NDC shift of the on-screen image's centre — the phone palette's safe
    /// area (`ViewportSafeArea`). Set by the viewport coordinator, which picks
    /// and projects with this same value; offscreen captures stay centred.
    var centerOffset: SIMD2<Float> = .zero
    var scene = ViewportScene()

    private let cache = GPUResourceCache()
    /// Face-material patches' vertex buffers, by patch key.
    private var patchBuffers: [String: (positions: MTLBuffer, normals: MTLBuffer, count: Int)] = [:]
    private let quadTextures = ImageQuadTextureCache()
    private let decalTextures = ImageQuadTextureCache()
    private let bodyTextures = BodyTextureCache()
    /// Face materials' projected pictures (the `.image` pattern).
    private let patchTextures = FingerprintTextureCache()
    /// Bound for the lit shader's picture when there is none to show: Metal
    /// wants every texture the function reads bound.
    private lazy var whiteTexture: MTLTexture? = {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm, width: 1, height: 1, mipmapped: false)
        descriptor.usage = .shaderRead
        guard let texture = context.device.makeTexture(descriptor: descriptor) else { return nil }
        var white: [UInt8] = [255, 255, 255, 255]
        texture.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: &white, bytesPerRow: 4)
        return texture
    }()

    private func syncPatchTextures() {
        patchTextures.sync(images: scene.facePatches.compactMap { patch in
            patch.material.textureData.map { (patch.material.textureRevision, $0) }
        }, device: context.device)
    }
    private let gizmoRenderer = GizmoRenderer()
    #if DEBUG
    private var didMarkFirstDraw = false
    #endif
    private let orientationCubeRenderer = OrientationCubeRenderer()
    private var viewportSize = CGSize(width: 1, height: 1)

    /// Sketch stroke weight, in DRAWABLE PIXELS (`viewportSize` is the drawable,
    /// so this is already device pixels — ~3pt on a 2× display). Metal lines are
    /// 1px, which reads as a hairline; Shapr3D's sketch strokes are chunky.
    static let sketchStrokeWidthPixels: Float = 6

    /// World-units-per-gizmo-unit for constant ~screen size, shared by
    /// rendering and hit-testing.
    func gizmoScale(origin: SIMD3<Float>) -> Float {
        simd_length(camera.position - origin) * tan(camera.fovY * 0.5) * 0.24
    }

    init(context: RenderContext) {
        self.context = context
        super.init()
    }

    /// Called when the viewport is laid out or resized (rotation, split view).
    /// The coordinator uses it to re-publish the camera, since every SwiftUI
    /// overlay that projects world points is sized off this view.
    var viewportSizeChanged: (() -> Void)?

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if size.width > 0, size.height > 0 {
            viewportSize = size
            viewportSizeChanged?()
            // Rendering is paused/on-demand. Rotation can otherwise stretch
            // the previous drawable while SwiftUI markers already project
            // against the new bounds, until an unrelated scene action redraws.
            view.setNeedsDisplay()
        }
    }

    func draw(in view: MTKView) {
        #if DEBUG
        if !didMarkFirstDraw { didMarkFirstDraw = true; OpenTiming.mark("first draw") }
        #endif
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = context.commandQueue.makeCommandBuffer()
        else { return }

        // Every frame ends in a second overlay pass (cleared depth): the
        // orientation cube always, plus gizmo/pull arrow/plane pickers when
        // present. Keep the MSAA color texture and resolve at the end.
        let msaaColor = descriptor.colorAttachments[0].texture
        let resolveTarget = descriptor.colorAttachments[0].resolveTexture
        // A pass with a resolveTexture attached must use a resolving store
        // action (Metal validation asserts otherwise) — detach it here and
        // resolve in the overlay pass instead.
        descriptor.colorAttachments[0].resolveTexture = nil
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.depthAttachment.storeAction = .dontCare

        cache.sync(with: scene, device: context.device)
        quadTextures.sync(quads: scene.imageQuads, device: context.device)
        bodyTextures.sync(bodies: scene.bodies, device: context.device)
        syncPatchTextures()

        var frame = makeFrameUniforms()
        if let target = descriptor.colorAttachments[0].texture,
           var blur = depthOfFieldUniforms(frame, width: target.width, height: target.height),
           let targets = liveDepthOfFieldTargets(width: target.width, height: target.height) {
            // Depth of field: the scene into textures of its own, then blurred
            // onto the screen.
            guard encodeScene(into: targets, clearColor: descriptor.colorAttachments[0].clearColor,
                              commandBuffer: commandBuffer, frame: &frame),
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
            encodeDepthOfField(encoder: encoder, from: targets, uniforms: &blur)
            encoder.endEncoding()
        } else {
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
            }
            encodeScene(encoder: encoder, frame: &frame)
            encoder.endEncoding()
        }

        // Overlays are never sectioned (they use the unclipped flat-color
        // fragment shader, but keep the uniforms honest too).
        frame.clipEnabled = 0

        // 6. Overlay pass: depth cleared so overlays draw on top.
        if let msaaColor {
            let overlay = MTLRenderPassDescriptor()
            overlay.colorAttachments[0].texture = msaaColor
            overlay.colorAttachments[0].loadAction = .load
            if let resolveTarget {
                overlay.colorAttachments[0].resolveTexture = resolveTarget
                overlay.colorAttachments[0].storeAction = .multisampleResolve
            } else {
                overlay.colorAttachments[0].storeAction = .store
            }
            overlay.depthAttachment.texture = descriptor.depthAttachment.texture
            overlay.depthAttachment.loadAction = .clear
            overlay.depthAttachment.storeAction = .dontCare
            overlay.depthAttachment.clearDepth = 1

            if let overlayEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: overlay) {
                gizmoRenderer.prepare(device: context.device)
                if var gizmo = scene.gizmo {
                    gizmo.scale = gizmoScale(origin: gizmo.origin)
                    gizmoRenderer.draw(
                        encoder: overlayEncoder,
                        pipelines: context.pipelines,
                        frame: &frame,
                        gizmo: gizmo
                    )
                }
                if !scene.planePickers.isEmpty {
                    // Origin tiles keep a constant on-screen size: resolve
                    // them here with the same gizmo unit the hit test uses.
                    let tiles = scene.planePickers.map { tile -> PlanePickerTile in
                        guard tile.screenProportional else { return tile }
                        let o = tile.plane.origin
                        let origin = SIMD3<Float>(Float(o.x), Float(o.y), Float(o.z))
                        return tile.scaled(by: PlanePicking.originTileScale(
                            gizmoUnit: Double(gizmoScale(origin: origin))))
                    }
                    gizmoRenderer.drawPlaneTiles(
                        encoder: overlayEncoder,
                        pipelines: context.pipelines,
                        frame: &frame,
                        tiles: tiles
                    )
                }
                // The pull handle is drawn as an always-on-top SwiftUI SF Symbol
                // overlay (ExtrudeGizmoOverlay), not in the 3D pass — so it stays
                // visible when the cap dips below/behind a surface. `scene.pullArrow`
                // is still populated for the geometric grab hit-test.
                // Orientation cube (spec §7.2), always on. Layout math is in
                // points so its NDC placement matches tap hit-testing.
                orientationCubeRenderer.prepare(device: context.device)
                orientationCubeRenderer.draw(
                    encoder: overlayEncoder,
                    pipelines: context.pipelines,
                    camera: camera,
                    viewSize: view.bounds.size
                )
                overlayEncoder.endEncoding()
            }
        }

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }

    /// Everything except the gizmo overlay — shared by live drawing and
    /// offscreen thumbnail/screenshot capture. `drawBackground`/`drawGrid`
    /// support screenshot options (transparent background, grid off).
    private func encodeScene(
        encoder: MTLRenderCommandEncoder,
        frame: inout FrameUniforms,
        drawBackground: Bool = true,
        drawGrid: Bool = true
    ) {
        let pipelines = context.pipelines
        let mode = scene.displayMode

        // 1. Background gradient
        if drawBackground {
            encoder.setRenderPipelineState(pipelines.background)
            encoder.setDepthStencilState(pipelines.depthIgnore)
            encoder.setFragmentBytes(&frame, length: MemoryLayout<FrameUniforms>.stride,
                                     index: Int(BufferIndexFrameUniforms.rawValue))
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }

        // Frame uniforms for both stages up front; the fragment binding feeds
        // the section clip test in the edge/fill/sketch shaders.
        encoder.setVertexBytes(&frame, length: MemoryLayout<FrameUniforms>.stride,
                               index: Int(BufferIndexFrameUniforms.rawValue))
        encoder.setFragmentBytes(&frame, length: MemoryLayout<FrameUniforms>.stride,
                                 index: Int(BufferIndexFrameUniforms.rawValue))

        // 1b. Ground blob shadows, before any body fragments land.
        if scene.groundShadow {
            drawGroundShadows(encoder: encoder)
        }

        // Face-material buffers of patches no longer in the scene go.
        if !patchBuffers.isEmpty {
            let live = Set(scene.facePatches.map(\.key))
            patchBuffers = patchBuffers.filter { live.contains($0.key) }
        }

        // 2. Opaque bodies. Wireframe swaps the fill for a depth-only prepass
        // so hidden lines stay hidden; x-ray defers every body to the
        // translucent pass (6).
        switch mode {
        case .shaded, .shadedNoEdges:
            encoder.setDepthStencilState(pipelines.depthReadWrite)
            for drawable in scene.bodies where !drawable.isSeeThrough {
                drawBody(drawable, encoder: encoder, pipeline: pipelines.lit)
            }
            drawFacePatches(seeThrough: false, encoder: encoder, pipeline: pipelines.lit)
            drawDecals(encoder: encoder)
        case .wireframe:
            encoder.setDepthStencilState(pipelines.depthReadWrite)
            for drawable in scene.bodies where !drawable.isSeeThrough {
                drawBody(drawable, encoder: encoder, pipeline: pipelines.depthOnly)
            }
            drawFacePatches(seeThrough: false, encoder: encoder, pipeline: pipelines.depthOnly)
        case .xray:
            break
        }

        // 3. Feature edges (+ optional hidden-edge pass, reversed depth test).
        // Visualization shows the surfaces alone.
        if mode != .shadedNoEdges, scene.visualization == nil {
            encoder.setRenderPipelineState(pipelines.edge)
            encoder.setDepthStencilState(pipelines.depthReadOnly)
            for drawable in scene.bodies where !drawable.isTranslucent {
                drawEdges(drawable, encoder: encoder)
            }
            if scene.showHiddenEdges {
                encoder.setDepthStencilState(pipelines.depthGreaterReadOnly)
                for drawable in scene.bodies where !drawable.isTranslucent {
                    drawEdges(drawable, encoder: encoder, alphaScale: 0.25)
                }
            }
        }

        // 4. Active sketch grid, or ground in modeling (blended, depth read only)
        if drawGrid, scene.visualization == nil {
            encoder.setRenderPipelineState(pipelines.grid)
            encoder.setDepthStencilState(pipelines.depthReadOnly)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        // 4a. Image quads (Insert Image): blended, depth read, no depth write.
        if !scene.imageQuads.isEmpty {
            drawImageQuads(encoder: encoder)
        }

        // 4b. Closed-profile fills (edge pipeline reused for its depth bias so
        // fills win against coplanar body faces; blended, no depth write)
        if !scene.profileFills.isEmpty {
            encoder.setRenderPipelineState(pipelines.edge)
            encoder.setDepthStencilState(pipelines.depthReadOnly)
            for batch in scene.profileFills where !batch.triangles.isEmpty {
                var body = BodyUniforms()
                body.modelMatrix = matrix_identity_float4x4
                body.baseColor = batch.color
                let length = batch.triangles.count * MemoryLayout<SIMD3<Float>>.stride
                guard let buffer = batch.triangles.withUnsafeBytes({ raw in
                    context.device.makeBuffer(bytes: raw.baseAddress!, length: length,
                                              options: .storageModeShared)
                }) else { continue }
                encoder.setVertexBuffer(buffer, offset: 0, index: Int(BufferIndexPositions.rawValue))
                encoder.setVertexBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                       index: Int(BufferIndexBodyUniforms.rawValue))
                encoder.setFragmentBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                         index: Int(BufferIndexBodyUniforms.rawValue))
                encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                       vertexCount: batch.triangles.count)
            }
        }

        // 5. Sketch overlay strokes. Drawn with the THICK-line pipeline: Metal's
        // line primitive is 1px (a hairline on Retina), and a sketch on a solid's
        // face is coplanar with it, so the hairline also lost the depth fight and
        // the stroke would vanish. The quad expansion carries a bigger bias.
        if !scene.sketchLines.isEmpty {
            encoder.setRenderPipelineState(pipelines.thickLine)
            encoder.setDepthStencilState(pipelines.depthReadOnly)
            for batch in scene.sketchLines where !batch.segments.isEmpty {
                var body = BodyUniforms()
                body.modelMatrix = matrix_identity_float4x4
                body.baseColor = batch.color
                body.lineHalfWidthPx = Self.sketchStrokeWidthPixels / 2
                let length = batch.segments.count * MemoryLayout<SIMD3<Float>>.stride
                guard let buffer = batch.segments.withUnsafeBytes({ raw in
                    context.device.makeBuffer(bytes: raw.baseAddress!, length: length,
                                              options: .storageModeShared)
                }) else { continue }
                encoder.setVertexBuffer(buffer, offset: 0, index: Int(BufferIndexPositions.rawValue))
                encoder.setVertexBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                       index: Int(BufferIndexBodyUniforms.rawValue))
                encoder.setFragmentBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                         index: Int(BufferIndexBodyUniforms.rawValue))
                // 2 endpoints per segment → 6 quad vertices per segment.
                encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                       vertexCount: batch.segments.count / 2 * 6)
            }
        }

        // 6. Translucent bodies (previews) last; in x-ray every body renders
        // here at a fixed low alpha (depth read, no write).
        for drawable in scene.bodies where drawable.isSeeThrough || mode == .xray {
            encoder.setDepthStencilState(pipelines.depthReadOnly)
            // Previews take the Tool Preview Opacity setting; a glass-like
            // material keeps its own opacity.
            let alpha: Float? = drawable.isTranslucent ? scene.toolPreviewOpacity
                : mode == .xray ? 0.35 : nil
            drawBody(drawable, encoder: encoder, pipeline: pipelines.litBlended,
                     alphaOverride: alpha)
        }
        // …then see-through face materials (every patch in x-ray).
        if mode != .wireframe {
            encoder.setDepthStencilState(pipelines.depthReadOnly)
            drawFacePatches(seeThrough: mode == .xray ? nil : true, encoder: encoder,
                            pipeline: pipelines.litBlended, alphaOverride: mode == .xray ? 0.35 : nil)
        }
    }

    /// Insert-Image reference quads: textured, blended, both windings so the
    /// image reads from either side (mirrored from the back, like paper).
    private func drawImageQuads(encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(context.pipelines.texturedQuad)
        encoder.setDepthStencilState(context.pipelines.depthReadOnly)
        for quad in scene.imageQuads {
            guard let texture = quadTextures.texture(for: quad.id) else { continue }
            let hx = quad.xAxis * (quad.width * 0.5)
            let hy = quad.yAxis * (quad.height * 0.5)
            let c0 = quad.origin - hx - hy // bottom-left
            let c1 = quad.origin + hx - hy // bottom-right
            let c2 = quad.origin + hx + hy // top-right
            let c3 = quad.origin - hx + hy // top-left
            let positions: [SIMD3<Float>] = [
                c0, c1, c2, c0, c2, c3,
                c0, c2, c1, c0, c3, c2,
            ]
            // Image v runs top-down: v=0 at the top edge (c3/c2).
            let u0 = SIMD2<Float>(0, 1), u1 = SIMD2<Float>(1, 1)
            let u2 = SIMD2<Float>(1, 0), u3 = SIMD2<Float>(0, 0)
            let uvs: [SIMD2<Float>] = [
                u0, u1, u2, u0, u2, u3,
                u0, u2, u1, u0, u3, u2,
            ]

            var body = BodyUniforms()
            body.modelMatrix = matrix_identity_float4x4
            body.baseColor = SIMD4(1, 1, 1, max(0, min(1, quad.opacity)))
            positions.withUnsafeBytes { raw in
                encoder.setVertexBytes(raw.baseAddress!, length: raw.count,
                                       index: Int(BufferIndexPositions.rawValue))
            }
            uvs.withUnsafeBytes { raw in
                encoder.setVertexBytes(raw.baseAddress!, length: raw.count,
                                       index: Int(BufferIndexTexcoords.rawValue))
            }
            encoder.setFragmentBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                     index: Int(BufferIndexBodyUniforms.rawValue))
            encoder.setFragmentTexture(texture, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                   vertexCount: positions.count)
        }
    }

    /// Cheap planar blob shadows (visualization v1): one soft dark ellipse on
    /// the ground plane under each opaque body's AABB, fading as the body
    /// lifts off the ground.
    private func drawGroundShadows(encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(context.pipelines.blobShadow)
        encoder.setDepthStencilState(context.pipelines.depthReadOnly)
        for drawable in scene.bodies where !drawable.isTranslucent {
            let aabb = drawable.renderMesh.localAABB
            var lo = SIMD3<Float>(.greatestFiniteMagnitude, .greatestFiniteMagnitude,
                                  .greatestFiniteMagnitude)
            var hi = -lo
            for i in 0..<8 {
                let corner = SIMD3<Float>(
                    (i & 1) == 0 ? aabb.min.x : aabb.max.x,
                    (i & 2) == 0 ? aabb.min.y : aabb.max.y,
                    (i & 4) == 0 ? aabb.min.z : aabb.max.z
                )
                let world4 = drawable.modelMatrix * SIMD4(corner, 1)
                let world = SIMD3(world4.x, world4.y, world4.z)
                lo = simd_min(lo, world)
                hi = simd_max(hi, world)
            }
            let rx = max((hi.x - lo.x) * 0.5, 1e-3) * 1.25
            let rz = max((hi.z - lo.z) * 0.5, 1e-3) * 1.25
            let cx = (lo.x + hi.x) * 0.5
            let cz = (lo.z + hi.z) * 0.5
            let lift = max(lo.y, 0)
            let footprint = max(rx, rz)
            // Slight lift above y=0 to dodge z-fighting with coplanar faces.
            let y: Float = 0.002
            let c0 = SIMD3<Float>(cx - rx, y, cz - rz)
            let c1 = SIMD3<Float>(cx + rx, y, cz - rz)
            let c2 = SIMD3<Float>(cx + rx, y, cz + rz)
            let c3 = SIMD3<Float>(cx - rx, y, cz + rz)
            let positions: [SIMD3<Float>] = [c0, c1, c2, c0, c2, c3]
            let uvs: [SIMD2<Float>] = [
                SIMD2(0, 0), SIMD2(1, 0), SIMD2(1, 1),
                SIMD2(0, 0), SIMD2(1, 1), SIMD2(0, 1),
            ]

            var body = BodyUniforms()
            body.modelMatrix = matrix_identity_float4x4
            let strength: Float = 0.30 / (1 + lift / max(footprint, 1e-3))
            body.baseColor = SIMD4(0.05, 0.06, 0.08, strength)
            positions.withUnsafeBytes { raw in
                encoder.setVertexBytes(raw.baseAddress!, length: raw.count,
                                       index: Int(BufferIndexPositions.rawValue))
            }
            uvs.withUnsafeBytes { raw in
                encoder.setVertexBytes(raw.baseAddress!, length: raw.count,
                                       index: Int(BufferIndexTexcoords.rawValue))
            }
            encoder.setFragmentBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                     index: Int(BufferIndexBodyUniforms.rawValue))
            encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                   vertexCount: positions.count)
        }
    }

    // MARK: - Depth of field (spec §14)

    /// The scene's colour (multisample when anti-aliasing is on, with its
    /// resolve) and depth, kept for the blur pass to read.
    struct DepthOfFieldTargets {
        var color: MTLTexture
        var resolved: MTLTexture?
        var depth: MTLTexture
        var readable: MTLTexture { resolved ?? color }
    }

    private var depthOfFieldTargetCache: DepthOfFieldTargets?

    private func liveDepthOfFieldTargets(width: Int, height: Int) -> DepthOfFieldTargets? {
        if let cached = depthOfFieldTargetCache, cached.color.width == width, cached.color.height == height {
            return cached
        }
        depthOfFieldTargetCache = makeDepthOfFieldTargets(width: width, height: height)
        return depthOfFieldTargetCache
    }

    private func makeDepthOfFieldTargets(width: Int, height: Int) -> DepthOfFieldTargets? {
        let device = context.device, samples = RenderContext.sampleCount
        func texture(_ format: MTLPixelFormat, multisample: Bool, read: Bool) -> MTLTexture? {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: format, width: width, height: height, mipmapped: false)
            if multisample {
                descriptor.textureType = .type2DMultisample
                descriptor.sampleCount = samples
            }
            descriptor.usage = read ? [.renderTarget, .shaderRead] : [.renderTarget]
            descriptor.storageMode = .private
            return device.makeTexture(descriptor: descriptor)
        }
        let multisample = samples > 1
        guard let color = texture(RenderContext.colorPixelFormat, multisample: multisample, read: !multisample),
              let depth = texture(RenderContext.depthPixelFormat, multisample: multisample, read: true) else { return nil }
        let resolved = multisample ? texture(RenderContext.colorPixelFormat, multisample: false, read: true) : nil
        if multisample, resolved == nil { return nil }
        return DepthOfFieldTargets(color: color, resolved: resolved, depth: depth)
    }

    /// The blur pass's uniforms for an image `width` × `height` drawn with
    /// `frame`; nil when depth of field is off.
    private func depthOfFieldUniforms(_ frame: FrameUniforms, width: Int, height: Int) -> DepthOfFieldUniforms? {
        guard let dof = scene.visualization?.depthOfField, scene.displayMode != .wireframe else { return nil }
        let eye = camera.position
        let forward = simd_normalize(camera.target - eye)
        var u = DepthOfFieldUniforms()
        u.inverseViewProjection = simd_inverse(frame.viewProjectionMatrix)
        u.cameraPosition = SIMD4(eye, 1)
        u.viewDirection = SIMD4(forward, 0)
        u.focusDistance = DepthOfFieldKit.focusDistance(eye: eye, viewDirection: forward, focus: dof.focus ?? camera.target)
        u.widestRadius = dof.blur * Float(height) * DepthOfFieldKit.maxRadiusFraction
        u.imageWidth = Float(width)
        u.imageHeight = Float(height)
        return u
    }

    /// The scene into `targets`, keeping its depth for the blur.
    @discardableResult
    private func encodeScene(into targets: DepthOfFieldTargets, clearColor: MTLClearColor,
                             commandBuffer: MTLCommandBuffer, frame: inout FrameUniforms,
                             drawBackground: Bool = true, drawGrid: Bool = true) -> Bool {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = targets.color
        pass.colorAttachments[0].resolveTexture = targets.resolved
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = clearColor
        pass.colorAttachments[0].storeAction = targets.resolved != nil ? .multisampleResolve : .store
        pass.depthAttachment.texture = targets.depth
        pass.depthAttachment.loadAction = .clear
        pass.depthAttachment.storeAction = .store
        pass.depthAttachment.clearDepth = 1
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return false }
        encodeScene(encoder: encoder, frame: &frame, drawBackground: drawBackground, drawGrid: drawGrid)
        encoder.endEncoding()
        return true
    }

    private func encodeDepthOfField(encoder: MTLRenderCommandEncoder, from targets: DepthOfFieldTargets,
                                    uniforms: inout DepthOfFieldUniforms) {
        let pipelines = context.pipelines
        encoder.setRenderPipelineState(targets.depth.textureType == .type2DMultisample
                                       ? pipelines.depthOfFieldMS : pipelines.depthOfField)
        encoder.setDepthStencilState(pipelines.depthIgnore)
        encoder.setFragmentTexture(targets.readable, index: 0)
        encoder.setFragmentTexture(targets.depth, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<DepthOfFieldUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    }

    // MARK: - Thumbnail capture

    /// Offscreen render of the current scene (no gizmo), returned as PNG data.
    /// Screenshot options: `transparentBackground` clears to alpha 0 and skips
    /// the gradient pass; `showGrid` off skips the ground grid.
    func makeThumbnailPNG(
        width: Int = 640,
        height: Int = 480,
        transparentBackground: Bool = false,
        showGrid: Bool = true
    ) -> Data? {
        let device = context.device

        let colorDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: RenderContext.colorPixelFormat, width: width, height: height, mipmapped: false
        )
        colorDescriptor.textureType = .type2DMultisample
        colorDescriptor.sampleCount = RenderContext.sampleCount
        colorDescriptor.usage = [.renderTarget]
        colorDescriptor.storageMode = .private

        let resolveDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: RenderContext.colorPixelFormat, width: width, height: height, mipmapped: false
        )
        resolveDescriptor.usage = [.renderTarget, .shaderRead]
        resolveDescriptor.storageMode = .shared

        let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: RenderContext.depthPixelFormat, width: width, height: height, mipmapped: false
        )
        depthDescriptor.textureType = .type2DMultisample
        depthDescriptor.sampleCount = RenderContext.sampleCount
        depthDescriptor.usage = [.renderTarget]
        depthDescriptor.storageMode = .private

        guard
            let colorTexture = device.makeTexture(descriptor: colorDescriptor),
            let resolveTexture = device.makeTexture(descriptor: resolveDescriptor),
            let depthTexture = device.makeTexture(descriptor: depthDescriptor),
            let commandBuffer = context.commandQueue.makeCommandBuffer()
        else {
            NSLog("[openshape3d] thumbnail: texture/commandBuffer creation failed")
            return nil
        }

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = colorTexture
        pass.colorAttachments[0].resolveTexture = resolveTexture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .multisampleResolve
        pass.colorAttachments[0].clearColor = transparentBackground
            ? MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            : MTLClearColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1)
        pass.depthAttachment.texture = depthTexture
        pass.depthAttachment.loadAction = .clear
        pass.depthAttachment.storeAction = .dontCare
        pass.depthAttachment.clearDepth = 1

        cache.sync(with: scene, device: context.device)
        quadTextures.sync(quads: scene.imageQuads, device: context.device)
        bodyTextures.sync(bodies: scene.bodies, device: context.device)
        syncPatchTextures()
        var frame = makeFrameUniforms(viewportSize: CGSize(width: width, height: height))
        if var blur = depthOfFieldUniforms(frame, width: width, height: height),
           let targets = makeDepthOfFieldTargets(width: width, height: height) {
            // Depth of field: the scene first, then blurred into the capture.
            guard encodeScene(into: targets, clearColor: pass.colorAttachments[0].clearColor,
                              commandBuffer: commandBuffer, frame: &frame,
                              drawBackground: !transparentBackground, drawGrid: showGrid),
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return nil }
            encodeDepthOfField(encoder: encoder, from: targets, uniforms: &blur)
            encoder.endEncoding()
        } else {
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else {
                NSLog("[openshape3d] thumbnail: encoder creation failed")
                return nil
            }
            encodeScene(
                encoder: encoder,
                frame: &frame,
                drawBackground: !transparentBackground,
                drawGrid: showGrid
            )
            encoder.endEncoding()
        }
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Read back BGRA and wrap as PNG.
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        pixels.withUnsafeMutableBytes { raw in
            resolveTexture.getBytes(
                raw.baseAddress!,
                bytesPerRow: bytesPerRow,
                from: MTLRegionMake2D(0, 0, width, height),
                mipmapLevel: 0
            )
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue
            | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard
            let providerData = CFDataCreate(nil, pixels, pixels.count),
            let provider = CGDataProvider(data: providerData),
            let image = CGImage(
                width: width, height: height,
                bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow,
                space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: provider, decode: nil, shouldInterpolate: false,
                intent: .defaultIntent
            )
        else {
            NSLog("[openshape3d] thumbnail: CGImage creation failed")
            return nil
        }
        return UIImage(cgImage: image).pngData()
    }

    // MARK: - Draw helpers

    private func drawBody(
        _ drawable: BodyDrawable,
        encoder: MTLRenderCommandEncoder,
        pipeline: MTLRenderPipelineState,
        alphaOverride: Float? = nil
    ) {
        guard let resources = cache.resources(for: drawable.id), resources.indexCount > 0 else { return }
        // An imported body with a texture and texcoords shades through the
        // textured twin of the requested lit pipeline; depth-only and other
        // passes keep the pipeline they asked for.
        var chosen = pipeline
        // A projected picture (the `.image` pattern) is the lit shader's own
        // business, texcoords or not.
        let projectsImage = (drawable.material?.pattern ?? 0) > MaterialPattern.imageThreshold
        if !projectsImage, let texcoords = resources.texcoordBuffer,
           let texture = bodyTextures.texture(for: drawable.id) {
            if pipeline === context.pipelines.lit {
                chosen = context.pipelines.litTextured
            } else if pipeline === context.pipelines.litBlended {
                chosen = context.pipelines.litTexturedBlended
            }
            if chosen !== pipeline {
                encoder.setVertexBuffer(texcoords, offset: 0,
                                        index: Int(BufferIndexTexcoords.rawValue))
                encoder.setFragmentTexture(texture, index: 0)
            }
        }
        if chosen === pipeline {
            let picture = projectsImage ? bodyTextures.texture(for: drawable.id) : nil
            encoder.setFragmentTexture(picture ?? whiteTexture, index: 0)
        }
        encoder.setRenderPipelineState(chosen)
        var body = makeBodyUniforms(drawable)
        if let alphaOverride {
            body.baseColor.w = alphaOverride
        }
        encoder.setVertexBuffer(resources.positionBuffer, offset: 0,
                                index: Int(BufferIndexPositions.rawValue))
        encoder.setVertexBuffer(resources.normalBuffer, offset: 0,
                                index: Int(BufferIndexNormals.rawValue))
        encoder.setVertexBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                               index: Int(BufferIndexBodyUniforms.rawValue))
        encoder.setFragmentBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                 index: Int(BufferIndexBodyUniforms.rawValue))
        var frame = makeFrameUniforms()
        encoder.setFragmentBytes(&frame, length: MemoryLayout<FrameUniforms>.stride,
                                 index: Int(BufferIndexFrameUniforms.rawValue))
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: resources.indexCount,
            indexType: .uint32,
            indexBuffer: resources.indexBuffer,
            indexBufferOffset: 0
        )
    }

    private func drawEdges(
        _ drawable: BodyDrawable,
        encoder: MTLRenderCommandEncoder,
        alphaScale: Float = 1
    ) {
        guard let resources = cache.resources(for: drawable.id),
              let edgeBuffer = resources.edgeVertexBuffer,
              resources.edgeVertexCount > 0
        else { return }
        var body = makeBodyUniforms(drawable)
        let selected = drawable.selectionState == SelectionStateSelected.rawValue
        body.baseColor = selected
            ? makeFrameUniforms().accentColor
            : SIMD4(0.13, 0.15, 0.17, 1)
        body.baseColor.w *= alphaScale
        encoder.setVertexBuffer(edgeBuffer, offset: 0, index: Int(BufferIndexPositions.rawValue))
        encoder.setVertexBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                               index: Int(BufferIndexBodyUniforms.rawValue))
        encoder.setFragmentBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                 index: Int(BufferIndexBodyUniforms.rawValue))
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: resources.edgeVertexCount)
    }

    // MARK: - Uniforms

    private func makeFrameUniforms(viewportSize: CGSize? = nil) -> FrameUniforms {
        // An explicit size is an offscreen capture: no palette sits over it.
        let centerOffset = viewportSize == nil ? self.centerOffset : .zero
        let viewportSize = viewportSize ?? self.viewportSize
        let aspect = Float(viewportSize.width / max(viewportSize.height, 1))
        let cameraPosition = camera.position

        // Headlight: key light fixed relative to the camera, offset up and left,
        // so the model never goes dark while orbiting.
        let view = camera.viewMatrix
        let right = SIMD3(view.columns.0.x, view.columns.1.x, view.columns.2.x)
        let up = SIMD3(view.columns.0.y, view.columns.1.y, view.columns.2.y)
        let forward = simd_normalize(camera.target - cameraPosition)
        let lightDirection = simd_normalize(forward + right * 0.35 - up * 0.45)

        var frame = FrameUniforms()
        frame.viewProjectionMatrix = camera.viewProjection(aspect: aspect, centerOffset: centerOffset)
        frame.cameraPosition = SIMD4(cameraPosition, 1)
        frame.keyLightDirection = SIMD4(lightDirection, 0)
        frame.skyColor = SIMD4(1.0, 1.0, 1.05, 1)
        frame.groundColor = SIMD4(0.62, 0.60, 0.58, 1)
        frame.backgroundTop = SIMD4(0.94, 0.95, 0.97, 1)
        frame.backgroundBottom = SIMD4(0.82, 0.84, 0.88, 1)
        if let lighting = scene.visualization {
            // Visualization: a world-fixed sun and the environment's colours.
            frame.keyLightDirection = SIMD4(lighting.lightDirection, 0)
            frame.keyLightColor = SIMD4(lighting.lightColor, 1)
            frame.skyColor = SIMD4(lighting.sky, 1)
            frame.groundColor = SIMD4(lighting.ground, 1)
            frame.backgroundTop = SIMD4(lighting.backgroundTop, 1)
            frame.backgroundBottom = SIMD4(lighting.backgroundBottom, 1)
        }
        frame.accentColor = SIMD4(0.0, 0.52, 1.0, 1) // Shapr3D selection blue
        // The grid follows the zoom (bug report abb6ea37): at a fixed 1 mm
        // pitch and 120 mm fade radius it vanished as soon as the view pulled
        // back to metre scale. The pitch steps by decades so the view always
        // holds on the order of ten to a hundred minor lines, and the fade
        // radius grows with the camera distance so the plane never runs out
        // under a large model. Majors stay every tenth minor.
        let minorSpacing = Float(scene.lockedGridSpacing ?? camera.gridMinorSpacing)
        let fadeRadius = max(120, camera.distance * 10)
        // w: Surface Analysis for the lit shaders (the grid ignores it).
        frame.gridParams = SIMD4(minorSpacing, 10, fadeRadius, scene.surfaceAnalysis.shaderValue)
        let gridPlane = scene.gridPlane ?? .ground
        let gridCenter = gridPlane.toWorld(gridPlane.toLocal(SIMD3<Double>(camera.target)))
        frame.gridCenter = SIMD4(SIMD3<Float>(gridCenter), 0)
        frame.gridOrigin = SIMD4(SIMD3<Float>(gridPlane.origin), 0)
        frame.gridXAxis = SIMD4(SIMD3<Float>(gridPlane.xAxis), 0)
        frame.gridYAxis = SIMD4(SIMD3<Float>(gridPlane.yAxis), 0)
        frame.edgeDepthBiasNDC = 1e-4
        frame.viewportWidth = Float(max(viewportSize.width, 1))
        frame.viewportHeight = Float(max(viewportSize.height, 1))

        // Section view: fragments beyond the plane are discarded (spec §16.1).
        if let section = scene.sectionPlane, section.enabled {
            let plane = section.clipVector
            if plane != .zero {
                frame.clipPlane = plane
                frame.clipEnabled = 1
            }
        }
        return frame
    }

    /// Decals (spec §14): each decal's body drawn again — its own triangles
    /// and its face-material patches — through the decal shader, which keeps
    /// what falls in the decal's box; pulled toward the eye to win the surface.
    private func drawDecals(encoder: MTLRenderCommandEncoder) {
        guard !scene.decals.isEmpty else { return }
        decalTextures.sync(images: scene.decals.map { ($0.id, 0, $0.image) }, device: context.device)
        let pipelines = context.pipelines
        encoder.setDepthStencilState(pipelines.depthReadOnly)
        encoder.setDepthBias(-2, slopeScale: -2, clamp: 0)
        defer { encoder.setDepthBias(0, slopeScale: 0, clamp: 0) }
        var frame = makeFrameUniforms()
        for decal in scene.decals {
            guard let drawable = scene.bodies.first(where: { $0.id == decal.bodyID }), !drawable.isTranslucent,
                  let resources = cache.resources(for: decal.bodyID),
                  let texture = decalTextures.texture(for: decal.id) else { continue }
            encoder.setRenderPipelineState(pipelines.decal)
            var body = makeBodyUniforms(drawable)
            var u = DecalUniforms()
            u.center = SIMD4(decal.center, 1)
            u.axisU = SIMD4(decal.u, decal.halfWidth)
            u.axisV = SIMD4(decal.v, decal.halfHeight)
            u.normal = SIMD4(decal.n, decal.depth)
            u.opacity = decal.opacity
            u.selected = decal.isSelected ? 1 : 0
            encoder.setVertexBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                   index: Int(BufferIndexBodyUniforms.rawValue))
            encoder.setFragmentBytes(&frame, length: MemoryLayout<FrameUniforms>.stride,
                                     index: Int(BufferIndexFrameUniforms.rawValue))
            encoder.setFragmentBytes(&u, length: MemoryLayout<DecalUniforms>.stride,
                                     index: Int(BufferIndexDecal.rawValue))
            encoder.setFragmentTexture(texture, index: 0)
            if resources.indexCount > 0 {
                encoder.setVertexBuffer(resources.positionBuffer, offset: 0, index: Int(BufferIndexPositions.rawValue))
                encoder.setVertexBuffer(resources.normalBuffer, offset: 0, index: Int(BufferIndexNormals.rawValue))
                encoder.drawIndexedPrimitives(type: .triangle, indexCount: resources.indexCount, indexType: .uint32,
                                              indexBuffer: resources.indexBuffer, indexBufferOffset: 0)
            }
            for patch in scene.facePatches where patch.bodyID == decal.bodyID {
                guard let buffers = patchBuffers[patch.key] else { continue }
                encoder.setVertexBuffer(buffers.positions, offset: 0, index: Int(BufferIndexPositions.rawValue))
                encoder.setVertexBuffer(buffers.normals, offset: 0, index: Int(BufferIndexNormals.rawValue))
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: buffers.count)
            }
        }
    }

    /// Face materials (spec §14): the faces a body leaves out, each drawn in
    /// its own material — opaque ones (`seeThrough` false) with the opaque
    /// bodies, see-through ones (true) in the blended pass; nil draws all.
    private func drawFacePatches(seeThrough: Bool?, encoder: MTLRenderCommandEncoder,
                                 pipeline: MTLRenderPipelineState, alphaOverride: Float? = nil) {
        let drawn = Set(scene.bodies.filter { !$0.isTranslucent }.map(\.id))
        for patch in scene.facePatches where drawn.contains(patch.bodyID) {
            if let seeThrough, (patch.material.baseColor.w < 0.999) != seeThrough { continue }
            if patchBuffers[patch.key] == nil {
                let length = patch.positions.count * MemoryLayout<SIMD3<Float>>.stride
                guard length > 0,
                      let positions = patch.positions.withUnsafeBytes({
                          context.device.makeBuffer(bytes: $0.baseAddress!, length: length, options: .storageModeShared)
                      }),
                      let normals = patch.normals.withUnsafeBytes({
                          context.device.makeBuffer(bytes: $0.baseAddress!, length: length, options: .storageModeShared)
                      }) else { continue }
                patchBuffers[patch.key] = (positions, normals, patch.positions.count)
            }
            guard let buffers = patchBuffers[patch.key] else { continue }
            encoder.setRenderPipelineState(pipeline)
            var body = makeBodyUniforms(BodyDrawable(
                id: patch.bodyID, renderMesh: RenderMesh(positions: [], normals: [], indices: []), edges: nil,
                meshRevision: 0, modelMatrix: patch.modelMatrix, baseColor: patch.material.baseColor,
                selectionState: patch.selectionState, material: patch.material))
            if let alphaOverride { body.baseColor.w = alphaOverride }
            let picture = patch.material.pattern > MaterialPattern.imageThreshold
                ? patchTextures.texture(for: patch.material.textureRevision) : nil
            encoder.setFragmentTexture(picture ?? whiteTexture, index: 0)
            encoder.setVertexBuffer(buffers.positions, offset: 0, index: Int(BufferIndexPositions.rawValue))
            encoder.setVertexBuffer(buffers.normals, offset: 0, index: Int(BufferIndexNormals.rawValue))
            encoder.setVertexBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                   index: Int(BufferIndexBodyUniforms.rawValue))
            encoder.setFragmentBytes(&body, length: MemoryLayout<BodyUniforms>.stride,
                                     index: Int(BufferIndexBodyUniforms.rawValue))
            var frame = makeFrameUniforms()
            encoder.setFragmentBytes(&frame, length: MemoryLayout<FrameUniforms>.stride,
                                     index: Int(BufferIndexFrameUniforms.rawValue))
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: buffers.count)
        }
    }

    private func makeBodyUniforms(_ drawable: BodyDrawable) -> BodyUniforms {
        var body = BodyUniforms()
        body.modelMatrix = drawable.modelMatrix
        body.baseColor = drawable.baseColor
        body.selectionState = drawable.selectionState
        // Visualization-lite material: zero metallic/roughness (the C-struct
        // default) keeps the legacy shading path in fragment_lit.
        if let material = drawable.material {
            body.baseColor = material.baseColor
            body.metallic = material.metallic
            body.roughness = material.roughness
            body.emission = material.emission
            body.pattern = material.pattern
            body.patternSize = material.patternSize
            body.patternRotation = material.patternRotation
        }
        return body
    }
}
