import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/ui/screens/main/interactions/bloc/interaction_center_event.dart';

sealed class InteractionCenterState {
  const InteractionCenterState();
}

final class InteractionCenterLoading extends InteractionCenterState {
  const InteractionCenterLoading();
}

final class InteractionCenterFailure extends InteractionCenterState {
  const InteractionCenterFailure();
}

final class InteractionCenterLoaded extends InteractionCenterState {
  const InteractionCenterLoaded({
    required this.profiles,
    this.mode = InteractionCenterMode.romance,
    this.section = InteractionSection.matches,
  });

  final List<DiscoveryProfile> profiles;
  final InteractionCenterMode mode;
  final InteractionSection section;

  List<DiscoveryProfile> get visibleProfiles => profiles
      .where((profile) {
        final relationship = profile.relationship;
        return switch (section) {
          InteractionSection.matches =>
            relationship.romantic == DiscoveryRomanticState.matched,
          InteractionSection.likesReceived =>
            relationship.romantic == DiscoveryRomanticState.likeReceived,
          InteractionSection.likesSent =>
            relationship.romantic == DiscoveryRomanticState.likeSent,
          InteractionSection.friends =>
            relationship.friendship == DiscoveryFriendshipState.friends,
          InteractionSection.offersReceived =>
            relationship.friendship == DiscoveryFriendshipState.offerReceived,
          InteractionSection.offersSent =>
            relationship.friendship == DiscoveryFriendshipState.offerSent,
        };
      })
      .toList(growable: false);

  int count(InteractionSection section) {
    return profiles.where((profile) {
      final relationship = profile.relationship;
      return switch (section) {
        InteractionSection.matches =>
          relationship.romantic == DiscoveryRomanticState.matched,
        InteractionSection.likesReceived =>
          relationship.romantic == DiscoveryRomanticState.likeReceived,
        InteractionSection.likesSent =>
          relationship.romantic == DiscoveryRomanticState.likeSent,
        InteractionSection.friends =>
          relationship.friendship == DiscoveryFriendshipState.friends,
        InteractionSection.offersReceived =>
          relationship.friendship == DiscoveryFriendshipState.offerReceived,
        InteractionSection.offersSent =>
          relationship.friendship == DiscoveryFriendshipState.offerSent,
      };
    }).length;
  }

  InteractionCenterLoaded copyWith({
    InteractionCenterMode? mode,
    InteractionSection? section,
  }) {
    return InteractionCenterLoaded(
      profiles: profiles,
      mode: mode ?? this.mode,
      section: section ?? this.section,
    );
  }
}
