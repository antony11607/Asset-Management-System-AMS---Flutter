import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../widgets/user_widgets.dart';

class UserOwnedAsset {
  final String id;
  final String name;
  final String category;
  final String assignedDate;
  final String status;

  const UserOwnedAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.assignedDate,
    required this.status,
  });

  factory UserOwnedAsset.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserOwnedAsset(
      id: (data['assetCode'] ?? doc.id).toString(),
      name: (data['assetName'] ?? 'Asset').toString(),
      category: (data['assetCategory'] ?? 'Asset').toString(),
      assignedDate: (data['allocatedAt'] as Timestamp?) != null ? 'Allocated' : 'Allocated',
      status: (data['status'] ?? 'Allocated').toString(),
    );
  }
}

class UserMyAssetsPage extends StatefulWidget {
  const UserMyAssetsPage({super.key});

  @override
  State<UserMyAssetsPage> createState() => _UserMyAssetsPageState();
}

class _UserMyAssetsPageState extends State<UserMyAssetsPage> {
  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'maintenance requested') {
      return const Color(0xFFFF9800);
    } else if (normalized == 'maintenance' || normalized == 'under maintenance') {
      return const Color(0xFFFFA726);
    }
    return const Color(0xFF4CAF50);
  }

  bool _isApprovedAllocation(Map<String, dynamic> data) {
    final approved = data['approved'];
    if (approved is bool) {
      return approved;
    }
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    return status == 'approved' || status == 'allocated' || status == 'active' || status == 'maintenance requested' || status == 'under maintenance';
  }

  Future<void> _showReturnDialog(BuildContext context, DocumentSnapshot<Map<String, dynamic>> allocationDoc) async {
    final data = allocationDoc.data() ?? {};
    final currentQuantity = data['quantity'] ?? 1;
    int returnQuantity = currentQuantity;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Return Asset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Asset: ${data['assetName'] ?? 'Asset'}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('Current Quantity: $currentQuantity', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              if (currentQuantity > 1) ...[
                Text('Select quantity to return:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: returnQuantity > 1 ? () => setState(() => returnQuantity--) : null,
                      icon: const Icon(Icons.remove_circle),
                    ),
                    Text(
                      returnQuantity.toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: returnQuantity < currentQuantity ? () => setState(() => returnQuantity++) : null,
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => returnQuantity = currentQuantity),
                  child: const Text('Return All'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Return $returnQuantity'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('returnRequests').add({
        'allocationId': allocationDoc.id,
        'assetId': data['assetId'],
        'assetName': data['assetName'],
        'assetCode': data['assetCode'],
        'userId': data['userId'],
        'quantity': returnQuantity,
        'status': 'Pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Return request submitted for $returnQuantity unit(s)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to submit return request: $e')),
        );
      }
    }
  }

  Future<void> _showMaintenanceDialog(BuildContext context, DocumentSnapshot<Map<String, dynamic>> allocationDoc) async {
    final data = allocationDoc.data() ?? {};
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Maintenance'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asset: ${data['assetName'] ?? 'Asset'}', style: Theme.of(context).textTheme.bodyMedium),
                Text('Code: ${data['assetCode'] ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Description',
                    hintText: 'Describe the issue or service needed',
                  ),
                  maxLines: 4,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a description' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context);
              await _submitMaintenanceRequest(data, descriptionController.text.trim());
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitMaintenanceRequest(Map<String, dynamic> allocationData, String description) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to request maintenance.')),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('maintenanceRequests').add({
        'assetId': allocationData['assetId'],
        'assetName': allocationData['assetName'],
        'assetCode': allocationData['assetCode'],
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'User',
        'quantity': allocationData['quantity'] ?? 1,
        'description': description,
        'status': 'Pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance request submitted successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to submit maintenance request: $e')),
        );
      }
    }
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
          Text('Owned Assets', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Assets currently assigned to you.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('allocations').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Unable to load your allocated assets: ${snapshot.error}'),
                  ),
                );
              }

              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                return const Text('Please sign in to view your assets.');
              }

              final allocations = (snapshot.data?.docs ?? [])
                  .where((doc) => (doc.data()['userId'] ?? '') == uid && _isApprovedAllocation(doc.data()))
                  .toList()
                ..sort((a, b) {
                  final aTime = (a.data()['allocatedAt'] as Timestamp?)?.toDate();
                  final bTime = (b.data()['allocatedAt'] as Timestamp?)?.toDate();
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

              if (allocations.isEmpty) {
                return const Text('No approved allocated assets yet.');
              }

              return Column(
                children: allocations.map((doc) {
                  final data = doc.data();
                  final asset = UserOwnedAsset.fromDoc(doc);
                  final displayStatus = asset.status;
                  final statusColor = _statusColor(displayStatus);
                  final quantity = data['quantity'] ?? 1;
                  
                  // Check if there's a pending maintenance request for this allocation
                  final hasPendingMaintenance = data['status']?.toString().toLowerCase() == 'maintenance requested';
                  
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
                              child: Icon(Icons.inventory_2_outlined, color: Color(0xFF2555FF)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(asset.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Text('${asset.id} - ${asset.category} • Qty: $quantity', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color.lerp(statusColor, Colors.white, 0.86),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(displayStatus, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ],
                        ),
                        if (hasPendingMaintenance) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Color(0xFFFF9800)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Maintenance request pending approval',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF9800)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Assigned on ${asset.assignedDate}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                            ),
                            if (!hasPendingMaintenance)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'return') {
                                    _showReturnDialog(context, doc);
                                  } else if (value == 'maintenance') {
                                    _showMaintenanceDialog(context, doc);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'return',
                                    child: Row(
                                      children: [
                                        Icon(Icons.undo, size: 20),
                                        SizedBox(width: 12),
                                        Text('Return Asset'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'maintenance',
                                    child: Row(
                                      children: [
                                        Icon(Icons.build_circle_outlined, size: 20),
                                        SizedBox(width: 12),
                                        Text('Request Maintenance'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
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
          const UserBottomNavigation(selectedRoute: AppRoutes.userMyAssets),
    );
  }
}