import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/nfc_status_card.dart';

class AgentRequiredScreen extends StatelessWidget {
  const AgentRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.agentRequired)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const NfcStatusCard(
              status: NfcUiStatus.securityError,
              detail:
                  'La lecture complète, la modification et l’écriture NFC sont réservées aux agents connectés.',
            ),
            CustomButton(
              label: AppStrings.agentAccess,
              icon: Icons.login,
              onPressed: () => Navigator.of(context).pushNamed('/login'),
            ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: AppStrings.publicQrOnly,
              icon: Icons.qr_code_scanner,
              backgroundColor: AppColors.accent,
              onPressed: () => Navigator.of(context).pushNamed('/qr-scanner'),
            ),
          ],
        ),
      ),
    );
  }
}
