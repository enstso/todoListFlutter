import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'tasks_page.dart';
import 'sign_up_page.dart';

// Sign-in screen allowing users to log in with email and password.
// Uses Provider to access AuthService for authentication.
class SignInPage extends StatelessWidget {
  static const route = '/signin';
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers for email and password input fields
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          // Constrains max width to keep UI clean on large screens (web/tablet)
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon at the top
                  const Icon(Icons.task_alt, size: 56),

                  const SizedBox(height: 12),
                  // Welcome message
                  Text('Welcome 👋', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Log In to see your tasks',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 24),

                  // Email input field
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Password input field
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final auth = context.read<AuthService>();

                        try {
                          // Attempt sign-in with email + password
                          await auth.signIn(emailCtrl.text.trim(), passCtrl.text);

                          // Navigate to tasks page after successful login
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed(TasksPage.route);
                          }
                        } catch (e) {
                          // On authentication error, show a snackbar message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Log In'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Link to sign-up page for new users
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(SignUpPage.route),
                    child: const Text("Create an account"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
