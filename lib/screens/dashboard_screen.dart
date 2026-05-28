import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/glassmorphic_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Displays the reload bottom sheet modal
  void _showReloadModal(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

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
        final List<double> reloadAmounts = [100, 200, 500, 1000];

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
                  langProvider.translate('reloadBalance'),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select an amount to simulate reloading your Lanka Go card.',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Segmented Reload Grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: reloadAmounts.map((amount) {
                    return InkWell(
                      onTap: () {
                        authProvider.reloadBalance(amount);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Successfully reloaded ${langProvider.translate('lkr')} ${amount.toStringAsFixed(2)}!',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: const Color(0xFF00E676),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(20)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${langProvider.translate('lkr')} ${amount.toStringAsFixed(0)}',
                          style: GoogleFonts.shareTechMono(
                            color: const Color(0xFF00F2FE),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Displays the recent travel history popup list
  void _showHistoryModal(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

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
        final List<Map<String, dynamic>> trips = [
          {
            'route': 'Route 138 - Pettah to Maharagama',
            'time': 'Today, 08:32 AM',
            'fare': 40.0,
            'bus': 'LK-NC-4829',
          },
          {
            'route': 'Route 120 - Colombo to Horana',
            'time': 'Yesterday, 05:14 PM',
            'fare': 55.0,
            'bus': 'LK-ND-9182',
          },
          {
            'route': 'Route 177 - Kollupitiya to Kaduwela',
            'time': '26 May, 07:10 AM',
            'fare': 35.0,
            'bus': 'LK-NB-1092',
          },
        ];

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
                
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trips.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.white.withAlpha(20)),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
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
                                child: const Icon(Icons.directions_bus, color: Color(0xFF00F2FE), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip['route'],
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${trip['time']} • ${trip['bus']}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '- ${langProvider.translate('lkr')} ${trip['fare'].toStringAsFixed(2)}',
                            style: GoogleFonts.shareTechMono(
                              color: const Color(0xFFFFB300),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    // Get current logged-in user or provide fallback mock
    final user = authProvider.currentUser;
    final size = MediaQuery.of(context).size;

    if (user == null) {
      // Fallback redirection to login just in case
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Daily Cap Math
    final double capProgress = (user.dailySpent / user.dailyCap).clamp(0.0, 1.0);
    final isCapReached = user.dailySpent >= user.dailyCap;

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
                  // Dashboard Header / Top profile bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ayubowan,',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
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
                      
                      // Small interactive avatar navigating to Profile
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00F2FE),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F2FE).withAlpha(60),
                                blurRadius: 10,
                              ),
                            ],
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
                  
                  const SizedBox(height: 32),

                  // Smart Card Visual Component
                  InkWell(
                    onTap: () {
                      // Secret tap feature: simulate riding a bus costing LKR 20.00
                      authProvider.deductTrip(20.0);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isCapReached 
                            ? 'Daily Cap reached! This trip is free.' 
                            : 'Simulated bus trip check-in. Deducted LKR 20.00'),
                          backgroundColor: isCapReached ? const Color(0xFF00F2FE) : const Color(0xFFFFB300),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: GlassmorphicCard(
                      borderRadius: 24,
                      gradientColors: [
                        const Color(0xFF1E1B4B).withAlpha(180), // Deep blue-violet
                        const Color(0xFF0F172A).withAlpha(120), // Dark slate
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: user.status.toLowerCase() == 'active'
                                        ? const Color(0xFF00E676).withAlpha(30)
                                        : Colors.redAccent.withAlpha(30),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: user.status.toLowerCase() == 'active'
                                          ? const Color(0xFF00E676)
                                          : Colors.redAccent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: user.status.toLowerCase() == 'active'
                                              ? const Color(0xFF00E676)
                                              : Colors.redAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        langProvider.translate(user.status.toLowerCase()),
                                        style: TextStyle(
                                          color: user.status.toLowerCase() == 'active'
                                              ? const Color(0xFF00E676)
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 36),

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
                  ),

                  const SizedBox(height: 28),

                  // Daily Cap Progress Component
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
                              '${langProvider.translate('lkr')} ${user.dailySpent.toStringAsFixed(0)} / ${user.dailyCap.toStringAsFixed(0)}',
                              style: GoogleFonts.shareTechMono(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Custom colorful progress meter
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                color: Colors.white.withAlpha(20),
                              ),
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
                        
                        // Captions
                        Text(
                          isCapReached
                              ? 'Daily capping reached! Your transit trips are free for today.'
                              : '${langProvider.translate('lkr')} ${(user.dailyCap - user.dailySpent).toStringAsFixed(2)} remaining before daily cap discount triggers.',
                          style: GoogleFonts.inter(
                            color: isCapReached ? const Color(0xFF00E676) : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Actions Section Label
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

                  // Action Buttons Row (Reload & History)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          context: context,
                          label: langProvider.translate('reloadBalance'),
                          icon: Icons.add_card,
                          color: const Color(0xFF00F2FE),
                          onTap: () => _showReloadModal(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionTile(
                          context: context,
                          label: langProvider.translate('travelHistory'),
                          icon: Icons.history,
                          color: const Color(0xFFFFB300),
                          onTap: () => _showHistoryModal(context),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Profile Full Width Tile
                  _buildActionTile(
                    context: context,
                    label: langProvider.translate('profile'),
                    icon: Icons.person_outline,
                    color: Colors.white,
                    isFullWidth: true,
                    onTap: () => Navigator.pushNamed(context, '/profile'),
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

  /// Builds a premium visual button tile for dashboard activities
  Widget _buildActionTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: isFullWidth ? 64 : 96,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(12)),
        ),
        child: Row(
          mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
