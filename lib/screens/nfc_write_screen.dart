import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_health_card/models/medical_record.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/state/app_state.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_button.dart';
import 'package:smart_health_card/widgets/nfc_status_card.dart';

class NfcWriteScreen extends ConsumerStatefulWidget {
  const NfcWriteScreen({super.key, required this.patient});

  final Patient patient;

  @override
  ConsumerState<NfcWriteScreen> createState() => _NfcWriteScreenState();
}

class _NfcWriteScreenState extends ConsumerState<NfcWriteScreen> {
  NfcUiStatus _status = NfcUiStatus.waiting;
  bool _canGenerateLabel = false;
  bool _isSessionRunning = false;
  String? _message;

  Future<void> _writeNfc() async {
    final nfc = ref.read(nfcServiceProvider);
    final storage = ref.read(storageProvider);
    final encryption = ref.read(encryptionProvider);
    final agent = ref.read(agentSessionProvider);

    setState(() {
      _status = NfcUiStatus.waiting;
      _canGenerateLabel = false;
      _isSessionRunning = true;
      _message = null;
    });

    try {
      final isAvailable = await nfc.isAvailable();
      if (!isAvailable) {
        setState(() {
          _status = NfcUiStatus.incompatible;
          _message =
              'NFC indisponible sur cet appareil. Enregistrement local effectué.';
        });
        await _saveLocalRecord(storage, encryption, agent?.id ?? 'agent');
        return;
      }

      setState(() => _status = NfcUiStatus.writing);
      final success = await nfc.writeCard(widget.patient, agent?.id ?? 'agent');
      if (!success) {
        setState(() {
          _status = NfcUiStatus.incompatible;
          _message = 'Écriture NFC échouée. Vérifiez la carte et réessayez.';
        });
        return;
      }

      await _saveLocalRecord(storage, encryption, agent?.id ?? 'agent');
      setState(() {
        _status = NfcUiStatus.success;
        _canGenerateLabel = true;
        _message = 'Carte écrite et patient enregistré hors ligne.';
      });
    } catch (e) {
      setState(() {
        _status = NfcUiStatus.incompatible;
        _message = 'Erreur NFC : $e';
      });
    } finally {
      if (mounted) setState(() => _isSessionRunning = false);
    }
  }

  Future<void> _saveLocalRecord(
    dynamic storage,
    dynamic encryption,
    String agentId,
  ) async {
    final agent = ref.read(agentSessionProvider);
    await storage.savePatient(widget.patient);
    final signature = await encryption.generateSignature(
      widget.patient.toJson(),
      agentId,
    );
    await storage.addHistoryRecord(
      MedicalRecord(
        patientId: widget.patient.id,
        timestamp: DateTime.now(),
        agentId: agent?.id ?? agentId,
        agentName: agent?.name ?? 'Agent',
        hospital: agent?.hospital ?? 'Centre de santé',
        action: 'create',
        details: 'Création et écriture de la carte',
        signature: signature,
      ),
    );
  }

  void _openLabelPreview() {
    Navigator.of(context).pushNamed(
      '/card-label',
      arguments: {
        'Nom': widget.patient.lastName,
        'Prenom': widget.patient.firstName,
        'Groupe sanguin': widget.patient.bloodType,
        'Contact urgence': widget.patient.emergencyContact,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Écriture NFC')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              widget.patient.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cette étape fonctionne hors ligne. Sur téléphone compatible, l’écriture NFC réelle sera lancée.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            NfcStatusCard(status: _status, detail: _message),
            const SizedBox(height: AppSpacing.md),
            if (!_canGenerateLabel)
              CustomButton(
                label: AppStrings.startNfcWrite,
                icon: Icons.nfc,
                backgroundColor: AppColors.burkinaOrange,
                onPressed: _isSessionRunning ? null : _writeNfc,
              ),
            if (_canGenerateLabel)
              CustomButton(
                label: AppStrings.generateQr,
                icon: Icons.qr_code_2,
                onPressed: _openLabelPreview,
              ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: AppStrings.back,
              icon: Icons.arrow_back,
              backgroundColor: AppColors.mutedText,
              onPressed:
                  _isSessionRunning ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
