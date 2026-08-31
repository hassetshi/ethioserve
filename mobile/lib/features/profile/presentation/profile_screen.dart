import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/profile.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _populateIfNeeded(Profile? profile) {
    if (_initialized || profile == null) return;
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    setState(() => _saving = true);
    try {
      final existing = ref.read(myProfileProvider).valueOrNull;
      final updated = Profile(
        userId: currentUser.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        preferredLanguage: existing?.preferredLanguage ?? currentUser.languageCode,
      );
      await ref.read(profileRepositoryProvider).upsertProfile(updated);
      ref.invalidate(myProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile saved.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Something went wrong. Please try again.'),
        ),
        data: (profile) {
          _populateIfNeeded(profile);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
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
        },
      ),
    );
  }
}
