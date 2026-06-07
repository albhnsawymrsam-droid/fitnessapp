import 'package:ai/screens/admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_screen.dart';
import '../models/meal_model.dart';
import '../models/workout_model.dart';
import '../repositories/plan_repository.dart';
import '../repositories/profile_repository.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  final String? age;
  final String? height;
  final String? weight;
  final String? gender;
  final String? targetWeight;
  final String? activityLevel;
  final String? fitnessGoal;
  final String? experienceLevel;
  final String? equipment;
  final String? durationDays;
  final bool isAdmin;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.targetWeight,
    this.activityLevel,
    this.fitnessGoal,
    this.experienceLevel,
    this.equipment,
    this.durationDays,
    this.isAdmin = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();

  // ==========================================
  // Theme Colors
  // ==========================================
  final Color bgColor = const Color(0xFFF4F6F9);
  final Color cardColor = Colors.white;
  final Color neonGreen = const Color(0xFF00C853);
  final Color accentOrange = const Color(0xFFFF6D00);
  final Color accentBlue = const Color(0xFF00B0FF);

  // ==========================================
  // Stats Variables
  // ==========================================
  double currentWeight = 70.0;
  double currentHeight = 170.0;
  int currentAge = 25;
  double targetWeightVal = 70.0;
  // startedWeight = الوزن اللي جه من الأونبوردينج (widget.weight) وبيتحفظ لو اتعدل البروفايل
  double startedWeight = 70.0;
  String currentFitnessGoal = 'lose weight';

  double calculatedBMI = 0.0;
  double calculatedBMR = 0.0;
  double targetCalories = 0.0;
  double weightToLose = 0.0;
  double activityMultiplier = 1.55;

  double currentDaySlider = 1.0;

  // ==========================================
  // API State Variables
  // ==========================================
  final PlanRepository _planRepo = PlanRepository();

  // وجبات
  List<Meal> todayMealsList = [];
  bool isLoadingMeals = true;
  bool isLoadingMealsByDay = false;
  double consumedCalories = 0.0;

  // تمارين
  WorkoutDay? todayWorkoutsData;
  bool isLoadingWorkouts = true;
  bool isLoadingWorkoutsByDay = false;
  double currentWorkoutDaySlider = 1.0;
  int completedExercisesCount = 0;

  // Generate / Cancel
  int _selectedPlanDays = 3;
  int _currentPlanDays = 30;
  bool _isGeneratingPlan = false;
  bool _isCancelling = false;

  // ==========================================
  // Init
  // ==========================================
  @override
  void initState() {
    super.initState();
    _currentPlanDays = _parsePositive(widget.durationDays, 30);
    _selectedPlanDays = _currentPlanDays;
    _parseAndCalculateStats();
    // جيب أحدث بيانات البروفايل من الـ API عشان نتأكد أن الوزن محدث
    _refreshProfileDataOnDashboardLoad();
    _fetchTodayMeals();
    _fetchTodayWorkouts();
  }

  void _parseAndCalculateStats() {
    startedWeight = double.tryParse(widget.weight ?? '70') ?? 70.0;
    currentWeight = startedWeight;
    currentHeight = double.tryParse(widget.height ?? '170') ?? 170.0;
    currentAge = int.tryParse(widget.age ?? '25') ?? 25;
    targetWeightVal = double.tryParse(widget.targetWeight ?? '70') ?? 70.0;
    currentFitnessGoal = widget.fitnessGoal ?? 'lose weight';

    _recalculate();
  }

  /// يُستدعى بعد كل تحديث للبروفايل عشان يعيد حساب كل المتغيرات
  void _recalculate() {
    double heightInMeters = currentHeight / 100;
    calculatedBMI = currentWeight / (heightInMeters * heightInMeters);

    bool isMale = (widget.gender?.toLowerCase() ?? 'male') == 'male';
    calculatedBMR = isMale
        ? (10 * currentWeight) + (6.25 * currentHeight) - (5 * currentAge) + 5
        : (10 * currentWeight) +
            (6.25 * currentHeight) -
            (5 * currentAge) -
            161;

    String actLevel = widget.activityLevel?.toLowerCase() ?? 'moderate';
    if (actLevel.contains('sedentary'))
      activityMultiplier = 1.2;
    else if (actLevel.contains('light'))
      activityMultiplier = 1.375;
    else if (actLevel.contains('very') || actLevel.contains('high'))
      activityMultiplier = 1.725;
    else
      activityMultiplier = 1.55;

    double tdee = calculatedBMR * activityMultiplier;
    String goal = widget.fitnessGoal?.toLowerCase() ?? 'lose weight';
    if (goal.contains('lose'))
      targetCalories = tdee - 500;
    else if (goal.contains('gain'))
      targetCalories = tdee + 500;
    else
      targetCalories = tdee;

    if (targetCalories < 1200) targetCalories = 1200;

    weightToLose = (currentWeight - targetWeightVal).abs();
  }

  // ==========================================
  // API Calls
  // ==========================================
  Future<void> _fetchTodayMeals() async {
    setState(() => isLoadingMeals = true);
    final response = await _planRepo.fetchTodayMeals();
    if (mounted) {
      setState(() {
        if (response != null) {
          todayMealsList = response.meals;
          consumedCalories = todayMealsList
              .where((m) => m.isDone)
              .fold(0.0, (sum, m) => sum + m.calories);
        }
        isLoadingMeals = false;
      });
    }
  }

  Future<void> _fetchMealsByDay(int day) async {
    setState(() => isLoadingMealsByDay = true);
    final response = await _planRepo.fetchCurrentMeals();
    if (mounted) {
      setState(() {
        if (response != null) {
          if (response.durationDays > 0) {
            _currentPlanDays = response.durationDays;
            currentDaySlider = currentDaySlider
                .clamp(1.0, _currentPlanDays.toDouble())
                .toDouble();
            currentWorkoutDaySlider = currentWorkoutDaySlider
                .clamp(1.0, _currentPlanDays.toDouble())
                .toDouble();
          }

          final selectedDayMeals = response.mealDays
              .where((mealDay) => mealDay.day == day)
              .expand((mealDay) => mealDay.meals)
              .toList();

          todayMealsList = selectedDayMeals;
          consumedCalories = todayMealsList
              .where((m) => m.isDone)
              .fold(0.0, (sum, m) => sum + m.calories);
        }
        isLoadingMealsByDay = false;
      });
    }
  }

  Future<void> _fetchTodayWorkouts() async {
    setState(() => isLoadingWorkouts = true);
    final response = await _planRepo.fetchTodayWorkouts();
    if (mounted) {
      setState(() {
        if (response != null && response.workouts.isNotEmpty) {
          if (response.durationDays > 0) {
            _currentPlanDays = response.durationDays;
            currentDaySlider = currentDaySlider
                .clamp(1.0, _currentPlanDays.toDouble())
                .toDouble();
            currentWorkoutDaySlider = currentWorkoutDaySlider
                .clamp(1.0, _currentPlanDays.toDouble())
                .toDouble();
          }

          todayWorkoutsData = response.workouts.firstWhere(
            (workoutDay) => workoutDay.day == currentWorkoutDaySlider.toInt(),
            orElse: () => response.workouts.first,
          );
          completedExercisesCount = todayWorkoutsData!.exercises
              .where((e) => e.status == 'DONE')
              .length;
        } else {
          todayWorkoutsData = null;
          completedExercisesCount = 0;
        }
        isLoadingWorkouts = false;
      });
    }
  }

  Future<void> _toggleMeal(int index, bool value) async {
    final meal = todayMealsList[index];
    final success = await _planRepo.toggleMeal(
      meal.mealTime,
      currentDaySlider.toInt(),
    );

    if (mounted && success) {
      setState(() {
        todayMealsList[index].isDone = value;
        consumedCalories = todayMealsList
            .where((m) => m.isDone)
            .fold(0.0, (sum, m) => sum + m.calories);
      });
    }
  }

  Future<void> _toggleExercise(int index) async {
    if (todayWorkoutsData == null) return;

    final ex = todayWorkoutsData!.exercises[index];
    final success = await _planRepo.toggleWorkout(
      ex.exerciseId,
      currentWorkoutDaySlider.toInt(),
    );

    if (!mounted || !success) return;

    setState(() {
      bool isCurrentlyDone = ex.status == 'DONE';
      todayWorkoutsData!.exercises[index] = Exercise(
        exerciseName: ex.exerciseName,
        exerciseId: ex.exerciseId,
        sets: ex.sets,
        reps: ex.reps,
        intensity: ex.intensity,
        status: isCurrentlyDone ? 'NOT_DONE' : 'DONE',
      );
      completedExercisesCount =
          todayWorkoutsData!.exercises.where((e) => e.status == 'DONE').length;
    });
  }

  int _parsePositive(String? value, int fallback) {
    final parsed = int.tryParse(value ?? '');
    return (parsed != null && parsed > 0) ? parsed : fallback;
  }

  Future<void> _generatePlan(int days) async {
    setState(() => _isGeneratingPlan = true);
    final snackBar = ScaffoldMessenger.of(context);
    snackBar.showSnackBar(
      SnackBar(
          content: const Text('Generating plan...'),
          backgroundColor: neonGreen),
    );
    try {
      final requestBody = {
        'fullname': widget.userName,
        'email': widget.userEmail,
        'age': _parsePositive(widget.age, 25),
        'height': _parsePositive(widget.height, 170),
        'weight': _parsePositive(widget.weight, 70),
        'gender': widget.gender ?? 'Male',
        'targetWeight': _parsePositive(widget.targetWeight, 70),
        'activityLevel': widget.activityLevel ?? 'light',
        'fitnessGoal': widget.fitnessGoal ?? 'lose weight',
        'experienceLevel': widget.experienceLevel ?? 'beginner',
        'equipment': widget.equipment ?? 'at home',
        'planDays': days,
        'durationDays': days,
      };
      await _planRepo.generatePlan(days, requestBody);
      if (mounted) {
        setState(() {
          _currentPlanDays = days;
          _selectedPlanDays = days;
          currentDaySlider =
              currentDaySlider.clamp(1.0, days.toDouble()).toDouble();
          currentWorkoutDaySlider =
              currentWorkoutDaySlider.clamp(1.0, days.toDouble()).toDouble();
        });
        snackBar.showSnackBar(
          SnackBar(
              content: const Text('Plan generated successfully!'),
              backgroundColor: neonGreen),
        );
        await _fetchTodayMeals();
        await _fetchTodayWorkouts();
      }
    } catch (e) {
      if (mounted) {
        snackBar.showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPlan = false);
    }
  }

  Future<void> _cancelPlan() async {
    setState(() => _isCancelling = true);
    final snackBar = ScaffoldMessenger.of(context);
    final success = await _planRepo.cancelPlan();
    if (mounted) {
      setState(() {
        _isCancelling = false;
        if (success) {
          todayMealsList.clear();
          todayWorkoutsData = null;
          consumedCalories = 0.0;
          completedExercisesCount = 0;
          snackBar.showSnackBar(
            const SnackBar(
                content: Text('Plan cancelled successfully!'),
                backgroundColor: Colors.green),
          );
        } else {
          snackBar.showSnackBar(
            const SnackBar(
                content: Text('Failed to cancel plan. Please try again.'),
                backgroundColor: Colors.red),
          );
        }
      });
    }
  }

  void _showPlanDaysDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: neonGreen),
            const SizedBox(width: 10),
            const Text('Choose Plan Length',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (index) {
            final days = index + 1;
            return RadioListTile<int>(
              title: Text('$days day${days > 1 ? 's' : ''}'),
              value: days,
              groupValue: _selectedPlanDays,
              activeColor: neonGreen,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPlanDays = value);
                  Navigator.of(context).pop();
                  _generatePlan(value);
                }
              },
            );
          }),
        ),
      ),
    );
  }

  void _confirmCancelPlan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Cancel Plan',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel your current plan? All your progress will be lost.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, Keep it',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelPlan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _onDayChanged(double val) {
    setState(() => currentDaySlider = val);
    _fetchMealsByDay(val.toInt());
  }

  Future<void> _fetchWorkoutsByDay(int day) async {
    setState(() => isLoadingWorkoutsByDay = true);
    final response = await _planRepo.fetchTodayWorkouts();
    if (mounted) {
      setState(() {
        if (response != null && response.workouts.isNotEmpty) {
          todayWorkoutsData = response.workouts.firstWhere(
            (workoutDay) => workoutDay.day == day,
            orElse: () => response.workouts.first,
          );
          completedExercisesCount = todayWorkoutsData!.exercises
              .where((e) => e.status == 'DONE')
              .length;
        } else {
          todayWorkoutsData = null;
          completedExercisesCount = 0;
        }
        isLoadingWorkoutsByDay = false;
      });
    }
  }

  void _onWorkoutDayChanged(double val) {
    setState(() => currentWorkoutDaySlider = val);
    _fetchWorkoutsByDay(val.toInt());
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeScreen(),
            _buildMealPlanScreen(),
            _buildWorkoutPlanScreen(),
            _buildStatsScreen(),
            _buildProgressScreen(),
            _buildAiExerciseScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ==========================================
  // 1. HOME SCREEN
  // ==========================================
  Widget _buildHomeScreen() {
    int totalExercises = todayWorkoutsData?.exercises.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),

          // Generate & Cancel Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPlan ? null : _showPlanDaysDialog,
                  icon: _isGeneratingPlan
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.bolt, size: 18),
                  label: Text(
                      _isGeneratingPlan ? 'Generating...' : 'Generate Plan',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isCancelling ? null : _confirmCancelPlan,
                  icon: _isCancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.red, strokeWidth: 2))
                      : const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(_isCancelling ? 'Cancelling...' : 'Cancel Plan',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Today's Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's Summary",
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Icon(Icons.bolt, color: neonGreen),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHomeStatItem(
                        "Calories",
                        "${consumedCalories.toInt()}/${targetCalories.toInt()}",
                        Icons.local_fire_department,
                        neonGreen),
                    _buildHomeStatItem("Weight", "${currentWeight.toInt()} kg",
                        Icons.monitor_weight, accentBlue),
                    _buildHomeStatItem(
                        "Exercises",
                        "$completedExercisesCount/$totalExercises",
                        Icons.check_circle_outline,
                        accentOrange),
                  ],
                ),
                const SizedBox(height: 20),
                Text("Calories Burned / Target",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: (consumedCalories /
                          (targetCalories > 0 ? targetCalories : 1))
                      .clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  color: neonGreen,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Text("Exercises Completed",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: totalExercises == 0
                      ? 0
                      : (completedExercisesCount / totalExercises)
                          .clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  color: accentOrange,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Today's Meals Status (quick view)
          const Text("Today's Meals Status",
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (isLoadingMeals)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Colors.green)))
          else if (todayMealsList.isEmpty)
            _buildEmptyCard("No meals for today. Generate a plan first!",
                Icons.restaurant_menu)
          else
            ...todayMealsList.map((m) => _buildSimpleMealTile(m)),
          const SizedBox(height: 25),

          // Quick Navigation
          const Text("Quick Navigation",
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildQuickTile("Check Meal Plan", Icons.restaurant,
              () => setState(() => _selectedIndex = 1)),
          _buildQuickTile("View Today's Workout", Icons.fitness_center,
              () => setState(() => _selectedIndex = 2)),
        ],
      ),
    );
  }

  Widget _buildHomeStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildSimpleMealTile(Meal meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: meal.isDone
            ? Border.all(color: neonGreen.withValues(alpha: 0.4), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(meal.isDone ? Icons.check_circle : Icons.circle_outlined,
              color: meal.isDone ? neonGreen : Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "${meal.mealTime}: ${meal.name}",
              style: TextStyle(
                color: meal.isDone ? Colors.grey : Colors.black87,
                decoration: meal.isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text("${meal.calories.toInt()} kcal",
              style: TextStyle(
                  color: accentOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: neonGreen),
        title: Text(title,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios,
            color: Colors.grey.shade400, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
        ],
      ),
    );
  }

  // ==========================================
  // 2. MEAL PLAN SCREEN
  // ==========================================
  Widget _buildMealPlanScreen() {
    double totalMealsCal =
        todayMealsList.fold(0.0, (sum, m) => sum + m.calories);
    double dayProgress = totalMealsCal > 0
        ? (consumedCalories / totalMealsCal).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MEAL PLAN",
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 5),
          Container(width: 80, height: 3, color: neonGreen),
          const SizedBox(height: 20),

          // Day selector bar
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Plan Overview",
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                const SizedBox(height: 15),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentPlanDays,
                    itemBuilder: (context, index) {
                      double barHeight = 40 + (index * 13 % 60).toDouble();
                      bool isSelected = (index + 1) == currentDaySlider.toInt();
                      return GestureDetector(
                        onTap: () => _onDayChanged((index + 1).toDouble()),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isSelected ? 12 : 8,
                                height: isSelected ? barHeight + 10 : barHeight,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? neonGreen
                                      : neonGreen.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "D${index + 1}",
                                style: TextStyle(
                                  color: isSelected
                                      ? neonGreen
                                      : Colors.grey.shade500,
                                  fontSize: isSelected ? 10 : 8,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Text("Day ${currentDaySlider.toInt()}",
                  style: TextStyle(
                      color: Colors.red.shade400, fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: currentDaySlider,
                  min: 1,
                  max: _currentPlanDays.toDouble(),
                  activeColor: Colors.red.shade400,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: _onDayChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Meals list from API
          if (isLoadingMeals)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: Colors.green)))
          else if (isLoadingMealsByDay)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: neonGreen),
                    const SizedBox(height: 12),
                    Text("Loading day ${currentDaySlider.toInt()} meals...",
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (todayMealsList.isEmpty)
            _buildEmptyCard(
                "No meals found for day ${currentDaySlider.toInt()}.",
                Icons.restaurant_menu)
          else
            ...List.generate(
                todayMealsList.length, (index) => _buildMealCard(index)),
          const SizedBox(height: 20),

          // Circular progress summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: dayProgress,
                        strokeWidth: 10,
                        color: neonGreen,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Completed",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 10)),
                        Text("${(dayProgress * 100).toInt()}%",
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroIndicator("Protein Tracker", neonGreen),
                    const SizedBox(height: 6),
                    _buildMacroIndicator("Carbs Target", accentOrange),
                    const SizedBox(height: 6),
                    _buildMacroIndicator("Fats Balance", accentBlue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(int index) {
    var meal = todayMealsList[index];
    bool isDone = meal.isDone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDone
            ? Border.all(color: neonGreen.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDone
                            ? neonGreen.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        meal.mealTime.toUpperCase(),
                        style: TextStyle(
                          color: isDone ? neonGreen : Colors.blueAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDone ? Colors.grey : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDone,
                activeColor: neonGreen,
                activeTrackColor: neonGreen.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
                onChanged: (value) => _toggleMeal(index, value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("${meal.calories.toStringAsFixed(1)} kcal",
                  style: TextStyle(
                      color: accentOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroIndicator(String label, Color col) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: Colors.black87, fontSize: 12)),
      ],
    );
  }

  // ==========================================
  // 3. WORKOUT PLAN SCREEN
  // ==========================================
  Widget _buildWorkoutPlanScreen() {
    int totalExercises = todayWorkoutsData?.exercises.length ?? 0;
    double workoutDayProgress = totalExercises == 0
        ? 0.0
        : (completedExercisesCount / totalExercises).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("WORKOUT PLAN",
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 5),
          Container(width: 120, height: 3, color: neonGreen),
          const SizedBox(height: 20),

          // Day selector bar
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Workout Plan Overview",
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                const SizedBox(height: 15),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentPlanDays,
                    itemBuilder: (context, index) {
                      double barHeight = 40 + (index * 13 % 60).toDouble();
                      bool isSelected =
                          (index + 1) == currentWorkoutDaySlider.toInt();
                      return GestureDetector(
                        onTap: () =>
                            _onWorkoutDayChanged((index + 1).toDouble()),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isSelected ? 12 : 8,
                                height: isSelected ? barHeight + 10 : barHeight,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accentOrange
                                      : accentOrange.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "D${index + 1}",
                                style: TextStyle(
                                  color: isSelected
                                      ? accentOrange
                                      : Colors.grey.shade500,
                                  fontSize: isSelected ? 10 : 8,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Text("Day ${currentWorkoutDaySlider.toInt()}",
                  style: TextStyle(
                      color: accentOrange, fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: currentWorkoutDaySlider,
                  min: 1,
                  max: _currentPlanDays.toDouble(),
                  activeColor: accentOrange,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: _onWorkoutDayChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Exercises list from API
          if (isLoadingWorkouts)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: Colors.green)))
          else if (isLoadingWorkoutsByDay)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: accentOrange),
                    const SizedBox(height: 12),
                    Text(
                        "Loading day ${currentWorkoutDaySlider.toInt()} workouts...",
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (todayWorkoutsData == null ||
              todayWorkoutsData!.exercises.isEmpty)
            _buildEmptyCard(
                "No workouts found for day ${currentWorkoutDaySlider.toInt()}. Generate a plan first!",
                Icons.fitness_center)
          else ...[
            if (todayWorkoutsData!.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(todayWorkoutsData!.title,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ),
            ...List.generate(
              todayWorkoutsData!.exercises.length,
              (index) {
                var ex = todayWorkoutsData!.exercises[index];
                bool isDone = ex.status == 'DONE';
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: isDone
                        ? Border.all(
                            color: neonGreen.withValues(alpha: 0.5), width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${(index + 1).toString().padLeft(2, '0')}",
                        style: TextStyle(
                          color: isDone
                              ? Colors.grey
                              : neonGreen.withValues(alpha: 0.8),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ex.exerciseName,
                              style: TextStyle(
                                color: isDone ? Colors.grey : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.fitness_center,
                                    color: isDone ? Colors.grey : Colors.orange,
                                    size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  "${ex.sets} sets x ${ex.reps} reps",
                                  style: TextStyle(
                                    color: isDone
                                        ? Colors.grey
                                        : Colors.grey.shade700,
                                    fontSize: 14,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildWorkoutTag(
                                    "Sets ${ex.sets}",
                                    isDone
                                        ? Colors.grey
                                        : Colors.green.shade700),
                                _buildWorkoutTag(
                                    "Reps ${ex.reps}",
                                    isDone
                                        ? Colors.grey
                                        : Colors.blue.shade700),
                                if (ex.intensity != null)
                                  _buildWorkoutTag(
                                      "Intensity ${ex.intensity}",
                                      isDone
                                          ? Colors.grey
                                          : Colors.red.shade700),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: isDone,
                            activeColor: neonGreen,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            side: BorderSide(
                                color: Colors.grey.shade400, width: 1.5),
                            onChanged: (_) => _toggleExercise(index),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 20),

          // Circular progress summary للـ workout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: workoutDayProgress,
                        strokeWidth: 10,
                        color: accentOrange,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Completed",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 10)),
                        Text("${(workoutDayProgress * 100).toInt()}%",
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMacroIndicator(
                        "$completedExercisesCount / $totalExercises Done",
                        neonGreen),
                    const SizedBox(height: 6),
                    _buildMacroIndicator(
                        "Day ${currentWorkoutDaySlider.toInt()} Workout",
                        accentOrange),
                    const SizedBox(height: 6),
                    _buildMacroIndicator("Keep it up! 💪", accentBlue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTag(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg, width: 0.5),
      ),
      child: Text(label,
          style:
              TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  // ==========================================
  // 4. STATS SCREEN
  // ==========================================
  Widget _buildStatsScreen() {
    Color bmiColor = neonGreen;
    String bmiStatus = "Normal weight";
    double bmiProgress = 0.5;

    if (calculatedBMI < 18.5) {
      bmiColor = Colors.blue;
      bmiStatus = "Underweight";
      bmiProgress = 0.2;
    } else if (calculatedBMI >= 25 && calculatedBMI < 30) {
      bmiColor = Colors.orange;
      bmiStatus = "Overweight";
      bmiProgress = 0.75;
    } else if (calculatedBMI >= 30) {
      bmiColor = Colors.red;
      bmiStatus = "Obese";
      bmiProgress = 0.9;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("YOUR STATS",
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 5),
          Container(width: 100, height: 3, color: neonGreen),
          const SizedBox(height: 25),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildGridStatCard(targetCalories.toInt().toString(),
                  "DAILY TARGET", "kcal / day"),
              _buildGridStatCard(
                  calculatedBMR.toInt().toString(), "BMR", "kcal / day"),
              _buildGridStatCard(
                  calculatedBMI.toStringAsFixed(1), "BMI", bmiStatus,
                  valueColor: bmiColor),
              _buildGridStatCard(
                  weightToLose.toStringAsFixed(1), "LOSE WEIGHT", "kg to goal"),
              _buildGridStatCard(
                  widget.durationDays ?? "60", "DURATION", "days"),
              _buildGridStatCard(
                  activityMultiplier.toString(), "ACTIVITY", "multiplier"),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("BMI Status",
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("You are currently in the $bmiStatus range.",
                          style: TextStyle(color: bmiColor, fontSize: 12)),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: bmiProgress),
                        duration: const Duration(seconds: 1),
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                          value: value,
                          strokeWidth: 12,
                          color: bmiColor,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ),
                    Text(calculatedBMI.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          if (targetCalories < 1300)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade400, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Calories target is very low — consider consulting a doctor.",
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridStatCard(String val, String title, String sub,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
              child: Text(val,
                  style: TextStyle(
                      color: valueColor ?? neonGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          FittedBox(
              child: Text(title,
                  style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 9,
                      fontWeight: FontWeight.bold))),
          FittedBox(
              child: Text(sub,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 8))),
        ],
      ),
    );
  }

  // ==========================================
  // 5. PROGRESS SCREEN  ←  التعديل هنا
  // ==========================================
  Widget _buildProgressScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("PROGRESS TRACKING",
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),

          // ── Goal card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.trending_up_rounded, size: 80, color: neonGreen),
                const SizedBox(height: 15),
                Text(
                  "Goal: ${currentFitnessGoal.toUpperCase()}",
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // ── Weight Bar Chart ──
          _buildWeightBarChart(),
        ],
      ),
    );
  }

  /// Bar Chart يعرض Started / Current / Aim Weight
  Widget _buildWeightBarChart() {
    // أعلى قيمة لتحديد نسبة الارتفاع
    final double maxVal = [startedWeight, currentWeight, targetWeightVal]
        .reduce((a, b) => a > b ? a : b);

    final bars = [
      _WeightBarData(
        label: "Started",
        value: startedWeight,
        color: accentBlue,
      ),
      _WeightBarData(
        label: "Current",
        value: currentWeight,
        color: neonGreen,
      ),
      _WeightBarData(
        label: "Aim",
        value: targetWeightVal,
        color: accentOrange,
      ),
    ];

    const double chartHeight = 160.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weight Overview",
            style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "kg",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((bar) {
              final double barH =
                  maxVal > 0 ? (bar.value / maxVal) * chartHeight : 0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // القيمة فوق البار
                  Text(
                    "${bar.value.toStringAsFixed(1)} kg",
                    style: TextStyle(
                        color: bar.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  // البار نفسه
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: barH),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (context, animH, _) => Container(
                      width: 52,
                      height: animH,
                      decoration: BoxDecoration(
                        color: bar.color,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        gradient: LinearGradient(
                          colors: [
                            bar.color.withValues(alpha: 0.7),
                            bar.color,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // الليبل تحت البار
                  const SizedBox(height: 8),
                  Text(
                    bar.label,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearProgress(String label, double val, Color col) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.black87, fontSize: 13)),
            Text("${(val * 100).toInt()}%",
                style: TextStyle(
                    color: col, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: val.clamp(0.0, 1.0),
          color: col,
          backgroundColor: Colors.grey.shade200,
          minHeight: 8,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  // ==========================================
  // 6. AI EXERCISE SCREEN
  // ==========================================
  Widget _buildAiExerciseScreen() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 90, color: accentBlue),
          const SizedBox(height: 20),
          const Text("AI Form Feedback",
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            "Analyze your body pose positioning with live metrics tracking feedback.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Select exercise video",
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 15),
              ElevatedButton(
                onPressed: () async {
                  final XFile? video =
                      await _picker.pickVideo(source: ImageSource.gallery);
                  if (video != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Processing: ${video.name}"),
                      backgroundColor: neonGreen,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Start",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER  ← فيه refresh بعد رجوع البروفايل
  // ==========================================
  Widget _buildHeader() {
    print("isAdmin value: ${widget.isAdmin}"); // ✅ أضف السطر ده مؤقتاً
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${widget.userName}!",
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "Welcome back to your ultimate dashboard.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ), // ✅ زرار Admin Panel — بيظهر بس لو isAdmin == true
        if (widget.isAdmin) ...[
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Admin',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: () async {
            // ── فتح البروفايل وانتظار الرجوع ──
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  userName: widget.userName,
                  userEmail: widget.userEmail,
                  age: widget.age ?? "25",
                  height: widget.height ?? "170",
                  weight: widget.weight ?? "70",
                  targetWeight: widget.targetWeight ?? "70",
                  gender: widget.gender ?? "Male",
                  activityLevel: widget.activityLevel ?? "moderate",
                  fitnessGoal: widget.fitnessGoal ?? "lose weight",
                  experienceLevel: widget.experienceLevel ?? "beginner",
                  equipment: widget.equipment ?? "full gym",
                ),
              ),
            );

            // ── بعد الرجوع: نجيب بيانات البروفايل المحدثة ونحدث الداشبورد ──
            if (mounted) {
              await _refreshAfterProfileUpdate();
            }
          },
          child: CircleAvatar(
              backgroundColor: neonGreen,
              radius: 24,
              child: const Icon(Icons.person, color: Colors.white)),
        ),
      ],
    );
  }

  /// يُستدعى عند تحميل الـ Dashboard لأول مرة
  /// يجيب أحدث بيانات البروفايل من الـ API عشان الوزن ميكونش قديم
  Future<void> _refreshProfileDataOnDashboardLoad() async {
    try {
      final repo = _ProfileRefreshHelper();
      final profile = await repo.fetchLatestData();

      if (profile != null && mounted) {
        setState(() {
          currentWeight = profile.currentWeight;
          targetWeightVal = profile.targetWeight;
          currentFitnessGoal = profile.fitnessGoal;
          _recalculate();
        });
      }
    } catch (e) {
      // لو فشل الـ fetch، بنفضل باستخدام القيم اللي اتمررت في الـ widget
      debugPrint("Failed to fetch profile on dashboard load: $e");
    }
  }

  /// يُستدعى بعد رجوع المستخدم من ProfileScreen
  /// يجيب أحدث بيانات البروفايل ويحدث currentWeight, targetWeightVal وكل المشتقات
  Future<void> _refreshAfterProfileUpdate() async {
    try {
      final repo = _ProfileRefreshHelper();
      final profile = await repo.fetchLatestData();

      if (profile != null && mounted) {
        setState(() {
          currentWeight = profile.currentWeight;
          targetWeightVal = profile.targetWeight;
          currentFitnessGoal = profile.fitnessGoal;
          _recalculate();
        });
      }
    } catch (e) {
      // لو فشل الـ fetch مش مشكلة — القيم القديمة تفضل
      debugPrint("Failed to fetch profile after update: $e");
    }
  }

  // ==========================================
  // BOTTOM NAV BAR
  // ==========================================
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      selectedItemColor: neonGreen,
      unselectedItemColor: Colors.grey.shade500,
      backgroundColor: cardColor,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu), label: 'Meal'),
        BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center), label: 'Workout'),
        BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined), label: 'Stats'),
        BottomNavigationBarItem(
            icon: Icon(Icons.stacked_line_chart), label: 'Progress'),
        BottomNavigationBarItem(
            icon: Icon(Icons.psychology), label: 'AI Exercise'),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Helper model + class للـ refresh بعد ProfileScreen
// ══════════════════════════════════════════════════════════════════

class _LatestProfileData {
  final double currentWeight;
  final double targetWeight;
  final String fitnessGoal;
  _LatestProfileData({
    required this.currentWeight,
    required this.targetWeight,
    required this.fitnessGoal,
  });
}

/// يجيب أحدث بيانات البروفايل من الـ ProfileRepository
class _ProfileRefreshHelper {
  Future<_LatestProfileData?> fetchLatestData() async {
    try {
      final repo = ProfileRepository();
      final profile = await repo.getProfileData();
      if (profile == null) return null;
      return _LatestProfileData(
        currentWeight: profile.currentWeight.toDouble(),
        targetWeight: profile.targetWeight.toDouble(),
        fitnessGoal: profile.fitnessGoal,
      );
    } catch (_) {
      return null;
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// Data model for Weight Bar Chart
// ══════════════════════════════════════════════════════════════════
class _WeightBarData {
  final String label;
  final double value;
  final Color color;

  const _WeightBarData({
    required this.label,
    required this.value,
    required this.color,
  });
}
