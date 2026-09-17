"""Narration and chapter panels for the three tutorials. `say` is spoken;
title/sub/lines fill the chapter panel; `chapter` groups segments into the
YouTube description's chapter list."""

SKETCHING = [
 {"id": "intro", "chapter": "Intro", "title": "Sketching", "sub": "Tutorial 1 of 3",
  "lines": ["Sketch planes", "Rectangles, circles, lines, arcs", "Dimensions and constraints", "From sketch to solid"],
  "say": "Welcome to OpenShape 3D, a free, open-source CAD app for iPad. This is the first video in a short series, and it's all about sketching: the two-D drawings that every solid model starts from. We'll pick a plane, draw a few shapes, give them exact dimensions, and see how constraints keep everything lined up."},
 {"id": "planes", "chapter": "Sketch planes", "title": "Every sketch lives on a plane", "sub": "Sketch › Rectangle, then pick a plane",
  "lines": ["Ground, front and right planes at the origin", "Or tap any flat face of a body", "The camera turns to face the plane"],
  "say": "Let's start a blank design. Every sketch lives on a plane. When you pick a sketch tool, the app offers the three planes at the origin: ground, front and right. You can also tap any flat face on an existing body. I'll tap the ground plane, and the camera turns to look straight at it."},
 {"id": "rectangle", "chapter": "Rectangle", "title": "Draw, then type the size", "sub": "Diagonal rectangle",
  "lines": ["Drag between opposite corners", "Snaps to the grid as you draw", "Rough is fine: the numbers come next"],
  "say": "The rectangle tool draws between two opposite corners: touch down on one corner and drag to the other. Don't worry about the exact size while drawing. Rough is fine, because in CAD the numbers come next."},
 {"id": "dimension", "chapter": "Dimensions", "title": "Dimensions are constraints", "sub": "Tap an edge, tap its label, type a value",
  "lines": ["Select a line to see its dimension", "Type the exact length", "A typed dimension holds when you edit later"],
  "say": "Tap an edge and its dimension appears. Tap the label and type the exact length: forty millimeters. Now the width is locked. That's the important idea in a parametric sketch: a dimension you type isn't just a number, it's a constraint that keeps holding as you keep editing."},
 {"id": "circles", "chapter": "Circles", "title": "Circles", "sub": "Center, then radius",
  "lines": ["Touch the center, drag out the radius", "Guides snap to the middle of edges", "Radius or diameter readout in Settings"],
  "say": "Circles work the same way: touch down on the center and drag out the radius. As you move, guidelines snap to the middle of edges and to other points, so it's easy to center a hole exactly. Let's add two, for mounting holes."},
 {"id": "lines_arcs", "chapter": "Lines, arcs, polygons", "title": "Lines, arcs and more", "sub": "The rest of the Sketch palette",
  "lines": ["Line: tap point to point", "Arc: center, start and end", "Polygon, ellipse and spline", "Text and construction geometry"],
  "say": "The palette has the rest of the usual shapes. Lines go tap to tap and chain into a path. Arcs take a center, a start and an end. There are polygons, ellipses, and splines that flow through the points you place. Here are a few of them on the same plane."},
 {"id": "constraints", "chapter": "Constraints", "title": "Constraints", "sub": "Horizontal, vertical, coincident, tangent…",
  "lines": ["Many are added automatically as you draw", "The Constrain panel adds more", "Select two lines to make them parallel or equal"],
  "say": "While you draw, the app adds constraints for you: a line you drew nearly flat becomes horizontal, endpoints that touch become coincident. The Constrain panel adds the rest: parallel, perpendicular, tangent, equal, and lock. Select two lines and tap Parallel, and they stay parallel no matter how you drag them."},
 {"id": "editing", "chapter": "Editing", "title": "Editing a sketch", "sub": "Select, drag, delete, undo",
  "lines": ["Tap to select, drag to move", "Delete removes what's selected", "Undo and redo cover every step"],
  "say": "Everything stays editable. Tap to select, drag a point or a line to move it, and the constraints follow. Delete removes the selection, and undo and redo cover every step, so you can experiment freely."},
 {"id": "profiles", "chapter": "Profiles", "title": "Closed loops become profiles", "sub": "What the solid tools look for",
  "lines": ["A closed outline is a region", "A loop inside a loop is a hole", "Open lines are guides, not faces"],
  "say": "Here's what the three-D tools care about. A closed outline becomes a region you can extrude or revolve. A loop inside another loop, like our circles, becomes a hole. Open lines don't make faces, but they're useful as guides and as paths for sweeps."},
 {"id": "extrude", "chapter": "Sketch to solid", "title": "From sketch to solid", "sub": "Exit Sketching, then Extrude",
  "lines": ["Exit Sketching", "Tap the region, pull the arrow or type a height", "Holes come along for free"],
  "say": "Tap Exit Sketching, then pick Extrude, tap the region, and pull the arrow or type a height. The plate comes up six millimeters, and the circles become holes automatically. That's a sketch turned into a solid."},
 {"id": "outro", "chapter": "Next", "title": "Next: shapes", "sub": "Extrude, revolve, sweep, loft and booleans",
  "lines": ["Try the sample designs in the Demos folder", "Free and open source on GitHub", "Next video: from sketch to solid shapes"],
  "say": "That's sketching. Open the sample designs in the Demos folder to see finished sketches, and try changing a dimension to watch the model rebuild. In the next video we go from sketches to shapes: extrude, revolve, sweep, loft, and booleans. Thanks for watching."},
]

