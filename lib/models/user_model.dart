class UserModel {
  final String id;
  final String name;
  final String email;
  final double balance;
  final double dailySpent;
  final double dailyCap;
  final String status; // 'Active' or 'Suspended'
  final String cardNumber;
  final String userType; // 'Student' or 'Standard'
  final bool isFrozen;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.balance,
    required this.dailySpent,
    required this.dailyCap,
    required this.status,
    required this.cardNumber,
    this.userType = 'Standard',
    this.isFrozen = false,
  });

  /// Factory constructor to parse a UserModel from a scanned QR payload.
  /// Payload format: LANKAGO:USER:id:name:email:balance:dailySpent:dailyCap:status:cardNumber:userType:isFrozen
  factory UserModel.fromQRString(String qrString) {
    final parts = qrString.split(':');
    if (parts.length < 10) {
      throw const FormatException('Invalid QR Payload format');
    }

    return UserModel(
      id: parts[2],
      name: parts[3],
      email: parts[4],
      balance: double.tryParse(parts[5]) ?? 0.0,
      dailySpent: double.tryParse(parts[6]) ?? 0.0,
      dailyCap: double.tryParse(parts[7]) ?? 100.0,
      status: parts[8],
      cardNumber: parts[9],
      userType: parts.length > 10 ? parts[10] : 'Standard',
      isFrozen: parts.length > 11 ? (parts[11] == 'true') : false,
    );
  }

  /// Create a copy of the model with overridden fields.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? balance,
    double? dailySpent,
    double? dailyCap,
    String? status,
    String? cardNumber,
    String? userType,
    bool? isFrozen,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      balance: balance ?? this.balance,
      dailySpent: dailySpent ?? this.dailySpent,
      dailyCap: dailyCap ?? this.dailyCap,
      status: status ?? this.status,
      cardNumber: cardNumber ?? this.cardNumber,
      userType: userType ?? this.userType,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'balance': balance,
      'dailySpent': dailySpent,
      'dailyCap': dailyCap,
      'status': status,
      'cardNumber': cardNumber,
      'userType': userType,
      'isFrozen': isFrozen,
    };
  }
}
