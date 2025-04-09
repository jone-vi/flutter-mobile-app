import '/util/theme_provider.dart';
import '/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/ic_launcher.png',
              height: 60,
            )
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                themeProvider.toggleTheme();
              },
              child: Text(themeProvider.themeMode == ThemeMode.light
                  ? 'Switch to Dark Mode'
                  : 'Switch to Light Mode'),
            ),
            if (authService.currentUser != null &&
                !authService.currentUser!.emailVerified &&
                authService.currentUser!.email != null)
              Column(
                children: [
                  const SizedBox(height: 50),
                  const Text('Your email is not verified'),
                  ElevatedButton(
                    onPressed: () {
                      authService.sendVerifyEmail();
                    },
                    child: const Text('Resend Verification Email'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
