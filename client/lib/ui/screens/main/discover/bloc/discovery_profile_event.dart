sealed class DiscoveryProfileEvent {
  const DiscoveryProfileEvent();
}

final class DiscoveryProfileRefreshRequested extends DiscoveryProfileEvent {
  const DiscoveryProfileRefreshRequested();
}

final class DiscoveryProfileLikeSubmitted extends DiscoveryProfileEvent {
  const DiscoveryProfileLikeSubmitted(this.reason);

  final String reason;
}

final class DiscoveryProfileFriendshipOfferSubmitted
    extends DiscoveryProfileEvent {
  const DiscoveryProfileFriendshipOfferSubmitted(this.reason);

  final String reason;
}

final class DiscoveryProfileFriendshipOfferAccepted
    extends DiscoveryProfileEvent {
  const DiscoveryProfileFriendshipOfferAccepted();
}

final class DiscoveryProfileFeedbackDismissed extends DiscoveryProfileEvent {
  const DiscoveryProfileFeedbackDismissed();
}
