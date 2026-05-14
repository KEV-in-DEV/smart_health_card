import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

import '../models/temporary_models.dart';
import 'patient_validation.dart';

/// Exception claire pour les erreurs NFC affichees par l'UI.
class NfcServiceException implements Exception {
  const NfcServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;
  

  @override
  String toString() => 'NfcServiceException: $message';
}

/// Service NFC pour NTAG216.
///
/// Les donnees sont stockees en NDEF texte pour le MVP. Les zones marquees
/// "A remplacer" seront branchees au chiffrement/dechiffrement de la personne C.
class NfcService {
  NfcService({this.pollTimeout = const Duration(seconds: 20)});

  static const int maxPayloadBytes = PatientValidation.maxNtag216PayloadBytes;
  final Duration pollTimeout;

  /// Verifie si le telephone supporte le NFC.
  Future<bool> isNfcAvailable() async {
    final availability = await FlutterNfcKit.nfcAvailability;
    return availability != NFCAvailability.not_supported;
  }

  /// Verifie si le NFC est active.
  ///
  /// Sur Android/iOS, l'activation se fait generalement dans les reglages
  /// systeme. L'UI peut afficher un message si cette methode retourne false.
  Future<bool> isNfcEnabled() async {
    final availability = await FlutterNfcKit.nfcAvailability;
    return availability == NFCAvailability.available;
  }

  /// Lit une carte NFC, decode le premier enregistrement NDEF texte et retourne
  /// un [Patient]. Retourne null seulement si aucune donnee patient exploitable
  /// n'est trouvee.
  Future<Patient?> readCard() async {
    try {
      final tag = await _pollTag();
      _ensureNdefReadable(tag);

      final records = await FlutterNfcKit.readNDEFRecords(cached: false);
      if (records.isEmpty) {
        throw const NfcServiceException('Carte vide ou sans donnees NDEF.');
      }

      final payload = _extractTextRecord(records);
      if (payload == null || payload.trim().isEmpty) {
        throw const NfcServiceException('Carte invalide: donnees patient absentes.');
      }

      // A remplacer par le dechiffrement de C.
      final decryptedJson = payload;
      return Patient.fromJsonString(decryptedJson);
    } on NfcServiceException {
      rethrow;
    } on TimeoutException catch (error) {
      throw NfcServiceException('Aucune carte detectee avant expiration.', error);
    } on FormatException catch (error) {
      throw NfcServiceException('Carte invalide: JSON patient illisible.', error);
    } catch (error) {
      throw NfcServiceException('Lecture NFC impossible.', error);
    } finally {
      await _finishSession();
    }
  }

  /// Ecrit les donnees patient en NDEF texte apres authentification NTAG PWD.
  ///
  /// [writePassword] accepte soit 4 octets (8 caracteres hex), soit 16 octets
  /// (32 caracteres hex). NTAG216 utilise 4 octets pour PWD_AUTH; si 16 octets
  /// sont fournis par le registre hospitalier, les 4 premiers sont utilises ici.
  Future<bool> writeCard(Patient patient, String writePassword) async {
    final validation = PatientValidation.validate(patient);
    if (!validation.isValid) {
      throw NfcServiceException(validation.errors.join(' '));
    }

    try {
      final tag = await _pollTag();
      _ensureNdefWritable(tag);

      await _authenticateWithNtagPassword(writePassword);

      // A remplacer par le chiffrement de C.
      final encryptedJson = patient.toJsonString();
      final payloadBytes = utf8.encode(encryptedJson);
      if (payloadBytes.length > maxPayloadBytes) {
        throw NfcServiceException(
          'Donnees trop volumineuses (${payloadBytes.length}/$maxPayloadBytes octets).',
        );
      }

      await FlutterNfcKit.writeNDEFRecords(<ndef.NDEFRecord>[
        ndef.TextRecord(language: 'fr', text: encryptedJson),
      ]);
      return true;
    } on NfcServiceException {
      rethrow;
    } on TimeoutException catch (error) {
      throw NfcServiceException('Aucune carte detectee avant expiration.', error);
    } catch (error) {
      throw NfcServiceException(
        'Ecriture NFC impossible. Verifiez la carte et le mot de passe.',
        error,
      );
    } finally {
      await _finishSession();
    }
  }

