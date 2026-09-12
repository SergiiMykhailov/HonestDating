import 'package:flutter/cupertino.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/ui/localization/app_copy.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class AgeEligibilityScreen extends StatefulWidget {
  const AgeEligibilityScreen({super.key, required this.profileSetupRepository});

  final BaseProfileSetupRepository profileSetupRepository;

  @override
  State<AgeEligibilityScreen> createState() => _AgeEligibilityScreenState();
}

class _AgeEligibilityScreenState extends State<AgeEligibilityScreen> {
  String _dateOfBirthText = '';

  DateTime? get _dateOfBirth {
    final match = RegExp(
      r'^(\d{2})\.(\d{2})\.(\d{4})$',
    ).firstMatch(_dateOfBirthText.trim());
    if (match == null) {
      return null;
    }

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);

    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return date;
  }

  bool get _isAgeEligible {
    final dateOfBirth = _dateOfBirth;
    if (dateOfBirth == null) {
      return false;
    }

    final now = DateTime.now();
    final eighteenthBirthday = DateTime(now.year - 18, now.month, now.day);
    return !dateOfBirth.isAfter(eighteenthBirthday);
  }

  bool get _hasCompleteDate => _dateOfBirthText.trim().length >= 10;

  bool get _hasInvalidDate => _hasCompleteDate && _dateOfBirth == null;

  bool get _isUnderage => _dateOfBirth != null && !_isAgeEligible;

  String get _errorMessage {
    if (_hasInvalidDate) {
      return AppCopy.ageEligibilityInvalidDate;
    }
    if (_isUnderage) {
      return AppCopy.ageEligibilityUnderage;
    }
    return '';
  }

  void _onDateOfBirthChanged(String value) {
    setState(() => _dateOfBirthText = value);
  }

  Future<void> _continueToConsent() async {
    final dateOfBirth = _dateOfBirth;
    if (dateOfBirth == null) {
      return;
    }

    await widget.profileSetupRepository.saveDraft(
      widget.profileSetupRepository.draft.copyWith(dateOfBirth: dateOfBirth),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamed(BaseRouter.consent);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: AppCopy.ageEligibilityNavigationTitle,
            leading: _BackButton(onPressed: () => Navigator.of(context).pop()),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: [
                  const AppSetupProgress(currentStep: 2, totalSteps: 6),
                  const SizedBox(height: 42),
                  const Text(
                    AppCopy.ageEligibilityTitle,
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
                    AppCopy.ageEligibilityBody,
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  if (_hasInvalidDate || _isUnderage) ...[
                    const SizedBox(height: 24),
                    AppFeedbackCard(
                      message: _errorMessage,
                      tone: AppFeedbackTone.error,
                    ),
                  ],
                  const SizedBox(height: 28),
                  AppFormField(
                    label: AppCopy.ageEligibilityDateLabel,
                    placeholder: AppCopy.ageEligibilityDatePlaceholder,
                    keyboardType: TextInputType.datetime,
                    onChanged: _onDateOfBirthChanged,
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: AppCopy.ageEligibilityAction,
                    onPressed: _isAgeEligible ? _continueToConsent : null,
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
