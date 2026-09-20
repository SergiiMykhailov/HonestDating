import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration_flow/bloc/registration_attribute_bloc.dart';
import 'package:honest_dating/ui/screens/registration_flow/registration_attribute.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class RegistrationAttributeScreen extends StatelessWidget {
  const RegistrationAttributeScreen({
    super.key,
    required BaseProfileSetupRepository repository,
    required this.step,
  }) : _repository = repository;

  final BaseProfileSetupRepository _repository;
  final RegistrationAttributeStep step;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistrationAttributeBloc>(
      create: (BuildContext context) =>
          RegistrationAttributeBloc(repository: _repository, step: step),
      child: const _RegistrationAttributeView(),
    );
  }
}

class _RegistrationAttributeView extends StatelessWidget {
  const _RegistrationAttributeView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child:
          BlocConsumer<RegistrationAttributeBloc, RegistrationAttributeState>(
            listenWhen: (previous, current) =>
                previous.navigationRequest != current.navigationRequest,
            listener: (BuildContext context, RegistrationAttributeState state) {
              switch (state.destination) {
                case RegistrationAttributeDestination.nextAttribute:
                  Navigator.of(context).pushNamed(
                    BaseRouter.registrationAttribute,
                    arguments: state.step.next,
                  );
                case RegistrationAttributeDestination
                    .friendshipOnlyConfirmation:
                  Navigator.of(context).pushNamed(
                    BaseRouter.registrationFriendshipOnlyConfirmation,
                  );
                case RegistrationAttributeDestination.religiosity:
                  Navigator.of(
                    context,
                  ).pushNamed(BaseRouter.registrationReligiosity);
                case RegistrationAttributeDestination.registrationComplete:
                  Navigator.of(
                    context,
                  ).pushNamed(BaseRouter.registrationComplete);
                case null:
                  break;
              }
            },
            builder: (BuildContext context, RegistrationAttributeState state) {
              final step = state.step;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppNavigationBar(
                    title: 'Create profile',
                    leading: _BackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          AppSetupProgress(
                            currentStep: step.registrationStep,
                            totalSteps: 25,
                          ),
                          const SizedBox(height: 42),
                          Text(
                            step.title,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 30,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            step.body,
                            style: const TextStyle(
                              color: AppColors.mutedInk,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (step == RegistrationAttributeStep.height)
                            _HeightEntry(state: state)
                          else if (step.allowsMultipleChoices)
                            _LanguageChoices(state: state)
                          else
                            _InstantChoices(step: step),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _InstantChoices extends StatelessWidget {
  const _InstantChoices({required this.step});

  final RegistrationAttributeStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: registrationOptionsFor(step)
          .map(
            (String option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  onPressed: () {
                    context.read<RegistrationAttributeBloc>().add(
                      RegistrationAttributeOptionSelected(option),
                    );
                  },
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.coral,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LanguageChoices extends StatelessWidget {
  const _LanguageChoices({required this.state});

  final RegistrationAttributeState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...registrationOptionsFor(state.step).map((String option) {
          final isSelected = state.draft.languages.contains(option);
          final isAvailable = isSelected || state.draft.languages.length < 5;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Opacity(
              opacity: isAvailable ? 1 : 0.45,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: isAvailable
                    ? () {
                        context.read<RegistrationAttributeBloc>().add(
                          RegistrationAttributeLanguageToggled(option),
                        );
                      }
                    : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: CupertinoSwitch(
                            value: isSelected,
                            activeTrackColor: AppColors.coral,
                            onChanged: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        AppPrimaryButton(
          label: 'Continue',
          onPressed: state.canContinue
              ? () {
                  context.read<RegistrationAttributeBloc>().add(
                    const RegistrationAttributeContinueRequested(),
                  );
                }
              : null,
        ),
      ],
    );
  }
}

class _HeightEntry extends StatefulWidget {
  const _HeightEntry({required this.state});

  final RegistrationAttributeState state;

  @override
  State<_HeightEntry> createState() => _HeightEntryState();
}

class _HeightEntryState extends State<_HeightEntry> {
  late final TextEditingController _centimetersController;
  late final TextEditingController _imperialController;

  @override
  void initState() {
    super.initState();
    final draft = widget.state.draft;
    _centimetersController = TextEditingController(
      text: draft.heightCentimeters,
    );
    _imperialController = TextEditingController(
      text: draft.heightFeet.isEmpty && draft.heightInches.isEmpty
          ? ''
          : "${draft.heightFeet}' ${draft.heightInches}\"",
    );
  }

  @override
  void dispose() {
    _centimetersController.dispose();
    _imperialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.state.draft;
    final isMetric = draft.heightUnit == HeightUnit.metric;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _UnitButton(
              label: 'Centimetres',
              isSelected: isMetric,
              onPressed: () => context.read<RegistrationAttributeBloc>().add(
                const RegistrationAttributeHeightUnitChanged(HeightUnit.metric),
              ),
            ),
            const SizedBox(width: 10),
            _UnitButton(
              label: 'Feet & inches',
              isSelected: !isMetric,
              onPressed: () => context.read<RegistrationAttributeBloc>().add(
                const RegistrationAttributeHeightUnitChanged(
                  HeightUnit.imperial,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (isMetric)
          AppFormField(
            label: 'Height in centimetres',
            placeholder: 'For example, 171',
            controller: _centimetersController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (String value) {
              context.read<RegistrationAttributeBloc>().add(
                RegistrationAttributeHeightChanged(centimeters: value),
              );
            },
          )
        else
          AppFormField(
            label: 'Height in feet and inches',
            placeholder: "For example, 5' 7\"",
            controller: _imperialController,
            autofocus: true,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'''[0-9'"\s]''')),
            ],
            onChanged: (String value) {
              context.read<RegistrationAttributeBloc>().add(
                RegistrationAttributeHeightChanged(imperialHeight: value),
              );
            },
          ),
        if ((isMetric && draft.heightCentimeters.isNotEmpty ||
                !isMetric && _imperialController.text.isNotEmpty) &&
            !draft.hasValidRegistrationHeight) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text(
              'Enter a height between 80 and 250 cm.',
              style: TextStyle(color: AppColors.coral, fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 18),
        AppPrimaryButton(
          label: 'Continue',
          onPressed: widget.state.canContinue
              ? () {
                  context.read<RegistrationAttributeBloc>().add(
                    const RegistrationAttributeContinueRequested(),
                  );
                }
              : null,
        ),
      ],
    );
  }
}

class _UnitButton extends StatelessWidget {
  const _UnitButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: isSelected ? AppColors.coral : null,
      borderRadius: BorderRadius.circular(20),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.canvas : AppColors.coral,
          fontSize: 14,
          fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(15),
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
