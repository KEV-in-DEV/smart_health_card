import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smart_health_card.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table patients
    await db.execute('''
      CREATE TABLE patients(
        id TEXT PRIMARY KEY,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        birthDate TEXT NOT NULL,
        bloodType TEXT NOT NULL,
        allergies TEXT,
        treatments TEXT,
        medicalHistory TEXT,
        emergencyContact TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Table medical_history
    await db.execute('''
      CREATE TABLE medical_history(
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        agentId TEXT NOT NULL,
        agentName TEXT NOT NULL,
        hospital TEXT NOT NULL,
        action TEXT NOT NULL,
        details TEXT,
        signature TEXT NOT NULL,
        FOREIGN KEY(patientId) REFERENCES patients(id) ON DELETE CASCADE
      )
    ''');

    // Table agents
    await db.execute('''
      CREATE TABLE agents(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        hospital TEXT NOT NULL,
        hashedPassword TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // Index pour les requêtes rapides
    await db.execute('CREATE INDEX idx_patient_name ON patients(lastName)');
    await db.execute(
      'CREATE INDEX idx_history_patient ON medical_history(patientId)',
    );
    await db.execute(
      'CREATE INDEX idx_history_timestamp ON medical_history(timestamp)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrations futures
      // await db.execute('ALTER TABLE patients ADD COLUMN newColumn TEXT');
    }
  }

  /// Insère ou remplace un patient
  Future<void> insertOrUpdatePatient(Map<String, dynamic> patient) async {
    final db = await database;
    await db.insert(
      'patients',
      patient,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère un patient par ID
  Future<Map<String, dynamic>?> getPatient(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Récupère tous les patients
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;
    return await db.query('patients', orderBy: 'lastName ASC');
  }

  /// Récupère les N derniers patients
  Future<List<Map<String, dynamic>>> getRecentPatients({int limit = 10}) async {
    final db = await database;
    return await db.query('patients', orderBy: 'updatedAt DESC', limit: limit);
  }

  /// Supprime un patient
  Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MEDICAL HISTORY ====================

  /// Ajoute un enregistrement d'historique
  Future<void> insertHistoryRecord(Map<String, dynamic> record) async {
    final db = await database;
    await db.insert('medical_history', record);
  }

  /// Récupère l'historique d'un patient
  Future<List<Map<String, dynamic>>> getHistoryForPatient(
    String patientId,
  ) async {
    final db = await database;
    return await db.query(
      'medical_history',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'timestamp DESC',
    );
  }

  /// Récupère tout l'historique
  Future<List<Map<String, dynamic>>> getAllHistory() async {
    final db = await database;
    return await db.query('medical_history', orderBy: 'timestamp DESC');
  }

  // ==================== AGENTS ====================

  /// Ajoute un agent
  Future<void> insertAgent(Map<String, dynamic> agent) async {
    final db = await database;
    await db.insert(
      'agents',
      agent,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère un agent par ID
  Future<Map<String, dynamic>?> getAgent(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'agents',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Vérifie les identifiants
  Future<Map<String, dynamic>?> authenticateAgent(
    String id,
    String hashedPassword,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'agents',
      where: 'id = ? AND hashedPassword = ?',
      whereArgs: [id, hashedPassword],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Supprime tout (pour tests)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('medical_history');
    await db.delete('patients');
    await db.delete('agents');
  }
}
