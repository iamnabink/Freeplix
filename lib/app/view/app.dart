import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeplix/core/router/app_router.dart';
import 'package:freeplix/core/theme/app_theme.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/data/repositories/watchlist_repository.dart';
import 'package:freeplix/features/watchlist/bloc/watchlist_cubit.dart';
import 'package:freeplix/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class App extends StatefulWidget {
  const App({required this.watchlistRepository, super.key});

  final WatchlistRepository watchlistRepository;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GoRouter _router = createRouter();
  final _tmdbRepository = TmdbRepository();

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _tmdbRepository,
      child: BlocProvider(
        create: (_) =>
            WatchlistCubit(repository: widget.watchlistRepository),
        child: MaterialApp.router(
          title: 'Freeplix',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          routerConfig: _router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Freeplix is a dark room by design; it does not follow the
          // system's light theme.
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.dark,
        ),
      ),
    );
  }
}
