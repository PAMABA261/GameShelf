import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/supabase_service.dart';
import 'services/revenuecat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  await RevenueCatService.initialize();

  final bool hasSession = Supabase.instance.client.auth.currentSession != null;

  runApp(BackloggdCloneApp(initialRouteIsLoggedIn: hasSession));
}

class BackloggdCloneApp extends StatelessWidget {
  final bool initialRouteIsLoggedIn;

  const BackloggdCloneApp({super.key, required this.initialRouteIsLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipaton Backlog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14181C),
        colorScheme: ColorScheme.dark(
          primary: Colors.greenAccent[400]!,
          surface: const Color(0xFF1C2228),
        ),
      ),
      home: initialRouteIsLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}
