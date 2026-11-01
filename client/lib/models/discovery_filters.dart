class DiscoveryFilters {
  const DiscoveryFilters({
    this.minimumAge = 18,
    this.maximumAge = 99,
    this.maximumDistanceMiles,
    this.datingIntention,
    this.interest,
  });

  static const DiscoveryFilters none = DiscoveryFilters();

  final int minimumAge;
  final int maximumAge;
  final int? maximumDistanceMiles;
  final DiscoveryDatingIntention? datingIntention;
  final String? interest;

  bool get isEmpty =>
      minimumAge == 18 &&
      maximumAge == 99 &&
      maximumDistanceMiles == null &&
      datingIntention == null &&
      interest == null;

  int get activeCount => <bool>[
    minimumAge != 18 || maximumAge != 99,
    maximumDistanceMiles != null,
    datingIntention != null,
    interest != null,
  ].where((value) => value).length;

  DiscoveryFilters copyWith({
    int? minimumAge,
    int? maximumAge,
    int? maximumDistanceMiles,
    DiscoveryDatingIntention? datingIntention,
    String? interest,
    bool clearMaximumDistance = false,
    bool clearDatingIntention = false,
    bool clearInterest = false,
  }) {
    return DiscoveryFilters(
      minimumAge: minimumAge ?? this.minimumAge,
      maximumAge: maximumAge ?? this.maximumAge,
      maximumDistanceMiles: clearMaximumDistance
          ? null
          : maximumDistanceMiles ?? this.maximumDistanceMiles,
      datingIntention: clearDatingIntention
          ? null
          : datingIntention ?? this.datingIntention,
      interest: clearInterest ? null : interest ?? this.interest,
    );
  }
}

enum DiscoveryDatingIntention {
  longTerm('Long-term relationship'),
  openToLongTerm('Open to long-term'),
  friendshipOnly('Friendship only');

  const DiscoveryDatingIntention(this.label);

  final String label;
}
