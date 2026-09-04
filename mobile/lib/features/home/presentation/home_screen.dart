import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../catalog/domain/search_suggestion.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../notifications/presentation/notification_bell.dart';

/// AI search wiring (spec section 15) is Phase 11; nearby/featured provider
/// home sections are deferred until there's enough real provider density to
/// make them meaningful. Search and categories are both real as of Phase 5.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final categoriesAsync = ref.watch(categoriesProvider);
    final isLoggedIn = ref.watch(currentUserProvider).valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: isLoggedIn
            ? [
                const NotificationBell(),
                IconButton(
                  onPressed: () => context.push('/bookings'),
                  icon: const Icon(Icons.calendar_month_outlined),
                  tooltip: 'My Bookings',
                ),
                IconButton(
                  onPressed: () => context.push('/profile'),
                  icon: const Icon(Icons.person_outline),
                  tooltip: 'Profile',
                ),
              ]
            : [
                TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Log in'),
                ),
              ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.homeGreetingTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const _HomeSearchField(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/ai-search'),
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.aiSearchLabel),
            ),
            const SizedBox(height: 24),
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Text('Something went wrong. Please try again.'),
              data: (categories) => GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: categories
                    .map(
                      (category) => _CategoryTile(
                        label: category.localizedName(languageCode),
                        onTap: () => context.push('/categories/${category.id}'),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline typeahead search: stays on Home (no navigation on tap or on
/// keystroke) and shows a live suggestions dropdown, debounced so it
/// doesn't hit [searchSuggestionsProvider] on every keystroke. Picking a
/// suggestion is what navigates, straight to the shared provider-results
/// screen (same as category-browse and AI search) via `/categories/:id
/// /providers` or `/services/:id/providers`.
class _HomeSearchField extends ConsumerStatefulWidget {
  const _HomeSearchField();

  @override
  ConsumerState<_HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends ConsumerState<_HomeSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Only the dropdown's visibility depends on focus; rebuild to show/hide it.
    setState(() {});
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
    _focusNode.unfocus();
    final path = suggestion.type == SearchSuggestionType.category
        ? '/categories/${suggestion.id}/providers'
        : '/services/${suggestion.id}/providers';
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final showDropdown = _focusNode.hasFocus && _query.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          // Without this, TextField's default tap-outside-to-unfocus fires
          // on pointer-down and hides the dropdown (showDropdown depends on
          // focus) before a suggestion ListTile's own onTap can fire on
          // pointer-up - the tap lands on nothing and silently does
          // nothing. Suggestion selection explicitly unfocuses itself
          // (_selectSuggestion), so this field only needs to stop the
          // *automatic* unfocus-on-outside-tap from racing it.
          onTapOutside: (_) {},
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (showDropdown)
          Consumer(
            builder: (context, ref, _) {
              final suggestionsAsync = ref.watch(
                searchSuggestionsProvider(_query),
              );
              return Card(
                margin: const EdgeInsets.only(top: 4),
                child: suggestionsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Something went wrong. Please try again.'),
                  ),
                  data: (suggestions) => suggestions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No matching services found.'),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: suggestions
                              .map(
                                (suggestion) => ListTile(
                                  leading: Icon(
                                    suggestion.type ==
                                            SearchSuggestionType.category
                                        ? Icons.category_outlined
                                        : Icons.design_services_outlined,
                                  ),
                                  title: Text(
                                    suggestion.localizedName(languageCode),
                                  ),
                                  onTap: () => _selectSuggestion(suggestion),
                                ),
                              )
                              .toList(),
                        ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
