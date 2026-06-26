import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api/api_client.dart';
import 'api/token_store.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    webOptions: WebOptions(),
  );
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.read(secureStorageProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(tokenStoreProvider));
});

/// Debug helper.
void logDebug(String msg) {
  if (kDebugMode) debugPrint('[utsav] $msg');
}
