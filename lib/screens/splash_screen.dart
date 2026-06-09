import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../repositories/profile_repository.dart';
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

    // 2. استرجاع الـ token الخاص بالـ API
    await ApiService.instance.restoreAuthToken();

    final apiToken = ApiService.instance.authToken;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // 3. التحقق من تسجيل الدخول عبر الـ API أولاً
    if (apiToken != null && apiToken.isNotEmpty) {
      try {
        final profile = await ProfileRepository().getProfileData();
        if (profile != null) {
          // لديه ملف شخصي كامل -> الذهاب للـ Dashboard مباشرة
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                userName: profile.fullName,
                userEmail: profile.email,
                age: profile.age.toString(),
                height: profile.height.toString(),
                weight: profile.currentWeight.toString(),
                gender: profile.gender,
                targetWeight: profile.targetWeight.toString(),
                activityLevel: profile.activeLevel,
                fitnessGoal: profile.fitnessGoal,
                experienceLevel: profile.experienceLevel,
                equipment: profile.equipment,
                durationDays: "",
              ),
            ),
          );
          return;
        } else {
          // مسجل دخول ولكن لم يكمل بياناته (أونبوردينج)
          // نحاول إيجاد الإيميل والاسم المخزنين محلياً
          final prefs = await SharedPreferences.getInstance();
          final savedName = prefs.getString('user_name') ?? "Member";
          final savedEmail = prefs.getString('user_email') ?? "";

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(
                userName: savedName,
                userEmail: savedEmail.isNotEmpty
                    ? savedEmail
                    : (firebaseUser?.email ?? ""),
              ),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint("Splash API login error: $e");
        // لو حدث خطأ في النت ولكن الـ token موجود واليوزر محفوظ محلياً، ممكن نحاول نستخدم البيانات المحفوظة
        final prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString('user_name');
        final savedEmail = prefs.getString('user_email');
        final hasProfile = prefs.getBool('has_profile') ?? false;

        if (savedName != null && savedEmail != null && hasProfile) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                userName: savedName,
                userEmail: savedEmail,
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
              ),
            ),
          );
          return;
        }
      }
    }

    // 4. التحقق من تسجيل الدخول عبر Firebase إذا لم يكن هناك تسجيل عبر الـ API
    if (firebaseUser != null) {
      _checkFirestoreData(firebaseUser.uid, firebaseUser.email ?? "");
    } else {
      // غير مسجل إطلاقاً -> صفحة الـ Intro
      _navigateTo(const IntroScreen());
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
