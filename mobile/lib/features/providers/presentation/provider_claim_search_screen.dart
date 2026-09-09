import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import 'provider_providers.dart';

class ProviderClaimSearchScreen extends ConsumerStatefulWidget {
  const ProviderClaimSearchScreen({super.key});

  @override
  ConsumerState<ProviderClaimSearchScreen> createState() =>
      _ProviderClaimSearchScreenState();
}

class _ProviderClaimSearchScreenState
    extends ConsumerState<ProviderClaimSearchScreen> {
  final _controller = TextEditingController();
  String _submittedQuery = '';
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _claim(String providerId, String businessName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim this business?'),
        content: Text(
          'We\'ll ask an admin to review your request for "$businessName". '
          "You'll be notified once it's approved or rejected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit request'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await ref.read(providerRepositoryProvider).requestClaim(providerId);
      ref.invalidate(myClaimStatusProvider);
      if (mounted) context.go('/provider/claim/status');
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = _submittedQuery.isEmpty
        ? null
        : ref.watch(unclaimedProviderSearchProvider(_submittedQuery));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search by business name...',
            border: InputBorder.none,
          ),
          onSubmitted: (value) =>
              setState(() => _submittedQuery = value.trim()),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: resultsAsync == null
            ? const Center(child: Text('Search for your business by name.'))
            : resultsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(
                  child: Text('Something went wrong. Please try again.'),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return const Center(
                      child: Text(
                        "No unclaimed listing matches that name. If you don't "
                        'see your business, register it as a new one instead.',
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final provider = results[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.storefront),
                        ),
                        title: Text(provider.businessName),
                        trailing: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('This is my business'),
                        onTap: _submitting
                            ? null
                            : () => _claim(
                                provider.providerId,
                                provider.businessName,
                              ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
