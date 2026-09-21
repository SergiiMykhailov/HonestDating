import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';

sealed class InterestCatalogEvent {
  const InterestCatalogEvent();
}

class InterestCatalogReloaded extends InterestCatalogEvent {
  const InterestCatalogReloaded();
}

class InterestCatalogQueryChanged extends InterestCatalogEvent {
  const InterestCatalogQueryChanged(this.value);

  final String value;
}

class InterestCatalogInterestToggled extends InterestCatalogEvent {
  const InterestCatalogInterestToggled(this.interest);

  final String interest;
}

class InterestCatalogInterestRemoved extends InterestCatalogEvent {
  const InterestCatalogInterestRemoved(this.interest);

  final String interest;
}

class InterestCatalogState {
  const InterestCatalogState({required this.draft, this.query = ''});

  final ProfileSetupDraft draft;
  final String query;

  InterestCatalogState copyWith({ProfileSetupDraft? draft, String? query}) {
    return InterestCatalogState(
      draft: draft ?? this.draft,
      query: query ?? this.query,
    );
  }
}

class InterestCatalogBloc
    extends Bloc<InterestCatalogEvent, InterestCatalogState> {
  InterestCatalogBloc({required BaseProfileSetupRepository repository})
    : _repository = repository,
      super(InterestCatalogState(draft: repository.draft)) {
    on<InterestCatalogReloaded>(_onReloaded);
    on<InterestCatalogQueryChanged>(_onQueryChanged);
    on<InterestCatalogInterestToggled>(_onInterestToggled);
    on<InterestCatalogInterestRemoved>(_onInterestRemoved);
  }

  final BaseProfileSetupRepository _repository;

  void _onReloaded(
    InterestCatalogReloaded event,
    Emitter<InterestCatalogState> emit,
  ) {
    emit(state.copyWith(draft: _repository.draft));
  }

  void _onQueryChanged(
    InterestCatalogQueryChanged event,
    Emitter<InterestCatalogState> emit,
  ) {
    emit(state.copyWith(query: event.value));
  }

  Future<void> _onInterestToggled(
    InterestCatalogInterestToggled event,
    Emitter<InterestCatalogState> emit,
  ) async {
    final interests = List<String>.from(state.draft.interests);
    if (interests.contains(event.interest)) {
      interests.remove(event.interest);
    } else {
      interests.add(event.interest);
    }
    final draft = state.draft.copyWith(interests: interests);
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }

  Future<void> _onInterestRemoved(
    InterestCatalogInterestRemoved event,
    Emitter<InterestCatalogState> emit,
  ) async {
    final draft = state.draft.copyWith(
      interests: state.draft.interests
          .where((String interest) => interest != event.interest)
          .toList(),
    );
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }
}
