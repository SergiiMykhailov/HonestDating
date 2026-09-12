import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/ui/localization/app_copy.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _hasAcceptedTerms = false;
  bool _hasAcceptedPrivacyPolicy = false;

  bool get _canContinue => _hasAcceptedTerms && _hasAcceptedPrivacyPolicy;

  void _continueToIdentityVerification() {
    Navigator.of(context).pushNamed(BaseRouter.identityVerification);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: AppCopy.consentNavigationTitle,
            leading: _BackButton(onPressed: () => Navigator.of(context).pop()),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: [
                  const AppSetupProgress(currentStep: 3, totalSteps: 6),
                  const SizedBox(height: 42),
                  const Text(
                    AppCopy.consentTitle,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    AppCopy.consentBody,
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _ConsentToggle(
                    label: AppCopy.consentTermsLabel,
                    value: _hasAcceptedTerms,
                    onOpen: () {
                      Navigator.of(
                        context,
                      ).pushNamed(BaseRouter.termsOfService);
                    },
                    onChanged: (bool value) {
                      setState(() => _hasAcceptedTerms = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _ConsentToggle(
                    label: AppCopy.consentPrivacyLabel,
                    value: _hasAcceptedPrivacyPolicy,
                    onOpen: () {
                      Navigator.of(context).pushNamed(BaseRouter.privacyPolicy);
                    },
                    onChanged: (bool value) {
                      setState(() => _hasAcceptedPrivacyPolicy = value);
                    },
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: AppCopy.consentAction,
                    onPressed: _canContinue
                        ? _continueToIdentityVerification
                        : null,
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

class _ConsentToggle extends StatelessWidget {
  const _ConsentToggle({
    required this.label,
    required this.value,
    required this.onOpen,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final VoidCallback onOpen;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CupertinoSwitch(
              value: value,
              activeTrackColor: AppColors.coral,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              onPressed: onOpen,
              child: const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.coral,
                size: 18,
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
