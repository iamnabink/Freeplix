import 'package:flutter/material.dart';
import 'package:freeplix/core/widgets/state_views.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      eyebrow: 'Reel missing',
      icon: Icons.videocam_off_outlined,
      message: "That page isn't in the catalogue. The address may have "
          'changed, or the title may have been removed from TMDB.',
      action: FilledButton(
        onPressed: () => context.go('/'),
        child: const Text('Back to home'),
      ),
    );
  }
}
