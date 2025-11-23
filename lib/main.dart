import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth/auth_service.dart';
import 'services/task/task_service.dart';
import 'ui/pages/sign_in_page.dart';
import 'ui/pages/sign_up_page.dart';
import 'ui/pages/tasks_page.dart';
import 'ui/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before using platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the generated options (per platform)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Start the Flutter application
  runApp(const TodoApp());
}

// Root widget of the application
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Global dependency injection for services and auth stream
      providers: [
        // Authentication service (wrapper around FirebaseAuth)
        Provider<AuthService>(create: (_) => AuthService()),

        // Task service (Firestore + Storage access)
        Provider<TaskService>(create: (_) => TaskService()),

        // Authentication state stream, exposed globally
        // Allows us to react to user login/logout without stateful widgets
        StreamProvider<User?>(
          create: (ctx) => ctx.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Todo List',

        // Light theme definition
        theme: AppTheme.light,

        // Dark theme definition
        darkTheme: AppTheme.dark,

        // Use system setting to choose between light/dark
        themeMode: ThemeMode.system,

        // First widget loaded after app start
        home: const HomeGate(),

        // Named routes for navigation
        routes: {
          SignInPage.route: (_) => const SignInPage(),
          SignUpPage.route: (_) => const SignUpPage(),
          TasksPage.route: (_) => const TasksPage(),
        },
      ),
    );
  }
}

// Decides which page to show depending on authentication state
class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to current Firebase user from StreamProvider<User?>
    final user = context.watch<User?>();

    // If no user is logged in, show sign-in page
    if (user == null) {
      return const SignInPage();
    }

    // If user exists, show tasks page
    return const TasksPage();
  }
}
