import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/ai_search_result.dart';
import 'ai_service_providers.dart';

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _clarificationQuestion;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _clarificationQuestion = null;
      _errorText = null;
    });

    try {
      final AiSearchResult result =
          await ref.read(aiServiceProvider).interpretSearchQuery(query);

      if (!mounted) return;

      if (result.matched && result.serviceId != null) {
        context.push('/services/${result.serviceId}/providers');
      } else if (result.matched && result.categoryId != null) {
        context.push('/categories/${result.categoryId}/providers');
      } else {
        setState(() {
          _clarificationQuestion =
              result.clarificationQuestion ?? 'Could you describe what service you need?';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask EthioServe')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Describe what you need, in English or Amharic — e.g. '
                '"I need a plumber near me today" or "የቤት ጽዳት ባለሙያ ፈልጋለሁ".',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'What service do you need?',
                ),
                onSubmitted: (_) => _loading ? null : _ask(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _ask,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ask'),
              ),
              if (_clarificationQuestion != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_clarificationQuestion!),
                  ),
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
