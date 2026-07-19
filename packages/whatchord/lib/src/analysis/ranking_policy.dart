/// Cost difference threshold for engaging tie-breaker rules.
///
/// Candidate costs are positive explanation costs (see ChordAnalyzer), so this
/// is a difference of 0.25: roughly one structural surcharge. Within it,
/// tie-breaker rules resolve ambiguous interpretations without overriding clear
/// cost differences.
const double nearTieWindow = 0.25;

// ---- Per-rule cost guards ----------------------------------------------
//
// A cap bounds how big a cost disadvantage a rule may override: the rule
// fires only when its preferred reading costs no more than the cap above
// the competitor. A window is symmetric: the rule fires only when the two
// costs differ by no more than the window. Like nearTieWindow, these are
// tuning levers: raising one widens the ambiguity band its rule may decide,
// lowering it defers more pairs to raw cost. Constants are named for the
// rule they guard.

/// 'prefer conventional inversion in split-nine tritone dominant ambiguity'
const double splitNineTritoneWindow = 0.30;

/// 'prefer root-position minor-eleventh shell over sus slash'
const double m7Add11ShellCap = 1.30;

/// 'prefer complete dominant sharp-nine over non-seventh color'
const double dom7Sharp9Cap = 0.30;

/// 'prefer dominant flat-nine shell over colored diminished'
const double dom7Flat9Cap = 0.30;

/// 'prefer flat-nine-bass dominant over remote reinterpretation'
const double flatNineBassCap = 0.35;

/// 'prefer close root-position dominant7 over non-dominant slash'
const double dom7RootCap = 0.45;

/// 'prefer root-position altered-fifth dominant over slash'
const double alteredFifthCap = 0.30;

/// 'prefer ninth-bass seventh chord over altered slash'
const double ninthBassCap = 0.60;

/// 'prefer conventional altered seventh over add11 slash'
const double alteredSeventhCap = 0.70;

/// 'prefer root-position add-chord over sus slash'
const double addChordCap = 1.50;

/// 'prefer simple triad add-tone over seventh-family unusual quality'
const double triadAddToneCap = 1.50;

/// 'prefer readable sharp-eleven major over flat-five spelling'
const double sharpElevenMajorCap = 1.50;

/// 'prefer complete triad over structurally deficient reading'
const double completeTriadCap = 0.45;

/// 'prefer cleaner tritone flat-five dominant spelling'
const double tritoneSpellingWindow = 0.05;
