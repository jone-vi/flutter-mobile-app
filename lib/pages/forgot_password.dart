import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  ForgotPageState createState() => ForgotPageState();
}

class ForgotPageState extends State<ForgotPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _forgot() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an email'),
        ),
      );
      return;
    }

    if (_auth.currentUser != null) {
      context.go('/');
      return;
    }

    try {
      await _auth.forgotPassword(_emailController.text);
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Password Reset Email Sent'),
              content: const Text(
                  'Please check your email for a password reset link'),
              actions: [
                TextButton(
                  onPressed: () {
                    // close the dialog
                    Navigator.of(dialogContext).pop();
                    context.go('/login');
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            );
          });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'An unknown error occurred'),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reset Password',
                style:
                    GoogleFonts.koulen(fontSize: 24, color: Colors.grey[800])),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _forgot,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: const Text('Reset Password'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: Text(
                'Back to Login',
                style: GoogleFonts.roboto(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// widget with card that pops up when password reset email is sent
class PasswordResetCard extends StatelessWidget {
  const PasswordResetCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Text('Password reset email sent'),
          TextButton(
            onPressed: () {
              context.go('/login');
            },
            child: Text(
              'Back to Login',
              style: GoogleFonts.roboto(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
