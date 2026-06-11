import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminGetAllUsers extends StatefulWidget {
  const AdminGetAllUsers({super.key});

  @override
  State<AdminGetAllUsers> createState() => _AdminGetAllUsersState();
}

class _AdminGetAllUsersState extends State<AdminGetAllUsers> {
  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color bgColor = const Color(0xFFF4F6F9);

  bool _loading = false;
  List<Map<String, dynamic>> _users = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.get('getalluser');
      final data = response.data;
      final users = data['data']?['users'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _users = users
                  ?.map((item) =>
                      Map<String, dynamic>.from(item as Map<String, dynamic>))
                  .toList() ??
              [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users: $e';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final name = (user['fullname'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final id = (user['user_id'] ?? user['id'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          id.contains(query);
    }).toList();
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
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String fullName = user['fullname'] ?? 'Unknown User';
    final String email = user['email'] ?? 'No email';
    final String role = user['role'] ?? 'USER';
    final bool isBanned = user['banned'] == true;
    final String userId = (user['user_id'] ?? user['id'] ?? '').toString();

    // Badge styling based on role
    final Color roleBg = role.toLowerCase() == 'admin'
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFE3F2FD);
    final Color roleText = role.toLowerCase() == 'admin'
        ? const Color(0xFF2E7D32)
        : const Color(0xFF1565C0);

    // Badge styling based on status
    final Color statusBg =
        isBanned ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final Color statusText =
        isBanned ? const Color(0xFFC62828) : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBanned
                    ? Colors.red.withValues(alpha: 0.1)
                    : primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                role.toLowerCase() == 'admin'
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                color: isBanned ? Colors.red.shade700 : primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
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
                  if (userId.isNotEmpty &&
                      userId != 'null' &&
                      userId != '0') ...[
                    const SizedBox(height: 2),
                    Text(
                      "ID: $userId",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBadge(role, roleBg, roleText),
                const SizedBox(height: 6),
                _buildBadge(
                    isBanned ? 'Banned' : 'Active', statusBg, statusText),
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
          'All Users',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search users by name, email or ID...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear_rounded, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
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
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline_rounded,
                                    size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No matching users found'
                                      : 'No users found',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              return _buildUserCard(_filteredUsers[index]);
                            },
                          ),
          ),
        ],
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
