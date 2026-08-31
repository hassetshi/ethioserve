import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../providers/presentation/provider_providers.dart';
import 'booking_request_controller.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  const BookingRequestScreen({required this.providerId, super.key});

  final String providerId;

  @override
  ConsumerState<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  String? _serviceId;
  DateTime? _date;
  TimeOfDay? _time;
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);

    if (_serviceId == null || _date == null || _time == null || _addressController.text.trim().isEmpty) {
      setState(() => _errorText = 'Service, date, time, and address are required.');
      return;
    }

    final timeString =
        '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}:00';

    final booking = await ref.read(bookingRequestControllerProvider.notifier).submit(
          providerId: widget.providerId,
          serviceId: _serviceId!,
          scheduledDate: _date!,
          scheduledTime: timeString,
          address: _addressController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

    if (!mounted) return;

    if (booking == null) {
      setState(() => _errorText = 'Something went wrong. Please try again.');
      return;
    }

    context.pushReplacement('/bookings/${booking.id}/confirmation');
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final detailAsync = ref.watch(providerDetailProvider(widget.providerId));
    final requestState = ref.watch(bookingRequestControllerProvider);
    final isLoading = requestState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Request a booking')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Something went wrong. Please try again.')),
        data: (provider) {
          if (provider.services.isEmpty) {
            return const Center(
              child: Text('This provider has not listed any services yet.'),
            );
          }
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _serviceId,
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.services
                      .map((s) => DropdownMenuItem(
                            value: s.serviceId,
                            child: Text(languageCode == 'am' ? s.nameAm : s.nameEn),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _serviceId = value),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_date == null
                      ? 'Choose date'
                      : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(_time == null ? 'Choose time' : _time!.format(context)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Describe the problem (optional)',
                    border: OutlineInputBorder(),
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
                      : const Text('Submit request'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
