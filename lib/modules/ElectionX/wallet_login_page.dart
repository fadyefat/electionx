import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'HomeScreen.dart';

class WalletLoginPage extends StatefulWidget {
  final ReownAppKit appKit;
  const WalletLoginPage({super.key, required this.appKit});

  @override
  State<WalletLoginPage> createState() => _WalletLoginPageState();
}

class _WalletLoginPageState extends State<WalletLoginPage> {
  ReownAppKitModal? _appKitModal;
  bool? _isConnected;
  Timer? _connectionTimer;
  bool _snackShown = false; // ✅ Prevent snackbar spam

  @override
  void initState() {
    super.initState();
    _initializeAppKit();
  }

  Future<void> _initializeAppKit() async {
    if (_appKitModal != null) return;

    final appKit = widget.appKit;

    final appKitModal = ReownAppKitModal(
      context: context,
      appKit: appKit,
    );

    await appKitModal.init();

    setState(() {
      _appKitModal = appKitModal;
    });

    _startConnectionCheck();
  }

  void _startConnectionCheck() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    final isConnected = await _appKitModal?.isConnected ?? false;

    setState(() {
      _isConnected = isConnected;
    });

    if (_isConnected == true &&
        _appKitModal?.session != null &&
        _appKitModal?.selectedChain != null) {
      _connectionTimer?.cancel();
      await Future.delayed(const Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Homescreen(appKitModal: _appKitModal!),
        ),
      );
    } else {
      if (!_snackShown) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ المحفظة غير متصلة بشكل صحيح')),
        );
        _snackShown = true;
      }
    }
  }

  @override
  void dispose() {
    _appKitModal?.dispose();
    _connectionTimer?.cancel(); // ✅ Dispose timer properly
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
                      state: (_isConnected ?? false)
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
