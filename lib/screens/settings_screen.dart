import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentName = ref.watch(agentSessionProvider) ?? 'Agent de santé';
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              AppStrings.appSettings,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            CustomCard(
              title: AppStrings.connectedAgent,
              subtitle: agentName,
              icon: Icons.badge_outlined,
            ),
            CustomCard(
              title: AppStrings.offlineMode,
              subtitle:
                  'Les écrans actuels utilisent des données locales et des simulations. Internet n’est pas requis.',
              icon: Icons.cloud_off_outlined,
            ),
            CustomCard(
              title: AppStrings.darkTheme,
              subtitle: isDark ? 'Thème sombre activé' : 'Thème clair activé',
              icon: isDark ? Icons.dark_mode : Icons.light_mode,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.darkTheme),
                  value: isDark,
                  activeThumbColor: AppColors.burkinaGreen,
                  onChanged: (_) {
                    ref.read(themeModeProvider.notifier).toggle();
                  },
                ),
              ],
            ),
            const CustomCard(
              title: AppStrings.security,
              subtitle:
                  'La modification des cartes NFC est réservée aux agents connectés. Le chiffrement et les signatures seront raccordés par les services de données.',
              icon: Icons.security_outlined,
            ),
            CustomButton(
              label: AppStrings.logout,
              icon: Icons.logout,
              backgroundColor: AppColors.emergencyRed,
              onPressed: () {
                ref.read(agentSessionProvider.notifier).logout();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
