import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/profile_photo_verification.dart';
import 'package:honest_dating/repositories/base/base_profile_photo_verification_repository.dart';

sealed class ProfilePhotoValidationEvent {
  const ProfilePhotoValidationEvent();
}

class ProfilePhotoValidationStarted extends ProfilePhotoValidationEvent {
  const ProfilePhotoValidationStarted();
}

class ProfilePhotoValidationRetryRequested extends ProfilePhotoValidationEvent {
  const ProfilePhotoValidationRetryRequested();
}

class _ProfilePhotoValidationPollRequested extends ProfilePhotoValidationEvent {
  const _ProfilePhotoValidationPollRequested();
}

class ProfilePhotoValidationState {
  const ProfilePhotoValidationState({
    required this.status,
    this.isChecking = false,
    this.errorMessage,
    this.navigationRequest = 0,
  });

  final ProfilePhotoVerificationStatus status;
  final bool isChecking;
  final String? errorMessage;
  final int navigationRequest;

  ProfilePhotoValidationState copyWith({
    ProfilePhotoVerificationStatus? status,
    bool? isChecking,
    String? errorMessage,
    bool clearError = false,
    int? navigationRequest,
  }) {
    return ProfilePhotoValidationState(
      status: status ?? this.status,
      isChecking: isChecking ?? this.isChecking,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      navigationRequest: navigationRequest ?? this.navigationRequest,
    );
  }
}

class ProfilePhotoValidationBloc
    extends Bloc<ProfilePhotoValidationEvent, ProfilePhotoValidationState> {
  ProfilePhotoValidationBloc({
    required BaseProfilePhotoVerificationRepository repository,
    required ProfilePhotoVerificationSession session,
  }) : _repository = repository,
       _session = session,
       super(ProfilePhotoValidationState(status: session.status)) {
    on<ProfilePhotoValidationStarted>(_onStarted);
    on<ProfilePhotoValidationRetryRequested>(_onRetryRequested);
    on<_ProfilePhotoValidationPollRequested>(_onPollRequested);
  }

  final BaseProfilePhotoVerificationRepository _repository;
  final ProfilePhotoVerificationSession _session;
  Timer? _pollTimer;
  bool _requestInFlight = false;

  Future<void> _onStarted(
    ProfilePhotoValidationStarted event,
    Emitter<ProfilePhotoValidationState> emit,
  ) async {
    await _poll(emit);
    _schedulePolling();
  }

  Future<void> _onRetryRequested(
    ProfilePhotoValidationRetryRequested event,
    Emitter<ProfilePhotoValidationState> emit,
  ) async {
    await _poll(emit);
    _schedulePolling();
  }

  Future<void> _onPollRequested(
    _ProfilePhotoValidationPollRequested event,
    Emitter<ProfilePhotoValidationState> emit,
  ) async {
    await _poll(emit);
  }

  Future<void> _poll(Emitter<ProfilePhotoValidationState> emit) async {
    if (_requestInFlight ||
        state.status == ProfilePhotoVerificationStatus.approved ||
        state.status == ProfilePhotoVerificationStatus.rejected) {
      return;
    }
    _requestInFlight = true;
    emit(state.copyWith(isChecking: true, clearError: true));
    try {
      final status = await _repository.getVerificationStatus(
        _session.verificationToken,
      );
      final shouldNavigate = status == ProfilePhotoVerificationStatus.approved;
      emit(
        state.copyWith(
          status: status,
          isChecking: false,
          navigationRequest: shouldNavigate
              ? state.navigationRequest + 1
              : state.navigationRequest,
        ),
      );
      if (status == ProfilePhotoVerificationStatus.approved ||
          status == ProfilePhotoVerificationStatus.rejected ||
          status == ProfilePhotoVerificationStatus.unavailable) {
        _stopPolling();
      }
    } on ProfilePhotoVerificationException catch (error) {
      emit(
        state.copyWith(
          status: ProfilePhotoVerificationStatus.unavailable,
          isChecking: false,
          errorMessage: error.message,
        ),
      );
      _stopPolling();
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfilePhotoVerificationStatus.unavailable,
          isChecking: false,
          errorMessage: 'We could not check your photo yet. Please try again.',
        ),
      );
      _stopPolling();
    } finally {
      _requestInFlight = false;
    }
  }

  void _schedulePolling() {
    if (state.status != ProfilePhotoVerificationStatus.pending ||
        _pollTimer != null) {
      return;
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      add(const _ProfilePhotoValidationPollRequested());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
