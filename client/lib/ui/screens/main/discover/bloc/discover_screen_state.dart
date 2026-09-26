import 'package:honest_dating/models/discovery_profile.dart';

sealed class DiscoverScreenState {
  const DiscoverScreenState();
}

final class DiscoverScreenLoading extends DiscoverScreenState {
  const DiscoverScreenLoading();
}

final class DiscoverScreenLoaded extends DiscoverScreenState {
  const DiscoverScreenLoaded({required this.profiles, this.currentIndex = 0});

  final List<DiscoveryProfile> profiles;
  final int currentIndex;
}

final class DiscoverScreenFailure extends DiscoverScreenState {
  const DiscoverScreenFailure();
}
