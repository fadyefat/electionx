import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../../Network/election_service.dart';
import 'ResultScreen.dart';
import 'wallet_login_page.dart';
import 'package:web3dart/web3dart.dart';



class Homescreen extends StatefulWidget {
  final ReownAppKitModal appKitModal;


  const Homescreen({super.key, required this.appKitModal});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final ElectionService _electionService = ElectionService();
  List<Map<String, dynamic>> voters = [];
  bool hasVoted = false;
  int votedIndex = -1;
  bool _isLoading = true;
  EthereumAddress? _currentUser;
  EthereumAddress? _adminAddress;
  late ReownAppKitModal _appKitModal;

  @override
  void initState() {
    super.initState();
    _appKitModal = widget.appKitModal;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      await _electionService.init();
      _currentUser = await _electionService.getCurrentAddress(_appKitModal);
      _adminAddress = await _electionService.getOwner();

      // Debugging the addresses
      print("Current User Address: $_currentUser");
      print("Admin Address: $_adminAddress");
      print("🔗 session: ${_appKitModal.session}");
      print("🌐 selectedChain: ${_appKitModal.selectedChain}");

      final candidates = await _electionService.getAllCandidates();
      setState(() {
        voters = candidates;
        _isLoading = false;
      });
    } catch (e, s) {
      print("❌ Error in _initialize: $e");
      print("📌 StackTrace: $s");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to load data: $e')),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _ensureModalInitialized() async {
    if (_appKitModal == null) {
      final modal = ReownAppKitModal(context: context, appKit: widget.appKitModal.appKit!);
      await modal.init();
      setState(() => _appKitModal = modal);
    }
  }


  void addVoter(String walletAddress, String name) async {
    try {
      // ✅ تهيئة المودال إذا مش متعرف
      await _ensureModalInitialized();

      final isConnected = await _appKitModal!.isConnected;
      if (!isConnected) {
        await _appKitModal!.appKit!.connect();
        print("🔗 Wallet connection requested...");
      }

      print("🪪 Session: ${_appKitModal!.session}");
      print("🌐 SelectedChain: ${_appKitModal!.selectedChain}");
      print("👤 Current User Address: $_currentUser");

      // ✅ تنفيذ المعاملة
      final txHash = await _electionService.addCandidate(
        EthereumAddress.fromHex(walletAddress),
        name,
        _appKitModal!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم إضافة المرشح. Tx: $txHash')),
      );

      final updated = await _electionService.getAllCandidates();
      setState(() => voters = updated);
    } catch (e) {
      print("Error: Failed to add candidate: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل في إضافة المرشح: $e')),
      );
    }
  }





  void vote(int index) async {
    try {
      final txHash = await _electionService.vote(voters[index]['name'], _appKitModal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Voted successfully! Tx: $txHash')),
      );
      setState(() {
        hasVoted = true;
        votedIndex = index;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Voting failed: $e')),
      );
    }
  }

  void showAddDialog() {
    String newName = '';
    String newWallet = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Candidate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(hintText: 'Enter wallet address'),
                onChanged: (value) => newName = value,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(hintText: 'Enter name'),
                onChanged: (value) => newWallet = value,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (newName.isNotEmpty && newWallet.isNotEmpty) {
                  addVoter(newName, newWallet);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _checkIfAdminAndShowDialog() {
    // Compare addresses using `toString()`
    if (_currentUser?.toString() == _adminAddress?.toString()) {
      showAddDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Only admin can add candidates.')),
      );
    }
  }

  void confirmVote(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Vote'),
        content: Text('Are you sure you want to vote for ${voters[index]['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              vote(index);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void showVoteWarning(VoidCallback onConfirmed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚠ You can vote only once!')),
    );
    Future.delayed(const Duration(milliseconds: 700), onConfirmed);
  }

  void showResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          modal: _appKitModal,
          electionService: _electionService,
        ),
      ),
    );
  }


  void goToWalletConnect() {
    if (widget.appKitModal.appKit != null) {
      // تحويل النوع
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WalletLoginPage(appKit: widget.appKitModal.appKit as ReownAppKit),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Wallet not connected properly')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('ElectionX', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
            onPressed: goToWalletConnect,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: showResults,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: voters.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    voters[index]['name'],
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!hasVoted) {
                        showVoteWarning(() => confirmVote(index));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('❌ You already voted!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasVoted && votedIndex != index ? Colors.grey : Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Vote'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: _checkIfAdminAndShowDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
