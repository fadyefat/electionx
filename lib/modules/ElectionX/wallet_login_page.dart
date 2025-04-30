import 'dart:async'; // Import to use Timer
import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

import 'HomeScreen.dart';

class WalletLoginPage extends StatefulWidget {
  const WalletLoginPage({super.key});

  @override
  State<WalletLoginPage> createState() => _WalletLoginPageState();
}

class _WalletLoginPageState extends State<WalletLoginPage> {
  ReownAppKitModal? _appKitModal;
  bool? _isConnected;
  Timer? _connectionTimer; // Declare a Timer

  @override

  void initState() {
    super.initState();
    _initializeAppKit();
  }

  // Initialize AppKit
  Future<void> _initializeAppKit() async {
    if (_appKitModal != null) return; // ✅ prevent reinitialization

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

    final appKitModal = ReownAppKitModal(
      context: context,
      appKit: appKit,
    );

    await appKitModal.init();

    setState(() {
      _appKitModal = appKitModal;
    });

    // Start checking the connection status every 5 seconds
    _startConnectionCheck();
  }

  // Start the timer to check the connection every 5 seconds
  void _startConnectionCheck() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnection();
    });
  }

  // Check if the wallet is connected
  Future<void> _checkConnection() async {
    final isConnected = await _appKitModal?.isConnected ?? false;
    setState(() {
      _isConnected = isConnected;
    });

    // If connected, navigate to the next screen
    if (_isConnected == true) {
      // Stop the timer to avoid continuous checks
      _connectionTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homescreen()),
      );
    }
  }


  @override
  void dispose() {
    _appKitModal?.dispose(); // تضمن إنه ما يفضل شغال لما تخرج من الصفحة
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (_appKitModal == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ElectionX',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Let's get you connected",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AppKitModalConnectButton(
                      appKit: _appKitModal!,
                      state: _isConnected == true
                          ? ConnectButtonState.connected
                          : ConnectButtonState.disabled,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
