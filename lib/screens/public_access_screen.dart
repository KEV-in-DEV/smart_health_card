import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_health_card/state/app_state.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_button.dart';
import 'package:smart_health_card/widgets/custom_card.dart';

class PublicAccessScreen extends ConsumerWidget {
  const PublicAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            tooltip:
                isDark ? 'Passer au thème clair' : 'Passer au thème sombre',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.md),
            const Icon(
              Icons.health_and_safety,
              color: AppColors.burkinaGreen,
              size: 84,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.publicAccess,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sans connexion, vous pouvez seulement scanner le QR code d’une carte déjà créée.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            const CustomCard(
              title: AppStrings.publicDataOnly,
              subtitle:
                  'Nom, prénoms, groupe sanguin et contact urgence uniquement.',
              icon: Icons.visibility_outlined,
            ),
            CustomButton(
              label: AppStrings.publicQrOnly,
              icon: Icons.qr_code_scanner,
              backgroundColor: AppColors.accent,
              onPressed: () => Navigator.of(context).pushNamed('/qr-scanner'),
            ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: AppStrings.agentAccess,
              icon: Icons.login,
              onPressed: () => Navigator.of(context).pushNamed('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
