enum AuthenticationProvider {
  google('Google'),
  apple('Apple');

  const AuthenticationProvider(this.label);

  final String label;
}
