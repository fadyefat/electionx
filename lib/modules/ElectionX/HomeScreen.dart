import 'package:flutter/material.dart';
import '../../Network/election_service.dart';
import 'wallet_login_page.dart';
import 'ResultScreen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  List<Map<String, dynamic>> voters = [];
  bool hasVoted = false;
  int votedIndex = -1;
  late ElectionService electionService;

  @override
  void initState() {
    super.initState();
    electionService = ElectionService();
    electionService.init().then((_) {
      fetchCandidatesAndVotes();
    });
  }

  Future<void> fetchCandidatesAndVotes() async {
    try {
      final names = await electionService.getCandidates();
      final votes = await electionService.getVotes();

      if (names.isNotEmpty && votes.length == names.length) {
        setState(() {
          voters = List.generate(names.length, (i) {
            return {
              'name': names[i],
              'wallet': '', // optional
              'votes': votes[i],
            };
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to fetch data: $e')),
      );
    }
  }

  Future<bool> isOwner() async {
    final owner = await electionService.getOwner();
    return owner.isNotEmpty; // تحقق من وجود مالك فقط
  }

  void addVoter(String name, String walletAddress) async {
    if (walletAddress.isNotEmpty) {
      try {
        final tx = await electionService.getAddCandidateTx(name, walletAddress);
        final receipt = await electionService.sendTransaction(tx);
        if (receipt != null) {
          fetchCandidatesAndVotes(); // Update list after adding
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please connect your wallet')),
      );
    }
  }

  void showAddDialog() async {
    if (!await isOwner()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Only the owner can add candidates')),
      );
      return;
    }

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
                decoration: const InputDecoration(hintText: 'Enter candidate name'),
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
              Navigator.pop(context);
              vote(index);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void vote(int index) async {
    final candidateName = voters[index]['name'];
    // بدلاً من عنوان المحفظة الثابت، يمكن استخدام العنوان الحقيقي هنا
    final walletAddress = await electionService.getWalletAddress();

    if (walletAddress.isNotEmpty) {
      try {
        final tx = await electionService.getVoteTx(candidateName, walletAddress);
        final receipt = await electionService.sendTransaction(tx);
        if (receipt != null) {
          setState(() {
            hasVoted = true;
            votedIndex = index;
            voters[index]['votes'] += 1;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Voted for $candidateName')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Voting failed: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please connect your wallet')),
      );
    }
  }

  void showResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultScreen(voters: voters)),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchCandidatesAndVotes,
          ),
        ],
      ),
      body: voters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
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
                  Expanded(
                    child: Text(
                      '${voters[index]['name']} - ${voters[index]['votes']} votes',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!hasVoted) {
                        confirmVote(index);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('❌ You already voted!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      hasVoted && votedIndex != index ? Colors.grey : Colors.white,
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
