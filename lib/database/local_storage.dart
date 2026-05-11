import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/models/medical_record.dart';
import 'package:smart_health_card/models/agent.dart';
import 'database_helper.dart';

class LocalStorage implements IStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  LocalStorage._internal();

  factory LocalStorage() {
    return _instance;
  }

  /// Initialise Hive (à appeler dans main())
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('patient_cache');
  }

  Box<dynamic> get _cache => Hive.box('patient_cache');

  // ==================== PATIENTS ====================

  @override
  Future<void> savePatient(Patient patient) async {
    // Sauvegarde SQLite
    await _dbHelper.insertOrUpdatePatient(patient.toMap());
    
    // Cache Hive pour accès rapide
    await _cache.put(patient.id, patient.toMap());
  }

  @override
  Future<Patient?> getPatient(String id) async {
    // D'abord dans le cache
    final cached = _cache.get(id);
    if (cached != null) {
      return Patient.fromMap(Map<String, dynamic>.from(cached));
    }
    
    // Sinon en SQLite
    final data = await _dbHelper.getPatient(id);
    if (data != null) {
      final patient = Patient.fromMap(data);
      await _cache.put(patient.id, patient.toMap());
      return patient;
    }
    return null;
  }

  @override
  Future<List<Patient>> getRecentPatients({int limit = 10}) async {
    final data = await _dbHelper.getRecentPatients(limit: limit);
    return data.map((e) => Patient.fromMap(e)).toList();
  }

  @override
  Future<void> deletePatient(String id) async {
    await _dbHelper.deletePatient(id);
    await _cache.delete(id);
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    await savePatient(patient);
  }

  // ==================== HISTORY ====================

  @override
  Future<void> addHistoryRecord(MedicalRecord record) async {
    await _dbHelper.insertHistoryRecord(record.toMap());
  }

  @override
  Future<List<MedicalRecord>> getHistoryForPatient(String patientId) async {
    final data = await _dbHelper.getHistoryForPatient(patientId);
    return data.map((e) => MedicalRecord.fromMap(e)).toList();
  }

  @override
  Future<List<MedicalRecord>> getAllHistory() async {
    final data = await _dbHelper.getAllHistory();
    return data.map((e) => MedicalRecord.fromMap(e)).toList();
  }

  // ==================== AGENTS ====================

  Future<void> saveAgent(Agent agent) async {
    await _dbHelper.insertAgent(agent.toMap());
  }

  Future<Agent?> getAgent(String id) async {
    final data = await _dbHelper.getAgent(id);
    if (data != null) {
      return Agent.fromMap(data);
    }
    return null;
  }

  Future<Agent?> authenticate(String id, String hashedPassword) async {
    final data = await _dbHelper.authenticateAgent(id, hashedPassword);
    if (data != null) {
      return Agent.fromMap(data);
    }
    return null;
  }

  // ==================== UTILITAIRES ====================

  Future<void> clearAll() async {
    await _dbHelper.clearAll();
    await _cache.clear();
  }
}

// Interface que l'équipe a définie
abstract class IStorage {
  Future<void> savePatient(Patient patient);
  Future<Patient?> getPatient(String id);
  Future<List<Patient>> getRecentPatients({int limit});
  Future<void> deletePatient(String id);
  Future<void> updatePatient(Patient patient);
  Future<void> addHistoryRecord(MedicalRecord record);
  Future<List<MedicalRecord>> getHistoryForPatient(String patientId);
  Future<List<MedicalRecord>> getAllHistory();
}