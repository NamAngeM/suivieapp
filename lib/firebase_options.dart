import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuration Firebase pour Zoe Church Visitors
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDbXYVfRUT5G7-I504SRTfe6X3aVga2uJ8',
    appId: '1:754522100331:web:029f9ca71695040231972e',
    messagingSenderId: '754522100331',
    projectId: 'suivi-ames-app',
    authDomain: 'suivi-ames-app.firebaseapp.com',
    storageBucket: 'suivi-ames-app.firebasestorage.app',
    measurementId: 'G-Y99M0MS8P6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDOfCvfpnKOTK7gksBHxqc6bYA_39Nl50w',
    appId: '1:754522100331:android:7762f98b3bf0287731972e',
    messagingSenderId: '754522100331',
    projectId: 'suivi-ames-app',
    storageBucket: 'suivi-ames-app.firebasestorage.app',
  );

  // Configuration iOS - à ajouter si vous déployez sur iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '754522100331',
    projectId: 'suivi-ames-app',
    storageBucket: 'suivi-ames-app.firebasestorage.app',
    iosBundleId: 'com.zoechurch.zoeChurchVisitors',
  );
}
