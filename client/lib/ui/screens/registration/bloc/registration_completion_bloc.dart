import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';

enum RegistrationCompletionStage { aboutMe, interests, review }

sealed class RegistrationCompletionEvent {
  const RegistrationCompletionEvent();
}

class AboutMeChanged extends RegistrationCompletionEvent {
  const AboutMeChanged(this.value);

  final String value;
}

class AboutMeContinueRequested extends RegistrationCompletionEvent {
  const AboutMeContinueRequested();
}

class InterestsSubmitted extends RegistrationCompletionEvent {
  const InterestsSubmitted(this.value);

  final String value;
}

class InterestRemoved extends RegistrationCompletionEvent {
  const InterestRemoved(this.value);

  final String value;
}

class InterestsContinueRequested extends RegistrationCompletionEvent {
  const InterestsContinueRequested();
}

class RegistrationFinishRequested extends RegistrationCompletionEvent {
  const RegistrationFinishRequested();
}

class RegistrationCompletionState {
  const RegistrationCompletionState({
    required this.draft,
    required this.stage,
    this.navigationRequest = 0,
    this.isCompleted = false,
  });

  final ProfileSetupDraft draft;
  final RegistrationCompletionStage stage;
  final int navigationRequest;
  final bool isCompleted;

  bool get canContinue {
    switch (stage) {
      case RegistrationCompletionStage.aboutMe:
        return draft.aboutMe.trim().isNotEmpty;
      case RegistrationCompletionStage.interests:
        return draft.interests.isNotEmpty;
      case RegistrationCompletionStage.review:
        return draft.isReadyForMobileCompletion;
    }
  }

  RegistrationCompletionState copyWith({
    ProfileSetupDraft? draft,
    int? navigationRequest,
    bool? isCompleted,
  }) {
    return RegistrationCompletionState(
      draft: draft ?? this.draft,
      stage: stage,
      navigationRequest: navigationRequest ?? this.navigationRequest,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class RegistrationCompletionBloc
    extends Bloc<RegistrationCompletionEvent, RegistrationCompletionState> {
  RegistrationCompletionBloc({
    required BaseProfileSetupRepository repository,
    required RegistrationCompletionStage stage,
  }) : _repository = repository,
       super(
         RegistrationCompletionState(
           draft: _withNormalizedInterests(repository.draft),
           stage: stage,
         ),
       ) {
    on<AboutMeChanged>(_onAboutMeChanged);
    on<AboutMeContinueRequested>(_onAboutMeContinueRequested);
    on<InterestsSubmitted>(_onInterestsSubmitted);
    on<InterestRemoved>(_onInterestRemoved);
    on<InterestsContinueRequested>(_onInterestsContinueRequested);
    on<RegistrationFinishRequested>(_onRegistrationFinishRequested);
  }

  final BaseProfileSetupRepository _repository;

  Future<void> _onAboutMeChanged(
    AboutMeChanged event,
    Emitter<RegistrationCompletionState> emit,
  ) async {
    final draft = state.draft.copyWith(aboutMe: event.value);
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }

  void _onAboutMeContinueRequested(
    AboutMeContinueRequested event,
    Emitter<RegistrationCompletionState> emit,
  ) {
    if (state.stage == RegistrationCompletionStage.aboutMe &&
        state.canContinue) {
      emit(state.copyWith(navigationRequest: state.navigationRequest + 1));
    }
  }

  Future<void> _onInterestsSubmitted(
    InterestsSubmitted event,
    Emitter<RegistrationCompletionState> emit,
  ) async {
    final interests = _normalizedInterests([
      ...state.draft.interests,
      event.value,
    ]);
    final draft = state.draft.copyWith(interests: interests);
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }

  Future<void> _onInterestRemoved(
    InterestRemoved event,
    Emitter<RegistrationCompletionState> emit,
  ) async {
    final draft = state.draft.copyWith(
      interests: state.draft.interests
          .where((String interest) => interest != event.value)
          .toList(),
    );
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }

  void _onInterestsContinueRequested(
    InterestsContinueRequested event,
    Emitter<RegistrationCompletionState> emit,
  ) {
    if (state.stage == RegistrationCompletionStage.interests &&
        state.canContinue) {
      emit(state.copyWith(navigationRequest: state.navigationRequest + 1));
    }
  }

  Future<void> _onRegistrationFinishRequested(
    RegistrationFinishRequested event,
    Emitter<RegistrationCompletionState> emit,
  ) async {
    if (state.stage != RegistrationCompletionStage.review ||
        !state.canContinue) {
      return;
    }
    await _repository.completeMobileRegistration();
    emit(state.copyWith(isCompleted: true));
  }

  static ProfileSetupDraft _withNormalizedInterests(ProfileSetupDraft draft) {
    return draft.copyWith(interests: _normalizedInterests(draft.interests));
  }

  static List<String> _normalizedInterests(Iterable<String> values) {
    final interests = <String>[];
    for (final sourceValue in values) {
      for (final rawValue in sourceValue.split(RegExp(r'[;,]'))) {
        final value = rawValue.trim();
        final alreadyIncluded = interests.any(
          (String existing) => existing.toLowerCase() == value.toLowerCase(),
        );
        if (value.isNotEmpty && !alreadyIncluded) {
          interests.add(value);
        }
      }
    }
    return interests;
  }
}