SHAPES = [
 {"id": "intro", "chapter": "Intro", "title": "Shapes", "sub": "Tutorial 2 of 3",
  "lines": ["Extrude and revolve", "Sweep and loft", "Booleans", "Fillet, chamfer, shell, pattern"],
  "say": "Welcome back to OpenShape 3D. In this video we turn sketches into solid shapes. We'll extrude and revolve, sweep and loft, combine bodies with booleans, and finish with fillets, chamfers, shells and patterns. Every shape starts as a two-D sketch, so if you haven't seen the sketching video, watch that first."},
 {"id": "extrude", "chapter": "Extrude", "title": "Extrude", "sub": "A profile pushed along its normal",
  "lines": ["Sketch a rectangle, extrude it into a block", "A circle becomes a cylinder", "Pull the arrow or type the distance"],
  "say": "Extrude is the workhorse. A rectangle becomes a block, a circle becomes a cylinder. Select the region, then pull the arrow or type the distance. Symmetric extrudes grow both ways from the sketch plane, and a taper angle gives you drafted walls."},
 {"id": "revolve", "chapter": "Revolve", "title": "Revolve", "sub": "A profile spun around an axis",
  "lines": ["Sketch half of the outline", "Pick the axis", "Full turn, or any angle"],
  "say": "Revolve spins a profile around an axis. Sketch half of the outline, pick the axis, and choose a full turn or any angle. It's how you make anything round: knobs, bottles, wheels, pulleys. Here's a small handle from one profile."},
 {"id": "sweep", "chapter": "Sweep", "title": "Sweep", "sub": "A profile pushed along a path",
  "lines": ["A circle swept along a curve makes a tube", "The path can be lines, arcs or a helix", "Pipes, wires, springs"],
  "say": "Sweep pushes a profile along a path. A circle swept along a curve gives you a bent tube. The path can be lines and arcs, or a helix for springs and threads. Here's a tube following an arc."},
 {"id": "loft", "chapter": "Loft", "title": "Loft", "sub": "A smooth skin between profiles",
  "lines": ["Two or more profiles on different planes", "The solid blends from one to the next", "Funnels, hulls, transitions"],
  "say": "Loft blends between two or more profiles on different planes. A square at the bottom and a circle above it become a smooth transition, the classic square-to-round adapter. Add more sections and the surface flows through all of them."},
 {"id": "booleans", "chapter": "Booleans", "title": "Booleans", "sub": "Union, subtract, intersect",
  "lines": ["Union fuses bodies into one", "Subtract cuts one body out of another", "Intersect keeps only the overlap", "Or choose the boolean while extruding"],
  "say": "Booleans combine bodies. Union fuses them into one solid. Subtract cuts one body out of another, which is how you make holes and pockets. Intersect keeps only the overlap. You can also pick the boolean right on the extrude, so a cut is a single step."},
 {"id": "fillet", "chapter": "Fillet and chamfer", "title": "Fillet and chamfer", "sub": "Rounds and bevels on edges",
  "lines": ["Tap the edges, type the radius", "A tap on a rim picks the whole tangent chain", "Chamfer cuts a flat bevel"],
  "say": "Fillet rounds an edge with a radius, and chamfer cuts a flat bevel. Tap the edges you want, type the size, and apply. A tap on a curved rim picks up the whole chain of tangent edges, so a full round takes one tap."},
 {"id": "shell", "chapter": "Shell", "title": "Shell", "sub": "Hollow a body to a wall thickness",
  "lines": ["Pick the faces to leave open", "Type the wall thickness", "Cups, enclosures, housings"],
  "say": "Shell hollows a body out to a wall thickness. Pick the faces you want open, type the thickness, and the inside is removed. That's how you make a cup, an enclosure or a casting."},
 {"id": "pattern", "chapter": "Pattern and mirror", "title": "Pattern and mirror", "sub": "Repeat a body around an axis or across a plane",
  "lines": ["Circular pattern: count and axis", "Mirror across a plane", "Each copy follows the original"],
  "say": "Pattern repeats a body: a circular pattern around an axis, with a count and an angle. Mirror reflects a body across a plane. The copies are linked to the original, so change the source and every copy updates."},
 {"id": "history", "chapter": "History", "title": "Everything is a feature", "sub": "The History panel",
  "lines": ["Each shape you made is a step", "Edit a value and the model rebuilds", "Suppress a step to try without it"],
  "say": "Every shape we made is a feature in the History panel. Tap a step to change its value, and everything after it rebuilds. You can even suppress a step to see the model without it. That's parametric modeling."},
 {"id": "outro", "chapter": "Next", "title": "Next: materials", "sub": "Presets, color, metallic and roughness",
  "lines": ["Try the Modify and Combine palettes", "Free and open source on GitHub", "Next video: materials and appearance"],
  "say": "Those are the shape tools. Try them on the sample designs, and in the next video we'll give the models some materials: presets, custom colors, metallic and roughness. Thanks for watching."},
]

