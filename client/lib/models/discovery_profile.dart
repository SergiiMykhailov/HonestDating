class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.firstName,
    required this.age,
    required this.distanceMiles,
    required this.locationLabel,
    required this.primaryPhotoAsset,
    required this.headline,
  });

  final String id;
  final String firstName;
  final int age;
  final int distanceMiles;
  final String locationLabel;
  final String primaryPhotoAsset;
  final String headline;
}
