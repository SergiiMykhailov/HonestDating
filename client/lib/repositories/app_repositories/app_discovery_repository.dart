import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';

class AppDiscoveryRepository implements BaseDiscoveryRepository {
  @override
  Future<List<DiscoveryProfile>> loadProfiles() async {
    return const [
      DiscoveryProfile(
        id: 'preview-sandra',
        firstName: 'Sandra',
        age: 27,
        distanceMiles: 4,
        locationLabel: 'Tallinn, Estonia',
        primaryPhotoAsset: 'lib/resources/images/discover/sandra.png',
        headline:
            'I’m happiest outside, trying a new place, or catching up with people who make me laugh.',
      ),
      DiscoveryProfile(
        id: 'preview-annabelle',
        firstName: 'Annabelle',
        age: 29,
        distanceMiles: 9,
        locationLabel: 'Tallinn, Estonia',
        primaryPhotoAsset: 'lib/resources/images/discover/annabelle.png',
        headline:
            'Looking for kind company, coastal walks, and conversations that keep unfolding.',
      ),
      DiscoveryProfile(
        id: 'preview-kenji',
        firstName: 'Kenji',
        age: 31,
        distanceMiles: 3,
        locationLabel: 'Tallinn, Estonia',
        primaryPhotoAsset: 'lib/resources/images/discover/kenji.png',
        headline:
            'Bookshops, good coffee, and making room for the people who matter.',
      ),
    ];
  }
}
