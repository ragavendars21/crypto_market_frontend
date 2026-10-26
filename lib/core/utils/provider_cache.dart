import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension ProviderCache on Ref {
  /// Keeps an auto-dispose provider's result for [duration] after the last
  /// widget stops using it.
  ///
  /// Example: switching the chart from 7D to 1Y and back reuses the 7D data
  /// instead of requesting it again, but leaving the screen for longer
  /// still frees the memory.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
