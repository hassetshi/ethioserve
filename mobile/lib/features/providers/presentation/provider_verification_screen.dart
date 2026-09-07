import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'provider_providers.dart';

const _documentTypes = ['national_id', 'business_license', 'trade_license'];

class ProviderVerificationScreen extends ConsumerStatefulWidget {
  const ProviderVerificationScreen({required this.providerId, super.key});

  final String providerId;

  @override
  ConsumerState<ProviderVerificationScreen> createState() =>
      _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState
    extends ConsumerState<ProviderVerificationScreen> {
  String _documentType = _documentTypes.first;
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final extension = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'jpg';
      await ref
          .read(providerRepositoryProvider)
          .uploadVerificationDocument(
            providerId: widget.providerId,
            documentType: _documentType,
            bytes: bytes,
            fileExtension: extension,
          );
      ref.invalidate(myDocumentsProvider(widget.providerId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Document uploaded.')));
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
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(myDocumentsProvider(widget.providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload a document to verify your business. An admin reviews '
                'submissions manually.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _documentType,
                decoration: const InputDecoration(
                  labelText: 'Document type',
                  border: OutlineInputBorder(),
                ),
                items: _documentTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _documentType = value ?? _documentType),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: const Icon(Icons.upload_file),
                label: Text(_uploading ? 'Uploading...' : 'Choose & upload'),
              ),
              const SizedBox(height: 24),
              Text(
                'Submitted documents',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: documentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      const Text('Something went wrong. Please try again.'),
                  data: (documents) {
                    if (documents.isEmpty) {
                      return const Text('No documents submitted yet.');
                    }
                    return ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final doc = documents[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(doc.documentType),
                          trailing: Text(doc.verificationStatus),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
