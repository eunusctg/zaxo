import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_animations.dart';
import '../core/constants/app_colors.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/auth/sign_in_screen.dart';
import '../presentation/screens/auth/sign_up_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/chats/chat_screen.dart';
import '../presentation/screens/calls/audio_call_screen.dart';
import '../presentation/screens/calls/video_call_screen.dart';
import '../presentation/screens/status/status_view_screen.dart';
import '../presentation/screens/status/create_status_screen.dart';
import '../presentation/screens/settings/profile_screen.dart';
import '../presentation/screens/contacts/contacts_screen.dart';

/// Zaxo app router built with [GoRouter].
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter appRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _slideFadePage(
          state: state,
          child: const SplashScreen(),
        ),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _slideFadePage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      // Auth
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          if (tab == 'signup') return const SignUpScreen();
          return const SignInScreen();
        },
      ),

      // Home (with bottom navigation)
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _slideFadePage(
          state: state,
          child: const HomeScreen(),
        ),
      ),

      // Chat detail
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        pageBuilder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          return _slideFadePage(
            state: state,
            child: ChatScreen(chatId: chatId),
          );
        },
      ),

      // Audio call
      GoRoute(
        path: '/call/audio/:chatId',
        name: 'audioCall',
        pageBuilder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          return _slideFadePage(
            state: state,
            child: AudioCallScreen(chatId: chatId),
          );
        },
      ),

      // Video call
      GoRoute(
        path: '/call/video/:chatId',
        name: 'videoCall',
        pageBuilder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          return _slideFadePage(
            state: state,
            child: VideoCallScreen(chatId: chatId),
          );
        },
      ),

      // Status view
      GoRoute(
        path: '/status/view/:userId',
        name: 'statusView',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return _slideFadePage(
            state: state,
            child: StatusViewScreen(userId: userId),
          );
        },
      ),

      // Create status
      GoRoute(
        path: '/status/create',
        name: 'createStatus',
        pageBuilder: (context, state) => _slideFadePage(
          state: state,
          child: const CreateStatusScreen(),
        ),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => _slideFadePage(
          state: state,
          child: const ProfileScreen(),
        ),
      ),

      // Contacts
      GoRoute(
        path: '/contacts',
        name: 'contacts',
        pageBuilder: (context, state) => _slideFadePage(
          state: state,
          child: const ContactsScreen(),
        ),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  static CustomTransitionPage<void> _slideFadePage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppAnimations.pageTransitionDuration,
      reverseTransitionDuration: AppAnimations.pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AppAnimations.pageTransitionCurve,
          reverseCurve: AppAnimations.pageTransitionCurve,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppAnimations.defaultCurve,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
