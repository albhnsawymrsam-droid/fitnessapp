import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import '../repositories/profile_repository.dart';

class OnboardingScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const OnboardingScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color cardBg = const Color(0xFFF9F9F9);

  // --- Controllers & Variables (Screen 1) ---
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  String? _selectedGender;

  // --- Controllers & Variables (Screen 2) ---
  String? _selectedActivity;
  String? _selectedGoal;
  String? _selectedExp;
  String? _selectedEquipment;

  // لتخزين رسائل الخطأ وعرضها فوق كل حقل بشكل مخصص
  final Map<String, String?> _errors = {};

  void _showValidationSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ميثود مخصصة للتحقق من المنطق (Logical Validation) وتحديث الحقول يدوياً فوق الانبوت
  bool _validateCurrentPage() {
    bool isValid = true;
    setState(() {
      _errors.clear(); // تنظيف الأخطاء السابقة

      if (_currentPage == 0) {
        // فحص السن
        final age = int.tryParse(_ageController.text);
        if (age == null) {
          _errors['age'] = "Please enter a valid age";
          isValid = false;
        } else if (age < 12 || age > 90) {
          _errors['age'] = "Age must be between 12 and 90 years";
          isValid = false;
        }

        // فحص الجنس
        if (_selectedGender == null) {
          _showValidationSnackBar("Please select your gender");
          isValid = false;
        }

        // فحص الطول
        final height = double.tryParse(_heightController.text);
        if (height == null) {
          _errors['height'] = "Please enter your height";
          isValid = false;
        } else if (height < 100 || height > 250) {
          _errors['height'] = "Height must be between 100 and 250 cm";
          isValid = false;
        }

        // فحص الوزن الحالي
        final weight = double.tryParse(_weightController.text);
        if (weight == null) {
          _errors['weight'] = "Please enter your weight";
          isValid = false;
        } else if (weight < 30 || weight > 250) {
          _errors['weight'] = "Weight must be between 30 and 250 kg";
          isValid = false;
        }

        // فحص الوزن المستهدف (الصفحة الأولى)
        final targetW = double.tryParse(_targetWeightController.text);
        if (targetW == null) {
          _errors['targetWeight'] = "Please enter target weight";
          isValid = false;
        } else if (targetW < 30 || targetW > 250) {
          _errors['targetWeight'] = "Target must be between 30 and 250 kg";
          isValid = false;
        }
      } else if (_currentPage == 1) {
        // فحص الدروب داونز
        if (_selectedActivity == null) {
          _errors['activityLevel'] = "Please select activity level";
          isValid = false;
        }
        if (_selectedGoal == null) {
          _errors['fitnessGoal'] = "Please select fitness goal";
          isValid = false;
        }
        if (_selectedExp == null) {
          _errors['experienceLevel'] = "Please select experience level";
          isValid = false;
        }
        if (_selectedEquipment == null) {
          _errors['equipment'] = "Please select available equipment";
          isValid = false;
        }
      }
    });
    return isValid;
  }

  Future<bool> _saveToFirestore() async {
    setState(() => _isLoading = true);
    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (uid.isEmpty) return false;

      // ── الأول بنحفظ في Vercel ──
      final ageVal = int.tryParse(_ageController.text) ?? 20;
      final heightVal = double.tryParse(_heightController.text)?.toInt() ?? 180;
      final weightVal = double.tryParse(_weightController.text)?.toInt() ?? 85;
      final targetWeightVal =
          double.tryParse(_targetWeightController.text)?.toInt() ?? 100;

      final genderVal = _selectedGender?.toUpperCase() ?? 'MALE';
      final activeLevelVal =
          _selectedActivity?.toUpperCase().replaceAll(' ', '_') ?? 'LIGHT';
      final fitnessGoalVal =
          _selectedGoal?.toUpperCase().replaceAll(' ', '_') ?? 'LOSE_WEIGHT';
      final experienceLevelVal =
          _selectedExp?.toUpperCase().replaceAll(' ', '_') ?? 'BEGINNER';
      final equipmentVal =
          _selectedEquipment?.toUpperCase().replaceAll(' ', '_') ?? 'AT_HOME';

      final profileRepo = ProfileRepository();
      final userProfile = await profileRepo.addProfile(
        age: ageVal,
        gender: genderVal,
        height: heightVal,
        currentWeight: weightVal,
        targetWeight: targetWeightVal,
        activeLevel: activeLevelVal,
        fitnessGoal: fitnessGoalVal,
        experienceLevel: experienceLevelVal,
        equipment: equipmentVal,
      );

      if (userProfile == null) {
        throw Exception("Failed to add profile to Vercel backend.");
      }

      // ── بعد نجاح الـ Vercel، بنحفظ في Firestore ──
      double? finalTargetWeight = double.tryParse(
        _targetWeightController.text,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': widget.userName,
        'email': widget.userEmail,
        'age': int.tryParse(_ageController.text),
        'height': double.tryParse(_heightController.text),
        'weight': double.tryParse(_weightController.text),
        'targetWeight': finalTargetWeight,
        'gender': _selectedGender,
        'activityLevel': _selectedActivity,
        'fitnessGoal': _selectedGoal,
        'experienceLevel': _selectedExp,
        'equipment': _selectedEquipment,
        'setupComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (mounted) {
        _showValidationSnackBar("Error saving data: $e");
      }
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() async {
    if (_validateCurrentPage()) {
      if (_currentPage < 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // الخطوة الأخيرة: الحفظ والانتقال للداشبورد
        final success = await _saveToFirestore();
        if (!success || !mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userName: widget.userName,
              userEmail: widget.userEmail,
              age: _ageController.text,
              height: _heightController.text,
              weight: _weightController.text,
              targetWeight: _targetWeightController.text,
              gender: _selectedGender,
              activityLevel: _selectedActivity,
              fitnessGoal: _selectedGoal,
              experienceLevel: _selectedExp,
              equipment: _selectedEquipment,
            ),
          ),
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _buildProgressHeader(),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [_buildStepOne(), _buildStepTwo()],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  // --- Step 1: Physical Data ---
  Widget _buildStepOne() {
    return _pageWrapper(
      title: "Body Details",
      subtitle: "Let's start with the basics",
      child: Column(
        children: [
          _buildInputField(
            controller: _ageController,
            errorKey: 'age',
            label: "Age",
            icon: Icons.calendar_today,
            unit: "Years",
          ),
          const SizedBox(height: 15),
          _buildSectionTitle("Gender"),
          Row(
            children: [
              _buildGenderCard("Male", Icons.male),
              const SizedBox(width: 15),
              _buildGenderCard("Female", Icons.female),
            ],
          ),
          const SizedBox(height: 15),
          _buildInputField(
            controller: _heightController,
            errorKey: 'height',
            label: "Height",
            icon: Icons.height,
            unit: "cm",
          ),
          const SizedBox(height: 15),
          _buildInputField(
            controller: _weightController,
            errorKey: 'weight',
            label: "Current Weight",
            icon: Icons.monitor_weight,
            unit: "kg",
          ),
          const SizedBox(height: 15),
          _buildInputField(
            controller: _targetWeightController,
            errorKey: 'targetWeight',
            label: "Target Weight",
            icon: Icons.track_changes,
            unit: "kg",
          ),
        ],
      ),
    );
  }

  // --- Step 2: Fitness Goals & Level ---
  Widget _buildStepTwo() {
    return _pageWrapper(
      title: "Fitness Profile",
      subtitle: "Customize your training experience",
      child: Column(
        children: [
          _buildDropdownField(
            errorKey: 'activityLevel',
            label: "Activity Level",
            value: _selectedActivity,
            items: ["sedentary", "light", "moderate", "active", "very active"],
            onChanged: (v) => setState(() => _selectedActivity = v),
          ),
          const SizedBox(height: 15),
          _buildDropdownField(
            errorKey: 'fitnessGoal',
            label: "Fitness Goal",
            value: _selectedGoal,
            items: ["lose weight", "bodybuilding", "powerlifting", "athletics"],
            onChanged: (v) => setState(() => _selectedGoal = v),
          ),
          const SizedBox(height: 15),
          _buildDropdownField(
            errorKey: 'experienceLevel',
            label: "Experience Level",
            value: _selectedExp,
            items: ["beginner", "intermediate", "advanced"],
            onChanged: (v) => setState(() => _selectedExp = v),
          ),
          const SizedBox(height: 15),
          _buildDropdownField(
            errorKey: 'equipment',
            label: "Equipment",
            value: _selectedEquipment,
            items: ["full gym", "at home", "garage gym"],
            onChanged: (v) => setState(() => _selectedEquipment = v),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildProgressHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 6,
          width: 60,
          decoration: BoxDecoration(
            color: _currentPage >= index ? primaryGreen : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _pageWrapper({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildGenderCard(String label, IconData icon) {
    bool isSelected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? primaryGreen : cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryGreen : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String errorKey,
    required String label,
    required IconData icon,
    required String unit,
  }) {
    bool hasError = _errors[errorKey] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _errors[errorKey]!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: hasError ? Colors.redAccent : primaryGreen,
            ),
            suffixText: unit,
            filled: true,
            fillColor: cardBg,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : primaryGreen,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : Colors.transparent,
                width: 1,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String errorKey,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    bool hasError = _errors[errorKey] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(label),
            if (hasError)
              Text(
                _errors[errorKey]!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        DropdownButtonFormField<String>(
          value: value,
          hint: const Text("Select option"),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: cardBg,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : primaryGreen,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : Colors.transparent,
                width: 1,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousPage,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 55),
                  side: BorderSide(color: primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "BACK",
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                minimumSize: const Size(0, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentPage == 1 ? "CREATE PROFILE" : "NEXT",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dashboard_screen.dart';

// class OnboardingScreen extends StatefulWidget {
//   final String userName;
//   final String userEmail;

//   const OnboardingScreen({
//     super.key,
//     required this.userName,
//     required this.userEmail,
//   });

//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;

//   final Color primaryGreen = const Color(0xFF2E8B57);
//   final Color cardBg = const Color(0xFFF9F9F9);

//   // --- Controllers & Variables (Screen 1) ---
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _heightController = TextEditingController();
//   final TextEditingController _weightController = TextEditingController();
//   final TextEditingController _targetWeightController = TextEditingController();
//   String? _selectedGender;

//   // --- Controllers & Variables (Screen 2) ---
//   //final TextEditingController _durationDaysController =
//       TextEditingController(); // حقل الأيام الجديد المطلوب بالصفحة الثانية
//   String? _selectedActivity;
//   String? _selectedGoal;
//   String? _selectedExp;
//   String? _selectedEquipment;

//   // لتخزين رسائل الخطأ وعرضها فوق كل حقل بشكل مخصص
//   final Map<String, String?> _errors = {};

//   void _showValidationSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // ميثود مخصصة للتحقق من المنطق (Logical Validation) وتحديث الحقول يدوياً فوق الانبوت
//   bool _validateCurrentPage() {
//     bool isValid = true;
//     setState(() {
//       _errors.clear(); // تنظيف الأخطاء السابقة

//       if (_currentPage == 0) {
//         // فحص السن
//         final age = int.tryParse(_ageController.text);
//         if (age == null) {
//           _errors['age'] = "Please enter a valid age";
//           isValid = false;
//         } else if (age < 12 || age > 90) {
//           _errors['age'] = "Age must be between 12 and 90 years";
//           isValid = false;
//         }

//         // فحص الجنس
//         if (_selectedGender == null) {
//           _showValidationSnackBar("Please select your gender");
//           isValid = false;
//         }

//         // فحص الطول
//         final height = double.tryParse(_heightController.text);
//         if (height == null) {
//           _errors['height'] = "Please enter your height";
//           isValid = false;
//         } else if (height < 100 || height > 250) {
//           _errors['height'] = "Height must be between 100 and 250 cm";
//           isValid = false;
//         }

//         // فحص الوزن الحالي
//         final weight = double.tryParse(_weightController.text);
//         if (weight == null) {
//           _errors['weight'] = "Please enter your weight";
//           isValid = false;
//         } else if (weight < 30 || weight > 250) {
//           _errors['weight'] = "Weight must be between 30 and 250 kg";
//           isValid = false;
//         }

//         // فحص الوزن المستهدف (الصفحة الأولى)
//         final targetW = double.tryParse(_targetWeightController.text);
//         if (targetW == null) {
//           _errors['targetWeight'] = "Please enter target weight";
//           isValid = false;
//         } else if (targetW < 30 || targetW > 250) {
//           _errors['targetWeight'] = "Target must be between 30 and 250 kg";
//           isValid = false;
//         }
//       } else if (_currentPage == 1) {
//         // فحص الدروب داونز
//         if (_selectedActivity == null) {
//           _errors['activityLevel'] = "Please select activity level";
//           isValid = false;
//         }
//         if (_selectedGoal == null) {
//           _errors['fitnessGoal'] = "Please select fitness goal";
//           isValid = false;
//         }
//         if (_selectedExp == null) {
//           _errors['experienceLevel'] = "Please select experience level";
//           isValid = false;
//         }
//         if (_selectedEquipment == null) {
//           _errors['equipment'] = "Please select available equipment";
//           isValid = false;
//         }

//         // فحص أيام التدريب المحددة (Duration Days)
//         // final days = int.tryParse(_durationDaysController.text);
//         // if (days == null) {
//         //   _errors['durationDays'] = "Please enter training days";
//         //   isValid = false;
//         // } else if (days < 1 || days > 7) {
//         //   _errors['durationDays'] = "Days must be between 1 and 7 days a week";
//         //   isValid = false;
//         // }
//       }
//     });
//     return isValid;
//   }

//   Future<void> _saveToFirestore() async {
//     setState(() => _isLoading = true);
//     try {
//       final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

//       if (uid.isNotEmpty) {
//         // الاعتماد بالكامل على حقل الوزن المستهدف من الصفحة الأولى بعد حذف الثاني
//         double? finalTargetWeight = double.tryParse(
//           _targetWeightController.text,
//         );

//         await FirebaseFirestore.instance.collection('users').doc(uid).set({
//           'name': widget.userName,
//           'email': widget.userEmail,
//           'age': int.tryParse(_ageController.text),
//           'height': double.tryParse(_heightController.text),
//           'weight': double.tryParse(_weightController.text),
//           'targetWeight': finalTargetWeight,
//           'gender': _selectedGender,
//           'activityLevel': _selectedActivity,
//           'fitnessGoal': _selectedGoal,
//           'experienceLevel': _selectedExp,
//           'equipment': _selectedEquipment,
//           // 'durationDays': int.tryParse(
//           //   _durationDaysController.text,
//           // ), // حفظ الحقل الجديد المضاف
//           'setupComplete': true,
//           'lastUpdated': FieldValue.serverTimestamp(),
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         _showValidationSnackBar("Error saving data: $e");
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   void _nextPage() async {
//     if (_validateCurrentPage()) {
//       if (_currentPage < 1) {
//         _pageController.nextPage(
//           duration: const Duration(milliseconds: 500),
//           curve: Curves.easeInOut,
//         );
//       } else {
//         // الخطوة الأخيرة: الحفظ والانتقال للداشبورد
//         await _saveToFirestore();
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DashboardScreen(
//               userName: widget.userName,
//               userEmail: widget.userEmail,
//             ),
//           ),
//         );
//       }
//     }
//   }

//   void _previousPage() {
//     if (_currentPage > 0) {
//       _pageController.previousPage(
//         duration: const Duration(milliseconds: 500),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: _buildProgressHeader(),
//         centerTitle: true,
//       ),
//       body: Stack(
//         children: [
//           Form(
//             key: _formKey,
//             child: PageView(
//               controller: _pageController,
//               physics: const NeverScrollableScrollPhysics(),
//               onPageChanged: (page) => setState(() => _currentPage = page),
//               children: [_buildStepOne(), _buildStepTwo()],
//             ),
//           ),
//           if (_isLoading)
//             Container(
//               color: Colors.white.withOpacity(0.8),
//               child: Center(
//                 child: CircularProgressIndicator(color: primaryGreen),
//               ),
//             ),
//         ],
//       ),
//       bottomNavigationBar: _buildActionButtons(),
//     );
//   }

//   // --- Step 1: Physical Data ---
//   Widget _buildStepOne() {
//     return _pageWrapper(
//       title: "Body Details",
//       subtitle: "Let's start with the basics",
//       child: Column(
//         children: [
//           _buildInputField(
//             controller: _ageController,
//             errorKey: 'age',
//             label: "Age",
//             icon: Icons.calendar_today,
//             unit: "Years",
//           ),
//           const SizedBox(height: 15),
//           _buildSectionTitle("Gender"),
//           Row(
//             children: [
//               _buildGenderCard("Male", Icons.male),
//               const SizedBox(width: 15),
//               _buildGenderCard("Female", Icons.female),
//             ],
//           ),
//           const SizedBox(height: 15),
//           _buildInputField(
//             controller: _heightController,
//             errorKey: 'height',
//             label: "Height",
//             icon: Icons.height,
//             unit: "cm",
//           ),
//           const SizedBox(height: 15),
//           _buildInputField(
//             controller: _weightController,
//             errorKey: 'weight',
//             label: "Current Weight",
//             icon: Icons.monitor_weight,
//             unit: "kg",
//           ),
//           const SizedBox(height: 15),
//           _buildInputField(
//             controller: _targetWeightController,
//             errorKey: 'targetWeight',
//             label: "Target Weight",
//             icon: Icons.track_changes,
//             unit: "kg",
//           ),
//         ],
//       ),
//     );
//   }

//   // --- Step 2: Fitness Goals & Level ---
//   Widget _buildStepTwo() {
//     return _pageWrapper(
//       title: "Fitness Profile",
//       subtitle: "Customize your training experience",
//       child: Column(
//         children: [
//           _buildDropdownField(
//             errorKey: 'activityLevel',
//             label: "Activity Level",
//             value: _selectedActivity,
//             items: ["sedentary", "light", "moderate", "active", "very active"],
//             onChanged: (v) => setState(() => _selectedActivity = v),
//           ),
//           const SizedBox(height: 15),
//           _buildDropdownField(
//             errorKey: 'fitnessGoal',
//             label: "Fitness Goal",
//             value: _selectedGoal,
//             items: ["lose weight", "bodybuilding", "powerlifting", "athletics"],
//             onChanged: (v) => setState(() => _selectedGoal = v),
//           ),
//           const SizedBox(height: 15),
//           _buildDropdownField(
//             errorKey: 'experienceLevel',
//             label: "Experience Level",
//             value: _selectedExp,
//             items: ["beginner", "intermediate", "advanced"],
//             onChanged: (v) => setState(() => _selectedExp = v),
//           ),
//           const SizedBox(height: 15),
//           _buildDropdownField(
//             errorKey: 'equipment',
//             label: "Equipment",
//             value: _selectedEquipment,
//             items: ["full gym", "at home", "garage gym"],
//             onChanged: (v) => setState(() => _selectedEquipment = v),
//           ),
//           const SizedBox(height: 15),

//           // // الحقل الجديد الخاص بأيام التدريب (Duration Days)
//           // _buildInputField(
//           //   controller: _durationDaysController,
//           //   errorKey: 'durationDays',
//           //   label: "Duration Days",
//           //   icon: Icons.av_timer,
//           //   unit: "Days/Week",
//           // ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   // --- UI Helpers ---

//   Widget _buildProgressHeader() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(
//         2,
//         (index) => Container(
//           margin: const EdgeInsets.symmetric(horizontal: 5),
//           height: 6,
//           width: 60,
//           decoration: BoxDecoration(
//             color: _currentPage >= index ? primaryGreen : Colors.grey[200],
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _pageWrapper({
//     required String title,
//     required String subtitle,
//     required Widget child,
//   }) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),
//           Text(
//             title,
//             style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//           ),
//           Text(subtitle, style: TextStyle(color: Colors.grey[600])),
//           const SizedBox(height: 25),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _buildGenderCard(String label, IconData icon) {
//     bool isSelected = _selectedGender == label;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => _selectedGender = label),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 15),
//           decoration: BoxDecoration(
//             color: isSelected ? primaryGreen : cardBg,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isSelected ? primaryGreen : Colors.grey.shade300,
//             ),
//           ),
//           child: Column(
//             children: [
//               Icon(icon, color: isSelected ? Colors.white : Colors.grey),
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: isSelected ? Colors.white : Colors.black,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInputField({
//     required TextEditingController controller,
//     required String errorKey,
//     required String label,
//     required IconData icon,
//     required String unit,
//   }) {
//     bool hasError = _errors[errorKey] != null;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//             ),
//             if (hasError)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 2),
//                 child: Text(
//                   _errors[errorKey]!,
//                   style: const TextStyle(
//                     color: Colors.redAccent,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 6),
//         TextFormField(
//           controller: controller,
//           keyboardType: TextInputType.number,
//           decoration: InputDecoration(
//             prefixIcon: Icon(
//               icon,
//               color: hasError ? Colors.redAccent : primaryGreen,
//             ),
//             suffixText: unit,
//             filled: true,
//             fillColor: cardBg,
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: hasError ? Colors.redAccent : primaryGreen,
//                 width: 1.5,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: hasError ? Colors.redAccent : Colors.transparent,
//                 width: 1,
//               ),
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdownField({
//     required String errorKey,
//     required String label,
//     required String? value,
//     required List<String> items,
//     required Function(String?) onChanged,
//   }) {
//     bool hasError = _errors[errorKey] != null;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             _buildSectionTitle(label),
//             if (hasError)
//               Text(
//                 _errors[errorKey]!,
//                 style: const TextStyle(
//                   color: Colors.redAccent,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//           ],
//         ),
//         DropdownButtonFormField<String>(
//           value: value,
//           hint: const Text("Select option"),
//           items: items
//               .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//               .toList(),
//           onChanged: onChanged,
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: cardBg,
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: hasError ? Colors.redAccent : primaryGreen,
//                 width: 1.5,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: hasError ? Colors.redAccent : Colors.transparent,
//                 width: 1,
//               ),
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4, top: 4),
//       child: Text(
//         title,
//         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Row(
//         children: [
//           if (_currentPage > 0)
//             Expanded(
//               child: OutlinedButton(
//                 onPressed: _isLoading ? null : _previousPage,
//                 style: OutlinedButton.styleFrom(
//                   minimumSize: const Size(0, 55),
//                   side: BorderSide(color: primaryGreen),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Text(
//                   "BACK",
//                   style: TextStyle(
//                     color: primaryGreen,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           if (_currentPage > 0) const SizedBox(width: 15),
//           Expanded(
//             flex: 2,
//             child: ElevatedButton(
//               onPressed: _isLoading ? null : _nextPage,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryGreen,
//                 minimumSize: const Size(0, 55),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: Text(
//                 _currentPage == 1 ? "CREATE PROFILE" : "NEXT",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
