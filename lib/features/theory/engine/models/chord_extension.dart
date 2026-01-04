/// A chord extension/modifier relative to the root.
///
/// We separate the "musical meaning" from display style.
/// For now, this is only what we can infer from pitch-class content.
enum ChordExtension {
  flat9,
  nine,
  sharp9,
  eleven,
  sharp11,
  flat13,
  thirteen,
  add9,
  add11,
  add13,
}
