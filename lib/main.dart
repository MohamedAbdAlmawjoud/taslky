import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'controllers/auth_controller.dart';
import 'controllers/task_controller.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'models/task_model.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/reminder_service.dart';
import 'views/app_views.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final reminders = ReminderService();
  await reminders.initialize();
  runApp(
    TasklyApp(
      auth: AuthProvider(AuthController(AuthService())),
      tasks: TaskProvider(
        TaskController(TaskService()),
        reminderService: reminders,
      ),
    ),
  );
}

class TasklyApp extends StatefulWidget {
  const TasklyApp({super.key, required this.auth, required this.tasks});
  final AuthProvider auth;
  final TaskProvider tasks;
  @override
  State<TasklyApp> createState() => _TasklyAppState();
}

class _TasklyAppState extends State<TasklyApp> {
  String? _lastUid;
  void _authChanged() {
    final uid = widget.auth.currentUser?.uid;
    if (uid != null && uid != _lastUid) {
      _lastUid = uid;
      widget.tasks.loadTasks(uid);
    } else if (uid == null && _lastUid != null) {
      _lastUid = null;
      widget.tasks.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_authChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_authChanged);
    router.dispose();
    super.dispose();
  }

  late final GoRouter router = GoRouter(
    initialLocation: '/boot',
    refreshListenable: widget.auth,
    redirect: (context, state) {
      if (widget.auth.loading) return null;
      final signedIn = widget.auth.currentUser != null;
      if (state.matchedLocation == '/boot') {
        return signedIn ? '/today' : '/login';
      }
      final authRoute = [
        '/login',
        '/register',
        '/forgot',
      ].contains(state.matchedLocation);
      if (!signedIn && !authRoute) return '/login';
      if (signedIn && authRoute) return '/today';
      return null;
    },
    routes: [
      GoRoute(path: '/boot', builder: (c, s) => const _StartupPage()),
      GoRoute(
        path: '/login',
        builder: (c, s) => const AuthPage(register: false),
      ),
      GoRoute(
        path: '/register',
        builder: (c, s) => const AuthPage(register: true),
      ),
      GoRoute(
        path: '/forgot',
        builder: (c, s) => const AuthPage(register: false, forgot: true),
      ),
      ShellRoute(
        builder: (c, s, child) =>
            AppShell(location: s.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/today', builder: (c, s) => const TodayPage()),
          GoRoute(path: '/tasks', builder: (c, s) => const TasksPage()),
          GoRoute(path: '/calendar', builder: (c, s) => const CalendarPage()),
          GoRoute(path: '/profile', builder: (c, s) => const ProfilePage()),
        ],
      ),
      GoRoute(path: '/add', builder: (c, s) => const TaskFormPage()),
      GoRoute(
        path: '/edit/:id',
        builder: (c, s) => TaskFormPage(
          task: s.extra is TaskModel ? s.extra as TaskModel : null,
        ),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (c, s) => TaskDetailPage(id: s.pathParameters['id']!),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.auth),
      ChangeNotifierProvider.value(value: widget.tasks),
    ],
    child: MaterialApp.router(
      title: 'Taskly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.soft,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      routerConfig: router,
    ),
  );
}

class _StartupPage extends StatelessWidget {
  const _StartupPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
