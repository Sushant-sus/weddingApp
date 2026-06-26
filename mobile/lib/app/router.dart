import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/events/events_screen.dart';
import '../features/shell/app_shell.dart';

/// Auth-guarded router. Redirects to /login when unauthenticated and away from
/// /login once signed in. The events picker is the post-login landing screen.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => notifier.value++);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      // Hold on the splash until the session has been restored.
      if (auth.status == AuthStatus.unknown) return loc == '/' ? null : '/';
      final authed = auth.status == AuthStatus.authenticated;
      if (!authed) return loc == '/login' ? null : '/login';
      // Authenticated: keep them out of splash/login.
      if (loc == '/' || loc == '/login') return '/events';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
      GoRoute(path: '/app/dashboard', builder: (context, state) => const AppShell()),
    ],
  );
});
