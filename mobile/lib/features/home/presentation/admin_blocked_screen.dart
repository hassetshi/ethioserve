import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';

/// Shown if an admin account somehow reaches the customer/provider mobile
/// app. Admin functionality lives only in admin-web (spec sections 13, 43) —
/// this screen deliberately offers no path into the rest of the app.
class AdminBlockedScreen extends ConsumerWidget {
  const AdminBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Admin accounts use the EthioServe admin web application, '
                'not this app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
