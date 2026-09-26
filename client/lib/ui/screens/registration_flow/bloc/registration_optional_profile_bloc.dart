import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';

const int _registrationGalleryPhotoLimit = 2;

sealed class RegistrationInterestsEvent {
  const RegistrationInterestsEvent();
}

class RegistrationInterestsQueryChanged extends RegistrationInterestsEvent {
  const RegistrationInterestsQueryChanged(this.query);

  final String query;
}

class RegistrationInterestToggled extends RegistrationInterestsEvent {
  const RegistrationInterestToggled(this.interest);

  final String interest;
}

class RegistrationInterestsContinueRequested
    extends RegistrationInterestsEvent {
  const RegistrationInterestsContinueRequested();
}

class RegistrationInterestsState {
  const RegistrationInterestsState({
    required this.draft,
    this.query = '',
    this.navigationRequest = 0,
  });

  final ProfileSetupDraft draft;
  final String query;
  final int navigationRequest;

  RegistrationInterestsState copyWith({
    ProfileSetupDraft? draft,
    String? query,
    int? navigationRequest,
  }) {
    return RegistrationInterestsState(
      draft: draft ?? this.draft,
      query: query ?? this.query,
      navigationRequest: navigationRequest ?? this.navigationRequest,
    );
  }
}

class RegistrationInterestsBloc
    extends Bloc<RegistrationInterestsEvent, RegistrationInterestsState> {
  RegistrationInterestsBloc({required BaseProfileSetupRepository repository})
    : _repository = repository,
      super(RegistrationInterestsState(draft: repository.draft)) {
    on<RegistrationInterestsQueryChanged>(_onQueryChanged);
    on<RegistrationInterestToggled>(_onInterestToggled);
    on<RegistrationInterestsContinueRequested>(_onContinueRequested);
  }

  final BaseProfileSetupRepository _repository;

  void _onQueryChanged(
    RegistrationInterestsQueryChanged event,
    Emitter<RegistrationInterestsState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onInterestToggled(
    RegistrationInterestToggled event,
    Emitter<RegistrationInterestsState> emit,
  ) async {
    final interests = List<String>.from(state.draft.interests);
    if (!interests.remove(event.interest)) {
      interests.add(event.interest);
    }
    final draft = state.draft.copyWith(interests: interests);
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }

  void _onContinueRequested(
    RegistrationInterestsContinueRequested event,
    Emitter<RegistrationInterestsState> emit,
  ) {
    emit(state.copyWith(navigationRequest: state.navigationRequest + 1));
  }
}

sealed class RegistrationGalleryPhotosEvent {
  const RegistrationGalleryPhotosEvent();
}

class RegistrationGalleryPhotosRequested
    extends RegistrationGalleryPhotosEvent {
  const RegistrationGalleryPhotosRequested();
}

class RegistrationGalleryPhotoRemoved extends RegistrationGalleryPhotosEvent {
  const RegistrationGalleryPhotoRemoved(this.path);

  final String path;
}

class RegistrationGalleryPhotosContinueRequested
    extends RegistrationGalleryPhotosEvent {
  const RegistrationGalleryPhotosContinueRequested();
}

class RegistrationGalleryPhotosState {
  const RegistrationGalleryPhotosState({
    required this.draft,
    this.isPicking = false,
    this.errorMessage,
    this.navigationRequest = 0,
  });

  final ProfileSetupDraft draft;
  final bool isPicking;
  final String? errorMessage;
  final int navigationRequest;

  RegistrationGalleryPhotosState copyWith({
    ProfileSetupDraft? draft,
    bool? isPicking,
    String? errorMessage,
    bool clearError = false,
    int? navigationRequest,
  }) {
    return RegistrationGalleryPhotosState(
      draft: draft ?? this.draft,
      isPicking: isPicking ?? this.isPicking,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      navigationRequest: navigationRequest ?? this.navigationRequest,
    );
  }
}

class RegistrationGalleryPhotosBloc
    extends
        Bloc<RegistrationGalleryPhotosEvent, RegistrationGalleryPhotosState> {
  RegistrationGalleryPhotosBloc({
    required BaseProfileSetupRepository repository,
  }) : _repository = repository,
       super(RegistrationGalleryPhotosState(draft: repository.draft)) {
    on<RegistrationGalleryPhotosRequested>(_onPhotosRequested);
    on<RegistrationGalleryPhotoRemoved>(_onPhotoRemoved);
    on<RegistrationGalleryPhotosContinueRequested>(_onContinueRequested);
  }

  final BaseProfileSetupRepository _repository;

  Future<void> _onPhotosRequested(
    RegistrationGalleryPhotosRequested event,
    Emitter<RegistrationGalleryPhotosState> emit,
  ) async {
    if (state.isPicking ||
        state.draft.galleryPhotoPaths.length >=
            _registrationGalleryPhotoLimit) {
      return;
    }
    emit(state.copyWith(isPicking: true, clearError: true));
    try {
      final selected = await _repository.selectGalleryPhotos();
      final paths = <String>{
        ...state.draft.galleryPhotoPaths.take(_registrationGalleryPhotoLimit),
        ...selected,
      }..remove(state.draft.mainPhotoPath);
      final draft = state.draft.copyWith(
        galleryPhotoPaths: paths.take(_registrationGalleryPhotoLimit).toList(),
      );
      await _repository.saveDraft(draft);
      emit(state.copyWith(draft: draft, isPicking: false));
    } catch (_) {
      emit(
        state.copyWith(
          isPicking: false,
          errorMessage: 'We could not add those photos. Please try again.',
        ),
      );
    }
  }

  Future<void> _onPhotoRemoved(
    RegistrationGalleryPhotoRemoved event,
    Emitter<RegistrationGalleryPhotosState> emit,
  ) async {
    final draft = state.draft.copyWith(
      galleryPhotoPaths: state.draft.galleryPhotoPaths
          .where((String path) => path != event.path)
          .toList(),
    );
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }

  void _onContinueRequested(
    RegistrationGalleryPhotosContinueRequested event,
    Emitter<RegistrationGalleryPhotosState> emit,
  ) {
    if (state.isPicking) {
      return;
    }
    emit(state.copyWith(navigationRequest: state.navigationRequest + 1));
  }
}
