import 'package:honest_dating/models/discovery_filters.dart';
import 'package:honest_dating/models/discovery_profile.dart';

sealed class DiscoverScreenState {
  const DiscoverScreenState();
}

final class DiscoverScreenLoading extends DiscoverScreenState {
  const DiscoverScreenLoading();
}

final class DiscoverScreenLoaded extends DiscoverScreenState {
  const DiscoverScreenLoaded({
    required this.profiles,
    this.currentIndex = 0,
    this.filters = DiscoveryFilters.none,
    this.availableInterests = const <String>[],
  });

  final List<DiscoveryProfile> profiles;
  final int currentIndex;
  final DiscoveryFilters filters;
  final List<String> availableInterests;
}

final class DiscoverScreenFailure extends DiscoverScreenState {
  const DiscoverScreenFailure();
}
