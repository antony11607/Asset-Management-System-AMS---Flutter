import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app_routes.dart';
import 'admin_dashboard.dart';
import 'login_page.dart';
import 'pages/admin_profile_page.dart';
import 'pages/user_asset_requests_page.dart';
import 'pages/user_my_assets_page.dart';
import 'pages/user_pages.dart';
import 'pages/user_profile_page.dart';
import 'register_page.dart';
import 'service_provider_dashboard.dart';
import 'widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific configuration
  if (kIsWeb) {
    // Web platform requires explicit FirebaseOptions
    // Configuration extracted from google-services.json
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA8OQNqMDUBdHxdJRBbENXM5u9qsPaq4TA",
        authDomain: "asset-ms-71f11.firebaseapp.com",
        projectId: "asset-ms-71f11",
        storageBucket: "asset-ms-71f11.firebasestorage.app",
        messagingSenderId: "83595668969",
        appId: "1:83595668969:web:85a61177c3e80727f4af78",
      ),
    );
  } else {
    // Mobile platforms (Android/iOS) use google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asset Management System',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2555FF),
          onPrimary: Colors.white,
          secondary: Color(0xFF1F3AC4),
          onSecondary: Colors.white,
          surface: Color(0xFFF4F7FF),
          onSurface: Color(0xFF0F172A),
          outline: Color(0xFF8B95A1),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FF),
        useMaterial3: true,
      ),
      home: const SplashLauncher(),
      routes: {
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.register: (context) => const RegisterPage(),
        AppRoutes.admin: (context) => const AdminDashboard(),
        AppRoutes.adminProfile: (context) => const AdminProfilePage(),
        AppRoutes.serviceProvider: (context) => const ServiceProviderDashboard(),
        AppRoutes.serviceProviderProfile: (context) => const ServiceProviderProfilePage(),
        AppRoutes.serviceProviderSettings: (context) => const ServiceProviderSettingsPage(),
        AppRoutes.userDashboard: (context) => const UserDashboardPage(),
        AppRoutes.userMyAssets: (context) => const UserMyAssetsPage(),
        AppRoutes.userAssets: (context) => const UserAssetsPage(),
        AppRoutes.userRequests: (context) => const UserAssetRequestsPage(),
        AppRoutes.userProfile: (context) => const UserProfilePage(),
        AppRoutes.userSettings: (context) => const UserSettingsPage(),
      },
    );
  }
}

// Authentication State Listener
class AuthStateListener extends StatelessWidget {
  const AuthStateListener({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, navigate to appropriate dashboard
          // The login page will handle role-based routing
          return const LoginPage();
        }
        
        // User is not signed in, show login page
        return const LoginPage();
      },
    );
  }
}

class SplashLauncher extends StatefulWidget {
  const SplashLauncher({super.key});

  @override
  State<SplashLauncher> createState() => _SplashLauncherState();
}

class _SplashLauncherState extends State<SplashLauncher> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      AppRoutes.go(context, AppRoutes.login, replace: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}