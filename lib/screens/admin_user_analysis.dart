import 'package:flutter/material.dart';
import 'package:ai/services/api_service.dart';

class AdminUserAnalysis extends StatefulWidget {
  const AdminUserAnalysis({super.key});

  @override
  State<AdminUserAnalysis> createState() => _AdminUserAnalysisState();
}

class _AdminUserAnalysisState extends State<AdminUserAnalysis> {
  bool _loading = false;
  Map<String, dynamic>? _stats;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiService.instance.get('admin/getstats');
      final data = resp.data;
      if (data != null &&
          data['data'] != null &&
          data['data']['stats'] != null) {
        setState(
            () => _stats = Map<String, dynamic>.from(data['data']['stats']));
      } else {
        setState(() => _stats = null);
      }
    } catch (e) {
      setState(() => _stats = null);
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
      appBar: AppBar(title: const Text('User Analysis')),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_stats == null)
                ? const Center(child: Text('No analysis found'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.group),
                          title: const Text('Total Users'),
                          trailing: Text('${_stats!['total_users'] ?? '0'}'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.monitor_weight),
                          title: const Text('Average Weight'),
                          trailing: Text('${_stats!['average_weight'] ?? '-'}'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Goals',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: (_stats!['goals'] as List?)?.length ?? 0,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final goal = Map<String, dynamic>.from(
                                _stats!['goals'][index]);
                            return ListTile(
                              leading: const Icon(Icons.flag),
                              title: Text(goal['fitness_goal'] ?? '-'),
                              trailing: Text(goal['count']?.toString() ?? '0'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
