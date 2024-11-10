import 'dart:async';
import 'dart:convert'; // Import to use utf8 decoding
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'mongodb.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MongoDatabase.connect();
  runApp(const NFCTagReaderApp());
}

class NFCTagReaderApp extends StatelessWidget {
  const NFCTagReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NFCReaderScreen(),
    );
  }
}

class NFCReaderScreen extends StatefulWidget {
  const NFCReaderScreen({super.key});

  @override
  _NFCReaderScreenState createState() => _NFCReaderScreenState();
}

class _NFCReaderScreenState extends State<NFCReaderScreen> {
  String _nfcData = 'Tap the button to start reading NFC';

  Timer? _timeout; // Timer to handle a read timeout

  final _w3mService = W3MService(
    projectId: '3f504b438c5f4bc99a18a91d05b074e8', 
    metadata: const PairingMetadata(
      name: 'Web3Modal Flutter Example',
      description: 'Web3Modal Flutter Example',
      url: 'https://www.walletconnect.com/',
      icons: ['https://walletconnect.com/walletconnect-logo.png'],
      redirect: Redirect(
        native: 'flutterdapp://',
        universal: 'https://www.walletconnect.com',
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
     _w3mService.init();

  }

Future<void> callStoreHashFunction() async {
    try {
      // The contract ABI and address
      final deployedContract = DeployedContract(
        ContractAbi.fromJson(
          jsonEncode([
            {
              "inputs": [
                {"internalType": "string", "name": "_netId", "type": "string"},
                {"internalType": "string", "name": "_locationHash", "type": "string"}
              ],
              "name": "storeHash",
              "outputs": [],
              "stateMutability": "nonpayable",
              "type": "function"
            }
          ]), // ABI object for the contract
          'DigitalCardAccess', // Your contract name
        ),
        EthereumAddress.fromHex('0x1D8fF279B26171d48b9B8FfAdF1b979F0B144D22'), // Replace with your contract address
      );


      // Call the storeHash function with dummy values
      _w3mService.requestWriteContract(
        topic: _w3mService.session!.topic.toString(),
        chainId: 'eip155:1', // Using Ethereum mainnet (eip155:1), change it if using testnets
        deployedContract: deployedContract,
        functionName: 'storeHash',
        parameters: ['12345', 'abcde12345'],
        transaction: Transaction(
          from: EthereumAddress.fromHex('0x765434567566'),
        ),
      );

      print('Hash stored successfully');
    } catch (e) {
      print('Error calling storeHash function: $e');
    }
  }
  Future<void> _checkNFCAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _nfcData = isAvailable ? 'NFC Available' : 'NFC not Available';
    });
  }

  void _startReadingNFCSession() {
    print("Starting NFC read session...");

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        _timeout?.cancel();

        print("NFC tag detected!");
        setState(() {
          _nfcData = 'NFC tag detected! Reading data...';
        });

        try {
          var nDef = Ndef.from(tag);
          if (nDef != null && nDef.cachedMessage != null) {
            // Retrieve the payload as Uint8List and convert to String
            Uint8List payloadBytes = nDef.cachedMessage!.records.first.payload;
            String payload = utf8.decode(payloadBytes.sublist(3)); // Skip language code bytes
            var details=payload.split(", ");
            String studentId = details[1].substring(4);
            String location = "11"; //will change onevery receptor 
            var student = await MongoDatabase.getStudentById(studentId);
            setState(() {
              _nfcData = student != null && student['Location']==true? 'Location is false or student not found': 
              'Location is true for ${details[0].substring(6)} (ID: $studentId)';
            });
          } else {
            setState(() {
              _nfcData = 'No NDEF message found';
            });
          }
        } catch (e) {
          setState(() {
            _nfcData = 'Failed to read: $e';
          });
        } finally {
          NfcManager.instance.stopSession();
        }
      },
      onError: (NfcError error) async {
        setState(() {
          _nfcData = 'Error: ${error.message}';
        });
      },
    );

    _timeout = Timer(Duration(seconds: 5), () {
      setState(() {
        _nfcData = 'No NFC detected';
      });
      NfcManager.instance.stopSession();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Reader')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _nfcData,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startReadingNFCSession,
              child: const Text('Start Reading NFC'),
            ),
          ],
        ),
      ),
    );
  }
}