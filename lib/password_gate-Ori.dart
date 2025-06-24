import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Critical import for kDebugMode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enigmator_techno/password_helper.dart';
import 'package:enigmator_techno/file_crypto_page.dart';

class PasswordGate extends StatefulWidget {
  const PasswordGate({super.key});

  @override
  State<PasswordGate> createState() => _PasswordGateState();
}

class _PasswordGateState extends State<PasswordGate> {
  final _passwordController = TextEditingController();
  final _extraInputController = TextEditingController();
  String _duration = 'weekly';
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('Password Gate Initialized');
    }
  }

  Future<void> _validateAccess() async {
    final now = DateTime.now().toUtc();
    final expectedPassword = PasswordHelper.generatePassword(
      _duration,
      _extraInputController.text.trim(),
    );

    if (_passwordController.text.trim() == expectedPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastAccess', now.toIso8601String());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FileCryptoPage()),
      );
    } else {
      setState(() => _error = 'Invalid credentials');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: _duration,
                items: ['daily', 'weekly', 'monthly', 'annually'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _duration = value!),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _extraInputController,
                decoration: const InputDecoration(
                  labelText: 'Security Input',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _validateAccess,
                child: const Text('UNLOCK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _extraInputController.dispose();
    super.dispose();
  }
}