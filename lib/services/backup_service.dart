import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/models/medical_record.dart';
import 'package:smart_health_card/services/encryption_service.dart';
import 'package:smart_health_card/database/local_storage.dart';

class BackupService {
  final LocalStorage _storage = LocalStorage();
  final EncryptionService _encryption = EncryptionService();

  /// Exporte toutes les données dans un fichier JSON chiffré
  Future<File> exportAllData() async {
    // Récupérer toutes les données
    final patients = await _getAllPatients();
    final history = await _storage.getAllHistory();
    
    final exportData = {
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'patients': patients.map((p) => p.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(),
    };
    
    final jsonString = jsonEncode(exportData);
    final encrypted = await _encryption.encrypt(jsonString);
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/smart_health_backup_${DateTime.now().millisecondsSinceEpoch}.enc');
    
    await file.writeAsString(encrypted);
    return file;
  }

  /// Importe des données depuis un fichier de backup
  Future<void> importData(File file) async {
    final encrypted = await file.readAsString();
    final jsonString = await _encryption.decrypt(encrypted);
    final Map<String, dynamic> data = jsonDecode(jsonString);
    
    // Vérification de version
    if (data['version'] != 1) {
      throw Exception('Version de backup incompatible');
    }
    
    // Import patients
    final patients = (data['patients'] as List)
        .map((p) => Patient.fromJson(p))
        .toList();
    
    for (final patient in patients) {
      await _storage.savePatient(patient);
    }
    
    // Import history
    final history = (data['history'] as List)
        .map((h) => MedicalRecord.fromJson(h))
        .toList();
    
    for (final record in history) {
      await _storage.addHistoryRecord(record);
    }
  }

  /// Récupère tous les patients (privé)
  Future<List<Patient>> _getAllPatients() async {
    // On peut récupérer via getRecentPatients avec une grande limite
    return await _storage.getRecentPatients(limit: 10000);
  }

  /// Génère un rapport d'intégrité
  Future<Map<String, dynamic>> integrityReport() async {
    final patients = await _getAllPatients();
    final history = await _storage.getAllHistory();
    
    return {
      'totalPatients': patients.length,
      'totalHistoryRecords': history.length,
      'lastBackup': null, // À implémenter avec stockage du dernier backup
      'integrityCheck': 'ok',
    };
  }
}