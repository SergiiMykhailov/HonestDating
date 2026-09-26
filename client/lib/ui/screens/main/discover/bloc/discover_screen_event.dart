sealed class DiscoverScreenEvent {
  const DiscoverScreenEvent();
}

final class DiscoverScreenLoadRequested extends DiscoverScreenEvent {
  const DiscoverScreenLoadRequested();
}

final class DiscoverProfilePositionChanged extends DiscoverScreenEvent {
  const DiscoverProfilePositionChanged(this.index);

  final int index;
}
