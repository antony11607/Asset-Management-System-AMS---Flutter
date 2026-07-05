import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final String logoPath;
  final String subtitle;
  final Color backgroundColor;

  const SplashScreen({
    super.key,
    this.logoPath = 'assets/logo.png',
    this.subtitle = 'Developed by ShaTechX',
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                logoPath,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
