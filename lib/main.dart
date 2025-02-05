import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/prayer_list_screen.dart';
import 'theme/theme_provider.dart';
import 'widgets/privacy_consent_dialog.dart';
import 'services/privacy_service.dart';

void main() {
  runApp(const MyAppInitializer());
}

class MyAppInitializer extends StatefulWidget {
  const MyAppInitializer({Key? key}) : super(key: key);

  @override
  _MyAppInitializerState createState() => _MyAppInitializerState();
}

class _MyAppInitializerState extends State<MyAppInitializer> {
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  bool _hasConsent = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if this is the first launch
      final prefs = await SharedPreferences.getInstance();
      _isFirstLaunch = prefs.getBool('first_launch') ?? true;

      // Check privacy consent
      if (_isFirstLaunch) {
        // First launch, we'll show the dialog
        _hasConsent = false;
      } else {
        // Not first launch, check existing consent
        _hasConsent = await PrivacyService.hasUserConsent();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Handle any initialization errors
      print('Initialization error: $e');
      setState(() {
        _isLoading = false;
        _isFirstLaunch = true;
        _hasConsent = false;
      });
    }
  }

  Future<void> _handlePrivacyConsent(BuildContext context) async {
    final result = await showPrivacyConsentDialog(context);
    if (result) {
      await PrivacyService.setUserConsent(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_launch', false);
      
      setState(() {
        _isFirstLaunch = false;
        _hasConsent = true;
      });
    } else {
      // If user doesn't accept, keep first launch state
      await PrivacyService.setUserConsent(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MyApp(
      initialConsent: _hasConsent,
    );
  }
}

class MyApp extends StatelessWidget {
  final bool initialConsent;

  const MyApp({
    Key? key, 
    required this.initialConsent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Orações Respondidas',
          theme: themeProvider.theme,
          home: initialConsent 
            ? PrayerListScreen() 
            : Builder(
                builder: (context) {
                  // Trigger privacy consent dialog on first build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showPrivacyDialog(context);
                  });
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }

  Future<void> _showPrivacyDialog(BuildContext context) async {
    final result = await showPrivacyConsentDialog(context);
    if (result) {
      await PrivacyService.setUserConsent(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_launch', false);

      // Navigate to PrayerListScreen if consent is given
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PrayerListScreen())
      );
    } else {
      // If user doesn't accept, keep first launch state
      await PrivacyService.setUserConsent(false);
    }
  }
}
