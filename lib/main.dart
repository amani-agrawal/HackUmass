import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NFCStatusScreen(),
    );
  }
}

class NFCStatusScreen extends StatefulWidget {
  const NFCStatusScreen({super.key});

  @override
  _NFCStatusScreenState createState() => _NFCStatusScreenState();
}

class _NFCStatusScreenState extends State<NFCStatusScreen> {
  String _nfcStatus = 'Tap the button to start NFC';
  String name = 'Krishiv Seth'; // Replace with your actual name
  String id = 'ks7118';     // Replace with your actual ID
  String uni_id = 'N17927534';
  Timer? _timeout; // Timer to handle the timeout for "No NFC detected"

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  Future<void> _checkNFCAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _nfcStatus = isAvailable ? 'NFC Available' : 'NFC not Available';
    });
  }

  void _startNFCSession() {
    print("Starting NFC session...");
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        // Cancel the timeout if the tag is detected
        _timeout?.cancel();

        print("Tag detected!");
        setState(() {
          _nfcStatus = 'NFC tag detected! Sending data...';
        });

        // Prepare data payload
        String payload = 'Name: $name, ID: $id, University ID : $uni_id';
        NdefMessage message = NdefMessage([
          NdefRecord.createText(payload),
        ]);

        try {
          var nDef = Ndef.from(tag);
          if (nDef != null && nDef.isWritable) {
            await nDef.write(message);
            setState(() {
              _nfcStatus = 'Data Sent Successfully';
            });
          } else {
            setState(() {
              _nfcStatus = 'Tag is not Writable';
            });
          }
        } catch (e) {
          setState(() {
            _nfcStatus = 'Failed: $e';
          });
        } finally {
          NfcManager.instance.stopSession();
        }
      },
      onError: (NfcError error) async {
        print("Error: ${error.message}");
        setState(() {
          _nfcStatus = 'Error: ${error.message}';
        });
      },
    );

    // Set a timeout for 5 seconds (or any duration you want) using a Timer
    _timeout = Timer(Duration(seconds: 5), () {
      setState(() {
        _nfcStatus = 'No NFC detected';
      });

      // Stop the NFC session
      NfcManager.instance.stopSession();
    });
  }

  @override
  void dispose() {
    // Cancel the timeout if the widget is disposed
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Availability Check')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _nfcStatus,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startNFCSession,
              child: const Text('Start NFC Session'),
            ),
          ],
        ),
      ),
    );
  }
}
