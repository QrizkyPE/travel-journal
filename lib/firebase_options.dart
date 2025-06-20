// File generated by FlutterFire CLI.
// This file is a template and should be replaced with actual configuration from Firebase CLI
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyCE6w5f1sq8TTvPvEYNwXXF6vw4EBHRZqM',
    appId: '1:826819912238:web:58609723e80048924275bf',
    messagingSenderId: '826819912238',
    projectId: 'traveljournal-7a730',
    authDomain: 'traveljournal-7a730.firebaseapp.com',
    databaseURL: 'https://traveljournal-7a730-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'traveljournal-7a730.firebasestorage.app',
    measurementId: 'G-1ZQ415TKYP',
  );

  // Replace with actual configuration from Firebase console

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4u9MKVX3MR0o4cSCS7iU_BQ4bhabZYww',
    appId: '1:826819912238:android:7dd14f035e82cc244275bf',
    messagingSenderId: '826819912238',
    projectId: 'traveljournal-7a730',
    databaseURL: 'https://traveljournal-7a730-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'traveljournal-7a730.firebasestorage.app',
  );

  // Replace with actual configuration from Firebase console

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBUblh1REoxpOo5k-hzmFcQlgrAPozkIyw',
    appId: '1:826819912238:ios:26f64fc7ac2d61b04275bf',
    messagingSenderId: '826819912238',
    projectId: 'traveljournal-7a730',
    databaseURL: 'https://traveljournal-7a730-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'traveljournal-7a730.firebasestorage.app',
    iosBundleId: 'com.example.traveljournal',
  );

  // Replace with actual configuration from Firebase console

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBUblh1REoxpOo5k-hzmFcQlgrAPozkIyw',
    appId: '1:826819912238:ios:26f64fc7ac2d61b04275bf',
    messagingSenderId: '826819912238',
    projectId: 'traveljournal-7a730',
    databaseURL: 'https://traveljournal-7a730-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'traveljournal-7a730.firebasestorage.app',
    iosBundleId: 'com.example.traveljournal',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCE6w5f1sq8TTvPvEYNwXXF6vw4EBHRZqM',
    appId: '1:826819912238:web:1591b32a3cdec74c4275bf',
    messagingSenderId: '826819912238',
    projectId: 'traveljournal-7a730',
    authDomain: 'traveljournal-7a730.firebaseapp.com',
    databaseURL: 'https://traveljournal-7a730-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'traveljournal-7a730.firebasestorage.app',
    measurementId: 'G-RVRKJWSX07',
  );

}