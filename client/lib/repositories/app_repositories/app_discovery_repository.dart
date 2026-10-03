import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';

/// A device-local preview of the relationship rules used by Epic 2.
///
/// The implementation intentionally keeps all data in memory. Replacing it
/// with a server-backed repository is a later slice, after its relationship
/// contract has been agreed.
class AppDiscoveryRepository implements BaseDiscoveryRepository {
  AppDiscoveryRepository()
    : _profiles = <String, DiscoveryProfile>{
        for (final profile in _previewProfiles) profile.id: profile,
      };

  static const List<DiscoveryProfile> _previewProfiles = <DiscoveryProfile>[
    DiscoveryProfile(
      id: 'preview-sandra',
      firstName: 'Sandra',
      age: 27,
      distanceMiles: 4,
      locationLabel: 'Tallinn, Estonia',
      primaryPhotoAsset: 'lib/resources/images/discover/sandra.png',
      headline:
          'I’m happiest outside, trying a new place, or catching up with people who make me laugh.',
      details: <DiscoveryProfileDetail>[
        DiscoveryProfileDetail(label: 'Orientation', value: 'Straight'),
        DiscoveryProfileDetail(
          label: 'Dating intention',
          value: 'Long-term relationship',
        ),
        DiscoveryProfileDetail(label: 'Height', value: '168 cm'),
        DiscoveryProfileDetail(
          label: 'Languages',
          value: 'English, Estonian, Spanish',
        ),
        DiscoveryProfileDetail(label: 'Religion', value: 'No religion'),
        DiscoveryProfileDetail(label: 'Going out', value: 'Enjoys going out'),
        DiscoveryProfileDetail(label: 'Exercise', value: '3–4 times a week'),
        DiscoveryProfileDetail(label: 'Pets', value: 'Has a dog'),
        DiscoveryProfileDetail(label: 'Education', value: 'Bachelor’s degree'),
        DiscoveryProfileDetail(label: 'Work', value: 'Product designer'),
      ],
      interests: <String>['Travel', 'Books', 'Live music', 'Dancing', 'Hiking'],
      questions: <DiscoveryProfileQuestion>[
        DiscoveryProfileQuestion(
          question: 'A small thing that always improves my day',
          answer: 'A long walk without a plan and a very good coffee.',
        ),
        DiscoveryProfileQuestion(
          question: 'Something I would love to learn',
          answer:
              'How to make pasta that feels worth inviting people over for.',
        ),
      ],
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
      details: <DiscoveryProfileDetail>[
        DiscoveryProfileDetail(label: 'Orientation', value: 'Straight'),
        DiscoveryProfileDetail(
          label: 'Dating intention',
          value: 'Open to long-term',
        ),
        DiscoveryProfileDetail(label: 'Height', value: '171 cm'),
        DiscoveryProfileDetail(
          label: 'Languages',
          value: 'English, French, Turkish',
        ),
        DiscoveryProfileDetail(label: 'Religion', value: 'No religion'),
        DiscoveryProfileDetail(label: 'Diet', value: 'No restrictions'),
        DiscoveryProfileDetail(label: 'Exercise', value: '1–2 times a week'),
        DiscoveryProfileDetail(label: 'Alcohol', value: 'Occasionally'),
        DiscoveryProfileDetail(label: 'Education', value: 'Master’s degree'),
        DiscoveryProfileDetail(label: 'Work', value: 'Architect'),
      ],
      interests: <String>['Photography', 'Travel', 'Museums', 'Cooking'],
      questions: <DiscoveryProfileQuestion>[
        DiscoveryProfileQuestion(
          question: 'A place I keep returning to',
          answer:
              'The sea in the off-season, when it feels like it belongs to nobody.',
        ),
        DiscoveryProfileQuestion(
          question: 'My ideal Sunday',
          answer: 'A market, a long lunch, and absolutely no rush afterwards.',
        ),
      ],
      relationship: DiscoveryRelationship(
        romantic: DiscoveryRomanticState.likeReceived,
        incomingLikeReason:
            'Your curiosity, warmth, and the way you describe an ordinary day all stood out to me.',
      ),
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
      details: <DiscoveryProfileDetail>[
        DiscoveryProfileDetail(label: 'Orientation', value: 'Straight'),
        DiscoveryProfileDetail(
          label: 'Dating intention',
          value: 'Not dating — friendship only',
        ),
        DiscoveryProfileDetail(label: 'Height', value: '182 cm'),
        DiscoveryProfileDetail(label: 'Languages', value: 'English, Japanese'),
        DiscoveryProfileDetail(label: 'Religion', value: 'No religion'),
        DiscoveryProfileDetail(label: 'Social', value: 'Balanced'),
        DiscoveryProfileDetail(label: 'Going out', value: 'Enjoys going out'),
        DiscoveryProfileDetail(label: 'Alcohol', value: 'Never'),
        DiscoveryProfileDetail(label: 'Pets', value: 'No pets'),
        DiscoveryProfileDetail(label: 'Work', value: 'Editor'),
      ],
      interests: <String>['Bookshops', 'Coffee', 'Film', 'Cycling'],
      questions: <DiscoveryProfileQuestion>[
        DiscoveryProfileQuestion(
          question: 'The last thing I recommended to a friend',
          answer:
              'A tiny bookshop where the owner always has one more title to suggest.',
        ),
        DiscoveryProfileQuestion(
          question: 'A conversation I enjoy',
          answer:
              'One that wanders a little and does not need to arrive anywhere.',
        ),
      ],
      relationship: DiscoveryRelationship(
        romantic: DiscoveryRomanticState.unavailable,
        friendship: DiscoveryFriendshipState.offerReceived,
        incomingFriendshipReason:
            'You seem thoughtful and I would genuinely enjoy talking about books and films with you.',
      ),
    ),
  ];

