import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class AdminReportingScreen extends StatefulWidget {
  const AdminReportingScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportingScreen> createState() => _AdminReportingScreenState();
}

class _AdminReportingScreenState extends State<AdminReportingScreen> {
  String _rangeFilter = '30d';

  Stream<QuerySnapshot<Map<String, dynamic>>> _activitiesStream() {
    return FirebaseFirestore.instance
        .collectionGroup('activities')
        .orderBy('loggedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  bool _matchesRange(dynamic loggedAt) {
    if (_rangeFilter == 'all') return true;

    DateTime? dateTime;
    if (loggedAt is Timestamp) {
      dateTime = loggedAt.toDate();
    } else if (loggedAt is DateTime) {
      dateTime = loggedAt;
    }

    if (dateTime == null) return false;

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (_rangeFilter == '7d') {
      return difference.inDays <= 7;
    }
    if (_rangeFilter == '30d') {
      return difference.inDays <= 30;
    }
    return true;
  }

  String _formatDate(dynamic value) {
    DateTime? dateTime;
    if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is DateTime) {
      dateTime = value;
    }

    if (dateTime == null) return 'Unknown';

    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _activitiesStream(),
            builder: (context, activitySnapshot) {
              if (activitySnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load activity reports:\n${activitySnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              if (!activitySnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentOrange,
                  ),
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _usersStream(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load user data:\n${userSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  if (!userSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentOrange,
                      ),
                    );
                  }

                  final allActivities = activitySnapshot.data!.docs
                      .where((doc) => _matchesRange(doc.data()['loggedAt']))
                      .toList();

                  final allUsers = userSnapshot.data!.docs;

                  final userMap = <String, Map<String, dynamic>>{};
                  for (final userDoc in allUsers) {
                    userMap[userDoc.id] = userDoc.data();
                  }

                  final totalUsers = allUsers.length;
                  final totalActivities = allActivities.length;

                  int totalMinutes = 0;
                  int evidenceSubmitted = 0;
                  int evidenceApproved = 0;
                  int evidenceRejected = 0;
                  int pendingEvidence = 0;

                  final activityTypeCount = <String, int>{};
                  final userActivityCount = <String, int>{};
                  final userMinutesCount = <String, int>{};

                  for (final doc in allActivities) {
                    final data = doc.data();

                    final uid = (data['uid'] ?? '').toString();
                    final activityType =
                        (data['activityType'] ?? 'Unknown').toString();
                    final durationMinutes =
                        (data['durationMinutes'] ?? 0) as int? ?? 0;
                    final hasEvidence = data['hasEvidence'] == true;
                    final evidenceStatus =
                        (data['evidenceStatus'] ?? 'pending').toString();

                    totalMinutes += durationMinutes;

                    activityTypeCount[activityType] =
                        (activityTypeCount[activityType] ?? 0) + 1;

                    if (uid.isNotEmpty) {
                      userActivityCount[uid] =
                          (userActivityCount[uid] ?? 0) + 1;
                      userMinutesCount[uid] =
                          (userMinutesCount[uid] ?? 0) + durationMinutes;
                    }

                    if (hasEvidence) {
                      evidenceSubmitted++;
                      if (evidenceStatus == 'approved') {
                        evidenceApproved++;
                      } else if (evidenceStatus == 'rejected') {
                        evidenceRejected++;
                      } else {
                        pendingEvidence++;
                      }
                    }
                  }

                  final sortedActivityTypes = activityTypeCount.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  final topUsers = userActivityCount.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  final recentActivities = [...allActivities]..sort((a, b) {
                      final aTime = a.data()['loggedAt'];
                      final bTime = b.data()['loggedAt'];

                      DateTime? aDate;
                      DateTime? bDate;

                      if (aTime is Timestamp) aDate = aTime.toDate();
                      if (bTime is Timestamp) bDate = bTime.toDate();

                      return (bDate ?? DateTime(1970))
                          .compareTo(aDate ?? DateTime(1970));
                    });

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            const Text(
                              '📊 Admin Reporting Center',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Track user engagement, activity trends, and evidence review performance.',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _RangeFilterCard(
                                      label: 'Last 7 Days',
                                      value: '7D',
                                      icon: Icons.date_range,
                                      selected: _rangeFilter == '7d',
                                      color: AppColors.accentOrange,
                                      onTap: () {
                                        setState(() => _rangeFilter = '7d');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _RangeFilterCard(
                                      label: 'Last 30 Days',
                                      value: '30D',
                                      icon: Icons.calendar_month,
                                      selected: _rangeFilter == '30d',
                                      color: const Color(0xFF3B82F6),
                                      onTap: () {
                                        setState(() => _rangeFilter = '30d');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _RangeFilterCard(
                                      label: 'All Time',
                                      value: 'ALL',
                                      icon: Icons.all_inclusive,
                                      selected: _rangeFilter == 'all',
                                      color: const Color(0xFF7C3AED),
                                      onTap: () {
                                        setState(() => _rangeFilter = 'all');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _MetricCard(
                                  title: 'Total Users',
                                  value: totalUsers.toString(),
                                  icon: Icons.people_alt_outlined,
                                  color: const Color(0xFF3B82F6),
                                ),
                                _MetricCard(
                                  title: 'Activities Logged',
                                  value: totalActivities.toString(),
                                  icon: Icons.checklist_rounded,
                                  color: AppColors.accentOrange,
                                ),
                                _MetricCard(
                                  title: 'Focus Minutes',
                                  value: totalMinutes.toString(),
                                  icon: Icons.timer_outlined,
                                  color: const Color(0xFF22C55E),
                                ),
                                _MetricCard(
                                  title: 'Evidence Submitted',
                                  value: evidenceSubmitted.toString(),
                                  icon: Icons.verified_outlined,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _ReportSectionCard(
                                    title: 'Evidence Review Summary',
                                    child: Column(
                                      children: [
                                        _SummaryRow(
                                          label: 'Pending',
                                          value: pendingEvidence.toString(),
                                          color: AppColors.accentOrange,
                                        ),
                                        const SizedBox(height: 10),
                                        _SummaryRow(
                                          label: 'Approved',
                                          value: evidenceApproved.toString(),
                                          color: const Color(0xFF22C55E),
                                        ),
                                        const SizedBox(height: 10),
                                        _SummaryRow(
                                          label: 'Rejected',
                                          value: evidenceRejected.toString(),
                                          color: const Color(0xFFFF4D67),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ReportSectionCard(
                                    title: 'Top Activity Types',
                                    child: sortedActivityTypes.isEmpty
                                        ? const _EmptyStateText(
                                            text:
                                                'No activity data found for the selected range.',
                                          )
                                        : Column(
                                            children: sortedActivityTypes
                                                .take(5)
                                                .map(
                                                  (entry) => _ActivityTypeRow(
                                                    label: entry.key,
                                                    count: entry.value,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _ReportSectionCard(
                              title: 'Top Active Users',
                              child: topUsers.isEmpty
                                  ? const _EmptyStateText(
                                      text:
                                          'No active users found for the selected range.',
                                    )
                                  : Column(
                                      children: topUsers.take(5).map((entry) {
                                        final uid = entry.key;
                                        final count = entry.value;
                                        final userData =
                                            userMap[uid] ?? <String, dynamic>{};
                                        final displayName =
                                            (userData['displayName'] ??
                                                    'Unknown User')
                                                .toString();
                                        final email =
                                            (userData['email'] ?? 'No email')
                                                .toString();
                                        final minutes =
                                            userMinutesCount[uid] ?? 0;

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _TopUserTile(
                                            displayName: displayName,
                                            email: email,
                                            activityCount: count,
                                            totalMinutes: minutes,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            _ReportSectionCard(
                              title: 'Recent Activity Logs',
                              child: recentActivities.isEmpty
                                  ? const _EmptyStateText(
                                      text:
                                          'No recent activity logs in the selected range.',
                                    )
                                  : Column(
                                      children:
                                          recentActivities.take(8).map((doc) {
                                        final data = doc.data();
                                        final uid =
                                            (data['uid'] ?? '').toString();
                                        final activityType =
                                            (data['activityType'] ?? 'Unknown')
                                                .toString();
                                        final durationMinutes =
                                            (data['durationMinutes'] ?? 0)
                                                    as int? ??
                                                0;
                                        final mood =
                                            (data['mood'] ?? '-').toString();
                                        final hasEvidence =
                                            data['hasEvidence'] == true;
                                        final loggedAt =
                                            _formatDate(data['loggedAt']);

                                        final userData =
                                            userMap[uid] ?? <String, dynamic>{};
                                        final displayName =
                                            (userData['displayName'] ??
                                                    'Unknown User')
                                                .toString();

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _RecentActivityTile(
                                            displayName: displayName,
                                            activityType: activityType,
                                            mood: mood,
                                            durationMinutes: durationMinutes,
                                            hasEvidence: hasEvidence,
                                            loggedAt: loggedAt,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RangeFilterCard extends StatelessWidget {
  const _RangeFilterCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.95)
              : AppColors.primaryDarkGrey.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? color : AppColors.textWhite.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 362,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  const _ReportSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTypeRow extends StatelessWidget {
  const _ActivityTypeRow({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentOrange,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopUserTile extends StatelessWidget {
  const _TopUserTile({
    required this.displayName,
    required this.email,
    required this.activityCount,
    required this.totalMinutes,
  });

  final String displayName;
  final String email;
  final int activityCount;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_outline,
              color: AppColors.accentOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$activityCount logs',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalMinutes min',
                style: const TextStyle(
                  color: AppColors.accentOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({
    required this.displayName,
    required this.activityType,
    required this.mood,
    required this.durationMinutes,
    required this.hasEvidence,
    required this.loggedAt,
  });

  final String displayName;
  final String activityType;
  final String mood;
  final int durationMinutes;
  final bool hasEvidence;
  final String loggedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: hasEvidence
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
                  : AppColors.accentOrange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasEvidence ? Icons.verified_outlined : Icons.schedule,
              color: hasEvidence
                  ? const Color(0xFF7C3AED)
                  : AppColors.accentOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniTag(
                      label: activityType,
                      color: AppColors.primaryDarkGrey,
                    ),
                    _MiniTag(
                      label: '$durationMinutes min',
                      color: const Color(0xFF22C55E),
                    ),
                    _MiniTag(
                      label: mood,
                      color: const Color(0xFF3B82F6),
                    ),
                    if (hasEvidence)
                      const _MiniTag(
                        label: 'Evidence',
                        color: Color(0xFF7C3AED),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loggedAt,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyStateText extends StatelessWidget {
  const _EmptyStateText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textGrey,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
