import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/screens/registration/bloc/profile_setup_bloc.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key, required this.repository});

  final BaseProfileSetupRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileSetupBloc>(
      create: (BuildContext context) =>
          ProfileSetupBloc(repository: repository),
      child: const _ProfileSetupFlow(),
    );
  }
}

class _ProfileSetupFlow extends StatefulWidget {
  const _ProfileSetupFlow();

  @override
  State<_ProfileSetupFlow> createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends State<_ProfileSetupFlow> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  bool _didSeedTextControllers = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeedTextControllers) {
      return;
    }
    _syncTextController(context.read<ProfileSetupBloc>().state);
    _didSeedTextControllers = true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocConsumer<ProfileSetupBloc, ProfileSetupState>(
        listenWhen: (ProfileSetupState previous, ProfileSetupState current) =>
            previous.step != current.step,
        listener: (BuildContext context, ProfileSetupState state) {
          _syncTextController(state);
        },
        builder: (BuildContext context, ProfileSetupState state) {
          if (state.isCompleted) {
            return _ProfileDetailsSavedView(
              onBack: () => Navigator.of(context).pop(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: 'Create profile',
                leading: _BackButton(
                  onPressed: () => _onBackPressed(context, state),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    children: [
                      const AppSetupProgress(currentStep: 5, totalSteps: 6),
                      const SizedBox(height: 20),
                      _FlowProgress(step: state.step),
                      const SizedBox(height: 40),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _StepContent(
                          key: ValueKey<ProfileSetupStep>(state.step),
                          state: state,
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                          heightController: _heightController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.requiresContinue && !state.requiresTextEntry)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: AppPrimaryButton(
                      label: 'Continue',
                      onPressed: state.canContinue
                          ? () {
                              context.read<ProfileSetupBloc>().add(
                                const ProfileSetupContinueRequested(),
                              );
                            }
                          : null,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _onBackPressed(BuildContext context, ProfileSetupState state) {
    if (state.step == ProfileSetupStep.firstName) {
      Navigator.of(context).pop();
      return;
    }
    context.read<ProfileSetupBloc>().add(const ProfileSetupBackRequested());
  }

  void _syncTextController(ProfileSetupState state) {
    switch (state.step) {
      case ProfileSetupStep.firstName:
        _firstNameController.text = state.draft.firstName;
      case ProfileSetupStep.lastName:
        _lastNameController.text = state.draft.lastName;
      case ProfileSetupStep.height:
        _heightController.text = state.draft.heightCentimeters;
      default:
        return;
    }
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    super.key,
    required this.state,
    required this.firstNameController,
    required this.lastNameController,
    required this.heightController,
  });

  final ProfileSetupState state;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController heightController;

  @override
  Widget build(BuildContext context) {
    final step = state.step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _titleFor(step),
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
          _bodyFor(step),
          style: const TextStyle(
            color: AppColors.mutedInk,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 30),
        if (state.requiresTextEntry)
          _TextEntryStep(
            state: state,
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            heightController: heightController,
          )
        else if (state.isVerifiedDetails)
          _VerifiedDetailsCard(draft: state.draft)
        else if (state.requiresMultipleChoices)
          _MultipleChoiceStep(state: state)
        else
          _SingleChoiceStep(state: state),
      ],
    );
  }
}

class _TextEntryStep extends StatelessWidget {
  const _TextEntryStep({
    required this.state,
    required this.firstNameController,
    required this.lastNameController,
    required this.heightController,
  });

  final ProfileSetupState state;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController heightController;

  @override
  Widget build(BuildContext context) {
    final controller = switch (state.step) {
      ProfileSetupStep.firstName => firstNameController,
      ProfileSetupStep.lastName => lastNameController,
      ProfileSetupStep.height => heightController,
      _ => firstNameController,
    };
    final isHeight = state.step == ProfileSetupStep.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormField(
          label: isHeight ? 'Height in centimetres' : 'Required',
          placeholder: isHeight ? 'For example, 171' : 'Type here',
          controller: controller,
          keyboardType: isHeight ? TextInputType.number : TextInputType.name,
          autofocus: true,
          onChanged: (String value) {
            context.read<ProfileSetupBloc>().add(
              ProfileSetupTextChanged(value),
            );
          },
        ),
        if (isHeight &&
            state.draft.heightCentimeters.isNotEmpty &&
            !state.draft.hasValidHeight) ...[
          const SizedBox(height: 9),
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
          onPressed: state.canContinue
              ? () {
                  context.read<ProfileSetupBloc>().add(
                    const ProfileSetupContinueRequested(),
                  );
                }
              : null,
        ),
      ],
    );
  }
}

class _SingleChoiceStep extends StatelessWidget {
  const _SingleChoiceStep({required this.state});

  final ProfileSetupState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _optionsFor(state.step)
          .map(
            (String option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InstantChoice(
                label: option,
                onPressed: () {
                  context.read<ProfileSetupBloc>().add(
                    ProfileSetupSingleChoiceSelected(option),
                  );
                },
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MultipleChoiceStep extends StatelessWidget {
  const _MultipleChoiceStep({required this.state});

  final ProfileSetupState state;

  @override
  Widget build(BuildContext context) {
    final isLanguages = state.step == ProfileSetupStep.languages;
    final selected = isLanguages
        ? state.draft.languages
        : state.draft.foodRestrictions;
    final maximumSelections = isLanguages ? 3 : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFeedbackCard(
          message: isLanguages
              ? 'Choose up to three languages, then continue.'
              : 'Choose any that apply. No Restrictions cannot be combined with another choice.',
        ),
        const SizedBox(height: 18),
        ..._optionsFor(state.step).map((String option) {
          final isSelected = selected.contains(option);
          final cannotSelect =
              maximumSelections != null &&
              selected.length >= maximumSelections &&
              !isSelected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ToggleChoice(
              label: option,
              isSelected: isSelected,
              isEnabled: !cannotSelect,
              onChanged: () {
                context.read<ProfileSetupBloc>().add(
                  ProfileSetupMultiChoiceToggled(option),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _InstantChoice extends StatelessWidget {
  const _InstantChoice({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onPressed: onPressed,
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

class _ToggleChoice extends StatelessWidget {
  const _ToggleChoice({
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onChanged,
  });

  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.45,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: isEnabled ? onChanged : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
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
                CupertinoSwitch(
                  value: isSelected,
                  activeTrackColor: AppColors.coral,
                  onChanged: isEnabled ? (bool value) => onChanged() : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerifiedDetailsCard extends StatelessWidget {
  const _VerifiedDetailsCard({required this.draft});

  final ProfileSetupDraft draft;

  @override
  Widget build(BuildContext context) {
    final dateOfBirth = draft.dateOfBirth;
    if (dateOfBirth == null) {
      return const AppFeedbackCard(
        message:
            'Your verified date of birth is unavailable. Return to the date-of-birth step and enter it again.',
        tone: AppFeedbackTone.error,
      );
    }

    final dateLabel =
        '${dateOfBirth.day.toString().padLeft(2, '0')}.${dateOfBirth.month.toString().padLeft(2, '0')}.${dateOfBirth.year}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.softCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _ReadOnlyDetail(label: 'Date of birth', value: dateLabel),
            _ReadOnlyDetail(label: 'Age', value: '${draft.age}'),
            _ReadOnlyDetail(
              label: 'Zodiac sign',
              value: draft.zodiacSign ?? '—',
            ),
            _ReadOnlyDetail(
              label: 'Year animal',
              value: draft.yearAnimal ?? '—',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyDetail extends StatelessWidget {
  const _ReadOnlyDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.mutedInk, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowProgress extends StatelessWidget {
  const _FlowProgress({required this.step});

  final ProfileSetupStep step;

  @override
  Widget build(BuildContext context) {
    final current = step.index + 1;
    final total = ProfileSetupStep.values.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile detail $current of $total',
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
                widthFactor: current / total,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.plum),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailsSavedView extends StatelessWidget {
  const _ProfileDetailsSavedView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNavigationBar(
          title: 'Profile details',
          leading: _BackButton(onPressed: onBack),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSetupProgress(currentStep: 5, totalSteps: 6),
                  const Spacer(),
                  const Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.coralSoft,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 104,
                        height: 104,
                        child: Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          size: 58,
                          color: AppColors.coral,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Profile details saved',
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
                    'Photos, About Me, and interests are the next required registration slices. Discover remains locked until they are complete.',
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ],
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

String _titleFor(ProfileSetupStep step) {
  switch (step) {
    case ProfileSetupStep.firstName:
      return 'What’s your first name?';
    case ProfileSetupStep.lastName:
      return 'And your last name?';
    case ProfileSetupStep.verifiedDetails:
      return 'Your verified details';
    case ProfileSetupStep.gender:
      return 'How do you identify?';
    case ProfileSetupStep.orientation:
      return 'What is your orientation?';
    case ProfileSetupStep.relationshipIntention:
      return 'What are you looking for?';
    case ProfileSetupStep.height:
      return 'How tall are you?';
    case ProfileSetupStep.bodyType:
      return 'How would you describe your body type?';
    case ProfileSetupStep.hairColor:
      return 'What is your hair color?';
    case ProfileSetupStep.eyeColor:
      return 'What is your eye color?';
    case ProfileSetupStep.languages:
      return 'Which languages do you speak?';
    case ProfileSetupStep.countryOfOrigin:
      return 'Where are you from?';
    case ProfileSetupStep.religion:
      return 'What is your religion?';
    case ProfileSetupStep.religiosity:
      return 'How religious are you?';
    case ProfileSetupStep.socialOrientation:
      return 'How social are you?';
    case ProfileSetupStep.goingOut:
      return 'How do you like to go out?';
    case ProfileSetupStep.hosting:
      return 'How do you feel about hosting?';
    case ProfileSetupStep.livingArrangement:
      return 'What is your living arrangement?';
    case ProfileSetupStep.livingEnvironment:
      return 'Where do you feel at home?';
    case ProfileSetupStep.diet:
      return 'What is your diet?';
    case ProfileSetupStep.foodRestrictions:
      return 'Any food restrictions?';
    case ProfileSetupStep.exercise:
      return 'How often do you exercise?';
    case ProfileSetupStep.sleepSchedule:
      return 'What is your sleep schedule?';
    case ProfileSetupStep.alcohol:
      return 'How often do you drink alcohol?';
    case ProfileSetupStep.smoking:
      return 'Do you smoke?';
    case ProfileSetupStep.recreationalDrugs:
      return 'Do you use recreational drugs?';
    case ProfileSetupStep.pets:
      return 'What is your relationship with pets?';
    case ProfileSetupStep.children:
      return 'What is your relationship with children?';
    case ProfileSetupStep.travelFrequency:
      return 'How often do you travel?';
    case ProfileSetupStep.educationLevel:
      return 'What is your education level?';
    case ProfileSetupStep.currentEducation:
      return 'Are you studying now?';
    case ProfileSetupStep.employment:
      return 'What is your employment status?';
  }
}

String _bodyFor(ProfileSetupStep step) {
  switch (step) {
    case ProfileSetupStep.verifiedDetails:
      return 'These are calculated from the date of birth you confirmed earlier.';
    case ProfileSetupStep.languages:
      return 'Select the languages you can speak. You can choose up to three.';
    case ProfileSetupStep.foodRestrictions:
      return 'Select all that apply to you.';
    case ProfileSetupStep.firstName:
    case ProfileSetupStep.lastName:
      return 'Use the name you want people to see. It is protected after registration.';
    default:
      return 'Tap one option to choose it and continue.';
  }
}

List<String> _optionsFor(ProfileSetupStep step) {
  switch (step) {
    case ProfileSetupStep.gender:
      return const <String>['Man', 'Woman', 'Non-binary'];
    case ProfileSetupStep.orientation:
      return const <String>[
        'Straight',
        'Gay/Lesbian',
        'Bisexual',
        'Pansexual',
        'Asexual',
        'Queer',
        'Other',
      ];
    case ProfileSetupStep.relationshipIntention:
      return const <String>[
        'Long-Term Relationship',
        'Long-Term, Open to Short-Term',
        'Short-Term, Open to Long-Term',
        'Short-Term Relationship',
        'Not Dating — Friendship Only',
      ];
    case ProfileSetupStep.bodyType:
      return const <String>[
        'Slim',
        'Average',
        'Athletic',
        'Muscular',
        'Curvy',
        'Large',
        'Other',
      ];
    case ProfileSetupStep.hairColor:
      return const <String>[
        'Black',
        'Brown',
        'Blonde',
        'Red',
        'Gray',
        'White',
        'Other',
      ];
    case ProfileSetupStep.eyeColor:
      return const <String>[
        'Brown',
        'Blue',
        'Green',
        'Hazel',
        'Gray',
        'Amber',
        'Other',
      ];
    case ProfileSetupStep.languages:
      return _languages;
    case ProfileSetupStep.countryOfOrigin:
      return _countries;
    case ProfileSetupStep.religion:
      return const <String>[
        'Christianity',
        'Islam',
        'Judaism',
        'Hinduism',
        'Buddhism',
        'Sikhism',
        'Other Religion',
        'No Religion',
      ];
    case ProfileSetupStep.religiosity:
      return const <String>[
        'Very Religious',
        'Moderately Religious',
        'Somewhat Religious',
        'Not Religious',
      ];
    case ProfileSetupStep.socialOrientation:
      return const <String>['Introvert', 'Ambivert', 'Extrovert'];
    case ProfileSetupStep.goingOut:
      return const <String>[
        'Homebody',
        'Sometimes Goes Out',
        'Enjoys Going Out',
      ];
    case ProfileSetupStep.hosting:
      return const <String>[
        'Prefers Not to Host',
        'Sometimes Hosts',
        'Enjoys Hosting',
      ];
    case ProfileSetupStep.livingArrangement:
      return const <String>[
        'Live Alone',
        'Live with Roommates',
        'Live with Family',
        'Live with a Partner',
      ];
    case ProfileSetupStep.livingEnvironment:
      return const <String>['Urban', 'Suburban', 'Rural'];
    case ProfileSetupStep.diet:
      return const <String>[
        'Omnivore',
        'Vegetarian',
        'Vegan',
        'Pescatarian',
        'Flexitarian',
      ];
    case ProfileSetupStep.foodRestrictions:
      return _foodRestrictions;
    case ProfileSetupStep.exercise:
      return const <String>[
        'Never',
        'Occasionally',
        '1–2 times a week',
        '3–4 times a week',
        '5+ times a week',
      ];
    case ProfileSetupStep.sleepSchedule:
      return const <String>['Early Bird', 'Flexible', 'Night Owl'];
    case ProfileSetupStep.alcohol:
      return const <String>['Never', 'Rarely', 'Occasionally', 'Regularly'];
    case ProfileSetupStep.smoking:
    case ProfileSetupStep.recreationalDrugs:
      return const <String>['Never', 'Occasionally', 'Regularly'];
    case ProfileSetupStep.pets:
      return const <String>[
        'No Pets, Doesn’t Want Any',
        'No Pets, Wants Pets',
        'No Pets, Open to Pets',
        'Has Pets, Doesn’t Want More',
        'Has Pets, Wants More',
        'Has Pets, Open to More',
      ];
    case ProfileSetupStep.children:
      return const <String>[
        'No Children, Doesn’t Want Any',
        'No Children, Wants Children',
        'No Children, Open to Children',
        'Has Children, Doesn’t Want More',
        'Has Children, Wants More',
        'Has Children, Open to More',
      ];
    case ProfileSetupStep.travelFrequency:
      return const <String>[
        'Rarely Travels',
        'Occasionally Travels',
        'Frequently Travels',
      ];
    case ProfileSetupStep.educationLevel:
      return const <String>[
        'High School',
        'Vocational / Trade School',
        'Associate Degree',
        'Bachelor’s Degree',
        'Master’s Degree',
        'Doctoral Degree',
        'Professional Degree',
        'Other',
      ];
    case ProfileSetupStep.currentEducation:
      return const <String>[
        'Not Currently Studying',
        'Undergraduate Student',
        'Graduate Student',
        'Doctoral Student',
        'Vocational / Trade Student',
        'Other Student',
      ];
    case ProfileSetupStep.employment:
      return const <String>[
        'Employed',
        'Self-Employed',
        'Entrepreneur',
        'Not Currently Working',
      ];
    default:
      return const <String>[];
  }
}

const List<String> _languages = <String>[
  'Arabic',
  'Chinese',
  'English',
  'Estonian',
  'Finnish',
  'French',
  'German',
  'Hindi',
  'Italian',
  'Japanese',
  'Korean',
  'Polish',
  'Portuguese',
  'Russian',
  'Spanish',
  'Swedish',
  'Ukrainian',
];

const List<String> _countries = <String>[
  'Australia',
  'Brazil',
  'Canada',
  'China',
  'Estonia',
  'Finland',
  'France',
  'Germany',
  'India',
  'Italy',
  'Japan',
  'Mexico',
  'Poland',
  'Spain',
  'Ukraine',
  'United Kingdom',
  'United States',
];

const List<String> _foodRestrictions = <String>[
  'No Restrictions',
  'Halal',
  'Kosher',
  'Gluten-Free',
  'Dairy-Free',
  'Nut-Free',
  'Low-Glycemic',
  'Other Restrictions',
];
