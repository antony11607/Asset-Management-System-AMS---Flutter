import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../widgets/user_widgets.dart';

class UserAssetRequest {
  final String id;
  final String asset;
  final String category;
  final String date;
  final String status;
  final String? remarks;

  const UserAssetRequest({
    required this.id,
    required this.asset,
    required this.category,
    required this.date,
    required this.status,
    this.remarks,
  });

  factory UserAssetRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'] as Timestamp?;
    String dateStr;
    if (createdAt != null) {
      final date = createdAt.toDate();
      dateStr = '${date.day}/${date.month}/${date.year}';
    } else {
      dateStr = 'Requested';
    }

    return UserAssetRequest(
      id: doc.id.substring(0, 6).toUpperCase(),
      asset: (data['assetName'] ?? 'Asset').toString(),
      category: (data['category'] ?? 'N/A').toString(),
      date: dateStr,
      status: (data['status'] ?? 'Pending').toString(),
      remarks: data['remarks']?.toString(),
    );
  }
}

class UserAssetRequestsPage extends StatelessWidget {
  const UserAssetRequestsPage({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFFFA726);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShaTechx - AMS'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text('My Requests', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Track your asset request status.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: () {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
              }
              return FirebaseFirestore.instance
                  .collection('assetRequests')
                  .where('userId', isEqualTo: uid)
                  .snapshots();
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                String errorMessage = 'Unable to load requests. Please try again.';
                if (error != null) {
                  errorMessage += '\n\nError: ${error.toString()}';
                }
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    errorMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                return const Text('Please sign in to see your requests.');
              }

              var requests = (snapshot.data?.docs ?? []);
              
              // Sort requests by createdAt timestamp (newest first)
              requests.sort((a, b) {
                final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate();
                final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate();
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              if (requests.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'No requests yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return Column(
                children: requests.map((doc) {
                  final request = UserAssetRequest.fromDoc(doc);
                  final statusColor = _statusColor(request.status);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE8F0FF),
                              child: Icon(Icons.assignment_outlined, color: Color(0xFF2555FF)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(request.asset, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('${request.id} • ${request.date}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color.lerp(statusColor, Colors.white, 0.86),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                request.status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        if (request.category != 'N/A') ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.category_outlined, size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text(
                                request.category,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                        if (request.remarks != null && request.remarks!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes_outlined, size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  request.remarks!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar:
          const UserBottomNavigation(selectedRoute: AppRoutes.userRequests),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              AppRoutes.logout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
