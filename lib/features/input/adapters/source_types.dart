import 'package:flutter_riverpod/misc.dart';

import '../models/input_note_event.dart';

typedef NoteEventsSource = ProviderListenable<Stream<InputNoteEvent>>;
typedef NoteNumbersSource = ProviderListenable<Set<int>>;
typedef PedalDownSource = ProviderListenable<bool>;
