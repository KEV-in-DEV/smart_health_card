import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_health_card/models/medical_record.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/state/app_state.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_button.dart';
import 'package:smart_health_card/widgets/custom_card.dart';
import 'package:smart_health_card/widgets/nfc_status_card.dart';

class ReadCardScreen extends ConsumerStatefulWidget {
  const ReadCardScreen({super.key});

  @override
  ConsumerState<ReadCardScreen> createState() => _ReadCardScreenState();
}

class _ReadCardScreenState extends ConsumerState<ReadCardScreen> {
  NfcUiStatus _status = NfcUiStatus.waiting;
  bool _isSessionRunning = false;
  Patient? _patient;
  List<MedicalRecord> _history = [];
  String? _message;

  Future<void> _readNfc() async {
    final nfc = ref.read(nfcServiceProvider);
    final storage = ref.read(storageProvider);
    final encryption = ref.read(encryptionProvider);
    final agent = ref.read(agentSessionProvider);

    setState(() {
      _status = NfcUiStatus.waiting;
      _isSessionRunning = true;
      _patient = null;
      _history = [];
      _message = null;
    });

    try {
      final isAvailable = await nfc.isAvailable();
      if (!isAvailable) {
        setState(() {
          _status = NfcUiStatus.incompatible;
          _message = 'NFC indisponible sur cet appareil.';
        });
        return;
      }

      setState(() => _status = NfcUiStatus.reading);
      final patient = await nfc.readCard();
      if (patient == null) {
        setState(() {
          _status = NfcUiStatus.incompatible;
          _message = 'Aucune carte valide n’a été lue.';
        });
        return;
      }

      await storage.savePatient(patient);
      final signature = await encryption.generateSignature(
        patient.toJson(),
        agent?.id ?? 'agent',
      );
      await storage.addHistoryRecord(
        MedicalRecord(
          patientId: patient.id,
          timestamp: DateTime.now(),
          agentId: agent?.id ?? 'agent',
          agentName: agent?.name ?? 'Agent',
          hospital: agent?.hospital ?? 'Centre de santé',
          action: 'read',
          details: 'Lecture de la carte NFC',
          signature: signature,
        ),
      );
      final history = await storage.getHistoryForPatient(patient.id);

      setState(() {
        _status = NfcUiStatus.success;
        _patient = patient;
        _history = history;
        _message = '${AppStrings.cardVerified} - données lues hors ligne.';
      });
    } catch (e) {
      setState(() {
        _status = NfcUiStatus.incompatible;
        _message = 'Erreur de lecture : $e';
      });
    } finally {
      if (mounted) setState(() => _isSessionRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = _patient;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.readCard)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            NfcStatusCard(status: _status, detail: _message),
            const SizedBox(height: AppSpacing.md),
            if (patient == null) ...[
              CustomButton(
                label: AppStrings.startNfcRead,
                icon: Icons.nfc,
                onPressed: _isSessionRunning ? null : _readNfc,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomButton(
                label: AppStrings.back,
                icon: Icons.arrow_back,
                backgroundColor: AppColors.mutedText,
                onPressed:
                    _isSessionRunning
                        ? null
                        : () => Navigator.of(context).pop(),
              ),
            ] else ...[
              CustomCard(
                title: patient.fullName,
                subtitle: 'Dossier médical d’urgence',
                icon: Icons.person,
                children: [
                  _InfoRow(label: 'Âge', value: '${patient.age} ans'),
                  _InfoRow(label: 'Groupe sanguin', value: patient.bloodType),
                  _InfoRow(
                    label: 'Allergies',
                    value: _formatList(patient.allergies),
                  ),
                  _InfoRow(
                    label: 'Traitements',
                    value: _formatList(patient.treatments),
                  ),
                  _InfoRow(
                    label: 'Antécédents',
                    value: _formatList(patient.medicalHistory),
                  ),
                  _InfoRow(
                    label: 'Contact d’urgence',
                    value: patient.emergencyContact,
                  ),
                ],
              ),
              Text(
                'Historique des modifications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_history.isEmpty)
                const CustomCard(title: AppStrings.noData, icon: Icons.history)
              else
                for (final item in _history)
                  CustomCard(
                    title: _actionLabel(item.action),
                    subtitle:
                        '${_formatDate(item.timestamp)}\n${item.agentName} - ${item.hospital}',
                    icon: Icons.update,
                  ),
              const SizedBox(height: AppSpacing.md),
              CustomButton(
                label: AppStrings.back,
                icon: Icons.arrow_back,
                backgroundColor: AppColors.mutedText,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatList(List<String> values) {
    return values.isEmpty ? 'Aucun' : values.join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _actionLabel(String action) {
    return switch (action) {
      'create' => 'Création de carte',
      'read' => 'Lecture de carte',
      'update' => 'Modification de carte',
      _ => action,
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(flex: 6, child: Text(value)),
        ],
      ),
    );
  }
}
