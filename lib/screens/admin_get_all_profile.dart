import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminGetAllProfile extends StatefulWidget {
  const AdminGetAllProfile({super.key});

  @override
  State<AdminGetAllProfile> createState() => _AdminGetAllProfileState();
}

class _AdminGetAllProfileState extends State<AdminGetAllProfile> {
  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color bgColor = const Color(0xFFF4F6F9);

  bool _loading = false;
  List<Map<String, dynamic>> _profiles = [];
  String? _error;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.get('getAllProfile');
      final data = response.data;
      final profiles = data['data']?['profiles'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _profiles = profiles
                  ?.map((p) =>
                      Map<String, dynamic>.from(p as Map<String, dynamic>))
                  .toList() ??
              [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profiles: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryGreen, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> p) {
    final user = p['user'] as Map<String, dynamic>?;
    final String fullName = user?['fullname'] ?? 'Unknown User';
    final String email = user?['email'] ?? 'No email';
    final String fitnessGoal = p['fitness_goal'] ?? 'Not set';
    final String activityLevel = p['active_level'] ?? 'Not set';
    final String dateStr = p['createdAt']?.toString().split('T').first ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_circle_rounded,
                    color: primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildBadge(fitnessGoal, const Color(0xFFE8F5E9), primaryGreen),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Row(
              children: [
                _buildDetailItem(
                    Icons.cake_rounded, 'Age', '${p['age'] ?? '-'} yrs'),
                const SizedBox(width: 12),
                _buildDetailItem(
                    Icons.wc_rounded, 'Gender', '${p['gender'] ?? '-'}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailItem(Icons.straighten_rounded, 'Height',
                    '${p['height'] ?? '-'} cm'),
                const SizedBox(width: 12),
                _buildDetailItem(Icons.monitor_weight_rounded, 'Weight',
                    '${p['current_weight'] ?? '-'} kg'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailItem(Icons.bolt_rounded, 'Activity', activityLevel),
                const SizedBox(width: 12),
                _buildDetailItem(
                    Icons.calendar_today_rounded, 'Joined On', dateStr),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'All Profiles',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 60, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : _profiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.manage_accounts_rounded,
                              size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No profiles found',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _profiles.length,
                      itemBuilder: (context, index) {
                        return _buildProfileCard(_profiles[index]);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        backgroundColor: primaryGreen,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    );
  }
}
