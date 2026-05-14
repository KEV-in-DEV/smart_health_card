import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class CardLabelScreen extends StatelessWidget {
  const CardLabelScreen({super.key, required this.data});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    final publicData = {
      'Nom': data['Nom'] ?? '',
      'Prenom': data['Prenom'] ?? '',
      'Groupe sanguin': data['Groupe sanguin'] ?? '',
      'Contact urgence': data['Contact urgence'] ?? '',
    };
    final qrPayload =
        'SMART_HEALTH_CARD_PUBLIC|'
        'nom=${publicData['Nom']}|'
        'prenom=${publicData['Prenom']}|'
        'groupe=${publicData['Groupe sanguin']}|'
        'urgence=${publicData['Contact urgence']}';

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
              title: '${publicData['Nom']} ${publicData['Prenom']}',
              subtitle:
                  'Groupe sanguin : ${publicData['Groupe sanguin']}\nContact d’urgence : ${publicData['Contact urgence']}',
              icon: Icons.badge_outlined,
              children: [
                Center(
                  child: Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 210,
                      backgroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            CustomButton(
              label: AppStrings.printLabel,
              icon: Icons.print,
              onPressed: () {
                // TODO: remplacer par un service d'impression/export PDF si l’équipe l’ajoute.
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
              onPressed: () => Navigator.of(
                context,
              ).popUntil((route) => route.settings.name == '/home'),
            ),
          ],
        ),
      ),
    );
  }
}
