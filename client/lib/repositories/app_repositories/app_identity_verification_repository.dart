import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:honest_dating/config/backend_configuration.dart';
import 'package:honest_dating/models/identity_verification_result.dart';
import 'package:honest_dating/repositories/base/base_identity_verification_repository.dart';
import 'package:http/http.dart' as http;

class AppIdentityVerificationRepository
    implements BaseIdentityVerificationRepository {
  AppIdentityVerificationRepository({
    FirebaseAuth? authentication,
    FirebaseAppCheck? appCheck,
    http.Client? client,
  }) : _authentication = authentication ?? FirebaseAuth.instance,
       _appCheck = appCheck ?? FirebaseAppCheck.instance,
       _client = client ?? http.Client();

  static const MethodChannel _channel = MethodChannel(
    'com.honestdating/facetec-test',
  );

  final FirebaseAuth _authentication;
  final FirebaseAppCheck _appCheck;
  final http.Client _client;
  String? _activeLivenessVerificationToken;

  @override
  String? get activeLivenessVerificationToken =>
      _activeLivenessVerificationToken;

  @override
  Future<bool> isLivenessCheckSkippedOnCurrentDevice() async {
    try {
      return await _channel.invokeMethod<bool>('isSimulator') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<IdentityVerificationResult> startLivenessCheck() async {
    _activeLivenessVerificationToken = null;

    try {
      final serverAttempt = await _startServerAttemptIfConfigured();
      final nativeArguments = serverAttempt == null
          ? null
          : await _nativeArgumentsFor(serverAttempt);
      final response = await _channel.invokeMethod<Object?>(
        'startLivenessCheck',
        nativeArguments,
      );
      final outcome = response is Map<Object?, Object?>
          ? response['outcome'] as String?
          : null;
      final verificationMode = response is Map<Object?, Object?>
          ? response['verificationMode'] as String?
          : null;
      final parsedOutcome = _outcomeFromPlatformValue(outcome);

      if (parsedOutcome != IdentityVerificationOutcome.verified) {
        return IdentityVerificationResult(outcome: parsedOutcome);
      }

      if (serverAttempt == null) {
        return const IdentityVerificationResult(
          outcome: IdentityVerificationOutcome.verified,
        );
      }

      // Simulator liveness is intentionally skipped. It may retain the
      // opaque token for approval-override preview only; production enforce
      // mode still requires the server to confirm real liveness.
      if (verificationMode == 'simulatorSkipped' ||
          !BackendConfiguration.usesBackendFaceTecTransport) {
        _activeLivenessVerificationToken = serverAttempt.token;
        return const IdentityVerificationResult(
          outcome: IdentityVerificationOutcome.verified,
        );
      }

      final completionStatus = await _completeServerAttempt(serverAttempt);
      if (completionStatus == 'approved') {
        _activeLivenessVerificationToken = serverAttempt.token;
        return const IdentityVerificationResult(
          outcome: IdentityVerificationOutcome.verified,
        );
      }

      return IdentityVerificationResult(
        outcome: completionStatus == 'unavailable'
            ? IdentityVerificationOutcome.serviceFailed
            : IdentityVerificationOutcome.failed,
      );
    } on MissingPluginException {
      return const IdentityVerificationResult(
        outcome: IdentityVerificationOutcome.unavailable,
      );
    } on PlatformException catch (error) {
      return IdentityVerificationResult(
        outcome: error.code == 'unsupported_platform'
            ? IdentityVerificationOutcome.unavailable
            : IdentityVerificationOutcome.failed,
      );
    } on _IdentityVerificationException {
      return const IdentityVerificationResult(
        outcome: IdentityVerificationOutcome.serviceFailed,
      );
    }
  }

  Future<_ServerLivenessAttempt?> _startServerAttemptIfConfigured() async {
    if (!BackendConfiguration.isServerOwnedIdentityVerificationEnabled) {
      return null;
    }
    final response = await _post(
      '/v1/identity-verifications',
      <String, Object?>{
        'biometricConsentVersion': BackendConfiguration.biometricConsentVersion,
      },
    );
    final token = response['verificationToken'];
    if (token is! String || token.isEmpty) {
      throw const _IdentityVerificationException();
    }
    return _ServerLivenessAttempt(token: token);
  }

  Future<Map<String, Object?>?> _nativeArgumentsFor(
    _ServerLivenessAttempt attempt,
  ) async {
    if (!BackendConfiguration.usesBackendFaceTecTransport) {
      return null;
    }
    final endpoint = _endpoint(
      '/v1/identity-verifications/${Uri.encodeComponent(attempt.token)}/facetec-session-requests',
    );
    final headers = await _authenticatedHeaders();
    return <String, Object?>{
      'useBackendTransport': true,
      'sessionRequestEndpoint': endpoint.toString(),
      'authorization': headers['Authorization'],
      'appCheckToken': headers['X-Firebase-AppCheck'],
    };
  }

  Future<String> _completeServerAttempt(_ServerLivenessAttempt attempt) async {
    final response = await _post(
      '/v1/identity-verifications/${Uri.encodeComponent(attempt.token)}/completion',
      const <String, Object?>{},
    );
    final status = response['status'];
    if (status is! String || status.isEmpty) {
      throw const _IdentityVerificationException();
    }
    return status;
  }

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client.post(
      _endpoint(path),
      headers: await _authenticatedHeaders(),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Uri _endpoint(String path) {
    final endpoint = BackendConfiguration.endpoint(path);
    if (endpoint == null) {
      throw const _IdentityVerificationException();
    }
    return endpoint;
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    final idToken = await _authentication.currentUser?.getIdToken();
    final appCheckToken = await _appCheck.getToken();
    if (idToken == null ||
        idToken.isEmpty ||
        appCheckToken == null ||
        appCheckToken.isEmpty) {
      throw const _IdentityVerificationException();
    }
    return <String, String>{
      'Authorization': 'Bearer $idToken',
      'X-Firebase-AppCheck': appCheckToken,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Map<String, Object?> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw const _IdentityVerificationException();
    }
    return decoded;
  }

  IdentityVerificationOutcome _outcomeFromPlatformValue(String? value) {
    switch (value) {
      case 'verified':
        return IdentityVerificationOutcome.verified;
      case 'cancelled':
        return IdentityVerificationOutcome.cancelled;
      case 'cameraPermissionDenied':
        return IdentityVerificationOutcome.cameraPermissionDenied;
      case 'initializationFailed':
        return IdentityVerificationOutcome.initializationFailed;
      case 'networkFailed':
        return IdentityVerificationOutcome.networkFailed;
      case 'serviceFailed':
        return IdentityVerificationOutcome.serviceFailed;
      case 'cameraError':
        return IdentityVerificationOutcome.cameraError;
      case 'lockedOut':
        return IdentityVerificationOutcome.lockedOut;
      case 'unavailable':
        return IdentityVerificationOutcome.unavailable;
      default:
        return IdentityVerificationOutcome.failed;
    }
  }
}

class _ServerLivenessAttempt {
  const _ServerLivenessAttempt({required this.token});

  final String token;
}

class _IdentityVerificationException implements Exception {
  const _IdentityVerificationException();
}
