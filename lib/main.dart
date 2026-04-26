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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AWBProvider()),
      ],
      child: MaterialApp(
        title: 'PANTAS AWB',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 2,
            centerTitle: false,
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
