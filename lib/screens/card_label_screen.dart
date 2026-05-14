import 'package:flutter/material.dart';
import 'package:smart_health_card/models/public_info.dart';
import 'package:smart_health_card/services/qr_service.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_button.dart';
import 'package:smart_health_card/widgets/custom_card.dart';

class CardLabelScreen extends StatelessWidget {
  const CardLabelScreen({super.key, required this.data});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    final info = PublicInfo(
      name: '${data['Nom'] ?? ''} ${data['Prenom'] ?? ''}'.trim(),
      bloodType: data['Groupe sanguin'] ?? '',
      emergencyPhone: data['Contact urgence'] ?? '',
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.labelPreview)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'À coller sur la carte',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cette étiquette ne contient que les informations publiques.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomCard(
              title: info.name,
              subtitle:
                  'Groupe sanguin : ${info.bloodType}\nContact d’urgence : ${info.emergencyPhone}',
              icon: Icons.badge_outlined,
              children: [
                Center(
                  child: Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: QrService().generateQR(info),
                  ),
                ),
              ],
            ),
            CustomButton(
              label: AppStrings.printLabel,
              icon: Icons.print,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonction impression à connecter plus tard.'),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: AppStrings.home,
              icon: Icons.home_outlined,
              backgroundColor: AppColors.mutedText,
              onPressed:
                  () => Navigator.of(
                    context,
                  ).popUntil((route) => route.settings.name == '/home'),
            ),
          ],
        ),
      ),
    );
  }
}
