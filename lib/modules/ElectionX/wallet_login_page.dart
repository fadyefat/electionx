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
  Timer? _connectionTimer;
  bool _snackShown = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeAppKit();
  }

  Future<void> _initializeAppKit() async {
    final modal = ReownAppKitModal(context: context, appKit: widget.appKit);
    await modal.init();
    setState(() => _appKitModal = modal);
    _startConnectionCheck();
  }

  void _startConnectionCheck() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    final modal = _appKitModal;
    if (modal == null) return;

    final connected = await modal.isConnected;
    setState(() => _isConnected = connected);

    if (connected && modal.session != null && modal.selectedChain != null) {
      _connectionTimer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Homescreen(appKitModal: modal)),
        );
      }
    } else if (!_snackShown && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('❌ المحفظة غير متصلة بشكل صحيح')));
      _snackShown = true;
    }
  }

  @override
  void dispose() {
    _appKitModal?.dispose();
    _connectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modal = _appKitModal;
    if (modal == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
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
                      appKit: modal,
                      state:  ConnectButtonState.connecting,
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
