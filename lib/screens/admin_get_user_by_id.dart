import 'package:flutter/material.dart';
import 'package:ai/services/api_service.dart';

class AdminGetUserById extends StatefulWidget {
  final String userId;
  const AdminGetUserById({super.key, required this.userId});

  @override
  State<AdminGetUserById> createState() => _AdminGetUserByIdState();
}

class _AdminGetUserByIdState extends State<AdminGetUserById> {
  bool _loading = false;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _summary;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiService.instance.get('admin/user/${widget.userId}');
      final data = resp.data;
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
    } catch (e) {
      setState(() {
        _user = null;
        _profile = null;
        _summary = null;
      });
    } finally {
      setState(() => _loading = false);
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
      appBar: AppBar(title: const Text('User By ID')),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _user == null
                ? const Center(child: Text('No user found'))
                : ListView(
                    children: [
                      Card(
                        child: ListTile(
                          title: Text(_user!['fullname'] ?? '-'),
                          subtitle: Text(_user!['email'] ?? '-'),
                          leading: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _infoChip('ID', _user!['user_id']?.toString()),
                          _infoChip('Role', _user!['role']),
                          _infoChip('Banned', _user!['banned']?.toString()),
                          _infoChip('Created', _user!['created_at']),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_profile != null) ...[
                        const Text('Profile',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _kvRow('Age', _profile!['age']?.toString()),
                                _kvRow('Gender', _profile!['gender']),
                                _kvRow(
                                    'Height', _profile!['height']?.toString()),
                                _kvRow('Current Weight',
                                    _profile!['current_weight']?.toString()),
                                _kvRow('Initial Weight',
                                    _profile!['initial_weight']?.toString()),
                                _kvRow('Target Weight',
                                    _profile!['target_weight']?.toString()),
                                _kvRow('BMI', _profile!['bmi']?.toString()),
                                _kvRow('BMR', _profile!['bmr']?.toString()),
                                _kvRow(
                                    'Active Level', _profile!['active_level']),
                                _kvRow(
                                    'Fitness Goal', _profile!['fitness_goal']),
                                _kvRow('Experience',
                                    _profile!['experience_level']),
                                _kvRow('Equipment', _profile!['equipment']),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_summary != null) ...[
                        const Text('Summary',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _kvRow('Initial Weight',
                                    _summary!['initialWeight']?.toString()),
                                _kvRow('Current Weight',
                                    _summary!['currentWeight']?.toString()),
                                _kvRow('Target Weight',
                                    _summary!['targetWeight']?.toString()),
                                _kvRow(
                                    'Total Entries',
                                    _summary!['totalWeightEntries']
                                        ?.toString()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _kvRow(String k, String? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k), Text(v ?? '-')],
        ),
      );

  Widget _infoChip(String label, String? value) => Chip(
        label: Text('$label: ${value ?? '-'}'),
      );
}
