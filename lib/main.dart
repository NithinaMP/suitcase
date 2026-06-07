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
import 'firebase_options.dart'; // ← uncomment after flutterfire configure

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
        builder: (context, child) {
          if (kIsWeb) return _WebFrame(child: child!);
          return child!;
        },
        home: const _AppGate(),
      ),
    );
  }
}

// class _WebFrame extends StatelessWidget {
//   final Widget child;
//   const _WebFrame({required this.child});
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     if (screenWidth <= 500) return child;
//     return Scaffold(
//       backgroundColor: const Color(0xFF0E0C09),
//       body: Center(
//         child: Container(
//           constraints: const BoxConstraints.expand(width: 430),
//           decoration: BoxDecoration(
//             color: SColors.cream,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.4),
//                 blurRadius: 60,
//               ),
//             ],
//           ),
//           child: ClipRect(child: child),
//         ),
//       ),
//     );
//   }
// }
class _WebFrame extends StatelessWidget {
  final Widget child;
  const _WebFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 500) return child;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0C09),
      body: Center(
        child: SizedBox(
          width: 430,
          child: ClipRect(child: child),
        ),
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
          backgroundColor: SColors.cream,
          body: Center(
            child: CircularProgressIndicator(
                color: SColors.gold, strokeWidth: 1.5),
          ),
        );
    }
  }
}