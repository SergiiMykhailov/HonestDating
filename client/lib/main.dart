import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:honest_dating/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HonestDatingApp());
}
