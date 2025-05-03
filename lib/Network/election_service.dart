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
    _contractAddress = EthereumAddress.fromHex("0x2046f08936Eb60DB5fce4bB6DcE34dEED84480a0");

    _contract = DeployedContract(
      ContractAbi.fromJson(_abiCode, "Election"),
      _contractAddress,
    );

    _addCandidate = _contract.function("AddConduation");
    _getAllCandidateNames = _contract.function("getAllCandidateNames");
    _owner = _contract.function("owner");
    _voting = _contract.function("voting");
    _result = _contract.function("result");
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
  Future<String> addCandidate(String name, EthereumAddress wallet, ReownAppKitModal modal) async {
    final session = modal.session;
    final selectedChain = modal.selectedChain;

    if (session == null || selectedChain == null) {
      throw Exception("Session or chain not initialized.");
    }

    final namespace = ReownAppKitModalNetworks.getNamespaceForChainId(selectedChain.chainId);
    final from = session.getAddress(namespace);
    if (from == null) throw Exception("No address found in session.");

    final data = _client.encodeFunctionCall(_addCandidate, [wallet, name]);

    final response = await modal.request(
      topic: session.topic,
      chainId: 'eip155:${selectedChain.chainId}',
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
      chainId: 'eip155:${selectedChain.chainId}',
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
    final session = modal.session;
    final selectedChain = modal.selectedChain;

    if (session == null || selectedChain == null) {
      throw Exception("Session or chain not initialized.");
    }

    final namespace = ReownAppKitModalNetworks.getNamespaceForChainId(selectedChain.chainId);
    final from = session.getAddress(namespace);
    if (from == null) throw Exception("No address found in session.");

    final data = _client.encodeFunctionCall(_result, []);

    final response = await modal.request(
      topic: session.topic,
      chainId: 'eip155:${selectedChain.chainId}',
      request: SessionRequestParams(
        method: 'eth_call',
        params: [
          {
            'from': from,
            'to': _contractAddress.hex,
            'data': data,
          },
          "latest"
        ],
      ),
    );

    return response.toString();
  }
}

// ✅ Extension لسهولة تشفير البيانات للدوال
extension ABIEncoding on Web3Client {
  String encodeFunctionCall(ContractFunction function, List<dynamic> params) {
    final encoded = function.encodeCall(params);
    return '0x' + bytesToHex(encoded, include0x: false);
  }
}
