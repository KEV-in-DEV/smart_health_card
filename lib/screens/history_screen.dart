import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../widgets/custom_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _actions = [
    (
      date: '12/05/2026 18:40',
      action: 'Lecture carte patient',
      agent: 'Agent BF-102',
      hospital: 'CHU Yalgado Ouedraogo',
    ),
    (
      date: '12/05/2026 16:15',
      action: 'Modification traitements',
      agent: 'Agent BF-102',
      hospital: 'CMA de Pissy',
    ),
    (
      date: '11/05/2026 09:10',
      action: 'Creation carte',
      agent: 'Agent BF-087',
      hospital: 'CHR de Koudougou',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.history)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Actions recentes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            // TODO: remplacer par Storage.getHistory().
            for (final item in _actions)
              CustomCard(
                title: item.action,
                subtitle: '${item.date}\n${item.agent} - ${item.hospital}',
                icon: Icons.history,
              ),
          ],
        ),
      ),
    );
  }
}
