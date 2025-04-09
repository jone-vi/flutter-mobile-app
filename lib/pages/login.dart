import '../database.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an email and password'),
        ),
      );
      return;
    }

    if (_auth.currentUser != null) {
      context.go('/profile');
      return;
    }

    try {
      Trace customTrace = FirebasePerformance.instance.newTrace('Login-Trace');
      await customTrace.start();
      try {
        await _auth.signIn(_emailController.text, _passwordController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password or username incorrect'),
          ),
        );
      }
      if (mounted) {
        final db = Provider.of<Database>(context, listen: false);
        await db.syncFromFirestore();
        context.go('/profile');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syncing data from cloud...'),
          ),
        );
      }
      await customTrace.stop();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'An unknown error occurred'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.go('/settings');
              },
            ),
          ],
        ),
        body: Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to',
                  textAlign: TextAlign.center,
                  style:
                      GoogleFonts.koulen(fontSize: 24, color: Colors.grey[800]),
                ),
                Text(
                  'lookt',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kumbhSans(fontSize: 60),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/forgot');
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.koulen(fontSize: 16),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                FilledButton(
                    onPressed: () {
                      _login();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                    child: Text(
                      'Login',
                      style:
                          GoogleFonts.koulen(fontSize: 20, color: Colors.white),
                    )),
                const SizedBox(height: 10),
                const NotRegisteredWidget(),
              ],
            ),
          ),
        ));
  }
}

class NotRegisteredWidget extends StatelessWidget {
  const NotRegisteredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Not registered yet?',
          style: GoogleFonts.koulen(fontSize: 16),
        ),
        TextButton(
          onPressed: () {
            context.go('/signup');
          },
          child: Text(
            'Register',
            style: GoogleFonts.koulen(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
