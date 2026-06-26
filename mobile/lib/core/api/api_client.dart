import 'package:dio/dio.dart';
import '../config/env.dart';
import 'token_store.dart';

/// Thrown for any non-2xx API response, carrying the backend's error code.
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
  @override
  String toString() => message;
}

/// Dio-based client that mirrors the web app's axios setup:
///  - attaches the Bearer access token
///  - on 401, tries a single refresh + retry (skips the /auth/* flows)
///  - unwraps the { success, data } envelope
class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl, contentType: 'application/json'));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = _tokens.accessToken;
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
      onError: _onError,
    ));
  }

  late final Dio _dio;
  final TokenStore _tokens;
  Future<String?>? _refreshing;
  void Function()? onSessionExpired;

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    final res = e.response;
    final path = e.requestOptions.path;
    final noRefresh = path.contains('/auth/') && !path.contains('/auth/me');
    final retried = e.requestOptions.extra['_retry'] == true;

    if (res?.statusCode == 401 && !retried && !noRefresh) {
      _refreshing ??= _refresh();
      final newToken = await _refreshing;
      _refreshing = null;
      if (newToken != null) {
        final opts = e.requestOptions;
        opts.extra['_retry'] = true;
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final clone = await _dio.fetch(opts);
          return handler.resolve(clone);
        } catch (_) {/* fall through */}
      }
      onSessionExpired?.call();
    }
    handler.next(e);
  }

  Future<String?> _refresh() async {
    final rt = _tokens.refreshToken;
    if (rt == null) return null;
    try {
      final r = await Dio(BaseOptions(baseUrl: Env.apiBaseUrl))
          .post('/auth/refresh-token', data: {'refreshToken': rt});
      final token = r.data?['data']?['accessToken'] as String?;
      if (token != null) await _tokens.setAccess(token);
      return token;
    } catch (_) {
      return null;
    }
  }

  ApiException _wrap(DioException e) {
    final body = e.response?.data;
    final err = body is Map ? body['error'] : null;
    return ApiException(
      e.response?.statusCode ?? 0,
      (err?['code'] as String?) ?? 'NETWORK_ERROR',
      (err?['message'] as String?) ?? e.message ?? 'Request failed',
    );
  }

  // Unwrap { success, data }.
  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async {
    try {
      final r = await _dio.get(path, queryParameters: query);
      return r.data['data'] as T;
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<T> post<T>(String path, {Object? data}) async {
    try {
      final r = await _dio.post(path, data: data ?? {});
      return r.data['data'] as T;
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<T> put<T>(String path, {Object? data}) async {
    try {
      final r = await _dio.put(path, data: data ?? {});
      return r.data['data'] as T;
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<T> patch<T>(String path, {Object? data}) async {
    try {
      final r = await _dio.patch(path, data: data ?? {});
      return r.data['data'] as T;
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  Future<T> delete<T>(String path) async {
    try {
      final r = await _dio.delete(path);
      return r.data['data'] as T;
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }
}
