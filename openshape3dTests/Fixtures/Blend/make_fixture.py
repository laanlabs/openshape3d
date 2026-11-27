# Writes the Blender 5 test files. Run with Blender 5.x:
#   Blender -b --factory-startup --python make_fixture.py -- <folder>
# The compressed one is checked in as blender-5.3-materials.blend.
import bpy, sys, os, math, mathutils
out = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)

def material(name, color, metallic, roughness, emission=None, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*color, 1.0)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Alpha'].default_value = alpha
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*emission[0], 1.0)
        bsdf.inputs['Emission Strength'].default_value = emission[1]
    return m

# A crate standing on the ground.
bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 1))
cube = bpy.context.object; cube.name = "Crate"
cube.data.materials.append(material("Red Paint", (0.8, 0.1, 0.05), 0.0, 0.35))

# A pillar laid on its side: an Euler rotation.
bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.5, depth=3, location=(3, 0, 1.5))
cyl = bpy.context.object; cyl.name = "Pillar"
cyl.rotation_euler = (math.radians(90), 0, 0)
cyl.data.materials.append(material("Brushed Steel", (0.55, 0.57, 0.6), 0.9, 0.25))

# A panel that hangs off the crate: a parent, a parent inverse, a
# quaternion rotation and a scale.
bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 3, 0.5))
lamp = bpy.context.object; lamp.name = "Glow Panel"
lamp.parent = cube
lamp.matrix_parent_inverse = mathutils.Matrix.Translation((0, 0, -1))
lamp.rotation_mode = 'QUATERNION'
lamp.rotation_quaternion = mathutils.Quaternion((1, 0, 0), math.radians(90))
lamp.scale = (2, 2, 2)
lamp.data.materials.append(material("Glow", (0.1, 0.6, 1.0), 0.0, 0.5, emission=((0.1, 0.6, 1.0), 4.0), alpha=0.5))

# What the importer should find, for the test: world bounds in metres.
bpy.context.view_layer.update()
for ob in (cube, cyl, lamp):
    points = [ob.matrix_world @ v.co for v in ob.data.vertices]
    low = [round(min(p[i] for p in points), 4) for i in range(3)]
    high = [round(max(p[i] for p in points), 4) for i in range(3)]
    print("BOUNDS", ob.name, low, high)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, "b5-plain.blend"), compress=False)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, "b5-zstd.blend"), compress=True)
print("SAVED", bpy.app.version_string)
