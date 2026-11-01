import 'package:honest_dating/models/discovery_filters.dart';

sealed class DiscoverScreenEvent {
  const DiscoverScreenEvent();
}

final class DiscoverScreenLoadRequested extends DiscoverScreenEvent {
  const DiscoverScreenLoadRequested({this.filters});

  final DiscoveryFilters? filters;
}

final class DiscoverProfilePositionChanged extends DiscoverScreenEvent {
  const DiscoverProfilePositionChanged(this.index);

  final int index;
}

final class DiscoverFiltersChanged extends DiscoverScreenEvent {
  const DiscoverFiltersChanged(this.filters);

  final DiscoveryFilters filters;
}
