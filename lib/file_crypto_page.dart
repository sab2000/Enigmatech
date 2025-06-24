import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class FileCryptoHelper {
  static Uint8List generateKey(String password) {
    return Uint8List.fromList(sha256.convert(utf8.encode(password)).bytes);
  }

  static Uint8List encryptFile(Uint8List bytes, String password) {
    final key = generateKey(password);
    // Your encryption implementation
    return bytes;
  }

  static Uint8List decryptFile(Uint8List bytes, String password) {
    final key = generateKey(password);
    // Your decryption implementation
    return bytes;
  }
}