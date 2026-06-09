import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'onboarding_screen.dart';
import '../repositories/auth_repository.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color lightGray = const Color(0xFFEEEEEE);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  final AuthRepository _authRepository = AuthRepository();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // --- 1. دالة التسجيل بالإيميل والباسورد (API) ---
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await _authRepository.register(
          fullname: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

        if (!mounted) return;

        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } catch (firebaseError) {
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
          } catch (_) {
            // Ignore here; we'll verify existence below.
          }
        }

        // Ensure there's a Firebase user before navigating to onboarding.
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) {
          _showErrorSnackBar(
              'Could not create or sign in Firebase user. Please try logging in.');
          return;
        }

        _navigateToOnboarding(user.fullname, user.email);
      } catch (e) {
        _showErrorSnackBar(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- 2. دالة التسجيل بجوجل ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      _navigateToOnboarding(
        userCredential.user?.displayName ?? "Fitness User",
        userCredential.user?.email ?? "",
      );
    } catch (e) {
      _showErrorSnackBar("Google Sign-In failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. وظائف مساعدة (Helpers) ---
  void _navigateToOnboarding(String name, String email) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OnboardingScreen(userName: name, userEmail: email),
      ),
      (route) => false,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Start your fitness journey today!',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hintText: 'Enter your name',
                icon: Icons.person_outline,
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'example@gmail.com',
                icon: Icons.email_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final trimmed = val.trim();
                  // Require a valid Gmail address following Google's format:
                  // 6 to 30 characters consisting of a-z, 0-9, and . before @gmail.com
                  final gmailRegex = RegExp(r'^[a-zA-Z0-9.]{6,30}@gmail\.com$',
                      caseSensitive: false);
                  if (!gmailRegex.hasMatch(trimmed)) {
                    return 'Please enter a valid Gmail address (6-30 chars, a-z, 0-9, .)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Min. 8 chars, uppercase, lowercase, number & symbol',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Password is required';
                  }
                  if (val.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(val)) {
                    return 'Must contain at least one uppercase letter';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(val)) {
                    return 'Must contain at least one lowercase letter';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(val)) {
                    return 'Must contain at least one digit';
                  }
                  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val)) {
                    return 'Must contain at least one special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hintText: 'Repeat password',
                icon: Icons.lock_reset,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                validator: (val) => (val != _passwordController.text)
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 35),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // const SizedBox(height: 20),
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: Divider(color: Colors.grey.shade300),
                        //     ),
                        //     const Padding(
                        //       padding: EdgeInsets.symmetric(horizontal: 10),
                        //       child: Text(
                        //         "OR",
                        //         style: TextStyle(color: Colors.grey),
                        //       ),
                        //     ),
                        //     Expanded(
                        //       child: Divider(color: Colors.grey.shade300),
                        //     ),
                        //   ],
                        // ),
                        // const SizedBox(height: 20),
                        // OutlinedButton.icon(
                        //   onPressed: _signInWithGoogle,
                        //   icon: Image.asset(
                        //     'assets/images/Google__G__logo.svg.webp',
                        //     height: 24,
                        //   ),
                        //   label: const Text(
                        //     "Continue with Google",
                        //     style: TextStyle(
                        //       color: Colors.black,
                        //       fontWeight: FontWeight.w600,
                        //     ),
                        //   ),
                        //   style: OutlinedButton.styleFrom(
                        //     minimumSize: const Size(double.infinity, 55),
                        //     side: BorderSide(color: Colors.grey.shade300),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(12),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            fillColor: lightGray,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
