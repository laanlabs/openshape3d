"""Narration, chapter panels and YouTube text for the ten project tutorials
(projects.py builds the models). `say` is spoken; title/sub/lines fill the
chapter panel; `chapter` is the YouTube chapter label."""


def seg(id, chapter, title, sub, lines, say):
    return {"id": id, "chapter": chapter, "title": title, "sub": sub, "lines": lines, "say": say}


FOOTER = """OpenShape 3D is free and open source (MIT). Source code, issues and releases:
https://github.com/laanlabs/openshape3d

Project tutorials
1 – Coffee mug · 2 – Chess pawn & rook · 3 – LEGO-style brick · 4 – Name keychain · 5 – Twisted vase
6 – Bolt & nut with threads · 7 – Spur gears · 8 – Fidget spinner · 9 – Ice cube tray · 10 – Print-in-place hinged box

Basics: Sketching · Shapes · Materials

#CAD #iPad #3Dprinting #3Dmodeling #OpenShape3D"""

BASE_TAGS = ["OpenShape 3D", "iPad CAD", "CAD tutorial", "3D modeling", "3D printing", "3D printing design",
             "free CAD app", "open source CAD", "CAD for beginners", "iPad Pro", "Shapr3D alternative",
             "Fusion 360 alternative", "parametric modeling"]


def video(n, slug, name, script, title, thumb, description, tags, outro_foot):
    return {"script": script, "slug": slug, "series": f"Project {n} · {name}",
            "title_card": name, "title_sub": f"OpenShape 3D project tutorial · {n} of 10",
            "outro_foot": outro_foot, "title": title, "thumb": thumb,
            "description": description, "footer": FOOTER, "tags": tags + BASE_TAGS}


OUTRO = "Free on iPad · github.com/laanlabs/openshape3d"

# ---- 1. coffee mug -------------------------------------------------------------------

MUG = [
 seg("intro", "Intro", "Coffee mug", "Project 1 of 10",
     ["Revolve the body", "Shell it hollow", "Sweep the handle", "Export for printing"],
     "In this tutorial we'll model a classic coffee mug in OpenShape 3D, the free, open-source CAD app for iPad. It's the perfect first project: a revolve for the body, a shell to hollow it out, and a sweep for the handle. Let's start a blank design."),
 seg("profile", "Half profile", "Sketch half the mug", "Front plane · Line",
     ["38 mm radius at the base", "Leans out to 41 mm at the top", "95 mm tall", "The center line is the axis"],
     "Every round object starts as a half profile. On the front plane, sketch half of the mug's cross-section: thirty-eight millimeters out along the bottom, a wall that leans out slightly to forty-one at the top, ninety-five millimeters tall, and a line back down the center. That center line will be our axis."),
 seg("revolve", "Revolve", "Revolve", "Tap the profile › Revolve › tap the axis",
     ["The extrude bar offers Revolve", "Tap the center line as the axis", "A full 360° turn"],
     "Tap the profile and the extrude bar comes up. Choose Revolve, tap the center line as the axis, and spin it a full three hundred and sixty degrees. One sketch just became a solid mug blank."),
 seg("fillet", "Fillet the base", "Soften the base", "Modify › Fillet",
     ["Tap the bottom edge", "Radius 6 mm"],
     "Real mugs have a soft base. Choose Fillet, tap the bottom edge, and type a radius of six millimeters."),
 seg("shell", "Shell", "Hollow it out", "Modify › Shell",
     ["Tap the top face to leave it open", "Wall thickness 3.5 mm", "The inside is removed in one step"],
     "Now hollow it. Shell removes the inside and leaves a wall as thick as you type. Tap the top face to leave it open, and use three and a half millimeters, a good wall for a printed mug."),
 seg("path", "Handle sketches", "A path and a section", "Two sketches for a sweep",
     ["Path: line, half circle, line", "Section: a 14 × 9 mm ellipse", "The section sits at the path's start"],
     "The handle needs two sketches. First the path, on the front plane: a short line out of the wall, a half circle, and a line back in. Then a small ellipse, fourteen by nine millimeters, on a plane at the start of the path. That's the handle's cross-section."),
 seg("sweep", "Sweep", "Sweep the handle", "Tap the section › Sweep › tap the path",
     ["The ellipse follows the path", "Result: Union fuses it to the body", "Both ends start inside the wall"],
     "Tap the ellipse, choose Sweep, and tap the path. The ellipse travels along the path, and with the result set to Union, the handle fuses to the body in the same step. Both ends start inside the wall, so the joint is solid."),
 seg("rim", "Round the rim", "Round the rim", "Modify › Fillet",
     ["Inner and outer top edges", "Radius 1.5 mm", "Comfortable to drink from"],
     "Finally, round the rim so it's comfortable to drink from: a one and a half millimeter fillet on the inner and outer top edges."),
 seg("material", "Material", "A glossy finish", "Select the body › Material",
     ["Off-white, low roughness", "Orbit to check every side"],
     "Give it a glossy off-white finish, and turn it around to check it from every side."),
 seg("export", "Export", "Export for printing", "Export › STL",
     ["STL or 3MF for your slicer", "Save to Files, iCloud Drive or a USB drive"],
     "To print it, open the Export menu and choose STL, or 3MF. The file saves wherever you like: iCloud Drive, a USB drive, or straight into your slicer app."),
 seg("outro", "Next", "Everything stays editable", "The History panel",
     ["Change the height, the wall or the handle", "The mug rebuilds", "Next: a chess pawn and rook"],
     "Every step is in the History panel, so you can go back and change the height, the wall, or the handle, and the mug rebuilds. That's the coffee mug. Next up: chess pieces. Thanks for watching."),
]

