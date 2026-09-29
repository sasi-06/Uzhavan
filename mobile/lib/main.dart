import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_state.dart';
import 'core/providers/accessibility_provider.dart';
import 'core/services/on_device_nlp_engine.dart';
import 'app/app_shell.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Preload on-device neural AI model immediately on startup
  OnDeviceNlpEngine.instance.loadModel();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDummyKeyForUzhavanMarketplaceWeb",
        appId: "1:105650923648039626695:web:uzhavan69849web",
        messagingSenderId: "105650923648039626695",
        projectId: "uzhavan-69849",
        storageBucket: "uzhavan-69849.appspot.com",
      ),
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
      ],
      child: const UzhavanApp(),
    ),
  );
}

class UzhavanApp extends StatelessWidget {
  const UzhavanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uzhavan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ta'),
        Locale('te'),
        Locale('hi'),
        Locale('en'),
      ],
      home: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return state.isAuthenticated ? const AppShell() : const LoginScreen();
        },
      ),
    );
  }
}
