import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_action_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardController = TextEditingController();
  
  String _accountType = 'regular'; // 'regular' | 'student'

  @override
  void initState() {
    super.initState();
    _generateRandomCardNumber();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _generateRandomCardNumber() {
    final random = Random();
    final block1 = random.nextInt(9000) + 1000;
    final block2 = random.nextInt(9000) + 1000;
    setState(() {
      _cardController.text = 'LK-GO-$block1-$block2';
    });
  }

  void _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    final cardNumber = _cardController.text.trim();

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
    final success = await authProvider.registerWithEmail(
      name: name,
      email: email,
      password: password,
      phone: phone,
      accountType: _accountType,
      cardNumber: cardNumber,
    );

    if (mounted) {
      Navigator.pop(context); // Dismiss loader
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account successfully created!'),
            backgroundColor: Color(0xFF00E676),
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
                const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                const SizedBox(width: 10),
                const Text(
                  'Registration Error',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              authProvider.authError ?? 'Registration failed. Please try again.',
              style: const TextStyle(color: Colors.white70),
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

  @override
  Widget build(BuildContext context) {
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
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button & Title
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        ),
                        const Spacer(),
                        Text(
                          'Create Account',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40), // Balance alignment
                      ],
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        'Join Lanka Go today. Get 100 LKR promotional travel credit automatically credited upon registration!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white54,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Email Address', Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Password', Icons.lock_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please choose a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Phone Number', Icons.phone_outlined),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card Number Field
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cardController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Lanka Go Card Number', Icons.credit_card),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter or generate a card number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _generateRandomCardNumber,
                            icon: const Icon(Icons.refresh, color: Color(0xFF00F2FE)),
                            tooltip: 'Generate new card number',
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Account Type Toggle Label
                    const Text(
                      'Account Classification',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),

                    // Regular / Student Choice Chips
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Regular (Full Fare)')),
                            selected: _accountType == 'regular',
                            selectedColor: const Color(0xFF00F2FE).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF00F2FE),
                            labelStyle: TextStyle(
                              color: _accountType == 'regular' ? const Color(0xFF00F2FE) : Colors.white60,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (selected) {
                              if (selected) setState(() => _accountType = 'regular');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Student (50% Off)')),
                            selected: _accountType == 'student',
                            selectedColor: const Color(0xFFFFB300).withOpacity(0.2),
                            checkmarkColor: const Color(0xFFFFB300),
                            labelStyle: TextStyle(
                              color: _accountType == 'student' ? const Color(0xFFFFB300) : Colors.white60,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (selected) {
                              if (selected) setState(() => _accountType = 'student');
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    CustomActionButton(
                      text: 'Create Account & Link Card',
                      icon: Icons.person_add_alt_1_outlined,
                      gradient: const [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                      onPressed: _submitRegister,
                      width: double.infinity,
                      height: 52,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF00F2FE)),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00F2FE), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