# ---- 2. chess pawn and rook ---------------------------------------------------------------

CHESS = [
 seg("intro", "Intro", "Chess pawn & rook", "Project 2 of 10",
     ["Splines and arcs in a profile", "Revolve", "Cut battlements with a pattern", "Subtract"],
     "Chess pieces are the classic way to learn Revolve, because every piece is round. We'll model a pawn, then a rook with its battlements, in OpenShape 3D on iPad."),
 seg("pawn_profile", "Pawn profile", "The pawn's half profile", "Front plane · Line, Spline, Arc",
     ["Stepped base, 30 mm across", "A spline for the curved body", "A collar, then an arc for the head"],
     "Sketch the pawn's half profile on the front plane: a stepped base thirty millimeters across, a spline for the curved body, a collar, and an arc for the head. Splines are perfect for organic curves: they flow smoothly through the points you place."),
 seg("pawn_revolve", "Revolve the pawn", "Revolve", "Tap the profile › Revolve › tap the axis",
     ["The center line is the axis", "A full turn"],
     "Tap the profile, choose Revolve, and pick the center line. A full turn gives the finished pawn."),
 seg("rook_profile", "Rook", "The rook", "Same idea, taller profile",
     ["Flared base, 32 mm across", "A slightly tapered tower", "Wider crown, 54 mm tall"],
     "The rook is the same idea with a taller, straighter profile: a flared base, a tower that tapers slightly, and a wider crown at the top, fifty-four millimeters tall. Revolve it the same way."),
 seg("pocket", "Hollow crown", "Hollow the crown", "Extrude · Result: Subtract",
     ["A 17 mm circle on the top face", "5 mm down, subtracted"],
     "Now the battlements. First, sketch a circle on the top face and extrude it down five millimeters with the result set to Subtract. That hollows out the crown."),
 seg("slot", "Slot cutter", "One slot", "Extrude · Result: New Body",
     ["A 4.4 mm rectangle across the top", "6 mm deep", "A separate body: the cutting tool"],
     "Next, one slot: a rectangle four point four millimeters wide, right across the top, extruded six millimeters down as a separate body. This is our cutting tool."),
 seg("pattern", "Pattern & subtract", "Pattern, then subtract", "Transform › Pattern · Combine › Subtract",
     ["Circular pattern, 3 copies", "Each slot crosses the crown: 6 notches", "Subtract the cutters from the rook"],
     "Pattern it around the rook's axis: Transform, Pattern, circular, three copies. Each slot crosses the whole crown, so three of them make six notches. Then Combine, Subtract, and the cutters are gone, leaving the battlements."),
 seg("material", "Material", "Wood", "Select the bodies › Material",
     ["A warm wood finish", "Printing? Pick any color"],
     "A warm wood material suits a chess set. Of course, if you're printing them, pick any color you like."),
 seg("export", "Export", "Export for printing", "Export › STL",
     ["Each piece prints standing up", "Scale both together for a bigger set"],
     "Export the pieces as an STL. They print standing up, and if you want a bigger set, scale both pieces together so they stay in proportion."),
 seg("outro", "Next", "Two techniques", "Revolve + pattern & subtract",
     ["Try the bishop and the queen", "Next: a LEGO-style brick"],
     "Two pieces, two techniques: revolve for the shape, and pattern plus subtract for the details. Try the bishop and the queen with the same tools. Thanks for watching."),
]

# ---- 3. LEGO-style brick ---------------------------------------------------------------------

