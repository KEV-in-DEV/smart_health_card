import 'package:flutter/material.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/models/medical_record.dart';
import 'package:smart_health_card/models/agent.dart';
import 'package:smart_health_card/database/local_storage.dart';
import 'package:smart_health_card/services/encryption_service.dart';
import 'package:smart_health_card/services/backup_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final LocalStorage _storage = LocalStorage();
  final EncryptionService _encryption = EncryptionService();
  final BackupService _backup = BackupService();
  
  String _log = "=== LOG DES TESTS ===\n";
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _log += "$message\n";
    });
    print(message);
  }

  Future<void> _testEncryption() async {
    setState(() => _isLoading = true);
    try {
      _addLog("\n--- TEST CHIFFREMENT ---");
      
      final original = "Données médicales secrètes du patient";
      final encrypted = await _encryption.encrypt(original);
      final decrypted = await _encryption.decrypt(encrypted);
      
      _addLog("Original: $original");
      _addLog("Chiffré: $encrypted");
      _addLog("Déchiffré: $decrypted");
      _addLog("✅ Résultat: ${original == decrypted ? 'OK' : 'ERREUR'}");
    } catch (e) {
      _addLog("❌ Erreur chiffrement: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testPasswordHash() async {
    setState(() => _isLoading = true);
    try {
      _addLog("\n--- TEST HASH MOT DE PASSE ---");
      
      final password = "monMotDePasse123";
      final hashed = await _encryption.hashPassword(password);
      final isValid = await _encryption.verifyPassword(password, hashed);
      final isInvalid = await _encryption.verifyPassword("wrongPassword", hashed);
      
      _addLog("Mot de passe: $password");
      _addLog("Hash généré: $hashed");
      _addLog("Vérification correcte: $isValid");
      _addLog("Vérification incorrecte: $isInvalid");
      _addLog("✅ Résultat: ${isValid && !isInvalid ? 'OK' : 'ERREUR'}");
    } catch (e) {
      _addLog("❌ Erreur hash: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testDatabase() async {
    setState(() => _isLoading = true);
    try {
      _addLog("\n--- TEST BASE DE DONNÉES ---");
      
      final patient = Patient(
        firstName: "Fatimata",
        lastName: "ZONGO",
        birthDate: DateTime(1990, 5, 15),
        bloodType: "A+",
        allergies: ["Pénicilline", "Arachides"],
        treatments: ["Paracétamol 500mg"],
        medicalHistory: ["Paludisme 2022", "Typhoïde 2023"],
        emergencyContact: "+226 70 12 34 56",
      );
      
      await _storage.savePatient(patient);
      _addLog("✅ Patient sauvegardé: ${patient.fullName}");
      
      final retrieved = await _storage.getPatient(patient.id);
      if (retrieved != null) {
        _addLog("✅ Patient récupéré: ${retrieved.fullName} (${retrieved.age} ans)");
        _addLog("   Groupe sanguin: ${retrieved.bloodType}");
        _addLog("   Allergies: ${retrieved.allergies.join(', ')}");
      }
      
      final recent = await _storage.getRecentPatients(limit: 5);
      _addLog("✅ ${recent.length} patient(s) récent(s) dans la base");
      
      final historyRecord = MedicalRecord(
        patientId: patient.id,
        timestamp: DateTime.now(),
        agentId: "AGENT001",
        agentName: "Dr DIALLO",
        hospital: "Hôpital A",
        action: "create",
        details: "Création du dossier patient",
        signature: "signature_test",
      );
      await _storage.addHistoryRecord(historyRecord);
      _addLog("✅ Historique ajouté");
      
      final history = await _storage.getHistoryForPatient(patient.id);
      _addLog("✅ ${history.length} enregistrement(s) d'historique");
      
    } catch (e) {
      _addLog("❌ Erreur base données: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testBackup() async {
    setState(() => _isLoading = true);
    try {
      _addLog("\n--- TEST BACKUP ---");
      
      final backupFile = await _backup.exportAllData();
      _addLog("✅ Backup créé: ${backupFile.path}");
      _addLog("   Taille: ${await backupFile.length()} octets");
      
      final report = await _backup.integrityReport();
      _addLog("✅ Rapport intégrité: ${report['totalPatients']} patients, ${report['totalHistoryRecords']} historiques");
      
    } catch (e) {
      _addLog("❌ Erreur backup: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _runAllTests() async {
    await _testEncryption();
    await _testPasswordHash();
    await _testDatabase();
    await _testBackup();
    _addLog("\n=== TOUS LES TESTS TERMINÉS ===");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧪 TEST - Personne C"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Boutons de test (CORRIGÉ : Padding autour de Wrap)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testEncryption,
                  icon: const Icon(Icons.lock),
                  label: const Text("Chiffrement"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testPasswordHash,
                  icon: const Icon(Icons.key),
                  label: const Text("Hash mot de passe"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testDatabase,
                  icon: const Icon(Icons.storage),
                  label: const Text("Base de données"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testBackup,
                  icon: const Icon(Icons.backup),
                  label: const Text("Backup"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runAllTests,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("TOUS LES TESTS"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
          // Zone de logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _log,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}