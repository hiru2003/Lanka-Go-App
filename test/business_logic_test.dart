import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lanka_go/providers/auth_provider.dart';
import 'package:lanka_go/models/transaction_model.dart';
import 'package:lanka_go/services/sqlite_service.dart';

void main() {
  // Initialize ffi for sqflite in tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Lanka Go - Business Logic & Capping Tests', () {
    late AuthProvider authProvider;

    setUp(() async {
      // Close active database from any previous test to avoid lock/file pollution issues
      await SqliteService.closeDatabase();

      authProvider = AuthProvider();
      // Start in online mode by default
      authProvider.setNetworkState(true);
      
      // Reset database cache for each test
      final dbPath = await databaseFactory.getDatabasesPath();
      await databaseFactory.deleteDatabase('$dbPath/lankago_cache.db');
      await authProvider.initDatabaseCache();
    });

    tearDown(() async {
      // Allow any pending background SQLite transactions to write to the database
      // before closing and deleting the database file in setUp
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('1. Student Discount - 50% fare reduction', () async {
      // payload format: LANKAGO:USER:id:name:email:balance:phone:status:accountType:cardNumber
      const studentPayload = 'LANKAGO:USER:stu_123:Hirusha:hirusha@lankago.com:200.0:0771234567:active:student:CARD12345:';
      final success = await authProvider.loginWithQR(studentPayload);
      expect(success, isTrue);
      expect(authProvider.currentUser!.accountType, 'student');
      expect(authProvider.currentUser!.balance, 200.0);

      // Base fare 40 LKR, with 50% discount should calculate to 20 LKR
      final processed = authProvider.processBusTrip(
        baseFare: 40.0,
        routeName: 'Route 138 - Pettah to Maharagama',
        busId: 'LK-NC-4829',
        context: null,
      );

      expect(processed, isTrue);
      // Balance should be: 200.0 - 20.0 = 180.0
      expect(authProvider.currentUser!.balance, 180.0);
      expect(authProvider.travelHistory.first.amount, -20.0);
      expect(authProvider.travelHistory.first.type, 'travel');
    });

    test('2. Regular Passenger - No discount (Full base fare charged)', () async {
      const regularPayload = 'LANKAGO:USER:reg_123:Saman:saman@lankago.com:200.0:0777654321:active:regular:CARD54321:';
      final success = await authProvider.loginWithQR(regularPayload);
      expect(success, isTrue);
      expect(authProvider.currentUser!.accountType, 'regular');

      // Base fare 40 LKR, should calculate to 40 LKR
      final processed = authProvider.processBusTrip(
        baseFare: 40.0,
        routeName: 'Route 138 - Pettah to Maharagama',
        busId: 'LK-NC-4829',
        context: null,
      );

      expect(processed, isTrue);
      // Balance should be: 200.0 - 40.0 = 160.0
      expect(authProvider.currentUser!.balance, 160.0);
      expect(authProvider.travelHistory.first.amount, -40.0);
    });

    test('3. Daily Cap (LKR 100.00 Limit) - Rides capped at LKR 100.00 total spent', () async {
      const capPayload = 'LANKAGO:USER:cap_123:Nimal:nimal@lankago.com:300.0:0777654322:active:regular:CARD99999:';
      final success = await authProvider.loginWithQR(capPayload);
      expect(success, isTrue);

      // AuthProvider initial mock logs 1 travel of -40 today (under regular). 
      // Thus Nimal starts with daily spent of 40 LKR today.
      expect(authProvider.dailySpent, 40.0);

      // First trip today in test: base fare 50.0. Daily spent becomes 40 + 50 = 90.0
      authProvider.clearDuplicateScanCache(); // bypass lockout
      var processed = authProvider.processBusTrip(
        baseFare: 50.0,
        routeName: 'Route 138',
        busId: 'LK-NC-4829',
        context: null,
      );
      expect(processed, isTrue);
      expect(authProvider.dailySpent, 90.0);
      expect(authProvider.currentUser!.balance, 250.0); // 300 - 50 = 250 (initial mock tx history doesn't affect balance)

      // Second trip today in test: base fare 30.0. Only 10.0 remaining before cap.
      // So calculated fare should be capped at 10.0. Type should be travel_capped.
      authProvider.clearDuplicateScanCache(); // bypass lockout
      processed = authProvider.processBusTrip(
        baseFare: 30.0,
        routeName: 'Route 120',
        busId: 'LK-ND-9182',
        context: null,
      );
      expect(processed, isTrue);
      expect(authProvider.dailySpent, 100.0);
      expect(authProvider.currentUser!.balance, 240.0); // 250 - 10 = 240
      expect(authProvider.travelHistory.first.amount, -10.0);
      expect(authProvider.travelHistory.first.type, 'travel_capped');

      // Third trip today in test: base fare 40.0. Already at LKR 100 daily cap.
      // Calculated fare should be 0.0, and type travel_capped.
      authProvider.clearDuplicateScanCache(); // bypass lockout
      processed = authProvider.processBusTrip(
        baseFare: 40.0,
        routeName: 'Route 138',
        busId: 'LK-NC-4829',
        context: null,
      );
      expect(processed, isTrue);
      expect(authProvider.dailySpent, 100.0);
      expect(authProvider.currentUser!.balance, 240.0); // No deduction
      expect(authProvider.travelHistory.first.amount, 0.0);
      expect(authProvider.travelHistory.first.type, 'travel_capped');
    });

    test('4. Duplicate Scan Protection - Lockout within 1 minute', () async {
      const dupPayload = 'LANKAGO:USER:dup_123:Kamal:kamal@lankago.com:200.0:0771122334:active:regular:CARD22222:';
      final success = await authProvider.loginWithQR(dupPayload);
      expect(success, isTrue);

      // Scan 1: Should be processed successfully
      var processed = authProvider.processBusTrip(
        baseFare: 40.0,
        routeName: 'Route 138',
        busId: 'LK-NC-4829',
        context: null,
      );
      expect(processed, isTrue);

      // Scan 2 (Immediate scan): Should be rejected due to duplicate scan lockout
      processed = authProvider.processBusTrip(
        baseFare: 40.0,
        routeName: 'Route 138',
        busId: 'LK-NC-4829',
        context: null,
      );
      expect(processed, isFalse); // Locked out!

      // Reset cache: Should allow scan again
      authProvider.clearDuplicateScanCache();
      processed = authProvider.processBusTrip(
        baseFare: 40.0,
        routeName: 'Route 138',
        busId: 'LK-NC-4829',
        context: null,
      );
      expect(processed, isTrue);
    });

    test('5. Low Balance Notification Threshold - Low balance triggers below LKR 50.00', () async {
      const lowBalPayload = 'LANKAGO:USER:low_123:Sunil:sunil@lankago.com:60.0:0779988776:active:regular:CARD33333:';
      final success = await authProvider.loginWithQR(lowBalPayload);
      expect(success, isTrue);
      expect(authProvider.isLowBalance, isFalse); // balance 60 >= 50

      // Trip costing 20 LKR: balance will drop to 40 LKR
      authProvider.clearDuplicateScanCache();
      final processed = authProvider.processBusTrip(
        baseFare: 20.0,
        routeName: 'Route 138',
        busId: 'LK-NC-4829',
        context: null,
      );
      expect(processed, isTrue);
      expect(authProvider.currentUser!.balance, 40.0);
      expect(authProvider.isLowBalance, isTrue); // balance 40 < 50
    });

    test('6. Offline SQLite Transaction Capping - Up to 500 queued limit', () async {
      const offlinePayload = 'LANKAGO:USER:off_123:OfflineTester:off@lankago.com:10000.0:0771122112:active:regular:CARD44444:';
      final success = await authProvider.loginWithQR(offlinePayload);
      expect(success, isTrue);

      // Set offline mode
      authProvider.setNetworkState(false);

      // Push 500 mock transactions directly to the database
      final db = (await authProvider.sqliteService.database)!;
      
      // Let's add 500 entries to simulate the limit
      await db.transaction((txn) async {
        for (int i = 0; i < 500; i++) {
          await txn.insert(
            'offline_transactions',
            {
              'id': 'tx_off_fill_$i',
              'user_id': 'off_123',
              'type': 'travel',
              'amount': -10.0,
              'timestamp': DateTime.now().toIso8601String(),
              'route': 'Offline Route',
              'bus_id': 'LK-BUS-0000',
              'is_offline': 1,
              'is_synced': 0,
            },
          );
        }
      });

      // Verify the count in SQLite is exactly 500
      final count = await authProvider.sqliteService.getUnsyncedCount();
      expect(count, 500);

      // Now, another scan in offline mode should be blocked because SQLite cache is full
      authProvider.clearDuplicateScanCache();
      authProvider.processBusTrip(
        baseFare: 10.0,
        routeName: 'Offline Route',
        busId: 'LK-BUS-0000',
        context: null,
      );

      // Wait, processBusTrip uses an async queue call. Since the queue call will fail in SQLite, 
      // the synchronous return of processBusTrip is true (because it starts the queueing chain), 
      // but let's verify if the database inserts are blocked.
      // Wait, let's examine the sqliteService.queueOfflineTransaction method.
      // If we call queueOfflineTransaction directly, does it throw? Yes, we can expect it to throw.
      expect(
        () => authProvider.sqliteService.queueOfflineTransaction(
          TransactionModel(
            id: 'tx_off_blocked',
            userId: 'off_123',
            type: 'travel',
            amount: -10.0,
            timestamp: DateTime.now().toIso8601String(),
            route: 'Offline Route',
            busId: 'LK-BUS-0000',
            isOffline: true,
            isSynced: false,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
