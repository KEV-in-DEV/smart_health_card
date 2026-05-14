import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/state/app_state.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_button.dart';
import 'package:smart_health_card/widgets/custom_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.agentName});

  final String agentName;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _openBottomTab(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) Navigator.of(context).pushNamed('/history');
    if (index == 2) Navigator.of(context).pushNamed('/settings');
  }

  void _logout() {
    ref.read(agentSessionProvider.notifier).logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final storage = ref.watch(storageProvider);

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
          IconButton(
            tooltip: AppStrings.logout,
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Bonjour, ${widget.agentName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choisissez une action rapide.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              label: AppStrings.readCard,
              icon: Icons.nfc,
              onPressed: () => Navigator.of(context).pushNamed('/read-card'),
            ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: AppStrings.writeCard,
              icon: Icons.edit_note,
              backgroundColor: AppColors.burkinaOrange,
              onPressed: () => Navigator.of(context).pushNamed('/write-card'),
            ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: AppStrings.scanQr,
              icon: Icons.qr_code_scanner,
              backgroundColor: AppColors.accent,
              onPressed: () => Navigator.of(context).pushNamed('/qr-scanner'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              AppStrings.recentCards,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<List<Patient>>(
              future: storage.getRecentPatients(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final patients = snapshot.data ?? [];
                if (patients.isEmpty) {
                  return const CustomCard(
                    title: AppStrings.noData,
                    subtitle:
                        'Les cartes lues ou créées apparaîtront ici hors ligne.',
                    icon: Icons.credit_card_off_outlined,
                  );
                }
                return Column(
                  children: [
                    for (final patient in patients)
                      CustomCard(
                        title: patient.fullName,
                        subtitle:
                            'Groupe ${patient.bloodType} - ${patient.age} ans',
                        icon: Icons.credit_card,
                        onTap:
                            () => Navigator.of(context).pushNamed('/read-card'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _openBottomTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: AppStrings.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: AppStrings.history,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }
}
