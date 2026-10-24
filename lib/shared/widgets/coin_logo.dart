import 'package:flutter/material.dart';

/// Circular coin logo with a letter fallback when there is no image URL or
/// the image fails to load (offline, broken link).
///
/// Uses `Image.network`, which caches decoded images in memory. A disk cache
/// package was left out on purpose: logos are small and it would add native
/// plugins that complicate widget tests.
class CoinLogo extends StatelessWidget {
  const CoinLogo({
    super.key,
    required this.imageUrl,
    required this.symbol,
    required this.size,
  });

  final String? imageUrl;
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = _LetterAvatar(symbol: symbol, size: size);
    final url = imageUrl;

    return ExcludeSemantics(
      // The coin name next to the logo already describes it.
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? fallback
            : ClipOval(
                child: Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  // Decode at display size instead of full resolution.
                  cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  errorBuilder: (_, _, _) => fallback,
                  frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) return child;
                    return fallback;
                  },
                ),
              ),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar({required this.symbol, required this.size});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final letter = symbol.isEmpty ? '?' : symbol[0].toUpperCase();

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.surfaceContainerHighest,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
