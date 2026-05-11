import 'dart:convert';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/services/encryption_service.dart';

class NfcService implements INfcService {
  final EncryptionService _encryption = EncryptionService();
  
  /// Vérifie si le NFC est disponible
  @override
  Future<bool> isAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      return false;
    }
  }
  
  /// Vérifie si le NFC est activé
  @override
  Future<bool> isEnabled() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      return false;
    }
  }
  
  /// Lit une carte NFC et retourne le Patient
  @override
  Future<Patient?> readCard() async {
    try {
      // Attend la pose d'une carte
      final NFCTag tag = await FlutterNfcKit.poll();
      
      // Récupère l'UID de la carte
      final cardUid = tag.id;
      print("UID carte: $cardUid");
      
      // Récupère les données NDEF
      final NFCMap? data = await FlutterNfcKit.ndefRead();
      
      if (data == null) {
        throw Exception("Aucune donnée NDEF trouvée");
      }
      
      // Extrait le message
      final String? rawData = data['message'];
      
      if (rawData == null || rawData.isEmpty) {
        throw Exception("Données invalides sur la carte");
      }
      
      print("Données brutes: $rawData");
      
      // Déchiffre les données
      String decryptedData;
      try {
        decryptedData = await _encryption.decrypt(rawData);
      } catch (e) {
        print("Déchiffrement impossible, lecture en clair: $e");
        decryptedData = rawData;
      }
      
      // Parse le JSON
      final Map<String, dynamic> jsonData = jsonDecode(decryptedData);
      
      // Reconstruit le Patient
      final patient = Patient.fromJson(jsonData);
      
      // Arrête la session NFC
      await FlutterNfcKit.finish();
      
      return patient;
      
    } catch (e) {
      await FlutterNfcKit.finish();
      print("Erreur lecture NFC: $e");
      return null;
    }
  }
  
  /// Écrit les données du patient sur la carte NFC
  @override
  Future<bool> writeCard(Patient patient, String writePassword) async {
    try {
      // Attend la pose d'une carte
      final NFCTag tag = await FlutterNfcKit.poll();
      
      print("Carte détectée: ${tag.id}");
      
      // Prépare les données JSON
      final jsonData = patient.toJson();
      final jsonString = jsonEncode(jsonData);
      
      // Chiffre les données
      final encryptedData = await _encryption.encrypt(jsonString);
      
      // Prépare le message NDEF
      final ndefMessage = {
        'message': encryptedData,
        'type': 'text/plain',
      };
      
      // Écrit sur la carte
      await FlutterNfcKit.ndefWrite(ndefMessage);
      
      // Arrête la session
      await FlutterNfcKit.finish();
      
      return true;
      
    } catch (e) {
      await FlutterNfcKit.finish();
      print("Erreur écriture NFC: $e");
      return false;
    }
  }
  
  /// Récupère l'UID de la carte
  Future<String> getCardUid() async {
    try {
      final NFCTag tag = await FlutterNfcKit.poll();
      final uid = tag.id;
      await FlutterNfcKit.finish();
      return uid;
    } catch (e) {
      await FlutterNfcKit.finish();
      return "";
    }
  }
}

// Interface définie par l'équipe
abstract class INfcService {
  Future<bool> isAvailable();
  Future<bool> isEnabled();
  Future<Patient?> readCard();
  Future<bool> writeCard(Patient patient, String writePassword);
}