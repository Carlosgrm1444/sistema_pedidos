import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'design.dart';
import 'firebase_options.dart';
import 'feedback.dart';
import 'workspace.dart';

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
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeServices();
  }

  Future<void> _initializeServices() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
  }

  void _retry() => setState(() => _initialization = _initializeServices());

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      final theme = appTheme(Brightness.light);
      if (snapshot.hasError) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Scaffold(
            body: AppBackdrop(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: PolishedCard(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 42),
                          const SizedBox(height: 14),
                          const Text(
                            'No se pudo iniciar la aplicación',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Revisa tu conexión a internet y vuelve a intentarlo.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
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
      if (snapshot.connectionState != ConnectionState.done) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: const BrandedProgress(),
        );
      }
      return const OrderApp();
    },
  );
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
    unawaited(AppFeedback.instance.load());
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
    AppFeedback.instance.select();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de pedidos',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: _mode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOutCubic,
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
    body: AppBackdrop(
      child: Center(
        child: MotionReveal(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/brand/mark.png', width: 104, height: 104),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 15),
              Text(
                'Preparando tu espacio de trabajo…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
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
      AppFeedback.instance.success();
    } catch (exception) {
      AppFeedback.instance.error();
      if (mounted) {
        setState(() {
          error = exception is FirebaseAuthException
              ? switch (exception.code) {
                  'popup-closed-by-user' =>
                    'Cerraste la ventana de Google. Puedes intentarlo de nuevo.',
                  'unauthorized-domain' =>
                    'Este dominio aún no está autorizado en Firebase.',
                  _ => exception.message ?? 'No se pudo iniciar sesión.',
                }
              : 'No se pudo iniciar sesión: $exception';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final theme = Theme.of(context);
            final signInCard = MotionReveal(
              offset: 22,
              child: PolishedCard(
                child: Padding(
                  padding: EdgeInsets.all(
                    constraints.maxWidth >= 520 ? 38 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/brand/mark.png',
                        width: 96,
                        height: 96,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'SISTEMA DE PEDIDOS',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Bienvenido de nuevo',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entra con tu cuenta de Google para continuar con tus pedidos.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      AnimatedSwitcher(
                        duration: motionDuration(context, 220),
                        child: error == null
                            ? const SizedBox.shrink(key: ValueKey('no-error'))
                            : Padding(
                                key: ValueKey(error),
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      FilledButton.icon(
                        onPressed: busy ? null : _signIn,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          busy ? 'Conectando…' : 'Continuar con Google',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Divider(color: theme.colorScheme.outlineVariant),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onToggleTheme,
                            icon: Icon(
                              widget.mode == ThemeMode.dark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              size: 19,
                            ),
                            label: Text(
                              widget.mode == ThemeMode.dark
                                  ? 'Tema claro'
                                  : 'Tema oscuro',
                            ),
                          ),
                          AnimatedBuilder(
                            animation: AppFeedback.instance,
                            builder: (context, _) => TextButton.icon(
                              onPressed: () => AppFeedback.instance.toggle(),
                              icon: Icon(
                                AppFeedback.instance.soundsEnabled
                                    ? Icons.volume_up_outlined
                                    : Icons.volume_off_outlined,
                                size: 19,
                              ),
                              label: Text(
                                AppFeedback.instance.soundsEnabled
                                    ? 'Sonido activo'
                                    : 'Sin sonido',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: signInCard,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class PendingView extends StatelessWidget {
  const PendingView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackdrop(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: MotionReveal(
              child: PolishedCard(
                child: Padding(
                  padding: const EdgeInsets.all(34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/brand/mark.png',
                        width: 86,
                        height: 86,
                      ),
                      const SizedBox(height: 22),
                      Icon(
                        Icons.hourglass_top_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Acceso pendiente',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tu cuenta ya está registrada. Un administrador debe asignarte permisos para usar la aplicación.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
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
      ),
    ),
  );
}
