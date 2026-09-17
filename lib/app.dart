import 'package:flutter/material.dart';
import 'package:mobileapp/constants/colors.dart';
import 'package:mobileapp/routes/app_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaptopHarbor',
      debugShowCheckedModeBanner: false,

      // ⚠️ MUST BE '/'
      initialRoute: AppRoutes.splash,

      routes: AppRoutes.getRoutes(),

      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: AppColors.deepBlack,
        primaryColor: AppColors.richGold,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.deepBlack,
          foregroundColor: AppColors.lightGold,
          elevation: 0,
        ),
        cardColor: AppColors.cardBlack,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.softGold),
          bodyMedium: TextStyle(color: AppColors.softGold),
        ),
      ),
    );
  }
}
