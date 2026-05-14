import 'package:smart_health_card/models/patient.dart';

class PatientValidation {
  static ValidationResult validate(Patient patient) {
    final errors = <String>[];
    final warnings = <String>[];

    if (patient.firstName.trim().isEmpty) {
      errors.add('Le prénom est obligatoire');
    }

    if (patient.lastName.trim().isEmpty) {
      errors.add('Le nom est obligatoire');
    }

    if (patient.birthDate.isAfter(DateTime.now())) {
      errors.add('La date de naissance ne peut pas être dans le futur');
    }

    if (patient.birthDate.year < 1900) {
      errors.add('La date de naissance semble invalide');
    }

    const validBloodTypes = [
      'A+',
      'A-',
      'B+',
      'B-',
      'AB+',
      'AB-',
      'O+',
      'O-',
      '',
    ];
    if (!validBloodTypes.contains(patient.bloodType)) {
      warnings.add('Groupe sanguin non reconnu : ${patient.bloodType}');
    }

    if (patient.emergencyContact.isEmpty) {
      warnings.add('Le contact d’urgence est recommandé');
    } else if (patient.emergencyContact.length < 8) {
      warnings.add('Le contact d’urgence semble trop court');
    }

    final estimatedSize = _estimateDataSize(patient);
    if (estimatedSize > 800) {
      errors.add(
        'Les données dépassent la capacité estimée de la carte NFC ($estimatedSize > 800 octets). Réduisez les antécédents.',
      );
    } else if (estimatedSize > 700) {
      warnings.add(
        'Les données sont proches de la limite estimée de la carte NFC ($estimatedSize / 800 octets)',
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      estimatedSize: estimatedSize,
    );
  }

  static int _estimateDataSize(Patient patient) {
    return patient.toJson().toString().length;
  }

  static Future<bool> isValidForNfc(Patient patient) async {
    return validate(patient).isValid;
  }

  static Patient clean(Patient patient) {
    return patient.copyWith(
      firstName: patient.firstName.trim(),
      lastName: patient.lastName.trim(),
      allergies: patient.allergies.where((a) => a.trim().isNotEmpty).toList(),
      treatments: patient.treatments.where((t) => t.trim().isNotEmpty).toList(),
      medicalHistory:
          patient.medicalHistory.where((h) => h.trim().isNotEmpty).toList(),
      emergencyContact: patient.emergencyContact.trim(),
    );
  }
}

class ValidationResult {
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.estimatedSize,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int estimatedSize;

  String getFormattedMessage() {
    final buffer = StringBuffer();

    if (errors.isNotEmpty) {
      buffer.writeln('Erreurs :');
      for (final error in errors) {
        buffer.writeln('- $error');
      }
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('Avertissements :');
      for (final warning in warnings) {
        buffer.writeln('- $warning');
      }
    }

    if (isValid) {
      buffer.write('Données valides. Taille estimée : $estimatedSize octets.');
    } else {
      buffer.write('Données invalides. Corrigez les erreurs.');
    }

    return buffer.toString();
  }
}
