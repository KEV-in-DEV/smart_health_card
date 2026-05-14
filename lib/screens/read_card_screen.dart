import 'package:flutter/material.dart';

import '../services/nfc_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/nfc_status_card.dart';

class ReadCardScreen extends StatefulWidget {
  const ReadCardScreen({super.key});

  @override
  State<ReadCardScreen> createState() => _ReadCardScreenState();
}

class _ReadCardScreenState extends State<ReadCardScreen> {
  NfcUiStatus _status = NfcUiStatus.waiting;
  bool _hasCard = false;
  bool _isSessionRunning = false;
  Map<String, String> _cardData = {};

  Future<void> _readCard() async {
    setState(() {
      _status = NfcUiStatus.waiting;
      _hasCard = false;
      _isSessionRunning = true;
      _cardData = {};
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
      final result = await NfcService.readCard(
        alertMessage: 'Approchez la carte pour la lecture complète',
      );

      if (!mounted) return;
      if (result.isBlank) {
        setState(() {
          _status = NfcUiStatus.blankDetected;
          _isSessionRunning = false;
        });
        return;
      }

      setState(() {
        _status = NfcUiStatus.success;
        _hasCard = true;
        _isSessionRunning = false;
        _cardData = result.data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = NfcUiStatus.incompatible;
        _isSessionRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.readCard)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            NfcStatusCard(
              status: _status,
              detail: _hasCard
                  ? '${AppStrings.cardVerified} - données lues hors ligne.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_hasCard) ...[
              CustomButton(
                label: AppStrings.startNfcRead,
                icon: Icons.nfc,
                onPressed: _isSessionRunning ? null : _readCard,
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
            if (_hasCard) ...[
              CustomCard(
                title: '${_cardData['Nom']} ${_cardData['Prénom']}',
                subtitle: 'Dossier médical d’urgence',
                icon: Icons.person,
                children: [
                  for (final entry in _cardData.entries)
                    _InfoRow(label: entry.key, value: entry.value),
                ],
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
