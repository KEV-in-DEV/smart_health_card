import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/nfc_service.dart';
import '../state/app_state.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/nfc_status_card.dart';

class NfcWriteScreen extends ConsumerStatefulWidget {
  const NfcWriteScreen({super.key, required this.patientData});

  final Map<String, String> patientData;

  @override
  ConsumerState<NfcWriteScreen> createState() => _NfcWriteScreenState();
}

class _NfcWriteScreenState extends ConsumerState<NfcWriteScreen> {
  NfcUiStatus _status = NfcUiStatus.waiting;
  bool _canGenerateLabel = false;
  bool _isSessionRunning = false;

  Future<void> _writeToCard() async {
    setState(() {
      _status = NfcUiStatus.waiting;
      _canGenerateLabel = false;
      _isSessionRunning = true;
    });

    try {
      final available = await NfcService.isAvailable();
      if (!available) {
        setState(() {
          _status = NfcUiStatus.incompatible;
          _isSessionRunning = false;
        });
        return;
      }

      setState(() => _status = NfcUiStatus.detected);
      final success = await NfcService.writeCard(
        widget.patientData,
        alertMessage: 'Approchez la carte pour écrire les données publiques',
      );

      if (!mounted) return;
      setState(() {
        _status = success ? NfcUiStatus.success : NfcUiStatus.securityError;
        _canGenerateLabel = success;
        _isSessionRunning = false;
      });

      if (success) {
        ref.read(cardRepositoryProvider.notifier).addCard(widget.patientData);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = NfcUiStatus.securityError;
        _isSessionRunning = false;
      });
    }
  }

  void _openLabelPreview() {
    Navigator.of(
      context,
    ).pushNamed('/card-label', arguments: _publicCardData());
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${widget.patientData['Nom'] ?? ''} ${widget.patientData['Prénom'] ?? ''}'
            .trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Écriture NFC')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              fullName.isEmpty ? 'Nouveau patient' : fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cette étape reste locale et fonctionne sans Internet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            NfcStatusCard(
              status: _status,
              action: _canGenerateLabel
                  ? CustomButton(
                      label: AppStrings.generateQr,
                      icon: Icons.qr_code_2,
                      onPressed: _openLabelPreview,
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_canGenerateLabel)
              CustomButton(
                label: AppStrings.startNfcWrite,
                icon: Icons.nfc,
                backgroundColor: AppColors.burkinaOrange,
                onPressed: _isSessionRunning ? null : _writeToCard,
              ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: AppStrings.back,
              icon: Icons.arrow_back,
              backgroundColor: AppColors.mutedText,
              onPressed: _isSessionRunning
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _publicCardData() {
    return {
      'Nom': widget.patientData['Nom'] ?? '',
      'Prenom': widget.patientData['Prénom'] ?? '',
      'Groupe sanguin': widget.patientData['Groupe sanguin'] ?? '',
      'Contact urgence': widget.patientData['Contact d’urgence'] ?? '',
    };
  }
}
