import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';

class NfcReadResult {
  final bool isBlank;
  final Map<String, String> data;

  const NfcReadResult({required this.isBlank, required this.data});
}

class NfcService {
  static const _mimeType = 'application/json';

  static Future<bool> isAvailable() async {
    return NfcManager.instance.isAvailable();
  }

  static Future<NfcReadResult> readCard({String alertMessage = 'Approchez la carte NFC'}) async {
    final completer = Completer<NfcReadResult>();

    await NfcManager.instance.startSession(
      alertMessage: alertMessage,
      onDiscovered: (tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            completer.complete(const NfcReadResult(isBlank: true, data: {}));
            await NfcManager.instance.stopSession(errorMessage: 'Carte non compatible');
            return;
          }

          final message = await ndef.read();
          if (message.records.isEmpty) {
            completer.complete(const NfcReadResult(isBlank: true, data: {}));
            await NfcManager.instance.stopSession(alertMessage: 'Carte vierge détectée');
            return;
          }

          final first = message.records.first;
          final payload = first.payload;
          final recordType = String.fromCharCodes(first.type);
          if (first.typeNameFormat == NdefTypeNameFormat.media &&
              recordType == _mimeType) {
            final jsonString = utf8.decode(payload);
            final dynamic decoded = json.decode(jsonString);
            if (decoded is Map<String, dynamic>) {
              final cardData = decoded.map((key, value) {
                return MapEntry(key.toString(), value?.toString() ?? '');
              });
              completer.complete(NfcReadResult(isBlank: false, data: cardData));
            } else {
              completer.complete(const NfcReadResult(isBlank: true, data: {}));
            }
          } else {
            completer.complete(const NfcReadResult(isBlank: true, data: {}));
          }

          await NfcManager.instance.stopSession(alertMessage: 'Lecture terminée');
        } catch (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          await NfcManager.instance.stopSession(errorMessage: 'Erreur NFC');
        }
      },
    );

    return completer.future;
  }

  static Future<bool> writeCard(
    Map<String, String> data, {
    String alertMessage = 'Approchez une carte NFC vierge',
  }) async {
    final completer = Completer<bool>();

    await NfcManager.instance.startSession(
      alertMessage: alertMessage,
      onDiscovered: (tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            completer.complete(false);
            await NfcManager.instance.stopSession(errorMessage: 'Carte non compatible');
            return;
          }

          final payload = utf8.encode(json.encode(data));
          final record = NdefRecord.createMime(_mimeType, Uint8List.fromList(payload));
          final message = NdefMessage([record]);
          await ndef.write(message);
          completer.complete(true);
          await NfcManager.instance.stopSession(alertMessage: 'Écriture terminée');
        } catch (error) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          await NfcManager.instance.stopSession(errorMessage: 'Erreur d’écriture NFC');
        }
      },
    );

    return completer.future;
  }
}
