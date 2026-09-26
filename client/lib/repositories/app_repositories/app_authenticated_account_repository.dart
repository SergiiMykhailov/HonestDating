import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:honest_dating/repositories/base/base_authenticated_account_repository.dart';

class AppAuthenticatedAccountRepository
    implements BaseAuthenticatedAccountRepository {
  AppAuthenticatedAccountRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? authentication,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _authentication = authentication ?? FirebaseAuth.instance;

  static const String debugPreviewEmail = 'folia.dummy@gmail.com';
  final FirebaseFirestore _firestore;
  final FirebaseAuth _authentication;

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

  @override
  Future<void> ensureDebugPreviewAccount(String userId) async {
    final accountReference = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((Transaction transaction) async {
      final accountSnapshot = await transaction.get(accountReference);

      if (accountSnapshot.exists) {
        transaction.update(accountReference, <String, Object>{
          'email': debugPreviewEmail,
          'accountKind': 'debugPreview',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      transaction.set(accountReference, <String, Object>{
        'schemaVersion': 1,
        'email': debugPreviewEmail,
        'accountKind': 'debugPreview',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<bool> hasCompletedMobileRegistration() async {
    final user = await _authentication.authStateChanges().first;
    if (user == null) {
      return false;
    }
    final accountSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    return accountSnapshot.data()?['registrationCompletedAt'] is Timestamp;
  }

  @override
  Future<void> completeMobileRegistration(String userId) {
    return _firestore.collection('users').doc(userId).update(<String, Object>{
      'registrationCompletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
