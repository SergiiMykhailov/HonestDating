import 'package:flutter/cupertino.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Honest Dating'),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A respectful place to meet.',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This is the architecture-only skeleton for Honest Dating.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(BaseRouter.home);
                  },
                  child: const Text('Open skeleton'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
