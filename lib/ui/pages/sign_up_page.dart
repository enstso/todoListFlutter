import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'tasks_page.dart';

// Sign-up page allowing new users to create an account using
// email + password authentication with Firebase.
class SignUpPage extends StatelessWidget {
  static const route = '/signup';
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers for input fields
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      // Simple app bar indicating the purpose of the page
      appBar: AppBar(title: const Text('Create an account')),
      body: Center(
        child: ConstrainedBox(
          // Constrain max width (useful on web and tablets)
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              // Ensures column wraps content nicely
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page title
                Text(
                  'Inscription',
                  style: Theme.of(context).textTheme.headlineSmall,
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

                // Main button to create a new account
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final auth = context.read<AuthService>();

                      try {
                        // Create user account using Firebase Auth
                        await auth.signUp(emailCtrl.text.trim(), passCtrl.text);

                        // If successful, navigate to task list
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed(
                            TasksPage.route,
                          );
                        }
                      } catch (e) {
                        // If registration fails, show an error message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Create an account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
