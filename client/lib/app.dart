import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_theme.dart';
import 'package:honest_dating/ui/routing/app_routing/app_router_factory.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';

class HonestDatingApp extends StatelessWidget {
  const HonestDatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouterFactory().createMainRouter();

    return CupertinoApp(
      title: 'Honest Dating',
      theme: AppTheme.cupertino,
      initialRoute: BaseRouter.onboarding,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
