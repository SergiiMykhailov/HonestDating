import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';

class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.onChanged,
  });

  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.mutedInk, fontSize: 13),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofocus: autofocus,
          onChanged: onChanged,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          placeholder: placeholder,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
        ),
      ],
    );
  }
}

class AppSelectionRow extends StatelessWidget {
  const AppSelectionRow({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.mutedInk,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.coral,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: const Size(38, 38),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      color: isSelected ? AppColors.coral : AppColors.canvas,
      borderRadius: BorderRadius.circular(20),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.canvas : AppColors.plum,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AppSetupProgress extends StatelessWidget {
  const AppSetupProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps == 0 ? 0.0 : currentStep / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $currentStep of $totalSteps',
          style: const TextStyle(color: AppColors.mutedInk, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            width: double.infinity,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.line),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.coral),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