MATERIALS = [
 {"id": "intro", "chapter": "Intro", "title": "Materials", "sub": "Tutorial 3 of 3",
  "lines": ["The Material tool", "Presets: steel, aluminum, brass, plastic, rubber, wood", "Color, metallic and roughness", "Appearance only, geometry stays exact"],
  "say": "Welcome to the third OpenShape 3D tutorial: materials. We'll open a sample design, give its bodies materials from the presets, then build a custom look with color, metallic and roughness. Materials are appearance only. The geometry underneath stays exact, so nothing about your part changes except how it looks."},
 {"id": "open", "chapter": "Opening a sample", "title": "The motorcycle wheel", "sub": "Add Sample Designs › Demos › Motorcycle Wheel",
  "lines": ["Two bodies: the rim and the tyre", "Double-tap a body to select it", "The Material tool lives in the palette"],
  "say": "I'll add the sample designs and open the motorcycle wheel. It has two bodies, the rim and the tyre. Double-tap a body to select it as a whole, and the Material tool in the palette lights up."},
 {"id": "sheet", "chapter": "The Material sheet", "title": "The Material sheet", "sub": "Presets on top, custom below",
  "lines": ["Presets: one tap sets color, metallic and roughness", "Custom: a color picker and two sliders", "Apply commits one undoable step"],
  "say": "Tap Material and the sheet opens. The presets on top set a color, a metallic value and a roughness in one tap. Below them you can pick any color and adjust the two sliders yourself. Apply commits it as one undoable step. Let's make the rim aluminum."},
 {"id": "presets", "chapter": "Presets", "title": "The presets", "sub": "Steel · Aluminum · Brass · Plastic Matte · Plastic Gloss · Rubber · Wood",
  "lines": ["Metals: metallic 100 %, low roughness", "Plastics: metallic 0 %", "Rubber and wood: rough, no shine"],
  "say": "Here are all the presets on the rim, one after another. Steel, aluminum and brass are metals: fully metallic with a low roughness, so they reflect the environment. Plastic matte and plastic gloss have no metallic at all, and differ only in roughness. Rubber and wood are rough with no shine."},
 {"id": "metallic", "chapter": "Metallic and roughness", "title": "Metallic", "sub": "Is it a metal or not?",
  "lines": ["0 %: a painted or plastic surface", "100 %: reflections take the base color", "In between rarely looks real"],
  "say": "Metallic is a yes-or-no kind of value. At zero, the surface behaves like paint or plastic: it has a colored base and a white highlight. At one hundred percent, the whole surface reflects, and the reflections take on the base color. Values in between rarely look like a real material, so pick one or the other."},
 {"id": "roughness", "title": "Roughness", "sub": "How sharp the highlights are",
  "lines": ["Low: mirror-like, tight highlights", "High: soft, diffuse", "Most real parts sit between 20 and 60 %"],
  "say": "Roughness controls how sharp the highlights are. Low roughness is mirror-like with tight, bright highlights. High roughness scatters the light into a soft sheen. Watch the rim go from polished to brushed as I raise it."},
 {"id": "custom", "chapter": "Custom colors", "title": "Custom colors", "sub": "Pick a color, then tune the sliders",
  "lines": ["Any color from the picker", "Plastic: metallic 0, roughness to taste", "Painted metal: metallic 0, roughness low"],
  "say": "For a custom look, pick a color, then tune the sliders. A blue with zero metallic and a medium roughness reads as plastic. Drop the roughness and it looks like glossy paint. The tyre gets the rubber preset, which is exactly what it is."},
 {"id": "bottle", "chapter": "More examples", "title": "The glass bottle", "sub": "A light tint with low roughness",
  "lines": ["Tinted, smooth, non-metallic", "Materials are per body", "Every change is one undo step"],
  "say": "Let's give the glass bottle a look too: a light green tint, no metallic, and a low roughness for a smooth, glossy surface. Materials are per body, so an assembly can mix as many as you like, and every change is a single undo step."},
 {"id": "geometry", "chapter": "Appearance vs geometry", "title": "Appearance, not geometry", "sub": "The numbers don't change",
  "lines": ["Volume and dimensions stay the same", "Materials aren't in the feature history", "Exports carry the exact geometry"],
  "say": "One last thing. Materials never touch the geometry. The volume in the info bar is the same before and after, they don't appear as steps in the history, and when you export a STEP or STL file, it's the exact solid that goes out."},
 {"id": "outro", "chapter": "Wrap-up", "title": "That's the series", "sub": "Sketching · Shapes · Materials",
  "lines": ["Sample designs in the Demos folder", "Free and open source on GitHub", "Questions and requests in the comments"],
  "say": "That wraps up the series: sketching, shapes and materials. The app is free and open source, and the sample designs in the Demos folder are a good place to keep exploring. If there's a tool you'd like covered next, leave a comment. Thanks for watching."},
]

