import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/bus_routes_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reload_screen.dart';
import 'screens/routes_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LankaGoApp());
}

class LankaGoApp extends StatelessWidget {
  const LankaGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => BusRoutesProvider()),
      ],
      child: MaterialApp(
      title: 'Lanka Go',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration (Premium dark theme by default)
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00F2FE),
        scaffoldBackgroundColor: const Color(0xFF020617),
        cardColor: const Color(0xFF1E293B),
        disabledColor: Colors.white24,
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFFFFB300),
          surface: Color(0xFF0F172A),
          error: Color(0xFFEF4444),
        ),

        // Typography using Google Fonts
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme.copyWith(
            bodyLarge: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            bodyMedium: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            titleLarge: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      
      // Routes config
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/reload': (context) => const ReloadScreen(),
        '/routes': (context) => const RoutesScreen(),
      },
    ),
  );
}
}
