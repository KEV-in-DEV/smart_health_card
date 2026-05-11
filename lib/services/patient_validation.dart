import 'package:smart_health_card/models/patient.dart';

class PatientValidation {
  
  /// Valide toutes les données du patient
  static ValidationResult validate(Patient patient) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Vérifie le nom
    if (patient.firstName.trim().isEmpty) {
      errors.add("Le prénom est obligatoire");
    }
    
    if (patient.lastName.trim().isEmpty) {
      errors.add("Le nom est obligatoire");
    }
    
    // Vérifie la date de naissance
    if (patient.birthDate.isAfter(DateTime.now())) {
      errors.add("La date de naissance ne peut pas être dans le futur");
    }
    
    if (patient.birthDate.year < 1900) {
      errors.add("La date de naissance semble invalide");
    }
    
    // Vérifie le groupe sanguin
    final validBloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", ""];
    if (!validBloodTypes.contains(patient.bloodType)) {
      warnings.add("Groupe sanguin non reconnu: ${patient.bloodType}");
    }
    
    // Vérifie le contact d'urgence
    if (patient.emergencyContact.isEmpty) {
      warnings.add("Le contact d'urgence est recommandé");
    } else if (patient.emergencyContact.length < 8) {
      warnings.add("Le contact d'urgence semble trop court");
    }
    
    // Vérifie la taille des données (pour NFC)
    final estimatedSize = _estimateDataSize(patient);
    if (estimatedSize > 800) {
      errors.add("Les données dépassent la capacité de la carte NFC (${estimatedSize} > 800 octets). Réduisez les antécédents.");
    } else if (estimatedSize > 700) {
      warnings.add("Les données sont proches de la limite de la carte NFC ($estimatedSize / 800 octets)");
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      estimatedSize: estimatedSize,
    );
  }
  
  /// Estime la taille des données en JSON
  static int _estimateDataSize(Patient patient) {
    final json = patient.toJson();
    final string = json.toString();
    return string.length;
  }
  
  /// Valide spécifiquement pour l'écriture NFC
  static Future<bool> isValidForNfc(Patient patient) async {
    final result = validate(patient);
    return result.isValid;
  }
  
  /// Nettoie les données (trim, remove empty strings)
  static Patient clean(Patient patient) {
    return patient.copyWith(
      firstName: patient.firstName.trim(),
      lastName: patient.lastName.trim(),
      allergies: patient.allergies.where((a) => a.trim().isNotEmpty).toList(),
      treatments: patient.treatments.where((t) => t.trim().isNotEmpty).toList(),
      medicalHistory: patient.medicalHistory.where((h) => h.trim().isNotEmpty).toList(),
      emergencyContact: patient.emergencyContact.trim(),
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int estimatedSize;
  
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.estimatedSize,
  });
  
  String getFormattedMessage() {
    final buffer = StringBuffer();
    
    if (errors.isNotEmpty) {
      buffer.writeln("❌ ERREURS:");
      for (final error in errors) {
        buffer.writeln("   - $error");
      }
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln("⚠️ AVERTISSEMENTS:");
      for (final warning in warnings) {
        buffer.writeln("   - $warning");
      }
    }
    
    if (isValid) {
      buffer.write("✅ Données valides. ");
      buffer.write("Taille estimée: $estimatedSize octets.");
    } else {
      buffer.write("❌ Données invalides. Corrigez les erreurs.");
    }
    
    return buffer.toString();
  }
}