  final Map<String, DiscoveryProfile> _profiles;

  @override
  Future<List<DiscoveryProfile>> loadProfiles() async {
    return List<DiscoveryProfile>.unmodifiable(_profiles.values);
  }

  @override
  Future<DiscoveryProfile> loadProfile(String profileId) async {
    return _profileFor(profileId);
  }

  @override
  Future<DiscoveryProfile> sendLike({
    required String profileId,
    required String reason,
  }) async {
    _validateReason(reason);
    final profile = _profileFor(profileId);
    final relationship = profile.relationship;

    if (relationship.friendship != DiscoveryFriendshipState.none) {
      throw StateError(
        'Romantic interest is unavailable because a friendship connection already exists or is pending.',
      );
    }

    switch (relationship.romantic) {
      case DiscoveryRomanticState.none:
        return _store(
          profile.copyWith(
            relationship: relationship.copyWith(
              romantic: DiscoveryRomanticState.likeSent,
              outgoingLikeReason: reason.trim(),
            ),
          ),
        );
      case DiscoveryRomanticState.likeReceived:
        return _store(
          profile.copyWith(
            relationship: relationship.copyWith(
              romantic: DiscoveryRomanticState.matched,
              outgoingLikeReason: reason.trim(),
            ),
          ),
        );
      case DiscoveryRomanticState.likeSent:
        throw StateError('You have already sent a Like to this person.');
      case DiscoveryRomanticState.matched:
        throw StateError('You are already matched with this person.');
      case DiscoveryRomanticState.unavailable:
        throw StateError('Romantic interest is unavailable for this profile.');
    }
  }

  @override
  Future<DiscoveryProfile> sendFriendshipOffer({
    required String profileId,
    required String reason,
  }) async {
    _validateReason(reason);
    final profile = _profileFor(profileId);
    final relationship = profile.relationship;

    if (relationship.friendship != DiscoveryFriendshipState.none) {
      throw StateError('A friendship connection already exists or is pending.');
    }
    if (relationship.romantic == DiscoveryRomanticState.likeSent) {
      throw StateError(
        'You have already expressed romantic interest, so you cannot offer friendship at this time.',
      );
    }
    if (relationship.romantic == DiscoveryRomanticState.matched) {
      throw StateError('You are already matched with this person.');
    }

    return _store(
      profile.copyWith(
        relationship: relationship.copyWith(
          romantic: DiscoveryRomanticState.unavailable,
          friendship: DiscoveryFriendshipState.offerSent,
          outgoingFriendshipReason: reason.trim(),
        ),
      ),
    );
  }

  @override
  Future<DiscoveryProfile> acceptFriendshipOffer(String profileId) async {
    final profile = _profileFor(profileId);
    final relationship = profile.relationship;
    if (relationship.friendship != DiscoveryFriendshipState.offerReceived) {
      throw StateError('There is no friendship offer to accept.');
    }
    return _store(
      profile.copyWith(
        relationship: relationship.copyWith(
          friendship: DiscoveryFriendshipState.friends,
          clearIncomingFriendshipReason: true,
        ),
      ),
    );
  }

  DiscoveryProfile _profileFor(String profileId) {
    final profile = _profiles[profileId];
    if (profile == null) {
      throw StateError('This profile is no longer available.');
    }
    return profile;
  }

  DiscoveryProfile _store(DiscoveryProfile profile) {
    _profiles[profile.id] = profile;
    return profile;
  }

  void _validateReason(String reason) {
    final length = reason.trim().length;
    if (length < 50 || length > 500) {
      throw StateError(
        'Write a personal reason between 50 and 500 characters.',
      );
    }
  }
}
