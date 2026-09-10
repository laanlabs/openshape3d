# Explicit-unit source retention — September10,2026

Baseline3130e1c pushed; immutable05be744IPA unchanged. QA33/40 partial.
Native1924 selected10mm line: type2cm→20mm withf(x); reselect/open→2cm.
Typing20mm still showsf(x). Clone6492 selected2mm line: pad0.1cm→1mm correctly,
but nof(x), reopenedfield1. Thus conversion passes but enteredsource is lost.
Inspected screenshots /tmp/os3d-units-*.png. Different zoomscales explicit.

Fix extends optionaldisplayExpression to explicit-unit scalar numbers, not only
arithmetic. Bare numbers still clear source/marker. Original scalar-test clearing
fixture now uses bare2 inmm displayunits; new test covers0.1cm/reopen/inchesdisplay/
1mm/bare2/Undo. UI arithmetic workflow extended with cmkey and source reopening.
Serial exec60601 owns simulator, /tmp/os3d-explicit-unit-source-20260910.xcresult
and.log. No result yet. Live post-fix/gallery/history and publication pending.
Native20mm/f(x) afterexplicit20mm; clone reservedtest. No physicalinputclaim.

## Verification

Clean16/16 /tmp/os3d-explicit-unit-source-20260910.xcresult (11keypad,4arc,1UI),
exec60601exit0. Live clone saved0.1cm openswithsource/f(x), bare2 clearsmarker;
Undo restores1/f(x), Redo2. Native explicit20mm→bare10 clearsmarker, Undo20/f(x),
Redo10. Both finalUndo andgalleryreopen retain explicitunit source: native20mm,
clone0.1cm. All screenshots inspected. Native trialprompt skipped with AXelem25;
firstCmd4beforeforeground didnotchangeview, laterforegroundTop settled. First
clonefocus/navigation hitinactivewindow andis excluded; explicitappswitch fixed
delivery. No appfailure inferred from those attempts.
Diagnosis324placements/all4hashesonce/no predecessor loss verified via
/tmp/os3d-units-diagnosis-publication.docx. Post-fix publicationpending. No runner.

Final publication verified328placements/allfourfinalhashesonce/no predecessor loss
(/tmp/os3d-units-final-publication.docx); master38/prior keyboardnote/newunitnote
once, no media loss (/tmp/os3d-units-master.docx). Local evidence hashed.
