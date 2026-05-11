import 'package:uuid/uuid.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final String agentId;
  final String agentName;
  final String hospital;
  final String action; // "read", "create", "update"
  final String details;
  final String signature; // hash

  MedicalRecord({
    String? id,
    required this.patientId,
    required this.timestamp,
    required this.agentId,
    required this.agentName,
    required this.hospital,
    required this.action,
    required this.details,
    required this.signature,
  }) : id = id ?? const Uuid().v4();

  /// Convertit en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'timestamp': timestamp.toIso8601String(),
      'agentId': agentId,
      'agentName': agentName,
      'hospital': hospital,
      'action': action,
      'details': details,
      'signature': signature,
    };
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'timestamp': timestamp.toIso8601String(),
      'agentId': agentId,
      'agentName': agentName,
      'hospital': hospital,
      'action': action,
      'details': details,
      'signature': signature,
    };
  }

  /// Crée depuis JSON
  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'],
      patientId: json['patientId'],
      timestamp: DateTime.parse(json['timestamp']),
      agentId: json['agentId'],
      agentName: json['agentName'],
      hospital: json['hospital'],
      action: json['action'],
      details: json['details'],
      signature: json['signature'],
    );
  }

  /// Crée depuis Map SQLite
  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'],
      patientId: map['patientId'],
      timestamp: DateTime.parse(map['timestamp']),
      agentId: map['agentId'],
      agentName: map['agentName'],
      hospital: map['hospital'],
      action: map['action'],
      details: map['details'],
      signature: map['signature'],
    );
  }
}