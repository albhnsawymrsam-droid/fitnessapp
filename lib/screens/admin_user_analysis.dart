import 'package:flutter/material.dart';
import 'package:ai/services/api_service.dart';

class AdminUserAnalysis extends StatefulWidget {
  const AdminUserAnalysis({super.key});

  @override
  State<AdminUserAnalysis> createState() => _AdminUserAnalysisState();
}

class _AdminUserAnalysisState extends State<AdminUserAnalysis> {
  final Color primaryGreen = const Color(0xFF2E8B57);
  final Color bgColor = const Color(0xFFF4F6F9);

  bool _loading = false;
  Map<String, dynamic>? _stats;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final resp = await ApiService.instance.get('admin/getstats');
      final data = resp.data;
      if (mounted) {
        if (data != null &&
            data['data'] != null &&
            data['data']['stats'] != null) {
          setState(
              () => _stats = Map<String, dynamic>.from(data['data']['stats']));
        } else {
          setState(() => _stats = null);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _stats = null);
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final String title = goal['fitness_goal'] ?? 'Unknown';
    final String count = goal['count']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.fitness_center_rounded, color: primaryGreen, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count,
            style: TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsList = _stats != null ? (_stats!['goals'] as List?) : null;
    final List<Map<String, dynamic>> processedGoals = [];
    int lossWeightCount = 0;

    if (goalsList != null) {
      for (var item in goalsList) {
        if (item == null) continue;
        final map = Map<String, dynamic>.from(item);
        final String goalName =
            (map['fitness_goal'] ?? '').toString().trim().toLowerCase();
        final int count = int.tryParse(map['count']?.toString() ?? '0') ?? 0;

        if (goalName == 'maintenance') {
          // شيلها مش عندنا ف المشروع
          continue;
        }

        if (goalName == 'lose_weight' ||
            goalName == 'lose weight' ||
            goalName == 'weight_loss' ||
            goalName == 'weight loss' ||
            goalName == 'loss_weight' ||
            goalName == 'loss weight') {
          lossWeightCount += count;
        } else {
          processedGoals.add(map);
        }
      }

      if (lossWeightCount > 0) {
        processedGoals.add({
          'fitness_goal': 'LOSS_WEIGHT',
          'count': lossWeightCount,
        });
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'User Analysis',
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
          : (_stats == null)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 65, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No analysis found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatCard(
                            'Total Users',
                            '${_stats!['total_users'] ?? '0'}',
                            Icons.people_alt_rounded,
                            primaryGreen,
                          ),
                          const SizedBox(width: 14),
                          _buildStatCard(
                            'Average Weight',
                            '${_stats!['average_weight'] ?? '-'} kg',
                            Icons.monitor_weight_rounded,
                            Colors.orange.shade800,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                        child: Row(
                          children: [
                            Icon(Icons.bar_chart_rounded,
                                color: primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Fitness Goals Breakdown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: processedGoals.isEmpty
                            ? Center(
                                child: Text(
                                  'No goal statistics found',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: processedGoals.length,
                                itemBuilder: (context, index) {
                                  return _buildGoalCard(processedGoals[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
