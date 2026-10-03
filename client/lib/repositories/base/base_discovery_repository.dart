import 'package:honest_dating/models/discovery_profile.dart';

abstract interface class BaseDiscoveryRepository {
  Future<List<DiscoveryProfile>> loadProfiles();

  Future<DiscoveryProfile> loadProfile(String profileId);

  Future<DiscoveryProfile> sendLike({
    required String profileId,
    required String reason,
  });

  Future<DiscoveryProfile> sendFriendshipOffer({
    required String profileId,
    required String reason,
  });

  Future<DiscoveryProfile> acceptFriendshipOffer(String profileId);
}
