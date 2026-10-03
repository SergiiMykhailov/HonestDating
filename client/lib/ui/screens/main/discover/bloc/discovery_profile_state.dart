import 'package:honest_dating/models/discovery_profile.dart';

class DiscoveryProfileState {
  const DiscoveryProfileState({
    required this.profile,
    this.isSubmitting = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final DiscoveryProfile profile;
  final bool isSubmitting;
  final String? feedbackMessage;
  final bool feedbackIsError;

  DiscoveryProfileState copyWith({
    DiscoveryProfile? profile,
    bool? isSubmitting,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return DiscoveryProfileState(
      profile: profile ?? this.profile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedbackMessage: clearFeedback
          ? null
          : feedbackMessage ?? this.feedbackMessage,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }
}
