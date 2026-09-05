import 'package:flutter/cupertino.dart';

abstract interface class BaseRouter {
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String likes = '/likes';
  static const String matches = '/matches';
  static const String messages = '/messages';
  static const String profile = '/profile';

  Route<void> onGenerateRoute(RouteSettings settings);
}
