import 'package:flutter/material.dart';
import '../../Network/wallet_login_page.dart';
import 'ResultScreen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  List<Map<String, dynamic>> voters = [];
  bool hasVoted = false; // Track if user already voted
  int votedIndex = -1;   // Track which project the user voted for

  void addVoter(String name, String walletAddress) {
    setState(() {
      voters.add({'name': name, 'wallet': walletAddress, 'votes': 0});
    });
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
                onChanged: (value) {
                  newName = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(hintText: 'Enter wallet address'),
                onChanged: (value) {
                  newWallet = value;
                },
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
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
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
            onPressed: () => Navigator.pop(context), // No
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                voters[index]['votes'] += 1;
                hasVoted = true;
                votedIndex = index;
              });
              Navigator.pop(context); // Close confirm dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ You voted for ${voters[index]['name']}!'),
                  duration: const Duration(milliseconds: 700),
                ),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {},
        ),
        centerTitle: true,
        title: const Text(
          'ElectionX',
          style: TextStyle(color: Colors.white),
        ),
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
        onPressed: showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
