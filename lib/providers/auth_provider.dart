import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../services/sqlite_service.dart';
import '../services/payhere_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticating = false;
  bool _isReloading = false;
  String? _authError;
  
  // Backend connection url
  final String backendUrl = 'http://localhost:5001'; // Target local Flask server

  // Core Systems
  bool _isOnline = true;
  final List<TransactionModel> _travelHistory = [];
  final SqliteService _sqliteService = SqliteService();
  final PayHereService _payHereService = PayHereService();
  
  // Duplicate scan tracking
  final Map<String, DateTime> _lastScanTimestamps = {};

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAuthenticating => _isAuthenticating;
  bool get isReloading => _isReloading;
  String? get authError => _authError;
  
  bool get isOnline => _isOnline;
  List<TransactionModel> get travelHistory => List.unmodifiable(_travelHistory);
  SqliteService get sqliteService => _sqliteService;
  
  // Low balance alerts trigger at LKR 50.00
  bool get isLowBalance => _currentUser != null && _currentUser!.balance < 50.0;

  double get dailyCap => 100.0;
  
  double get dailySpent {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    double spent = 0.0;
    for (var tx in _travelHistory) {
      if (tx.type.startsWith('travel') && tx.timestamp.startsWith(todayStr)) {
        spent += tx.amount.abs();
      }
    }
    return spent;
  }

  /// Initializes local SQLite database
  Future<void> initDatabaseCache() async {
    await _sqliteService.database;
  }

  Future<bool> loginWithQR(String qrPayload) async {
    _isAuthenticating = true;
    _authError = null;
    notifyListeners();

    try {
      // Initialize local cache helper
      await initDatabaseCache();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (qrPayload.startsWith('LANKAGO:USER:')) {
        final user = UserModel.fromQRString(qrPayload);
        _currentUser = user;
        
        // Save initial balance to SQLite cache
        await _sqliteService.updateCachedUser(user.id, user.balance);

        // Fetch user from Flask API if online
        if (_isOnline) {
          try {
            final response = await http.get(Uri.parse('$backendUrl/api/users/${user.id}'))
                .timeout(const Duration(seconds: 4));
            if (response.statusCode == 200) {
              final apiUser = UserModel.fromJson(jsonDecode(response.body));
              _currentUser = apiUser;
              await _sqliteService.updateCachedUser(apiUser.id, apiUser.balance);
            }
          } catch (e) {
            print('Could not fetch latest user profile from backend: $e. Using QR payload.');
          }
        }
        
        // Add initial mock travel history
        _travelHistory.clear();
        _travelHistory.addAll([
          TransactionModel(
            id: 'tx_init_1',
            userId: user.id,
            type: 'travel',
            amount: user.accountType == 'student' ? -20.0 : -40.0,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
            route: 'Route 138 - Pettah to Maharagama',
            busId: 'LK-NC-4829',
            isOffline: false,
            isSynced: true,
          ),
          TransactionModel(
            id: 'tx_init_2',
            userId: user.id,
            type: 'travel',
            amount: user.accountType == 'student' ? -27.5 : -55.0,
            timestamp: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            route: 'Route 120 - Colombo to Horana',
            busId: 'LK-ND-9182',
            isOffline: false,
            isSynced: true,
          ),
        ]);
        
        _isAuthenticating = false;
        notifyListeners();
        
        // Check initial balance alert
        if (isLowBalance) {
          _triggerLowBalanceAlerts();
        }
        
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

  /// Toggles between Student and Regular passenger classifications
  void toggleUserType() {
    if (_currentUser != null) {
      final nextType = _currentUser!.accountType == 'student' ? 'regular' : 'student';
      _currentUser = _currentUser!.copyWith(accountType: nextType);
      notifyListeners();
    }
  }

  /// Freezes or unfreezes the travel card
  void setFreezeState(bool frozen) {
    if (_currentUser != null) {
      final nextStatus = frozen ? 'frozen' : 'active';
      _currentUser = _currentUser!.copyWith(status: nextStatus);
      notifyListeners();
    }
  }

  /// Simulate reloading balance using PayHere payment sandbox api callbacks
  Future<bool> reloadBalanceWithPayHere(double amount, BuildContext? context) async {
    if (_currentUser == null) return false;
    
    _isReloading = true;
    notifyListeners();

    // 1. Calculate MD5 checksum signature
    final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final sig = _payHereService.generateCheckoutSignature(orderId: orderId, amount: amount);
    print('PayHere Sandbox Gateway signature generated: MD5 checksum = $sig');

    // 2. Simulate Sandbox credit card authorization delay
    await Future.delayed(const Duration(seconds: 1));

    // 3. Trigger payment webhook callback to Flask backend API (updates remote server)
    final success = await _payHereService.triggerWebhookSuccess(
      orderId: orderId,
      amount: amount,
      userId: _currentUser!.id,
      backendUrl: backendUrl,
    );

    if (success) {
      // 4. Fetch new balance from backend or local fallback
      _currentUser = _currentUser!.copyWith(
        balance: _currentUser!.balance + amount,
      );
      await _sqliteService.updateCachedUser(_currentUser!.id, _currentUser!.balance);
      
      final reloadTx = TransactionModel(
        id: 'tx_pay_$orderId',
        userId: _currentUser!.id,
        type: 'reload',
        amount: amount,
        timestamp: DateTime.now().toIso8601String(),
        route: 'Digital Wallet Deposit',
        busId: 'Gateway: PayHere',
        isOffline: false,
        isSynced: true,
      );

      _travelHistory.insert(0, reloadTx);
      _isReloading = false;
      notifyListeners();
      
      return true;
    }

    _isReloading = false;
    notifyListeners();
    return false;
  }

  /// Processes bus trip check-in (implements Student discounts, LKR 100 capping, 1-min duplicate block, SQLite cache checks, and low-balance warnings)
  bool processBusTrip({
    required double baseFare,
    required String routeName,
    required String busId,
    required BuildContext? context,
  }) {
    if (_currentUser == null) return false;

    // Check if card status is frozen
    if (_currentUser!.status == 'frozen') {
      return false;
    }

    // 1. Duplicate Scan Protection (1-minute timeout block on same card ID)
    final now = DateTime.now();
    final lastScan = _lastScanTimestamps[_currentUser!.id];
    if (lastScan != null && now.difference(lastScan) < const Duration(minutes: 1)) {
      print('Warning: Duplicate card scan detected on validator. Scanning blocked for 1 minute.');
      return false;
    }
    _lastScanTimestamps[_currentUser!.id] = now;

    // 2. Student Discount calculations (50% slash)
    double calculatedFare = baseFare;
    if (_currentUser!.accountType == 'student') {
      calculatedFare = baseFare * 0.5;
    }

    // 3. LKR 100 Daily Cap Capping Rule
    // Check total expenditures of today
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    double todaySpent = 0.0;
    for (var tx in _travelHistory) {
      if (tx.type.startsWith('travel') && tx.timestamp.startsWith(todayStr)) {
        todaySpent += tx.amount.abs();
      }
    }

    double actualCost = calculatedFare;
    String transactionType = "travel";

    if (todaySpent >= 100.0) {
      actualCost = 0.0; // Free travel
      transactionType = "travel_capped";
    } else if (todaySpent + calculatedFare > 100.0) {
      actualCost = 100.0 - todaySpent; // Pay up to LKR 100 cap
      transactionType = "travel_capped";
    }

    if (_isOnline) {
      // ONLINE FARE DEDUCTION FLOW
      if (_currentUser!.balance < actualCost) return false;

      // Update state
      _currentUser = _currentUser!.copyWith(
        balance: _currentUser!.balance - actualCost,
      );
      _sqliteService.updateCachedUser(_currentUser!.id, _currentUser!.balance);

      final onlineTx = TransactionModel(
        id: 'tx_on_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.id,
        type: transactionType,
        amount: -actualCost,
        timestamp: DateTime.now().toIso8601String(),
        route: routeName,
        busId: busId,
        isOffline: false,
        isSynced: true,
      );

      _travelHistory.insert(0, onlineTx);
      notifyListeners();

      // Check low balance notifications
      if (isLowBalance) {
        _triggerLowBalanceAlerts(context: context);
      }
      return true;
    } else {
      // OFFLINE FARE DEDUCTION FLOW (SQLite Caching Layer)
      
      // Verify cached SQLite balance
      final double cachedBalance = _currentUser!.balance;
      if (cachedBalance < actualCost) {
        print('Offline check-in rejected: cached balance is insufficient.');
        return false;
      }

      final offlineTx = TransactionModel(
        id: 'tx_off_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.id,
        type: transactionType,
        amount: -actualCost,
        timestamp: DateTime.now().toIso8601String(),
        route: routeName,
        busId: busId,
        isOffline: true,
        isSynced: false,
      );

      try {
        // Queue to local SQLite cache, which throws if 500 cap is reached!
        _sqliteService.queueOfflineTransaction(offlineTx).then((_) {
          // Update model balance representing local card values update
          _currentUser = _currentUser!.copyWith(
            balance: _currentUser!.balance - actualCost,
          );
          
          _travelHistory.insert(0, offlineTx);
          notifyListeners();
          
          if (isLowBalance) {
            _triggerLowBalanceAlerts(context: context);
          }
        }).catchError((e) {
          print('Offline transaction blocked: ${e.toString()}');
        });
        return true;
      } catch (e) {
        print('Offline transaction error: $e');
        return false;
      }
    }
  }

  /// Triggers push alerts and prints outbox telco SMS warnings
  void _triggerLowBalanceAlerts({BuildContext? context}) {
    if (_currentUser == null) return;
    
    // 1. Firebase Messaging Push Alert simulation
    NotificationService.triggerFirebasePushNotification(
      title: 'Lanka Go Wallet Warning',
      body: 'Your balance is LKR ${_currentUser!.balance.toStringAsFixed(2)}. Reload below LKR 50 safety threshold.',
      context: context,
    );

    // 2. Fallback SMS gateway printout
    NotificationService.triggerFallbackSMSAlert(
      phoneNumber: _currentUser!.phone,
      currentBalance: _currentUser!.balance,
    );
  }

  /// Synchronizes SQLite offline transaction buffer with the Flask sync API
  Future<void> syncOfflineTransactions() async {
    if (!_isOnline || _currentUser == null) return; // Must be online to sync
    
    final unsynced = await _sqliteService.getUnsyncedTransactions();
    if (unsynced.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/transactions/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _currentUser!.id,
          'transactions': unsynced.map((tx) => {
            'id': tx.id,
            'fare': tx.amount.abs(),
            'timestamp': tx.timestamp,
            'route': tx.route,
            'busId': tx.busId,
          }).toList(),
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final List<dynamic> syncedTxs = result['synced_transactions'] ?? [];
        
        final List<String> successfullySyncedIds = [];
        
        // Update local memory history logs
        for (var syncedItem in syncedTxs) {
          if (syncedItem['status'] == 'synced') {
            final txId = syncedItem['id'];
            successfullySyncedIds.add(txId);
            
            // Mark synced in local history list
            for (int i = 0; i < _travelHistory.length; i++) {
              if (_travelHistory[i].id == txId) {
                _travelHistory[i] = _travelHistory[i].copyWith(
                  isOffline: false,
                  isSynced: true,
                  type: syncedItem['type'],
                  amount: (syncedItem['amount'] as num).toDouble(),
                );
              }
            }
          }
        }
        
        // Update SQLite sync flags
        await _sqliteService.markAsSynced(successfullySyncedIds);
        await _sqliteService.clearSyncedTransactions();

        // Update server balance
        _currentUser = _currentUser!.copyWith(
          balance: (result['new_balance'] as num).toDouble(),
        );
        await _sqliteService.updateCachedUser(_currentUser!.id, _currentUser!.balance);
        
        notifyListeners();
      }
    } catch (e) {
      print('Sync API upload error: $e. Unsynced transactions retained in cache.');
    }
  }

  /// Perform logout
  void logout() {
    _currentUser = null;
    _authError = null;
    _travelHistory.clear();
    _lastScanTimestamps.clear();
    notifyListeners();
  }

  /// Clears duplicate scan timestamps (primarily for testing purposes)
  void clearDuplicateScanCache() {
    _lastScanTimestamps.clear();
  }
}
