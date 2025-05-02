import 'package:flutter/material.dart';
import '../../Network/election_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required List<Map<String, dynamic>> voters});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ElectionService _electionService = ElectionService();
  List<Map<String, dynamic>> voters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    await _electionService.init();

    final result = await _electionService.getAllCandidates();
    setState(() {
      voters = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Results')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (voters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Results')),
        body: const Center(child: Text('No candidates yet.')),
      );
    }

    voters.sort((a, b) => b['votes'].compareTo(a['votes']));
    final winner = voters.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voting Results:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: voters.length,
                itemBuilder: (context, index) {
                  final voter = voters[index];
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(voter['name']),
                    trailing: Text('${voter['votes']} vote(s)'),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '🏆 Winner: ${winner['name']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
