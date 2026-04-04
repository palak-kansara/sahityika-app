import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/isbn_service.dart';
import 'manual_add_book_screen.dart';

class ISBNScannerScreen extends StatefulWidget {
  const ISBNScannerScreen({super.key});

  @override
  State<ISBNScannerScreen> createState() => _ISBNScannerScreenState();
}

class _ISBNScannerScreenState extends State<ISBNScannerScreen> {
  String? scannedISBN;
  bool isScanning = true;
  bool isLoading = false;
  String? message;
  Map<String, dynamic>? book;
  bool _bookNotFound = false;

  bool _isValidISBN(String value) {
    return value.length == 10 || value.length == 13;
  }

  Future<void> _callIsbnApi(String isbn) async {
    setState(() {
      isLoading = true;
      message = null;
      book = null;
      _bookNotFound = false;
    });

    final response = await IsbnService.checkIsbn(isbn);

    setState(() {
      isLoading = false;

      if (response.containsKey("isbn")) {
        // Case 1: Invalid ISBN
        message = response["isbn"][0];
      } else if (response["found"] == false) {
        // Case 3: Book not found
        message = response["message"];
        _bookNotFound = true;
      } else if (response["found"] == true) {
        // Case 2: Book found
        book = response["book"];
      }
    });
  }

  Future<void> _openManualAdd({String? isbn}) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ManualAddBookScreen(prefilledIsbn: isbn),
      ),
    );
    if (!mounted || added != true) return;
    setState(() {
      scannedISBN = null;
      isScanning = true;
      message = null;
      book = null;
      _bookNotFound = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan ISBN"),
        actions: [
          TextButton(
            onPressed: () => _openManualAdd(),
            child: const Text('Manual entry'),
          ),
        ],
      ),
      body: Column(
        children: [
          // CAMERA
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: (capture) {
                if (!isScanning) return;

                final barcode = capture.barcodes.first;
                final String? code = barcode.rawValue;

                if (code != null && _isValidISBN(code)) {
                  setState(() {
                    scannedISBN = code;
                    isScanning = false;
                  });

                  _callIsbnApi(code);
                }
              },
            ),
          ),

          // RESULT AREA
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black12,
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : book != null
                        ? _buildBookInfo()
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  message ?? "Point camera at book barcode",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (_bookNotFound && scannedISBN != null) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _openManualAdd(isbn: scannedISBN),
                                    icon: const Icon(Icons.edit_note),
                                    label: const Text('Enter book details manually'),
                                  ),
                                ],
                              ],
                            ),
                          ),
              ),
            ),
          ),

          // BUTTON
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  scannedISBN = null;
                  isScanning = true;
                  message = null;
                  book = null;
                  _bookNotFound = false;
                });
              },
              child: const Text("Scan Another Book"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          book!["title"],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text("ISBN-13: ${book!["isbn_13"]}"),
        const SizedBox(height: 8),
        Text("Publisher: ${book!["publisher"] ?? "N/A"}"),
      ],
    );
  }
}
