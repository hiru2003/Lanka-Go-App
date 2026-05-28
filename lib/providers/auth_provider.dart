import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../services/offline_sync_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticating = false;
  bool _isReloading = false;
  String? _authError;
  
  // Simulation States
  bool _isOnline = true;
  final List<TransactionModel> _travelHistory = [];
  final OfflineSyncService _offlineService = OfflineSyncService();

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAuthenticating => _isAuthenticating;
  bool get isReloading => _isReloading;
  String? get authError => _authError;
  
  bool get isOnline => _isOnline;
  List<TransactionModel> get travelHistory => List.unmodifiable(_travelHistory);
  OfflineSyncService get offlineService => _offlineService;

  /// Low balance check (alert at less than LKR 100.00)
  bool get isLowBalance => _currentUser != null && _currentUser!.balance < 100.0;

  /// Validates the QR code scanned. If it contains "LANKAGO:USER", it decodes and logs in.
  Future<bool> loginWithQR(String qrPayload) async {
    _isAuthenticating = true;
    _authError = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      if (qrPayload.startsWith('LANKAGO:USER:')) {
        final user = UserModel.fromQRString(qrPayload);
        _currentUser = user;
        
        // Add initial mock travel history
        _travelHistory.clear();
        _travelHistory.addAll([
          TransactionModel(
            id: 'tx_init_1',
            route: 'Route 138 - Pettah to Maharagama',
            fare: user.userType == 'Student' ? 20.0 : 40.0,
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
            busId: 'LK-NC-4829',
            isOffline: false,
            isSynced: true,
          ),
          TransactionModel(
            id: 'tx_init_2',
            route: 'Route 120 - Colombo to Horana',
            fare: user.userType == 'Student' ? 27.5 : 55.0,
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            busId: 'LK-ND-9182',
            isOffline: false,
            isSynced: true,
          ),
        ]);
        
        _isAuthenticating = false;
        notifyListeners();
        return true;
      } else {
        _authError = 'Invalid Lanka Go payload. QR code format is unrecognized.';
        _isAuthenticating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authError = 'Error decoding QR card: ${e.toString()}';
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  /// Sets the simulated network connection state (Online / Offline)
  void setNetworkState(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  /// Toggles between Student and Standard passenger classifications for quick testing
  void toggleUserType() {
    if (_currentUser != null) {
      final nextType = _currentUser!.userType == 'Student' ? 'Standard' : 'Student';
      _currentUser = _currentUser!.copyWith(userType: nextType);
      notifyListeners();
    }
  }

  /// Freezes or unfreezes the travel card
  void setFreezeState(bool frozen) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isFrozen: frozen);
      notifyListeners();
    }
  }

  /// Simulate reloading balance using an online payment gateway
  Future<bool> reloadBalanceWithGateway(double amount) async {
    if (_currentUser == null) return false;
    
    _isReloading = true;
    notifyListeners();

    // 1. Enter Reload Amount & confirm payment -> gateway processing delay
    await Future.delayed(const Duration(seconds: 1));

    // 2. Gateway success -> Update account balance
    _currentUser = _currentUser!.copyWith(
      balance: _currentUser!.balance + amount,
    );
    _isReloading = false;
    notifyListeners();
    return true;
  }

  /// Processes check-in and deducts fare (handles student discounts, caps, and offline validation)
  bool processBusTrip({
    required double baseFare,
    required String routeName,
    required String busId,
  }) {
    if (_currentUser == null) return false;

    // Check if card is frozen
    if (_currentUser!.isFrozen) {
      return false;
    }

    if (_isOnline) {
      // ONLINE FARE DEDUCTION FLOW
      
      // Calculate fare with Student 50% discount
      double calculatedFare = baseFare;
      if (_currentUser!.userType == 'Student') {
        calculatedFare = baseFare * 0.5;
      }

      // Check balance
      if (_currentUser!.balance < calculatedFare) return false;

      // Handle Sri Lankan Daily Capping limits
      double newDailySpent = _currentUser!.dailySpent;
      double actualCost = calculatedFare;

      if (newDailySpent >= _currentUser!.dailyCap) {
        actualCost = 0.0; // Free travel
      } else if (newDailySpent + calculatedFare > _currentUser!.dailyCap) {
        actualCost = _currentUser!.dailyCap - newDailySpent; // Up to the cap
        newDailySpent = _currentUser!.dailyCap;
      } else {
        newDailySpent += calculatedFare;
      }

      // Deduct balance and record transaction
      _currentUser = _currentUser!.copyWith(
        balance: _currentUser!.balance - actualCost,
        dailySpent: newDailySpent,
      );

      final onlineTx = TransactionModel(
        id: 'tx_on_${DateTime.now().millisecondsSinceEpoch}',
        route: routeName,
        fare: actualCost,
        timestamp: DateTime.now(),
        busId: busId,
        isOffline: false,
        isSynced: true,
      );

      _travelHistory.insert(0, onlineTx);
      notifyListeners();
      return true;
    } else {
      // OFFLINE FARE DEDUCTION FLOW
      final result = _offlineService.validatePassengerQROffline(
        user: _currentUser!,
        baseFare: baseFare,
        busId: busId,
        routeName: routeName,
      );

      if (result.isValid && result.transaction != null) {
        // In offline smart card systems, the new balance is immediately written to the card chip.
        // We simulate that by local balance deduction.
        _currentUser = _currentUser!.copyWith(
          balance: _currentUser!.balance - result.calculatedFare,
          dailySpent: _currentUser!.dailySpent + result.calculatedFare,
        );

        // Record the transaction locally in the travel log
        _travelHistory.insert(0, result.transaction!);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    }
  }

  /// Simulates syncing offline transactions back to the backend when online connectivity returns
  Future<void> syncOfflineTransactions() async {
    if (!_isOnline) return; // Must be online to sync
    
    final syncedTxs = await _offlineService.syncOfflineTransactionsToServer();
    
    if (syncedTxs.isNotEmpty) {
      // Update our history log: convert matching unsynced offline records to synced online records
      for (int i = 0; i < _travelHistory.length; i++) {
        final localTx = _travelHistory[i];
        if (localTx.isOffline && !localTx.isSynced) {
          // Find matching item by timestamp/ID details
          final matched = syncedTxs.firstWhere(
            (s) => s.id == localTx.id,
            orElse: () => localTx,
          );
          if (matched.isSynced) {
            _travelHistory[i] = localTx.copyWith(
              isOffline: false,
              isSynced: true,
            );
          }
        }
      }
      notifyListeners();
    }
  }

  /// Clear any error message
  void clearError() {
    _authError = null;
    notifyListeners();
  }

  /// Perform logout
  void logout() {
    _currentUser = null;
    _authError = null;
    _travelHistory.clear();
    notifyListeners();
  }
}
