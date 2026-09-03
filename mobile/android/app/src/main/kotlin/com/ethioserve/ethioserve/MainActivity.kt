package com.ethioserve.ethioserve

import io.flutter.embedding.android.FlutterFragmentActivity

// flutter_stripe requires FlutterFragmentActivity, not the default
// FlutterActivity — Stripe's native Android PaymentSheet UI is implemented
// as an Android Fragment. See
// https://github.com/flutter-stripe/flutter_stripe#android
class MainActivity : FlutterFragmentActivity()
