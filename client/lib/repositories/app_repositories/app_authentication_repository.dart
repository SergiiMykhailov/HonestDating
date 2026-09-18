import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:honest_dating/models/authentication_provider.dart';
import 'package:honest_dating/models/authentication_start_result.dart';
import 'package:honest_dating/repositories/base/base_authenticated_account_repository.dart';
import 'package:honest_dating/repositories/base/base_authentication_repository.dart';

class AppAuthenticationRepository implements BaseAuthenticationRepository {
  AppAuthenticationRepository({
    required BaseAuthenticatedAccountRepository authenticatedAccountRepository,
    FirebaseAuth? auth,
  }) : _authenticatedAccountRepository = authenticatedAccountRepository,
       _auth = auth ?? FirebaseAuth.instance;

  static Future<void>? _googleInitialization;

  final FirebaseAuth _auth;
  final BaseAuthenticatedAccountRepository _authenticatedAccountRepository;

  @override
  Future<AuthenticationStartResult> beginSocialAuthentication(
    AuthenticationProvider provider,
  ) async {
    try {
      final UserCredential credential = await switch (provider) {
        AuthenticationProvider.google => _signInWithGoogle(),
        AuthenticationProvider.apple => _signInWithApple(),
      };
      final User? user = credential.user ?? _auth.currentUser;
      if (user == null) {
        throw const _AuthenticationConfigurationException();
      }

      try {
        await _authenticatedAccountRepository.ensureAccount(user.uid);
      } catch (_) {
        return AuthenticationStartResult(
          provider: provider,
          status: AuthenticationStartStatus.dataAccessFailed,
        );
      }

      return AuthenticationStartResult(
        provider: provider,
        status: AuthenticationStartStatus.authenticated,
      );
    } on GoogleSignInException catch (exception) {
      return AuthenticationStartResult(
        provider: provider,
        status: switch (exception.code) {
          GoogleSignInExceptionCode.canceled =>
            AuthenticationStartStatus.cancelled,
          GoogleSignInExceptionCode.clientConfigurationError ||
          GoogleSignInExceptionCode.providerConfigurationError =>
            AuthenticationStartStatus.providerConfigurationRequired,
          _ => AuthenticationStartStatus.failed,
        },
      );
    } on _AuthenticationConfigurationException {
      return AuthenticationStartResult(
        provider: provider,
        status: AuthenticationStartStatus.providerConfigurationRequired,
      );
    } on FirebaseAuthException catch (exception) {
      return AuthenticationStartResult(
        provider: provider,
        status: switch (exception.code) {
          'operation-not-allowed' ||
          'unsupported-platform' ||
          'invalid-oauth-client-id' =>
            AuthenticationStartStatus.providerConfigurationRequired,
          'web-context-cancelled' ||
          'popup-closed-by-user' => AuthenticationStartStatus.cancelled,
          _ => AuthenticationStartStatus.failed,
        },
      );
    } on UnsupportedError {
      return AuthenticationStartResult(
        provider: provider,
        status: AuthenticationStartStatus.providerConfigurationRequired,
      );
    } catch (_) {
      return AuthenticationStartResult(
        provider: provider,
        status: AuthenticationStartStatus.failed,
      );
    }
  }

  Future<UserCredential> _signInWithGoogle() async {
    if (kIsWeb) {
      return _auth.signInWithPopup(GoogleAuthProvider());
    }

    await (_googleInitialization ??= GoogleSignIn.instance.initialize());
    final GoogleSignInAccount account = await GoogleSignIn.instance
        .authenticate();
    final String? idToken = account.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw const _AuthenticationConfigurationException();
    }

    return _signInOrLinkWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<UserCredential> _signInWithApple() async {
    final AppleAuthProvider provider = AppleAuthProvider();

    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }

    final User? currentUser = _auth.currentUser;
    if (currentUser?.isAnonymous ?? false) {
      try {
        return await currentUser!.linkWithProvider(provider);
      } on FirebaseAuthException catch (exception) {
        if (exception.code == 'credential-already-in-use') {
          return _auth.signInWithProvider(provider);
        }
        rethrow;
      }
    }

    return _auth.signInWithProvider(provider);
  }

  Future<UserCredential> _signInOrLinkWithCredential(
    AuthCredential credential,
  ) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser?.isAnonymous ?? false) {
      try {
        return await currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (exception) {
        if (exception.code == 'credential-already-in-use') {
          return _auth.signInWithCredential(credential);
        }
        rethrow;
      }
    }

    return _auth.signInWithCredential(credential);
  }
}

class _AuthenticationConfigurationException implements Exception {
  const _AuthenticationConfigurationException();
}
