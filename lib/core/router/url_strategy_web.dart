import 'package:flutter_web_plugins/url_strategy.dart';

/// Drops the `#` from web URLs so a title's address is `/title/movie/603`
/// rather than `/#/title/movie/603` — the links Freeplix asks people to
/// share have to survive being pasted.
///
/// This needs the host to serve `index.html` for unknown paths. GitHub Pages
/// has no rewrite rule, so the build copies `index.html` to `404.html`.
void configureUrlStrategy() => usePathUrlStrategy();
