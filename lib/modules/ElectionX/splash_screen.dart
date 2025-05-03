import 'package:flutter/material.dart';
import 'dart:async';
import 'package:reown_appkit/reown_appkit.dart'; // مهم
import 'wallet_login_page.dart';

class SplashScreen extends StatefulWidget {
  final ReownAppKit appKit;

  const SplashScreen({super.key, required this.appKit});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WalletLoginPage(appKit: widget.appKit), // تمرير الـ appKit هنا
        ),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.how_to_vote,
              color: Colors.white,
              size: 100,
            ),
            SizedBox(height: 20),
            Text(
              'ElectionX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
