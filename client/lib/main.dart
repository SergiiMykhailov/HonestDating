import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter/widgets.dart';
import 'package:honest_dating/app.dart';

const String _stagingAppCheckDebugToken = String.fromEnvironment(
  'APP_CHECK_DEBUG_TOKEN',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // `flutter run --release --flavor staging` has kDebugMode disabled. Staging
  // therefore needs an explicit debug provider while the production flavor
  // continues to use hardware-backed attestation.
  final useDebugAppCheck = kDebugMode || appFlavor == 'staging';
  await FirebaseAppCheck.instance.activate(
    providerAndroid: useDebugAppCheck
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: useDebugAppCheck
        ? AppleDebugProvider(
            debugToken: _stagingAppCheckDebugToken.isEmpty
                ? null
                : _stagingAppCheckDebugToken,
          )
        : const AppleAppAttestProvider(),
  );
  runApp(const HonestDatingApp());
}
