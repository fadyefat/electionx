import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> voters;

  const ResultScreen({super.key, required this.voters});

  @override
  Widget build(BuildContext context) {
    if (voters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('No voters yet.')),
      );
    }

    List<Map<String, dynamic>> sortedVoters = [...voters];
    sortedVoters.sort((a, b) => b['votes'].compareTo(a['votes']));
    final winner = sortedVoters.first;

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
            ...sortedVoters.map((voter) => ListTile(
              title: Text(voter['name']),
              trailing: Text('${voter['votes']} vote(s)'),
            )),
            const Spacer(),
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
