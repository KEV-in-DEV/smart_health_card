import 'dart:convert';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/records/well_known/text.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/services/encryption_service.dart';

class NfcService implements INfcService {
  final EncryptionService _encryption = EncryptionService();

  @override
  Future<bool> isAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isEnabled() async {
    return isAvailable();
  }

  @override
  Future<Patient?> readCard() async {
    try {
      await FlutterNfcKit.poll();
      final records = await FlutterNfcKit.readNDEFRecords(cached: false);
      if (records.isEmpty) {
        throw Exception('Aucune donnée NDEF trouvée');
      }

      final textRecords = records.whereType<TextRecord>();
      final rawData =
          textRecords.isNotEmpty
              ? textRecords.first.text
              : records.first.payload?.isNotEmpty == true
              ? utf8.decode(records.first.payload!)
              : null;

      if (rawData == null || rawData.isEmpty) {
        throw Exception('Données invalides sur la carte');
      }

      String decodedData;
      try {
        decodedData = await _encryption.decrypt(rawData);
      } catch (_) {
        decodedData = rawData;
      }

      final jsonData = jsonDecode(decodedData) as Map<String, dynamic>;
      return Patient.fromJson(jsonData);
    } catch (_) {
      return null;
    } finally {
      await _finishSession();
    }
  }

  @override
  Future<bool> writeCard(Patient patient, String writePassword) async {
    try {
      await FlutterNfcKit.poll();
      final jsonString = jsonEncode(patient.toJson());
      final encryptedData = await _encryption.encrypt(jsonString);

      await FlutterNfcKit.writeNDEFRecords([
        TextRecord(language: 'fr', text: encryptedData),
      ]);

      return true;
    } catch (_) {
      return false;
    } finally {
      await _finishSession();
    }
  }

  Future<String> getCardUid() async {
    try {
      final tag = await FlutterNfcKit.poll();
      return tag.id;
    } catch (_) {
      return '';
    } finally {
      await _finishSession();
    }
  }

  Future<void> _finishSession() async {
    try {
      await FlutterNfcKit.finish();
    } catch (_) {
      // Session may already be closed.
    }
  }
}

abstract class INfcService {
  Future<bool> isAvailable();
  Future<bool> isEnabled();
  Future<Patient?> readCard();
  Future<bool> writeCard(Patient patient, String writePassword);
}
