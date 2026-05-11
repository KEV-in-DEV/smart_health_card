import 'package:uuid/uuid.dart';
import 'medical_record.dart';

class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String bloodType;
  final List<String> allergies;
  final List<String> treatments;
  final List<String> medicalHistory;
  final String emergencyContact;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MedicalRecord> history;

  Patient({
    String? id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.bloodType,
    required this.allergies,
    required this.treatments,
    required this.medicalHistory,
    required this.emergencyContact,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MedicalRecord>? history,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       history = history ?? [];

  /// Calcule l'âge à partir de la date de naissance
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Nom complet
  String get fullName => '$firstName $lastName';

  /// Convertit en Map pour stockage SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'bloodType': bloodType,
      'allergies': allergies.join(','),
      'treatments': treatments.join(','),
      'medicalHistory': medicalHistory.join(','),
      'emergencyContact': emergencyContact,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convertit en JSON pour export/carte NFC
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'bloodType': bloodType,
      'allergies': allergies,
      'treatments': treatments,
      'medicalHistory': medicalHistory,
      'emergencyContact': emergencyContact,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'history': history.map((e) => e.toJson()).toList(),
    };
  }

  /// Crée un Patient depuis JSON
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: DateTime.parse(json['birthDate']),
      bloodType: json['bloodType'],
      allergies: List<String>.from(json['allergies']),
      treatments: List<String>.from(json['treatments']),
      medicalHistory: List<String>.from(json['medicalHistory']),
      emergencyContact: json['emergencyContact'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      history: json['history'] != null
          ? (json['history'] as List).map((e) => MedicalRecord.fromJson(e)).toList()
          : [],
    );
  }

  /// Crée un Patient depuis Map SQLite
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      birthDate: DateTime.parse(map['birthDate']),
      bloodType: map['bloodType'],
      allergies: map['allergies'].toString().split(',').where((s) => s.isNotEmpty).toList(),
      treatments: map['treatments'].toString().split(',').where((s) => s.isNotEmpty).toList(),
      medicalHistory: map['medicalHistory'].toString().split(',').where((s) => s.isNotEmpty).toList(),
      emergencyContact: map['emergencyContact'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  /// Copie avec modifications
  Patient copyWith({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? bloodType,
    List<String>? allergies,
    List<String>? treatments,
    List<String>? medicalHistory,
    String? emergencyContact,
    List<MedicalRecord>? history,
  }) {
    return Patient(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      treatments: treatments ?? this.treatments,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      history: history ?? this.history,
    );
  }
}