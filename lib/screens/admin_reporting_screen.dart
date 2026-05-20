import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';

import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

import 'csv_export_stub.dart' if (dart.library.html) 'csv_export_web.dart';

class AdminReportingScreen extends StatefulWidget {
  const AdminReportingScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportingScreen> createState() => _AdminReportingScreenState();
}

class _AdminReportingScreenState extends State<AdminReportingScreen> {
  List<Map<String, dynamic>> _userStats = [];

  String _sortBy = 'minutes';
  String _search = '';
  String _rangeFilter = '30d';

  Stream<QuerySnapshot<Map<String, dynamic>>> _activitiesStream() {
    return FirebaseFirestore.instance.collectionGroup('activities').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  bool _withinRange(DateTime date) {
    final now = DateTime.now();

    if (_rangeFilter == '7d') {
      return now.difference(date).inDays <= 7;
    }
    if (_rangeFilter == '30d') {
      return now.difference(date).inDays <= 30;
    }
    return true;
  }

  void _processData(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> activities,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users) {
    final userMap = {for (var u in users) u.id: u.data()};

    final stats = <String, Map<String, dynamic>>{};

    for (final doc in activities) {
      final data = doc.data();

      final uid = data['uid'];
      if (uid == null) continue;

      final ts = data['loggedAt'];
      DateTime? date;
      if (ts is Timestamp) date = ts.toDate();

      if (date == null || !_withinRange(date)) continue;

      final duration = (data['durationMinutes'] ?? 0) as int;

      stats.putIfAbsent(uid, () {
        final userData = userMap[uid] ?? {};
        return {
          'name': userData['displayName'] ?? 'Unknown',
          'email': userData['email'] ?? '-',
          'minutes': 0,
          'activity': 0,
        };
      });

      stats[uid]!['minutes'] += duration;
      stats[uid]!['activity'] += 1;
    }

    var list = stats.values.toList();

    list = list.where((u) {
      final name = u['name'].toString().toLowerCase();
      final email = u['email'].toString().toLowerCase();
      return name.contains(_search) || email.contains(_search);
    }).toList();

    list.sort((a, b) => _sortBy == 'minutes'
        ? b['minutes'].compareTo(a['minutes'])
        : b['activity'].compareTo(a['activity']));

    _userStats = list;
  }

  void _exportCSV() {
    final rows = [
      ['Name', 'Email', 'Minutes', 'Activities'],
      ..._userStats.map((u) => [
            u['name'],
            u['email'],
            u['minutes'].toString(),
            u['activity'].toString(),
          ])
    ];

    final csv = const ListToCsvConverter().convert(rows);

    downloadCSV(context, csv);
  }

  Widget _buildChart() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          barGroups: _userStats.take(5).toList().asMap().entries.map((e) {
            final user = e.value;

            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (user['minutes'] as int).toDouble(),
                  color: AppColors.accentOrange,
                  width: 16,
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Reports')),
      body: GradientBackground(
        child: SafeArea(
          child: StreamBuilder(
            stream: _activitiesStream(),
            builder: (context, activitySnapshot) {
              if (!activitySnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder(
                stream: _usersStream(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  _processData(
                      activitySnapshot.data!.docs, userSnapshot.data!.docs);

                  if (_userStats.isEmpty) {
                    return const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  hintStyle:
                                      const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: AppColors.primaryDarkGrey,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (v) =>
                                    setState(() => _search = v.toLowerCase()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: _sortBy,
                              items: const [
                                DropdownMenuItem(
                                    value: 'minutes', child: Text('Minutes')),
                                DropdownMenuItem(
                                    value: 'activity', child: Text('Activity')),
                              ],
                              onChanged: (v) => setState(() => _sortBy = v!),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: _rangeFilter,
                              items: const [
                                DropdownMenuItem(
                                    value: '7d', child: Text('7D')),
                                DropdownMenuItem(
                                    value: '30d', child: Text('30D')),
                                DropdownMenuItem(
                                    value: 'all', child: Text('All')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _rangeFilter = v!),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _exportCSV,
                              icon: const Icon(Icons.download),
                              label: const Text('CSV'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildChart(),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _headerRow(),
                            ..._userStats.map(_row),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.cardBackground,
      child: const Row(
        children: [
          Expanded(child: Text('Name')),
          Expanded(child: Text('Email')),
          Expanded(child: Text('Minutes')),
          Expanded(child: Text('Activity')),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> u) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      color: AppColors.primaryDarkGrey,
      child: Row(
        children: [
          Expanded(child: Text(u['name'])),
          Expanded(child: Text(u['email'])),
          Expanded(child: Text('${u['minutes']}')),
          Expanded(child: Text('${u['activity']}')),
        ],
      ),
    );
  }
}
