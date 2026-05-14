import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_health_card/models/medical_record.dart';
import 'package:smart_health_card/state/app_state.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.history)),
      body: SafeArea(
        child: FutureBuilder<List<MedicalRecord>>(
          future: storage.getAllHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final actions = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Actions récentes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                if (actions.isEmpty)
                  const CustomCard(
                    title: AppStrings.noData,
                    subtitle:
                        'Les lectures et écritures NFC seront enregistrées ici.',
                    icon: Icons.history,
                  )
                else
                  for (final item in actions)
                    CustomCard(
                      title: _actionLabel(item.action),
                      subtitle:
                          '${_formatDate(item.timestamp)}\n${item.agentName} - ${item.hospital}\n${item.details}',
                      icon: Icons.history,
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static String _actionLabel(String action) {
    return switch (action) {
      'create' => 'Création de carte',
      'read' => 'Lecture de carte',
      'update' => 'Modification de carte',
      _ => action,
    };
  }
}
