/// Public backend routing configuration supplied at build time.
///
/// It is deliberately not a credential. Production calls still require the
/// current Firebase Authentication and App Check tokens. Example:
/// `--dart-define=BACKEND_BASE_URL=https://your-service.run.app`.
class BackendConfiguration {
  const BackendConfiguration._();

  /// The public Frankfurt Cloud Run routing URL. Firebase Authentication and
  /// App Check still authorize every data endpoint; this value is not a
  /// credential.
  static const String _baseUrl =
      'https://honest-dating-backend-mk5xbfcfha-ey.a.run.app';
  static const String _biometricConsentVersion = String.fromEnvironment(
    'BIOMETRIC_CONSENT_VERSION',
  );
  static const String _faceTecTransportMode = String.fromEnvironment(
    'FACETEC_TRANSPORT_MODE',
    defaultValue: 'direct_test',
  );

  /// Server-owned liveness requires an approved versioned consent document.
  /// This app has no default because legal content and its version are product
  /// configuration, not client code.
  static String? get biometricConsentVersion {
    final value = _biometricConsentVersion.trim();
    return value.isEmpty ? null : value;
  }

  static bool get isServerOwnedIdentityVerificationEnabled {
    return endpoint('/v1/identity-verifications') != null &&
        biometricConsentVersion != null;
  }

  /// `backend` relays encrypted FaceTec session blobs through Cloud Run. The
  /// default keeps the current native FaceTec Test API preview unchanged.
  static bool get usesBackendFaceTecTransport {
    return _faceTecTransportMode.trim().toLowerCase() == 'backend';
  }

  static Uri? endpoint(String path) {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      return null;
    }

    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null || !baseUri.hasScheme || !baseUri.hasAuthority) {
      return null;
    }
    return baseUri.replace(path: _joinPath(baseUri.path, path));
  }

  static String _joinPath(String basePath, String endpointPath) {
    final normalizedBase = basePath.replaceFirst(RegExp(r'/+$'), '');
    final normalizedEndpoint = endpointPath.replaceFirst(RegExp(r'^/+'), '');
    return '$normalizedBase/$normalizedEndpoint';
  }
}
