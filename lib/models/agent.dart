class Agent {
  final String id;
  final String name;
  final String hospital;
  final String hashedPassword;
  final String role; // "doctor", "nurse", "admin"

  Agent({
    required this.id,
    required this.name,
    required this.hospital,
    required this.hashedPassword,
    this.role = "doctor",
  });

  /// Convertit en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hospital': hospital,
      'hashedPassword': hashedPassword,
      'role': role,
    };
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'hospital': hospital, 'role': role};
  }

  /// Crée depuis Map SQLite
  factory Agent.fromMap(Map<String, dynamic> map) {
    return Agent(
      id: map['id'],
      name: map['name'],
      hospital: map['hospital'],
      hashedPassword: map['hashedPassword'],
      role: map['role'] ?? "doctor",
    );
  }

  /// Crée depuis JSON (sans mot de passe)
  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'],
      name: json['name'],
      hospital: json['hospital'],
      hashedPassword: '', // Ne pas exposer le mot de passe dans JSON
      role: json['role'] ?? "doctor",
    );
  }
}
