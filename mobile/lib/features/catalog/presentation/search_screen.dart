import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import 'catalog_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _submittedQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final resultsAsync = _submittedQuery.isEmpty
        ? null
        : ref.watch(serviceSearchProvider(_submittedQuery));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search services...',
            border: InputBorder.none,
          ),
          onSubmitted: (value) => setState(() => _submittedQuery = value.trim()),
        ),
      ),
      body: resultsAsync == null
          ? const Center(child: Text('Search for a service, e.g. "plumbing".'))
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Something went wrong. Please try again.')),
              data: (services) {
                if (services.isEmpty) {
                  return const Center(child: Text('No matching services found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return ListTile(
                      title: Text(service.localizedName(languageCode)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/services/${service.id}/providers'),
                    );
                  },
                );
              },
            ),
    );
  }
}
