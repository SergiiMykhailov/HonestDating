import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/ui/screens/main/discover/discover_screen.dart';
import 'package:honest_dating/ui/screens/main/discover/discovery_profile_preview_screen.dart';

void main() {
  const profile = DiscoveryProfile(
    id: 'profile-id',
    firstName: 'Alex',
    age: 27,
    distanceMiles: 2,
    locationLabel: 'Tallinn',
    primaryPhotoUrl: 'https://example.com/profile.jpg',
    headline: 'Hello',
  );

  testWidgets('heart action opens the Like reason sheet', (tester) async {
    await _pumpProfile(tester, profile);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    final action = find.byIcon(CupertinoIcons.heart_fill);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('Send a Like'), findsOneWidget);
    expect(
      find.text('What caught your attention about this person?'),
      findsOneWidget,
    );
  });

  testWidgets('friendship action opens the offer reason sheet', (tester) async {
    await _pumpProfile(tester, profile);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    final action = find.byIcon(CupertinoIcons.person_2_fill);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('Offer friendship'), findsWidgets);
    expect(
      find.text('Why would you genuinely enjoy getting to know this person?'),
      findsOneWidget,
    );
  });

  testWidgets('profile marks a sent romantic request', (tester) async {
    final sentProfile = profile.copyWith(
      relationship: const DiscoveryRelationship(
        romantic: DiscoveryRomanticState.likeSent,
      ),
    );
    await _pumpProfile(tester, sentProfile);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
    expect(find.text('Like sent'), findsOneWidget);
  });

  testWidgets('Discover marks a sent friendship offer', (tester) async {
    final sentProfile = profile.copyWith(
      relationship: const DiscoveryRelationship(
        romantic: DiscoveryRomanticState.unavailable,
        friendship: DiscoveryFriendshipState.offerSent,
      ),
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: DiscoverScreen(repository: _ProfileRepository(sentProfile)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Friendship offer sent'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
  });
}

Future<void> _pumpProfile(WidgetTester tester, DiscoveryProfile profile) async {
  await tester.pumpWidget(
    CupertinoApp(
      home: DiscoveryProfilePreviewScreen(
        profile: profile,
        repository: _ProfileRepository(profile),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ProfileRepository implements BaseDiscoveryRepository {
  _ProfileRepository(this.profile);

  final DiscoveryProfile profile;

  @override
  Future<DiscoveryProfile> acceptFriendshipOffer(String profileId) async =>
      profile;

  @override
  Future<DiscoveryProfile> loadProfile(String profileId) async => profile;

  @override
  Future<List<DiscoveryProfile>> loadProfiles() async => [profile];

  @override
  Future<List<DiscoveryProfile>> loadRelationshipProfiles() async => [profile];

  @override
  Future<DiscoveryProfile> sendFriendshipOffer({
    required String profileId,
    required String reason,
  }) async => profile;

  @override
  Future<DiscoveryProfile> sendLike({
    required String profileId,
    required String reason,
  }) async => profile;
}