VIDEOS = {
 "sketching": {
  "script": SKETCHING, "series": "Tutorial 1 · Sketching",
  "title_card": "Sketching", "title_sub": "OpenShape 3D tutorial · part 1 of 3",
  "outro_foot": "Next: from sketch to solid shapes",
  "title": "OpenShape 3D Tutorial: Sketching on iPad — Planes, Dimensions & Constraints (Free CAD App)",
  "thumb": "SKETCHING · exact dimensions on iPad",
  "description": """Learn sketching in OpenShape 3D, the free, open-source CAD app for iPad. In this first tutorial of the series we pick a sketch plane, draw rectangles and circles by touch, type exact dimensions, look at lines, arcs, polygons and splines, and see how constraints keep a sketch true. We finish by extruding the sketch into a solid plate.

What you'll learn
• How sketch planes work (ground, front, right, or any flat face)
• Drawing rectangles and circles by touch, then typing exact sizes
• Why a dimension is a constraint, and how auto-constraints work
• Lines, arcs, polygons, ellipses and splines
• Closed loops, holes and open guide lines
• Turning a sketch into a solid with Extrude""",
  "footer": """OpenShape 3D is free and open source (MIT). Source code, issues and releases:
https://github.com/laanlabs/openshape3d

Series
Part 1 – Sketching (this video)
Part 2 – Shapes: extrude, revolve, sweep, loft and booleans
Part 3 – Materials: presets, color, metallic and roughness

#CAD #iPad #3Dmodeling #OpenSource #OpenShape3D""",
  "tags": ["OpenShape 3D", "CAD", "iPad CAD", "3D modeling", "sketching tutorial", "parametric modeling", "constraints", "dimensions",
           "free CAD app", "open source CAD", "iPad Pro", "Apple Pencil", "3D printing design", "solid modeling", "CAD tutorial for beginners",
           "Shapr3D alternative", "Fusion 360 alternative", "B-rep", "OpenCASCADE", "sketch plane"],
 },
 "shapes": {
  "script": SHAPES, "series": "Tutorial 2 · Shapes",
  "title_card": "Shapes", "title_sub": "OpenShape 3D tutorial · part 2 of 3",
  "outro_foot": "Next: materials and appearance",
  "title": "OpenShape 3D Tutorial: Extrude, Revolve, Sweep, Loft & Booleans on iPad (Free CAD App)",
  "thumb": "SHAPES · sketch to solid",
  "description": """Turn sketches into solid shapes in OpenShape 3D, the free, open-source CAD app for iPad. Part 2 of the tutorial series covers every solid tool: extrude and revolve, sweep and loft, booleans (union, subtract, intersect), fillet and chamfer, shell, and circular patterns and mirrors, ending with the parametric History panel.

What you'll learn
• Extrude: blocks, cylinders, symmetric and tapered extrudes
• Revolve: anything round from a single profile
• Sweep: tubes and springs along a path
• Loft: smooth transitions between profiles
• Booleans: union, subtract and intersect
• Fillet, chamfer and shell
• Pattern and mirror
• Editing steps in the History panel""",
  "footer": """OpenShape 3D is free and open source (MIT). Source code, issues and releases:
https://github.com/laanlabs/openshape3d

Series
Part 1 – Sketching: planes, dimensions and constraints
Part 2 – Shapes (this video)
Part 3 – Materials: presets, color, metallic and roughness

#CAD #iPad #3Dmodeling #OpenSource #OpenShape3D""",
  "tags": ["OpenShape 3D", "CAD", "iPad CAD", "3D modeling", "extrude", "revolve", "sweep", "loft", "boolean", "fillet", "chamfer", "shell",
           "circular pattern", "parametric modeling", "free CAD app", "open source CAD", "solid modeling tutorial", "3D printing design",
           "Shapr3D alternative", "Fusion 360 alternative", "CAD tutorial for beginners", "OpenCASCADE"],
 },
 "materials": {
  "script": MATERIALS, "series": "Tutorial 3 · Materials",
  "title_card": "Materials", "title_sub": "OpenShape 3D tutorial · part 3 of 3",
  "outro_foot": "Sketching · Shapes · Materials",
  "title": "OpenShape 3D Tutorial: Materials & Appearance on iPad — Presets, Color, Metallic, Roughness",
  "thumb": "MATERIALS · metal, plastic, rubber, glass",
  "description": """Give your models a realistic look in OpenShape 3D, the free, open-source CAD app for iPad. Part 3 of the tutorial series opens the motorcycle wheel sample, applies the material presets (steel, aluminum, brass, plastic matte and gloss, rubber, wood), then explains metallic and roughness and builds custom colors, a rubber tyre and a tinted glass bottle. Materials are appearance only: the geometry, the history and your exports stay exact.

What you'll learn
• Selecting a body and opening the Material sheet
• What each preset does
• Metallic: metal or not
• Roughness: from polished to matte
• Custom colors for plastics and painted metal
• Why materials never change your geometry""",
  "footer": """OpenShape 3D is free and open source (MIT). Source code, issues and releases:
https://github.com/laanlabs/openshape3d

Series
Part 1 – Sketching: planes, dimensions and constraints
Part 2 – Shapes: extrude, revolve, sweep, loft and booleans
Part 3 – Materials (this video)

#CAD #iPad #3Dmodeling #OpenSource #OpenShape3D""",
  "tags": ["OpenShape 3D", "CAD", "iPad CAD", "3D modeling", "materials", "PBR", "metallic roughness", "rendering", "material presets",
           "appearance", "parametric modeling", "free CAD app", "open source CAD", "3D printing design", "Shapr3D alternative",
           "Fusion 360 alternative", "CAD tutorial for beginners", "product design iPad"],
 },
}
