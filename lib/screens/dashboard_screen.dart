import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/glassmorphic_card.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Displays the recent travel history popup list
  void _showHistoryModal(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final history = authProvider.travelHistory;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  langProvider.translate('travelHistory'),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (history.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'No travel records found.',
                        style: GoogleFonts.inter(color: Colors.white30),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.white.withAlpha(20)),
                      itemBuilder: (context, index) {
                        final trip = history[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(10),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      trip.type == 'reload' ? Icons.add_card : Icons.directions_bus,
                                      color: trip.type == 'reload' ? const Color(0xFF00E676) : const Color(0xFF00F2FE),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trip.route,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${trip.busId} • ',
                                            style: GoogleFonts.inter(
                                              color: Colors.white38,
                                              fontSize: 10,
                                            ),
                                          ),
                                          _buildSyncBadge(trip),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                '${trip.amount > 0 ? "+" : ""} ${langProvider.translate('lkr')} ${trip.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.shareTechMono(
                                  color: trip.amount > 0 ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the small inline badge tag indicating transaction validation state
  Widget _buildSyncBadge(TransactionModel trip) {
    if (trip.isOffline && !trip.isSynced) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(30),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange, width: 0.5),
        ),
        child: const Text(
          'OFFLINE',
          style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      );
    }
    
    if (trip.isOffline && trip.isSynced) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.withAlpha(30),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.teal, width: 0.5),
        ),
        child: const Text(
          'SYNCED',
          style: TextStyle(color: Colors.teal, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF00F2FE).withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF00F2FE), width: 0.5),
      ),
      child: const Text(
        'ONLINE',
        style: TextStyle(color: Color(0xFF00F2FE), fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final user = authProvider.currentUser;
    final size = MediaQuery.of(context).size;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double capProgress = (authProvider.dailySpent / authProvider.dailyCap).clamp(0.0, 1.0);
    final isCapReached = authProvider.dailySpent >= authProvider.dailyCap;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ayubowan, ',
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                              // Network visual label
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: authProvider.isOnline ? const Color(0xFF00E676) : Colors.red,
                                  boxShadow: [
                                    BoxShadow(
                                      color: authProvider.isOnline ? const Color(0xFF00E676).withAlpha(120) : Colors.red.withAlpha(120),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                authProvider.isOnline ? 'Online' : 'Offline Mode',
                                style: GoogleFonts.inter(
                                  color: authProvider.isOnline ? Colors.white30 : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            user.name,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00F2FE),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF1E293B),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0] : 'U',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF00F2FE),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),

                  // 1. LOW BALANCE NOTIFICATION SYSTEM (< LKR 50 safety threshold)
                  if (authProvider.isLowBalance)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withAlpha(100), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withAlpha(10),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Low Balance Warning!',
                                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your balance is below LKR 50.00 safety threshold.',
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.orange.withAlpha(40),
                              foregroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => Navigator.pushNamed(context, '/reload'),
                            child: const Text('RELOAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  // Visual Smart Card Display
                  Stack(
                    children: [
                      GlassmorphicCard(
                        borderRadius: 24,
                        gradientColors: [
                          const Color(0xFF1E1B4B).withAlpha(180),
                          const Color(0xFF0F172A).withAlpha(120),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.waves, color: Color(0xFF00F2FE), size: 28),
                                      const SizedBox(width: 8),
                                      Text(
                                        'LANKA GO PASS',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // User Type student tag
                                  if (user.accountType == 'student')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB300).withAlpha(40),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFFFB300), width: 1),
                                      ),
                                      child: const Text(
                                        'STUDENT',
                                        style: TextStyle(
                                          color: Color(0xFFFFB300),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 32),

                              Text(
                                langProvider.translate('balance'),
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${langProvider.translate('lkr')} ${user.balance.toStringAsFixed(2)}',
                                style: GoogleFonts.shareTechMono(
                                  color: const Color(0xFFFFFFFF),
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 28),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CARD HOLDER',
                                        style: GoogleFonts.inter(
                                          color: Colors.white24,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.name.toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'CARD ID',
                                        style: GoogleFonts.inter(
                                          color: Colors.white24,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.cardNumber,
                                        style: GoogleFonts.shareTechMono(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // FREEZE CARD BLOCKED OVERLAY SHIELD
                      if (user.status == 'frozen')
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              color: Colors.red.withAlpha(200),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.ac_unit, color: Colors.white, size: 48),
                                  const SizedBox(height: 8),
                                  Text(
                                    'CARD FROZEN',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Transactions blocked. Unfreeze card to use.',
                                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Daily Cap Progress Widget (Capped at LKR 100.00 spent)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.av_timer, color: Color(0xFFFFB300), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  langProvider.translate('dailyCap'),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${langProvider.translate('lkr')} ${authProvider.dailySpent.toStringAsFixed(0)} / ${authProvider.dailyCap.toStringAsFixed(0)}',
                              style: GoogleFonts.shareTechMono(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(height: 8, color: Colors.white.withAlpha(20)),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: 8,
                                width: (size.width - 88) * capProgress,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isCapReached
                              ? 'Daily capping reached! subsequent travel fares capped to LKR 0.00.'
                              : '${langProvider.translate('lkr')} ${(authProvider.dailyCap - authProvider.dailySpent).toStringAsFixed(2)} remaining before daily cap discount triggers.',
                          style: GoogleFonts.inter(
                            color: isCapReached ? const Color(0xFF00E676) : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // INTERACTIVE DEVELOPER TESTING PANEL (SQLite / Double scans simulator)
                  _buildDevTestingPanel(context, authProvider, user),

                  const SizedBox(height: 28),

                  // Quick Actions row
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
                    child: Text(
                      'QUICK ACTIONS',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          context: context,
                          label: langProvider.translate('reloadBalance'),
                          icon: Icons.add_card,
                          color: const Color(0xFF00F2FE),
                          onTap: () => Navigator.pushNamed(context, '/reload'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionTile(
                          context: context,
                          label: 'Bus ETAs & Routes',
                          icon: Icons.navigation_outlined,
                          color: const Color(0xFFFFB300),
                          onTap: () => Navigator.pushNamed(context, '/routes'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          context: context,
                          label: langProvider.translate('travelHistory'),
                          icon: Icons.history,
                          color: Colors.white,
                          onTap: () => _showHistoryModal(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionTile(
                          context: context,
                          label: langProvider.translate('profile'),
                          icon: Icons.person_outline,
                          color: Colors.white,
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the visual testing panel widget allowing quick switches of states
  Widget _buildDevTestingPanel(BuildContext context, AuthProvider authProvider, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00F2FE).withAlpha(80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LANKA GO SIMULATOR',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF00F2FE),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              // SQLite Cache Counter out of 500 limit
              FutureBuilder<int>(
                future: authProvider.sqliteService.getUnsyncedCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: count >= 500 
                          ? Colors.red.withAlpha(45) 
                          : (count > 0 ? Colors.orange.withAlpha(45) : Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SQLite: $count / 500',
                      style: TextStyle(
                        color: count >= 500 
                            ? Colors.red 
                            : (count > 0 ? Colors.orange : Colors.white54),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive toggles row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Connection toggle
              _buildDevToggle(
                label: 'Network',
                value: authProvider.isOnline ? 'Online' : 'Offline',
                activeColor: authProvider.isOnline ? const Color(0xFF00E676) : Colors.red,
                onTap: () => authProvider.setNetworkState(!authProvider.isOnline),
              ),
              
              // Student type toggle
              _buildDevToggle(
                label: 'Account Type',
                value: user.accountType,
                activeColor: user.accountType == 'student' ? const Color(0xFFFFB300) : Colors.white,
                onTap: () => authProvider.toggleUserType(),
              ),

              // Freeze toggle
              _buildDevToggle(
                label: 'Card Lock',
                value: user.status == 'frozen' ? 'Locked' : 'Active',
                activeColor: user.status == 'frozen' ? Colors.red : const Color(0xFF00E676),
                onTap: () => authProvider.setFreezeState(user.status != 'frozen'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action simulation triggers
          Row(
            children: [
              // Simulate Trip button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF020617),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withAlpha(20)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    // Try processing trip with standard cost LKR 50.00
                    final success = authProvider.processBusTrip(
                      baseFare: 50.0,
                      routeName: '138 Pettah-Borella',
                      busId: 'LK-NC-4829',
                      context: context,
                    );
                    
                    if (success) {
                      final double charge = user.accountType == 'student' ? 25.0 : 50.0;
                      final modeStr = authProvider.isOnline ? 'Online Server' : 'Local SQLite';
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Success! Bus Check-in complete. Charged LKR ${charge.toStringAsFixed(2)} via $modeStr.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: const Color(0xFF00E676),
                        ),
                      );
                    } else {
                      String failReason = 'Transaction rejected: insufficient balance.';
                      if (user.status == 'frozen') {
                        failReason = 'Transaction rejected: card is frozen!';
                      } else {
                        // Check if duplicate timeout occurred
                        final now = DateTime.now();
                        final lastScan = authProvider.travelHistory.isEmpty 
                            ? null 
                            : DateTime.parse(authProvider.travelHistory.first.timestamp);
                        if (lastScan != null && now.difference(lastScan) < const Duration(minutes: 1)) {
                          failReason = 'Duplicate scan blocked (1-min timeout protection)';
                        }
                      }
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(failReason, style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.directions_bus_filled_outlined, size: 16),
                  label: const Text('Deduct trip (LKR 50)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              
              // Force synchronization button
              FutureBuilder<int>(
                future: authProvider.sqliteService.getUnsyncedCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676).withAlpha(30),
                        foregroundColor: const Color(0xFF00E676),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF00E676)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: !authProvider.isOnline 
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cannot sync: connection is offline.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          : () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(color: Color(0xFF00E676)),
                                ),
                              );
                              
                              await authProvider.syncOfflineTransactions();
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sync Complete! Offline queue uploaded to server.'),
                                    backgroundColor: Color(0xFF00E676),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.cloud_sync_outlined, size: 16),
                      label: const Text('Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to build small clickable state modifiers inside Dev simulator card
  Widget _buildDevToggle({
    required String label,
    required String value,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: activeColor.withAlpha(60)),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(color: activeColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
