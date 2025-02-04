import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/prayer_list_screen.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Orações Respondidas',
          theme: themeProvider.theme,
          debugShowCheckedModeBanner: false,
          home: const PrayerListScreen(),
        ),
      ),
    );
  }
}
