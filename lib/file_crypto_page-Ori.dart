import 'package:flutter/material.dart';
import 'package:Enigmatech/encrypt_screen.dart';

class FileCryptoPage extends StatelessWidget {
  const FileCryptoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ENIGMATOR TECHNO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: const EncryptScreen(),
    );
  }
}