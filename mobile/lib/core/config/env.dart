/// Runtime configuration. Override the API base URL at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://your-render-app/api/v1
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api/v1',
  );
}
