import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../application/market_query_controller.dart';
import '../../domain/market_query.dart';
import 'sort_sheet.dart';

/// Search field plus sort and filter chips for the market list.
///
/// Each chip watches only the part of the query it shows (via `select`), so
/// typing in the search field doesn't rebuild the chips and vice versa.
class SearchAndFilterBar extends StatelessWidget {
  const SearchAndFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // Opaque so list items scroll underneath cleanly while it's pinned.
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SearchField(),
            SizedBox(height: AppSpacing.sm),
            _FilterChips(),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();

  /// Matches the backend's limit for the `search` parameter.
  static const _maxSearchLength = 50;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    ref.read(marketQueryProvider.notifier).submitSearch('');
    setState(() {}); // Hide the clear button.
  }

  @override
  Widget build(BuildContext context) {
    // If search is cleared elsewhere (e.g. the empty state's "Clear" button),
    // empty the text field too.
    ref.listen(marketQueryProvider.select((q) => q.trimmedSearch), (_, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
        setState(() {});
      }
    });

    final notifier = ref.read(marketQueryProvider.notifier);

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      inputFormatters: [LengthLimitingTextInputFormatter(_maxSearchLength)],
      decoration: InputDecoration(
        hintText: 'Search by name or symbol',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: _clear,
              ),
      ),
      onChanged: (text) {
        notifier.updateSearch(text);
        setState(() {}); // Show or hide the clear button.
      },
      onSubmitted: notifier.submitSearch,
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(marketQueryProvider.select((q) => q.sort));
    final movement = ref.watch(marketQueryProvider.select((q) => q.movement));
    final tier = ref.watch(marketQueryProvider.select((q) => q.tier));
    final notifier = ref.read(marketQueryProvider.notifier);

    // A plain scrolling Row (not a lazy ListView): with only six chips,
    // building them all is cheap and keeps every chip reachable by screen
    // readers.
    return SizedBox(
      height: AppSizes.minTouchTarget,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ActionChip(
              avatar: const Icon(Icons.sort_rounded, size: AppIconSize.md),
              label: Text(sort.label),
              tooltip: 'Change sort order',
              onPressed: () async {
                final selected = await showSortSheet(context, current: sort);
                if (selected != null) notifier.setSort(selected);
              },
            ),
            const _ChipDivider(),
            for (final option in [
              MarketMovement.gainers,
              MarketMovement.losers,
            ])
              _FilterChip(
                label: option.label,
                tooltip: '${option.label} in the last 24 hours',
                selected: movement == option,
                onSelected: () => notifier.toggleMovement(option),
              ),
            const _ChipDivider(),
            for (final option in [
              MarketCapTier.large,
              MarketCapTier.mid,
              MarketCapTier.small,
            ])
              _FilterChip(
                label: option.label,
                tooltip: option.description,
                selected: tier == option,
                onSelected: () => notifier.toggleTier(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        tooltip: tooltip,
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _ChipDivider extends StatelessWidget {
  const _ChipDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      child: VerticalDivider(width: AppSpacing.sm),
    );
  }
}
