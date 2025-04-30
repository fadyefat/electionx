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
            Expanded( // Makes the list scrollable
              child: ListView.builder(
                itemCount: sortedVoters.length,
                itemBuilder: (context, index) {
                  final voter = sortedVoters[index];
                  return ListTile(
                    leading: Text(
                      '${index + 1}', // Show 1,2,3,4 beside name
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    title: Text(
                      voter['name'],
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: Text(
                      '${voter['votes']} vote(s)',
                      style: const TextStyle(fontSize: 16),
                    ),
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
