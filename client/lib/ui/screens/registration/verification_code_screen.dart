import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/ui/localization/app_copy.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  static const _mockVerificationCode = '012345';

  String _code = '';
  bool _hasAdvanced = false;

  bool get _hasInvalidCode =>
      _code.length == _mockVerificationCode.length &&
      _code != _mockVerificationCode;

  void _onCodeChanged(String value) {
    final code = value.replaceAll(RegExp(r'\D'), '');

    setState(() => _code = code);

    if (code == _mockVerificationCode && !_hasAdvanced) {
      _hasAdvanced = true;
      Navigator.of(context).pushReplacementNamed(BaseRouter.ageEligibility);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: AppCopy.verificationCodeNavigationTitle,
            leading: _BackButton(onPressed: () => Navigator.of(context).pop()),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: [
                  const AppSetupProgress(currentStep: 1, totalSteps: 6),
                  const SizedBox(height: 42),
                  const Text(
                    AppCopy.verificationCodeTitle,
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
                    AppCopy.verificationCodeBody,
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  if (_hasInvalidCode) ...[
                    const SizedBox(height: 24),
                    const AppFeedbackCard(
                      message: AppCopy.verificationCodeInvalid,
                      tone: AppFeedbackTone.error,
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.only(left: 14, bottom: 7),
                    child: Text(
                      AppCopy.verificationCodeFieldLabel,
                      style: TextStyle(color: AppColors.mutedInk, fontSize: 13),
                    ),
                  ),
                  CupertinoTextField(
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 9,
                    ),
                    placeholder: AppCopy.verificationCodePlaceholder,
                    placeholderStyle: const TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 23,
                      letterSpacing: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 19,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: _onCodeChanged,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasInvalidCode
                            ? AppColors.coral
                            : AppColors.line,
                      ),
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
