import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBKnFB3Nt_a2QVFiMDYW7W83TzIDESijUs',
    appId: '1:691534337387:web:c18080365b2b7e71d7e82e',
    messagingSenderId: '691534337387',
    projectId: 'kopdes-99646',
    authDomain: 'kopdes-99646.firebaseapp.com',
    storageBucket: 'kopdes-99646.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-TjymWoT7Xt_bYS0YrduZKtaFvmiZXNA',
    appId: '1:691534337387:android:6843915ca0666b08d7e82e',
    messagingSenderId: '691534337387',
    projectId: 'kopdes-99646',
    storageBucket: 'kopdes-99646.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9GP_2jukAgjm0sMWFApFJi1KBn_dFrwE',
    appId: '1:691534337387:ios:e97c7ff3497b9621d7e82e',
    messagingSenderId: '691534337387',
    projectId: 'kopdes-99646',
    storageBucket: 'kopdes-99646.firebasestorage.app',
    iosBundleId: 'com.example.flutterKop',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA9GP_2jukAgjm0sMWFApFJi1KBn_dFrwE',
    appId: '1:691534337387:ios:e97c7ff3497b9621d7e82e',
    messagingSenderId: '691534337387',
    projectId: 'kopdes-99646',
    storageBucket: 'kopdes-99646.firebasestorage.app',
    iosBundleId: 'com.example.flutterKop',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBKnFB3Nt_a2QVFiMDYW7W83TzIDESijUs',
    appId: '1:691534337387:web:93434268c10cd4a3d7e82e',
    messagingSenderId: '691534337387',
    projectId: 'kopdes-99646',
    authDomain: 'kopdes-99646.firebaseapp.com',
    storageBucket: 'kopdes-99646.firebasestorage.app',
  );
}
