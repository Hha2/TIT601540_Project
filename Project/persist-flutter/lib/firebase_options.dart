// IMPORTANT: Run `flutterfire configure` after adding google-services.json
// to android/app/ and GoogleService-Info.plist to ios/Runner/.
// See SETUP.md for full instructions.

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
        throw UnsupportedError('Unsupported platform.');
    }
  }

  // TODO: Replace ALL placeholder values with your Firebase project config.
  // 1. Go to console.firebase.google.com
  // 2. Create/select your project
  // 3. Add Android app: com.persist.persist_flutter
  // 4. Download google-services.json → place in android/app/
  // 5. Add iOS app: com.persist.persistFlutter
  // 6. Download GoogleService-Info.plist → place in ios/Runner/
  // 7. Run: flutterfire configure  (or fill values below manually)

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAhlsgHTEAX09XBUhJjiosMgGGEIxuDaZE',
    appId: '1:880714616:android:69e9d9d4260f6026c1de8d',
    messagingSenderId: '880714616',
    projectId: 'persist-app-312ac',
    storageBucket: 'persist-app-312ac.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.persist.persistFlutter',
  );
}
