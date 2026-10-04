import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discovery_profile_event.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discovery_profile_state.dart';

class DiscoveryProfileBloc
    extends Bloc<DiscoveryProfileEvent, DiscoveryProfileState> {
  DiscoveryProfileBloc({
    required BaseDiscoveryRepository repository,
    required DiscoveryProfile initialProfile,
  }) : _repository = repository,
       super(DiscoveryProfileState(profile: initialProfile)) {
    on<DiscoveryProfileRefreshRequested>(_onRefreshRequested);
    on<DiscoveryProfileLikeSubmitted>(_onLikeSubmitted);
    on<DiscoveryProfileFriendshipOfferSubmitted>(_onFriendshipOfferSubmitted);
    on<DiscoveryProfileFriendshipOfferAccepted>(_onFriendshipOfferAccepted);
    on<DiscoveryProfileFeedbackDismissed>(_onFeedbackDismissed);
  }

  final BaseDiscoveryRepository _repository;

  Future<void> _onRefreshRequested(
    DiscoveryProfileRefreshRequested event,
    Emitter<DiscoveryProfileState> emit,
  ) async {
    try {
      final profile = await _repository.loadProfile(state.profile.id);
      emit(state.copyWith(profile: profile));
    } catch (_) {
      // Keep the last Firebase snapshot visible if a refresh cannot complete.
    }
  }

  Future<void> _onLikeSubmitted(
    DiscoveryProfileLikeSubmitted event,
    Emitter<DiscoveryProfileState> emit,
  ) async {
    await _runAction(
      emit,
      () => _repository.sendLike(
        profileId: state.profile.id,
        reason: event.reason,
      ),
      successMessage: (DiscoveryProfile profile) {
        return profile.relationship.romantic == DiscoveryRomanticState.matched
            ? 'It’s a match. Your reasons are now part of your shared connection.'
            : 'Like sent. Your reason stays private unless the Like becomes mutual.';
      },
    );
  }

  Future<void> _onFriendshipOfferSubmitted(
    DiscoveryProfileFriendshipOfferSubmitted event,
    Emitter<DiscoveryProfileState> emit,
  ) async {
    await _runAction(
      emit,
      () => _repository.sendFriendshipOffer(
        profileId: state.profile.id,
        reason: event.reason,
      ),
      successMessage: (_) =>
          'Friendship offer sent. Your reason is visible to them immediately.',
    );
  }

  Future<void> _onFriendshipOfferAccepted(
    DiscoveryProfileFriendshipOfferAccepted event,
    Emitter<DiscoveryProfileState> emit,
  ) async {
    await _runAction(
      emit,
      () => _repository.acceptFriendshipOffer(state.profile.id),
      successMessage: (_) => 'You are now friends.',
    );
  }

  void _onFeedbackDismissed(
    DiscoveryProfileFeedbackDismissed event,
    Emitter<DiscoveryProfileState> emit,
  ) {
    emit(state.copyWith(clearFeedback: true));
  }

  Future<void> _runAction(
    Emitter<DiscoveryProfileState> emit,
    Future<DiscoveryProfile> Function() action, {
    required String Function(DiscoveryProfile profile) successMessage,
  }) async {
    if (state.isSubmitting) {
      return;
    }
    emit(state.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      final profile = await action();
      emit(
        state.copyWith(
          profile: profile,
          isSubmitting: false,
          feedbackMessage: successMessage(profile),
          feedbackIsError: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          feedbackMessage: _messageFor(error),
          feedbackIsError: true,
        ),
      );
    }
  }

  String _messageFor(Object error) {
    if (error case StateError(:final message)) {
      return message.toString();
    }
    return 'We could not update this connection. Please try again.';
  }
}
