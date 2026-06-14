import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// Opens the native share sheet for a chord [link].
///
/// [sharePositionOrigin] is the source rect the sheet should anchor to; it is
/// required for the popover presentation on iPad.
Future<void> shareChordLink(Uri link, {Rect? sharePositionOrigin}) async {
  await SharePlus.instance.share(
    ShareParams(uri: link, sharePositionOrigin: sharePositionOrigin),
  );
}
