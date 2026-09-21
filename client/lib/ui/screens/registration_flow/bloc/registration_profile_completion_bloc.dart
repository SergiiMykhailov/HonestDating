import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';

sealed class RegistrationProfileCompletionEvent {
  const RegistrationProfileCompletionEvent();
}

class RegistrationProfileCompletionRefreshed
    extends RegistrationProfileCompletionEvent {
  const RegistrationProfileCompletionRefreshed();
}

class RegistrationProfileCompletionRequested
    extends RegistrationProfileCompletionEvent {
  const RegistrationProfileCompletionRequested();
}

class RegistrationProfileCompletionState {
  const RegistrationProfileCompletionState({
    required this.draft,
    this.isCompleting = false,
    this.isCompleted = false,
  });

  final ProfileSetupDraft draft;
  final bool isCompleting;
  final bool isCompleted;

  bool get canComplete => draft.isReadyForRegistrationCompletion;

  RegistrationProfileCompletionState copyWith({
    ProfileSetupDraft? draft,
    bool? isCompleting,
    bool? isCompleted,
  }) {
    return RegistrationProfileCompletionState(
      draft: draft ?? this.draft,
      isCompleting: isCompleting ?? this.isCompleting,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class RegistrationProfileCompletionBloc
    extends
        Bloc<
          RegistrationProfileCompletionEvent,
          RegistrationProfileCompletionState
        > {
  RegistrationProfileCompletionBloc({
    required BaseProfileSetupRepository repository,
  }) : _repository = repository,
       super(RegistrationProfileCompletionState(draft: repository.draft)) {
    on<RegistrationProfileCompletionRefreshed>(_onRefreshed);
    on<RegistrationProfileCompletionRequested>(_onCompletionRequested);
  }

  final BaseProfileSetupRepository _repository;

  void _onRefreshed(
    RegistrationProfileCompletionRefreshed event,
    Emitter<RegistrationProfileCompletionState> emit,
  ) {
    emit(state.copyWith(draft: _repository.draft));
  }

  Future<void> _onCompletionRequested(
    RegistrationProfileCompletionRequested event,
    Emitter<RegistrationProfileCompletionState> emit,
  ) async {
    if (!state.canComplete || state.isCompleting || state.isCompleted) {
      return;
    }
    emit(state.copyWith(isCompleting: true));
    await _repository.completeMobileRegistration();
    emit(state.copyWith(isCompleting: false, isCompleted: true));
  }
}
