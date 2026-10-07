import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'firebase_options.dart';
import 'workspace.dart';

const brandBlue = Color(0xFF215FD1);
const brandSlate = Color(0xFF68788F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'En Linux abre la versión web con: flutter run -d chrome',
            ),
          ),
        ),
      ),
    );
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const OrderApp());
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'No se pudo conectar a Firebase: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class OrderApp extends StatefulWidget {
  const OrderApp({super.key});

  @override
  State<OrderApp> createState() => _OrderAppState();
}

class _OrderAppState extends State<OrderApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(
          () => _mode = prefs.getBool('darkMode') == true
              ? ThemeMode.dark
              : ThemeMode.light,
        );
      }
    });
  }

  Future<void> _toggleTheme() async {
    final dark = _mode != ThemeMode.dark;
    setState(() => _mode = dark ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', dark);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness brightness) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandBlue,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF111827)
          : const Color(0xFFF3F6FA),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF1A2434)
            : Colors.white,
        foregroundColor: brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF203049),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.dark
            ? const Color(0xFF1B293B)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return MaterialApp(
      title: 'Sistema de pedidos',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: _mode,
      home: AuthGate(mode: _mode, onToggleTheme: _toggleTheme),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({required this.mode, required this.onToggleTheme, super.key});
  final ThemeMode mode;
  final VoidCallback onToggleTheme;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<void>? _profileFuture;
  String? _profileUid;
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Store.instance.auth.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return _message('Error de acceso: ${authSnapshot.error}');
        }
        if (!authSnapshot.hasData) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const BrandedProgress();
          }
          _profileUid = null;
          _profileFuture = null;
          _seeded = false;
          return LoginView(
            onToggleTheme: widget.onToggleTheme,
            mode: widget.mode,
          );
        }
        final user = authSnapshot.data!;
        if (_profileUid != user.uid) {
          _profileUid = user.uid;
          _profileFuture = Store.instance.ensureProfile(user);
          _seeded = false;
        }
        return FutureBuilder<void>(
          future: _profileFuture,
          builder: (context, profileReady) {
            if (profileReady.hasError) {
              return _message(
                'No se pudo crear el perfil: ${profileReady.error}',
              );
            }
            if (profileReady.connectionState != ConnectionState.done) {
              return const BrandedProgress();
            }
            return StreamBuilder<Item?>(
              stream: Store.instance.profile(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _message(
                    'No se pudo leer el perfil: ${snapshot.error}',
                  );
                }
                final profile = snapshot.data;
                if (profile == null) return const BrandedProgress();
                if (profile.text('role') == 'pending') {
                  return const PendingView();
                }
                if (profile.text('role') == 'admin' && !_seeded) {
                  _seeded = true;
                  Store.instance.seedStatuses().catchError((Object error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No se pudieron crear los estados: $error',
                          ),
                        ),
                      );
                    }
                  });
                }
                return Workspace(
                  key: ValueKey('${user.uid}-${profile.text('role')}'),
                  profile: profile,
                  mode: widget.mode,
                  onToggleTheme: widget.onToggleTheme,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _message(String value) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SelectableText(value, textAlign: TextAlign.center),
      ),
    ),
  );
}

class BrandedProgress extends StatelessWidget {
  const BrandedProgress({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/brand/mark.png', width: 96, height: 96),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class LoginView extends StatefulWidget {
  const LoginView({required this.mode, required this.onToggleTheme, super.key});
  final ThemeMode mode;
  final VoidCallback onToggleTheme;
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool busy = false;
  String? error;

  Future<void> _signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await Store.instance.signInWithGoogle();
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/brand/mark.png',
                      width: 126,
                      height: 126,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Sistema de pedidos',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa con tu cuenta de Google para continuar.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (error != null) ...[
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton.icon(
                      onPressed: busy ? null : _signIn,
                      icon: const Icon(Icons.login),
                      label: Text(
                        busy ? 'Conectando…' : 'Continuar con Google',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: widget.onToggleTheme,
                      icon: Icon(
                        widget.mode == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                      label: Text(
                        widget.mode == ThemeMode.dark
                            ? 'Tema claro'
                            : 'Tema oscuro',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PendingView extends StatelessWidget {
  const PendingView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/brand/mark.png', width: 90, height: 90),
                  const SizedBox(height: 16),
                  Text(
                    'Acceso pendiente',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu cuenta ya se registró. Un administrador debe asignarte permisos para usar la aplicación.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => Store.instance.auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
