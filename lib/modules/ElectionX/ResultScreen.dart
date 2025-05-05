import 'package:flutter/material.dart';
import 'package:reown_appkit/modal/appkit_modal_impl.dart';
import '../../Network/election_service.dart';

class ResultScreen extends StatefulWidget {
  final ReownAppKitModal modal;
  final ElectionService electionService;

  const ResultScreen({
    Key? key,
    required this.modal,
    required this.electionService,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  bool _isOwner = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    await widget.electionService.init();
    final current = await widget.electionService.getCurrentAddress(widget.modal);
    final owner = await widget.electionService.getOwner();

    setState(() {
      _isOwner = current == owner;
    });

    if (_isOwner) {
      try {
        _result = await widget.electionService.readResult();
      } catch (e) {
        // Voting still ongoing or revert
        _result = 'Voting is still ongoing.';
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isOwner) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Results')),
        body: const Center(
          child: Text(
            '⛔️ النتائج متاحة للمالك فقط حالياً.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Results')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Voting Results:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Text(
                _result!,
                style: const TextStyle(fontSize: 20, color: Colors.orange),
              )
            else
              const Text(
                'لا توجد نتيجة بعد.',
                style: TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
