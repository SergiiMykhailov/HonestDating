import 'package:honest_dating/models/discovery_profile.dart';

abstract interface class BaseDiscoveryRepository {
  Future<List<DiscoveryProfile>> loadProfiles();
}
