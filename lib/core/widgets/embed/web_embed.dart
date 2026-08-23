import 'package:flutter/widgets.dart';
import 'package:freeplix/core/widgets/embed/web_embed_stub.dart'
    if (dart.library.js_interop) 'package:freeplix/core/widgets/embed/web_embed_web.dart'
    as impl;

/// Renders [url] inside a sandboxed frame on web.
///
/// On every other platform this reports that it cannot render, and the caller
/// falls back to opening the URL in the system browser.
class WebEmbed extends StatelessWidget {
  const WebEmbed({required this.url, super.key});

  static bool get isSupported => impl.isEmbedSupported;

  final String url;

  @override
  Widget build(BuildContext context) => impl.buildEmbed(url);
}
