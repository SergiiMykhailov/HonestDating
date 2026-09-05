import 'package:flutter/cupertino.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
