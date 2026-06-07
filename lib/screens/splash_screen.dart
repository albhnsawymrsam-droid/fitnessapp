import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';
import 'intro_screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // 1. استنى ثانيتين عشان اللوجو يظهر (شياكة)
    await Future.delayed(const Duration(seconds: 2));

    // 2. هل فيه يوزر مسجل أصلاً؟
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // مش مسجل -> وديه على صفحة الـ Intro
      _navigateTo(const IntroScreen());
    } else {
      // مسجل -> تعال نشوف الداتابيز بتاعته
      _checkFirestoreData(user.uid, user.email ?? "");
    }
  }

  // --- ميثود الفحص وتعديل المتغيرات لتطابق الـ DashboardScreen المحدثة ---
  Future<void> _checkFirestoreData(String uid, String email) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // هل هو مخلص الاونبوردنج؟
        bool isSetupComplete = data['setupComplete'] ?? false;

        if (isSetupComplete) {
          if (!mounted) return;
          // التنقل إلى الـ Dashboard بالمتغيرات الصحيحة والمطابقة
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                userName: data['name'] ?? "Member",
                userEmail: data['email'] ?? email,
                age: data['age']?.toString() ?? "",
                height: data['height']?.toString() ?? "",
                weight: data['weight']?.toString() ?? "",
                gender: data['gender'] ?? "",
                targetWeight: data['targetWeight']?.toString() ?? "",
                activityLevel: data['activityLevel'] ?? "",
                fitnessGoal: data['fitnessGoal'] ?? "",
                experienceLevel: data['experienceLevel'] ?? "",
                equipment: data['equipment'] ?? "",
                durationDays: data['durationDays']?.toString() ??
                    "", // تم إضافة تمرير المتغير الجديد هنا بنجاح
              ),
            ),
          );
        } else {
          // مسجل دخول بس لسه مكملش بياناته -> وديه يكمل
          _navigateTo(
            OnboardingScreen(
              userName: data['name'] ?? "Member",
              userEmail: email,
            ),
          );
        }
      } else {
        // ملوش داتابيز أصلاً -> وديه يعمل اونبوردنج
        _navigateTo(OnboardingScreen(userName: "Member", userEmail: email));
      }
    } catch (e) {
      print("Splash Firestore Error: $e");
      // لو حصل أي ايرور في النت، وديه اللوجين احتياطي
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.fitness_center, size: 80, color: Color(0xFF2E8B57)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Color(0xFF2E8B57)),
          ],
        ),
      ),
    );
  }
}
