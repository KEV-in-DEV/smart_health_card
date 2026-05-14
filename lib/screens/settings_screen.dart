import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_health_card/state/app_state.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_button.dart';
import 'package:smart_health_card/widgets/custom_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(agentSessionProvider);
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
              subtitle:
                  agent == null
                      ? 'Aucun agent'
                      : '${agent.name}\n${agent.hospital}',
              icon: Icons.badge_outlined,
            ),
            const CustomCard(
              title: AppStrings.offlineMode,
              subtitle:
                  'Les données sont enregistrées localement. Internet n’est pas requis pour créer, lire ou consulter l’historique.',
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
                  'Les données médicales NFC sont chiffrées par le service de sécurité. La modification est réservée aux agents connectés.',
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
