import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'admin_get_all_users.dart';
import 'admin_get_user_by_id.dart';
import 'admin_user_analysis.dart';
import 'admin_get_all_profile.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color lightGray = const Color(0xFFF5F6F8);

  bool _loading = false;

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _getAllUsers() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminGetAllUsers()),
    );
  }

  Future<void> _getUserById() async {
    // Show input dialog to enter user id
    final id = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter user id'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'User id'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('OK')),
          ],
        );
      },
    );

    if (id == null || id.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminGetUserById(userId: id)),
    );
  }

  Future<void> _getAllUserAnalysis() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminUserAnalysis()),
    );
  }

  Future<void> _getAllProfile() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminGetAllProfile()),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return Expanded(
      child: SizedBox(
        height: 64,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: lightGray,
            foregroundColor: Colors.black87,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName ?? user?.email?.split('@').first ?? 'username';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Center(
                child: Text('Welcome Mr $userName',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 36),

            // First row
            Row(
              children: [
                _actionButton('get all user', _getAllUsers),
                const SizedBox(width: 16),
                _actionButton('get user by id', _getUserById),
              ],
            ),

            const SizedBox(height: 24),

            // Second row
            Row(
              children: [
                _actionButton('get all user analysis', _getAllUserAnalysis),
                const SizedBox(width: 16),
                _actionButton('get all profile', _getAllProfile),
              ],
            ),

            const Spacer(),

            Center(
              child: SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Logout',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
            ),

            if (_loading) ...[
              const SizedBox(height: 18),
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E8B57))),
            ]
          ],
        ),
      ),
    );
  }
}
