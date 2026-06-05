import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/auth_provider.dart' as ap;
import 'providers/lookbook_provider.dart';
import 'views/splash/splash_view.dart';
import 'views/home/home_view.dart';
import 'core/constants/app_theme.dart';
// import 'firebase_options.dart'; // ← uncomment after flutterfire configure

// ══════════════════════════════════════════════════════════════
//  SUITCASE — main.dart
//  Supports: Android, iOS, Web (Firebase Hosting)
//  Web URL : suitcase.web.app
//  Play Store: com.suitcase.app
// ══════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // ← uncomment after flutterfire configure
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
      ],
      child: MaterialApp(
        title: 'Suitcase',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: SColors.cream,
          colorScheme: ColorScheme.light(
            primary: SColors.ink,
            secondary: SColors.gold,
            surface: SColors.cream,
            background: SColors.cream,
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        // Web: centers the app in a 430px frame on large screens
        // Mobile: renders full screen as normal
        builder: (context, child) {
          if (kIsWeb) {
            return _WebFrame(child: child!);
          }
          return child!;
        },
        home: const _AppGate(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WEB FRAME
//  On desktop browsers: renders app centered at 430px width
//  with a subtle dark background — looks like a phone mockup.
//  On mobile browsers: renders full screen normally.
//  Zero changes needed to any individual screen.
// ══════════════════════════════════════════════════════════════
class _WebFrame extends StatelessWidget {
  final Widget child;
  const _WebFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // On narrow screens (mobile browser) — full screen
    if (screenWidth <= 500) return child;

    // On wide screens (tablet/desktop browser) — centered frame
    return Scaffold(
      backgroundColor: const Color(0xFF0E0C09), // near-black backdrop
      body: Center(
        child: Container(
          width: 430,
          // Full height always
          constraints: const BoxConstraints.expand(width: 430),
          decoration: BoxDecoration(
            color: SColors.cream,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 60,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  APP GATE
//  Reads Firebase auth state and routes accordingly.
//  Returning users go directly to HomeView — no splash screen.
//  New users go to SplashScreen → Onboarding → Auth.
// ══════════════════════════════════════════════════════════════
class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.SuitcaseAuthProvider>();

    switch (auth.state) {
      case ap.AuthState.authenticated:
        return const HomeView();

      case ap.AuthState.unauthenticated:
        return const SplashScreen();

      case ap.AuthState.unknown:
      // Firebase resolving auth state — show minimal loader
        return const Scaffold(
          backgroundColor: SColors.cream,
          body: Center(
            child: CircularProgressIndicator(
              color: SColors.gold,
              strokeWidth: 1.5,
            ),
          ),
        );
    }
  }
}