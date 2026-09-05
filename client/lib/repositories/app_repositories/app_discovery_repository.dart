import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';

class AppDiscoveryRepository implements BaseDiscoveryRepository {
  @override
  Future<List<DiscoveryProfile>> loadProfiles() async {
    return const [
      DiscoveryProfile(
        id: 'sample-1',
        firstName: 'Sample',
        headline: 'A local placeholder profile for the app skeleton.',
      ),
    ];
  }
}
