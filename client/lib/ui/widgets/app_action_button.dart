import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/authentication_provider.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: CupertinoButton(
        color: AppColors.coral,
        borderRadius: BorderRadius.circular(16),
        disabledColor: AppColors.coral.withValues(alpha: 0.45),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(color: AppColors.canvas)
            : Text(
                label,
                style: const TextStyle(
                  color: AppColors.canvas,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class AppSocialSignInButton extends StatelessWidget {
  const AppSocialSignInButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  final AuthenticationProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        onPressed: isLoading ? null : onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
            color: AppColors.canvas,
          ),
          child: Center(
            child: isLoading
                ? const CupertinoActivityIndicator(color: AppColors.coral)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProviderMark(provider: provider),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with ${provider.label}',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProviderMark extends StatelessWidget {
  const _ProviderMark({required this.provider});

  final AuthenticationProvider provider;

  @override
  Widget build(BuildContext context) {
    switch (provider) {
      case AuthenticationProvider.google:
        return const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.coralSoft,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      case AuthenticationProvider.apple:
        return const Icon(Icons.apple, color: AppColors.ink, size: 22);
    }
  }
}
