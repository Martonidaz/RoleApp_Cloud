import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/constantes.dart';
import 'screens/tela_login.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AppRole());
}

class AppRole extends StatelessWidget {
  const AppRole({super.key});

  @override
  Widget build(BuildContext context) {
    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIconColor: kPrimaryColor,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Rolê',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            scaffoldBackgroundColor: kBgLight,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kPrimaryColor,
              primary: kPrimaryColor,
              secondary: kSecondaryColor,
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: kBgLight,
              foregroundColor: kPrimaryColor,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: kPrimaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 4,
              shadowColor: Colors.black12,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            inputDecorationTheme: inputDecorationTheme,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryColor,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: kPrimaryColor.withOpacity(0.1),
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
            ),
          ),
          darkTheme: ThemeData(
            scaffoldBackgroundColor: kBgDark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kPrimaryColor,
              primary: const Color(0xFF90CAF9),
              secondary: const Color(0xFF66BB6A),
              surface: const Color(0xFF1E1E1E),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: kBgDark,
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: inputDecorationTheme.copyWith(
              fillColor: Colors.white.withOpacity(0.05),
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white10),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              indicatorColor: Colors.white10,
            ),
          ),
          home: const TelaLogin(),
        );
      },
    );
  }
}
