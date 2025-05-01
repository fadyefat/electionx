import 'package:flutter/material.dart';
import 'package:reown_appkit/modal/appkit_modal_impl.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3dart/web3dart.dart';

import '../../Network/election_service.dart' show ElectionService;
import '../../Network/siwe_config.dart';
import 'ResultScreen.dart';
import 'wallet_login_page.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }


  Future<void> _initialize() async {
    try {
      // Step 1: Create the appKit instance
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

      // Step 2: Create the modal using the appKit
      _appKitModal = ReownAppKitModal(
        context: context,
        appKit: appKit,
      );

      // Step 3: Initialize the modal
      await _appKitModal.init();

      // Step 4: Initialize the contract logic
      await _electionService.init();
      _currentUser = await _electionService.getCurrentAddress(_appKitModal);
      _adminAddress = await _electionService.getOwner();

      final fetchedVoters = await _electionService.getAllCandidates();

      setState(() {
        voters = fetchedVoters;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Initialization error: $e');
      debugPrint('🔍 Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing: $e')),
      );
    }
  }

  void addVoter(String name, String walletAddress) async {
    try {
      final txHash = await _electionService.addCandidate(
        name,
        EthereumAddress.fromHex(walletAddress),
        _appKitModal,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Candidate added. Tx: $txHash')),
      );
      setState(() {
        voters.add({'name': name, 'wallet': walletAddress, 'votes': 0});
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to add candidate: $e')),
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
          title: const Text('Add Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(hintText: 'Enter project name'),
                onChanged: (value) => newName = value,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(hintText: 'Enter wallet address'),
                onChanged: (value) => newWallet = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.trim().isNotEmpty && newWallet.trim().isNotEmpty) {
                  addVoter(newName.trim(), newWallet.trim());
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
    if (_currentUser == _adminAddress) {
      showAddDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Only the admin can add projects.')),
      );
    }
  }

  void showVoteWarning(VoidCallback onConfirmed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠ You only have one chance to vote!'),
        duration: Duration(milliseconds: 700),
      ),
    );
    Future.delayed(const Duration(milliseconds: 700), onConfirmed);
  }

  void confirmVote(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Vote'),
        content: Text('Are you sure you want to vote for ${voters[index]['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                voters[index]['votes'] += 1;
                hasVoted = true;
                votedIndex = index;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ You voted for ${voters[index]['name']}!')),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void showResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(voters: voters),
      ),
    );
  }

  void goToWalletConnect() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletLoginPage()),
    );
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
                          const SnackBar(
                            content: Text('❌ You already voted!'),
                            duration: Duration(milliseconds: 700),
                          ),
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
