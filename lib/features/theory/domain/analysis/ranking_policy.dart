/// Cost difference threshold for engaging tie-breaker rules.
///
/// Candidate costs are positive explanation costs (see ChordAnalyzer), so this
/// is a difference of 0.25: roughly one structural surcharge. Within it,
/// tie-breaker rules resolve ambiguous interpretations without overriding clear
/// cost differences.
const double nearTieWindow = 0.25;
