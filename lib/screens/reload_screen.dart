import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/custom_action_button.dart';

class ReloadScreen extends StatefulWidget {
  const ReloadScreen({super.key});

  @override
  State<ReloadScreen> createState() => _ReloadScreenState();
}

class _ReloadScreenState extends State<ReloadScreen> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isGatewayOpen = false;
  
  // Mock Payment Gateway Form Fields
  final TextEditingController _cardNumberController = TextEditingController(text: '4532 7182 9283 1092');
  final TextEditingController _expiryController = TextEditingController(text: '12/29');
  final TextEditingController _cvvController = TextEditingController(text: '382');

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _submitReload() async {
    if (!_formKey.currentState!.validate()) return;
    
    final double amount = double.parse(_amountController.text);

    if (amount < 10.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum reload amount is LKR 10.00'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Open simulated PayHere Webview Gateway sheet
    setState(() {
      _isGatewayOpen = true;
    });
  }

  void _processGatewayPayment(double amount) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    setState(() {
      _isGatewayOpen = false;
    });

    // Show simulated API loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00F2FE)),
      ),
    );

    // Call state provider
    final success = await authProvider.reloadBalanceWithPayHere(amount, context);

    if (mounted) {
      Navigator.pop(context); // Dismiss loader
    }

    if (success) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00E676)),
                SizedBox(width: 10),
                Text('Reload Success', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Successfully deposited ${langProvider.translate('lkr')} ${amount.toStringAsFixed(2)} to your Lanka Go Card via PayHere Sandbox.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back to dashboard
                },
                child: const Text('OK', style: TextStyle(color: Color(0xFF00F2FE), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Gateway transaction failed. Please retry.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

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
          langProvider.translate('reloadBalance'),
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isGatewayOpen 
                ? _buildPayHereGatewayScreen(double.parse(_amountController.text)) 
                : _buildAmountInputScreen(langProvider),
          ),
        ),
      ),
    );
  }

  /// Initial screen asking order amount to reload
  Widget _buildAmountInputScreen(LanguageProvider langProvider) {
    return SingleChildScrollView(
      key: const ValueKey('input_screen'),
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ONLINE RELOAD',
              style: GoogleFonts.outfit(
                color: const Color(0xFF00F2FE),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reload Balance',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a deposit amount (Minimum LKR 10.00). Transactions are processed securely through PayHere Sandbox checkout.',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            
            // Amount Input field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '${langProvider.translate('lkr')} ',
                prefixStyle: GoogleFonts.shareTechMono(color: const Color(0xFFFFB300), fontSize: 24, fontWeight: FontWeight.bold),
                labelText: 'Amount to Deposit',
                labelStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF00F2FE), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a valid amount';
                }
                final val = double.tryParse(value);
                if (val == null || val <= 0) {
                  return 'Please enter a positive numeric value';
                }
                if (val < 10) {
                  return 'Minimum reload is LKR 10.00';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 48),

            CustomActionButton(
              text: 'Proceed to Payment',
              icon: Icons.payment,
              gradient: const [Color(0xFF00F2FE), Color(0xFF4FACFE)],
              onPressed: _submitReload,
            ),
          ],
        ),
      ),
    );
  }

  /// Simulated PayHere Sandbox payment webview form
  Widget _buildPayHereGatewayScreen(double amount) {
    return SingleChildScrollView(
      key: const ValueKey('gateway_screen'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PayHere header logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB300).withAlpha(50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security, color: Color(0xFFFFB300), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'payhere',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SANDBOX TEST',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFB300),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          Text(
            'Checkout Details',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Invoice Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(10)),
            ),
            child: Column(
              children: [
                _buildInvoiceRow('Merchant Name', 'Lanka Go Transport PLC'),
                const Divider(color: Colors.white10),
                _buildInvoiceRow('Currency', 'Sri Lankan Rupee (LKR)'),
                const Divider(color: Colors.white10),
                _buildInvoiceRow('Subtotal', 'LKR ${amount.toStringAsFixed(2)}'),
                const Divider(color: Colors.white10),
                _buildInvoiceRow('Processing Fee', 'LKR 0.00'),
                const Divider(color: Colors.white10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    Text(
                      'LKR ${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.shareTechMono(color: const Color(0xFF00E676), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Credit Card Inputs form
          Text(
            'Enter Card Information',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Card input
          TextFormField(
            controller: _cardNumberController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.credit_card, color: Colors.white54),
              labelText: 'Card Number',
              labelStyle: const TextStyle(color: Colors.white30),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withAlpha(10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFB300)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Expiry
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    labelStyle: const TextStyle(color: Colors.white30),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withAlpha(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFB300)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // CVV
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'CVC / CVV',
                    labelStyle: const TextStyle(color: Colors.white30),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withAlpha(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFB300)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Pay Now button
          CustomActionButton(
            text: 'Confirm LKR ${amount.toStringAsFixed(2)}',
            icon: Icons.verified_user,
            gradient: const [Color(0xFFFFB300), Color(0xFFFFA000)], // gold
            onPressed: () => _processGatewayPayment(amount),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isGatewayOpen = false;
                });
              },
              child: const Text('Cancel Payment', style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
