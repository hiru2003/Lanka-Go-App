import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/custom_action_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isFrozen = user.status == 'frozen';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          langProvider.translate('profile'),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  
                  // Big Avatar Circle
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFrozen ? Colors.red : const Color(0xFF00F2FE),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isFrozen ? Colors.red.withAlpha(50) : const Color(0xFF00F2FE).withAlpha(50),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: const Color(0xFF1E293B),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : 'U',
                        style: GoogleFonts.outfit(
                          color: isFrozen ? Colors.red : const Color(0xFF00F2FE),
                          fontWeight: FontWeight.bold,
                          fontSize: 42,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name & Email
                  Text(
                    user.name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 36),

                  // Settings Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withAlpha(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          langProvider.translate('settings').toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF00F2FE),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Card ID
                        _buildProfileField(
                          label: langProvider.translate('cardNumber'),
                          value: user.cardNumber,
                          icon: Icons.credit_card_outlined,
                        ),
                        Divider(color: Colors.white.withAlpha(15), height: 32),

                        // Card Status
                        _buildProfileField(
                          label: langProvider.translate('cardStatus'),
                          value: isFrozen ? 'Card Frozen' : 'Card Active',
                          icon: Icons.check_circle_outline,
                          valueColor: isFrozen ? Colors.redAccent : const Color(0xFF00E676),
                        ),
                        Divider(color: Colors.white.withAlpha(15), height: 32),

                        // Classification Type (Student/Standard)
                        _buildProfileField(
                          label: 'Passenger Classification',
                          value: user.accountType.toUpperCase(),
                          icon: Icons.assignment_ind_outlined,
                          valueColor: user.accountType == 'student'
                              ? const Color(0xFFFFB300)
                              : Colors.white,
                        ),
                        Divider(color: Colors.white.withAlpha(15), height: 32),

                        // Phone Number
                        _buildProfileField(
                          label: 'Phone Contact',
                          value: user.phone,
                          icon: Icons.phone_android_outlined,
                        ),
                        Divider(color: Colors.white.withAlpha(15), height: 32),

                        // Card Freezing Switch Control
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.ac_unit, color: isFrozen ? Colors.red : Colors.white54, size: 20),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Freeze Card',
                                      style: GoogleFonts.inter(
                                        color: Colors.white30,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isFrozen ? 'Card Frozen' : 'Card Active',
                                      style: GoogleFonts.inter(
                                        color: isFrozen ? Colors.red : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: isFrozen,
                              activeThumbColor: Colors.red,
                              onChanged: (val) {
                                authProvider.setFreezeState(val);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      val ? 'Card Frozen successfully!' : 'Card Unfrozen successfully!',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: val ? Colors.redAccent : const Color(0xFF00E676),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Divider(color: Colors.white.withAlpha(15), height: 32),

                        // Language Selector
                        LanguageSelector(isCompact: false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Log Out
                  CustomActionButton(
                    text: langProvider.translate('logout'),
                    icon: Icons.logout,
                    gradient: const [
                      Color(0xFFEF4444),
                      Color(0xFFDC2626),
                    ],
                    onPressed: () {
                      authProvider.logout();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a profile informational item row
  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white30,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
