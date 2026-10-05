import 'package:flutter_test/flutter_test.dart';
import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/ui/screens/main/interactions/bloc/interaction_center_event.dart';
import 'package:honest_dating/ui/screens/main/interactions/bloc/interaction_center_state.dart';

void main() {
  test('filters and counts every relationship section', () {
    final state = InteractionCenterLoaded(
      profiles: [
        _profile('match', romantic: DiscoveryRomanticState.matched),
        _profile('received', romantic: DiscoveryRomanticState.likeReceived),
        _profile(
          'friend',
          romantic: DiscoveryRomanticState.unavailable,
          friendship: DiscoveryFriendshipState.friends,
        ),
      ],
      section: InteractionSection.likesReceived,
    );

    expect(state.count(InteractionSection.matches), 1);
    expect(state.count(InteractionSection.likesReceived), 1);
    expect(state.count(InteractionSection.friends), 1);
    expect(state.visibleProfiles.single.id, 'received');
  });
}

DiscoveryProfile _profile(
  String id, {
  DiscoveryRomanticState romantic = DiscoveryRomanticState.none,
  DiscoveryFriendshipState friendship = DiscoveryFriendshipState.none,
}) {
  return DiscoveryProfile(
    id: id,
    firstName: id,
    age: 25,
    distanceMiles: 1,
    locationLabel: 'Tallinn',
    primaryPhotoUrl: 'https://example.com/$id.jpg',
    headline: 'Hello',
    relationship: DiscoveryRelationship(
      romantic: romantic,
      friendship: friendship,
    ),
  );
}