BRICK = [
 seg("intro", "Intro", "LEGO-style 2×4 brick", "Project 3 of 10",
     ["Exact dimensions", "Shell", "Linear patterns", "Union"],
     "Let's model a LEGO-compatible two by four brick. It's a great exercise in exact dimensions, shells and patterns, and on a well-tuned printer it clicks onto real bricks."),
 seg("block", "The block", "31.8 × 15.8 × 9.6 mm", "Rectangle · tap it · type the height",
     ["8 mm per stud", "minus 0.1 mm each side", "Height 9.6 mm"],
     "The brick is thirty-one point eight by fifteen point eight millimeters: eight millimeters per stud, minus a tenth on each side so neighboring bricks don't rub. Tap the rectangle, and type the height: nine point six."),
 seg("shell", "Shell", "Hollow underside", "Modify › Shell",
     ["Bottom face open", "1.2 mm walls"],
     "Flip to the bottom view. Shell with the bottom face open and a one point two millimeter wall gives the hollow underside."),
 seg("stud", "One stud", "One stud", "Sketch on the top face",
     ["4.8 mm circle", "1.7 mm tall"],
     "Now one stud, on the top face: a circle four point eight millimeters across, extruded one point seven millimeters up."),
 seg("pattern", "Pattern the studs", "Pattern instead of copying", "Transform › Pattern · linear",
     ["4 copies, 8 mm apart", "Union the row", "Pattern the row across, union into the brick"],
     "Instead of drawing eight studs, pattern one. Transform, Pattern, linear, four copies eight millimeters apart. Union them into a row, pattern the row across, and union everything into the brick."),
 seg("tubes", "Tubes", "The tubes underneath", "Two circles make a ring",
     ["6.51 mm outside, 4.8 mm inside", "Up to the ceiling", "Pattern ×3, union"],
     "Underneath, tubes grip the studs of the brick below: six point five one millimeters outside, four point eight inside. Draw one as two circles, extrude the ring up to the ceiling, pattern it three times and union it in."),
 seg("material", "Material", "Classic red", "Select the body › Material",
     ["The tubes sit between the stud positions"],
     "Classic red. From below you can see the three tubes sitting exactly between the stud positions."),
 seg("export", "Export", "Export for printing", "Export › STL",
     ["Print studs up", "The ceiling bridges: no supports"],
     "Export it as an STL and print it studs up. The ceiling is a short bridge, so it needs no supports."),
 seg("outro", "Next", "Make it any size", "Edit the numbers in History",
     ["2×2, 1×8 or a plate", "Next: a name keychain"],
     "Change the dimensions and the pattern counts to make a two by two, a one by eight or a flat plate: the numbers are all in the history. Thanks for watching."),
]

# ---- 4. name keychain ----------------------------------------------------------------------------

KEYCHAIN = [
 seg("intro", "Intro", "Name keychain", "Project 4 of 10",
     ["A rounded tag", "The Text tool", "Raised letters", "Two colors"],
     "A name keychain is the most popular first 3D print there is. We'll make one in OpenShape 3D on iPad, with raised letters you can print in a second color."),
 seg("plate", "The tag", "60 × 20 mm tag", "Rectangle · tap it · type the height",
     ["On the ground plane", "3 mm thick"],
     "Start with a rectangle, sixty by twenty millimeters, on the ground plane. Tap it and type three millimeters for the height."),
 seg("round", "Round corners", "Round the corners", "Modify › Fillet",
     ["The four short vertical edges", "Radius 6 mm"],
     "Round the four corners with a six millimeter fillet, so it's nice in a pocket."),
 seg("hole", "Key ring hole", "A hole for the ring", "Circle · Extrude · Result: Subtract",
     ["6 mm across", "Cut straight through"],
     "Add a six millimeter hole for the key ring near one end, and cut it straight through with a subtract extrude."),
 seg("text", "Text tool", "The Text tool", "Sketch › Text",
     ["Tap the tag's top face to sketch on it", "Tap where the text starts", "Type the name · height 10 mm · Add"],
     "Now the name. Pick the Text tool from the Sketch menu, tap the top of the tag to sketch on it, then tap where the text should start. Type the name, keep the height at ten millimeters, and tap Add. The letters arrive as ordinary sketch outlines."),
 seg("raise", "Raise the letters", "Raise the letters", "Extrude · Result: New Body",
     ["1.6 mm tall", "Union the letters together", "Separate from the tag: a second color"],
     "Extrude the letters up one point six millimeters as a new body, and union them together. Keeping the letters separate from the tag means you can print them in a different color."),
 seg("turn", "Face the camera", "Turn it to face us", "Transform › Rotate",
     ["Text follows the face's own axes", "Rotate tag and letters 135° about vertical", "Now the name reads from the front"],
     "The Text tool writes along the face's own axes, which here run across our view. So select the tag and the letters and rotate them one hundred thirty-five degrees around the vertical axis, and the name faces the camera."),
 seg("colors", "Two colors", "Two colors", "Select a body › Material",
     ["Blue tag, white letters", "Multi-color printer: a filament per body", "Single color: pause and swap at the letters"],
     "A blue tag with white letters. On a multi-color printer, give each body its own filament. On a single-color printer, just pause at the layer where the letters start and swap the filament."),
 seg("export", "Export", "Export as 3MF", "Export › 3MF",
     ["Each body is its own object", "Ready to assign filaments"],
     "Export it as a 3MF file: each body comes through as its own object, ready for you to assign a filament to each."),
 seg("outro", "Next", "Make one for everyone", "Change the text, extrude again",
     ["Next: a twisted vase"],
     "Change the text and extrude again for the next name. Thanks for watching."),
]

# ---- 5. twisted vase -----------------------------------------------------------------------------

