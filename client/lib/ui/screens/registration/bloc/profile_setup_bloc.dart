import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';

enum ProfileSetupStep {
  firstName,
  lastName,
  verifiedDetails,
  gender,
  orientation,
  relationshipIntention,
  height,
  bodyType,
  hairColor,
  eyeColor,
  languages,
  countryOfOrigin,
  religion,
  religiosity,
  socialOrientation,
  goingOut,
  hosting,
  livingArrangement,
  livingEnvironment,
  diet,
  foodRestrictions,
  exercise,
  sleepSchedule,
  alcohol,
  smoking,
  recreationalDrugs,
  pets,
  children,
  travelFrequency,
  educationLevel,
  currentEducation,
  employment,
}

sealed class ProfileSetupEvent {
  const ProfileSetupEvent();
}

class ProfileSetupTextChanged extends ProfileSetupEvent {
  const ProfileSetupTextChanged(this.value);

  final String value;
}

class ProfileSetupContinueRequested extends ProfileSetupEvent {
  const ProfileSetupContinueRequested();
}

class ProfileSetupSingleChoiceSelected extends ProfileSetupEvent {
  const ProfileSetupSingleChoiceSelected(this.value);

  final String value;
}

class ProfileSetupMultiChoiceToggled extends ProfileSetupEvent {
  const ProfileSetupMultiChoiceToggled(this.value);

  final String value;
}

class ProfileSetupState {
  const ProfileSetupState({
    required this.draft,
    required this.step,
    this.nextStep,
    this.isCompleted = false,
  });

  final ProfileSetupDraft draft;
  final ProfileSetupStep step;
  final ProfileSetupStep? nextStep;
  final bool isCompleted;

  bool get requiresTextEntry =>
      step == ProfileSetupStep.firstName ||
      step == ProfileSetupStep.lastName ||
      step == ProfileSetupStep.height;

  bool get requiresMultipleChoices =>
      step == ProfileSetupStep.languages ||
      step == ProfileSetupStep.foodRestrictions;

  bool get isVerifiedDetails => step == ProfileSetupStep.verifiedDetails;

  bool get requiresContinue =>
      requiresTextEntry || requiresMultipleChoices || isVerifiedDetails;

  bool get canContinue {
    switch (step) {
      case ProfileSetupStep.firstName:
        return draft.firstName.trim().isNotEmpty;
      case ProfileSetupStep.lastName:
        return draft.lastName.trim().isNotEmpty;
      case ProfileSetupStep.verifiedDetails:
        return draft.dateOfBirth != null;
      case ProfileSetupStep.height:
        return draft.hasValidHeight;
      case ProfileSetupStep.languages:
        return draft.languages.isNotEmpty;
      case ProfileSetupStep.foodRestrictions:
        return draft.foodRestrictions.isNotEmpty;
      default:
        return false;
    }
  }

  ProfileSetupState withDraft(ProfileSetupDraft draft) {
    return ProfileSetupState(draft: draft, step: step);
  }

  ProfileSetupState withNextStep(ProfileSetupStep nextStep) {
    return ProfileSetupState(draft: draft, step: step, nextStep: nextStep);
  }

  ProfileSetupState completed() {
    return ProfileSetupState(draft: draft, step: step, isCompleted: true);
  }
}

class ProfileSetupBloc extends Bloc<ProfileSetupEvent, ProfileSetupState> {
  ProfileSetupBloc({
    required BaseProfileSetupRepository repository,
    required ProfileSetupStep step,
  }) : _repository = repository,
       super(ProfileSetupState(draft: repository.draft, step: step)) {
    on<ProfileSetupTextChanged>(_onTextChanged);
    on<ProfileSetupContinueRequested>(_onContinueRequested);
    on<ProfileSetupSingleChoiceSelected>(_onSingleChoiceSelected);
    on<ProfileSetupMultiChoiceToggled>(_onMultiChoiceToggled);
  }

  final BaseProfileSetupRepository _repository;

  Future<void> _onTextChanged(
    ProfileSetupTextChanged event,
    Emitter<ProfileSetupState> emit,
  ) async {
    final draft = switch (state.step) {
      ProfileSetupStep.firstName => state.draft.copyWith(
        firstName: event.value,
      ),
      ProfileSetupStep.lastName => state.draft.copyWith(lastName: event.value),
      ProfileSetupStep.height => state.draft.copyWith(
        heightCentimeters: event.value,
      ),
      _ => state.draft,
    };
    await _saveAndEmit(emit, draft);
  }

  Future<void> _onContinueRequested(
    ProfileSetupContinueRequested event,
    Emitter<ProfileSetupState> emit,
  ) async {
    if (!state.canContinue) {
      return;
    }
    await _advance(emit);
  }

  Future<void> _onSingleChoiceSelected(
    ProfileSetupSingleChoiceSelected event,
    Emitter<ProfileSetupState> emit,
  ) async {
    final draft = _draftWithSingleChoice(event.value);
    await _saveAndEmit(emit, draft);
    await _advance(emit);
  }

