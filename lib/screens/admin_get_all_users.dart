import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminGetAllUsers extends StatefulWidget {
  const AdminGetAllUsers({super.key});

  @override
  State<AdminGetAllUsers> createState() => _AdminGetAllUsersState();
}

class _AdminGetAllUsersState extends State<AdminGetAllUsers> {
  bool _loading = false;
  List<Map<String, dynamic>> _users = [];
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.get('getalluser');
      final data = response.data;
      final users = data['data']?['users'] as List<dynamic>?;
      _users = users
              ?.map((item) =>
                  Map<String, dynamic>.from(item as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      _error = 'Failed to load users: $e';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _users.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            title: Text(user['fullname'] ?? 'Unknown'),
                            subtitle: Text(user['email'] ?? ''),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  user['role'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user['banned'] == true ? 'Banned' : 'Active',
                                  style: TextStyle(
                                    color: user['banned'] == true
                                        ? Colors.red
                                        : Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        backgroundColor: const Color(0xFF2E8B57),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
