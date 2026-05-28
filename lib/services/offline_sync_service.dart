import '../models/user_model.dart';
import '../models/transaction_model.dart';

class OfflineValidationResult {
  final bool isValid;
  final String? rejectionReason;
  final double calculatedFare;
  final TransactionModel? transaction;

  OfflineValidationResult({
    required this.isValid,
    this.rejectionReason,
    this.calculatedFare = 0.0,
    this.transaction,
  });
}

class OfflineSyncService {
  // Simulates local cache/database of offline transactions on the Bus Validator
  final List<TransactionModel> _offlineQueue = [];

  List<TransactionModel> get offlineQueue => List.unmodifiable(_offlineQueue);
  int get unsyncedCount => _offlineQueue.length;

  /// Simulates offline verification inside the bus validator when passenger scans the QR card
  OfflineValidationResult validatePassengerQROffline({
    required UserModel user,
    required double baseFare,
    required String busId,
    required String routeName,
  }) {
    // 1. Verify Card Status (Stolen/Frozen card detection)
    if (user.status == 'frozen') {
      return OfflineValidationResult(
        isValid: false,
        rejectionReason: 'Card Frozen. Scan Rejected.',
      );
    }

    if (user.status.toLowerCase() != 'active') {
      return OfflineValidationResult(
        isValid: false,
        rejectionReason: 'Card Suspended. Scan Rejected.',
      );
    }

    // 2. Calculate Fare (Student Discount: 50% off)
    double finalFare = baseFare;
    if (user.accountType == 'student') {
      finalFare = baseFare * 0.5; // 50% discount
    }

    // 3. Balance verification (Offline check)
    if (user.balance < finalFare) {
      return OfflineValidationResult(
        isValid: false,
        rejectionReason: 'Insufficient Balance. Required LKR ${finalFare.toStringAsFixed(2)}',
      );
    }

    // 4. Create local offline transaction
    final offlineTransaction = TransactionModel(
      id: 'tx_off_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      type: 'travel',
      amount: -finalFare,
      timestamp: DateTime.now().toIso8601String(),
      route: routeName,
      busId: busId,
      isOffline: true,
      isSynced: false,
    );

    // Queue transaction locally on validator memory
    _offlineQueue.add(offlineTransaction);

    return OfflineValidationResult(
      isValid: true,
      calculatedFare: finalFare,
      transaction: offlineTransaction,
    );
  }

  /// Simulates synchronizing local validator transactions with the backend database
  /// returns the list of successfully synced transaction logs.
  Future<List<TransactionModel>> syncOfflineTransactionsToServer() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final List<TransactionModel> syncedList = [];
    
    for (var tx in _offlineQueue) {
      syncedList.add(tx.copyWith(isSynced: true));
    }
    
    // Clear local validator queue after successful sync
    _offlineQueue.clear();
    
    return syncedList;
  }
}
