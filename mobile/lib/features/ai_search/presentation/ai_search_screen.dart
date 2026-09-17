import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/speech/speech_providers.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../providers/domain/provider_summary.dart';
import '../../providers/presentation/provider_providers.dart';
import '../../providers/presentation/widgets/provider_result_card.dart';
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
  bool _listening = false;
  String? _clarificationQuestion;
  String? _errorText;

  // Non-null once a query has actually matched a category/service -
  // distinguishes "matched, results shown below (maybe zero)" from
  // "unmatched, showing a clarification question instead". Deliberately
  // not the same "show results" flag as _HomeSearchField's dropdown: that
  // one is gated on focus (so a tap-outside race matters); this one is
  // gated on a result-state variable set once after the async match
  // resolves, so the default focus-loss/unfocus behavior is harmless here.
  String? _matchedLabel;
  List<ProviderSummary>? _results;

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
      _matchedLabel = null;
      _results = null;
    });

    try {
      final AiSearchResult result = await ref
          .read(aiServiceProvider)
          .interpretSearchQuery(query);

      if (!mounted) return;

      if (result.matched &&
          (result.serviceId != null || result.categoryId != null)) {
        FocusScope.of(context).unfocus();
        final languageCode = ref.read(localeProvider)?.languageCode ?? 'en';
        final label = result.serviceId != null
            ? await ref
                  .read(serviceProvider(result.serviceId!).future)
                  .then((s) => s.localizedName(languageCode))
            : await ref
                  .read(categoryProvider(result.categoryId!).future)
                  .then((c) => c.localizedName(languageCode));

        // "Near me" is the whole point of this flow (spec: help users find
        // *nearby* Ethiopian businesses) - try location silently rather
        // than gating it behind a separate chip/tap the way the filtered
        // results screen does; getCurrentLocation already degrades
        // gracefully (returns null) on denial/unavailability.
        final location = await ref
            .read(locationServiceProvider)
            .getCurrentLocation();

        final results = await ref
            .read(providerRepositoryProvider)
            .searchProviders(
              categoryId: result.categoryId,
              serviceId: result.serviceId,
              lat: location?.latitude,
              lng: location?.longitude,
            );

        if (!mounted) return;
        setState(() {
          _matchedLabel = label;
          _results = results;
        });
      } else {
        setState(() {
          _clarificationQuestion =
              result.clarificationQuestion ??
              'Could you describe what service you need?';
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

  Future<void> _startVoiceInput() async {
    final languageCode = ref.read(localeProvider)?.languageCode ?? 'en';

    setState(() {
      _listening = true;
      _errorText = null;
    });

    final text = await ref
        .read(speechToTextServiceProvider)
        .listen(languageCode: languageCode);

    if (!mounted) return;
    setState(() => _listening = false);

    if (text == null) {
      setState(() {
        _errorText = languageCode == 'am'
            ? "Voice input in Amharic isn't supported on this device yet — "
                  'please type your request, or switch to English.'
            : "Couldn't hear that — please try again or type your request.";
      });
      return;
    }

    _controller.text = text;
    await _ask();
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
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'What service do you need?',
                  suffixIcon: IconButton(
                    onPressed: _listening ? null : _startVoiceInput,
                    tooltip: 'Speak your request',
                    icon: _listening
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mic_none),
                  ),
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
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_matchedLabel != null) ...[
                const SizedBox(height: 24),
                Text(
                  _matchedLabel!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_results!.isEmpty)
                  const Text('No providers found nearby for that yet.')
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _results!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final provider = _results![index];
                        return ProviderResultCard(
                          summary: provider,
                          onTap: () =>
                              context.push('/providers/${provider.providerId}'),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
