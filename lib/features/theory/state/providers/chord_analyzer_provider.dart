import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatchord/whatchord.dart';

/// The app's single [ChordAnalyzer]. Sharing one instance shares its LRU
/// cache across every feature that names chords.
final chordAnalyzerProvider = Provider<ChordAnalyzer>((ref) => ChordAnalyzer());
