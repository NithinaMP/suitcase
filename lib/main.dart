import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/auth_provider.dart' as ap;
import 'providers/lookbook_provider.dart';
import 'providers/travel_engine_provider.dart';
import 'views/splash/splash_view.dart';
import 'views/shell/app_shell.dart';
import 'core/constants/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SuitcaseApp());
}

class SuitcaseApp extends StatelessWidget {
  const SuitcaseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ap.SuitcaseAuthProvider()),
        ChangeNotifierProvider(create: (_) => LookbookProvider()),
        ChangeNotifierProvider(create: (_) => TravelEngineProvider()),
      ],
      child: MaterialApp(
        title: 'Suitcase',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: SColors.bg,
          colorScheme: ColorScheme.light(
            primary: SColors.ink,
            secondary: SColors.gold,
            surface: SColors.bg,
            background: SColors.bg,
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        // Web: full screen, no phone frame
        builder: kIsWeb
            ? (context, child) => _WebLayout(child: child!)
            : null,
        home: const _AppGate(),
      ),
    );
  }
}

// ── Web Layout — full screen, responsive ─────────────────────
// On mobile browser (<600px): full screen
// On desktop browser (>600px): centered max 480px with clean bg
// NOT a phone frame — feels like a real website
class _WebLayout extends StatelessWidget {
  final Widget child;
  const _WebLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return child; // mobile browser — full screen

    // Desktop: centered content column, clean background
    return Scaffold(
      backgroundColor: const Color(0xFFF0EBE3),
      body: Row(
        children: [
          // Left padding — decorative
          Expanded(
            child: Container(
              color: const Color(0xFFF0EBE3),
              child: Center(
                child: Text('SUITCASE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 4,
                    color: const Color(0xFFB5895A).withOpacity(0.4),
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
          ),
          // Center content
          Container(
            width: 480,
            decoration: BoxDecoration(
              color: SColors.bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                ),
              ],
            ),
            child: child,
          ),
          // Right padding — decorative
          Expanded(
            child: Container(
              color: const Color(0xFFF0EBE3),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Text('dress the journey · own the moment',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3,
                      color: const Color(0xFFB5895A).withOpacity(0.35),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.SuitcaseAuthProvider>();
    switch (auth.state) {
      case ap.AuthState.authenticated:
        return const AppShell();
      case ap.AuthState.unauthenticated:
        return const SplashScreen();
      case ap.AuthState.unknown:
        return const Scaffold(
          backgroundColor: SColors.bg,
          body: Center(
            child: CircularProgressIndicator(
                color: SColors.gold, strokeWidth: 1.5),
          ),
        );
    }
  }
}