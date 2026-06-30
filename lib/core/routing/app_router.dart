import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/onboarding/presentation/controllers/onboarding_provider.dart';
import '../../shared/widgets/app_shell.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/stats/presentation/screens/weekly_review_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/controllers/auth_provider.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RefListener(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final onboardingState = ref.read(onboardingProvider);
      final onboarding = onboardingState.value;
      final location = state.matchedLocation;

      // Always allow splash through
      if (location == AppRoutes.splash) return null;

      if (onboarding == null) return null;

      final isCompleted =
          onboarding.isCompleted || ref.read(authProvider) != null;
      final goingToOnboarding = location == AppRoutes.onboarding;

      if (!isCompleted && !goingToOnboarding) {
        return AppRoutes.onboarding;
      }
      if (isCompleted && goingToOnboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding Screen (No bottom nav)
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyReview,
        builder: (context, state) => const WeeklyReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      // App Navigation Shell
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: AppRoutes.stats,
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class _RefListener extends ChangeNotifier {
  _RefListener(Ref ref) {
    ref.listen(onboardingProvider, (_, __) => notifyListeners());
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

// Deprecated global reference, retained for compilation back-compatibility
// but routerProvider should be preferred.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    ),
  ],
);
