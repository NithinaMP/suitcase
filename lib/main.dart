import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
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
          appBarTheme: AppBarTheme(
            backgroundColor: SColors.bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: SColors.ink),
          ),
        ),
        home: const _AppGate(),
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