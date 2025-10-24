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
import 'services/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // ⚠️ configure firebase_options si tu les utilises
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<TaskService>(create: (_) => TaskService()),
        Provider<NotificationService>(
          create: (_) {
            final service = NotificationService();
            // Fire and forget initialization
            service.init();
            return service;
          },
        ),
        // Stream global d’auth pour router sans StatefulWidget
        StreamProvider<User?>(
          create: (ctx) => ctx.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Todo List',
        theme: AppTheme.light, // Material 3, typo & couleurs
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const HomeGate(),
        routes: {
          SignInPage.route: (_) => const SignInPage(),
          SignUpPage.route: (_) => const SignUpPage(),
          TasksPage.route: (_) => const TasksPage(),
        },
      ),
    );
  }
}

class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    if (user == null) {
      return const SignInPage();
    }
    return const TasksPage();
  }
}
