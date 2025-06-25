import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:enigmatech/file_crypto_helper.dart';
import 'package:enigmatech/password_gate.dart';

class EncryptScreen extends StatefulWidget {
  const EncryptScreen({super.key});

  @override
  State<EncryptScreen> createState() => _EncryptScreenState();
}

class _EncryptScreenState extends State<EncryptScreen> with SingleTickerProviderStateMixin {
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
  
  // New features state
  bool _processFileMode = true;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  bool _showProcessingAnimation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.5, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  // Main processing function
  Future<void> _processContent() async {
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Security Key is required');
      return;
    }

    if ((_processFileMode && _fileBytes == null) || 
        (!_processFileMode && _textInputController.text.isEmpty)) {
      _showSnackBar('Please provide content to process');
      return;
    }

    setState(() {
      _isProcessing = true;
      _showProcessingAnimation = true;
    });

    try {
      if (_processFileMode) {
        final processed = _isEncrypting
            ? await FileCryptoHelper.encryptFile(_fileBytes!, _passwordController.text)
            : await FileCryptoHelper.decryptFile(_fileBytes!, _passwordController.text);
        _downloadFile(processed);
      } else {
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
      setState(() {
        _isProcessing = false;
        _showProcessingAnimation = false;
      });
    }
  }

  // Enhanced text processing
  Future<String> _enhancedEncryptText(String text) async {
    final bytes = utf8.encode(text.toLowerCase());
    final encryptedBytes = await FileCryptoHelper.encryptFile(
      Uint8List.fromList(bytes), 
      _passwordController.text
    );
    return _addRandomSpaces(base64.encode(encryptedBytes));
  }

  Future<String> _enhancedDecryptText(String text) async {
    final cleanText = text.replaceAll(' ', '');
    final bytes = base64.decode(cleanText);
    final decryptedBytes = await FileCryptoHelper.decryptFile(
      Uint8List.fromList(bytes), 
      _passwordController.text
    );
    return utf8.decode(decryptedBytes);
  }

  String _addRandomSpaces(String text) {
    final result = StringBuffer();
    var position = 0;
    while (position < text.length) {
      final endPos = min(position + 2 + _random.nextInt(9), text.length);
      result.write(text.substring(position, endPos));
      position = endPos;
      if (position < text.length) result.write(' ');
    }
    return result.toString();
  }

  // File handling
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
      ..setAttribute('download', _generateFilename(_fileName))
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  String _generateFilename(String original) {
    final extIndex = original.lastIndexOf('.');
    final name = extIndex > 0 ? original.substring(0, extIndex) : original;
    final ext = extIndex > 0 ? original.substring(extIndex) : '';
    final numbers = List.generate(3, (_) => _random.nextInt(10)).join();
    return '${name}_$numbers$ext';
  }

  // UI Helpers
  void _clearAll() {
    setState(() {
      _fileBytes = null;
      _fileName = '';
      _textInputController.clear();
      _processedText = '';
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
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

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PasswordGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ENIGMATOR PRO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Security Key
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'SECURITY KEY',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),

                  // Operation Mode Toggle (Encrypt/Decrypt)
                  Card(
                    child: ListTile(
                      title: const Text('OPERATION MODE'),
                      trailing: Switch(
                        value: _isEncrypting,
                        onChanged: (value) => setState(() => _isEncrypting = value),
                        activeColor: Colors.blueAccent,
                      ),
                      subtitle: Text(_isEncrypting ? 'Encryption' : 'Decryption'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Process Mode Toggle (File/Text)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.settings),
                          const SizedBox(width: 15),
                          const Text('PROCESS MODE:'),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ToggleButtons(
                              isSelected: [_processFileMode, !_processFileMode],
                              onPressed: (index) => setState(() {
                                _processFileMode = index == 0;
                                _clearAll();
                              }),
                              children: const [Text('FILE'), Text('TEXT')],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Content Section
                  _processFileMode ? _buildFileSection() : _buildTextSection(),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
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
                            _isEncrypting 
                                ? '${_processFileMode ? 'PROCESS FILE' : 'PROCESS TEXT'}' 
                                : '${_processFileMode ? 'RESTORE FILE' : 'RESTORE TEXT'}',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.delete),
                          label: const Text('CLEAR ALL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Results
                  if (_processedText.isNotEmpty && !_processFileMode) 
                    _buildResultSection(),
                ],
              ),
            ),
          ),

          // Processing Animation
          if (_showProcessingAnimation)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SlideTransition(
                    position: _offsetAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isEncrypting ? 'Encrypting...' : 'Decrypting...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileSection() => Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'FILE PROCESSING',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildTextSection() => Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'TEXT PROCESSING',
                style: TextStyle(fontWeight: FontWeight.bold),
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
      );

  Widget _buildResultSection() => Card(
        elevation: 8,
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
      );
}