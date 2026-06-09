import 'package:flutter/material.dart';
import 'package:ai/services/api_service.dart';

class AdminGetUserById extends StatefulWidget {
  final String userId;
  const AdminGetUserById({super.key, required this.userId});

  @override
  State<AdminGetUserById> createState() => _AdminGetUserByIdState();
}

class _AdminGetUserByIdState extends State<AdminGetUserById> {
  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color bgColor = const Color(0xFFF4F6F9);

  bool _loading = false;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _summary;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final resp = await ApiService.instance.get('admin/user/${widget.userId}');
      final data = resp.data;
      if (mounted) {
        if (data != null &&
            data['data'] != null &&
            data['data']['user'] != null) {
          setState(() {
            _user = Map<String, dynamic>.from(data['data']['user']);
            _profile = _user!['profile'] != null
                ? Map<String, dynamic>.from(_user!['profile'])
                : null;
            _summary = data['data']['summary'] != null
                ? Map<String, dynamic>.from(data['data']['summary'])
                : null;
          });
        } else {
          setState(() {
            _user = null;
            _profile = null;
            _summary = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _user = null;
          _profile = null;
          _summary = null;
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String key, String? value,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
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
              const SizedBox(width: 12),
              Text(
                key,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                value ?? '-',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    String? createdDate;
    if (_user != null && _user!['created_at'] != null) {
      createdDate = _user!['created_at'].toString().split('T').first;
    }

    final bool isBanned = _user?['banned'] == true;
    final String role = _user?['role'] ?? 'USER';

    final Color roleBg = role.toLowerCase() == 'admin'
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFE3F2FD);
    final Color roleText = role.toLowerCase() == 'admin'
        ? const Color(0xFF2E7D32)
        : const Color(0xFF1565C0);

    final Color statusBg =
        isBanned ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final Color statusText =
        isBanned ? const Color(0xFFC62828) : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'User Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        backgroundColor: primaryGreen,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_rounded,
                          size: 65, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No user found',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Main Identity Card
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_rounded,
                                color: primaryGreen, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user!['fullname'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _user!['email'] ?? '-',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildSectionHeader(
                        'Account Information', Icons.badge_rounded),

                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.fingerprint_rounded, 'User ID',
                              _user!['user_id']?.toString()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.shield_rounded,
                                      color: primaryGreen, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Role',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                _buildBadge(role, roleBg, roleText),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.block_rounded,
                                      color: primaryGreen, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Account Status',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                _buildBadge(isBanned ? 'Banned' : 'Active',
                                    statusBg, statusText),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          _buildInfoRow(Icons.calendar_today_rounded,
                              'Created At', createdDate,
                              isLast: true),
                        ],
                      ),
                    ),

                    if (_profile != null) ...[
                      _buildSectionHeader('Health & Fitness Profile',
                          Icons.health_and_safety_rounded),
                      Container(
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.cake_rounded, 'Age',
                                '${_profile!['age'] ?? '-'} yrs'),
                            _buildInfoRow(Icons.wc_rounded, 'Gender',
                                _profile!['gender']?.toString()),
                            _buildInfoRow(Icons.straighten_rounded, 'Height',
                                '${_profile!['height'] ?? '-'} cm'),
                            _buildInfoRow(
                                Icons.monitor_weight_rounded,
                                'Current Weight',
                                '${_profile!['current_weight'] ?? '-'} kg'),
                            _buildInfoRow(Icons.scale_rounded, 'Initial Weight',
                                '${_profile!['initial_weight'] ?? '-'} kg'),
                            _buildInfoRow(Icons.flag_rounded, 'Target Weight',
                                '${_profile!['target_weight'] ?? '-'} kg'),
                            _buildInfoRow(Icons.analytics_rounded, 'BMI',
                                _profile!['bmi']?.toString()),
                            _buildInfoRow(Icons.local_fire_department_rounded,
                                'BMR', '${_profile!['bmr'] ?? '-'} kcal'),
                            _buildInfoRow(Icons.bolt_rounded, 'Activity Level',
                                _profile!['active_level']?.toString()),
                            _buildInfoRow(
                                Icons.fitness_center_rounded,
                                'Fitness Goal',
                                _profile!['fitness_goal']?.toString()),
                            _buildInfoRow(
                                Icons.trending_up_rounded,
                                'Experience Level',
                                _profile!['experience_level']?.toString()),
                            _buildInfoRow(Icons.sports_gymnastics_rounded,
                                'Equipment', _profile!['equipment']?.toString(),
                                isLast: true),
                          ],
                        ),
                      ),
                    ],

                    if (_summary != null) ...[
                      _buildSectionHeader(
                          'Weight History Summary', Icons.history_rounded),
                      Container(
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.scale_rounded, 'Initial Weight',
                                '${_summary!['initialWeight'] ?? '-'} kg'),
                            _buildInfoRow(
                                Icons.monitor_weight_rounded,
                                'Current Weight',
                                '${_summary!['currentWeight'] ?? '-'} kg'),
                            _buildInfoRow(Icons.flag_rounded, 'Target Weight',
                                '${_summary!['targetWeight'] ?? '-'} kg'),
                            _buildInfoRow(
                                Icons.history_rounded,
                                'Total Weight Entries',
                                _summary!['totalWeightEntries']?.toString(),
                                isLast: true),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}
