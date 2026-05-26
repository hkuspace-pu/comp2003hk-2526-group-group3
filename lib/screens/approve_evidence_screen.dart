import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class ApproveEvidenceScreen extends StatefulWidget {
  const ApproveEvidenceScreen({Key? key}) : super(key: key);

  @override
  State<ApproveEvidenceScreen> createState() => _ApproveEvidenceScreenState();
}

class _ApproveEvidenceScreenState extends State<ApproveEvidenceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final Future<String?> _roleFuture;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _evidenceStream;

  String _statusFilter = 'pending';

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _roleFuture = currentUser == null
        ? Future<String?>.value(null)
        : _firestoreService.getUserRole(currentUser.uid);
    _evidenceStream = _buildEvidenceStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildEvidenceStream() {
    return _db
        .collectionGroup('activities')
        .orderBy('loggedAt', descending: true)
        .snapshots();
  }

  bool _hasEvidenceData(Map<String, dynamic> data) {
    final explicitHasEvidence = data['hasEvidence'] == true;
    final possibleRefs = [
      data['photoUrl'],
      data['evidenceUrl'],
      data['photoGsUrl'],
      data['evidenceGsUrl'],
      data['photoStoragePath'],
      data['evidenceStoragePath'],
    ];

    return explicitHasEvidence ||
        possibleRefs.any(
          (value) => value != null && value.toString().trim().isNotEmpty,
        );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _evidenceDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) => _hasEvidenceData(doc.data())).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final status = (data['evidenceStatus'] ?? 'pending').toString();
      return status == _statusFilter;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF22C55E);
      case 'rejected':
        return const Color(0xFFFF4D67);
      default:
        return AppColors.accentOrange;
    }
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

  Future<void> _approveEvidence(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      await doc.reference.update({
        'evidenceStatus': 'approved',
        'evidenceReviewedAt': FieldValue.serverTimestamp(),
        'evidenceReviewedByUid': adminUid,
        'evidenceReviewNote': null,
      });

      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Evidence approved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text('Failed to approve evidence: $e')),
      );
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.primaryDarkGrey,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            title: const Text(
              'Reject Evidence',
              style: TextStyle(color: AppColors.textWhite),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Optionally tell the user why the evidence was rejected.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: InputDecoration(
                        hintText: 'Reason for rejection',
                        hintStyle: const TextStyle(color: AppColors.textGrey),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(dialogContext).pop(text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textRed,
                  foregroundColor: AppColors.textWhite,
                ),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _rejectEvidence(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null || !mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final note = await _showRejectDialog();
    if (!mounted || note == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      await doc.reference.update({
        'evidenceStatus': 'rejected',
        'evidenceReviewedAt': FieldValue.serverTimestamp(),
        'evidenceReviewedByUid': adminUid,
        'evidenceReviewNote': note.isEmpty ? null : note,
      });

      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Evidence rejected.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text('Failed to reject evidence: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Evidence'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: currentUser == null
              ? const Center(
                  child: Text(
                    'Please sign in again.',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : FutureBuilder<String?>(
                  future: _roleFuture,
                  builder: (context, roleSnapshot) {
                    if (roleSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentOrange,
                        ),
                      );
                    }

                    if (roleSnapshot.data != 'admin') {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Only admin users can review uploaded evidence.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _evidenceStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Failed to load evidence:\n${snapshot.error}',
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

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentOrange,
                            ),
                          );
                        }

                        final docs = _evidenceDocs(snapshot.data!.docs);
                        final pendingCount = docs
                            .where(
                              (doc) =>
                                  (doc.data()['evidenceStatus'] ?? 'pending') ==
                                  'pending',
                            )
                            .length;
                        final approvedCount = docs
                            .where(
                              (doc) =>
                                  doc.data()['evidenceStatus'] == 'approved',
                            )
                            .length;
                        final rejectedCount = docs
                            .where(
                              (doc) =>
                                  doc.data()['evidenceStatus'] == 'rejected',
                            )
                            .length;
                        final filteredDocs = _filterDocs(docs);

                        return ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredDocs.length + 3,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 24, bottom: 12),
                                child: Text(
                                  '🛂 Evidence Review Queue',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            if (index == 1) {
                              return _EvidenceStatusPanel(
                                statusFilter: _statusFilter,
                                pendingCount: pendingCount,
                                approvedCount: approvedCount,
                                rejectedCount: rejectedCount,
                                onFilterChanged: (value) {
                                  if (!mounted) return;
                                  setState(() => _statusFilter = value);
                                },
                              );
                            }

                            if (filteredDocs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'No evidence found for the selected review status.',
                                    style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final docIndex = index - 2;
                            if (docIndex < 0 ||
                                docIndex >= filteredDocs.length) {
                              return const SizedBox(height: 24);
                            }

                            final doc = filteredDocs[docIndex];
                            final data = doc.data();
                            final status = (data['evidenceStatus'] ?? 'pending')
                                .toString();

                            return Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: _EvidenceCard(
                                key: ValueKey(doc.reference.path),
                                doc: doc,
                                statusColor: _statusColor(status),
                                formattedLoggedAt:
                                    _formatDate(data['loggedAt']),
                                onApprove: () => _approveEvidence(doc),
                                onReject: () => _rejectEvidence(doc),
                              ),
                            );
                          },
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

class _EvidenceStatusPanel extends StatelessWidget {
  const _EvidenceStatusPanel({
    required this.statusFilter,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.onFilterChanged,
  });

  final String statusFilter;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatusFilterCard(
              label: 'Pending',
              value: pendingCount.toString(),
              icon: Icons.hourglass_top,
              selected: statusFilter == 'pending',
              color: AppColors.accentOrange,
              onTap: () => onFilterChanged('pending'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatusFilterCard(
              label: 'Approved',
              value: approvedCount.toString(),
              icon: Icons.verified,
              selected: statusFilter == 'approved',
              color: const Color(0xFF22C55E),
              onTap: () => onFilterChanged('approved'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatusFilterCard(
              label: 'Rejected',
              value: rejectedCount.toString(),
              icon: Icons.cancel_outlined,
              selected: statusFilter == 'rejected',
              color: const Color(0xFFFF4D67),
              onTap: () => onFilterChanged('rejected'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterCard extends StatelessWidget {
  const _StatusFilterCard({
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
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    super.key,
    required this.doc,
    required this.statusColor,
    required this.formattedLoggedAt,
    required this.onApprove,
    required this.onReject,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Color statusColor;
  final String formattedLoggedAt;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final uid = (data['uid'] ?? '').toString();
    final status = (data['evidenceStatus'] ?? 'pending').toString();
    final evidenceType = (data['evidenceType'] ?? 'image').toString();
    final evidenceRef = (data['photoUrl'] ??
            data['evidenceUrl'] ??
            data['photoGsUrl'] ??
            data['evidenceGsUrl'] ??
            data['photoStoragePath'] ??
            data['evidenceStoragePath'] ??
            '')
        .toString();
    final activityType =
        (data['activityType'] ?? 'Unknown Activity').toString();
    final mood = (data['mood'] ?? '-').toString();
    final notes = (data['notes'] ?? '').toString();
    final durationMinutes = (data['durationMinutes'] ?? 0).toString();
    final reviewNote = (data['evidenceReviewNote'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  evidenceType == 'video' ? Icons.videocam : Icons.image,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UserInfo(uid: uid),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PillTag(
                          label: status.toUpperCase(),
                          color: statusColor,
                        ),
                        _PillTag(
                          label: evidenceType.toUpperCase(),
                          color: const Color(0xFF3B82F6),
                        ),
                        _PillTag(
                          label: activityType,
                          color: AppColors.primaryDarkGrey,
                        ),
                        _PillTag(
                          label: '$durationMinutes min • $mood',
                          color: const Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Uploaded: $formattedLoggedAt',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notes,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _EvidencePreview(
            key: ValueKey(evidenceRef),
            evidenceType: evidenceType,
            evidenceRef: evidenceRef,
          ),
          if (reviewNote.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status == 'rejected' ? 'Rejection Note' : 'Review Note',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reviewNote,
                    style: const TextStyle(color: AppColors.textWhite),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      foregroundColor: AppColors.accentOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Approve',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textRed,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Reject',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'approved'
                        ? Icons.verified
                        : Icons.cancel_outlined,
                    color: statusColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status == 'approved'
                          ? 'This evidence has already been approved.'
                          : 'This evidence has already been rejected.',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
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

class _UserInfo extends StatefulWidget {
  const _UserInfo({required this.uid});

  final String uid;

  @override
  State<_UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<_UserInfo> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() ?? const <String, dynamic>{};
        final displayName =
            (userData['displayName'] ?? 'Unknown User').toString();
        final email = (userData['email'] ?? 'No email').toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EvidencePreview extends StatefulWidget {
  const _EvidencePreview({
    super.key,
    required this.evidenceType,
    required this.evidenceRef,
  });

  final String evidenceType;
  final String evidenceRef;

  @override
  State<_EvidencePreview> createState() => _EvidencePreviewState();
}

class _EvidencePreviewState extends State<_EvidencePreview> {
  static const String _activityPhotosBucketUrl =
      'gs://focus-aquarium.firebasestorage.app';

  late Future<String> _downloadUrlFuture;

  @override
  void initState() {
    super.initState();
    _downloadUrlFuture = _resolveDownloadUrl(widget.evidenceRef);
  }

  @override
  void didUpdateWidget(covariant _EvidencePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evidenceRef != widget.evidenceRef) {
      _downloadUrlFuture = _resolveDownloadUrl(widget.evidenceRef);
    }
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<String> _resolveDownloadUrl(String value) async {
    final refValue = value.trim();
    if (refValue.isEmpty) return '';

    if (_isHttpUrl(refValue)) return refValue;

    if (refValue.startsWith('gs://')) {
      return FirebaseStorage.instance.refFromURL(refValue).getDownloadURL();
    }

    final storage = FirebaseStorage.instanceFor(
      bucket: _activityPhotosBucketUrl,
    );
    return storage.ref(refValue).getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.evidenceRef.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Evidence URL is missing for this record.',
          style: TextStyle(color: AppColors.textGrey),
        ),
      );
    }

    return FutureBuilder<String>(
      future: _downloadUrlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: AppColors.accentOrange,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Failed to load evidence from Storage: ${snapshot.error ?? 'missing download URL'}',
              style: const TextStyle(color: AppColors.textGrey),
            ),
          );
        }

        final downloadUrl = snapshot.data!;
        if (widget.evidenceType == 'video') {
          return _VideoEvidencePlayer(url: downloadUrl);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              downloadUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
                alignment: Alignment.center,
                child: const Text(
                  'Failed to load image evidence.',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VideoEvidencePlayer extends StatefulWidget {
  const _VideoEvidencePlayer({required this.url});

  final String url;

  @override
  State<_VideoEvidencePlayer> createState() => _VideoEvidencePlayerState();
}

class _VideoEvidencePlayerState extends State<_VideoEvidencePlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();
      controller.setLooping(true);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load video evidence.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.accentOrange),
      );
    }

    if (_error != null || _controller == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryDarkGrey.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _error ?? 'Unable to preview video evidence.',
          style: const TextStyle(color: AppColors.textGrey),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                label: Text(
                  _controller!.value.isPlaying ? 'Pause Video' : 'Play Video',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
