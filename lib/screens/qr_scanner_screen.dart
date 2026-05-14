import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_health_card/models/public_info.dart';
import 'package:smart_health_card/state/app_state.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_button.dart';
import 'package:smart_health_card/widgets/custom_card.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  PublicInfo? _info;
  bool _isScanning = false;

  Future<void> _scanQr() async {
    setState(() => _isScanning = true);
    try {
      final info = await ref.read(qrServiceProvider).scanQR();
      if (!mounted) return;
      setState(() => _info = info);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Scan QR impossible : $e')));
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              label: AppStrings.scanQr,
              icon: Icons.camera_alt_outlined,
              isLoading: _isScanning,
              onPressed: _scanQr,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_info != null)
              CustomCard(
                title: AppStrings.publicDataOnly,
                icon: Icons.verified_user_outlined,
                children: [
                  _PublicInfo(label: 'Nom', value: _info!.name),
                  _PublicInfo(label: 'Groupe sanguin', value: _info!.bloodType),
                  _PublicInfo(
                    label: 'Téléphone d’urgence',
                    value: _info!.emergencyPhone,
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
