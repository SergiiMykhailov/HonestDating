import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/models/discovery_filters.dart';

abstract interface class BaseDiscoveryRepository {
  Future<List<DiscoveryProfile>> loadProfiles({
    DiscoveryFilters filters = DiscoveryFilters.none,
  });

  Future<DiscoveryProfile> loadProfile(String profileId);

  Future<List<DiscoveryProfile>> loadRelationshipProfiles();

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
