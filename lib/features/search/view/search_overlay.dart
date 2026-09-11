import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freeplix/core/theme/app_colors.dart';
import 'package:freeplix/core/theme/app_spacing.dart';
import 'package:freeplix/core/theme/app_typography.dart';
import 'package:freeplix/core/widgets/media_grid.dart';
import 'package:freeplix/core/widgets/state_views.dart';
import 'package:freeplix/data/models/media_item.dart';
import 'package:freeplix/data/repositories/tmdb_repository.dart';
import 'package:freeplix/features/search/bloc/search_cubit.dart';
import 'package:go_router/go_router.dart';

/// Opens search as a floating overlay over the current page, rather than
/// navigating to a separate screen — the picture stays behind a scrim while
/// the reader looks something up, then dismisses back to where they were.
Future<void> openSearchOverlay(BuildContext context) {
  final repository = context.read<TmdbRepository>();
  final router = GoRouter.of(context);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close search',
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: Motion.base,
    pageBuilder: (dialogContext, _, _) {
      return BlocProvider(
        create: (_) => SearchCubit(repository: repository),
        child: _SearchOverlay(
          onSelect: (item) {
            Navigator.of(dialogContext).pop();
            router.go('/title/${item.type.wire}/${item.id}');
          },
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _SearchOverlay extends HookWidget {
  const _SearchOverlay({required this.onSelect});

  final void Function(MediaItem) onSelect;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final focus = useFocusNode();
    final cubit = context.read<SearchCubit>();
    final viewport = MediaQuery.sizeOf(context);
    final isCompact = viewport.width < Breakpoints.compact;

    useEffect(() {
      focus.requestFocus();
      return null;
    }, const []);

    void close() => Navigator.of(context).pop();

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Material(
        color: AppColors.ink.withValues(alpha: 0.98),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? Insets.md : Insets.xxl,
              vertical: isCompact ? Insets.sm : Insets.lg,
            ),
            child: Column(
              children: [
                _SearchField(
                  controller: controller,
                  focus: focus,
                  onChanged: cubit.query,
                  onClose: close,
                ),
                const SizedBox(height: Insets.md),
                Expanded(child: _OverlayResults(onSelect: onSelect)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // A single underline field — no fill, no rectangle — so the search bar
    // reads as a line the reader writes on, not a boxed control.
    return TextField(
      controller: controller,
      focusNode: focus,
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: AppTypography.bodyStyle(size: 18, color: AppColors.emulsion),
      cursorColor: AppColors.lamp,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: false,
        hintText: 'Search titles, franchises, or characters',
        hintStyle: AppTypography.bodyStyle(
          size: 18,
          color: AppColors.screenDim,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 24,
          color: AppColors.screenDim,
        ),
        suffixIcon: IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, size: 20),
          color: AppColors.screen,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: Insets.md),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.ash),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.lamp, width: 2),
        ),
      ),
    );
  }
}

class _OverlayResults extends StatelessWidget {
  const _OverlayResults({required this.onSelect});

  final void Function(MediaItem) onSelect;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        const padding = EdgeInsets.all(Insets.md);

        return CustomScrollView(
          slivers: [
            switch (state.status) {
              SearchStatus.idle => const SliverToBoxAdapter(
                child: EmptyView(
                  compact: true,
                  icon: Icons.search_rounded,
                  eyebrow: 'Nothing searched yet',
                  message: 'Start typing and results appear as you go.',
                ),
              ),
              SearchStatus.typing ||
              SearchStatus.loading => const SliverPadding(
                padding: padding,
                sliver: MediaGridSkeletonSliver(count: 8),
              ),
              SearchStatus.failure => SliverToBoxAdapter(
                child: ErrorView(
                  compact: true,
                  message: state.error ?? 'Search failed.',
                  onRetry: context.read<SearchCubit>().retry,
                ),
              ),
              SearchStatus.ready when state.results.isEmpty =>
                SliverToBoxAdapter(
                  child: EmptyView(
                    compact: true,
                    eyebrow: 'No matches',
                    message:
                        'Nothing in TMDB matches "${state.query}". '
                        'Check the spelling, or try fewer words.',
                  ),
                ),
              SearchStatus.ready => SliverPadding(
                padding: padding,
                sliver: MediaGridSliver(
                  items: state.results,
                  onSelect: onSelect,
                ),
              ),
            },
          ],
        );
      },
    );
  }
}
