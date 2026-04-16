// ⚠️  DEVELOPMENT PLACEHOLDER — replace with real values by running:
//
//       cd cambook_app
//       flutterfire configure
//
// Steps to get real credentials:
//   1. Install Firebase CLI:   npm install -g firebase-tools
//   2. Log in:                 firebase login
//   3. Generate config:        flutterfire configure
//
// The command above will overwrite this file with real keys and will
// automatically place ios/Runner/GoogleService-Info.plist.
//
// NOTE: The fake values below are syntactically valid so Firebase
// initializes without crashing. Firebase API calls will fail with
// permission errors until real credentials are supplied.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run `flutterfire configure` to regenerate.',
        );
    }
  }

  // ── Web ───────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'dev-placeholder-web-api-key',
    appId:             '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId:         'cambook-dev-placeholder',
    authDomain:        'cambook-dev-placeholder.firebaseapp.com',
    storageBucket:     'cambook-dev-placeholder.appspot.com',
  );

  // ── Android ───────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'dev-placeholder-android-api-key',
    appId:             '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId:         'cambook-dev-placeholder',
    storageBucket:     'cambook-dev-placeholder.appspot.com',
  );

  // ── iOS ───────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'dev-placeholder-ios-api-key',
    appId:             '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId:         'cambook-dev-placeholder',
    storageBucket:     'cambook-dev-placeholder.appspot.com',
    iosBundleId:       'com.cambook.cambookApp',
  );
}
