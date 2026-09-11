import 'package:flutter/services.dart';
import 'package:freeplix/core/share/share_result.dart';

/// Off the web there is no canonical origin for a backend-less build, so the
/// in-app path is the best we can offer.
String shareUrlFor(String path) => path;

/// No native share sheet is wired up off the web, so copy the link.
Future<ShareResult> shareOrCopy({
  required String url,
  required String text,
}) async {
  await Clipboard.setData(ClipboardData(text: url));
  return ShareResult.copied;
}