  Future<void> _onMultiChoiceToggled(
    ProfileSetupMultiChoiceToggled event,
    Emitter<ProfileSetupState> emit,
  ) async {
    final draft = switch (state.step) {
      ProfileSetupStep.languages => state.draft.copyWith(
        languages: _toggleLanguages(event.value),
      ),
      ProfileSetupStep.foodRestrictions => state.draft.copyWith(
        foodRestrictions: _toggleFoodRestriction(event.value),
      ),
      _ => state.draft,
    };
    await _saveAndEmit(emit, draft);
  }

  ProfileSetupDraft _draftWithSingleChoice(String value) {
    switch (state.step) {
      case ProfileSetupStep.gender:
        return state.draft.copyWith(gender: value);
      case ProfileSetupStep.orientation:
        return state.draft.copyWith(orientation: value);
      case ProfileSetupStep.relationshipIntention:
        return state.draft.copyWith(relationshipIntention: value);
      case ProfileSetupStep.bodyType:
        return state.draft.copyWith(bodyType: value);
      case ProfileSetupStep.hairColor:
        return state.draft.copyWith(hairColor: value);
      case ProfileSetupStep.eyeColor:
        return state.draft.copyWith(eyeColor: value);
      case ProfileSetupStep.countryOfOrigin:
        return state.draft.copyWith(countryOfOrigin: value);
      case ProfileSetupStep.religion:
        return state.draft.copyWith(
          religion: value,
          religiosity: value == 'No Religion' ? '' : state.draft.religiosity,
        );
      case ProfileSetupStep.religiosity:
        return state.draft.copyWith(religiosity: value);
      case ProfileSetupStep.socialOrientation:
        return state.draft.copyWith(socialOrientation: value);
      case ProfileSetupStep.goingOut:
        return state.draft.copyWith(goingOut: value);
      case ProfileSetupStep.hosting:
        return state.draft.copyWith(hosting: value);
      case ProfileSetupStep.livingArrangement:
        return state.draft.copyWith(livingArrangement: value);
      case ProfileSetupStep.livingEnvironment:
        return state.draft.copyWith(livingEnvironment: value);
      case ProfileSetupStep.diet:
        return state.draft.copyWith(diet: value);
      case ProfileSetupStep.exercise:
        return state.draft.copyWith(exercise: value);
      case ProfileSetupStep.sleepSchedule:
        return state.draft.copyWith(sleepSchedule: value);
      case ProfileSetupStep.alcohol:
        return state.draft.copyWith(alcohol: value);
      case ProfileSetupStep.smoking:
        return state.draft.copyWith(smoking: value);
      case ProfileSetupStep.recreationalDrugs:
        return state.draft.copyWith(recreationalDrugs: value);
      case ProfileSetupStep.pets:
        return state.draft.copyWith(pets: value);
      case ProfileSetupStep.children:
        return state.draft.copyWith(children: value);
      case ProfileSetupStep.travelFrequency:
        return state.draft.copyWith(travelFrequency: value);
      case ProfileSetupStep.educationLevel:
        return state.draft.copyWith(educationLevel: value);
      case ProfileSetupStep.currentEducation:
        return state.draft.copyWith(currentEducation: value);
      case ProfileSetupStep.employment:
        return state.draft.copyWith(employment: value);
      default:
        return state.draft;
    }
  }

  List<String> _toggleLanguages(String value) {
    final languages = state.draft.languages.toSet();
    if (!languages.add(value)) {
      languages.remove(value);
    } else if (languages.length > 3) {
      languages.remove(value);
    }
    return languages.toList()..sort();
  }

  List<String> _toggleFoodRestriction(String value) {
    const noRestrictions = 'No Restrictions';
    final restrictions = state.draft.foodRestrictions.toSet();
    if (!restrictions.add(value)) {
      restrictions.remove(value);
    } else if (value == noRestrictions) {
      restrictions
        ..clear()
        ..add(noRestrictions);
    } else {
      restrictions.remove(noRestrictions);
    }
    return restrictions.toList()..sort();
  }

  Future<void> _saveAndEmit(
    Emitter<ProfileSetupState> emit,
    ProfileSetupDraft draft,
  ) async {
    await _repository.saveDraft(draft);
    emit(state.withDraft(draft));
  }

  Future<void> _advance(Emitter<ProfileSetupState> emit) async {
    final nextIndex =
        state.step == ProfileSetupStep.religion &&
            state.draft.religion == 'No Religion'
        ? ProfileSetupStep.socialOrientation.index
        : state.step.index + 1;
    if (nextIndex >= ProfileSetupStep.values.length) {
      await _repository.saveDraft(state.draft);
      emit(state.completed());
      return;
    }
    emit(state.withNextStep(ProfileSetupStep.values[nextIndex]));
  }
}
