import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'custom_card.dart';

enum NfcUiStatus {
  nfcDisabled,
  waiting,
  detected,
  blankDetected,
  reading,
  writing,
  success,
  incompatible,
  securityError,
}

class NfcStatusCard extends StatelessWidget {
  const NfcStatusCard({
    super.key,
    required this.status,
    this.detail,
    this.action,
  });

  final NfcUiStatus status;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);

    return CustomCard(
      title: config.title,
      subtitle: detail ?? config.detail,
      icon: config.icon,
      children: [
        LinearProgressIndicator(
          value: config.showProgress ? null : 1,
          color: config.color,
          backgroundColor: config.color.withValues(alpha: 0.16),
        ),
        if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
      ],
    );
  }

  _NfcStatusConfig _configFor(NfcUiStatus status) {
    return switch (status) {
      NfcUiStatus.nfcDisabled => const _NfcStatusConfig(
        title: AppStrings.enableNfc,
        detail: 'Le téléphone doit avoir le NFC activé pour lire ou écrire.',
        icon: Icons.nfc_outlined,
        color: AppColors.burkinaOrange,
      ),
      NfcUiStatus.waiting => const _NfcStatusConfig(
        title: AppStrings.putCardNearPhone,
        detail: 'Gardez la carte proche du dos du téléphone.',
        icon: Icons.contactless_outlined,
        color: AppColors.accent,
        showProgress: true,
      ),
      NfcUiStatus.detected => const _NfcStatusConfig(
        title: AppStrings.cardDetected,
        detail: 'Verification de la carte en cours.',
        icon: Icons.credit_card,
        color: AppColors.burkinaGreen,
        showProgress: true,
      ),
      NfcUiStatus.blankDetected => const _NfcStatusConfig(
        title: AppStrings.blankCardDetected,
        detail: 'La carte peut recevoir les données du patient.',
        icon: Icons.add_card_outlined,
        color: AppColors.burkinaGreen,
      ),
      NfcUiStatus.reading => const _NfcStatusConfig(
        title: AppStrings.readingCard,
        detail: 'Lecture locale des informations de la carte.',
        icon: Icons.manage_search,
        color: AppColors.accent,
        showProgress: true,
      ),
      NfcUiStatus.writing => const _NfcStatusConfig(
        title: AppStrings.writingCard,
        detail: 'Ne retirez pas la carte pendant l’écriture.',
        icon: Icons.edit_note,
        color: AppColors.burkinaOrange,
        showProgress: true,
      ),
      NfcUiStatus.success => const _NfcStatusConfig(
        title: AppStrings.writeSuccess,
        detail: 'Vous pouvez maintenant générer l’étiquette QR.',
        icon: Icons.check_circle_outline,
        color: AppColors.burkinaGreen,
      ),
      NfcUiStatus.incompatible => const _NfcStatusConfig(
        title: AppStrings.incompatibleCard,
        detail: 'Utilisez une carte compatible avec Smart Health Card.',
        icon: Icons.error_outline,
        color: AppColors.emergencyRed,
      ),
      NfcUiStatus.securityError => const _NfcStatusConfig(
        title: AppStrings.signatureInvalid,
        detail: 'La carte ne peut pas être vérifiée.',
        icon: Icons.gpp_bad_outlined,
        color: AppColors.emergencyRed,
      ),
    };
  }
}

class _NfcStatusConfig {
  const _NfcStatusConfig({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    this.showProgress = false,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final bool showProgress;
}
