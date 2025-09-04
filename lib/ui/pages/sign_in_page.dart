import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'tasks_page.dart';
import 'sign_up_page.dart';

class SignInPage extends StatelessWidget {
  static const route = '/signin';
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.task_alt, size: 56),
                  const SizedBox(height: 12),
                  Text('Bienvenue 👋', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Connecte-toi pour voir tes tâches',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final auth = context.read<AuthService>();
                        try {
                          await auth.signIn(emailCtrl.text.trim(), passCtrl.text);
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed(TasksPage.route);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        }
                      },
                      child: const Text('Se connecter'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(SignUpPage.route),
                    child: const Text("Créer un compte"),
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
