import 'dart:async';
import 'database.dart';
import 'pages/pages.dart';
import 'util/parent.dart';
import 'util/theme_provider.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final Database db = await openDatabase();
  final FirebaseAuth auth = FirebaseAuth.instance;

  final Connectivity connectivity = Connectivity();

  Timer.periodic(const Duration(seconds: 15), (timer) async {
    var connectivityResult = await connectivity.checkConnectivity();

    if (!connectivityResult.contains(ConnectivityResult.none) &&
        auth.currentUser != null) {
      db.syncToFirestore();
    }
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Database db;
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Provider<Database>(
      create: (_) => db,
      dispose: (_, Database db) => db.close(),
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'lookt',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        darkTheme: ThemeData.dark(),
        themeMode: themeProvider.themeMode,
      ),
    );
  }
}

final FirebaseAuth auth = FirebaseAuth.instance;
final GoRouter _router = GoRouter(
  initialLocation: auth.currentUser == null ? '/login' : '/',
  routes: [
    ShellRoute(
      navigatorKey: GlobalKey<NavigatorState>(),
      builder: (context, state, child) => NavigationHost(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/warehouse',
          builder: (context, state) => const WarehousePage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
          redirect: (context, state) {
            if (FirebaseAuth.instance.currentUser == null) {
              return '/login';
            }
            return null;
          },
        ),
        GoRoute(
          path: '/additem',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>;
            return AddItemPage(
                addingType: extras['type'], parent: extras["parent"]);
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/warehouselist',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>;

            int? id;
            if (extras['parentId'] != null) {
              String parentIdString = extras['parentId'].toString().trim();
              id = int.tryParse(parentIdString);
            }

            final parent = ParentParams(
              type: extras['parentType'],
              id: id,
              name: extras['parentName'],
            );

            return WarehouseListPage(type: extras['type'], parent: parent);
          },
        ),
        GoRoute(
          path: '/warehouseitem',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>;
            final type = extras['type'] as String;
            final id = int.parse(extras['id']);
            return WarehouseItemPage(type: type, id: id);
          },
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>;
            final type = extras['type'] as String;
            final id = extras['id'];
            return EditPage(type: type, id: id);
          },
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        )
      ],
    ),
  ],
);

class NavigationHost extends StatefulWidget {
  final Widget child;
  const NavigationHost({super.key, required this.child});

  @override
  State<NavigationHost> createState() => _NavigationHostState();
}

class _NavigationHostState extends State<NavigationHost> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.warehouse), label: 'Warehouse'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/warehouse');
              break;
            case 1:
              context.go('/');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}
