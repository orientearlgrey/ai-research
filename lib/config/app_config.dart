class AppConfig {
  AppConfig._();

  /// Base URL for the Cloud Functions backend. Overridden at build time via
  /// `--dart-define=API_BASE_URL=...`. The placeholder default targets the
  /// local Firebase emulator convention; update once the backend project
  /// exists and this is actually wired up.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'http://localhost:5001/REPLACE_WITH_FIREBASE_PROJECT_ID/us-central1',
  );
}
