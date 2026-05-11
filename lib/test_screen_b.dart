import 'package:flutter/material.dart';
import 'package:smart_health_card/models/patient.dart';
import 'package:smart_health_card/models/public_info.dart';
import 'package:smart_health_card/services/nfc_service.dart';
import 'package:smart_health_card/services/qr_service.dart';
import 'package:smart_health_card/services/patient_validation.dart';

class TestScreenB extends StatefulWidget {
  const TestScreenB({super.key});

  @override
  State<TestScreenB> createState() => _TestScreenBState();
}

class _TestScreenBState extends State<TestScreenB> {
  final NfcService _nfc = NfcService();
  final QrService _qr = QrService();
  
  String _log = "=== TESTS NFC & QR ===\nAppuyez sur un bouton pour tester\n";
  bool _isLoading = false;
  Patient? _lastReadPatient;

  void _addLog(String message) {
    setState(() {
      _log += "$message\n";
    });
    print(message);
  }

  Future<void> _testNfcRead() async {
    setState(() => _isLoading = true);
    _addLog("\n--- LECTURE NFC ---");
    _addLog("Posez la carte sur le téléphone...");
    
    try {
      final patient = await _nfc.readCard();
      if (patient != null) {
        _lastReadPatient = patient;
        _addLog("✅ Carte lue avec succès !");
        _addLog("   Patient: ${patient.fullName}");
        _addLog("   Groupe: ${patient.bloodType}");
        _addLog("   Allergies: ${patient.allergies.join(', ')}");
      } else {
        _addLog("❌ Aucune carte détectée");
      }
    } catch (e) {
      _addLog("❌ Erreur: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testNfcWrite() async {
    setState(() => _isLoading = true);
    _addLog("\n--- ÉCRITURE NFC ---");
    
    // Crée un patient test
    final testPatient = Patient(
      firstName: "TEST",
      lastName: "NFC",
      birthDate: DateTime(1995, 1, 1),
      bloodType: "O+",
      allergies: ["Aucune"],
      treatments: ["Aucun"],
      medicalHistory: ["Patient test créé le ${DateTime.now()}"],
      emergencyContact: "+226 00 00 00 00",
    );
    
    _addLog("Patient à écrire: ${testPatient.fullName}");
    _addLog("Posez la carte vierge sur le téléphone...");
    
    try {
      final success = await _nfc.writeCard(testPatient, "testpassword123");
      if (success) {
        _addLog("✅ Écriture réussie !");
      } else {
        _addLog("❌ Écriture échouée");
      }
    } catch (e) {
      _addLog("❌ Erreur: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testValidation() async {
    setState(() => _isLoading = true);
    _addLog("\n--- VALIDATION DONNÉES ---");
    
    final testPatient = Patient(
      firstName: "   Fatimata   ",
      lastName: "ZONGO",
      birthDate: DateTime(1990, 5, 15),
      bloodType: "A+",
      allergies: ["Pénicilline", ""],
      treatments: ["Paracétamol 500mg"],
      medicalHistory: ["Paludisme 2022", "Typhoïde 2023"],
      emergencyContact: "70123456",
    );
    
    _addLog("Patient test: ${testPatient.fullName}");
    final result = PatientValidation.validate(testPatient);
    _addLog(result.getFormattedMessage());
    
    final cleaned = PatientValidation.clean(testPatient);
    _addLog("Après nettoyage: '${cleaned.firstName}' (plus d'espaces)");
    
    setState(() => _isLoading = false);
  }

  Future<void> _testQrScan() async {
    setState(() => _isLoading = true);
    _addLog("\n--- SCAN QR CODE ---");
    _addLog("Scannez le QR code d'une carte...");
    
    try {
      final publicInfo = await _qr.scanQR();
      _addLog("✅ QR scanné avec succès !");
      _addLog("   Nom: ${publicInfo.name}");
      _addLog("   Groupe sanguin: ${publicInfo.bloodType}");
      _addLog("   Contact urgence: ${publicInfo.emergencyPhone}");
    } catch (e) {
      _addLog("❌ Erreur: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testQrGenerate() async {
    setState(() => _isLoading = true);
    _addLog("\n--- GÉNÉRATION QR ---");
    
    final info = PublicInfo(
      name: "Fatimata ZONGO",
      bloodType: "A+",
      emergencyPhone: "+226 70 12 34 56",
    );
    
    final qrWidget = _qr.generateQR(info);
    _addLog("QR généré pour: ${info.name}");
    _addLog("Contenu: ${info.toQrString()}");
    
    // Affiche le QR dans un dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("QR Code Patient"),
        content: SizedBox(
          width: 250,
          height: 250,
          child: qrWidget,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📡 TEST - Personne B (NFC/QR)"),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testNfcRead,
                  icon: const Icon(Icons.nfc),
                  label: const Text("📖 Lire NFC"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testNfcWrite,
                  icon: const Icon(Icons.edit),
                  label: const Text("✏️ Écrire NFC"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testValidation,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("✅ Validation"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testQrScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("📷 Scanner QR"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testQrGenerate,
                  icon: const Icon(Icons.qr_code),
                  label: const Text("🖨️ Générer QR"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            ),
          ),
          
          if (_lastReadPatient != null)
            Card(
              margin: const EdgeInsets.all(12),
              color: Colors.green[50],
              child: ListTile(
                title: Text("Dernier patient lu: ${_lastReadPatient!.fullName}"),
                subtitle: Text("Groupe: ${_lastReadPatient!.bloodType}"),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _lastReadPatient = null),
                ),
              ),
            ),
          
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
                    color: Colors.orangeAccent,
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