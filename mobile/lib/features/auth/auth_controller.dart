import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/api/api_client.dart';
import '../../core/api/token_store.dart';
import '../../core/providers.dart';
import '../events/event_providers.dart';
import 'auth_models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.loading = false, this.error});
  final AuthStatus status;
  final AuthUser? user;
  final bool loading;
  final String? error;

  AuthState copyWith({AuthStatus? status, AuthUser? user, bool? loading, String? error, bool clearError = false}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref, this._api, this._tokens) : super(const AuthState()) {
    _api.onSessionExpired = () => logout();
    _bootstrap();
  }

  final Ref _ref;
  final ApiClient _api;
  final TokenStore _tokens;

  /// Clears event data cached for the previous user so a freshly signed-in
  /// account only ever sees its own events. [eventsProvider] is kept alive
  /// across sessions by the non-autoDispose [selectedEventProvider], so it must
  /// be invalidated explicitly when the authenticated user changes.
  void _resetUserScopedState({bool refetch = false}) {
    _ref.read(selectedEventIdProvider.notifier).state = null;
    if (refetch) _ref.invalidate(eventsProvider);
  }

  Future<void> _bootstrap() async {
    try {
      await _tokens.load();
      if (!_tokens.hasSession) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      final me = await _api.get<Map<String, dynamic>>('/auth/me');
      state = state.copyWith(status: AuthStatus.authenticated, user: AuthUser.fromJson(me));
    } catch (_) {
      try {
        await _tokens.clear();
      } catch (_) {}
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = await _api.post<Map<String, dynamic>>('/auth/login', data: {'email': email, 'password': password});
      await _tokens.save(access: data['accessToken'], refresh: data['refreshToken']);
      // Drop any event data cached for a previously signed-in user and force a
      // fresh fetch under the new token before the events screen reads it.
      _resetUserScopedState(refetch: true);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
        loading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Something went wrong');
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );
      state = state.copyWith(loading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Something went wrong');
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String otp) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _api.post<Map<String, dynamic>>('/auth/verify-email', data: {'email': email, 'otp': otp});
      state = state.copyWith(loading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Something went wrong');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', data: {'refreshToken': _tokens.refreshToken});
    } catch (_) {}
    await _tokens.clear();
    // Clear the selected event; the events cache is refetched on next login.
    _resetUserScopedState();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref, ref.read(apiClientProvider), ref.read(tokenStoreProvider));
});
