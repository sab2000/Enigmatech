import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:enigmatech/password_gate.dart';
import 'package:enigmatech/file_crypto_helper.dart';

void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load environment variables
  await dotenv.load(fileName: ".env");
  
  // 3. Run cryptographic self-test
  await _runCryptoSelfTest();

  // 4. Start the app
  runApp(const EnigmatorApp());
}

Future<void> _runCryptoSelfTest() async {
  try {
    debugPrint('[INIT] Running cryptographic self-test...');
    
    // Test vector with mixed case and special characters
    const testString = 'Enigmator@123';
    final testData = Uint8List.fromList(utf8.encode(testString));
    
    // Encryption/Decryption roundtrip
    final encrypted = await FileCryptoHelper.encryptFile(testData, 'test123');
    final decrypted = await FileCryptoHelper.decryptFile(encrypted, 'test123');
    
    // Verify integrity
    final result = utf8.decode(testData) == utf8.decode(decrypted) 
        ? 'PASSED' 
        : 'FAILED';
    
    debugPrint('[INIT] Crypto test $result');
    debugPrint('[INIT] Original: $testString');
    debugPrint('[INIT] Decrypted: ${utf8.decode(decrypted)}');
    
    // Verify WhatsApp config
    final supportNumber = dotenv.get('PRIMARY_SUPPORT', fallback: '');
    if (supportNumber.isEmpty) {
      debugPrint('[WARNING] WhatsApp support number not configured');
    }
  } catch (e) {
    debugPrint('[CRITICAL] Crypto test failed: ${e.toString()}');
    rethrow;
  }
}

class EnigmatorApp extends StatelessWidget {
  const EnigmatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enigmator Techno',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: const PasswordGate(),
      builder: (context, child) {
        ErrorWidget.builder = (errorDetails) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 20),
                  Text(
                    'System Integrity Violation',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please restart the application',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => main(),
                    child: const Text('RESTART APP'),
                  ),
                ],
              ),
            ),
          );
        };
        return child!;
      },
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
        primary: Colors.blueAccent,
        secondary: Colors.tealAccent,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white10,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}