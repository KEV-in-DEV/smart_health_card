import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/temporary_models.dart';

/// Exception claire pour les erreurs QR affichees par l'UI.
class QrServiceException implements Exception {
  const QrServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'QrServiceException: $message';
}

/// Donnees pretes pour l'aperçu/impression de l'etiquette de la carte.
class PrintableCardData {
  const PrintableCardData({
    required this.publicInfo,
    required this.qrPng,
    required this.labelLines,
  });

  final PublicInfo publicInfo;
  final Uint8List qrPng;
  final List<String> labelLines;
}

/// Service de scan et generation de QR codes publics.
class QrService {
  QrService({GlobalKey<NavigatorState>? navigatorKey})
    : _navigatorKey = navigatorKey;

  final GlobalKey<NavigatorState>? _navigatorKey;

  /// Ouvre la camera, scanne un QR code, puis retourne son contenu texte.
  ///
  /// Fournir un [navigatorKey] au constructeur, ou utiliser [scanQRWithContext]
  /// depuis un widget. Le contenu attendu est un JSON court PublicInfo.
  Future<String> scanQR() async {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      throw const QrServiceException(
        'Contexte Flutter indisponible. Utilisez scanQRWithContext(context).',
      );
    }
    return scanQRWithContext(context);
  }

  /// Variante pratique pour la personne A quand elle est deja dans un widget.
  Future<String> scanQRWithContext(BuildContext context) async {
    final navigator = Navigator.of(context);
    await _ensureCameraPermission();

    final result = await navigator.push<String>(
      MaterialPageRoute<String>(builder: (_) => const _QrScannerPage()),
    );

    if (result == null || result.trim().isEmpty) {
      throw const QrServiceException('Scan QR annule ou vide.');
    }
    return result;
  }

  /// Genere une image PNG QR en memoire a partir des donnees publiques.
  Future<Uint8List> generateQR(
    PublicInfo info, {
    double size = 512,
    Color foregroundColor = Colors.black,
  }) async {
    final payload = info.toJsonString();
    final painter = QrPainter(
      data: payload,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: QrEyeStyle(color: foregroundColor),
      dataModuleStyle: QrDataModuleStyle(color: foregroundColor),
    );

    final imageData = await painter.toImageData(
      size,
      format: ui.ImageByteFormat.png,
    );
    if (imageData == null) {
      throw const QrServiceException('Generation image QR impossible.');
    }
    return imageData.buffer.asUint8List();
  }

  /// Retourne un widget QR affichable directement dans l'UI.
  Widget buildQRWidget(PublicInfo info, {double size = 220}) {
    return QrImageView(
      data: info.toJsonString(),
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
    );
  }

  /// Parse le JSON public scanne en [PublicInfo].
  PublicInfo parsePublicInfo(String rawQrContent) {
    try {
      return PublicInfo.fromJson(
        jsonDecode(rawQrContent) as Map<String, dynamic>,
      );
    } catch (error) {
      throw QrServiceException('QR invalide: JSON public illisible.', error);
    }
  }

  /// Prepare les donnees publiques a imprimer/coller sur la carte.
  ///
  /// Le QR contient uniquement [PublicInfo]. Les lignes lisibles humainement
  /// contiennent nom/prenoms, groupe sanguin et contact d'urgence.
  Future<PrintableCardData> generatePrintableCardData(Patient patient) async {
    final publicInfo = patient.toPublicInfo();
    final qrPng = await generateQR(publicInfo);

    return PrintableCardData(
      publicInfo: publicInfo,
      qrPng: qrPng,
      labelLines: <String>[
        publicInfo.name,
        'Groupe sanguin: ${publicInfo.bloodType}',
        'Urgence: ${publicInfo.emergencyPhone}',
      ],
    );
  }

  Future<void> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw const QrServiceException('Permission camera refusee.');
    }
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner QR')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_handled) {
            return;
          }
          final barcodes = capture.barcodes;
          final value = barcodes.isEmpty ? null : barcodes.first.rawValue;
          if (value == null || value.trim().isEmpty) {
            return;
          }
          _handled = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}

/*
Exemple d'utilisation pour la personne A:

final qrService = QrService();

Future<void> scanner(BuildContext context) async {
  try {
    final raw = await qrService.scanQRWithContext(context);
    final publicInfo = qrService.parsePublicInfo(raw);
    // Afficher publicInfo.name, publicInfo.bloodType, publicInfo.emergencyPhone.
  } on QrServiceException catch (error) {
    // Afficher error.message dans l'UI.
  }
}

Widget afficherQr(Patient patient) {
  final publicInfo = PublicInfo(
    name: patient.fullName,
    bloodType: patient.bloodType,
    emergencyPhone: patient.emergencyContact,
  );
  return qrService.buildQRWidget(publicInfo);
}

Future<void> preparerEtiquette(Patient patient) async {
  final printable = await qrService.generatePrintableCardData(patient);
  // printable.qrPng => image QR a imprimer.
  // printable.labelLines => nom/prenoms, groupe sanguin, contact urgence.
}
*/
