import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_subscription_repository.dart';
import '../domain/subscription.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SupabaseSubscriptionRepository(Supabase.instance.client);
});

final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlan>>((ref) {
      return ref.watch(subscriptionRepositoryProvider).getPlans();
    });

final mySubscriptionProvider = FutureProvider.autoDispose
    .family<Subscription?, String>((ref, providerId) {
      return ref
          .watch(subscriptionRepositoryProvider)
          .getMySubscription(providerId);
    });
