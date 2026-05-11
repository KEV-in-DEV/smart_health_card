import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_health_card/models/public_info.dart';

class QrService implements IQrService {
  
  /// Scanne un QR code et retourne les infos publiques
  @override
  Future<PublicInfo> scanQR() async {
    final completer = Completer<PublicInfo>();
    
    final controller = MobileScannerController();
    
    final scanner = MobileScanner(
      controller: controller,
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          final rawValue = barcode.rawValue;
          if (rawValue != null) {
            try {
              final publicInfo = PublicInfo.fromQrString(rawValue);
              if (!completer.isCompleted) {
                completer.complete(publicInfo);
                controller.stop();
                // Fermer le dialog
                if (navigatorKey.currentContext != null) {
                  Navigator.pop(navigatorKey.currentContext!);
                }
              }
            } catch (e) {
              if (!completer.isCompleted) {
                completer.completeError("QR code invalide");
              }
            }
          }
        }
      },
    );
    
    // Affiche le scanner dans un dialog
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 300,
            height: 350,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Scannez le QR code"),
                ),
                Expanded(child: scanner),
                TextButton(
                  onPressed: () {
                    controller.stop();
                    Navigator.pop(context);
                    if (!completer.isCompleted) {
                      completer.completeError("Scan annulé");
                    }
                  },
                  child: const Text("Annuler"),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return completer.future;
  }
  
  /// Génère un QR code à partir des infos publiques
  @override
  Widget generateQR(PublicInfo info) {
    final qrString = info.toQrString();
    
    return QrImageView(
      data: qrString,
      version: QrVersions.auto,
      size: 200.0,
      eyeStyle: const QrEyeStyle(
        color: Colors.black,
        eyeShape: QrEyeShape.square,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        color: Colors.black,
        dataModuleShape: QrDataModuleShape.square,
      ),
    );
  }
}

// Interface définie par l'équipe
abstract class IQrService {
  Future<PublicInfo> scanQR();
  Widget generateQR(PublicInfo info);
}

// Pour naviguer dans le scanner
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();