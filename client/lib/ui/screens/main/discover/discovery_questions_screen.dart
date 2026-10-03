import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class DiscoveryQuestionsScreen extends StatelessWidget {
  const DiscoveryQuestionsScreen({super.key, required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        children: [
          AppNavigationBar(
            title: '100 Questions for Us',
            leading: _BackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                children: [
                  Text(
                    'A little more about ${profile.firstName}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'These are answers they chose to share before you connect.',
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (profile.questions.isEmpty)
                    const Text(
                      'No answers have been shared yet.',
                      style: TextStyle(color: AppColors.mutedInk, fontSize: 16),
                    )
                  else
                    ...profile.questions.map(
                      (DiscoveryProfileQuestion question) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _QuestionCard(question: question),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final DiscoveryProfileQuestion question;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.softCanvas,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: const TextStyle(
                color: AppColors.plum,
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              question.answer,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
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
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            CupertinoIcons.chevron_back,
            color: AppColors.coral,
            size: 24,
          ),
        ),
      ),
    );
  }
}
