import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({Key? key}) : super(key: key);

  @override
  _ExerciseSelectionScreenState createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  // ✅ غيّر الـ URL ده كل مرة بتشغل ngrok
  static const String ngrokUrl =
      'https://crisply-coping-angled.ngrok-free.dev/start_exercise';

  final List<Map<String, String>> exercises = [
    {"name": "Push Ups", "gif": "assets/videos/push_up.gif"},
    {"name": "Pull ups", "gif": "assets/videos/pull_ups.gif"},
    {"name": "Squats", "gif": "assets/videos/squats.gif"},
    {"name": "Jumping Jacks", "gif": "assets/videos/jumping_jacks.gif"},
    {"name": "Russian twists", "gif": "assets/videos/russian_twists.gif"},
  ];

  String? selectedExerciseName;
  String? selectedExerciseGif;
  bool _isLoading = false;

  Future<void> _startAiCamera(String exerciseName) async {
    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse(ngrokUrl),
            headers: {
              "Content-Type": "application/json",
              "ngrok-skip-browser-warning": "true", // ✅ مهم جداً مع ngrok
            },
            body: jsonEncode({"exercise_name": exerciseName}),
          )
          .timeout(const Duration(seconds: 10));

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ ${data['message']}"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Unknown error');
      }
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      _showError('Connection failed: $e\nتأكد إن السيرفر وngrok شغالين');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ $msg"), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "AI Trainer - Select Exercise",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // GIF Preview
          Container(
            height: 280,
            width: double.infinity,
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: selectedExerciseGif != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child:
                        Image.asset(selectedExerciseGif!, fit: BoxFit.contain),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center,
                            size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "Select an exercise to see the correct form",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
          ),

          // Exercise List
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final ex = exercises[index];
                final isSelected = selectedExerciseName == ex["name"];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  elevation: isSelected ? 3 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.green : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      ex["name"]!,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 28)
                        : const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      setState(() {
                        selectedExerciseName = ex["name"];
                        selectedExerciseGif = ex["gif"];
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Start Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E664),
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (selectedExerciseName == null || _isLoading)
                  ? null
                  : () => _startAiCamera(selectedExerciseName!),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Start Exercise",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ExerciseSelectionScreen extends StatefulWidget {
//   const ExerciseSelectionScreen({Key? key}) : super(key: key);

//   @override
//   _ExerciseSelectionScreenState createState() =>
//       _ExerciseSelectionScreenState();
// }

// class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
//   // القائمة المتطابقة بالملي مع أسامي ملفات الـ GIFs بتاعتك
//   final List<Map<String, String>> exercises = [
//     {"name": "Push Ups", "gif": "assets/videos/push_up.gif"},
//     {"name": "Pull ups", "gif": "assets/videos/pull_ups.gif"},
//     {"name": "Squats", "gif": "assets/videos/squats.gif"},
//     {"name": "Jumping Jacks", "gif": "assets/videos/jumping_jacks.gif"},
//     {"name": "Russian twists", "gif": "assets/videos/russian_twists.gif"},
//   ];

//   String? selectedExerciseName;
//   String? selectedExerciseGif;

//   // دالة تشغيل السيرفر المحلي لفتح كاميرا اللاب توب وموديل الـ AI
//   Future<void> _startAiCamera(String exerciseName) async {
//     // ⚠️ استبدل الـ IP ده بالـ IP بتاع لابتوبك الشخصي في الشبكة وقت المناقشة
//     final String localIP = "192.168.1.5";
//     final String url = Uri.parse(
//       // 'https://nephew-degrease-carnage.ngrok-free.dev/start_exercise';
//       'https://crisply-coping-angled.ngrok-free.dev/start_exercise',
//     ).toString();

//     try {
//       // إظهار لودينج لحد ما الكاميرا تفتح
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) =>
//             const Center(child: CircularProgressIndicator(color: Colors.green)),
//       );

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"exercise_name": exerciseName}),
//       );

//       Navigator.pop(context); // إغلاق الـ Loading بعد الرد

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text("AI Camera started for $exerciseName "),
//               backgroundColor: Colors.green),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text("Failed to start AI Camera"),
//               backgroundColor: Colors.red),
//         );
//       }
//     } catch (e) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text("Error connecting to AI Server: $e"),
//             backgroundColor: Colors.red),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         title: const Text("AI Trainer - Select Exercise",
//             style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           // 1. الجزء العلوي: عرض الـ GIF التعليمي للتمرين المختار
//           Container(
//             height: 280,
//             width: double.infinity,
//             margin: const EdgeInsets.all(15),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: [
//                 BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 5))
//               ],
//             ),
//             child: selectedExerciseGif != null
//                 ? ClipRRect(
//                     borderRadius: BorderRadius.circular(15),
//                     child:
//                         Image.asset(selectedExerciseGif!, fit: BoxFit.contain),
//                   )
//                 : const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.fitness_center,
//                             size: 50, color: Colors.grey),
//                         SizedBox(height: 10),
//                         Text("Select an exercise to see the correct form",
//                             style: TextStyle(color: Colors.grey, fontSize: 16)),
//                       ],
//                     ),
//                   ),
//           ),

//           // 2. الجزء الأوسط: قائمة الـ 5 تمارين المتاحة
//           Expanded(
//             child: ListView.builder(
//               itemCount: exercises.length,
//               itemBuilder: (context, index) {
//                 final ex = exercises[index];
//                 final isSelected = selectedExerciseName == ex["name"];
//                 return Card(
//                   margin:
//                       const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
//                   elevation: isSelected ? 3 : 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     side: BorderSide(
//                         color: isSelected ? Colors.green : Colors.transparent,
//                         width: 1.5),
//                   ),
//                   child: ListTile(
//                     contentPadding:
//                         const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                     title: Text(ex["name"]!,
//                         style: const TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold)),
//                     trailing: isSelected
//                         ? const Icon(Icons.check_circle,
//                             color: Colors.green, size: 28)
//                         : const Icon(Icons.arrow_forward_ios, size: 18),
//                     onTap: () {
//                       setState(() {
//                         selectedExerciseName = ex["name"];
//                         selectedExerciseGif = ex["gif"];
//                       });
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),

//           // 3. الجزء السفلي: زرار تشغيل الكاميرا والموديل أونلاين
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor:
//                     const Color(0xFF00E664), // نفس درجة الأخضر الرايقة بتاعتك
//                 minimumSize: const Size.fromHeight(55),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//               onPressed: selectedExerciseName == null
//                   ? null
//                   : () => _startAiCamera(selectedExerciseName!),
//               child: const Text("Start Exercise",
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white)),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
