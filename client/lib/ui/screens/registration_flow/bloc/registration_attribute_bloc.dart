import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/screens/registration_flow/registration_attribute.dart';

enum RegistrationAttributeDestination {
  nextAttribute,
  friendshipOnlyConfirmation,
  religiosity,
  registrationInterests,
}

sealed class RegistrationAttributeEvent {
  const RegistrationAttributeEvent();
}

class RegistrationAttributeOptionSelected extends RegistrationAttributeEvent {
  const RegistrationAttributeOptionSelected(this.value);

  final String value;
}

class RegistrationAttributeLanguageToggled extends RegistrationAttributeEvent {
  const RegistrationAttributeLanguageToggled(this.value);

  final String value;
}

class RegistrationAttributeHeightUnitChanged
    extends RegistrationAttributeEvent {
  const RegistrationAttributeHeightUnitChanged(this.unit);

  final HeightUnit unit;
}

class RegistrationAttributeHeightChanged extends RegistrationAttributeEvent {
  const RegistrationAttributeHeightChanged({
    this.centimeters,
    this.imperialHeight,
  });

  final String? centimeters;
  final String? imperialHeight;
}

class RegistrationAttributeContinueRequested
    extends RegistrationAttributeEvent {
  const RegistrationAttributeContinueRequested();
}

class RegistrationAttributeState {
  const RegistrationAttributeState({
    required this.step,
    required this.draft,
    this.destination,
    this.navigationRequest = 0,
  });

  final RegistrationAttributeStep step;
  final ProfileSetupDraft draft;
  final RegistrationAttributeDestination? destination;
  final int navigationRequest;

  bool get canContinue {
    if (step == RegistrationAttributeStep.languagesSpoken) {
      return draft.languages.isNotEmpty;
    }
    if (step == RegistrationAttributeStep.height) {
      return draft.hasValidRegistrationHeight;
    }
    return false;
  }

  RegistrationAttributeState copyWith({
    ProfileSetupDraft? draft,
    RegistrationAttributeDestination? destination,
    int? navigationRequest,
    bool clearDestination = false,
  }) {
    return RegistrationAttributeState(
      step: step,
      draft: draft ?? this.draft,
      destination: clearDestination ? null : destination ?? this.destination,
      navigationRequest: navigationRequest ?? this.navigationRequest,
    );
  }
}

