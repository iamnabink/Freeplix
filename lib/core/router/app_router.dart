import 'package:flutter/material.dart';
import 'package:freeplix/data/models/media_type.dart';
import 'package:freeplix/features/browse/view/browse_page.dart';
import 'package:freeplix/features/details/view/details_page.dart';
import 'package:freeplix/features/home/view/home_page.dart';
import 'package:freeplix/features/search/view/search_page.dart';
import 'package:freeplix/features/watch/view/watch_page.dart';
import 'package:freeplix/features/watchlist/view/watchlist_page.dart';
import 'package:freeplix/shell/view/app_shell.dart';
import 'package:freeplix/shell/view/not_found_page.dart';
import 'package:go_router/go_router.dart';

/// URL-first routing, because Freeplix is a web app before it is anything
/// else: every title has an address you can paste to someone.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _fade(state, const HomePage()),
          ),
          GoRoute(
            path: '/movies',
            pageBuilder: (context, state) => _fade(
              state,
              BrowsePage(
                type: MediaType.movie,
                genreId: _intParam(state.uri.queryParameters['genre']),
                castId: _intParam(state.uri.queryParameters['cast']),
              ),
            ),
          ),
          GoRoute(
            path: '/series',
            pageBuilder: (context, state) => _fade(
              state,
              BrowsePage(
                type: MediaType.tv,
                genreId: _intParam(state.uri.queryParameters['genre']),
              ),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => _fade(
              state,
              SearchPage(initialQuery: state.uri.queryParameters['q'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/list',
            pageBuilder: (context, state) =>
                _fade(state, const WatchlistPage()),
          ),
          GoRoute(
            path: '/title/:type/:id',
            pageBuilder: (context, state) {
              final id = _intParam(state.pathParameters['id']);
              if (id == null) return _fade(state, const NotFoundPage());
              return _fade(
                state,
                DetailsPage(
                  type: MediaType.fromWire(state.pathParameters['type']),
                  id: id,
                ),
              );
            },
          ),
        ],
      ),
      // The player takes the whole window — no shell chrome over the picture.
      GoRoute(
        path: '/watch/:type/:id',
        pageBuilder: (context, state) {
          final id = _intParam(state.pathParameters['id']);
          if (id == null) return _fade(state, const NotFoundPage());
          return _fade(
            state,
            WatchPage(
              type: MediaType.fromWire(state.pathParameters['type']),
              id: id,
              season: _intParam(state.uri.queryParameters['s']),
              episode: _intParam(state.uri.queryParameters['e']),
              trailer: state.uri.queryParameters['trailer'] == '1',
            ),
          );
        },
      ),
    ],
  );
}

int? _intParam(String? raw) => raw == null ? null : int.tryParse(raw);

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}
