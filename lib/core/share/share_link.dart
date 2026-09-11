import 'package:freeplix/core/share/share_link_stub.dart'
    if (dart.library.js_interop) 'package:freeplix/core/share/share_link_web.dart'
    as impl;
import 'package:freeplix/core/share/share_result.dart';

export 'package:freeplix/core/share/share_result.dart';

/// Builds an absolute, shareable URL for an in-app [path] (e.g.
/// `title/movie/603`). On web this resolves against the document base so it
/// works under a sub-path deploy like GitHub Pages; elsewhere it is best
/// effort, since a backend-less build has no canonical origin off the web.
String shareUrlFor(String path) => impl.shareUrlFor(path);

/// Hands [url] to the platform's native share sheet when one exists, and
/// otherwise copies it to the clipboard. [text] is the human label offered to
/// the share sheet (the title's name).
Future<ShareResult> shareOrCopy({
  required String url,
  required String text,
}) => impl.shareOrCopy(url: url, text: text);
