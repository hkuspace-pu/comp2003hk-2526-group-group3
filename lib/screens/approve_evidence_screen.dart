import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

// String _normalizeEvidenceUrl(String url) {
//   return url
//       .replaceAll('&amp;', '&')
//       .replaceAll('&#38;', '&')
//       .replaceAll('&quot;', '"')
//       .replaceAll('&#34;', '"');
// }

class ApproveEvidenceScreen extends StatefulWidget {
  const ApproveEvidenceScreen({Key? key}) : super(key: key);

  @override
  State<ApproveEvidenceScreen> createState() => _ApproveEvidenceScreenState();
}

class _ApproveEvidenceScreenState extends State<ApproveEvidenceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _statusFilter = 'pending';
  String? _busyDocPath;

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildEvidenceStream() {
    return _db
        .collectionGroup('activities')
        .where('hasEvidence', isEqualTo: true)
        .orderBy('loggedAt', descending: true)
        .snapshots();
  }

  Future<void> _approveEvidence(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) return;

    setState(() => _busyDocPath = doc.reference.path);
    try {
      await doc.reference.update({
        'evidenceStatus': 'approved',
        'evidenceReviewedAt': FieldValue.serverTimestamp(),
        'evidenceReviewedByUid': adminUid,
        'evidenceReviewNote': null,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidence approved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve evidence: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyDocPath = null);
    }
  }

  Future<void> _rejectEvidence(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) return;

    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDarkGrey,
        title: const Text(
          'Reject Evidence',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: Column(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textRed),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;

    setState(() => _busyDocPath = doc.reference.path);
    try {
      await doc.reference.update({
        'evidenceStatus': 'rejected',
        'evidenceReviewedAt': FieldValue.serverTimestamp(),
        'evidenceReviewedByUid': adminUid,
        'evidenceReviewNote': note.isEmpty ? null : note,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidence rejected.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject evidence: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyDocPath = null);
    }
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
                  future: _firestoreService.getUserRole(currentUser.uid),
                  builder: (context, roleSnapshot) {
                    if (!roleSnapshot.hasData) {
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
                      stream: _buildEvidenceStream(),
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

                        final docs = snapshot.data!.docs;
                        final pendingCount = docs
                            .where((doc) =>
                                (doc.data()['evidenceStatus'] ?? 'pending') ==
                                'pending')
                            .length;
                        final approvedCount = docs
                            .where((doc) =>
                                doc.data()['evidenceStatus'] == 'approved')
                            .length;
                        final rejectedCount = docs
                            .where((doc) =>
                                doc.data()['evidenceStatus'] == 'rejected')
                            .length;
                        final filteredDocs = _filterDocs(docs);

                        return ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            const SizedBox(height: 24),
                            const Text(
                              '🛂 Evidence Review Queue',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _StatusFilterCard(
                                          label: 'Pending',
                                          value: pendingCount.toString(),
                                          icon: Icons.hourglass_top,
                                          selected: _statusFilter == 'pending',
                                          color: AppColors.accentOrange,
                                          onTap: () => setState(
                                              () => _statusFilter = 'pending'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _StatusFilterCard(
                                          label: 'Approved',
                                          value: approvedCount.toString(),
                                          icon: Icons.verified,
                                          selected: _statusFilter == 'approved',
                                          color: const Color(0xFF22C55E),
                                          onTap: () => setState(
                                              () => _statusFilter = 'approved'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _StatusFilterCard(
                                          label: 'Rejected',
                                          value: rejectedCount.toString(),
                                          icon: Icons.cancel_outlined,
                                          selected: _statusFilter == 'rejected',
                                          color: const Color(0xFFFF4D67),
                                          onTap: () => setState(
                                              () => _statusFilter = 'rejected'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (filteredDocs.isEmpty)
                              Container(
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
                              )
                            else
                              ...filteredDocs.map(
                                (doc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _EvidenceCard(
                                    doc: doc,
                                    busy: _busyDocPath == doc.reference.path,
                                    statusColor: _statusColor(
                                      (doc.data()['evidenceStatus'] ??
                                              'pending')
                                          .toString(),
                                    ),
                                    formattedLoggedAt:
                                        _formatDate(doc.data()['loggedAt']),
                                    onApprove: () => _approveEvidence(doc),
                                    onReject: () => _rejectEvidence(doc),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
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
                Icon(
                  icon,
                  size: 18,
                  color: Colors.white,
                ),
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
    required this.doc,
    required this.busy,
    required this.statusColor,
    required this.formattedLoggedAt,
    required this.onApprove,
    required this.onReject,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool busy;
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
    final evidenceUrl = (data['evidenceUrl'] ?? '').toString();
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
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get(),
                      builder: (context, snapshot) {
                        final userData =
                            snapshot.data?.data() ?? const <String, dynamic>{};
                        final displayName =
                            (userData['displayName'] ?? 'Unknown User')
                                .toString();
                        final email =
                            (userData['email'] ?? 'No email').toString();
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
                    ),
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
            evidenceType: evidenceType,
            evidenceUrl: evidenceUrl,
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
                    style: const TextStyle(
                      color: AppColors.textWhite,
                    ),
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
                    onPressed: busy ? null : onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      foregroundColor: AppColors.accentOrange,
                      disabledBackgroundColor:
                          const Color(0xFF22C55E).withValues(alpha: 0.45),
                      disabledForegroundColor: Colors.white70,
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
                    onPressed: busy ? null : onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textRed,
                      foregroundColor: AppColors.textWhite,
                      disabledBackgroundColor:
                          const Color(0xFFFF4D67).withValues(alpha: 0.45),
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
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
          if (busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: AppColors.accentOrange,
              minHeight: 3,
            ),
          ],
        ],
      ),
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

class _EvidencePreview extends StatelessWidget {
  const _EvidencePreview({
    required this.evidenceType,
    required this.evidenceUrl,
  });

  final String evidenceType;
  final String evidenceUrl;

  @override
  Widget build(BuildContext context) {
    if (evidenceUrl.trim().isEmpty) {
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

    if (evidenceType == 'video') {
      return _VideoEvidencePlayer(url: evidenceUrl);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          evidenceUrl,
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
    } catch (e) {
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
