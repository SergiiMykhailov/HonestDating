import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/ui/localization/app_copy.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  static const _countries = <_CountryOption>[
    _CountryOption(name: 'Estonia', dialingCode: '+372'),
    _CountryOption(name: 'Finland', dialingCode: '+358'),
    _CountryOption(name: 'Latvia', dialingCode: '+371'),
    _CountryOption(name: 'Lithuania', dialingCode: '+370'),
    _CountryOption(name: 'Sweden', dialingCode: '+46'),
    _CountryOption(name: 'United States', dialingCode: '+1'),
  ];

  late _CountryOption _selectedCountry;
  String _phoneNumber = '';

  bool get _isPhoneNumberValid {
    final digitCount = _phoneNumber.replaceAll(RegExp(r'\D'), '').length;
    return digitCount >= 7 && digitCount <= 15;
  }

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries.first;
  }

  Future<void> _showCountryPicker() async {
    final initialIndex = _countries.indexOf(_selectedCountry);
    final controller = FixedExtentScrollController(initialItem: initialIndex);
    var selectedIndex = initialIndex;

    try {
      final country = await showCupertinoModalPopup<_CountryOption>(
        context: context,
        builder: (BuildContext context) {
          return _CountryPickerSheet(
            countries: _countries,
            controller: controller,
            onSelectedItemChanged: (int index) => selectedIndex = index,
            onDone: () => Navigator.of(context).pop(_countries[selectedIndex]),
          );
        },
      );

      if (mounted && country != null) {
        setState(() => _selectedCountry = country);
      }
    } finally {
      controller.dispose();
    }
  }

  void _onPhoneNumberChanged(String value) {
    setState(() => _phoneNumber = value);
  }

  void _requestVerificationPreview() {
    Navigator.of(context).pushNamed(BaseRouter.phoneVerificationCode);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: AppCopy.phoneVerificationNavigationTitle,
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
                    AppCopy.phoneVerificationTitle,
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
                    AppCopy.phoneVerificationBody,
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const AppFeedbackCard(
                    message: AppCopy.phoneVerificationPreview,
                  ),
                  const SizedBox(height: 28),
                  AppSelectionRow(
                    label: AppCopy.phoneVerificationCountryLabel,
                    value: _selectedCountry.displayValue,
                    onPressed: _showCountryPicker,
                  ),
                  const SizedBox(height: 20),
                  AppFormField(
                    label: AppCopy.phoneVerificationNumberLabel,
                    placeholder: AppCopy.phoneVerificationNumberPlaceholder,
                    keyboardType: TextInputType.phone,
                    onChanged: _onPhoneNumberChanged,
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: AppCopy.phoneVerificationAction,
                    onPressed: _isPhoneNumberValid
                        ? _requestVerificationPreview
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

class _CountryPickerSheet extends StatelessWidget {
  const _CountryPickerSheet({
    required this.countries,
    required this.controller,
    required this.onSelectedItemChanged,
    required this.onDone,
  });

  final List<_CountryOption> countries;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onSelectedItemChanged;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SizedBox(
          height: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 16, 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        AppCopy.phoneVerificationPickerTitle,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      onPressed: onDone,
                      child: const Text(
                        AppCopy.phoneVerificationPickerDone,
                        style: TextStyle(
                          color: AppColors.coral,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 1,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.line),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 48,
                  scrollController: controller,
                  onSelectedItemChanged: onSelectedItemChanged,
                  children: countries
                      .map(
                        (_CountryOption country) => Center(
                          child: Text(
                            country.displayValue,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryOption {
  const _CountryOption({required this.name, required this.dialingCode});

  final String name;
  final String dialingCode;

  String get displayValue => '$name ($dialingCode)';
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
