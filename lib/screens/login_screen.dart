import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/custom_action_button.dart';
import '../widgets/language_selector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  MobileScannerController? _scannerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String? _scanErrorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _scanErrorMessage = null;
      _isScanning = true;
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
      _scannerController?.dispose();
      _scannerController = null;
    });
  }

  void _handleBarCode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue != null && rawValue.isNotEmpty) {
      _stopScanning();
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

      // Show loader dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00F2FE),
          ),
        ),
      );

      final success = await authProvider.loginWithQR(rawValue);
      
      if (mounted) {
        Navigator.pop(context); // Dismiss loader
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(languageProvider.translate('loginSuccess')),
              backgroundColor: const Color(0xFF00E676),
            ),
          );
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFFB300)),
                  const SizedBox(width: 10),
                  Text(
                    languageProvider.translate('notification'),
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Text(
                authProvider.authError ?? languageProvider.translate('invalidQR'),
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  /// Bypass scan for local development/simulator testing
  void _bypassScan() async {
    // Format: LANKAGO:USER:id:name:email:balance:phone:status:accountType:cardNumber
    const mockPayload = 'LANKAGO:USER:usr_001:Kamal Silva:kamal.silva@lankago.lk:150.00:0771234567:active:regular:LK-GO-1092-8472';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00F2FE),
        ),
      ),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithQR(mockPayload);

    if (mounted) {
      Navigator.pop(context); // Dismiss loader
    }

    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.authError ?? 'Login Failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Dark slate blue
              Color(0xFF020617), // Deep space black
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top bar with App Name & Language Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.airport_shuttle, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          langProvider.translate('appName'),
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    LanguageSelector(isCompact: true),
                  ],
                ),
                
                const Spacer(),

                // Central Card Body
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isScanning ? _buildScannerView(size) : _buildSplashView(size, langProvider),
                ),

                const Spacer(),

                // Bottom Dev Bypass Button
                if (!_isScanning) ...[
                  Opacity(
                    opacity: 0.6,
                    child: TextButton.icon(
                      onPressed: _bypassScan,
                      icon: const Icon(Icons.developer_mode, color: Color(0xFFFFB300), size: 16),
                      label: Text(
                        langProvider.translate('bypassScan'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFB300),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Splash welcome layout
  Widget _buildSplashView(Size size, LanguageProvider langProvider) {
    return Column(
      key: const ValueKey('splash_view'),
      children: [
        // Premium Card Graphic
        Container(
          height: 190,
          width: size.width * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
            border: Border.all(color: Colors.white.withAlpha(20), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F2FE).withAlpha(10),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Stack(
            children: [
              // Abstract vector curves
              Positioned(
                right: -20,
                top: -20,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: const Color(0xFF00F2FE).withAlpha(10),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: const Color(0xFFFFB300).withAlpha(5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.contactless_outlined, color: Color(0xFF00F2FE), size: 32),
                        Text(
                          'LANKA GO SMART',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•••• •••• •••• 8472',
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          langProvider.translate('tagline'),
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 48),

        // Text labels
        Text(
          langProvider.translate('loginTitle'),
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            langProvider.translate('loginSubtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
        ),
        
        const SizedBox(height: 40),

        // Core CTA Button
        CustomActionButton(
          text: langProvider.translate('scanButton'),
          icon: Icons.qr_code_scanner,
          gradient: const [Color(0xFF00F2FE), Color(0xFF4FACFE)],
          onPressed: _startScanning,
          width: size.width * 0.75,
        ),
      ],
    );
  }

  /// QR Scanner View with mobile_scanner
  Widget _buildScannerView(Size size) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final scannerWidth = size.width * 0.8;

    return Column(
      key: const ValueKey('scanner_view'),
      children: [
        Text(
          langProvider.translate('scanningText'),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Viewport Frame
        Stack(
          alignment: Alignment.center,
          children: [
            // Scanner container
            Container(
              height: scannerWidth,
              width: scannerWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(30), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _scanErrorMessage != null
                    ? _buildScanErrorWidget()
                    : MobileScanner(
                        controller: _scannerController,
                        onDetect: _handleBarCode,
                        errorBuilder: (context, error, child) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                                _scanErrorMessage = langProvider.translate('cameraPermissionDenied');
                              } else {
                                _scanErrorMessage = 'Scanner Error: ${error.errorDetails?.message ?? error.toString()}';
                              }
                            });
                          });
                          return const SizedBox();
                        },
                      ),
              ),
            ),

            // Holographic focus lines overlay (only if no error)
            if (_scanErrorMessage == null)
              IgnorePointer(
                child: SizedBox(
                  height: scannerWidth,
                  width: scannerWidth,
                  child: Stack(
                    children: [
                      // Glow scanning bar
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: _pulseAnimation.value * (scannerWidth - 10),
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F2FE),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F2FE).withAlpha(180),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Floating framing corners
                      _buildScannerCorners(scannerWidth),
                    ],
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 32),

        // Action cancel / stop button
        CustomActionButton(
          text: langProvider.translate('logout') == 'Log Out' ? 'Cancel' : 'අවලංගු කරන්න',
          icon: Icons.close,
          gradient: const [Color(0xFFEF4444), Color(0xFFB91C1C)], // Red gradient
          onPressed: _stopScanning,
          width: size.width * 0.5,
          height: 48,
        ),
      ],
    );
  }

  /// Build customized focus corner markings for the scanner viewport
  Widget _buildScannerCorners(double size) {
    const double length = 30;
    const double thickness = 4;
    const Color cornerColor = Color(0xFF00F2FE);

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // Top Left
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: length,
                height: thickness,
                color: cornerColor,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: thickness,
                height: length,
                color: cornerColor,
              ),
            ),

            // Top Right
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: length,
                height: thickness,
                color: cornerColor,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: thickness,
                height: length,
                color: cornerColor,
              ),
            ),

            // Bottom Left
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: length,
                height: thickness,
                color: cornerColor,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: thickness,
                height: length,
                color: cornerColor,
              ),
            ),

            // Bottom Right
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: length,
                height: thickness,
                color: cornerColor,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: thickness,
                height: length,
                color: cornerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Built UI inside camera frame if error occurs
  Widget _buildScanErrorWidget() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            _scanErrorMessage ?? 'Camera error occurred.',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              _stopScanning();
              _startScanning();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(langProvider.translate('retryPermission')),
          ),
        ],
      ),
    );
  }
}
