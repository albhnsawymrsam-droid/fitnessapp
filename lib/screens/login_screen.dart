import 'package:ai/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';
import 'forgot_password_flow.dart';
import '../repositories/auth_repository.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color lightGray = const Color(0xFFEEEEEE);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isAdmin = false;
  final AuthRepository _authRepository = AuthRepository();

  // --- ميثود التنقل والتحقق من Firestore ---
  Future<void> _handleNavigation(User? user) async {
    if (user == null) return;
    try {
      String collectionName = 'users';

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        final bool isAdminUser =
            (userData['role'] ?? '').toString().toLowerCase() == 'admin';

        // فحص: هل كمل بيانات الأونبوردينج؟
        if (userData['setupComplete'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                userName: userData['name'] ?? "Member",
                userEmail: userData['email'] ?? user.email ?? "",
                age: userData['age']?.toString() ?? "",
                height: userData['height']?.toString() ?? "",
                weight: userData['weight']?.toString() ?? "",
                gender: userData['gender'] ?? "",
                targetWeight: userData['targetWeight']?.toString() ?? "",
                activityLevel: userData['activityLevel'] ?? "",
                fitnessGoal: userData['fitnessGoal'] ?? "",
                experienceLevel: userData['experienceLevel'] ?? "",
                equipment: userData['equipment'] ?? "",
                durationDays: userData['durationDays']?.toString() ?? "",
                isAdmin:
                    isAdminUser, // تم إضافة تمرير المتغير الجديد هنا لمنع أي خلل
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(
                userName: userData['name'] ?? user.displayName ?? "Member",
                userEmail: user.email ?? "",
              ),
            ),
          );
        }
      } else {
        // مستخدم جديد يسجل لأول مرة يروح يكمل بياناته
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingScreen(
              userName: user.displayName ?? "Member",
              userEmail: user.email ?? "",
            ),
          ),
        );
      }
    } catch (e) {
      print("Navigation Error: $e");
    }
  }

  // --- جوجل لوجين ---
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
      await _handleNavigation(userCredential.user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // // --- لوجين عادي (API) ---
  // Future<void> _login() async {
  //   if (_formKey.currentState!.validate()) {
  //     setState(() => _isLoading = true);
  //     try {
  //       final result = await _authRepository.login(
  //         email: _emailController.text.trim(),
  //         password: _passwordController.text.trim(),
  //       );

  //       if (!mounted) return;

  //       final token = result['token'];
  //       debugPrint('LOGIN token: $token');
  //       // ✅ أضف السطر ده
  //       if (token != null) ApiService.instance.setAuthToken(token);

  //       final user = result['user'];
  //       final hasProfile = result['hasProfile'] ?? false;

  //       if (_isAdmin) {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => const AdminScreen(),
  //           ),
  //         );
  //         return;
  //       }

  //       User? firebaseUser;
  //       try {
  //         final authResult =
  //             await FirebaseAuth.instance.signInWithEmailAndPassword(
  //           email: _emailController.text.trim(),
  //           password: _passwordController.text.trim(),
  //         );
  //         firebaseUser = authResult.user;
  //       } catch (_) {
  //         firebaseUser = null;
  //       }

  //       if (firebaseUser != null) {
  //         await _handleNavigation(firebaseUser);
  //         return;
  //       }

  //       if (hasProfile) {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => DashboardScreen(
  //               userName: user.fullname,
  //               userEmail: user.email,
  //               age: "",
  //               height: "",
  //               weight: "",
  //               gender: "",
  //               targetWeight: "",
  //               activityLevel: "",
  //               fitnessGoal: "",
  //               experienceLevel: "",
  //               equipment: "",
  //               durationDays: "",
  //             ),
  //           ),
  //         );
  //       } else {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => OnboardingScreen(
  //               userName: user.fullname,
  //               userEmail: user.email,
  //             ),
  //           ),
  //         );
  //       }
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(e.toString()),
  //           backgroundColor: Colors.redAccent,
  //         ),
  //       );
  //     } finally {
  //       if (mounted) setState(() => _isLoading = false);
  //     }
  //   }
  // }

// --- لوجين عادي (API) ---
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final result = await _authRepository.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        final token = result['token'];
        debugPrint('LOGIN token: $token');
        if (token != null){ ApiService.instance.setAuthToken(token);
        
        }

        final user = result['user'];
        final hasProfile = result['hasProfile'] ?? false;

        // if (_isAdmin) {
        //   Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => const AdminScreen(),
        //     ),
        //   );
        //   return;
        // }
        final role = result['user']?.role ?? result['role'] ?? '';
        final bool isAdminUser = role.toString().toLowerCase() == 'admin';

        User? firebaseUser;
        try {
          final authResult =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          firebaseUser = authResult.user;
        } catch (_) {
          firebaseUser = null;
        }

        if (firebaseUser != null) {
          await _handleNavigation(firebaseUser);
          return;
        }

        if (hasProfile) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                userName: user.fullname ?? "User",
                userEmail: user.email ?? "",
                age: "",
                height: "",
                weight: "",
                gender: "",
                targetWeight: "",
                activityLevel: "",
                fitnessGoal: "",
                experienceLevel: "",
                equipment: "",
                durationDays: "",
                isAdmin: isAdminUser,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(
                userName: user.fullname ?? "User",
                userEmail: user.email ?? "",
              ),
            ),
          );
        }
      } catch (e) {
        // 👈 التعديل السحري هنا: مسكنا الإيرور وحولناه لرسالة شيك
        if (!mounted) return;

        String errorMessage = "Something went wrong. Please try again.";
        if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          errorMessage =
              "Invalid Email or Password!"; // رسالة الخطأ لو البيانات غلط
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.red,
            behavior:
                SnackBarBehavior.floating, // عشان الرسالة تظهر عايمة وشكلها حلو
            margin: const EdgeInsets.all(20),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).padding.top + 40),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 25),

              // سويتش User / Admin
              // Container(
              //   height: 50,
              //   decoration: BoxDecoration(
              //     color: lightGray,
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Row(
              //     children: [
              //       _buildRoleTab(
              //         title: "User",
              //         selected: !_isAdmin,
              //         onTap: () => setState(() => _isAdmin = false),
              //       ),
              //       _buildRoleTab(
              //         title: "Admin",
              //         selected: _isAdmin,
              //         onTap: () => setState(() => _isAdmin = true),
              //       ),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 30),
              Text(
                _isAdmin ? 'Admin Portal' : 'Welcome Back!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'Enter your email',
                icon: Icons.email_outlined,
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Enter your password',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (value) => (value == null || value.length < 6)
                    ? 'Password is too short'
                    : null,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ElevatedButton(
                        //   onPressed: () {
                        //     setState(() => _isAdmin = true);
                        //     _login();
                        //   },
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: primaryGreen,
                        //     foregroundColor: Colors.white,
                        //     minimumSize: const Size(double.infinity, 55),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(12),
                        //     ),
                        //   ),
                        //   child: const Text(
                        //     'Login as Admin',
                        //     style: TextStyle(
                        //       fontSize: 16,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 20),

                        // زرار جوجل بعد تعديل الأيقونة
                        OutlinedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: Image.asset(
                            'assets/images/Google__G__logo.svg.webp',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.account_circle,
                              color: Colors.grey,
                            ),
                          ),
                          label: Text(
                            _isAdmin
                                ? "Login as Admin with Google"
                                : "Continue with Google",
                            style: const TextStyle(color: Colors.black),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),

              if (!_isAdmin) ...[
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Create Account",
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
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
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.grey),
            fillColor: lightGray,
            filled: true,
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