VASE = [
 seg("intro", "Intro", "Twisted vase", "Project 5 of 10",
     ["Stacked hexagon sections", "Loft through all of them", "Shell", "Vase-mode printing"],
     "Twisted vases are one of the most popular things to 3D print, and they're easy to design with a loft. Let's make one in OpenShape 3D."),
 seg("base", "The foot", "A hexagon foot", "Sketch › Polygon · 6 sides",
     ["On the ground plane", "34 mm from center to corner"],
     "Start with a hexagon on the ground plane, thirty-four millimeters from the center to each corner. That's the foot of the vase."),
 seg("sections", "Sections", "Four more sections", "Sketches on offset planes",
     ["At 45, 95, 140 and 165 mm", "Different sizes shape the silhouette", "Each turned 20° more: the twist"],
     "Add four more hexagons on planes stacked above it, at forty-five, ninety-five, one hundred forty and one hundred sixty-five millimeters. Each one is a different size, which shapes the silhouette, and each is turned twenty degrees more than the one below. That rotation is what makes the twist."),
 seg("loft", "Loft", "Loft", "Tap the first section › Loft › tap the others in order",
     ["A smooth skin through all five", "The corners spiral up the vase"],
     "Tap the first hexagon, choose Loft, then tap the others in order, bottom to top. The loft blends a smooth skin through all five, and the corners spiral up the vase."),
 seg("shell", "Shell", "Hollow it", "Modify › Shell",
     ["Top face open", "2 mm wall"],
     "Shell it with the top face open and a two millimeter wall."),
 seg("material", "Material", "Deep teal", "Select the body › Material",
     ["Low roughness for a glossy glaze"],
     "A deep teal with a glossy finish, and a slow turn to see the twist."),
 seg("vasemode", "Vase mode", "Printing tip: vase mode", "Spiral / vase mode in your slicer",
     ["Export the solid, before the shell", "The slicer prints one continuous wall", "The shelled version prints with any settings"],
     "One printing tip. If your slicer has a spiral or vase mode, export the solid version from before the shell: the slicer prints a single continuous wall, fast and seamless. The shelled version prints normally, with any settings."),
 seg("export", "Export", "Export for printing", "Export › STL",
     ["STL or 3MF"],
     "Export it as an STL or 3MF, and it's ready for the slicer."),
 seg("outro", "Next", "Make it yours", "Edit any section in History",
     ["More sides, a star, a bigger twist", "Next: a bolt and nut with threads"],
     "Try more sides, a star instead of a hexagon, or a bigger twist. Change any section in the history and the loft rebuilds. Thanks for watching."),
]

# ---- 6. bolt and nut ---------------------------------------------------------------------------------

BOLT = [
 seg("intro", "Intro", "Bolt & nut with threads", "Project 6 of 10",
     ["A hex head and shank", "A thread = a profile swept on a helix", "A matching nut", "Printable clearances"],
     "Threads look intimidating, but a thread is just a profile swept along a helix. We'll model a chunky, 3D-printable bolt and a matching nut in OpenShape 3D."),
 seg("head", "Hex head", "The hex head", "Polygon · tap it · type the height · Chamfer",
     ["19 mm across the flats", "8 mm tall", "1 mm chamfer on the top edges"],
     "The head is a hexagon, nineteen millimeters across the flats. Tap it and type eight millimeters. Then chamfer the top edges by one millimeter, like a real bolt."),
 seg("shank", "Shank", "The shank", "Circle on the head · Extrude · Result: Union",
     ["9.2 mm across: the minor diameter", "30 mm long"],
     "On top of the head, a circle nine point two millimeters across, extruded thirty millimeters and unioned on. That's the core of the thread: its minor diameter."),
 seg("profile", "Thread profile", "The thread profile", "A small trapezoid at the helix start",
     ["2.1 mm wide at the root", "A flat tip, out to a 12 mm major diameter", "Its plane faces along the helix"],
     "The thread profile is a small trapezoid: two point one millimeters wide at the root, narrowing to a flat tip that reaches out to a twelve millimeter major diameter. It sits on a plane at the start of the helix, facing along it."),
 seg("thread", "Helix sweep", "Sweep it along a helix", "Profile › Helix: radius, pitch, turns",
     ["Radius 4.6 mm · pitch 2.5 mm", "9.6 turns · Result: Union", "A coarse pitch prints reliably"],
     "Now the magic: sweep that profile along a helix. Radius four point six, a pitch of two and a half millimeters per turn, nine point six turns, unioned with the shank. A coarse pitch like this prints much more reliably than a fine metric thread."),
 seg("nut", "Nut", "The nut", "Polygon + circle · Extrude",
     ["The same 19 mm hexagon", "A 12.6 mm hole", "10 mm tall"],
     "The nut is the same hexagon with a twelve point six millimeter hole, extruded ten millimeters."),
 seg("nut_thread", "Internal thread", "An internal thread", "The profile flipped, same pitch",
     ["Points inward from the hole", "0.3 mm radial clearance", "About 0.2 mm on each flank"],
     "Its thread points inward: the same trapezoid, flipped, swept on a helix of the same pitch. The hole is point three millimeters bigger than the bolt all round, and the flanks leave about point two millimeters each side. That clearance is what lets printed threads turn."),
 seg("fit", "Test the fit", "Test the fit", "Transform › Move",
     ["Move the nut onto the bolt, thread in phase", "The solids never touch", "Half a pitch off, they would collide"],
     "Let's check the fit before printing. Move the nut onto the bolt, lined up with the thread, and the two solids don't touch anywhere: the threads interleave with clearance all round. Undo, and it's back beside the bolt."),
 seg("material", "Materials", "Steel and brass", "Select a body › Material",
     ["Double-tap to select", "Material › Steel › Apply", "Brass for the nut"],
     "Double-tap the bolt to select it, open the Material sheet, pick Steel, and apply. Brass for the nut, then one more turn around to admire the threads."),
 seg("export", "Export", "Export for printing", "Export › STL",
     ["Bolt: stand it on its head", "Nut: flat on the bed", "No supports"],
     "Export them as an STL. Print the bolt standing on its head and the nut flat on the bed; neither needs supports."),
 seg("outro", "Next", "Edit the thread", "Pitch, turns and length in History",
     ["Change the pitch or length, the thread rebuilds", "Next: spur gears"],
     "Change the pitch, the length or the clearance in the history, and the threads rebuild. Thanks for watching."),
]

