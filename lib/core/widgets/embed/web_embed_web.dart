import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

const isEmbedSupported = true;

final _registered = <String>{};

Widget buildEmbed(String url) {
  final viewType = 'freeplix-embed-${url.hashCode}';

  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final frame = web.document.createElement('iframe')
          as web.HTMLIFrameElement
        ..src = url
        ..width = '100%'
        ..height = '100%'
        ..allowFullscreen = true
        ..allow = 'autoplay; fullscreen; encrypted-media; picture-in-picture'
        // Deliberately omits allow-popups and allow-top-navigation: an
        // embedded player never has a reason to open a window or steer the
        // page, and blocking it here stops pop-unders at the frame boundary.
        ..setAttribute(
          'sandbox',
          'allow-scripts allow-same-origin allow-presentation allow-forms',
        )
        // YouTube refuses to embed when it gets no referrer (error 153), so
        // send the origin but never the full path.
        ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin')
        ..setAttribute('loading', 'lazy');
      frame.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%';
      return frame;
    });
  }

  return HtmlElementView(viewType: viewType);
}
