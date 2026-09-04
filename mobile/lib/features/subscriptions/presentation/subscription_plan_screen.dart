import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/subscription_plan.dart';
import 'subscription_providers.dart';

/// Reached from provider registration (non-blocking - a provider can also
/// skip and subscribe later from their dashboard) or the dashboard's
/// "Not listed" status card. Subscribing is independent of admin
/// verification: search requires both to be true, but a provider can pay
/// before or after being verified.
class SubscriptionPlanScreen extends ConsumerStatefulWidget {
  const SubscriptionPlanScreen({required this.providerId, super.key});

  final String providerId;

  @override
  ConsumerState<SubscriptionPlanScreen> createState() =>
      _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState
    extends ConsumerState<SubscriptionPlanScreen> {
  bool _busy = false;

  Future<void> _subscribe(String plan) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .subscribe(widget.providerId, plan);
      ref.invalidate(mySubscriptionProvider(widget.providerId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("You're now listed!")));
        Navigator.of(context).maybePop();
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.userMessage)));
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a listing plan')),
      body: SafeArea(
        child: plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text('Something went wrong. Please try again.'),
          ),
          data: (plans) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Subscribe to appear in customer search results. You can '
                'subscribe now or later from your dashboard.',
              ),
              const SizedBox(height: 16),
              ...plans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanCard(
                    plan: plan,
                    busy: _busy,
                    onSubscribe: () => _subscribe(plan.plan),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.busy,
    required this.onSubscribe,
  });

  final SubscriptionPlan plan;
  final bool busy;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.plan[0].toUpperCase() + plan.plan.substring(1),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('\$${plan.priceUsd.toStringAsFixed(0)}/${plan.interval}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: (busy || !plan.isAvailable) ? null : onSubscribe,
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      plan.isAvailable ? 'Subscribe' : 'Not available yet',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