# ---- 7. spur gears -------------------------------------------------------------------------------------

GEAR = [
 seg("intro", "Intro", "Spur gears", "Project 7 of 10",
     ["Module and tooth count", "An involute tooth", "Circular pattern", "A second gear that meshes"],
     "Gears are one of the most searched CAD tutorials. Let's model a real involute spur gear, and a second gear that meshes with it, in OpenShape 3D."),
 seg("numbers", "Module & teeth", "Two numbers", "Module 2 · 20 teeth",
     ["Module sets the tooth size", "Pitch circle = module × teeth = 40 mm", "Root circle ≈ 35 mm, 8 mm thick"],
     "Two numbers define a spur gear: the module, which sets the tooth size, and the number of teeth. We'll use module two and twenty teeth, so the pitch circle is forty millimeters across. Start with the root circle, about thirty-five millimeters across, and tap it to extrude eight millimeters."),
 seg("tooth", "Involute tooth", "One involute tooth", "Lines along the involute curve",
     ["Involute flanks roll smoothly", "20° pressure angle", "Tip circle 44 mm"],
     "Now one tooth. Its sides follow involute curves, the shape that keeps two gears rolling smoothly at a constant speed. I've sketched it from the standard formula, with a twenty degree pressure angle, out to the forty-four millimeter tip circle, and extruded it the same eight millimeters."),
 seg("pattern", "Pattern", "Twenty teeth", "Transform › Pattern · circular",
     ["20 copies around the center", "Union them into the blank"],
     "Pattern the tooth twenty times around the center, then union them all into the blank."),
 seg("bore", "Bore & windows", "Bore and windows", "Extrude · Subtract · Pattern",
     ["8 mm bore for the shaft", "Five 6.8 mm windows save material"],
     "Cut an eight millimeter bore for the shaft, and five round windows to save material and print time."),
 seg("pinion", "A meshing gear", "A second gear", "Same module · 12 teeth",
     ["Same module, or they won't mesh", "Centers 32 mm apart: (40 + 24) ÷ 2", "Turned half a tooth into the gaps"],
     "A second gear only meshes if it has the same module. This one has twelve teeth. Its center goes at half the sum of the two pitch diameters, thirty-two millimeters away, and it's turned half a tooth, so the teeth fall into each other's gaps."),
 seg("material", "Materials", "Brass and steel", "Select a body › Material",
     ["Double-tap to select", "Material › Brass › Apply", "Steel for the pinion"],
     "Double-tap the big gear to select it, open the Material sheet, pick Brass, and apply. Steel for the small one: the classic clockwork look."),
 seg("export", "Export", "Export for printing", "Export › STL",
     ["Print flat on the bed", "No supports"],
     "Export as an STL and print the gears flat on the bed. They need no supports."),
 seg("outro", "Next", "Change the tooth count", "Edit it in History",
     ["The pattern follows", "Next: a fidget spinner"],
     "Change the tooth count in the history, and the pattern follows. Thanks for watching."),
]

# ---- 8. fidget spinner -------------------------------------------------------------------------------

SPINNER = [
 seg("intro", "Intro", "Fidget spinner", "Project 8 of 10",
     ["Circular pattern", "Fillets for a smooth outline", "Press-fit bearing seats"],
     "Let's design a fidget spinner that takes standard six-oh-eight skateboard bearings. It's a great way to learn circular patterns, fillets, and designing for a press fit."),
 seg("hub", "Hub", "The hub", "Circle · tap it · type the height",
     ["30 mm across", "7 mm tall: a 608 bearing's width"],
     "The hub is a circle thirty millimeters across, extruded seven millimeters: exactly the width of a six-oh-eight bearing. Tap it and type the height."),
 seg("lobe", "One lobe", "One lobe", "Circle · Extrude · New Body",
     ["29 mm across", "26 mm from the center", "7 mm tall"],
     "One lobe: a twenty-nine millimeter circle, twenty-six millimeters out from the center, also seven millimeters tall."),
 seg("pattern", "Pattern", "Three lobes", "Transform › Pattern · circular · Combine › Union",
     ["3 copies around the center", "Union into one body"],
     "Pattern it three times around the center, and union everything into one body."),
 seg("fillet", "Fillet", "Smooth the joins", "Modify › Fillet",
     ["The six inside corners", "Radius 6 mm"],
     "The sharp inside corners where the lobes meet the hub look unfinished, and they're where a print would crack. Select those six edges and fillet them at six millimeters for a smooth outline."),
 seg("bearings", "Bearing seats", "Bearing seats", "Circles · Extrude · Subtract",
     ["A 608 bearing is 22 mm across", "22.1 mm holes for a press fit", "One in the center, one per lobe"],
     "A six-oh-eight bearing is twenty-two millimeters across. For a press fit, make the holes twenty-two point one: one in the center, and one in each lobe, patterned three times and subtracted. The outer bearings add weight, so it spins for longer."),
 seg("edges", "Soft edges", "Soft edges", "Modify › Fillet",
     ["Every top and bottom edge", "Radius 1 mm"],
     "Round every top and bottom edge by one millimeter, so it's comfortable in the hand."),
 seg("material", "Material", "Bright orange", "Select the body › Material",
     [],
     "Pick a bright orange, and turn it around to check the fillets from every side."),
 seg("export", "Export", "Export for printing", "Export › STL",
     ["Print it flat", "Press in the bearings", "Too tight? Change 22.1 to 22.2"],
     "Export an STL, print it flat, and press in the bearings. If they're too tight on your printer, change the hole to twenty-two point two in the history and print again."),
 seg("outro", "Next", "Four lobes?", "The pattern count is one number",
     ["Next: an ice cube tray"],
     "Want four lobes? The pattern count is one number. Thanks for watching."),
]

