import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminGetAllProfile extends StatefulWidget {
  const AdminGetAllProfile({super.key});

  @override
  State<AdminGetAllProfile> createState() => _AdminGetAllProfileState();
}

class _AdminGetAllProfileState extends State<AdminGetAllProfile> {
  bool _loading = false;
  List<Map<String, dynamic>> _profiles = [];
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.get('getAllProfile');
      final data = response.data;
      final profiles = data['data']?['profiles'] as List<dynamic>?;
      _profiles = profiles
              ?.map((p) => Map<String, dynamic>.from(p as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      _error = 'Failed to load profiles: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Widget _buildProfileTile(Map<String, dynamic> p) {
    final user = p['user'] as Map<String, dynamic>?;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      title: Text(user?['fullname'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text('Email: ${user?['email'] ?? ''}'),
          Text('Age: ${p['age'] ?? '-'} • Gender: ${p['gender'] ?? '-'}'),
          Text(
              'Height: ${p['height'] ?? '-'} cm • Weight: ${p['current_weight'] ?? '-'} kg'),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Goal: ${p['fitness_goal'] ?? '-'}',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            'Created: ${p['createdAt']?.toString().split('T').first ?? '-'}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Profiles')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _profiles.isEmpty
                    ? const Center(child: Text('No profiles found'))
                    : ListView.separated(
                        itemCount: _profiles.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _buildProfileTile(_profiles[index]),
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
