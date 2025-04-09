import '/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();
  User? _user;
  String _fullName = '';
  final String _error = '';

  @override
  void initState() {
    super.initState();

    _user = _auth.currentUser;
    if (_user != null) {
      setName();
    }
  }

  Future setName() async {
    String name;
    try {
      name = await _firestore.getFullName();
    } catch (e) {
      name = 'Name not found';
    }
    setState(() {
      _fullName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image(
              image: AssetImage('assets/images/ic_launcher.png'),
              height: 60,
            )
          ],
        ),
        centerTitle: true,
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
        child: _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud,
            size: 150,
            color: theme.colorScheme.secondary,
          ),
          const Text(
            "Logged in as",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            _fullName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            _user?.email ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          if (_error.isNotEmpty)
            Text(
              _error,
            ),
          FilledButton(
            onPressed: () {
              _auth.signOut();
              context.go('/login');
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
