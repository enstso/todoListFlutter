import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// Services
import 'package:todo_list/services/auth/auth_service.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/services/user/user_service.dart';

// UI
import 'package:todo_list/ui/pages/sign_in_page.dart';
import 'package:todo_list/ui/pages/sign_up_page.dart';
import 'package:todo_list/ui/pages/tasks_page.dart';
import 'package:todo_list/ui/theme/app_theme.dart';
import 'package:todo_list/ui/theme/theme_provider.dart'; // ⬅️ new

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

/// Root widget of the application.
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Global dependency injection for services, auth stream, and theme provider.
      providers: [
        // ThemeProvider is responsible for selecting light / dark / system mode.
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),

        // Authentication service (wrapper around FirebaseAuth)
        Provider<AuthService>(create: (_) => AuthService()),

        // Task service (Firestore + Storage access)
        Provider<TaskService>(create: (_) => TaskService()),

        // User service (used to store and query users in Firestore)
        Provider<UserService>(create: (_) => UserService()),

        // Authentication state stream, exposed globally.
        // Allows us to react to user login/logout without stateful widgets.
        StreamProvider<User?>(
          create: (ctx) => ctx.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: Builder(
        builder: (context) {
          // Listen to theme changes from ThemeProvider
          final themeMode = context.watch<ThemeProvider>().mode;

          return MaterialApp(
            title: 'Todo List',

            // Light theme definition
            theme: AppTheme.light,

            // Dark theme definition
            darkTheme: AppTheme.dark,

            // Use ThemeProvider's current mode (system / light / dark)
            themeMode: themeMode,

            // First widget loaded after app start
            home: const HomeGate(),

            // Named routes for navigation
            routes: {
              SignInPage.route: (_) => const SignInPage(),
              SignUpPage.route: (_) => const SignUpPage(),
              TasksPage.route: (_) => const TasksPage(),
            },
          );
        },
      ),
    );
  }
}

/// Decides which page to show depending on authentication state.
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
