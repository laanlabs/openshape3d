# Short rectangle edge selection - September 8, 2026

Baseline 258fee5. After gallery reopen, clone upper-left rectangle 2 by0.5
short right edge is approximately26 screen pixels. Midpoint (344,325)
selects upper endpoint, leaving baseline2 readout instead of height0.5.
Native comparison: reduce isolated rotated rectangle height600 to300,
short right edge (357,597) to(364,622), midpoint(360,609) selects EDGE
and shows300 readout plus white normal arrow. Commands followed by inspected
screenshots under rectangle-ui/os3d-short-native-*.png; clone baseline
diagnosis os3d-anchor-clone-post-reopen-height.png.

Correction: tap point query yields to central half of a nearer line when
endpoint distance exceeds a quarter of line length. Near-end taps and exact
other-geometry points still take priority. Only selection taps use this
preference; drag-control and other point queries retain existing semantics.
Serial19901 owns simulator:16 construction tests plus one short-edge UI
workflow, /tmp/os3d-short-edge-selection-20260908.log and .xcresult.
Post-fix live verification pending. Both Google Docs remain Saving blocked;
no new publication claim. Generic transform ring styling is separate/open.

Initial19901 completed exit65:16 geometry passes, new UI failure at expected
height-label selection. AVFoundation frame extraction from the test recording
shows previous multiple-edge selection still present; the midpoint tap toggled
one edge out. The initial blank tap did not establish the intended setup.
Targeted20358 reruns with blank tap at(0.2,0.7), asserts zero labels before
midpoint tap, and attaches that state. No product change based on this failure.
System ffmpeg could not load its x265 dependency; AVFoundation extracted the
frame successfully. No system package changes were made.

Targeted20358 failed earlier at blank-selection-clear assertion (labels2,
expected0). Settled43234 now separates palette and canvas taps with1second
intervals; this is a diagnostic test timing change, not a verified diagnosis.
If failure persists, reproduce blank deselection live before altering product.

Settled43234 passed1/1: blank selection actually cleared, short-edge midpoint
selected height, and its explicit editor opened. ViewportGestureController
single-tap recognizer requires the double-tap recognizer to fail; waiting
for completed single-tap delivery resolved the test setup failure. Product
fix unchanged since first16unit passes. This is initial failures followed by
a targeted pass, not a single clean combined run. Live recheck next.

Final live Front clone short edge (350,260) to(358,290), midpoint354,275
selects edge and exposes0.52mm; explicit label opens editor with0.52. After
commit of unchanged value and blank deselection, exact endpoint350,260
selects the endpoint alone. Native26pixel edge midpoint selects300mm edge;
exact endpoint357,597 shows Endpoint highlight. Paired semantic checks pass
for this sample. Blue generic ring and different endpoint/glyph styling remain
open, not full on-canvas acceptance. No tests or desktop worker active.
Both Docs remain blocked; final paired images/local index retained unpublished.