class RegistrationAttributeBloc
    extends Bloc<RegistrationAttributeEvent, RegistrationAttributeState> {
  RegistrationAttributeBloc({
    required BaseProfileSetupRepository repository,
    required RegistrationAttributeStep step,
  }) : _repository = repository,
       super(RegistrationAttributeState(step: step, draft: repository.draft)) {
    on<RegistrationAttributeOptionSelected>(_onOptionSelected);
    on<RegistrationAttributeLanguageToggled>(_onLanguageToggled);
    on<RegistrationAttributeHeightUnitChanged>(_onHeightUnitChanged);
    on<RegistrationAttributeHeightChanged>(_onHeightChanged);
    on<RegistrationAttributeContinueRequested>(_onContinueRequested);
  }

  final BaseProfileSetupRepository _repository;

  Future<void> _onOptionSelected(
    RegistrationAttributeOptionSelected event,
    Emitter<RegistrationAttributeState> emit,
  ) async {
    if (state.step.allowsMultipleChoices ||
        state.step == RegistrationAttributeStep.height) {
      return;
    }

    final draft = _draftWithValue(event.value);
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft, clearDestination: true));
    _navigateAfterValue(emit, event.value);
  }

  Future<void> _onLanguageToggled(
    RegistrationAttributeLanguageToggled event,
    Emitter<RegistrationAttributeState> emit,
  ) async {
    if (state.step != RegistrationAttributeStep.languagesSpoken) {
      return;
    }
    final languages = state.draft.languages.toSet();
    if (!languages.add(event.value)) {
      languages.remove(event.value);
    } else if (languages.length > 5) {
      languages.remove(event.value);
    }
    final draft = state.draft.copyWith(languages: languages.toList()..sort());
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft, clearDestination: true));
  }

  Future<void> _onHeightUnitChanged(
    RegistrationAttributeHeightUnitChanged event,
    Emitter<RegistrationAttributeState> emit,
  ) async {
    if (state.step != RegistrationAttributeStep.height) {
      return;
    }
    final draft = state.draft.copyWith(heightUnit: event.unit);
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft, clearDestination: true));
  }

  Future<void> _onHeightChanged(
    RegistrationAttributeHeightChanged event,
    Emitter<RegistrationAttributeState> emit,
  ) async {
    if (state.step != RegistrationAttributeStep.height) {
      return;
    }
    final imperialHeight = event.imperialHeight == null
        ? null
        : _parseImperialHeight(event.imperialHeight!);
    final draft = state.draft.copyWith(
      heightCentimeters: event.centimeters,
      heightFeet: imperialHeight?.feet ?? '',
      heightInches: imperialHeight?.inches ?? '',
    );
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft, clearDestination: true));
  }

  Future<void> _onContinueRequested(
    RegistrationAttributeContinueRequested event,
    Emitter<RegistrationAttributeState> emit,
  ) async {
    if (!state.canContinue) {
      return;
    }
    final draft = state.step == RegistrationAttributeStep.height
        ? state.draft.copyWith(
            heightCentimeters: state.draft.normalizedHeightCentimeters,
          )
        : state.draft;
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft, clearDestination: true));
    _navigateToNext(emit);
  }

  ProfileSetupDraft _draftWithValue(String value) {
    switch (state.step) {
      case RegistrationAttributeStep.sexualOrientation:
        return state.draft.copyWith(orientation: value);
      case RegistrationAttributeStep.datingIntention:
        return state.draft.copyWith(relationshipIntention: value);
      case RegistrationAttributeStep.bodyType:
        return state.draft.copyWith(bodyType: value);
      case RegistrationAttributeStep.countryOfOrigin:
        return state.draft.copyWith(countryOfOrigin: value);
      case RegistrationAttributeStep.religion:
        return state.draft.copyWith(
          religion: value,
          religiosity: value == 'No Religion' ? '' : state.draft.religiosity,
        );
      case RegistrationAttributeStep.socialOrientation:
        return state.draft.copyWith(socialOrientation: value);
      case RegistrationAttributeStep.goingOut:
        return state.draft.copyWith(goingOut: value);
      case RegistrationAttributeStep.livingArrangement:
        return state.draft.copyWith(livingArrangement: value);
      case RegistrationAttributeStep.diet:
        return state.draft.copyWith(diet: value);
      case RegistrationAttributeStep.exercise:
        return state.draft.copyWith(exercise: value);
      case RegistrationAttributeStep.alcohol:
        return state.draft.copyWith(alcohol: value);
      case RegistrationAttributeStep.smoking:
        return state.draft.copyWith(smoking: value);
      case RegistrationAttributeStep.recreationalDrugs:
        return state.draft.copyWith(recreationalDrugs: value);
      case RegistrationAttributeStep.pets:
        return state.draft.copyWith(pets: value);
      case RegistrationAttributeStep.children:
        return state.draft.copyWith(children: value);
      case RegistrationAttributeStep.educationLevel:
        return state.draft.copyWith(educationLevel: value);
      case RegistrationAttributeStep.currentStudy:
        return state.draft.copyWith(currentEducation: value);
      case RegistrationAttributeStep.workStatus:
        return state.draft.copyWith(employment: value);
      case RegistrationAttributeStep.politicalViews:
        return state.draft.copyWith(politicalViews: value);
      case RegistrationAttributeStep.height:
      case RegistrationAttributeStep.languagesSpoken:
        return state.draft;
    }
  }

  void _navigateAfterValue(
    Emitter<RegistrationAttributeState> emit,
    String value,
  ) {
    if (state.step == RegistrationAttributeStep.datingIntention &&
        value == 'Not Dating — Friendship Only') {
      _emitNavigation(
        emit,
        RegistrationAttributeDestination.friendshipOnlyConfirmation,
      );
      return;
    }
    _navigateToNext(emit);
  }

  void _navigateToNext(Emitter<RegistrationAttributeState> emit) {
    _emitNavigation(
      emit,
      state.step.next == null
          ? RegistrationAttributeDestination.registrationInterests
          : RegistrationAttributeDestination.nextAttribute,
    );
  }

  void _emitNavigation(
    Emitter<RegistrationAttributeState> emit,
    RegistrationAttributeDestination destination,
  ) {
    emit(
      state.copyWith(
        destination: destination,
        navigationRequest: state.navigationRequest + 1,
      ),
    );
  }
}

class _ImperialHeight {
  const _ImperialHeight({required this.feet, required this.inches});

  final String feet;
  final String inches;
}

_ImperialHeight? _parseImperialHeight(String input) {
  final match = RegExp(
    r'''^\s*(\d{1,2})\s*'\s*(\d{1,2})\s*"?\s*$''',
  ).firstMatch(input);
  if (match == null) {
    return null;
  }
  return _ImperialHeight(feet: match.group(1)!, inches: match.group(2)!);
}
