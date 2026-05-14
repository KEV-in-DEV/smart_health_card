import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/nfc_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/nfc_status_card.dart';

class PublicNfcReadScreen extends ConsumerStatefulWidget {
  const PublicNfcReadScreen({super.key});

  @override
  ConsumerState<PublicNfcReadScreen> createState() => _PublicNfcReadScreenState();
}

class _PublicNfcReadScreenState extends ConsumerState<PublicNfcReadScreen> {
  NfcUiStatus _status = NfcUiStatus.waiting;
  Map<String, String>? _cardData;
  bool _isSessionRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startPublicNfcRead();
      }
    });
  }

  Future<void> _startPublicNfcRead() async {
    setState(() {
      _status = NfcUiStatus.waiting;
      _cardData = null;
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
      final result = await NfcService.readCard(
        alertMessage: 'Approchez la carte pour voir les infos publiques',
      );

      if (!mounted) return;
      if (result.isBlank) {
        setState(() {
          _status = NfcUiStatus.blankDetected;
          _isSessionRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carte vierge détectée. Aucune donnée publique trouvée.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _status = NfcUiStatus.success;
        _cardData = result.data;
        _isSessionRunning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carte détectée ! Appuyez sur le bouton pour afficher.'),
          duration: Duration(seconds: 3),
        ),
      );

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Carte détectée'),
            content: const Text(
              'Informations publiques disponibles. Appuyez sur afficher pour voir.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Afficher'),
              ),
            ],
          );
        },
      );
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
      appBar: AppBar(title: const Text(AppStrings.publicAccess)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            NfcStatusCard(
              status: _status,
              detail: _status == NfcUiStatus.success
                  ? 'Carte détectée. Appuyez pour afficher les infos publiques.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: AppStrings.startNfcRead,
              icon: Icons.nfc,
              onPressed: _isSessionRunning ? null : _startPublicNfcRead,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_cardData != null) ...[
              CustomCard(
                title: '${_cardData!['Nom']} ${_cardData!['Prénom']}',
                subtitle: 'Informations publiques',
                icon: Icons.visibility_outlined,
                children: [
                  _buildInfoRow('Nom', _cardData!['Nom'] ?? ''),
                  _buildInfoRow('Prénoms', _cardData!['Prénom'] ?? ''),
                  _buildInfoRow('Groupe sanguin', _cardData!['Groupe sanguin'] ?? ''),
                  _buildInfoRow('Contact d’urgence', _cardData!['Contact d’urgence'] ?? ''),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
