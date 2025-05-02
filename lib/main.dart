import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'modules/ElectionX/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ReownAppKit globally before the app starts
  final appKit = await ReownAppKit.createInstance(
    projectId: '47a573f8635bdc22adf4030bdca85210',
    metadata: const PairingMetadata(
      name: 'ElectionX',
      description: 'Voting app using MetaMask login',
      url: 'https://github.com',
      icons: [
        'https://raw.githubusercontent.com/MetaMask/brand-resources/master/SVG/metamask-fox.svg',
      ],
    ),
  );

  runApp(MyApp(appKit: appKit));  // مرّر الـ appKit هنا
}

class MyApp extends StatelessWidget {
  final ReownAppKit appKit;
  const MyApp({super.key, required this.appKit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ElectionX',
      theme: ThemeData.dark(),
      home: SplashScreen(appKit: appKit), // ⬅️ مررها لأي شاشة تبدأ بها
    );
  }
}
