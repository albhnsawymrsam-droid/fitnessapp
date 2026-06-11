import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String age;
  final String height;
  final String weight;
  final String targetWeight;
  final String gender;
  final String activityLevel;
  final String fitnessGoal;
  final String experienceLevel;
  final String equipment;
  final dynamic
      userProfile; // إضافة المتغير ده عشان يحل مشكلة widget.userProfile

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.age,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.gender,
    required this.activityLevel,
    required this.fitnessGoal,
    required this.experienceLevel,
    required this.equipment,
    this.userProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color cardBg = const Color(0xFFF9F9F9);
  bool _isEditing = false;
  bool _isLoading = false;
  int? _profileId;

  // استدعاء الـ Repository للربط النظيف
  final ProfileRepository _profileRepository = ProfileRepository();
  final AuthRepository _authRepository = AuthRepository();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;

  String? _selectedGender;
  String? _selectedActivity;
  String? _selectedGoal;
  String? _selectedExp;
  String? _selectedEquipment;

  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
    _fetchProfileData(); // جلب البيانات فور فتح الشاشة
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.userName);
    _ageController = TextEditingController(text: widget.age);
    _heightController = TextEditingController(text: widget.height);
    _weightController = TextEditingController(text: widget.weight);
    _targetWeightController = TextEditingController(text: widget.targetWeight);

    _selectedGender = _getMatchingOption(widget.gender, ["Male", "Female"]);
    _selectedActivity = _getMatchingOption(widget.activityLevel, [
      "sedentary",
      "light",
      "moderate",
      "active",
      "very active",
    ]);
    _selectedGoal = _getMatchingOption(widget.fitnessGoal, [
      "lose weight",
      "bodybuilding",
      "powerlifting",
      "athletics",
    ]);
    _selectedExp = _getMatchingOption(widget.experienceLevel, [
      "beginner",
      "intermediate",
      "advanced",
    ]);
    _selectedEquipment = _getMatchingOption(widget.equipment, [
      "full gym",
      "at home",
      "garage gym",
    ]);
  }

  // دالة الربط النظيفة باستخدام الـ Repository
  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = await _profileRepository.getProfileData();

      if (userProfile != null && mounted) {
        setState(() {
          _profileId = userProfile.profileId;
          _nameController.text = userProfile.fullName;
          _ageController.text = userProfile.age.toString();
          _heightController.text = userProfile.height.toString();
          _weightController.text = userProfile.currentWeight.toString();
          _targetWeightController.text = userProfile.targetWeight.toString();

          _selectedGender =
              _getMatchingOption(userProfile.gender, ["Male", "Female"]);
          _selectedActivity = _getMatchingOption(userProfile.activeLevel,
              ["sedentary", "light", "moderate", "active", "very active"]);
          _selectedGoal = _getMatchingOption(userProfile.fitnessGoal,
              ["lose weight", "bodybuilding", "powerlifting", "athletics"]);
          _selectedExp = _getMatchingOption(userProfile.experienceLevel,
              ["beginner", "intermediate", "advanced"]);
          _selectedEquipment = _getMatchingOption(
              userProfile.equipment, ["full gym", "at home", "garage gym"]);
        });
      }
    } catch (e) {
      debugPrint("UI Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // String? _getMatchingOption(String value, List<String> options) {
  //   if (value.isEmpty) return null;
  //   final lowercaseOptions = options.map((e) => e.toLowerCase()).toList();
  //   final index = lowercaseOptions.indexOf(value.toLowerCase().trim());
  //   return index != -1 ? options[index] : null;
  // }
  String? _getMatchingOption(String value, List<String> options) {
    if (value.isEmpty) return null;

    // 1. بنشيل الشرطة السفلية ونحولها لمسافة، ونصغر الحروف عشان تطابق اللي عندنا
    String cleanedValue = value.replaceAll('_', ' ').toLowerCase().trim();

    // 2. بندور عليها في الخيارات بتاعتنا
    final index = options.indexWhere((e) => e.toLowerCase() == cleanedValue);

    return index != -1 ? options[index] : null;
  }

  bool _validateFields() {
    bool isValid = true;
    setState(() {
      _errors.clear();

      if (_nameController.text.trim().isEmpty) {
        _errors['name'] = "Name cannot be empty";
        isValid = false;
      }

      final age = int.tryParse(_ageController.text);
      if (age == null) {
        _errors['age'] = "Please enter a valid age";
        isValid = false;
      } else if (age < 12 || age > 90) {
        _errors['age'] = "Age must be between 12 and 90 years";
        isValid = false;
      }

      final height = double.tryParse(_heightController.text);
      if (height == null) {
        _errors['height'] = "Please enter your height";
        isValid = false;
      } else if (height < 100 || height > 250) {
        _errors['height'] = "Height must be between 100 and 250 cm";
        isValid = false;
      }

      final weight = double.tryParse(_weightController.text);
      if (weight == null) {
        _errors['weight'] = "Please enter your weight";
        isValid = false;
      } else if (weight < 30 || weight > 250) {
        _errors['weight'] = "Weight must be between 30 and 250 kg";
        isValid = false;
      }

      final targetW = double.tryParse(_targetWeightController.text);
      if (targetW == null) {
        _errors['targetWeight'] = "Please enter target weight";
        isValid = false;
      } else if (targetW < 30 || targetW > 250) {
        _errors['targetWeight'] = "Target must be between 30 and 250 kg";
        isValid = false;
      }

      if (_selectedGender == null) _errors['gender'] = "Select gender";
      if (_selectedActivity == null)
        _errors['activityLevel'] = "Select activity level";
      if (_selectedGoal == null) _errors['fitnessGoal'] = "Select fitness goal";
      if (_selectedExp == null)
        _errors['experienceLevel'] = "Select experience";
      if (_selectedEquipment == null) _errors['equipment'] = "Select equipment";

      if (_selectedGender == null ||
          _selectedActivity == null ||
          _selectedGoal == null ||
          _selectedExp == null ||
          _selectedEquipment == null) {
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _updateProfile() async {
    if (!_validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fix the errors above first"),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // استخدمنا tryParse للتحويل الآمن عشان الأبلكيشن ميهنجش
      final updatedProfile = await _profileRepository.updateProfile(
        profileId: _profileId ?? widget.userProfile?.profileId ?? 0,
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        height: int.tryParse(_heightController.text.trim()) ?? 0,
        currentWeight: int.tryParse(_weightController.text.trim()) ?? 0,
        targetWeight: int.tryParse(_targetWeightController.text.trim()) ?? 0,
        gender: _selectedGender?.toLowerCase() ?? 'male',
        activeLevel:
            _selectedActivity?.toLowerCase().replaceAll(' ', '_') ?? 'light',
        fitnessGoal:
            _selectedGoal?.toLowerCase().replaceAll(' ', '_') ?? 'lose_weight',
        experienceLevel:
            _selectedExp?.toLowerCase().replaceAll(' ', '_') ?? 'beginner',
        equipment:
            _selectedEquipment?.toLowerCase().replaceAll(' ', '_') ?? 'at_home',
      );

      if (updatedProfile != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Profile updated successfully."),
            backgroundColor: Colors.green));
        if (mounted) {
          setState(() {
            _profileId = updatedProfile.profileId;
            _nameController.text = updatedProfile.fullName;
            _ageController.text = updatedProfile.age.toString();
            _heightController.text = updatedProfile.height.toString();
            _weightController.text = updatedProfile.currentWeight.toString();
            _targetWeightController.text =
                updatedProfile.targetWeight.toString();
            _selectedGender =
                _getMatchingOption(updatedProfile.gender, ["Male", "Female"]);
            _selectedActivity = _getMatchingOption(updatedProfile.activeLevel,
                ["sedentary", "light", "moderate", "active", "very active"]);
            _selectedGoal = _getMatchingOption(updatedProfile.fitnessGoal,
                ["lose weight", "bodybuilding", "powerlifting", "athletics"]);
            _selectedExp = _getMatchingOption(updatedProfile.experienceLevel,
                ["beginner", "intermediate", "advanced"]);
            _selectedEquipment = _getMatchingOption(updatedProfile.equipment,
                ["full gym", "at home", "garage gym"]);
            _isEditing = false;
          });
        }
      } else {
        throw Exception("Server returned error");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double heightValue = double.tryParse(_heightController.text) ?? 170;
    double weightValue = double.tryParse(_weightController.text) ?? 70;

    double hMetre = heightValue / 100;
    double bmi = (hMetre > 0) ? (weightValue / (hMetre * hMetre)) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Fitness Identity',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check_circle : Icons.edit,
              color: primaryGreen,
              size: 28,
            ),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildEnhancedProfileCard(),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      _buildSmallMetricCard(
                        "BMI",
                        (bmi.isNaN || bmi.isInfinite || bmi == 0.0)
                            ? "0.0"
                            : bmi.toStringAsFixed(1),
                        Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _buildSmallMetricCard(
                        "Target",
                        "${_targetWeightController.text.isEmpty ? '0' : _targetWeightController.text} kg",
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildInfoGroup("Account & Body Metrics", [
                    _editableInfoTile(
                        Icons.person, "Full Name", _nameController, 'name',
                        isNumber: false),
                    _editableSelectionTile(
                        Icons.wc,
                        "Gender",
                        _selectedGender,
                        ["Male", "Female"],
                        'gender',
                        (val) => setState(() => _selectedGender = val)),
                    _editableInfoTile(
                        Icons.cake, "Age (Years)", _ageController, 'age'),
                    _editableInfoTile(Icons.height, "Height (cm)",
                        _heightController, 'height'),
                    _editableInfoTile(Icons.monitor_weight,
                        "Current Weight (kg)", _weightController, 'weight'),
                    _editableInfoTile(Icons.track_changes, "Target Weight (kg)",
                        _targetWeightController, 'targetWeight'),
                  ]),
                  const SizedBox(height: 20),
                  _buildInfoGroup("Training & Nutrition Profile", [
                    _editableSelectionTile(
                        Icons.bolt,
                        "Activity Level",
                        _selectedActivity,
                        [
                          "sedentary",
                          "light",
                          "moderate",
                          "active",
                          "very active"
                        ],
                        'activityLevel',
                        (val) => setState(() => _selectedActivity = val)),
                    _editableSelectionTile(
                        Icons.emoji_events,
                        "Fitness Goal",
                        _selectedGoal,
                        [
                          "lose weight",
                          "bodybuilding",
                          "powerlifting",
                          "athletics"
                        ],
                        'fitnessGoal',
                        (val) => setState(() => _selectedGoal = val)),
                    _editableSelectionTile(
                        Icons.star,
                        "Experience Level",
                        _selectedExp,
                        ["beginner", "intermediate", "advanced"],
                        'experienceLevel',
                        (val) => setState(() => _selectedExp = val)),
                    _editableSelectionTile(
                        Icons.fitness_center,
                        "Available Equipment",
                        _selectedEquipment,
                        ["full gym", "at home", "garage gym"],
                        'equipment',
                        (val) => setState(() => _selectedEquipment = val)),
                  ]),
                  const SizedBox(height: 35),
                  _buildLogoutButton(context),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildEnhancedProfileCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, const Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text[0].toUpperCase()
                  : "U",
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedGender ?? "Not Specified",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableInfoTile(
    IconData icon,
    String title,
    TextEditingController controller,
    String errorKey, {
    bool isNumber = true,
  }) {
    bool hasError = _errors[errorKey] != null;
    return Column(
      children: [
        ListTile(
          leading: _tileIcon(icon),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (_isEditing && hasError)
                Text(
                  _errors[errorKey]!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          subtitle: _isEditing
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextField(
                    controller: controller,
                    keyboardType:
                        isNumber ? TextInputType.number : TextInputType.text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (text) {
                      if (errorKey == 'weight' ||
                          errorKey == 'height' ||
                          errorKey == 'targetWeight') {
                        setState(() {});
                      }
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: hasError ? Colors.redAccent : primaryGreen,
                          width: 2,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: hasError
                              ? Colors.redAccent
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const Divider(height: 1, indent: 60, endIndent: 15),
      ],
    );
  }

  Widget _editableSelectionTile(
    IconData icon,
    String title,
    String? currentValue,
    List<String> options,
    String errorKey,
    Function(String?) onChanged,
  ) {
    bool hasError = _errors[errorKey] != null;
    String? safeValue = options.contains(currentValue) ? currentValue : null;

    return Column(
      children: [
        ListTile(
          leading: _tileIcon(icon),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (_isEditing && hasError)
                Text(
                  _errors[errorKey]!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          subtitle: _isEditing
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: DropdownButtonFormField<String>(
                    value: safeValue,
                    hint: const Text(
                      "Select option",
                      style: TextStyle(fontSize: 14),
                    ),
                    items: options.map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(
                          val,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: hasError ? Colors.redAccent : primaryGreen,
                          width: 2,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: hasError
                              ? Colors.redAccent
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                )
              : Text(
                  currentValue ?? "Not Selected",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const Divider(height: 1, indent: 60, endIndent: 15),
      ],
    );
  }

  Widget _tileIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: primaryGreen, size: 20),
    );
  }

  Widget _buildSmallMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGroup(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout),
        label: const Text(
          "Log Out",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEE),
          foregroundColor: Colors.red,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _authRepository.logout();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/intro', (route) => false);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// import '../repositories/auth_repository.dart';
// import '../repositories/profile_repository.dart';
// import '../services/api_service.dart';

// class ProfileScreen extends StatefulWidget {
//   final String userName;
//   final String userEmail;
//   final String age;
//   final String height;
//   final String weight;
//   final String targetWeight;
//   final String gender;
//   final String activityLevel;
//   final String fitnessGoal;
//   final String experienceLevel;
//   final String equipment;
//   final String durationDays;

//   const ProfileScreen({
//     super.key,
//     required this.userName,
//     required this.userEmail,
//     required this.age,
//     required this.height,
//     required this.weight,
//     required this.targetWeight,
//     required this.gender,
//     required this.activityLevel,
//     required this.fitnessGoal,
//     required this.experienceLevel,
//     required this.equipment,
//     required this.durationDays,
//   });

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final Color primaryGreen = const Color(0xFF2E8B57);
//   final Color cardBg = const Color(0xFFF9F9F9);
//   bool _isEditing = false;
//   bool _isLoading = false;
//   final ProfileRepository _profileRepository = ProfileRepository();
//   final AuthRepository _authRepository = AuthRepository();

//   // Controllers للبيانات النصية
//   late TextEditingController _nameController;
//   late TextEditingController _ageController;
//   late TextEditingController _heightController;
//   late TextEditingController _weightController;
//   late TextEditingController _targetWeightController;
//   late TextEditingController _durationDaysController;

//   // متغيرات للاختيارات (Dropdowns)
//   String? _selectedGender;
//   String? _selectedActivity;
//   String? _selectedGoal;
//   String? _selectedExp;
//   String? _selectedEquipment;

//   // تخزين رسائل الخطأ وعرضها فوق كل حقل بشكل مخصص أثناء التعديل
//   final Map<String, String?> _errors = {};

//   @override
//   void initState() {
//     super.initState();
//     _initControllers();
//   }

//   void _initControllers() {
//     _nameController = TextEditingController(text: widget.userName);
//     _ageController = TextEditingController(text: widget.age);
//     _heightController = TextEditingController(text: widget.height);
//     _weightController = TextEditingController(text: widget.weight);
//     _targetWeightController = TextEditingController(text: widget.targetWeight);
//     _durationDaysController = TextEditingController(text: widget.durationDays);

//     // تحويل الكلمات لتتطابق تماماً مع الخيارات الموجودة بالأسفل (toLowerCase) لتفادي أخطاء الـ Dropdown
//     _selectedGender = _getMatchingOption(widget.gender, ["Male", "Female"]);
//     _selectedActivity = _getMatchingOption(widget.activityLevel, [
//       "sedentary",
//       "light",
//       "moderate",
//       "active",
//       "very active",
//     ]);
//     _selectedGoal = _getMatchingOption(widget.fitnessGoal, [
//       "lose weight",
//       "bodybuilding",
//       "powerlifting",
//       "athletics",
//     ]);
//     _selectedExp = _getMatchingOption(widget.experienceLevel, [
//       "beginner",
//       "intermediate",
//       "advanced",
//     ]);
//     _selectedEquipment = _getMatchingOption(widget.equipment, [
//       "full gym",
//       "at home",
//       "garage gym",
//     ]);
//   }

//   // دالة مساعدة لضمان مطابقة النص القادم مع عناصر الـ Dropdown لتجنب إيرور السطر 579
//   String? _getMatchingOption(String value, List<String> options) {
//     if (value.isEmpty) return null;
//     final lowercaseOptions = options.map((e) => e.toLowerCase()).toList();
//     final index = lowercaseOptions.indexOf(value.toLowerCase().trim());
//     return index != -1 ? options[index] : null;
//   }

//   // ميثود الفحص والتحقق من المنطق (Validation) قبل الحفظ
//   bool _validateFields() {
//     bool isValid = true;
//     setState(() {
//       _errors.clear();

//       // فحص الاسم
//       if (_nameController.text.trim().isEmpty) {
//         _errors['name'] = "Name cannot be empty";
//         isValid = false;
//       }

//       // فحص السن
//       final age = int.tryParse(_ageController.text);
//       if (age == null) {
//         _errors['age'] = "Please enter a valid age";
//         isValid = false;
//       } else if (age < 12 || age > 90) {
//         _errors['age'] = "Age must be between 12 and 90 years";
//         isValid = false;
//       }

//       // فحص الطول
//       final height = double.tryParse(_heightController.text);
//       if (height == null) {
//         _errors['height'] = "Please enter your height";
//         isValid = false;
//       } else if (height < 100 || height > 250) {
//         _errors['height'] = "Height must be between 100 and 250 cm";
//         isValid = false;
//       }

//       // فحص الوزن الحالي
//       final weight = double.tryParse(_weightController.text);
//       if (weight == null) {
//         _errors['weight'] = "Please enter your weight";
//         isValid = false;
//       } else if (weight < 30 || weight > 250) {
//         _errors['weight'] = "Weight must be between 30 and 250 kg";
//         isValid = false;
//       }

//       // فحص الوزن المستهدف
//       final targetW = double.tryParse(_targetWeightController.text);
//       if (targetW == null) {
//         _errors['targetWeight'] = "Please enter target weight";
//         isValid = false;
//       } else if (targetW < 30 || targetW > 250) {
//         _errors['targetWeight'] = "Target must be between 30 and 250 kg";
//         isValid = false;
//       }

//       // فحص أيام التدريب
//       final days = int.tryParse(_durationDaysController.text);
//       if (days == null) {
//         _errors['durationDays'] = "Please enter training days";
//         isValid = false;
//       } else if (days < 1 || days > 7) {
//         _errors['durationDays'] = "Days must be between 1 and 7 days";
//         isValid = false;
//       }

//       // فحص القوائم المنسدلة
//       if (_selectedGender == null) _errors['gender'] = "Select gender";
//       if (_selectedActivity == null)
//         _errors['activityLevel'] = "Select activity level";
//       if (_selectedGoal == null) _errors['fitnessGoal'] = "Select fitness goal";
//       if (_selectedExp == null)
//         _errors['experienceLevel'] = "Select experience";
//       if (_selectedEquipment == null) _errors['equipment'] = "Select equipment";

//       if (_selectedGender == null ||
//           _selectedActivity == null ||
//           _selectedGoal == null ||
//           _selectedExp == null ||
//           _selectedEquipment == null) {
//         isValid = false;
//       }
//     });
//     return isValid;
//   }

//   Future<void> _updateProfile() async {
//     if (!_validateFields()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Please fix the errors above first"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);
//     try {
//       final profile = await _profileRepository.addProfile(
//         age: int.parse(_ageController.text.trim()),
//         gender: _selectedGender?.toLowerCase() ?? 'male',
//         height: int.parse(_heightController.text.trim()),
//         currentWeight: int.parse(_weightController.text.trim()),
//         targetWeight: int.parse(_targetWeightController.text.trim()),
//         activeLevel: _selectedActivity?.toLowerCase() ?? 'light',
//         fitnessGoal: _selectedGoal?.toLowerCase() ?? 'lose weight',
//         experienceLevel: _selectedExp?.toLowerCase() ?? 'beginner',
//         equipment: _selectedEquipment?.toLowerCase() ?? 'at home',
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               "Profile added successfully. Profile ID: ${profile['profile_id'] ?? 'N/A'}"),
//           backgroundColor: Colors.green,
//         ),
//       );
//       setState(() => _isEditing = false);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error adding profile: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // حل مشكلة السطر 202: حساب آمن للـ BMI لمنع الـ NaN والـ Null Errors أثناء إدخال المستخدم للبيانات
//     double heightValue = double.tryParse(_heightController.text) ?? 170;
//     double weightValue = double.tryParse(_weightController.text) ?? 70;

//     double hMetre = heightValue / 100;
//     double bmi = (hMetre > 0) ? (weightValue / (hMetre * hMetre)) : 0.0;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         title: const Text(
//           'My Fitness Identity',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               _isEditing ? Icons.check_circle : Icons.edit,
//               color: primaryGreen,
//               size: 28,
//             ),
//             onPressed: () {
//               if (_isEditing) {
//                 _updateProfile();
//               } else {
//                 setState(() => _isEditing = true);
//               }
//             },
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator(color: primaryGreen))
//           : SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),
//                   _buildEnhancedProfileCard(),
//                   const SizedBox(height: 25),
//                   Row(
//                     children: [
//                       _buildSmallMetricCard(
//                         "BMI",
//                         (bmi.isNaN || bmi.isInfinite || bmi == 0.0)
//                             ? "0.0"
//                             : bmi.toStringAsFixed(1),
//                         Colors.blue,
//                       ),
//                       const SizedBox(width: 10),
//                       _buildSmallMetricCard(
//                         "Target",
//                         "${_targetWeightController.text.isEmpty ? '0' : _targetWeightController.text} kg",
//                         Colors.orange,
//                       ),
//                       const SizedBox(width: 10),
//                       _buildSmallMetricCard(
//                         "Days/W",
//                         _durationDaysController.text.isEmpty
//                             ? '0'
//                             : _durationDaysController.text,
//                         Colors.purple,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 25),

//                   // --- المجموعة الأولى: البيانات الأساسية للـ Account ---
//                   _buildInfoGroup("Account & Body Metrics", [
//                     _editableInfoTile(
//                       Icons.person,
//                       "Full Name",
//                       _nameController,
//                       'name',
//                       isNumber: false,
//                     ),
//                     _editableSelectionTile(
//                       Icons.wc,
//                       "Gender",
//                       _selectedGender,
//                       ["Male", "Female"],
//                       'gender',
//                       (val) => setState(() => _selectedGender = val),
//                     ),
//                     _editableInfoTile(
//                       Icons.cake,
//                       "Age (Years)",
//                       _ageController,
//                       'age',
//                     ),
//                     _editableInfoTile(
//                       Icons.height,
//                       "Height (cm)",
//                       _heightController,
//                       'height',
//                     ),
//                     _editableInfoTile(
//                       Icons.monitor_weight,
//                       "Current Weight (kg)",
//                       _weightController,
//                       'weight',
//                     ),
//                     _editableInfoTile(
//                       Icons.track_changes,
//                       "Target Weight (kg)",
//                       _targetWeightController,
//                       'targetWeight',
//                     ),
//                   ]),

//                   const SizedBox(height: 20),

//                   // --- المجموعة الثانية: البيانات الرياضية ونظام التدريب ---
//                   _buildInfoGroup("Training & Nutrition Profile", [
//                     _editableSelectionTile(
//                       Icons.bolt,
//                       "Activity Level",
//                       _selectedActivity,
//                       [
//                         "sedentary",
//                         "light",
//                         "moderate",
//                         "active",
//                         "very active",
//                       ],
//                       'activityLevel',
//                       (val) => setState(() => _selectedActivity = val),
//                     ),
//                     _editableSelectionTile(
//                       Icons.emoji_events,
//                       "Fitness Goal",
//                       _selectedGoal,
//                       [
//                         "lose weight",
//                         "bodybuilding",
//                         "powerlifting",
//                         "athletics",
//                       ],
//                       'fitnessGoal',
//                       (val) => setState(() => _selectedGoal = val),
//                     ),
//                     _editableSelectionTile(
//                       Icons.star,
//                       "Experience Level",
//                       _selectedExp,
//                       ["beginner", "intermediate", "advanced"],
//                       'experienceLevel',
//                       (val) => setState(() => _selectedExp = val),
//                     ),
//                     _editableSelectionTile(
//                       Icons.fitness_center,
//                       "Available Equipment",
//                       _selectedEquipment,
//                       ["full gym", "at home", "garage gym"],
//                       'equipment',
//                       (val) => setState(() => _selectedEquipment = val),
//                     ),
//                     _editableInfoTile(
//                       Icons.calendar_month,
//                       "Training Days / Week",
//                       _durationDaysController,
//                       'durationDays',
//                     ),
//                   ]),

//                   const SizedBox(height: 35),
//                   _buildLogoutButton(context),
//                   const SizedBox(height: 50),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildEnhancedProfileCard() {
//     return Container(
//       padding: const EdgeInsets.all(25),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [primaryGreen, const Color(0xFF1B5E20)],
//         ),
//         borderRadius: BorderRadius.circular(25),
//         boxShadow: [
//           BoxShadow(
//             color: primaryGreen.withOpacity(0.3),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 45,
//             backgroundColor: Colors.white.withOpacity(0.2),
//             child: Text(
//               _nameController.text.isNotEmpty
//                   ? _nameController.text[0].toUpperCase()
//                   : "U",
//               style: const TextStyle(
//                 fontSize: 40,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           const SizedBox(width: 20),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _nameController.text,
//                   style: const TextStyle(
//                     fontSize: 22,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   widget.userEmail,
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.8),
//                     fontSize: 14,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     _selectedGender ?? "Not Specified",
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _editableInfoTile(
//     IconData icon,
//     String title,
//     TextEditingController controller,
//     String errorKey, {
//     bool isNumber = true,
//   }) {
//     bool hasError = _errors[errorKey] != null;
//     return Column(
//       children: [
//         ListTile(
//           leading: _tileIcon(icon),
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//               if (_isEditing && hasError)
//                 Text(
//                   _errors[errorKey]!,
//                   style: const TextStyle(
//                     color: Colors.redAccent,
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//             ],
//           ),
//           subtitle: _isEditing
//               ? Padding(
//                   padding: const EdgeInsets.only(top: 4),
//                   child: TextField(
//                     controller: controller,
//                     keyboardType:
//                         isNumber ? TextInputType.number : TextInputType.text,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     onChanged: (text) {
//                       // تحديث الـ UI فوراً لرؤية حساب الـ BMI يتغير ديناميكياً أثناء الكتابة
//                       if (errorKey == 'weight' ||
//                           errorKey == 'height' ||
//                           errorKey == 'targetWeight' ||
//                           errorKey == 'durationDays') {
//                         setState(() {});
//                       }
//                     },
//                     decoration: InputDecoration(
//                       isDense: true,
//                       contentPadding: const EdgeInsets.symmetric(vertical: 6),
//                       focusedBorder: UnderlineInputBorder(
//                         borderSide: BorderSide(
//                           color: hasError ? Colors.redAccent : primaryGreen,
//                           width: 2,
//                         ),
//                       ),
//                       enabledBorder: UnderlineInputBorder(
//                         borderSide: BorderSide(
//                           color: hasError
//                               ? Colors.redAccent
//                               : Colors.grey.shade400,
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//               : Text(
//                   controller.text,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//         ),
//         const Divider(height: 1, indent: 60, endIndent: 15),
//       ],
//     );
//   }

//   // تعديل الـ Dropdown ليعمل بمرونة تامة مع الـ Validation والـ Null Safety
//   Widget _editableSelectionTile(
//     IconData icon,
//     String title,
//     String? currentValue,
//     List<String> options,
//     String errorKey,
//     Function(String?) onChanged,
//   ) {
//     bool hasError = _errors[errorKey] != null;

//     // التأكد التام من أن القيمة الحالية موجودة داخل قائمة الاختيارات المتاحة
//     String? safeValue = options.contains(currentValue) ? currentValue : null;

//     return Column(
//       children: [
//         ListTile(
//           leading: _tileIcon(icon),
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//               if (_isEditing && hasError)
//                 Text(
//                   _errors[errorKey]!,
//                   style: const TextStyle(
//                     color: Colors.redAccent,
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//             ],
//           ),
//           subtitle: _isEditing
//               ? Padding(
//                   padding: const EdgeInsets.only(top: 4),
//                   child: DropdownButtonFormField<String>(
//                     value: safeValue,
//                     hint: const Text(
//                       "Select option",
//                       style: TextStyle(fontSize: 14),
//                     ),
//                     items: options.map((String val) {
//                       return DropdownMenuItem<String>(
//                         value: val,
//                         child: Text(
//                           val,
//                           style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                     onChanged: onChanged,
//                     decoration: InputDecoration(
//                       isDense: true,
//                       contentPadding: EdgeInsets.zero,
//                       focusedBorder: UnderlineInputBorder(
//                         borderSide: BorderSide(
//                           color: hasError ? Colors.redAccent : primaryGreen,
//                           width: 2,
//                         ),
//                       ),
//                       enabledBorder: UnderlineInputBorder(
//                         borderSide: BorderSide(
//                           color: hasError
//                               ? Colors.redAccent
//                               : Colors.grey.shade400,
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//               : Text(
//                   currentValue ?? "Not Selected",
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//         ),
//         const Divider(height: 1, indent: 60, endIndent: 15),
//       ],
//     );
//   }

//   Widget _tileIcon(IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: primaryGreen.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Icon(icon, color: primaryGreen, size: 20),
//     );
//   }

//   Widget _buildSmallMetricCard(String title, String value, Color color) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 15),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Text(
//               title,
//               style: const TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//             const SizedBox(height: 5),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoGroup(String title, List<Widget> tiles) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 5, bottom: 10),
//           child: Text(
//             title,
//             style: TextStyle(
//               color: primaryGreen,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//         ),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.grey.withOpacity(0.05),
//                 blurRadius: 15,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: Column(children: tiles),
//         ),
//       ],
//     );
//   }

//   Widget _buildLogoutButton(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       height: 55,
//       child: ElevatedButton.icon(
//         onPressed: () => _showLogoutDialog(context),
//         icon: const Icon(Icons.logout),
//         label: const Text(
//           "Log Out",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFFFFEBEE),
//           foregroundColor: Colors.red,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _sendVerificationCode(String email) async {
//     try {
//       await _authRepository.forgetPassword(email: email);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Verification code sent to your email'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to send verification code: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _showLogoutDialog(BuildContext context) {
//     final emailCtrl = TextEditingController(text: widget.userEmail);
//     final codeCtrl = TextEditingController();
//     final passwordCtrl = TextEditingController();
//     final confirmPasswordCtrl = TextEditingController();

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Logout & Reset Password'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text(
//                 'A verification code will be sent to your email. Use it to complete logout and reset password.',
//                 style: TextStyle(fontSize: 14),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: emailCtrl,
//                 enabled: false,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: codeCtrl,
//                 decoration: const InputDecoration(
//                   labelText: 'Verification Code',
//                   hintText: 'Enter code from email',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: passwordCtrl,
//                 obscureText: true,
//                 decoration: const InputDecoration(
//                   labelText: 'New Password',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: confirmPasswordCtrl,
//                 obscureText: true,
//                 decoration: const InputDecoration(
//                   labelText: 'Confirm Password',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => _sendVerificationCode(emailCtrl.text.trim()),
//             child: const Text('Send Code'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (codeCtrl.text.isEmpty ||
//                   passwordCtrl.text.isEmpty ||
//                   confirmPasswordCtrl.text.isEmpty) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Please fill all fields'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//                 return;
//               }

//               if (passwordCtrl.text != confirmPasswordCtrl.text) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Passwords do not match'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//                 return;
//               }

//               setState(() => _isLoading = true);
//               try {
//                 await _authRepository.resetPassword(
//                   email: emailCtrl.text.trim(),
//                   code: codeCtrl.text.trim(),
//                   newPassword: passwordCtrl.text.trim(),
//                   confirmPassword: confirmPasswordCtrl.text.trim(),
//                 );

//                 if (!mounted) return;
//                 Navigator.pop(ctx);

//                 ApiService.instance.setAuthToken(null);

//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Password reset successfully'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );

//                 Navigator.of(context)
//                     .pushNamedAndRemoveUntil('/login', (route) => false);
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Logout failed: $e'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               } finally {
//                 setState(() => _isLoading = false);
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: primaryGreen,
//             ),
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );
//   }
// }
