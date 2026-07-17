import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_shell.dart';
import 'bible_provider.dart';
import 'l10n/app_localizations.dart';
import 'notification_service.dart';
import 'prayer_provider.dart';
import 'reading_plans.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable runtime font fetching — fonts must be bundled as assets.
  // Without this, google_fonts throws an unhandled exception when the
  // device cannot reach fonts.gstatic.com (no network / simulator).
  GoogleFonts.config.allowRuntimeFetching = false;
  // Fire-and-forget: sets up the notification plugin and timezone so an
  // already-scheduled daily reminder keeps working across launches.
  NotificationService.instance.init();
  runApp(const BibleApp());
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BibleProvider()..init()),
        ChangeNotifierProvider(create: (_) => ReadingPlanProvider()),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
      ],
      child: Consumer<BibleProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: provider.appLocale,
            themeMode: provider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFFAF8F5), // Soft Cream
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFC8A951), // Elegant Gold
                secondary: Color(0xFFC8A951),
                surface: Color(0xFFFFFFFF), // Pure White
                onSurface: Color(0xFF1A202C), // Deep Navy/Charcoal
                surfaceContainerHighest: Color(0xFFFDF8ED), // Related cream
                outline: Color(0xFFC8A951),
              ),
              fontFamily: 'NotoSansEthiopic',
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFF2C1E16)),
                bodyMedium: TextStyle(color: Color(0xFF2C1E16)),
              ),
              iconTheme: const IconThemeData(color: Color(0xFF2C1E16)),
              dividerTheme: DividerThemeData(
                color: const Color(0xFF2C1E16).withValues(alpha: 0.2),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF000000), // OLED Black
              colorScheme: ColorScheme.dark(
                primary: const Color(0xFFFFD700), // Axios Gold
                secondary: const Color(0xFFFFD700), // Keep gold everywhere
                surface: const Color(0xFF111111),
                onSurface: Colors.white,
                onSurfaceVariant: Colors.white.withValues(alpha: 0.6),
                surfaceContainerHighest: const Color(0xFF222222),
                outline: const Color(0xFFFFD700),
              ),
              fontFamily: 'NotoSansEthiopic',
            ),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
