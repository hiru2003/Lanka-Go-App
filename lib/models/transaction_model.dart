class TransactionModel {
  final String id;
  final String userId;
  final String type; // "reload" | "travel" | "travel_capped"
  final double amount; // negative for travel, positive for reloads
  final String timestamp; // ISO 8601 String
  final String route; // helper for display
  final String busId; // helper for display
  final bool isOffline; // helper for local tracking
  final bool isSynced; // helper for local tracking

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.route = '',
    this.busId = '',
    this.isOffline = false,
    this.isSynced = true,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? type,
    double? amount,
    String? timestamp,
    String? route,
    String? busId,
    bool? isOffline,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      route: route ?? this.route,
      busId: busId ?? this.busId,
      isOffline: isOffline ?? this.isOffline,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'timestamp': timestamp,
      'route': route,
      'bus_id': busId,
      'is_offline': isOffline ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? 'travel',
      amount: (json['amount'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] ?? '',
      route: json['route'] ?? '',
      busId: json['bus_id'] ?? '',
      isOffline: json['is_offline'] == 1 || (json['isOffline'] ?? false),
      isSynced: json['is_synced'] == 1 || (json['isSynced'] ?? true),
    );
  }
}
