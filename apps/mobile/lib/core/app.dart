import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/activities/add_activity_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dogs/dog_list_screen.dart';
import '../features/community/community_screen.dart';
import '../features/dogs/create_dog_screen.dart';
import '../features/weights/weight_list_screen.dart';
import '../features/weights/add_weight_screen.dart';
import '../features/foods/barcode_scan_screen.dart';
import '../features/foods/food_create_screen.dart';
import '../features/meals/meal_create_screen.dart';
import '../features/meals/meals_list_screen.dart';

class DogWatchApp extends StatelessWidget {
  const DogWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DogWatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2CB89D)),
        scaffoldBackgroundColor: const Color(0xFFBFE3D4),
        useMaterial3: true,
        fontFamily: 'RobotoCondensed',
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'RobotoCondensed',
          bodyColor: const Color(0xFF163847),
          displayColor: const Color(0xFF163847),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/dogs': (_) => const DogListScreen(),
        '/community': (_) => const CommunityScreen(),
        '/dogs/create': (_) => const CreateDogScreen(),
        '/weights': (_) => const WeightListScreen(),
        '/weights/create': (_) => const AddWeightScreen(),
        '/scan': (_) => const BarcodeScanScreen(),
        '/foods/create': (_) => const FoodCreateScreen(),
        '/meals/create': (_) => const MealCreateScreen(),
        '/meals': (_) => const MealsListScreen(),
        '/activities/create': (_) => const AddActivityScreen(),
      },
    );
  }
}
