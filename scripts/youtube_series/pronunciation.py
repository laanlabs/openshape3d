"""Pronunciation guide for the narration voice.

The narration is a neural text-to-speech voice (edge-tts): it reads exactly
what it is given and guesses at CAD jargon. It has no phoneme markup (edge-tts
sends plain text), so words it could get wrong are RESPELLED in the text it
is handed. `speakable(text)` applies GUIDE to a `say` line just before
synthesis; the chapter panels, titles and YouTube text keep the real spelling.

Each entry: the term as written, how it is said (for people), IPA where a
dictionary gives one, and the respelling sent to the voice (None = the voice
reads it right as written, listed so a script writer knows). Sources:
Cambridge Dictionary (CAD /kæd/), Wikipedia "Fillet (mechanics)" (/ˈfɪlɪt/),
OED (involute /ˈɪnvəluːt/, Lego /ˈlɛɡoʊ/), Wikipedia "IGES" ("eye-jess"),
Wikipedia "Bézier curve" (/ˈbɛz.i.eɪ/).

Rules for writing a `say` line:
- Write numbers and units as words ("forty-one millimeters", "six degrees",
  "point four"), and part numbers as spoken ("six-oh-eight").
- Write the real term; add it here if the voice may misread it.
- Acronyms said letter by letter (STL, TPU) stay in capitals; acronyms said
  as a word (CAD, NURBS) and names in capitals (LEGO) are respelled.
"""
import re

# (term, regex, said as, IPA, sent to the voice as — None: read right as written)
# A respelling may use the regex's groups (\\1 keeps "Fillet" vs "fillet").
GUIDE = [
    ("CAD", r"\bCAD\b", "kad — one syllable, rhymes with dad", "/kæd/", "cad"),
    ("FreeCAD", r"\bFreeCAD\b", "free-kad", "", "Free cad"),
    ("AutoCAD", r"\bAutoCAD\b", "AW-toh-kad", "", "Auto cad"),
    ("Tinkercad", r"\bTinkercad\b", "TINK-er-kad", "", "Tinker cad"),
    ("fillet, fillets", r"\b([Ff])illet(s?)\b", "FILL-it (engineering), not fil-AY (cooking)", "/ˈfɪlɪt/", r"\1illit\2"),
    ("filleted", r"\b([Ff])illeted\b", "FILL-it-id", "", r"\1illitid"),
    ("filleting", r"\b([Ff])illeting\b", "FILL-it-ing", "", r"\1illiting"),
    ("chamfer", r"\b[Cc]hamfer", "CHAM-fer", "/ˈtʃæmfər/", None),
    ("involute", r"\b([Ii])nvolute\b", "IN-vuh-loot", "/ˈɪnvəluːt/", r"\1n-vuh-loot"),
    ("LEGO", r"\bLEGO\b", "LEG-oh", "/ˈlɛɡoʊ/", "Lego"),
    ("IGES", r"\bIGES\b", "EYE-jess", "", "eye-jess"),
    ("NURBS", r"\bNURBS\b", "nurbs, one word", "/nɜːrbz/", "nurbs"),
    ("B-rep", r"\bB-rep\b", "BEE-rep", "", "bee-rep"),
    ("Bézier", r"\bB[ée]zier\b", "BEZ-ee-ay", "/ˈbɛz.i.eɪ/", "Bez-ee-ay"),
    ("STEP", r"\bSTEP\b", "step, the word (the file format)", "", "step"),
    ("3MF", r"\b3MF\b", "three-em-eff", "", "three M F"),
    ("OBJ", r"\bOBJ\b", "oh-bee-jay", "", "O B J"),
    ("GLB", r"\bGLB\b", "gee-el-bee", "", "G L B"),
    ("DXF", r"\bDXF\b", "dee-ex-eff", "", "D X F"),
    ("STL", r"\bSTL\b", "ess-tee-el", "", None),
    ("TPU", r"\bTPU\b", "tee-pee-you", "", None),
    ("PLA", r"\bPLA\b", "pee-el-ay", "", None),
    ("PETG", r"\bPETG\b", "pee-ee-tee-gee", "", "P E T G"),
    ("OCCT", r"\bOCCT\b", "oh-see-see-tee", "", "O C C T"),
    ("OpenCASCADE", r"\bOpenCASCADE\b", "open cascade", "", "Open Cascade"),
    ("Shapr3D", r"\bShapr3D\b", "shaper three-dee", "", "Shaper three D"),
    ("Fusion 360", r"\bFusion 360\b", "fusion three-sixty", "", "Fusion three-sixty"),
    ("Onshape", r"\bOnshape\b", "on-shape", "", "On Shape"),
    ("3D", r"\b3D\b", "three-dee", "", "three-D"),
    ("helix", r"\bhelix\b", "HEE-liks", "/ˈhiːlɪks/", None),
    ("extrude", r"\bextrude\b", "ik-STROOD", "/ɪkˈstruːd/", None),
    ("mm", r"\bmm\b", "millimeters (never 'em em')", "", "millimeters"),
    ("°", r"°", "degrees", "", " degrees"),
    ("×", r"\s×\s", "by", "", " by "),
]


def speakable(text):
    """`text` as handed to the voice: every respelling in GUIDE applied."""
    for _term, pattern, _said, _ipa, respelling in GUIDE:
        if respelling is not None:
            text = re.sub(pattern, respelling, text)
    return text


def terms_in(text):
    """The GUIDE entries a line uses (for review before a take)."""
    return [(term, said) for term, p, said, _ipa, _r in GUIDE if re.search(p, text)]


if __name__ == "__main__":
    # The guide as a Markdown table (README.md carries a copy).
    print("| Term | Say it | IPA | Sent to the voice as |\n|---|---|---|---|")
    for term, pattern, said, ipa, respelling in GUIDE:
        sent = re.sub(pattern, respelling, term.split(",")[0]).strip() if respelling else "(as written)"
        print(f"| {term} | {said} | {ipa} | {sent} |")