# ---- 9. ice cube tray ---------------------------------------------------------------------------------

TRAY = [
 seg("intro", "Intro", "Ice cube tray", "Project 9 of 10",
     ["Draft angles", "Linear patterns", "Boolean subtract", "Fillets for release"],
     "An ice cube tray is a great lesson in draft angles, patterns and boolean cuts. Let's model one in OpenShape 3D."),
 seg("block", "The tray", "The tray", "Rectangle · tap it · type the height · Fillet",
     ["116 × 76 mm", "25 mm tall", "8 mm rounded corners"],
     "The tray is a one hundred sixteen by seventy-six millimeter rectangle, twenty-five millimeters tall. Tap it, type the height, then round the four corners with an eight millimeter fillet."),
 seg("pocket", "Draft", "One cube, with draft", "Extrude · Taper 6° · New Body",
     ["A 30 mm square on the top face", "20 mm down", "6° taper: narrower at the bottom"],
     "Now one cube: a thirty millimeter square on the top face, extruded twenty millimeters down as a new body, with a six degree taper. That taper is the draft angle: the pocket is narrower at the bottom, so the ice slides out."),
 seg("pattern", "Pattern", "Six cubes", "Transform › Pattern · linear",
     ["3 along the length, 36 mm apart", "Union the row", "Pattern the row across"],
     "Pattern the cube three times along the length, thirty-six millimeters apart, union the row, and pattern the row across for six cubes."),
 seg("subtract", "Subtract", "Cut the pockets", "Combine › Subtract",
     ["The tray is the target", "The six cubes are the tools"],
     "Combine, Subtract, and the six cubes cut their pockets out of the tray."),
 seg("floor", "Fillet", "Round the pockets", "Modify › Fillet",
     ["Each pocket's floor edges", "Radius 3 mm", "Easy release, no cracks"],
     "Fillet the bottom of each pocket by three millimeters. No sharp corners means easy release, and no cracks."),
 seg("material", "Material", "Icy blue", "Select the body › Material",
     [],
     "An icy blue, and a look from every side to check the pockets."),
 seg("export", "Export", "Export for printing", "Export › STL",
     ["Print in flexible TPU and twist the cubes out", "Or use it as a master for a silicone mold"],
     "Export an STL. Print it in a flexible filament like TPU so you can twist the cubes out, or use it as a master to cast a silicone mold."),
 seg("outro", "Next", "Resize it", "Counts and sizes in History",
     ["Next: a print-in-place hinged box"],
     "Change the count or the size in the history and the tray rebuilds. Thanks for watching."),
]

# ---- 10. print-in-place hinged box -------------------------------------------------------------------------

