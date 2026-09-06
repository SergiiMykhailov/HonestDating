import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class LegalDocumentPlaceholderScreen extends StatelessWidget {
  const LegalDocumentPlaceholderScreen({
    super.key,
    required this.title,
    required this.placeholder,
  });

  final String title;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: title,
            leading: _BackButton(onPressed: () => Navigator.of(context).pop()),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppFeedbackCard(message: placeholder),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(48, 48),
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.line),
        ),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            CupertinoIcons.chevron_back,
            color: AppColors.coral,
            size: 21,
          ),
        ),
      ),
    );
  }
}
