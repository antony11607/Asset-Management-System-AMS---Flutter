import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const admin = '/admin';
  static const adminProfile = '/admin/profile';
  static const serviceProvider = '/service-provider';
  static const serviceProviderProfile = '/service-provider/profile';
  static const serviceProviderSettings = '/service-provider/settings';
  static const userDashboard = '/user/dashboard';
  static const userAssets = '/user/assets';
  static const userMyAssets = '/user/my-assets';
  static const userRequests = '/user/requests';
  static const userProfile = '/user/profile';
  static const userSettings = '/user/settings';

  static void go(
    BuildContext context,
    String routeName, {
    bool clearStack = false,
    bool replace = false,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == routeName) return;

    if (clearStack) {
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
      return;
    }

    if (replace && currentRoute != null) {
      Navigator.of(context).pushReplacementNamed(routeName);
      return;
    }

    Navigator.of(context).pushNamed(routeName);
  }

  static void closeDrawerAndGo(BuildContext context, String routeName) {
    Navigator.of(context).pop();
    go(context, routeName, replace: true);
  }

  static Future<void> logout(BuildContext context) async {
    try {
      // Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Even if Firebase sign out fails, still navigate to login
      debugPrint('Error during Firebase sign out: $e');
    } finally {
      // Always navigate to login page
      if (context.mounted) {
        go(context, login, clearStack: true);
      }
    }
  }

  static int userBottomIndex(String routeName) {
    return switch (routeName) {
      userDashboard => 0,
      userAssets => 1,
      userMyAssets => 2,
      userRequests => 3,
      userProfile => 4,
      userSettings => -1,
      _ => 0,
    };
  }

  static String userRouteForBottomIndex(int index) {
    return switch (index) {
      0 => userDashboard,
      1 => userAssets,
      2 => userMyAssets,
      3 => userRequests,
      4 => userProfile,
      _ => userDashboard,
    };
  }
}
