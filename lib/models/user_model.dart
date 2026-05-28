class UserModel {
  final String id;
  final String name;
  final String email;
  final double balance;
  final String phone;
  final String status; // "active" | "frozen"
  final String accountType; // "regular" | "student"
  final String cardNumber;
  final List<String> routesHistory;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.balance,
    required this.phone,
    required this.status,
    required this.accountType,
    required this.cardNumber,
    required this.routesHistory,
  });

  /// Factory constructor to parse a UserModel from a scanned QR payload.
  /// Payload format: LANKAGO:USER:id:name:email:balance:phone:status:accountType:cardNumber:routesHistoryRefs
  factory UserModel.fromQRString(String qrString) {
    final parts = qrString.split(':');
    if (parts.length < 10) {
      throw const FormatException('Invalid QR Payload format');
    }

    final historyParts = parts.length > 10 ? parts[10].split(',') : <String>[];

    return UserModel(
      id: parts[2],
      name: parts[3],
      email: parts[4],
      balance: double.tryParse(parts[5]) ?? 0.0,
      phone: parts[6],
      status: parts[7],
      accountType: parts[8],
      cardNumber: parts[9],
      routesHistory: historyParts.where((s) => s.isNotEmpty).toList(),
    );
  }

  /// Create a copy of the model with overridden fields.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? balance,
    String? phone,
    String? status,
    String? accountType,
    String? cardNumber,
    List<String>? routesHistory,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      accountType: accountType ?? this.accountType,
      cardNumber: cardNumber ?? this.cardNumber,
      routesHistory: routesHistory ?? this.routesHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'balance': balance,
      'phone': phone,
      'status': status,
      'accountType': accountType,
      'cardNumber': cardNumber,
      'routes_history': routesHistory,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'active',
      accountType: json['accountType'] ?? 'regular',
      cardNumber: json['cardNumber'] ?? '',
      routesHistory: List<String>.from(json['routes_history'] ?? []),
    );
  }
}
