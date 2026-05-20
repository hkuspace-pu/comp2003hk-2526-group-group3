import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class AdminReportingScreen extends StatefulWidget {
  const AdminReportingScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportingScreen> createState() => _AdminReportingScreenState();
}

class _AdminReportingScreenState extends State<AdminReportingScreen> {
  List<Map<String, dynamic>> _userStats = [];
  String _sortBy = 'minutes';

  Stream<QuerySnapshot<Map<String, dynamic>>> _activitiesStream() {
    return FirebaseFirestore.instance.collectionGroup('activities').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  void _processData(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> activities,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> users) {
    final userMap = {
      for (final u in users) u.id: u.data(),
    };

    final stats = <String, Map<String, dynamic>>{};

    for (final doc in activities) {
      final data = doc.data();
      final uid = data['uid'];

      if (uid == null) continue;

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

    final list = stats.values.toList();

    list.sort((a, b) => _sortBy == 'minutes'
        ? b['minutes'].compareTo(a['minutes'])
        : b['activity'].compareTo(a['activity']));

    _userStats = list;
  }

  void _exportCSV() {
    final List<List<String>> rows = [
      ['Name', 'Email', 'Minutes', 'Activities'],
      ..._userStats.map((u) => [
            u['name'],
            u['email'],
            u['minutes'].toString(),
            u['activity'].toString(),
          ])
    ];

    final csv = const ListToCsvConverter().convert(rows);

    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "report.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
      ),
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

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            DropdownButton<String>(
                              value: _sortBy,
                              dropdownColor: AppColors.cardBackground,
                              items: const [
                                DropdownMenuItem(
                                  value: 'minutes',
                                  child: Text('Sort by Minutes'),
                                ),
                                DropdownMenuItem(
                                  value: 'activity',
                                  child: Text('Sort by Activity'),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _sortBy = val!;
                                });
                              },
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _exportCSV,
                              icon: const Icon(Icons.download),
                              label: const Text('Export CSV'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildHeaderRow(),
                            ..._userStats.map((u) => _buildRow(u)),
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

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('Name')),
          Expanded(child: Text('Email')),
          Expanded(child: Text('Minutes')),
          Expanded(child: Text('Activities')),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> u) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGrey,
        borderRadius: BorderRadius.circular(8),
      ),
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
