class TransactionModel {
  final String id;
  final String route;
  final double fare;
  final DateTime timestamp;
  final String busId;
  final bool isOffline;
  final bool isSynced;

  TransactionModel({
    required this.id,
    required this.route,
    required this.fare,
    required this.timestamp,
    required this.busId,
    this.isOffline = false,
    this.isSynced = true,
  });

  TransactionModel copyWith({
    String? id,
    String? route,
    double? fare,
    DateTime? timestamp,
    String? busId,
    bool? isOffline,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      route: route ?? this.route,
      fare: fare ?? this.fare,
      timestamp: timestamp ?? this.timestamp,
      busId: busId ?? this.busId,
      isOffline: isOffline ?? this.isOffline,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route': route,
      'fare': fare,
      'timestamp': timestamp.toIso8601String(),
      'busId': busId,
      'isOffline': isOffline,
      'isSynced': isSynced,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      route: json['route'],
      fare: json['fare'],
      timestamp: DateTime.parse(json['timestamp']),
      busId: json['busId'],
      isOffline: json['isOffline'] ?? false,
      isSynced: json['isSynced'] ?? true,
    );
  }
}
