class PublicInfo {
  final String name;
  final String bloodType;
  final String emergencyPhone;

  PublicInfo({
    required this.name,
    required this.bloodType,
    required this.emergencyPhone,
  });

  /// Convertit en JSON (pour QR code)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bloodType': bloodType,
      'emergencyPhone': emergencyPhone,
    };
  }

  /// Convertit en string compact pour QR code
  String toQrString() {
    return 'name:$name|blood:$bloodType|phone:$emergencyPhone';
  }

  /// Crée depuis string QR
  factory PublicInfo.fromQrString(String qrData) {
    final parts = qrData.split('|');
    String name = '';
    String bloodType = '';
    String emergencyPhone = '';

    for (final part in parts) {
      if (part.startsWith('name:')) name = part.substring(5);
      if (part.startsWith('blood:')) bloodType = part.substring(6);
      if (part.startsWith('phone:')) emergencyPhone = part.substring(6);
    }

    return PublicInfo(
      name: name,
      bloodType: bloodType,
      emergencyPhone: emergencyPhone,
    );
  }

  /// Crée depuis JSON
  factory PublicInfo.fromJson(Map<String, dynamic> json) {
    return PublicInfo(
      name: json['name'],
      bloodType: json['bloodType'],
      emergencyPhone: json['emergencyPhone'],
    );
  }
}
