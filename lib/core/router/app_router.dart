import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/educators/presentation/educators_screen.dart';
import '../../features/educators/presentation/educator_profile_screen.dart';
import '../../features/courses/presentation/courses_screen.dart';
import '../../features/courses/presentation/course_details_screen.dart';
import '../../features/exams/presentation/exams_screen.dart';
import '../../features/exams/presentation/exam_details_screen.dart';
import '../../features/exams/presentation/exam_content_tile.dart';
import '../../features/exams/presentation/course_type_screen.dart';
import '../../features/exams/presentation/exam_educators_screen.dart';
import '../../features/exams/presentation/exam_webinars_screen.dart';
import '../../features/test_series/presentation/test_series_screen.dart'
    as test_series_list;
import '../../features/test_series/presentation/test_series_details_screen.dart'
    as test_series_details;
import '../../features/live_test/presentation/live_test_screen.dart';
import '../../features/live_test/presentation/test_result_screen.dart';
import '../../features/webinars/presentation/webinars_screen.dart';
import '../../features/webinars/presentation/webinar_details_screen.dart';
import '../../features/dashboard/student_dashboard.dart';
import '../../features/dashboard/student_courses.dart';
import '../../features/dashboard/test_series.dart';
import '../../features/dashboard/following_tab_screen.dart';
import '../../features/coursePanel/course_panel.dart';
import '../../features/coursePanel/video_player_screen.dart';
import '../../features/coursePanel/pdf_viewer_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/dashboard/message_tab_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/dashboard/result_tab.dart';
import '../../features/dashboard/webinar_tab.dart';
import '../../features/post/all_posts.dart';
import '../../features/auth/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';
      final isSplash = state.matchedLocation == '/splash';
      // Don't redirect from splash - let it handle navigation
      if (isSplash) return null;

      // If not logged in and not on auth pages, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on auth pages, redirect to home
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.extra is String
              ? state.extra as String
              : state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),

      // Main Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const StudentDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/student-courses',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const StudentCoursesScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard/test-series',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const StudentTestSeriesScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard/webinars',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const WebinarTabScreen(),
            ),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const MessageTabScreen(),
            ),
          ),
          GoRoute(
            path: '/following',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const FollowingTabScreen(),
            ),
          ),
          GoRoute(
            path: '/results',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: ResultsTabScreen(
                resultData: state.extra is Map<String, dynamic>
                    ? state.extra as Map<String, dynamic>
                    : null,
              ),
            ),
          ),
          GoRoute(
            path: '/exams',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const ExamsScreen(),
            ),
          ),
          GoRoute(
            path: '/educators',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const EducatorsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: UniqueKey(),
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // Educator Profile
      GoRoute(
        path: '/educator/:id',
        builder: (context, state) => EducatorProfileScreen(
          educatorId: state.pathParameters['id']!,
        ),
      ),

      // Courses
      GoRoute(
        path: '/courses',
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: '/course/:id',
        builder: (context, state) => CourseDetailsScreen(
          courseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/course-panel/:id',
        builder: (context, state) {
          final extra = state.extra is Map ? state.extra as Map : const {};
          return CoursePanelScreen(
            courseId: state.pathParameters['id']!,
            title: extra['title']?.toString(),
            imageUrl: extra['imageUrl']?.toString(),
          );
        },
      ),
      GoRoute(
        path: '/video-player',
        builder: (context, state) {
          final extra = state.extra is Map ? state.extra as Map : const {};
          final title = extra['title']?.toString() ?? 'Video';
          final url = extra['url']?.toString() ?? '';
          final fullscreen = extra['fullscreen'] == true;
          return VideoPlayerScreen(
            title: title,
            url: url,
            fullscreen: fullscreen,
          );
        },
      ),
      GoRoute(
        path: '/pdf-viewer/:id',
        builder: (context, state) {
          final extra = state.extra is Map ? state.extra as Map : const {};
          final title = extra['title']?.toString() ?? 'Material';
          final url = extra['url']?.toString() ?? '';
          return PdfViewerScreen(title: title, url: url);
        },
      ),

      // Exams Detail
      GoRoute(
        path: '/exam/:type',
        builder: (context, state) => ExamDetailsScreen(
          examType: state.pathParameters['type']!,
          initialCourseType: state.uri.queryParameters['courseType'],
        ),
      ),
      GoRoute(
        path: '/exam-content/:type',
        builder: (context, state) => ExamContentTileScreen(
          examType: state.pathParameters['type']!,
        ),
      ),
      GoRoute(
        path: '/exam-courses/:type/:courseType',
        builder: (context, state) => CourseTypeScreen(
          examType: state.pathParameters['type']!,
          courseType: state.pathParameters['courseType']!,
        ),
      ),
      GoRoute(
        path: '/exam-educators/:type',
        builder: (context, state) => ExamEducatorsScreen(
          examType: state.pathParameters['type']!,
        ),
      ),
      GoRoute(
        path: '/exam-webinars/:type',
        builder: (context, state) => ExamWebinarsScreen(
          examType: state.pathParameters['type']!,
        ),
      ),

      // Posts
      GoRoute(
        path: '/posts',
        builder: (context, state) {
          final examType = state.uri.queryParameters['exam'];
          return PostsScreen(examType: examType);
        },
      ),

      // Test Series
      GoRoute(
        path: '/test-series',
        builder: (context, state) {
          final examType = state.uri.queryParameters['exam'];
          return test_series_list.TestSeriesScreen(examType: examType);
        },
      ),
      GoRoute(
        path: '/test-series/:id',
        builder: (context, state) =>
            test_series_details.TestSeriesDetailsScreen(
          testSeriesId: state.pathParameters['id']!,
        ),
      ),

      // Live Test
      GoRoute(
        path: '/live-test/:id',
        builder: (context, state) => LiveTestScreen(
          testId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/test-result/:id',
        builder: (context, state) => TestResultScreen(
          resultId: state.pathParameters['id']!,
          resultData: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),

      // Results

      // Webinars
      GoRoute(
        path: '/webinars',
        builder: (context, state) => const WebinarsScreen(),
      ),
      GoRoute(
        path: '/webinar/:id',
        builder: (context, state) => WebinarDetailsScreen(
          webinarId: state.pathParameters['id']!,
        ),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Messages
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
