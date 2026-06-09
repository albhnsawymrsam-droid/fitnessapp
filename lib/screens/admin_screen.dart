import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'admin_get_all_users.dart';
import 'admin_get_user_by_id.dart';
import 'admin_user_analysis.dart';
import 'admin_get_all_profile.dart';

class AdminScreen extends StatefulWidget {
  final String? adminName;
  const AdminScreen({super.key, this.adminName});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color lightGray = const Color(0xFFF5F6F8);

  bool _loading = false;
  String _adminName = '';

  @override
  void initState() {
    super.initState();
    _adminName = widget.adminName ?? '';
    if (_adminName.isEmpty) {
      _loadAdminName();
    }
  }

  Future<void> _loadAdminName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      if (name != null && name.isNotEmpty) {
        setState(() {
          _adminName = name;
        });
      } else {
        final user = FirebaseAuth.instance.currentUser;
        setState(() {
          _adminName =
              user?.displayName ?? user?.email?.split('@').first ?? 'Admin';
        });
      }
    } catch (_) {
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _adminName =
            user?.displayName ?? user?.email?.split('@').first ?? 'Admin';
      });
    }
  }

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

  Future<void> logout() async {
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

  Widget _buildAdminCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _adminName.isNotEmpty ? _adminName : 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Admin Control Panel',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, const Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SYSTEM ADMINISTRATOR',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildAdminCard(
              title: 'Get All Users',
              description: 'View and manage registered user accounts.',
              icon: Icons.people_alt_rounded,
              onTap: _getAllUsers,
            ),
            _buildAdminCard(
              title: 'Get User By ID',
              description: 'Search for a specific user using their ID.',
              icon: Icons.person_search_rounded,
              onTap: _getUserById,
            ),
            _buildAdminCard(
              title: 'Get All User Analysis',
              description: 'Analyze users exercise, plan, and meal statistics.',
              icon: Icons.analytics_rounded,
              onTap: _getAllUserAnalysis,
            ),
            _buildAdminCard(
              title: 'Get All Profiles',
              description: 'View comprehensive profiles of registered users.',
              icon: Icons.manage_accounts_rounded,
              onTap: _getAllProfile,
            ),
            if (_loading) ...[
              const SizedBox(height: 24),
              Center(child: CircularProgressIndicator(color: primaryGreen)),
            ]
          ],
        ),
      ),
    );
  }
}
