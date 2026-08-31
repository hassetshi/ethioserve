import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../catalog/presentation/catalog_providers.dart';
import 'provider_registration_controller.dart';

class ProviderRegistrationScreen extends ConsumerStatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  ConsumerState<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends ConsumerState<ProviderRegistrationScreen> {
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _cityId;
  String? _errorText;

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);

    if (_businessNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _cityId == null) {
      setState(() => _errorText = 'Business name, phone, and city are required.');
      return;
    }

    final providerId = await ref
        .read(providerRegistrationControllerProvider.notifier)
        .register(
          businessName: _businessNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          cityId: _cityId!,
        );

    if (!mounted) return;

    if (providerId == null) {
      setState(() => _errorText = 'Something went wrong. Please try again.');
      return;
    }

    context.go('/provider');
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final citiesAsync = ref.watch(citiesProvider);
    final registrationState = ref.watch(providerRegistrationControllerProvider);
    final isLoading = registrationState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Register as a provider')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Business phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            citiesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) =>
                  const Text('Something went wrong. Please try again.'),
              data: (cities) => DropdownButtonFormField<String>(
                initialValue: _cityId,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                items: cities
                    .map((city) => DropdownMenuItem(
                          value: city.id,
                          child: Text(city.localizedName(languageCode)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _cityId = value),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
