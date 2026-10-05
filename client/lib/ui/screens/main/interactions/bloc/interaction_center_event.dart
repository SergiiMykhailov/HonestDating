sealed class InteractionCenterEvent {
  const InteractionCenterEvent();
}

final class InteractionCenterLoadRequested extends InteractionCenterEvent {
  const InteractionCenterLoadRequested();
}

final class InteractionCenterModeChanged extends InteractionCenterEvent {
  const InteractionCenterModeChanged(this.mode);

  final InteractionCenterMode mode;
}

final class InteractionCenterSectionChanged extends InteractionCenterEvent {
  const InteractionCenterSectionChanged(this.section);

  final InteractionSection section;
}

enum InteractionCenterMode { romance, friendship }

enum InteractionSection {
  matches,
  likesReceived,
  likesSent,
  friends,
  offersReceived,
  offersSent,
}

extension InteractionSectionMode on InteractionSection {
  bool get isRomance => switch (this) {
    InteractionSection.matches ||
    InteractionSection.likesReceived ||
    InteractionSection.likesSent => true,
    _ => false,
  };
}
