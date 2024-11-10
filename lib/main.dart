import 'dart:async';
import 'dart:convert'; // Import to use utf8 decoding
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
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

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
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

            setState(() {
              _nfcData = 'Read Data: $payload';
            });
            print('NFC Read Data: $payload');
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
  void dispose() {
    _timeout?.cancel();
    super.dispose();
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
