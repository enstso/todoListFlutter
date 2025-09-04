import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'tasks_page.dart';

class SignUpPage extends StatelessWidget {
  static const route = '/signup';
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Inscription', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final auth = context.read<AuthService>();
                      try {
                        await auth.signUp(emailCtrl.text.trim(), passCtrl.text);
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed(TasksPage.route);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                      }
                    },
                    child: const Text('Créer mon compte'),
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
