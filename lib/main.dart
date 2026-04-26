import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantas_awb/providers/awb_provider.dart';
import 'package:pantas_awb/screens/home_screen.dart';
import 'package:pantas_awb/screens/create_awb_screen.dart';
import 'package:pantas_awb/screens/scan_qr_screen.dart';
import 'package:pantas_awb/screens/search_filter_screen.dart';
import 'package:pantas_awb/screens/settings_screen.dart';
import 'package:pantas_awb/screens/splash_screen.dart';
import 'package:pantas_awb/screens/create_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Professional Color Palette
  static const Color navyDark = Color(0xFF001F3F);
  static const Color navyMedium = Color(0xFF003D7A);
  static const Color cyanPrimary = Color(0xFF00D9FF);
  static const Color cyanLight = Color(0xFFE0F7FA);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AWBProvider()),
      ],
      child: MaterialApp(
        title: 'PANTAS AWB',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: navyDark,
          colorScheme: const ColorScheme.dark(
            primary: cyanPrimary,
            secondary: cyanPrimary,
            surface: navyMedium,
            background: navyDark,
            onPrimary: navyDark,
            onSecondary: navyDark,
            onSurface: Colors.white,
            onBackground: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: navyDark,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          cardTheme: CardTheme(
            color: navyMedium.withOpacity(0.5),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cyanPrimary.withOpacity(0.1)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: cyanPrimary,
              foregroundColor: navyDark,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              elevation: 4,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cyanPrimary.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cyanPrimary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cyanPrimary, width: 2),
            ),
            labelStyle: const TextStyle(color: cyanPrimary),
            hintStyle: const TextStyle(color: Colors.white54),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const CreateProfileScreen(),
          '/create': (context) => const CreateAWBScreen(),
          '/scan': (context) => const ScanQRScreen(),
          '/search': (context) => const SearchFilterScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
