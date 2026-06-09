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

final routerProvider = Provider<GoRouter>((ref) {
  // Watch the onboarding state to trigger router redirects reactively
  final onboardingState = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final onboarding = onboardingState.value;
      if (onboarding == null) return null;

      final isCompleted = onboarding.isCompleted;
      final goingToOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (!isCompleted && !goingToOnboarding) {
        return AppRoutes.onboarding;
      }
      if (isCompleted && goingToOnboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // Onboarding Screen (No bottom nav)
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Search Screen (No bottom nav)
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
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
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
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