HINGE = [
 seg("intro", "Intro", "Print-in-place hinged box", "Project 10 of 10",
     ["Knuckles and a pin", "Mirror", "Clearances", "Test the swing before printing"],
     "Print-in-place hinges come off the printer already assembled and working. Let's design a small hinged box in OpenShape 3D, and see how clearances make it possible."),
 seg("box", "The box", "The box", "Rectangle · tap it · type the height · Shell",
     ["60 × 40 mm, 30 mm tall", "Shell: top open, 2 mm walls"],
     "The box is a sixty by forty millimeter rectangle, thirty millimeters tall. Tap it, type the height, and shell it with the top open and a two millimeter wall."),
 seg("lid", "The lid", "The lid", "Sketch on an offset plane",
     ["The same rectangle, 0.4 mm above the box", "3 mm thick", "The gap is the first clearance"],
     "The lid is the same rectangle, on a plane point four millimeters above the box. That gap is the first clearance. Extrude it three millimeters."),
 seg("knuckles", "Knuckles", "Three knuckles", "Circle · Extrude · Transform › Mirror",
     ["8 mm cylinders along the back edge", "Two on the box: one, then a mirror", "One on the lid, 0.5 mm gap at each end"],
     "The hinge runs along the back edge. One knuckle is an eight millimeter cylinder, about twenty millimeters long, for the box; mirror it for the other end. The middle knuckle, which will belong to the lid, sits between them with half a millimeter gap at each end."),
 seg("clearance", "Clearances", "Cut clearance", "Combine › Subtract",
     ["Cylinders 0.4 mm bigger than the knuckles", "Cut from the lid around the box knuckles", "Cut from the box around the lid knuckle"],
     "Each knuckle overlaps the other part a little, so cut clearance around it: cylinders point four millimeters bigger than the knuckle, subtracted from the lid around the box's knuckles, and from the box around the lid's knuckle."),
 seg("pin", "The pin", "The pin", "Union and subtract",
     ["A 3.6 mm rod through all three", "Unioned to the box knuckles", "A 4.4 mm hole in the lid knuckle"],
     "Last, the pin: a three point six millimeter rod through all three knuckles. It's part of the box, and the lid's knuckle gets a hole point eight millimeters bigger, so it can turn. Union the knuckles to their parts, and we have two separate bodies."),
 seg("open", "Swing test", "Test the swing", "Transform › Rotate",
     ["105° about the hinge axis", "Nothing collides"],
     "Now the test. Rotate the lid one hundred and five degrees around the hinge axis. It swings open without touching the box anywhere."),
 seg("close", "Print pose", "Closed for printing", "Undo the rotation",
     ["Prints closed, exactly as modeled", "Lid and box never touch"],
     "Undo the rotation to close it again: that's the pose it prints in. The two parts never touch, so they come off the printer as one hinged box."),
 seg("export", "Export", "Export for printing", "Export › STL",
     ["Both bodies in one file", "The lid bridges the 0.4 mm gap", "Fused? Raise the gap in History"],
     "Export both bodies together as one STL. The lid's first layer bridges over the gap; if yours fuses to the walls, raise the gap in the history. Give the hinge a gentle twist the first time to break it free."),
 seg("outro", "Series", "That's all ten", "From a mug to a working hinge",
     ["Clearance is the key number", "0.4 mm suits most printers", "Tune it for yours"],
     "The key number is the clearance. Point four millimeters works on most printers; tune it in the history for yours. That's the last of our ten projects, from a coffee mug to a working hinge. Thanks for watching."),
]


