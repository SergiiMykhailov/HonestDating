import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:honest_dating/config/backend_configuration.dart';
import 'package:honest_dating/models/authentication_provider.dart';
import 'package:honest_dating/models/authentication_start_result.dart';
import 'package:honest_dating/repositories/base/base_authenticated_account_repository.dart';
import 'package:honest_dating/repositories/base/base_authentication_repository.dart';
import 'package:http/http.dart' as http;

class AppAuthenticationRepository implements BaseAuthenticationRepository {
  AppAuthenticationRepository({
    required BaseAuthenticatedAccountRepository authenticatedAccountRepository,
    FirebaseAuth? auth,
    FirebaseAppCheck? appCheck,
    http.Client? client,
  }) : _authenticatedAccountRepository = authenticatedAccountRepository,
       _auth = auth ?? FirebaseAuth.instance,
       _appCheck = appCheck ?? FirebaseAppCheck.instance,
       _client = client ?? http.Client();

  static Future<void>? _googleInitialization;

  final FirebaseAuth _auth;
  final FirebaseAppCheck _appCheck;
  final http.Client _client;
  final BaseAuthenticatedAccountRepository _authenticatedAccountRepository;

  @override
  Future<bool> beginDebugPreviewAuthentication() async {
    if (!kDebugMode) {
      return false;
    }
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      final customToken = await _requestDebugPreviewCustomToken();
      if (customToken == null) {
        return false;
      }
      final credential = await _auth.signInWithCustomToken(customToken);
      final user = credential.user ?? _auth.currentUser;
      if (user == null) {
        return false;
      }
      await _authenticatedAccountRepository.ensureDebugPreviewAccount(user.uid);
      return true;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

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

  Future<String?> _requestDebugPreviewCustomToken() async {
    final endpoint = BackendConfiguration.endpoint('/v1/debug-preview-auth');
    if (endpoint == null) {
      return null;
    }
    final idToken = await _auth.currentUser?.getIdToken();
    final appCheckToken = await _appCheck.getToken();
    if (idToken == null ||
        idToken.isEmpty ||
        appCheckToken == null ||
        appCheckToken.isEmpty) {
      return null;
    }

    final response = await _client.post(
      endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $idToken',
        'X-Firebase-AppCheck': appCheckToken,
      },
    );
    if (response.statusCode != 200) {
      return null;
    }
    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map<Object?, Object?>) {
      return null;
    }
    final customToken = responseBody['customToken'];
    return customToken is String && customToken.isNotEmpty ? customToken : null;
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
