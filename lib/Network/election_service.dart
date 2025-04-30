import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class ElectionService {
  final String rpcUrl = "https://sepolia.infura.io/v3/8c4396b4abc6465fbcf73f0c58b88293";
  final String contractAddress = "0x2046f08936Eb60DB5fce4bB6DcE34dEED84480a0";

  final String abi = '''[
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_candidate",
				"type": "address"
			},
			{
				"internalType": "string",
				"name": "_name",
				"type": "string"
			}
		],
		"name": "AddConduation",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "result",
		"outputs": [
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_duration",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "string",
				"name": "_nam",
				"type": "string"
			}
		],
		"name": "voting",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "get_NumOfVoting",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getAllCandidateNames",
		"outputs": [
			{
				"internalType": "string[]",
				"name": "",
				"type": "string[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
]'''; // اختصرته هنا للتنظيم

  late Web3Client client;
  late EthereumAddress contractAddr;
  late DeployedContract contract;

  ElectionService() {
    client = Web3Client(rpcUrl, Client());
    contractAddr = EthereumAddress.fromHex(contractAddress);
  }

  Future<void> init() async {
    contract = DeployedContract(
      ContractAbi.fromJson(abi, "Elections"),
      contractAddr,
    );
  }

  Future<Transaction> getAddCandidateTx(String name, String walletAddress, EthereumAddress sender) async {
    final function = contract.function("AddConduation");
    return Transaction.callContract(
      contract: contract,
      function: function,
      from: sender,
      parameters: [EthereumAddress.fromHex(walletAddress), name],
    );
  }

  Future<Transaction> getVoteTx(String name, EthereumAddress sender) async {
    final function = contract.function("voting");
    return Transaction.callContract(
      contract: contract,
      function: function,
      from: sender,
      parameters: [name],
    );
  }

  Future<Transaction> getResultTx(EthereumAddress sender) async {
    final function = contract.function("result");
    return Transaction.callContract(
      contract: contract,
      function: function,
      from: sender,
      parameters: [],
    );
  }

  Future<List<BigInt>> getVotes() async {
    final function = contract.function("get_NumOfVoting");
    final result = await client.call(
      contract: contract,
      function: function,
      params: [],
    );
    if (result.isNotEmpty && result.first is List) {
      return List<BigInt>.from(result.first);
    }
    return [];
  }

  Future<List<String>> getCandidates() async {
    final function = contract.function("getAllCandidateNames");
    final result = await client.call(
      contract: contract,
      function: function,
      params: [],
    );
    if (result.isNotEmpty && result.first is List) {
      return List<String>.from(result.first);
    }
    return [];
  }

  EthereumAddress getAddressFromHex(String address) {
    return EthereumAddress.fromHex(address);
  }
}
