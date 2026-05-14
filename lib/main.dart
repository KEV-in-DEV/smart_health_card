import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_health_card/database/local_storage.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/screens/agent_required_screen.dart';
import 'package:smart_health_card/screens/card_label_screen.dart';
import 'package:smart_health_card/screens/history_screen.dart';
import 'package:smart_health_card/screens/home_screen.dart';
import 'package:smart_health_card/screens/login_screen.dart';
import 'package:smart_health_card/screens/nfc_write_screen.dart';
import 'package:smart_health_card/screens/public_access_screen.dart';
import 'package:smart_health_card/screens/qr_scanner_screen.dart';
import 'package:smart_health_card/screens/read_card_screen.dart';
import 'package:smart_health_card/screens/settings_screen.dart';
import 'package:smart_health_card/screens/write_card_screen.dart';
import 'package:smart_health_card/services/qr_service.dart';
import 'package:smart_health_card/state/app_state.dart';
import 'package:smart_health_card/utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) {
            final isAgentConnected = ref.read(isAgentConnectedProvider);
            Widget guarded(Widget screen) {
              return isAgentConnected ? screen : const AgentRequiredScreen();
            }

            return switch (settings.name) {
              '/' => const PublicAccessScreen(),
              '/login' => const LoginScreen(),
              '/home' => HomeScreen(
                agentName:
                    ref.read(agentSessionProvider)?.name ??
                    (settings.arguments as String?) ??
                    'Agent de santé',
              ),
              '/read-card' => guarded(const ReadCardScreen()),
              '/write-card' => guarded(const WriteCardScreen()),
              '/nfc-write' => guarded(
                NfcWriteScreen(patient: settings.arguments as Patient),
              ),
              '/qr-scanner' => const QrScannerScreen(),
              '/history' => guarded(const HistoryScreen()),
              '/settings' => guarded(const SettingsScreen()),
              '/card-label' => guarded(
                CardLabelScreen(
                  data: (settings.arguments as Map<String, String>?) ?? {},
                ),
              ),
              _ => const PublicAccessScreen(),
            };
          },
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.burkinaGreen,
      brightness: brightness,
      primary: AppColors.burkinaGreen,
      secondary: AppColors.burkinaOrange,
      error: AppColors.emergencyRed,
      surface: isDark ? AppColors.darkSurface : AppColors.white,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: isDark ? AppColors.darkText : AppColors.text,
        displayColor: isDark ? AppColors.darkText : AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.burkinaGreen,
        foregroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.burkinaGreen, width: 2),
        ),
      ),
      dividerColor: isDark ? Colors.white24 : AppColors.border,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.burkinaGreen.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: AppTextSizes.small,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      useMaterial3: true,
    );
  }
}
