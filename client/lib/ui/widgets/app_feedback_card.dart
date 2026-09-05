import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';

enum AppFeedbackTone { information, error }

class AppFeedbackCard extends StatelessWidget {
  const AppFeedbackCard({
    super.key,
    required this.message,
    this.tone = AppFeedbackTone.information,
    this.onDismissed,
  });

  final String message;
  final AppFeedbackTone tone;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    final isError = tone == AppFeedbackTone.error;
    final color = isError ? AppColors.coral : AppColors.plum;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Icon(
              isError
                  ? CupertinoIcons.exclamationmark_circle
                  : CupertinoIcons.info_circle,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
            if (onDismissed != null)
              CupertinoButton(
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(6),
                onPressed: onDismissed,
                child: Icon(CupertinoIcons.xmark, color: color, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
