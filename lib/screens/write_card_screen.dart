import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class WriteCardScreen extends StatefulWidget {
  const WriteCardScreen({super.key});

  @override
  State<WriteCardScreen> createState() => _WriteCardScreenState();
}

class _WriteCardScreenState extends State<WriteCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fields = <String, TextEditingController>{
    'Nom': TextEditingController(),
    'Prénom': TextEditingController(),
    'Date de naissance': TextEditingController(),
    'Groupe sanguin': TextEditingController(),
    'Allergies': TextEditingController(),
    'Traitements': TextEditingController(),
    'Antécédents': TextEditingController(),
    'Contact d’urgence': TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _continueToNfc() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pushNamed('/nfc-write', arguments: _allPatientData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.writeCard)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Informations patient',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final entry in _fields.entries) ...[
                TextFormField(
                  controller: entry.value,
                  minLines: _isLongField(entry.key) ? 2 : 1,
                  maxLines: _isLongField(entry.key) ? 4 : 1,
                  keyboardType: entry.key == 'Contact d’urgence'
                      ? TextInputType.phone
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    prefixIcon: Icon(_iconForField(entry.key)),
                  ),
                  validator: (value) {
                    final isRequired = [
                      'Nom',
                      'Prénom',
                      'Date de naissance',
                      'Groupe sanguin',
                    ].contains(entry.key);
                    if (isRequired && (value == null || value.trim().isEmpty)) {
                      return AppStrings.requiredFields;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              CustomButton(
                label: AppStrings.continueToNfc,
                icon: Icons.arrow_forward,
                backgroundColor: AppColors.burkinaOrange,
                onPressed: _continueToNfc,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLongField(String field) {
    return ['Allergies', 'Traitements', 'Antécédents'].contains(field);
  }

  IconData _iconForField(String field) {
    return switch (field) {
      'Nom' || 'Prénom' => Icons.person_outline,
      'Date de naissance' => Icons.calendar_today_outlined,
      'Groupe sanguin' => Icons.bloodtype_outlined,
      'Contact d’urgence' => Icons.phone_outlined,
      _ => Icons.medical_information_outlined,
    };
  }

  Map<String, String> _allPatientData() {
    return {
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
    };
  }
}
