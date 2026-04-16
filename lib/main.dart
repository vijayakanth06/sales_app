import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';
import 'providers/providers.dart';
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: HomeSalesApp()));
}

class HomeSalesApp extends ConsumerWidget {
  const HomeSalesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return MaterialApp(
      title: 'HomeSales Tracker',
      debugShowCheckedModeBanner: false,
      locale: Locale(lang),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ta'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFFFF6F00),
          error: const Color(0xFFC62828),
          surface: Colors.white,
          background: const Color(0xFFF5F5F5),
        ),
        textTheme: GoogleFonts.notoSansTextTheme().copyWith(
          headlineLarge: GoogleFonts.notoSans(fontSize: 26, fontWeight: FontWeight.bold),
          headlineMedium: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: GoogleFonts.notoSans(fontSize: 18),
          bodyMedium: GoogleFonts.notoSans(fontSize: 16),
          labelLarge: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          minVerticalPadding: 12,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: const Color(0xFF1565C0),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.notoSans(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
      ),
      home: const AppShell(),
    );
  }
}
