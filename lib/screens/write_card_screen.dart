import 'package:flutter/material.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/services/patient_validation.dart';
import 'package:smart_health_card/utils/constants.dart';
import 'package:smart_health_card/widgets/custom_button.dart';

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
    'Date de naissance': TextEditingController(text: '1990-01-01'),
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
    final patient = _buildPatient();
    final validation = PatientValidation.validate(patient);

    if (!validation.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation.errors.join('\n'))));
      return;
    }

    Navigator.of(context).pushNamed('/nfc-write', arguments: patient);
  }

  Patient _buildPatient() {
    return Patient(
      lastName: _text('Nom'),
      firstName: _text('Prénom'),
      birthDate: _parseBirthDate(_text('Date de naissance')),
      bloodType: _text('Groupe sanguin'),
      allergies: _splitLines(_text('Allergies')),
      treatments: _splitLines(_text('Traitements')),
      medicalHistory: _splitLines(_text('Antécédents')),
      emergencyContact: _text('Contact d’urgence'),
    );
  }

  String _text(String key) => _fields[key]!.text.trim();

  List<String> _splitLines(String value) {
    return value
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  DateTime _parseBirthDate(String value) {
    final normalized = value.trim();
    final direct = DateTime.tryParse(normalized);
    if (direct != null) return direct;

    final parts = normalized.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.now().subtract(const Duration(days: 365 * 30));
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
                  keyboardType:
                      entry.key == 'Contact d’urgence'
                          ? TextInputType.phone
                          : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    helperText:
                        entry.key == 'Date de naissance'
                            ? 'Format : AAAA-MM-JJ ou JJ/MM/AAAA'
                            : null,
                    prefixIcon: Icon(_iconForField(entry.key)),
                  ),
                  validator: (value) {
                    final isRequired = [
                      'Nom',
                      'Prénom',
                      'Date de naissance',
                      'Groupe sanguin',
                      'Contact d’urgence',
                    ].contains(entry.key);
                    if (isRequired && (value == null || value.trim().isEmpty)) {
                      return AppStrings.requiredFields;
                    }
                    if (entry.key == 'Date de naissance' &&
                        value != null &&
                        value.trim().isNotEmpty &&
                        DateTime.tryParse(value.trim()) == null &&
                        value.split('/').length != 3) {
                      return 'Date invalide.';
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
}
