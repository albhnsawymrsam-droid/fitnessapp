import 'package:flutter/material.dart';

class VitaFlowGuideScreen extends StatelessWidget {
  const VitaFlowGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color neonGreen = Color(0xFF00C853);
    const Color accentOrange = Color(0xFFFF6D00);
    const Color accentBlue = Color(0xFF00B0FF);
    const Color bgColor = Color(0xFFF4F6F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Vitaflow Ecosystem Guide',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: neonGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: neonGreen,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Welcome to Vitaflow!',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Vitaflow, your ultimate AI-driven health and fitness partner. Here is a quick guide to understanding how our ecosystem works to help you achieve your goals safely and efficiently:',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Step 1
            _buildStepCard(
              stepNumber: "1",
              title: "Account Setup & Security",
              icon: Icons.security_rounded,
              iconColor: accentBlue,
              items: [
                _buildSubItem(
                  title: "Gmail Activation Required",
                  description:
                      "The system strictly requires registration using a real Gmail account (@gmail.com). This ensures you securely receive your weekly progress reports, account verification codes (OTP), and exportable PDF meal plans directly to your inbox.",
                ),
                _buildSubItem(
                  title: "Health Onboarding Profile",
                  description:
                      "Upon your first login, you must complete your onboarding profile by entering your essential biometrics: Age, Gender, Current Height, Current Weight, and Daily Activity Level. These parameters form the mathematical foundation for all AI calculations.",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Step 2
            _buildStepCard(
              stepNumber: "2",
              title: "Dynamic Plan Generation (AI Engine)",
              icon: Icons.psychology_rounded,
              iconColor: accentOrange,
              items: [
                _buildSubItem(
                  title: "Select Duration First",
                  description:
                      "To keep your journey safe, you choose the plan duration first, which ranges from 3 to 7 days.",
                ),
                _buildSubItem(
                  title: "Smart Weight Suggestions",
                  description:
                      "Once you select the days (even if it's a short 3-day or 4-day sprint), the backend automatically computes the scientifically safe weight threshold you can lose or gain within this specific window. This strictly prevents entering dangerous or unrealistic weight targets.",
                ),
                _buildSubItem(
                  title: "Generate My Plan",
                  description:
                      "Upon confirmation, the AI engine instantly customizes:\n\n• Personalized Nutrition Plan: Tailored daily calorie and macros breakdown.\n• Targeted Workout Routine: Optimized for your chosen duration and target goal.",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Step 3
            _buildStepCard(
              stepNumber: "3",
              title: "Daily Access & Real-Time AI Tracking",
              icon: Icons.videocam_rounded,
              iconColor: neonGreen,
              items: [
                _buildSubItem(
                  title: "Day-by-Day Access",
                  description:
                      "To keep you focused, your nutrition and workout schedule is unlocked day by day. You will only access the meals and training sessions designated for the \"Current Day\".",
                ),
                _buildSubItem(
                  title: "Interactive AI Gym Tracker",
                  description:
                      "When performing any exercise, you can launch the live camera tracking. Our built-in MediaPipe and Computer Vision model will track your body joints, count your repetitions (Reps) automatically, and evaluate your form in real-time to protect you from injuries.",
                ),
                _buildSubItem(
                  title: "Progress Analytics",
                  description:
                      "Visit the \"Progress\" screen anytime to view dynamic line charts tracking your actual weight change over time.",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Step 4
            _buildStepCard(
              stepNumber: "4",
              title: "Plan Completion & Renewal",
              icon: Icons.cached_rounded,
              iconColor: Colors.purple,
              items: [
                _buildSubItem(
                  title: "Continuous Progression",
                  description:
                      "As soon as your 3-to-7-day plan ends, the app safely closes the cycle and unlocks the \"Start a New Plan\" button. This allows you to log your new current weight and generate a fresh, updated phase of your fitness journey.",
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  stepNumber,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSubItem({
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
