import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _hasScanned = false;

  void _simulateScan() {
    setState(() => _hasScanned = true);
  }

  Map<String, String> _publicData() {
    return const {
      'Nom': 'Traore',
      'Prénom': 'Issa',
      'Groupe sanguin': 'B+',
      'Contact d’urgence': '+226 70 12 34 56',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isAgentConnected = ref.watch(isAgentConnectedProvider);
    final fullData = isAgentConnected
        ? ref.read(cardRepositoryProvider.notifier).findCardByName('Traore', 'Issa')
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.scanQr)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.text,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.white,
                  size: 110,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              label: AppStrings.scanSimulation,
              icon: Icons.camera_alt_outlined,
              onPressed: _simulateScan,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_hasScanned)
              CustomCard(
                title: isAgentConnected
                    ? 'Infos patient complètes'
                    : AppStrings.publicDataOnly,
                icon: isAgentConnected
                    ? Icons.health_and_safety
                    : Icons.verified_user_outlined,
                children: [
                  for (final entry in _publicData().entries)
                    _PublicInfo(label: entry.key, value: entry.value),
                  if (isAgentConnected && fullData != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    _PublicInfo(label: 'Date de naissance', value: fullData['Date de naissance'] ?? '-'),
                    _PublicInfo(label: 'Allergies', value: fullData['Allergies'] ?? '-'),
                    _PublicInfo(label: 'Traitements', value: fullData['Traitements'] ?? '-'),
                    _PublicInfo(label: 'Antécédents', value: fullData['Antécédents'] ?? '-'),
                  ],
                  if (isAgentConnected && fullData == null)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Carte inconnue en local : seules les informations publiques sont disponibles.',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PublicInfo extends StatelessWidget {
  const _PublicInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text('$label : $value'),
    );
  }
}
