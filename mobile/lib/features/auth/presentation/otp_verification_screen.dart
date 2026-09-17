import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'otp_controller.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    required this.phone,
    this.redirectTo,
    super.key,
  });

  final String phone;

  /// Where to send the user after a successful verify, if they were
  /// bounced here from a login-gated route. Null when Login was reached
  /// directly (e.g. Home's plain "Log in" button) - in that case, popping
  /// back past Login/OTP already reveals the right screen, nothing further
  /// needs pushing.
  final String? redirectTo;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref
        .read(otpControllerProvider.notifier)
        .verify(phone: widget.phone, code: _codeController.text.trim());

    if (!mounted || !success) return;

    // Login is always the sole entry point into this auth sub-flow, and
    // this OTP screen is always pushed exactly once on top of it - so
    // popping twice removes exactly [this OTP screen, Login] and reveals
    // whatever was underneath before the user hit the login wall (Home, if
    // reached via Home's plain "Log in" button; the last browse-trail
    // screen, if reached via a paywall redirect). The router's redirect
    // rule already guarantees a logged-in user can never navigate back
    // onto a rendered Login/OTP screen, so leaving them in history here is
    // safe.
    context.pop();
    context.pop();

    final redirectTo = widget.redirectTo;
    if (redirectTo != null) {
      context.push(redirectTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpControllerProvider);
    final isLoading = otpState.isLoading;
    final errorText = otpState.hasError
        ? (otpState.error is Exception ? otpState.error.toString() : null)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Enter the code sent to ${widget.phone}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: errorText != null
                      ? 'Something went wrong. Please try again.'
                      : null,
                ),
                onSubmitted: (_) => isLoading ? null : _submit(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => ref
                          .read(otpControllerProvider.notifier)
                          .resend(widget.phone),
                child: const Text('Resend code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
