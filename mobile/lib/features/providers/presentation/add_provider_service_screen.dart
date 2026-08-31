import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../catalog/presentation/catalog_providers.dart';
import 'provider_providers.dart';

const _pricingTypes = ['fixed', 'hourly', 'starting_from', 'quote'];

class AddProviderServiceScreen extends ConsumerStatefulWidget {
  const AddProviderServiceScreen({required this.providerId, super.key});

  final String providerId;

  @override
  ConsumerState<AddProviderServiceScreen> createState() =>
      _AddProviderServiceScreenState();
}

class _AddProviderServiceScreenState extends ConsumerState<AddProviderServiceScreen> {
  String? _categoryId;
  String? _serviceId;
  String _pricingType = 'starting_from';
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_serviceId == null) {
      setState(() => _errorText = 'Choose a service.');
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      await ref.read(providerRepositoryProvider).addOfferedService(
            providerId: widget.providerId,
            serviceId: _serviceId!,
            pricingType: _pricingType,
            minPrice: double.tryParse(_minPriceController.text.trim()),
            maxPrice: double.tryParse(_maxPriceController.text.trim()),
          );
      ref.invalidate(providerDetailProvider(widget.providerId));
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) setState(() => _errorText = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final categoriesAsync = ref.watch(categoriesProvider);
    final servicesAsync =
        _categoryId == null ? null : ref.watch(servicesByCategoryProvider(_categoryId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Add a service')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Something went wrong. Please try again.'),
              data: (categories) => DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.localizedName(languageCode)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  _categoryId = value;
                  _serviceId = null;
                }),
              ),
            ),
            const SizedBox(height: 16),
            if (servicesAsync != null)
              servicesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Something went wrong. Please try again.'),
                data: (services) => DropdownButtonFormField<String>(
                  initialValue: _serviceId,
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    border: OutlineInputBorder(),
                  ),
                  items: services
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.localizedName(languageCode)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _serviceId = value),
                ),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _pricingType,
              decoration: const InputDecoration(
                labelText: 'Pricing type',
                border: OutlineInputBorder(),
              ),
              items: _pricingTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _pricingType = value ?? _pricingType),
            ),
            if (_pricingType != 'quote') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min price (ETB)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max price (ETB, optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
