import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class FileCryptoHelper {
  static Uint8List generateKey(String password) {
    final key = sha256.convert(utf8.encode(password)).bytes;
    return Uint8List.fromList(key);
  }

  static Future<Uint8List> encryptFile(Uint8List bytes, String password) async {
    try {
      final key = encrypt.Key(generateKey(password));
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7')
      );
      
      final processedBytes = _processBeforeEncryption(bytes);
      final encrypted = encrypter.encryptBytes(processedBytes, iv: iv);
      
      return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    } catch (e) {
      throw Exception('Encryption failed: ${e.toString()}');
    }
  }

  static Future<Uint8List> decryptFile(Uint8List encryptedBytes, String password) async {
    try {
      if (encryptedBytes.length < 16) {
        throw Exception('Invalid encrypted data (too short)');
      }

      final iv = encrypt.IV(encryptedBytes.sublist(0, 16));
      final encryptedData = encryptedBytes.sublist(16);
      final key = encrypt.Key(generateKey(password));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7')
      );

      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedData), 
        iv: iv
      );
      
      return _processAfterDecryption(Uint8List.fromList(decrypted));
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  static Uint8List _processBeforeEncryption(Uint8List bytes) {
    try {
      final text = utf8.decode(bytes);
      return Uint8List.fromList(utf8.encode(text.toLowerCase()));
    } catch (e) {
      return bytes; // Return original if not UTF-8 text
    }
  }

  static Uint8List _processAfterDecryption(Uint8List bytes) {
    // In a real implementation, you would restore original case here
    // For now, we just return the decrypted bytes as-is
    return bytes;
  }
}