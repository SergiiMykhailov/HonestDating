import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (leading != null) Positioned(left: 16, child: leading!),
            if (trailing != null) Positioned(right: 16, child: trailing!),
          ],
        ),
      ),
    );
  }
}
