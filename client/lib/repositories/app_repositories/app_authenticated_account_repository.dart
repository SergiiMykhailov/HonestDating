import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:honest_dating/repositories/base/base_authenticated_account_repository.dart';

class AppAuthenticatedAccountRepository
    implements BaseAuthenticatedAccountRepository {
  AppAuthenticatedAccountRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> ensureAccount(String userId) async {
    final accountReference = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((Transaction transaction) async {
      final accountSnapshot = await transaction.get(accountReference);

      if (accountSnapshot.exists) {
        transaction.update(accountReference, <String, Object>{
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      transaction.set(accountReference, <String, Object>{
        'schemaVersion': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
