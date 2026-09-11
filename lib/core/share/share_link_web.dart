import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:freeplix/core/share/share_result.dart';
import 'package:web/web.dart' as web;

/// The subset of `ShareData` we hand to `navigator.share`.
extension type _ShareData._(JSObject _) implements JSObject {
  external factory _ShareData({String? title, String? url});
}

/// Resolves [path] against the document base, so a sub-path deploy (e.g.
/// `https://user.github.io/Freeplix/`) yields a link that actually opens.
String shareUrlFor(String path) {
  final rel = path.startsWith('/') ? path.substring(1) : path;
  return Uri.parse(web.document.baseURI).resolve(rel).toString();
}

/// Uses the Web Share API when the browser offers it (and the user gesture
/// allows it), falling back to the clipboard otherwise.
Future<ShareResult> shareOrCopy({
  required String url,
  required String text,
}) async {
  final navigator = web.window.navigator as JSObject;
  if (navigator.has('share')) {
    try {
      // Pass the name as the share *title* (subject) only — never as `text`,
      // which many targets glue onto the URL as "text url", corrupting the
      // link into ".../125988 Silo (2023)".
      final promise = navigator.callMethod<JSPromise>(
        'share'.toJS,
        _ShareData(title: text, url: url),
      );
      await promise.toDart;
    } on Object catch (_) {
      // The user dismissed the sheet, or the browser refused the payload.
      // Either way the native path handled it; don't also copy behind them.
    }
    return ShareResult.shared;
  }

  await Clipboard.setData(ClipboardData(text: url));
  return ShareResult.copied;
}
