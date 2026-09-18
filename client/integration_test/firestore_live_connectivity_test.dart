import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const bool _runFirestoreLiveTests = bool.fromEnvironment(
  'RUN_FIRESTORE_LIVE_TESTS',
  defaultValue: false,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('writes, reads, and removes a temporary Firestore collection', (
    WidgetTester _,
  ) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final collectionID =
        'testData-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final collection = FirebaseFirestore.instance.collection(collectionID);
    final probe = collection.doc('connectionProbe');

    try {
      await probe.set(<String, Object>{
        'key': 'value',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final snapshot = await probe.get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['key'], equals('value'));
    } finally {
      await probe.delete();

      final remainingDocuments = await collection.limit(1).get();
      expect(remainingDocuments.docs, isEmpty);
    }
  }, skip: !_runFirestoreLiveTests);
}
