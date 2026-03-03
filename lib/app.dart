import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/water/bloc/water_bloc.dart';
import 'features/water/bloc/water_state.dart';
import 'features/water/screens/home_screen.dart';
import 'features/water/screens/onboarding_screen.dart';
import 'l10n/app_localizations.dart';

class WaterReminderApp extends StatelessWidget {
  const WaterReminderApp({super.key});

  static const Color primaryWaterLight = Color(0xFF4FC3F7);
  static const Color primaryWater = Color(0xFF03A9F4);
  static const Color primaryWaterDark = Color(0xFF0288D1);
  static const Color deepWater = Color(0xFF01579B);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaterBloc, WaterState>(
      builder: (context, state) {
        return MaterialApp(
          title: 'Daily Water Reminder',
          debugShowCheckedModeBanner: false,
          locale: Locale(state.locale),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('gu'),
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryWater,
              primary: primaryWater,
              secondary: primaryWaterLight,
              surface: const Color(0xFFF0F9FF),
              error: const Color(0xFFEF5350),
            ),
            scaffoldBackgroundColor: const Color(0xFFF0F9FF),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: const TextStyle(
                color: deepWater,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              iconTheme: const IconThemeData(color: deepWater),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: primaryWater,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryWater,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryWaterDark,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFE3F2FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryWater, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: primaryWater,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              elevation: 8,
            ),
            tabBarTheme: const TabBarThemeData(
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xB3FFFFFF),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: Colors.white, width: 3),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: deepWater,
              contentTextStyle: const TextStyle(color: Colors.white),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
            ),
            sliderTheme: SliderThemeData(
              activeTrackColor: primaryWater,
              inactiveTrackColor: const Color(0xFFBBDEFB),
              thumbColor: primaryWaterDark,
              overlayColor: primaryWater.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(),
              overlayShape: const RoundSliderOverlayShape(),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: primaryWater,
              linearTrackColor: Color(0xFFE1F5FE),
            ),
            iconTheme: const IconThemeData(
              color: primaryWaterDark,
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: deepWater,
                letterSpacing: -1,
              ),
              headlineMedium: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: deepWater,
                letterSpacing: -0.5,
              ),
              titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryWaterDark,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                color: Color(0xFF37474F),
                letterSpacing: 0.2,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                color: Color(0xFF546E7A),
              ),
            ),
          ),
          home: state.onboardingCompleted
              ? const HomeScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }

  // Gradient decorations for water theme
  static BoxDecoration getWaterGradientBox({double borderRadius = 20}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryWaterLight, primaryWater],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: primaryWater.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration getGlassBox({Color color = Colors.white}) {
    return BoxDecoration(
      color: color.withOpacity(0.85),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
