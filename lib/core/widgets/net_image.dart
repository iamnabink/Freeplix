import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freeplix/core/theme/app_colors.dart';

/// Every remote image in Freeplix goes through here so loading and missing
/// artwork look the same everywhere.
class NetImage extends StatelessWidget {
  const NetImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.movie_outlined,
    super.key,
  });

  final String? url;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final source = url;
    if (source == null) return _Placeholder(icon: fallbackIcon);

    return CachedNetworkImage(
      imageUrl: source,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 260),
      placeholder: (_, _) => const _Placeholder(),
      errorWidget: (_, _, _) => _Placeholder(icon: fallbackIcon),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.posterPlaceholder,
      child: icon == null
          ? const SizedBox.expand()
          : Center(
              child: Icon(icon, color: AppColors.screenDim, size: 22),
            ),
    );
  }
}
