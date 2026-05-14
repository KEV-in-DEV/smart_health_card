import 'dart:convert';

import '../models/temporary_models.dart';

/// Resultat de validation avant ecriture NFC.
class PatientValidationResult {
  const PatientValidationResult({
    required this.isValid,
    required this.errors,
    required this.payloadSize,
  });

  final bool isValid;
  final List<String> errors;
  final int payloadSize;
}

/// Verifie que les donnees patient sont completes et compatibles NTAG216.
class PatientValidation {
  static const int maxNtag216PayloadBytes = 800;
  static const Set<String> acceptedBloodTypes = <String>{
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  };

  /// Retourne true si le patient peut etre ecrit sur la carte.
  static bool canWrite(Patient patient) => validate(patient).isValid;

  /// Controle les champs obligatoires et la taille UTF-8 du JSON.
  static PatientValidationResult validate(Patient patient) {
    final errors = <String>[];

    if (patient.id.trim().isEmpty) {
      errors.add('Identifiant patient manquant.');
    }
    if (patient.firstName.trim().isEmpty) {
      errors.add('Prenom patient manquant.');
    }
    if (patient.lastName.trim().isEmpty) {
      errors.add('Nom patient manquant.');
    }
    if (!acceptedBloodTypes.contains(patient.bloodType.trim().toUpperCase())) {
      errors.add('Groupe sanguin invalide.');
    }
    if (patient.emergencyContact.trim().isEmpty) {
      errors.add('Contact urgence manquant.');
    }
    if (patient.birthDate.isAfter(DateTime.now())) {
      errors.add('Date de naissance invalide.');
    }

    final payloadSize =
        utf8
            .encode(SmartHealthCardPayload.fromPatient(patient).toJsonString())
            .length;
    if (payloadSize > maxNtag216PayloadBytes) {
      errors.add(
        'Donnees trop volumineuses pour le MVP NFC '
        '($payloadSize/$maxNtag216PayloadBytes octets).',
      );
    }

    return PatientValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      payloadSize: payloadSize,
    );
  }
}
