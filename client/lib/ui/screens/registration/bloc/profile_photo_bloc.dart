import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/profile_photo_verification.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_photo_verification_repository.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';

sealed class ProfilePhotoEvent {
  const ProfilePhotoEvent();
}

class ProfileMainPhotoRequested extends ProfilePhotoEvent {
  const ProfileMainPhotoRequested();
}

class ProfileGalleryPhotosRequested extends ProfilePhotoEvent {
  const ProfileGalleryPhotosRequested();
}

class ProfileGalleryPhotoRemoved extends ProfilePhotoEvent {
  const ProfileGalleryPhotoRemoved(this.path);

  final String path;
}

class ProfilePhotoContinueRequested extends ProfilePhotoEvent {
  const ProfilePhotoContinueRequested();
}

class ProfilePhotoState {
  const ProfilePhotoState({
    required this.draft,
    this.isPicking = false,
    this.isUploading = false,
    this.navigationRequest = 0,
    this.verificationSession,
    this.errorMessage,
  });

  final ProfileSetupDraft draft;
  final bool isPicking;
  final bool isUploading;
  final int navigationRequest;
  final ProfilePhotoVerificationSession? verificationSession;
  final String? errorMessage;

  bool get canContinue =>
      draft.mainPhotoPath != null && !isPicking && !isUploading;

  bool get isBusy => isPicking || isUploading;

  ProfilePhotoState copyWith({
    ProfileSetupDraft? draft,
    bool? isPicking,
    bool? isUploading,
    int? navigationRequest,
    ProfilePhotoVerificationSession? verificationSession,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfilePhotoState(
      draft: draft ?? this.draft,
      isPicking: isPicking ?? this.isPicking,
      isUploading: isUploading ?? this.isUploading,
      navigationRequest: navigationRequest ?? this.navigationRequest,
      verificationSession: verificationSession ?? this.verificationSession,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ProfilePhotoBloc extends Bloc<ProfilePhotoEvent, ProfilePhotoState> {
  ProfilePhotoBloc({
    required BaseProfileSetupRepository repository,
    required BaseProfilePhotoVerificationRepository verificationRepository,
  }) : _repository = repository,
       _verificationRepository = verificationRepository,
       super(ProfilePhotoState(draft: repository.draft)) {
    on<ProfileMainPhotoRequested>(_onMainPhotoRequested);
    on<ProfileGalleryPhotosRequested>(_onGalleryPhotosRequested);
    on<ProfileGalleryPhotoRemoved>(_onGalleryPhotoRemoved);
    on<ProfilePhotoContinueRequested>(_onContinueRequested);
  }

  final BaseProfileSetupRepository _repository;
  final BaseProfilePhotoVerificationRepository _verificationRepository;

  Future<void> _onMainPhotoRequested(
    ProfileMainPhotoRequested event,
    Emitter<ProfilePhotoState> emit,
  ) async {
    emit(state.copyWith(isPicking: true, clearError: true));
    try {
      final path = await _repository.selectMainPhoto();
      if (path == null) {
        emit(state.copyWith(isPicking: false));
        return;
      }
      final draft = state.draft.copyWith(
        mainPhotoPath: path,
        galleryPhotoPaths: state.draft.galleryPhotoPaths
            .where((String galleryPath) => galleryPath != path)
            .toList(),
      );
      await _repository.saveDraft(draft);
      emit(state.copyWith(draft: draft, isPicking: false));
    } catch (_) {
      emit(
        state.copyWith(
          isPicking: false,
          errorMessage:
              'We could not open your photo library. Please try again.',
        ),
      );
    }
  }

  Future<void> _onGalleryPhotosRequested(
    ProfileGalleryPhotosRequested event,
    Emitter<ProfilePhotoState> emit,
  ) async {
    emit(state.copyWith(isPicking: true, clearError: true));
    try {
      final selectedPaths = await _repository.selectGalleryPhotos();
      final galleryPaths = <String>{
        ...state.draft.galleryPhotoPaths,
        ...selectedPaths,
      }..remove(state.draft.mainPhotoPath);
      final draft = state.draft.copyWith(
        galleryPhotoPaths: galleryPaths.toList(),
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

  Future<void> _onGalleryPhotoRemoved(
    ProfileGalleryPhotoRemoved event,
    Emitter<ProfilePhotoState> emit,
  ) async {
    final draft = state.draft.copyWith(
      galleryPhotoPaths: state.draft.galleryPhotoPaths
          .where((String path) => path != event.path)
          .toList(),
    );
    await _repository.saveDraft(draft);
    emit(state.copyWith(draft: draft));
  }

  Future<void> _onContinueRequested(
    ProfilePhotoContinueRequested event,
    Emitter<ProfilePhotoState> emit,
  ) async {
    final mainPhotoPath = state.draft.mainPhotoPath;
    if (mainPhotoPath == null || state.isBusy) {
      return;
    }

    emit(state.copyWith(isUploading: true, clearError: true));
    try {
      final session = await _verificationRepository.uploadAndStartVerification(
        mainPhotoPath: mainPhotoPath,
        galleryPhotoPaths: state.draft.galleryPhotoPaths,
      );
      emit(
        state.copyWith(
          isUploading: false,
          verificationSession: session,
          navigationRequest: state.navigationRequest + 1,
        ),
      );
    } on ProfilePhotoVerificationException catch (error) {
      emit(state.copyWith(isUploading: false, errorMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          isUploading: false,
          errorMessage: 'We could not upload your photos. Please try again.',
        ),
      );
    }
  }
}