VIDEOS = {
 "mug": video(1, "coffee-mug-tutorial", "Coffee mug", MUG,
   "Model a Coffee Mug on iPad — Revolve, Shell & Sweep (Free CAD Tutorial)",
   "COFFEE MUG\nrevolve · shell · sweep",
   """Model a classic coffee mug in OpenShape 3D, the free, open-source CAD app for iPad. The perfect first CAD project: revolve a half profile into the body, shell it hollow, sweep an ellipse along a path for the handle, fillet the base and rim, then export an STL for 3D printing.

What you'll learn
• Sketching a half profile on the front plane
• Revolve around a center line
• Fillet and shell
• Sweep a section along a path, fused with Union
• Exporting STL or 3MF for your slicer""",
   ["coffee mug", "mug CAD", "revolve", "shell", "sweep", "fillet", "mug 3D model"], OUTRO),
 "chess": video(2, "chess-pawn-rook-tutorial", "Chess pawn & rook", CHESS,
   "Model Chess Pieces on iPad — Pawn & Rook with Revolve (Free CAD Tutorial)",
   "CHESS PIECES\nrevolve · pattern · subtract",
   """Model a chess pawn and rook in OpenShape 3D, the free, open-source CAD app for iPad. Sketch half profiles with lines, a spline and an arc, revolve them into solid pieces, then cut the rook's battlements with a slot, a circular pattern and a boolean subtract.

What you'll learn
• Half profiles with splines and arcs
• Revolve
• Subtract extrudes
• Circular pattern + Combine › Subtract
• Materials and STL export""",
   ["chess pieces", "chess pawn", "chess rook", "revolve", "spline", "circular pattern", "3D printed chess set"], OUTRO),
 "brick": video(3, "lego-brick-tutorial", "LEGO-style brick", BRICK,
   "Model a LEGO-Compatible Brick on iPad — Exact Dimensions, Shell & Patterns (Free CAD)",
   "LEGO-STYLE BRICK\nshell · linear pattern",
   """Model a LEGO-compatible 2×4 brick in OpenShape 3D, the free, open-source CAD app for iPad, using the real dimensions: 8 mm stud pitch, 9.6 mm height, 4.8 mm studs and 6.51 mm tubes. A great exercise in exact sizes, shells, linear patterns and unions, and it prints without supports.

What you'll learn
• Exact dimensions and fit clearances
• Shell with an open face
• Linear patterns in two directions
• Rings from two circles
• Union and STL export

LEGO® is a trademark of the LEGO Group, which does not sponsor, authorize or endorse this video.""",
   ["LEGO brick", "LEGO compatible", "2x4 brick", "linear pattern", "shell", "exact dimensions", "3D printed LEGO"], OUTRO),
 "keychain": video(4, "name-keychain-tutorial", "Name keychain", KEYCHAIN,
   "Make a Name Keychain on iPad — Text Tool & Two-Color 3D Print (Free CAD Tutorial)",
   "NAME KEYCHAIN\ntext tool · two colors",
   """Make a custom name keychain in OpenShape 3D, the free, open-source CAD app for iPad. Extrude a rounded tag, cut a key ring hole, add your name with the Text tool, raise the letters as a separate body, and export a 3MF ready for a two-color print.

What you'll learn
• Extruding by tapping a sketch and typing the height
• Fillet and subtract
• The Text tool: sketching on a face, placing and sizing text
• Keeping parts as separate bodies for multi-color printing
• Exporting 3MF""",
   ["name keychain", "keychain", "text tool", "3D printed keychain", "two color 3D print", "multicolor", "3MF"], OUTRO),
 "vase": video(5, "twisted-vase-tutorial", "Twisted vase", VASE,
   "Design a Twisted Vase on iPad — Loft Tutorial for 3D Printing (Free CAD App)",
   "TWISTED VASE\nloft · shell · vase mode",
   """Design a twisted vase in OpenShape 3D, the free, open-source CAD app for iPad. Five hexagons on stacked planes, each rotated a little more, lofted into a smooth spiraling body, then shelled. Plus a tip for printing it in your slicer's vase (spiral) mode.

What you'll learn
• Sketches on offset planes
• Rotated polygons
• Loft through multiple sections
• Shell
• Vase-mode printing""",
   ["twisted vase", "vase", "loft", "vase mode", "spiral vase", "3D printed vase", "polygon"], OUTRO),
 "bolt": video(6, "bolt-and-nut-threads-tutorial", "Bolt & nut with threads", BOLT,
   "Model a Threaded Bolt & Nut on iPad — Helix Sweep Threads for 3D Printing (Free CAD)",
   "BOLT & NUT\nreal threads · helix sweep",
   """Model a 3D-printable hex bolt and a matching nut with real threads in OpenShape 3D, the free, open-source CAD app for iPad. A thread is just a profile swept along a helix: we build the head, the shank, an external thread with a coarse 2.5 mm pitch, and an internal thread with printable clearances.

What you'll learn
• Hexagons from the Polygon tool, and chamfers
• Thread profiles
• Helix sweep: radius, pitch and turns
• Internal threads and clearances for 3D printing
• Materials and STL export""",
   ["threads", "bolt and nut", "helix", "thread CAD", "3D printed threads", "hex bolt", "sweep"], OUTRO),
 "gear": video(7, "spur-gear-tutorial", "Spur gears", GEAR,
   "Model Spur Gears on iPad — Involute Teeth, Module & Meshing (Free CAD Tutorial)",
   "SPUR GEARS\ninvolute · module · mesh",
   """Model a real involute spur gear, and a second gear that meshes with it, in OpenShape 3D, the free, open-source CAD app for iPad. Module and tooth count, the involute tooth shape, circular patterns, bores and windows, and the center-distance rule that makes two gears mesh.

What you'll learn
• Module, pitch circle and tooth count
• The involute tooth profile
• Circular pattern + union
• Bores and weight-saving windows
• Center distance and meshing""",
   ["spur gear", "gears", "involute gear", "gear module", "circular pattern", "3D printed gears", "gear design"], OUTRO),
 "spinner": video(8, "fidget-spinner-tutorial", "Fidget spinner", SPINNER,
   "Design a Fidget Spinner on iPad — Patterns, Fillets & Bearing Press Fits (Free CAD)",
   "FIDGET SPINNER\n608 bearings · press fit",
   """Design a 3D-printable fidget spinner for standard 608 bearings in OpenShape 3D, the free, open-source CAD app for iPad. Circular patterns and unions build the shape, fillets smooth it, and 22.1 mm holes give the bearings a press fit.

What you'll learn
• Circular pattern + union
• Filleting inside corners
• Designing for a press fit
• Soft edges for comfort
• Tuning a fit in the history""",
   ["fidget spinner", "608 bearing", "press fit", "circular pattern", "fillet", "3D printed spinner"], OUTRO),
 "tray": video(9, "ice-cube-tray-tutorial", "Ice cube tray", TRAY,
   "Model an Ice Cube Tray on iPad — Draft Angles, Patterns & Subtract (Free CAD Tutorial)",
   "ICE CUBE TRAY\ndraft · pattern · subtract",
   """Model an ice cube tray in OpenShape 3D, the free, open-source CAD app for iPad. A tapered extrude gives each pocket a draft angle, linear patterns make six of them, a boolean subtract cuts them out, and fillets make the cubes release cleanly.

What you'll learn
• Draft angles with a tapered extrude
• Linear patterns in two directions
• Combine › Subtract
• Filleting pocket floors
• Printing in TPU, or as a mold master""",
   ["ice cube tray", "draft angle", "tapered extrude", "linear pattern", "boolean subtract", "mold design"], OUTRO),
 "hinge": video(10, "print-in-place-hinged-box-tutorial", "Print-in-place hinged box", HINGE,
   "Design a Print-in-Place Hinged Box on iPad — Knuckles, Pins & Clearances (Free CAD)",
   "HINGED BOX\nprint-in-place hinge",
   """Design a print-in-place hinged box in OpenShape 3D, the free, open-source CAD app for iPad. A shelled box, a lid with a 0.4 mm gap, three hinge knuckles (one mirrored), clearance cuts and a captive pin, then a rotation test to prove the lid swings free before you print.

What you'll learn
• Shell and offset sketch planes
• Mirror
• Clearance cuts with Combine › Subtract
• Captive pins
• Testing motion with Rotate before printing""",
   ["print in place", "hinged box", "hinge", "clearance", "mirror", "3D printed box", "print-in-place hinge"], OUTRO),
}
