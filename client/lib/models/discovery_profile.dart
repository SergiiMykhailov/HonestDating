class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.firstName,
    required this.age,
    required this.distanceMiles,
    required this.locationLabel,
    required this.primaryPhotoUrl,
    required this.headline,
    this.galleryPhotoUrls = const <String>[],
    this.details = const <DiscoveryProfileDetail>[],
    this.interests = const <String>[],
    this.questions = const <DiscoveryProfileQuestion>[],
    this.relationship = const DiscoveryRelationship(),
  });

  final String id;
  final String firstName;
  final int age;
  final int distanceMiles;
  final String locationLabel;
  final String primaryPhotoUrl;
  final String headline;
  final List<String> galleryPhotoUrls;
  final List<DiscoveryProfileDetail> details;
  final List<String> interests;
  final List<DiscoveryProfileQuestion> questions;
  final DiscoveryRelationship relationship;

  DiscoveryProfile copyWith({DiscoveryRelationship? relationship}) {
    return DiscoveryProfile(
      id: id,
      firstName: firstName,
      age: age,
      distanceMiles: distanceMiles,
      locationLabel: locationLabel,
      primaryPhotoUrl: primaryPhotoUrl,
      headline: headline,
      galleryPhotoUrls: galleryPhotoUrls,
      details: details,
      interests: interests,
      questions: questions,
      relationship: relationship ?? this.relationship,
    );
  }
}

class DiscoveryProfileDetail {
  const DiscoveryProfileDetail({required this.label, required this.value});

  final String label;
  final String value;
}

class DiscoveryProfileQuestion {
  const DiscoveryProfileQuestion({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

enum DiscoveryRomanticState {
  none,
  likeSent,
  likeReceived,
  matched,
  unavailable,
}

enum DiscoveryFriendshipState { none, offerSent, offerReceived, friends }

class DiscoveryRelationship {
  const DiscoveryRelationship({
    this.romantic = DiscoveryRomanticState.none,
    this.friendship = DiscoveryFriendshipState.none,
    this.outgoingLikeReason,
    this.incomingLikeReason,
    this.outgoingFriendshipReason,
    this.incomingFriendshipReason,
  });

  final DiscoveryRomanticState romantic;
  final DiscoveryFriendshipState friendship;
  final String? outgoingLikeReason;
  final String? incomingLikeReason;
  final String? outgoingFriendshipReason;
  final String? incomingFriendshipReason;

  DiscoveryRelationship copyWith({
    DiscoveryRomanticState? romantic,
    DiscoveryFriendshipState? friendship,
    String? outgoingLikeReason,
    String? incomingLikeReason,
    String? outgoingFriendshipReason,
    String? incomingFriendshipReason,
    bool clearIncomingFriendshipReason = false,
  }) {
    return DiscoveryRelationship(
      romantic: romantic ?? this.romantic,
      friendship: friendship ?? this.friendship,
      outgoingLikeReason: outgoingLikeReason ?? this.outgoingLikeReason,
      incomingLikeReason: incomingLikeReason ?? this.incomingLikeReason,
      outgoingFriendshipReason:
          outgoingFriendshipReason ?? this.outgoingFriendshipReason,
      incomingFriendshipReason: clearIncomingFriendshipReason
          ? null
          : incomingFriendshipReason ?? this.incomingFriendshipReason,
    );
  }
}
