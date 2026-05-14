import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt_package;

class EncryptionService implements IEncryption {
  static final EncryptionService _instance = EncryptionService._internal();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  encrypt_package.Key? _masterKey;

  EncryptionService._internal();

  factory EncryptionService() {
    return _instance;
  }

  static const String _masterKeyId = 'smart_health_master_key';

  /// Récupère ou génère la clé maître
  Future<encrypt_package.Key> _getMasterKey() async {
    if (_masterKey != null) return _masterKey!;

    final storedKey = await _secureStorage.read(key: _masterKeyId);

    if (storedKey != null) {
      _masterKey = encrypt_package.Key.fromBase64(storedKey);
      return _masterKey!;
    }

    // Génération d'une nouvelle clé aléatoire
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final newKey = encrypt_package.Key(keyBytes);

    await _secureStorage.write(key: _masterKeyId, value: newKey.base64);

    _masterKey = newKey;
    return _masterKey!;
  }

  @override
  Future<String> encrypt(String plainText) async {
    try {
      final key = await _getMasterKey();
      final iv = encrypt_package.IV.fromSecureRandom(16);
      final encrypter = encrypt_package.Encrypter(
        encrypt_package.AES(key, mode: encrypt_package.AESMode.gcm),
      );

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Retourne IV + cipherText en base64
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Erreur chiffrement: $e');
    }
  }

  @override
  Future<String> decrypt(String cipherText) async {
    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) {
        throw Exception('Format de chiffrement invalide');
      }

      final iv = encrypt_package.IV.fromBase64(parts[0]);
      final encryptedData = encrypt_package.Encrypted.fromBase64(parts[1]);
      final key = await _getMasterKey();
      final encrypter = encrypt_package.Encrypter(
        encrypt_package.AES(key, mode: encrypt_package.AESMode.gcm),
      );

      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception('Erreur déchiffrement: $e');
    }
  }

  @override
  Future<String> deriveCardKey(String cardUid, String hospitalSecret) async {
    // Utilise HKDF pour dériver une clé unique par carte
    final salt = utf8.encode('SmartHealthCardSalt');
    final info = utf8.encode('CardKey');

    final inputKey = utf8.encode('$cardUid:$hospitalSecret');

    // Création manuelle de HKDF (pour compatibilité)
    final pseudorandomKey = Hmac(sha256, inputKey).convert(salt).bytes;
    final List<int> derivedKey = [];
    int counter = 1;

    while (derivedKey.length < 32) {
      final data = <int>[...pseudorandomKey, ...info, counter];
      final block = Hmac(sha256, pseudorandomKey).convert(data).bytes;
      derivedKey.addAll(block);
      counter++;
    }

    return base64.encode(derivedKey.sublist(0, 32));
  }

  /// Hash un mot de passe avec sel
  Future<String> hashPassword(String password, {String? salt}) async {
    final generatedSalt = salt ?? _generateSalt();
    final saltedPassword = '$generatedSalt:$password';
    final hash = sha256.convert(utf8.encode(saltedPassword)).toString();
    return '$generatedSalt:$hash';
  }

  /// Vérifie un mot de passe
  Future<bool> verifyPassword(String password, String hashed) async {
    final parts = hashed.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final expectedHash = parts[1];

    final saltedPassword = '$salt:$password';
    final actualHash = sha256.convert(utf8.encode(saltedPassword)).toString();

    return actualHash == expectedHash;
  }

  String _generateSalt() {
    final random = Random.secure();
    return base64.encode(
      Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256))),
    );
  }

  /// Génère une signature pour l'historique
  Future<String> generateSignature(
    Map<String, dynamic> data,
    String agentId,
  ) async {
    final jsonString = jsonEncode(data);
    final hmac = Hmac(sha256, utf8.encode(agentId));
    final signature = hmac.convert(utf8.encode(jsonString)).toString();
    return signature;
  }

  /// Valide une signature
  Future<bool> validateSignature(
    Map<String, dynamic> data,
    String agentId,
    String signature,
  ) async {
    final expectedSignature = await generateSignature(data, agentId);
    return expectedSignature == signature;
  }
}

// Interface définie par l'équipe
abstract class IEncryption {
  Future<String> encrypt(String plainText);
  Future<String> decrypt(String cipherText);
  Future<String> deriveCardKey(String cardUid, String hospitalSecret);
}
