import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:reown_appkit/modal/appkit_modal_impl.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';


class ElectionService {
  late Web3Client _client;
  late String _abiCode;
  late EthereumAddress _contractAddress;
  late DeployedContract _contract;

  // Contract functions
  late ContractFunction _addCandidate;
  late ContractFunction _getAllCandidateNames;
  late ContractFunction _owner;
  late ContractFunction _voting;
  late ContractFunction _result;

  ElectionService() {
    _client = Web3Client(
      'https://sepolia.infura.io/v3/8c4396b4abc6465fbcf73f0c58b88293',
      Client(),
    );
  }

  Future<void> init() async {
    _abiCode = await rootBundle.loadString('assets/Election.json');
    _contractAddress = EthereumAddress.fromHex("0xedd570713a1C266A08DA040483cD54E3D84d554d");

    _contract = DeployedContract(
      ContractAbi.fromJson(_abiCode, "Election"),
      _contractAddress,
    );

    _addCandidate = _contract.function("AddConduation");
    _getAllCandidateNames = _contract.function("getAllCandidateNames");
    _owner = _contract.function("owner");
    _voting = _contract.function("voting");
    _result = _contract.function("getResult");
  }

  Future<String> readResult() async {
    // This will perform a call (no signature) to result(),
    // and will revert if voting not ended or caller ≠ owner.
    final response = await _client.call(
      contract: _contract,
      function: _result,
      params: [],
    );
    return response.first as String;
  }
  // ✅ جلب كل أسماء المرشحين وعدد أصواتهم
  Future<List<Map<String, dynamic>>> getAllCandidates() async {
    final names = await _client.call(
      contract: _contract,
      function: _getAllCandidateNames,
      params: [],
    );


    final nameList = (names[0] as List).map((e) => e.toString()).toList();


    List<Map<String, dynamic>> candidates = [];

    for (int i = 0; i < nameList.length; i++) {
      candidates.add({
        'name': nameList[i],
      });
    }

    return candidates;
  }

  // ✅ جلب عدد الأصوات فقط (لو أردت عرضهم مستقبلاً بشكل منفصل)


  // ✅ جلب العنوان الحالي من الجلسة
  Future<EthereumAddress> getCurrentAddress(ReownAppKitModal modal) async {
    final session = modal.session;
    final selectedChain = modal.selectedChain;

    if (session == null || selectedChain == null) {
      throw Exception("Session or chain not initialized.");
    }

    final namespace = ReownAppKitModalNetworks.getNamespaceForChainId(selectedChain.chainId);
    final addressHex = session.getAddress(namespace);

    if (addressHex == null) {
      throw Exception("No address found in session.");
    }

    return EthereumAddress.fromHex(addressHex);
  }

  // ✅ جلب عنوان الـ owner من العقد
  Future<EthereumAddress> getOwner() async {
    final result = await _client.call(
      contract: _contract,
      function: _owner,
      params: [],
    );
    return result.first as EthereumAddress;
  }

  // ✅ إضافة مرشح جديد (فقط من الـ owner - يتحقق العقد من الصلاحية)
  Future<String> addCandidate(EthereumAddress candidateAddress, String name, ReownAppKitModal modal) async {
    print("🚀 Starting addCandidate...");

    // التحقق من الجلسة والسلسلة
    final session = modal.session;
    final selectedChain = modal.selectedChain;

    if (session == null) {
      print("❌ Error: session is null");
      throw Exception("Session not initialized. Did you call connectWallet?");
    }

    if (selectedChain == null) {
      print("❌ Error: selectedChain is null");
      throw Exception("Chain not selected. Did you select a chain?");
    }

    print("✅ Session and Chain are initialized");

    // التحقق من namespace والعنوان
    final namespace = ReownAppKitModalNetworks.getNamespaceForChainId(selectedChain.chainId);
    final from = session.getAddress(namespace);

    if (from == null) {
      print("❌ Error: no address found in session");
      throw Exception("No address found in session.");
    }

    print("📤 Preparing transaction from: $from");
    print("📍 To contract: ${_contractAddress.hex}");
    print("👤 Candidate: ${candidateAddress.hex}, Name: $name");

    final data = _client.encodeFunctionCall(_addCandidate, [candidateAddress, name]);

    // إضافة شرط لتأكيد chainId = Sepolia
    if (selectedChain.chainId != 'eip155:11155111') {
      print("❌ Error: You are not connected to Sepolia chain.");
      throw Exception("Wrong network. Please connect to Sepolia.");
    }

    try {
      print("🦊 Requesting signature from MetaMask...");

      final response = await modal.request(
        topic: session.topic,
        chainId: selectedChain.chainId,
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [
            {
              'from': from,
              'to': _contractAddress.hex,
              'data': data,
            }
          ],
        ),
      );

      print("✅ Transaction sent successfully! Hash: $response");
      return response as String;
    } catch (e) {
      print("❌ Transaction Error: $e");
      rethrow;
    }
  }
  // ✅ تنفيذ تصويت لصالح مرشح معين
  Future<String> vote(String candidateName, ReownAppKitModal modal) async {
    final session = modal.session;
    final selectedChain = modal.selectedChain;

    if (session == null || selectedChain == null) {
      throw Exception("Session or chain not initialized.");
    }

    final namespace = ReownAppKitModalNetworks.getNamespaceForChainId(selectedChain.chainId);
    final from = session.getAddress(namespace);
    if (from == null) throw Exception("No address found in session.");

    final data = _client.encodeFunctionCall(_voting, [candidateName]);

    final response = await modal.request(
      topic: session.topic,
      chainId: selectedChain.chainId,
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [
          {
            'from': from,
            'to': _contractAddress.hex,
            'data': data,
          }
        ],
      ),
    );

    return response as String;
  }

  // ✅ جلب نتائج التصويت (حسب دالة result في العقد)
  Future<String> getResult(ReownAppKitModal modal) async {
    await init(); // تأكد إن init بيحمل abi ويجهز contract

    final session = modal.session;
    final selectedChain = modal.selectedChain;

    if (session == null || selectedChain == null) {
      throw Exception("Session or chain not initialized.");
    }

    final namespace = ReownAppKitModalNetworks.getNamespaceForChainId(selectedChain.chainId);
    final from = session.getAddress(namespace);
    if (from == null) throw Exception("No address found in session.");

    final getResultFunction = _contract.function('getResult');

    final result = await _client.call(
      contract: _contract,
      function: getResultFunction,
      params: [],
      sender: EthereumAddress.fromHex(from),
    );

    return result.first as String;
  }
}

// ✅ Extension لسهولة تشفير البيانات للدوال
extension ABIEncoding on Web3Client {
  String encodeFunctionCall(ContractFunction function, List<dynamic> params) {
    final encoded = function.encodeCall(params);
    return '0x' + bytesToHex(encoded, include0x: false);
  }
}