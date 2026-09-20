import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration_flow/bloc/registration_core_details_bloc.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class RegistrationCoreDetailsScreen extends StatelessWidget {
  const RegistrationCoreDetailsScreen({
    super.key,
    required BaseProfileSetupRepository repository,
    required this.step,
  }) : _repository = repository;

  final BaseProfileSetupRepository _repository;
  final RegistrationCoreDetailsStep step;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistrationCoreDetailsBloc>(
      create: (BuildContext context) =>
          RegistrationCoreDetailsBloc(repository: _repository, step: step),
      child: const _RegistrationCoreDetailsView(),
    );
  }
}

class _RegistrationCoreDetailsView extends StatefulWidget {
  const _RegistrationCoreDetailsView();

  @override
  State<_RegistrationCoreDetailsView> createState() =>
      _RegistrationCoreDetailsViewState();
}

class _RegistrationCoreDetailsViewState
    extends State<_RegistrationCoreDetailsView> {
  final TextEditingController _controller = TextEditingController();
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    final state = context.read<RegistrationCoreDetailsBloc>().state;
    _controller.text = switch (state.step) {
      RegistrationCoreDetailsStep.firstName => state.draft.firstName,
      RegistrationCoreDetailsStep.gender => '',
      RegistrationCoreDetailsStep.dateOfBirth => state.dateOfBirthInput,
    };
    _seeded = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child:
          BlocConsumer<
            RegistrationCoreDetailsBloc,
            RegistrationCoreDetailsState
          >(
            listenWhen: (previous, current) =>
                previous.navigationRequest != current.navigationRequest,
            listener:
                (BuildContext context, RegistrationCoreDetailsState state) {
                  if (state.navigationRequest == 0) {
                    return;
                  }
                  final next = state.step.next;
                  if (next != null) {
                    Navigator.of(context).pushNamed(
                      BaseRouter.registrationCoreDetails,
                      arguments: next,
                    );
                  } else {
                    Navigator.of(
                      context,
                    ).pushNamed(BaseRouter.identityVerification);
                  }
                },
            builder:
                (BuildContext context, RegistrationCoreDetailsState state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppNavigationBar(
                        title: 'Your details',
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
                                currentStep: state.step.registrationStep,
                                totalSteps: 25,
                              ),
                              const SizedBox(height: 42),
                              Text(
                                _titleFor(state.step),
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
                                _bodyFor(state.step),
                                style: const TextStyle(
                                  color: AppColors.mutedInk,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _StepInput(state: state, controller: _controller),
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

class _StepInput extends StatelessWidget {
  const _StepInput({required this.state, required this.controller});

  final RegistrationCoreDetailsState state;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    switch (state.step) {
      case RegistrationCoreDetailsStep.firstName:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormField(
              label: 'First name',
              placeholder: 'Type your first name',
              controller: controller,
              keyboardType: TextInputType.name,
              autofocus: true,
              onChanged: (String value) {
                context.read<RegistrationCoreDetailsBloc>().add(
                  RegistrationFirstNameChanged(value),
                );
              },
            ),
            const SizedBox(height: 18),
            _ContinueButton(enabled: state.canContinue),
          ],
        );
      case RegistrationCoreDetailsStep.gender:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const <String>['Man', 'Woman', 'Non-binary']
              .map(
                (String gender) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _GenderChoice(label: gender),
                ),
              )
              .toList(),
        );
      case RegistrationCoreDetailsStep.dateOfBirth:
        final error = state.dateOfBirthError ?? state.eligibilityError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormField(
              label: 'Date of birth',
              placeholder: 'DD.MM.YYYY',
              controller: controller,
              keyboardType: TextInputType.datetime,
              autofocus: true,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (String value) {
                context.read<RegistrationCoreDetailsBloc>().add(
                  RegistrationDateOfBirthChanged(value),
                );
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  error,
                  style: const TextStyle(color: AppColors.coral, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _ContinueButton(enabled: state.canContinue),
            const SizedBox(height: 22),
            const Text(
              'Please make sure your first name, gender, and date of birth are correct. After you complete registration, these details will be fixed and cannot be changed freely. This helps us maintain a trusted community that is more resistant to bots, catfishing, and bad behavior. If you make a genuine mistake, changes may be possible through the applicable verification or support-review process. Please review your information carefully before continuing.',
              style: TextStyle(
                color: AppColors.mutedInk,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        );
    }
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: 'Continue',
      onPressed: enabled
          ? () {
              context.read<RegistrationCoreDetailsBloc>().add(
                const RegistrationCoreDetailsContinueRequested(),
              );
            }
          : null,
    );
  }
}

class _GenderChoice extends StatelessWidget {
  const _GenderChoice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        onPressed: () {
          context.read<RegistrationCoreDetailsBloc>().add(
            RegistrationGenderSelected(label),
          );
        },
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.coral,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _titleFor(RegistrationCoreDetailsStep step) {
  switch (step) {
    case RegistrationCoreDetailsStep.firstName:
      return 'What’s your first name?';
    case RegistrationCoreDetailsStep.gender:
      return 'How do you identify?';
    case RegistrationCoreDetailsStep.dateOfBirth:
      return 'When were you born?';
  }
}

String _bodyFor(RegistrationCoreDetailsStep step) {
  switch (step) {
    case RegistrationCoreDetailsStep.firstName:
      return 'Use the name you want people to see.';
    case RegistrationCoreDetailsStep.gender:
      return 'Tap one option to choose it and continue.';
    case RegistrationCoreDetailsStep.dateOfBirth:
      return 'We use your date of birth to confirm you are eligible to join.';
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