  /// Retourne l'UID unique de la carte pour tracabilite/audit.
  Future<String> getCardUid() async {
    try {
      final tag = await _pollTag();
      if (tag.id.isEmpty) {
        throw const NfcServiceException('UID de carte indisponible.');
      }
      return tag.id;
    } catch (error) {
      if (error is NfcServiceException) {
        rethrow;
      }
      throw NfcServiceException('Impossible de lire lUID de la carte.', error);
    } finally {
      await _finishSession();
    }
  }

  Future<NFCTag> _pollTag() async {
    final enabled = await isNfcEnabled();
    if (!enabled) {
      throw const NfcServiceException(
        'NFC indisponible ou desactive. Activez le NFC dans les reglages.',
      );
    }

    return FlutterNfcKit.poll(
      timeout: pollTimeout,
      iosAlertMessage: 'Approchez la carte Smart Health Card.',
      iosMultipleTagMessage: 'Plusieurs cartes detectees. Gardez une seule carte.',
    );
  }

  void _ensureNdefReadable(NFCTag tag) {
    if (tag.ndefAvailable != true) {
      throw const NfcServiceException('Cette carte ne contient pas de zone NDEF.');
    }
  }

  void _ensureNdefWritable(NFCTag tag) {
    if (tag.ndefWritable != true) {
      throw const NfcServiceException('Cette carte NFC nest pas inscriptible.');
    }
    final capacity = tag.ndefCapacity;
    if (capacity != null && capacity < maxPayloadBytes) {
      throw NfcServiceException(
        'Capacite NFC insuffisante ($capacity octets disponibles).',
      );
    }
  }

  String? _extractTextRecord(List<ndef.NDEFRecord> records) {
    for (final record in records) {
      if (record is ndef.TextRecord && record.text != null) {
        return record.text;
      }

      final text = record.toString();
      if (text.trim().startsWith('{')) {
        return text;
      }

      final payload = record.payload;
      if (payload == null || payload.isEmpty) {
        continue;
      }
      final decoded = _decodeNdefTextPayload(payload);
      if (decoded != null && decoded.trim().startsWith('{')) {
        return decoded;
      }
    }
    return null;
  }

  String? _decodeNdefTextPayload(Uint8List payload) {
    if (payload.isEmpty) {
      return null;
    }

    final status = payload.first;
    final isUtf16 = (status & 0x80) != 0;
    final languageLength = status & 0x3F;
    final textStart = 1 + languageLength;
    if (textStart > payload.length) {
      return null;
    }

    final textBytes = payload.sublist(textStart);
    return isUtf16 ? null : utf8.decode(textBytes, allowMalformed: true);
  }

  Future<void> _authenticateWithNtagPassword(String writePassword) async {
    final password = _parseNtagPassword(writePassword);
    final command = '1B${_toHex(password)}';

    try {
      final response = await FlutterNfcKit.transceive(command);
      if (response.length < 4) {
        throw const NfcServiceException('Authentification NTAG refusee.');
      }
    } catch (error) {
      if (error is NfcServiceException) {
        rethrow;
      }
      throw NfcServiceException('Mot de passe ecriture NFC incorrect.', error);
    }
  }

  Uint8List _parseNtagPassword(String writePassword) {
    final normalized = writePassword.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (normalized.length != 8 && normalized.length != 32) {
      throw const NfcServiceException(
        'Mot de passe NTAG invalide: utilisez 4 octets hex ou 16 octets hex.',
      );
    }

    final passwordHex = normalized.substring(0, 8);
    return Uint8List.fromList(<int>[
      for (var i = 0; i < passwordHex.length; i += 2)
        int.parse(passwordHex.substring(i, i + 2), radix: 16),
    ]);
  }

  String _toHex(Uint8List bytes) =>
      bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();

  Future<void> _finishSession() async {
    try {
      await FlutterNfcKit.finish(iosAlertMessage: 'Operation terminee.');
    } catch (_) {
      // La session peut deja etre fermee si le tag a ete retire.
    }
  }
}

/*
Exemple d'utilisation pour la personne A:

final nfcService = NfcService();

Future<void> lireCarte() async {
  try {
    final patient = await nfcService.readCard();
    if (patient != null) {
      // Afficher patient.fullName, patient.bloodType, etc.
    }
  } on NfcServiceException catch (error) {
    // Afficher error.message dans un SnackBar ou une alerte.
  }
}

Future<void> ecrireCarte(Patient patient) async {
  const passwordHex = 'A1B2C3D4'; // ou 16 octets hex venant de l'hopital.
  final success = await nfcService.writeCard(patient, passwordHex);
  // success == true si l'ecriture est terminee.
}
*/
