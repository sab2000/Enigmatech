import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:enigmator_techno/file_crypto_helper.dart';
import 'package:enigmator_techno/password_gate.dart';

class EncryptScreen extends StatefulWidget {
  const EncryptScreen({super.key});

  @override
  State<EncryptScreen> createState() => _EncryptScreenState();
}

class _EncryptScreenState extends State<EncryptScreen> {
  // State variables
  Uint8List? _fileBytes;
  String _fileName = '';
  bool _isEncrypting = true;
  bool _isProcessing = false;
  final _passwordController = TextEditingController();
  final _textInputController = TextEditingController();
  String _processedText = '';
  String _lastOperation = '';
  final Random _random = Random();

  // Enhanced text processing parameters
  static const _minSpaces = 1;
  static const _maxSpaces = 1; // Exactly 1 space as requested
  static const _minWordLength = 2;
  static const _maxWordLength = 10;

  Future<void> _processContent() async {
    if ((_fileBytes == null && _textInputController.text.isEmpty) || 
        _passwordController.text.isEmpty) {
      _showSnackBar('Please provide content and password');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_fileBytes != null) {
        // File processing (unchanged)
        final processed = _isEncrypting
            ? await FileCryptoHelper.encryptFile(_fileBytes!, _passwordController.text)
            : await FileCryptoHelper.decryptFile(_fileBytes!, _passwordController.text);
        _downloadFile(processed);
      } else {
        // Enhanced text processing
        final result = _isEncrypting
            ? await _enhancedEncryptText(_textInputController.text)
            : await _enhancedDecryptText(_textInputController.text);
        
        setState(() {
          _processedText = result;
          _lastOperation = _isEncrypting ? 'ENCRYPTED' : 'DECRYPTED';
        });
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<String> _enhancedEncryptText(String text) async {
    // Step 1: Convert all to lowercase (preserving symbols)
    final lowercaseText = text.toLowerCase();
    final bytes = utf8.encode(lowercaseText);
    
    // Step 2: Encrypt
    final encryptedBytes = await FileCryptoHelper.encryptFile(
      Uint8List.fromList(bytes), 
      _passwordController.text
    );
    
    // Step 3: Base64 encode and add single spaces
    final base64Text = base64.encode(encryptedBytes);
    return _addSingleSpaces(base64Text);
  }

  Future<String> _enhancedDecryptText(String text) async {
    // Step 1: Remove all spaces
    final cleanText = text.replaceAll(' ', '');
    final bytes = base64.decode(cleanText);
    
    // Step 2: Decrypt
    final decryptedBytes = await FileCryptoHelper.decryptFile(
      Uint8List.fromList(bytes), 
      _passwordController.text
    );
    
    // Step 3: Return original text with case and symbols
    return utf8.decode(decryptedBytes);
  }

  String _addSingleSpaces(String text) {
    final result = StringBuffer();
    var position = 0;
    
    while (position < text.length) {
      // Add word segment (2-10 chars)
      final wordLength = _minWordLength + _random.nextInt(_maxWordLength - _minWordLength + 1);
      final endPos = min(position + wordLength, text.length);
      result.write(text.substring(position, endPos));
      position = endPos;
      
      // Add exactly 1 space between segments
      if (position < text.length) {
        result.write(' ');
      }
    }
    
    return result.toString();
  }

  void _pickFile() {
    final input = html.FileUploadInputElement()..accept = '*/*';
    input.click();
    input.onChange.listen((e) {
      final file = input.files!.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        setState(() {
          _fileBytes = Uint8List.fromList(reader.result as List<int>);
          _fileName = file.name;
          _processedText = '';
        });
      });
    });
  }

  void _downloadFile(Uint8List bytes) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '${_isEncrypting ? 'encrypted_' : 'decrypted_'}$_fileName')
      ..click();
    html.Url.revokeObjectUrl(url);
    _showSnackBar('File $_lastOperation successfully');
  }

  void _copyToClipboard() {
    html.window.navigator.clipboard?.writeText(_processedText);
    _showSnackBar('Copied to clipboard');
  }

  void _pasteFromClipboard() async {
    final text = await html.window.navigator.clipboard?.readText();
    if (text != null) {
      setState(() => _textInputController.text = text);
    }
  }

  void _clearAll() {
    setState(() {
      _fileBytes = null;
      _fileName = '';
      _textInputController.clear();
      _processedText = '';
    });
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PasswordGate()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ENIGMATOR PRO'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Mode selector card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, size: 30),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          _isEncrypting ? 'ENCRYPTION MODE' : 'DECRYPTION MODE',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isEncrypting,
                        onChanged: (value) => setState(() => _isEncrypting = value),
                        activeColor: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'SECURITY KEY',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                obscureText: true,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 20),

              // File selection card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'FILE PROCESSING',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fileName.isEmpty ? 'No file selected' : _fileName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('SELECT FILE'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Text processing card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'TEXT PROCESSING',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _textInputController,
                        maxLines: 5,
                        minLines: 3,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Enter text here',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.paste),
                                onPressed: _pasteFromClipboard,
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _textInputController.clear(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _processContent,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_isEncrypting ? Icons.lock : Icons.lock_open),
                      label: Text(
                        _isEncrypting ? 'PROCESS CONTENT' : 'RESTORE CONTENT',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.delete),
                    label: const Text('CLEAR ALL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Results section
              if (_processedText.isNotEmpty) ...[
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$_lastOperation RESULT',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: _copyToClipboard,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SelectableText(
                            _processedText,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Characters: ${_processedText.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}