import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/admin_widgets.dart';
import '../services/excel_export_service.dart';

class AdminAsset {
  final String uid;
  final String name;
  final String code;
  final String assignedTo;
  final String status;
  final int quantity;
  final Timestamp? createdAt;

  const AdminAsset({
    required this.uid,
    required this.name,
    required this.code,
    required this.assignedTo,
    required this.status,
    required this.quantity,
    required this.createdAt,
  });

  factory AdminAsset.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final quantity = int.tryParse((data['quantity'] ?? '0').toString()) ?? 0;
    final status = (data['status'] ?? '').toString().trim();
    return AdminAsset(
      uid: doc.id,
      name: (data['name'] ?? '').toString().trim(),
      code: (data['code'] ?? '').toString().trim(),
      assignedTo: (data['assignedTo'] ?? '').toString().trim(),
      status: status.isEmpty ? (quantity > 0 ? 'Available' : 'Unavailable') : status,
      quantity: quantity,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  bool get isAvailable => quantity > 0;

  String get availabilityLabel => isAvailable ? 'Available' : 'Unavailable';

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'allocated':
        return const Color(0xFF2196F3);
      case 'under maintenance':
        return const Color(0xFFFF9800);
      case 'available':
      case 'unavailable':
      default:
        return isAvailable ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    }
  }
}

class AdminRequest {
  final String id;
  final String item;
  final String user;
  final String status;
  final Color statusColor;

  const AdminRequest({
    required this.id,
    required this.item,
    required this.user,
    required this.status,
    required this.statusColor,
  });
}

class AdminUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String status;
  final bool approved;
  final String employeeId;
  final String phone;
  final String username;
  final Timestamp? createdAt;

  const AdminUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.approved,
    required this.employeeId,
    required this.phone,
    required this.username,
    required this.createdAt,
  });

  factory AdminUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminUser(
      uid: doc.id,
      name: (data['name'] ?? '').toString().trim(),
      email: (data['email'] ?? '').toString().trim(),
      role: (data['role'] ?? 'User').toString().trim(),
      status: (data['status'] ?? 'Pending').toString().trim(),
      approved: data['approved'] == true,
      employeeId: (data['employeeId'] ?? '').toString().trim(),
      phone: (data['phone'] ?? '').toString().trim(),
      username: (data['username'] ?? '').toString().trim(),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}

const List<AdminRequest> demoAssetRequests = [
  AdminRequest(id: 'REQ-001', item: 'Laptop', user: 'John Doe', status: 'Pending', statusColor: Color(0xFFFFC107)),
  AdminRequest(id: 'REQ-002', item: 'Monitor', user: 'Jane Smith', status: 'Pending', statusColor: Color(0xFFFFC107)),
  AdminRequest(id: 'REQ-003', item: 'Printer', user: 'Robert Brown', status: 'Approved', statusColor: Color(0xFF4CAF50)),
  AdminRequest(id: 'REQ-004', item: 'Laptop', user: 'Emily Davis', status: 'Rejected', statusColor: Color(0xFFF44336)),
];

const List<AdminRequest> demoMaintenanceRequests = [
  AdminRequest(id: 'MNT-001', item: 'Laptop', user: 'John Doe', status: 'In Progress', statusColor: Color(0xFF2196F3)),
  AdminRequest(id: 'MNT-002', item: 'Printer', user: 'Jane Smith', status: 'Assigned', statusColor: Color(0xFF42A5F5)),
  AdminRequest(id: 'MNT-003', item: 'Monitor', user: 'Robert Brown', status: 'Completed', statusColor: Color(0xFF4CAF50)),
  AdminRequest(id: 'MNT-004', item: 'Laptop', user: 'Emily Davis', status: 'Requested', statusColor: Color(0xFF9C27B0)),
];

class AdminOverviewPage extends StatelessWidget {
  final ValueChanged<int> onPageSelected;

  const AdminOverviewPage({
    super.key,
    required this.onPageSelected,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFE53935);
      case 'pending':
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF1976D2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnapshot) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('assets').snapshots(),
                builder: (context, assetsSnapshot) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('assetRequests').snapshots(),
                    builder: (context, requestsSnapshot) {
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance.collection('allocations').snapshots(),
                        builder: (context, allocationsSnapshot) {
                          if (usersSnapshot.connectionState == ConnectionState.waiting ||
                              assetsSnapshot.connectionState == ConnectionState.waiting ||
                              requestsSnapshot.connectionState == ConnectionState.waiting ||
                              allocationsSnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 180,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (usersSnapshot.hasError || assetsSnapshot.hasError || requestsSnapshot.hasError || allocationsSnapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: adminPanelDecoration(),
                              child: const Text('Unable to load dashboard statistics.'),
                            );
                          }

                          final users = usersSnapshot.data?.docs ?? [];
                          final assets = assetsSnapshot.data?.docs ?? [];
                          final requests = requestsSnapshot.data?.docs ?? [];
                          final allocations = allocationsSnapshot.data?.docs ?? [];

                          final totalUsers = users.length;
                          final pendingUsers = users.where((doc) {
                            final status = (doc.data()['status'] ?? 'Pending').toString().trim().toLowerCase();
                            return status == 'pending' || doc.data()['approved'] != true;
                          }).length;
                          final approvedUsers = users.where((doc) {
                            final approved = doc.data()['approved'] == true;
                            final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
                            return approved || status == 'active';
                          }).length;
                          final rejectedUsers = users.where((doc) {
                            final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
                            return status == 'inactive';
                          }).length;

                          final totalAssets = assets.fold<int>(0, (sum, doc) {
                            final quantity = int.tryParse((doc.data()['quantity'] ?? '0').toString()) ?? 0;
                            return sum + quantity;
                          });
                          final availableAssets = assets.where((doc) {
                            final quantity = int.tryParse((doc.data()['quantity'] ?? '0').toString()) ?? 0;
                            return quantity > 0;
                          }).fold<int>(0, (sum, doc) {
                            final quantity = int.tryParse((doc.data()['quantity'] ?? '0').toString()) ?? 0;
                            return sum + quantity;
                          });
                          
                          // Get all active allocations (excluding returned and under maintenance)
                          final activeAllocations = allocations.where((doc) {
                            final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
                            return status == 'allocated' || status == 'approved';
                          }).toList();
                          
                          // Allocated Assets = count of unique assets currently allocated to users
                          // Exclude assets that are under maintenance
                          final allocatedAssetIds = <String>{};
                          for (final allocation in activeAllocations) {
                            final assetId = allocation.data()['assetId']?.toString();
                            if (assetId != null) {
                              // Find the asset document by iterating
                              QueryDocumentSnapshot<Map<String, dynamic>>? assetDoc;
                              for (final doc in assets) {
                                if (doc.id == assetId) {
                                  assetDoc = doc;
                                  break;
                                }
                              }
                              if (assetDoc != null) {
                                final assetStatus = (assetDoc.data()['status'] ?? '').toString().trim().toLowerCase();
                                // Only count if asset is not under maintenance
                                if (assetStatus != 'under maintenance' && assetStatus != 'maintenance') {
                                  allocatedAssetIds.add(assetId);
                                }
                              }
                            }
                          }
                          final allocatedAssets = allocatedAssetIds.length;
                          
                          // Assets Under Maintenance = assets with maintenance status
                          final underMaintenanceAssets = assets.where((doc) {
                            final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
                            return status == 'under maintenance' || status == 'maintenance';
                          }).length;

                          final pendingAssetRequests = requests.where((doc) {
                            final status = (doc.data()['status'] ?? 'Pending').toString().trim().toLowerCase();
                            final type = (doc.data()['requestType'] ?? doc.data()['type'] ?? '').toString().trim().toLowerCase();
                            return status == 'pending' && type != 'maintenance' && type != 'maintenance request';
                          }).length;
                          final pendingMaintenanceRequests = requests.where((doc) {
                            final status = (doc.data()['status'] ?? 'Pending').toString().trim().toLowerCase();
                            final type = (doc.data()['requestType'] ?? doc.data()['type'] ?? '').toString().trim().toLowerCase();
                            return status == 'pending' && (type == 'maintenance' || type == 'maintenance request');
                          }).length;

                          return Column(
                            children: [
                              AdminOverviewGrid(
                                children: [
                                  AdminOverviewCard(title: 'Total Users', value: totalUsers.toString(), icon: Icons.group_outlined, color: const Color(0xFFE8F6FF)),
                                  AdminOverviewCard(title: 'Pending Users', value: pendingUsers.toString(), icon: Icons.person_add_alt_outlined, color: const Color(0xFFFFEFEE)),
                                  AdminOverviewCard(title: 'Total Assets', value: totalAssets.toString(), icon: Icons.inventory_2, color: const Color(0xFFE3EDFF)),
                                  AdminOverviewCard(title: 'Available Assets', value: availableAssets.toString(), icon: Icons.check_circle_outline, color: const Color(0xFFE8F7ED)),
                                  AdminOverviewCard(title: 'Allocated Assets', value: allocatedAssets.toString(), icon: Icons.person_outline, color: const Color(0xFFFFF2E8)),
                                  AdminOverviewCard(title: 'Assets Under Maintenance', value: underMaintenanceAssets.toString(), icon: Icons.build_circle_outlined, color: const Color(0xFFF1F1FF)),
                                  AdminOverviewCard(title: 'Pending Asset Requests', value: pendingAssetRequests.toString(), icon: Icons.pending_actions_outlined, color: const Color(0xFFFFEFEE)),
                                  AdminOverviewCard(title: 'Pending Maintenance Requests', value: pendingMaintenanceRequests.toString(), icon: Icons.handyman_outlined, color: const Color(0xFFE8F0FF)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth > 600) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(18),
                                            decoration: adminPanelDecoration(),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('User Registrations', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  height: 180,
                                                  child: PieChart(
                                                    PieChartData(
                                                      sectionsSpace: 2,
                                                      centerSpaceRadius: 50,
                                                      sections: [
                                                        PieChartSectionData(
                                                          value: pendingUsers.toDouble(),
                                                          color: const Color(0xFFFFC107),
                                                          title: pendingUsers.toString(),
                                                          radius: 60,
                                                          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                                        ),
                                                        PieChartSectionData(
                                                          value: approvedUsers.toDouble(),
                                                          color: const Color(0xFF4CAF50),
                                                          title: approvedUsers.toString(),
                                                          radius: 60,
                                                          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                                        ),
                                                        PieChartSectionData(
                                                          value: rejectedUsers.toDouble(),
                                                          color: const Color(0xFFF44336),
                                                          title: rejectedUsers.toString(),
                                                          radius: 60,
                                                          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                  children: const [
                                                    Row(
                                                      children: [
                                                        SizedBox(width: 10, height: 10, child: ColoredBox(color: Color(0xFFFFC107))),
                                                        SizedBox(width: 4),
                                                        Text('Pending', style: TextStyle(fontSize: 12)),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        SizedBox(width: 10, height: 10, child: ColoredBox(color: Color(0xFF4CAF50))),
                                                        SizedBox(width: 4),
                                                        Text('Approved', style: TextStyle(fontSize: 12)),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        SizedBox(width: 10, height: 10, child: ColoredBox(color: Color(0xFFF44336))),
                                                        SizedBox(width: 4),
                                                        Text('Inactive', style: TextStyle(fontSize: 12)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(18),
                                            decoration: adminPanelDecoration(),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Asset Status', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  height: 180,
                                                  child: BarChart(
                                                    BarChartData(
                                                      alignment: BarChartAlignment.spaceAround,
                                                      titlesData: FlTitlesData(
                                                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                        bottomTitles: AxisTitles(
                                                          sideTitles: SideTitles(
                                                            showTitles: true,
                                                            getTitlesWidget: (value, meta) {
                                                              switch (value.toInt()) {
                                                                case 0: return const Text('Allocated', style: TextStyle(fontSize: 10));
                                                                case 1: return const Text('Available', style: TextStyle(fontSize: 10));
                                                                case 2: return const Text('Maint.', style: TextStyle(fontSize: 10));
                                                                default: return const Text('');
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      borderData: FlBorderData(show: false),
                                                      barGroups: [
                                                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: allocatedAssets.toDouble(), color: const Color(0xFF2196F3), width: 20)]),
                                                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: availableAssets.toDouble(), color: const Color(0xFF4CAF50), width: 20)]),
                                                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: underMaintenanceAssets.toDouble(), color: const Color(0xFFFF9800), width: 20)]),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: adminPanelDecoration(),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('User Registrations', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              height: 200,
                                              child: PieChart(
                                                PieChartData(
                                                  sectionsSpace: 2,
                                                  centerSpaceRadius: 40,
                                                  sections: [
                                                    PieChartSectionData(
                                                      value: pendingUsers.toDouble(),
                                                      color: const Color(0xFFFFC107),
                                                      title: pendingUsers.toString(),
                                                      radius: 50,
                                                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                    PieChartSectionData(
                                                      value: approvedUsers.toDouble(),
                                                      color: const Color(0xFF4CAF50),
                                                      title: approvedUsers.toString(),
                                                      radius: 50,
                                                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                    PieChartSectionData(
                                                      value: rejectedUsers.toDouble(),
                                                      color: const Color(0xFFF44336),
                                                      title: rejectedUsers.toString(),
                                                      radius: 50,
                                                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: const [
                                                Row(
                                                  children: [
                                                    SizedBox(width: 10, height: 10, child: ColoredBox(color: Color(0xFFFFC107))),
                                                    SizedBox(width: 4),
                                                    Text('Pending', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    SizedBox(width: 10, height: 10, child: ColoredBox(color: Color(0xFF4CAF50))),
                                                    SizedBox(width: 4),
                                                    Text('Approved', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    SizedBox(width: 10, height: 10, child: ColoredBox(color: Color(0xFFF44336))),
                                                    SizedBox(width: 4),
                                                    Text('Inactive', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: adminPanelDecoration(),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Asset Status', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              height: 200,
                                              child: BarChart(
                                                BarChartData(
                                                  alignment: BarChartAlignment.spaceAround,
                                                  titlesData: FlTitlesData(
                                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                    bottomTitles: AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: true,
                                                        getTitlesWidget: (value, meta) {
                                                          switch (value.toInt()) {
                                                            case 0: return const Text('Allocated', style: TextStyle(fontSize: 10));
                                                            case 1: return const Text('Available', style: TextStyle(fontSize: 10));
                                                            case 2: return const Text('Maint.', style: TextStyle(fontSize: 10));
                                                            default: return const Text('');
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  borderData: FlBorderData(show: false),
                                                  barGroups: [
                                                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: allocatedAssets.toDouble(), color: const Color(0xFF2196F3), width: 20)]),
                                                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: availableAssets.toDouble(), color: const Color(0xFF4CAF50), width: 20)]),
                                                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: underMaintenanceAssets.toDouble(), color: const Color(0xFFFF9800), width: 20)]),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          AdminSectionHeader(
            title: 'Recent Asset Requests',
            actionLabel: 'View All',
            onAction: () => onPageSelected(2),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('assetRequests')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const _EmptyRequestPanel(message: 'Unable to load asset requests.');
              }

              final requests = (snapshot.data?.docs ?? [])
                  .where((doc) {
                    final type = (doc.data()['requestType'] ?? doc.data()['type'] ?? '').toString().trim().toLowerCase();
                    final status = (doc.data()['status'] ?? 'Pending').toString().trim().toLowerCase();
                    return type != 'maintenance' && type != 'maintenance request' && status == 'pending';
                  })
                  .toList()
                ..sort((a, b) {
                  final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate();
                  final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate();
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

              final recentRequests = requests.take(5).toList();

              if (recentRequests.isEmpty) {
                return const _EmptyRequestPanel(message: 'No pending asset requests.');
              }

              return Column(
                children: recentRequests.map((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? 'Pending').toString();
                  final statusColor = _statusColor(status);
                  return AdminRequestRow(
                    id: doc.id.substring(0, 6).toUpperCase(),
                    item: (data['assetName'] ?? 'Asset').toString(),
                    user: (data['userId'] ?? 'Unknown').toString().substring(0, 8),
                    status: status,
                    statusColor: statusColor,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const AdminSectionHeader(title: 'Recent Maintenance Requests'),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('assetRequests')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const _EmptyRequestPanel(message: 'Unable to load maintenance requests.');
              }

              final requests = (snapshot.data?.docs ?? [])
                  .where((doc) {
                    final type = (doc.data()['requestType'] ?? doc.data()['type'] ?? '').toString().trim().toLowerCase();
                    final status = (doc.data()['status'] ?? 'Pending').toString().trim().toLowerCase();
                    return (type == 'maintenance' || type == 'maintenance request') && status == 'pending';
                  })
                  .toList()
                ..sort((a, b) {
                  final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate();
                  final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate();
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

              final recentRequests = requests.take(5).toList();

              if (recentRequests.isEmpty) {
                return const _EmptyRequestPanel(message: 'No pending maintenance requests.');
              }

              return Column(
                children: recentRequests.map((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? 'Pending').toString();
                  final statusColor = _statusColor(status);
                  return AdminRequestRow(
                    id: doc.id.substring(0, 6).toUpperCase(),
                    item: (data['assetName'] ?? 'Asset').toString(),
                    user: (data['userId'] ?? 'Unknown').toString().substring(0, 8),
                    status: status,
                    statusColor: statusColor,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminAssetsPage extends StatefulWidget {
  const AdminAssetsPage({super.key});

  @override
  State<AdminAssetsPage> createState() => _AdminAssetsPageState();
}

class _AdminAssetsPageState extends State<AdminAssetsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  final Set<String> _processingAssetIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<AdminAsset>> _assetsStream() {
    return FirebaseFirestore.instance
        .collection('assets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => AdminAsset.fromDoc(doc)).toList());
  }

  List<AdminAsset> _filterAssets(List<AdminAsset> assets) {
    final search = _searchController.text.trim().toLowerCase();
    return assets.where((asset) {
      final matchesSearch = search.isEmpty ||
          asset.name.toLowerCase().contains(search) ||
          asset.code.toLowerCase().contains(search) ||
          asset.assignedTo.toLowerCase().contains(search);
      final normalizedStatus = asset.status.trim().toLowerCase();
      final matchesStatus = _selectedStatus == 'All' ||
          (_selectedStatus == 'Available' && asset.isAvailable) ||
          (_selectedStatus == 'Unavailable' && !asset.isAvailable) ||
          normalizedStatus == _selectedStatus.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _showAssetDialog({AdminAsset? asset}) async {
    final nameController = TextEditingController(text: asset?.name ?? '');
    final codeController = TextEditingController(text: asset?.code ?? '');
    final assignedToController = TextEditingController(text: asset?.assignedTo ?? '');
    final quantityController = TextEditingController(text: asset?.quantity.toString() ?? '1');
    String status = asset?.status ?? 'Available';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(asset == null ? 'Add Asset' : 'Edit Asset'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Asset Name'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter asset name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Asset Code'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter asset code' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: assignedToController,
                    decoration: const InputDecoration(labelText: 'Assigned To'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed < 0) return 'Enter a valid quantity';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'Available', child: Text('Available')),
                      DropdownMenuItem(value: 'Unavailable', child: Text('Unavailable')),
                      DropdownMenuItem(value: 'Allocated', child: Text('Allocated')),
                      DropdownMenuItem(value: 'Under Maintenance', child: Text('Under Maintenance')),
                    ],
                    onChanged: (value) => setDialogState(() => status = value!),
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
                await _saveAsset(
                  asset: asset,
                  name: nameController.text.trim(),
                  code: codeController.text.trim(),
                  assignedTo: assignedToController.text.trim(),
                  status: status,
                  quantity: int.parse(quantityController.text.trim()),
                );
              },
              child: Text(asset == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAsset({
    AdminAsset? asset,
    required String name,
    required String code,
    required String assignedTo,
    required String status,
    required int quantity,
  }) async {
    final collection = FirebaseFirestore.instance.collection('assets');
    final normalizedStatus = status.trim().isEmpty
        ? (quantity > 0 ? 'Available' : 'Unavailable')
        : status.trim();
    final data = {
      'name': name,
      'code': code,
      'assignedTo': assignedTo,
      'status': normalizedStatus,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (asset == null) {
        await collection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await collection.doc(asset.uid).update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(asset == null ? 'Asset added successfully.' : 'Asset updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save asset: $e')),
        );
      }
    }
  }

  Future<void> _showAssetDetailsDialog(AdminAsset asset) async {
    try {
      final allocationsSnapshot = await FirebaseFirestore.instance
          .collection('allocations')
          .where('assetId', isEqualTo: asset.uid)
          .get();

      final allocations = allocationsSnapshot.docs;
      final totalAllocated = allocations.fold<int>(0, (sum, doc) {
        final qty = (doc.data()['quantity'] ?? 0) as int;
        return sum + qty;
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(asset.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Asset Code', value: asset.code),
                _DetailRow(label: 'Total Quantity', value: asset.quantity.toString()),
                _DetailRow(label: 'Available', value: (asset.quantity - totalAllocated).toString()),
                _DetailRow(label: 'Allocated', value: totalAllocated.toString()),
                _DetailRow(label: 'Status', value: asset.status),
                const SizedBox(height: 16),
                const Text('Allocation Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                if (allocations.isEmpty)
                  const Text('No active allocations', style: TextStyle(color: Colors.black54))
                else
                  ...allocations.map((doc) {
                    final data = doc.data();
                    final qty = data['quantity'] ?? 0;
                    final status = (data['status'] ?? 'Unknown').toString();
                    final allocatedAt = (data['allocatedAt'] as Timestamp?)?.toDate();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User: ${(data['userId'] ?? 'Unknown').toString().substring(0, 8)}', style: const TextStyle(fontSize: 14)),
                                Text('Qty: $qty • Status: $status', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                if (allocatedAt != null)
                                  Text('Date: ${allocatedAt.day}/${allocatedAt.month}/${allocatedAt.year}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load asset details: $e')),
        );
      }
    }
  }

  Widget _DetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _deleteAsset(AdminAsset asset) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text('Delete ${asset.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete != true) return;

    if (_processingAssetIds.contains(asset.uid)) return;
    setState(() => _processingAssetIds.add(asset.uid));
    try {
      await FirebaseFirestore.instance.collection('assets').doc(asset.uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete asset: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingAssetIds.remove(asset.uid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const AdminPageHeader(
          title: 'Assets',
          subtitle: 'Manage company assets and inventory.',
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search by name, code, or assigned user',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(label: const Text('All'), selected: _selectedStatus == 'All', onSelected: (_) => setState(() => _selectedStatus = 'All')),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Available'), selected: _selectedStatus == 'Available', onSelected: (_) => setState(() => _selectedStatus = 'Available')),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Unavailable'), selected: _selectedStatus == 'Unavailable', onSelected: (_) => setState(() => _selectedStatus = 'Unavailable')),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Allocated'), selected: _selectedStatus == 'Allocated', onSelected: (_) => setState(() => _selectedStatus = 'Allocated')),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Under Maintenance'), selected: _selectedStatus == 'Under Maintenance', onSelected: (_) => setState(() => _selectedStatus = 'Under Maintenance')),
            ],
          ),
        ),
        const SizedBox(height: 18),
        StreamBuilder<List<AdminAsset>>(
          stream: _assetsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _EmptyRequestPanel(message: 'Unable to load assets from Firestore.');
            }

            final assets = _filterAssets(snapshot.data ?? []);
            if (assets.isEmpty) {
              return const _EmptyRequestPanel(message: 'No assets found for this filter.');
            }

            return Column(
              children: assets.map((asset) {
                final isProcessing = _processingAssetIds.contains(asset.uid);
                return AdminManagementCard(
                  icon: Icons.inventory_2_outlined,
                  title: asset.name,
                  subtitle: '${asset.code} • Qty ${asset.quantity} • ${asset.assignedTo.isEmpty ? 'Unassigned' : asset.assignedTo}',
                  status: asset.availabilityLabel,
                  statusColor: asset.statusColor,
                  actions: [
                    AdminActionButton(
                      label: 'View Details',
                      icon: Icons.visibility_outlined,
                      color: const Color(0xFF1976D2),
                      onPressed: isProcessing ? () {} : () => _showAssetDetailsDialog(asset),
                    ),
                    AdminActionButton(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF1976D2),
                      onPressed: isProcessing ? () {} : () => _showAssetDialog(asset: asset),
                    ),
                    AdminActionButton(
                      label: 'Delete',
                      icon: Icons.delete_outline,
                      color: const Color(0xFFE53935),
                      onPressed: isProcessing ? () {} : () => _deleteAsset(asset),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final Set<String> _processingUserIds = <String>{};
  final Set<String> _processingRequestIds = <String>{};
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const AdminPageHeader(
          title: 'Requests',
          subtitle: 'Approve or reject user registrations, asset requests, and return requests.',
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Requests'),
                selected: _selectedFilter == 'All',
                onSelected: (_) => setState(() => _selectedFilter = 'All'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Asset Requests'),
                selected: _selectedFilter == 'Asset',
                onSelected: (_) => setState(() => _selectedFilter = 'Asset'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Return Requests'),
                selected: _selectedFilter == 'Return',
                onSelected: (_) => setState(() => _selectedFilter = 'Return'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Maintenance Requests'),
                selected: _selectedFilter == 'Maintenance',
                onSelected: (_) => setState(() => _selectedFilter = 'Maintenance'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_selectedFilter == 'All' || _selectedFilter == 'Asset') ...[
          const AdminSectionHeader(title: 'Asset Requests'),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('assetRequests').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const _EmptyRequestPanel(message: 'Unable to load asset requests.');
              }

              final requests = (snapshot.data?.docs ?? [])
                  .where((requestDoc) {
                    final status = (requestDoc.data()['status'] ?? 'Pending').toString().trim();
                    return status.toLowerCase() == 'pending';
                  })
                  .toList()
                ..sort((a, b) {
                  final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate();
                  final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate();
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

              if (requests.isEmpty) {
                return const _EmptyRequestPanel(message: 'No pending asset requests.');
              }

              return Column(
                children: requests.map((requestDoc) {
                  final data = requestDoc.data();
                  final requestStatus = (data['status'] ?? 'Pending').toString();
                  final isProcessing = _processingRequestIds.contains(requestDoc.id);
                  final quantity = data['quantity'] ?? 1;
                  return AdminManagementCard(
                    icon: Icons.assignment_outlined,
                    title: (data['assetName'] ?? 'Asset').toString(),
                    subtitle: '${requestDoc.id.substring(0, 6).toUpperCase()} - Requested by ${data['userId'] ?? 'Unknown'} • Qty: $quantity',
                    status: requestStatus,
                    statusColor: requestStatus.toLowerCase() == 'approved'
                        ? const Color(0xFF2E7D32)
                        : requestStatus.toLowerCase() == 'rejected'
                            ? const Color(0xFFE53935)
                            : const Color(0xFFFFC107),
                    actions: [
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Approve',
                        icon: Icons.check,
                        color: const Color(0xFF2E7D32),
                        onPressed: isProcessing ? () {} : () => _handleAssetRequestDecision(requestDoc, approved: true),
                      ),
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Reject',
                        icon: Icons.close,
                        color: const Color(0xFFE53935),
                        onPressed: isProcessing ? () {} : () => _handleAssetRequestDecision(requestDoc, approved: false),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
        if (_selectedFilter == 'All' || _selectedFilter == 'Return') ...[
          const SizedBox(height: 24),
          const AdminSectionHeader(title: 'Return Requests'),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('returnRequests').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const _EmptyRequestPanel(message: 'Unable to load return requests.');
              }

              final returnRequests = (snapshot.data?.docs ?? [])
                  .where((doc) {
                    final status = (doc.data()['status'] ?? 'Pending').toString().trim();
                    return status.toLowerCase() == 'pending';
                  })
                  .toList()
                ..sort((a, b) {
                  final aTime = (a.data()['requestedAt'] as Timestamp?)?.toDate();
                  final bTime = (b.data()['requestedAt'] as Timestamp?)?.toDate();
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

              if (returnRequests.isEmpty) {
                return const _EmptyRequestPanel(message: 'No pending return requests.');
              }

              return Column(
                children: returnRequests.map((returnDoc) {
                  final data = returnDoc.data();
                  final returnStatus = (data['status'] ?? 'Pending').toString();
                  final isProcessing = _processingRequestIds.contains(returnDoc.id);
                  final quantity = data['quantity'] ?? 1;
                  return AdminManagementCard(
                    icon: Icons.undo_outlined,
                    title: (data['assetName'] ?? 'Asset').toString(),
                    subtitle: '${returnDoc.id.substring(0, 6).toUpperCase()} - Return from ${(data['userId'] ?? 'Unknown').toString().substring(0, 8)} • Qty: $quantity',
                    status: returnStatus,
                    statusColor: returnStatus.toLowerCase() == 'approved'
                        ? const Color(0xFF2E7D32)
                        : returnStatus.toLowerCase() == 'rejected'
                            ? const Color(0xFFE53935)
                            : const Color(0xFFFFC107),
                    actions: [
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Approve',
                        icon: Icons.check,
                        color: const Color(0xFF2E7D32),
                        onPressed: isProcessing ? () {} : () => _handleReturnRequestDecision(returnDoc, approved: true),
                      ),
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Reject',
                        icon: Icons.close,
                        color: const Color(0xFFE53935),
                        onPressed: isProcessing ? () {} : () => _handleReturnRequestDecision(returnDoc, approved: false),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
        if (_selectedFilter == 'All' || _selectedFilter == 'Maintenance') ...[
          const SizedBox(height: 24),
          const AdminSectionHeader(title: 'Maintenance Requests'),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('maintenanceRequests').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const _EmptyRequestPanel(message: 'Unable to load maintenance requests.');
              }

              final maintenanceRequests = (snapshot.data?.docs ?? [])
                  .where((doc) {
                    final status = (doc.data()['status'] ?? 'Pending').toString().trim();
                    return status.toLowerCase() == 'pending';
                  })
                  .toList()
                ..sort((a, b) {
                  final aTime = (a.data()['requestedAt'] as Timestamp?)?.toDate();
                  final bTime = (b.data()['requestedAt'] as Timestamp?)?.toDate();
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

              if (maintenanceRequests.isEmpty) {
                return const _EmptyRequestPanel(message: 'No pending maintenance requests.');
              }

              return Column(
                children: maintenanceRequests.map((maintDoc) {
                  final data = maintDoc.data();
                  final maintStatus = (data['status'] ?? 'Pending').toString();
                  final isProcessing = _processingRequestIds.contains(maintDoc.id);
                  final quantity = data['quantity'] ?? 1;
                  final description = (data['description'] ?? '').toString();
                  final requestedAt = (data['requestedAt'] as Timestamp?)?.toDate();
                  return AdminManagementCard(
                    icon: Icons.build_circle_outlined,
                    title: (data['assetName'] ?? 'Asset').toString(),
                    subtitle: '${maintDoc.id.substring(0, 6).toUpperCase()} - ${(data['userId'] ?? 'Unknown').toString().substring(0, 8)} • Qty: $quantity${description.isNotEmpty ? ' • $description' : ''}',
                    status: maintStatus,
                    statusColor: maintStatus.toLowerCase() == 'approved'
                        ? const Color(0xFF2E7D32)
                        : maintStatus.toLowerCase() == 'rejected'
                            ? const Color(0xFFE53935)
                            : const Color(0xFFFFC107),
                    actions: [
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Approve',
                        icon: Icons.check,
                        color: const Color(0xFF2E7D32),
                        onPressed: isProcessing ? () {} : () => _handleMaintenanceRequestDecision(maintDoc, approved: true),
                      ),
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Reject',
                        icon: Icons.close,
                        color: const Color(0xFFE53935),
                        onPressed: isProcessing ? () {} : () => _handleMaintenanceRequestDecision(maintDoc, approved: false),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        const AdminSectionHeader(title: 'User Registrations'),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('approved', isEqualTo: false)
              .where('status', isEqualTo: 'Pending')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _EmptyRequestPanel(message: 'Unable to load registration requests.');
            }

            final pendingUsers = snapshot.data?.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => AdminUser.fromDoc(doc)).toList() ?? [];

            if (pendingUsers.isEmpty) {
              return const _EmptyRequestPanel(message: 'No pending user registrations.');
            }

            return Column(
              children: pendingUsers.map((user) {
                final isProcessing = _processingUserIds.contains(user.uid);
                return AdminManagementCard(
                  icon: Icons.person_add_alt_outlined,
                  title: user.name.isEmpty ? user.email : user.name,
                  subtitle: '${user.email}${user.role.isNotEmpty ? ' - $user.role' : ''}',
                  status: user.status,
                  statusColor: _statusColor(user.status),
                  actions: [
                    AdminActionButton(
                      label: isProcessing ? 'Working...' : 'Approve',
                      icon: Icons.check,
                      color: const Color(0xFF2E7D32),
                      onPressed: isProcessing ? () {} : () => _handleRegistrationDecision(user, approved: true),
                    ),
                    AdminActionButton(
                      label: isProcessing ? 'Working...' : 'Reject',
                      icon: Icons.close,
                      color: const Color(0xFFE53935),
                      onPressed: isProcessing ? () {} : () => _handleRegistrationDecision(user, approved: false),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFFC107);
      case 'inactive':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF1976D2);
    }
  }

  Future<void> _handleAssetRequestDecision(DocumentSnapshot<Map<String, dynamic>> requestDoc, {required bool approved}) async {
    final requestId = requestDoc.id;
    if (_processingRequestIds.contains(requestId)) return;
    setState(() => _processingRequestIds.add(requestId));

    try {
      final requestData = requestDoc.data() ?? {};
      final assetId = requestData['assetId']?.toString();
      final assetName = (requestData['assetName'] ?? 'Asset').toString();
      final userId = requestData['userId']?.toString();
      final requestedQuantity = (requestData['quantity'] ?? 1) as int;

      if (approved) {
        if (assetId == null || userId == null) {
          throw Exception('Missing request details');
        }

        final assetDoc = await FirebaseFirestore.instance.collection('assets').doc(assetId).get();
        final assetData = assetDoc.data() ?? {};
        final availableQuantity = int.tryParse((assetData['quantity'] ?? '0').toString()) ?? 0;
        
        if (availableQuantity < requestedQuantity) {
          throw Exception('Only $availableQuantity units available, but $requestedQuantity requested');
        }

        // Check if user already has an allocation for this asset
        final existingAllocation = await FirebaseFirestore.instance
            .collection('allocations')
            .where('userId', isEqualTo: userId)
            .where('assetId', isEqualTo: assetId)
            .where('status', isEqualTo: 'Allocated')
            .limit(1)
            .get();

        int newQuantity = requestedQuantity;
        if (existingAllocation.docs.isNotEmpty) {
          // User already has allocation, add to existing quantity
          final existingDoc = existingAllocation.docs.first;
          final existingQty = (existingDoc.data()['quantity'] ?? 0) as int;
          newQuantity = existingQty + requestedQuantity;
          
          await existingDoc.reference.update({
            'quantity': newQuantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new allocation
          await FirebaseFirestore.instance.collection('allocations').add({
            'assetId': assetId,
            'assetName': assetName,
            'assetCode': assetData['code'] ?? '',
            'assetCategory': assetData['category'] ?? '',
            'userId': userId,
            'quantity': requestedQuantity,
            'status': 'Allocated',
            'allocatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update asset quantity
        await FirebaseFirestore.instance.collection('assets').doc(assetId).update({
          'quantity': availableQuantity - requestedQuantity,
          'status': (availableQuantity - requestedQuantity) > 0 ? 'Available' : 'Unavailable',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await requestDoc.reference.update({'status': approved ? 'Approved' : 'Rejected'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approved ? 'Asset request approved.' : 'Asset request rejected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to process request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingRequestIds.remove(requestId));
      }
    }
  }

  Future<void> _handleRegistrationDecision(AdminUser user, {required bool approved}) async {
    if (_processingUserIds.contains(user.uid)) return;

    setState(() {
      _processingUserIds.add(user.uid);
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'approved': approved,
        'status': approved ? 'Active' : 'Inactive',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approved ? 'User approved successfully.' : 'Registration rejected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update registration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(user.uid);
        });
      }
    }
  }

  Future<void> _handleMaintenanceRequestDecision(DocumentSnapshot<Map<String, dynamic>> maintDoc, {required bool approved}) async {
    final maintId = maintDoc.id;
    if (_processingRequestIds.contains(maintId)) return;
    setState(() => _processingRequestIds.add(maintId));

    try {
      final maintData = maintDoc.data() ?? {};
      final assetId = maintData['assetId']?.toString();
      final userId = maintData['userId']?.toString();

      if (approved) {
        if (assetId == null || userId == null) {
          throw Exception('Missing maintenance request details');
        }

        // Show service provider selection dialog
        final selectedServiceProvider = await _showServiceProviderSelectionDialog(context);
        if (selectedServiceProvider == null) {
          // Admin cancelled the dialog
          if (mounted) {
            setState(() => _processingRequestIds.remove(maintId));
          }
          return;
        }

        // Update maintenance request with service provider and status
        await maintDoc.reference.update({
          'status': 'Assigned',
          'assignedTo': selectedServiceProvider['uid'],
          'assignedToName': selectedServiceProvider['name'],
          'assignedAt': FieldValue.serverTimestamp(),
        });

        // Update asset status to Under Maintenance
        await FirebaseFirestore.instance.collection('assets').doc(assetId).update({
          'status': 'Under Maintenance',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update allocation status if exists
        final allocationSnapshot = await FirebaseFirestore.instance
            .collection('allocations')
            .where('userId', isEqualTo: userId)
            .where('assetId', isEqualTo: assetId)
            .limit(1)
            .get();

        if (allocationSnapshot.docs.isNotEmpty) {
          await allocationSnapshot.docs.first.reference.update({
            'status': 'Under Maintenance',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Maintenance request assigned to ${selectedServiceProvider['name']}')),
          );
        }
      } else {
        await maintDoc.reference.update({'status': 'Rejected'});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maintenance request rejected.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to process maintenance request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingRequestIds.remove(maintId));
      }
    }
  }

  Future<Map<String, String>?> _showServiceProviderSelectionDialog(BuildContext context) async {
    final serviceProviders = <Map<String, String>>[];
    
    try {
      // Fetch all users with Service Provider role
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Service Provider')
          .where('approved', isEqualTo: true)
          .where('status', isEqualTo: 'Active')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        serviceProviders.add({
          'uid': doc.id,
          'name': (data['name'] ?? data['username'] ?? 'Unknown').toString().trim(),
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load service providers: $e')),
        );
      }
      return null;
    }

    if (serviceProviders.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active service providers available.')),
        );
      }
      return null;
    }

    String? selectedProviderId = serviceProviders.first['uid'];

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Service Provider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose a service provider to assign this maintenance task:', style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 16),
              ...serviceProviders.map((provider) {
                final isSelected = selectedProviderId == provider['uid'];
                return RadioListTile<String>(
                  title: Text(provider['name']!),
                  value: provider['uid']!,
                  groupValue: selectedProviderId,
                  selected: isSelected,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedProviderId = value);
                    }
                  },
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: selectedProviderId == null
                  ? null
                  : () {
                      Map<String, String>? selected;
                      for (final provider in serviceProviders) {
                        if (provider['uid'] == selectedProviderId) {
                          selected = provider;
                          break;
                        }
                      }
                      if (selected != null) {
                        Navigator.pop(context, selected);
                      }
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReturnRequestDecision(DocumentSnapshot<Map<String, dynamic>> returnDoc, {required bool approved}) async {
    final returnId = returnDoc.id;
    if (_processingRequestIds.contains(returnId)) return;
    setState(() => _processingRequestIds.add(returnId));

    try {
      final returnData = returnDoc.data() ?? {};
      final assetId = returnData['assetId']?.toString();
      final userId = returnData['userId']?.toString();
      final returnQuantity = (returnData['quantity'] ?? 1) as int;
      final allocationId = returnData['allocationId']?.toString();

      if (approved) {
        if (assetId == null || userId == null || allocationId == null) {
          throw Exception('Missing return request details');
        }

        // Get the asset to update its quantity
        final assetDoc = await FirebaseFirestore.instance.collection('assets').doc(assetId).get();
        final assetData = assetDoc.data() ?? {};
        final currentQuantity = int.tryParse((assetData['quantity'] ?? '0').toString()) ?? 0;

        // Update asset quantity (increase available)
        await FirebaseFirestore.instance.collection('assets').doc(assetId).update({
          'quantity': currentQuantity + returnQuantity,
          'status': 'Available',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update or delete the allocation
        final allocationDoc = await FirebaseFirestore.instance.collection('allocations').doc(allocationId).get();
        if (allocationDoc.exists) {
          final allocationData = allocationDoc.data() ?? {};
          final allocatedQuantity = (allocationData['quantity'] ?? 0) as int;

          if (allocatedQuantity <= returnQuantity) {
            // If returning all or more than allocated, delete the allocation
            await allocationDoc.reference.delete();
          } else {
            // Otherwise, decrease the allocated quantity
            await allocationDoc.reference.update({
              'quantity': allocatedQuantity - returnQuantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Update return request status
      await returnDoc.reference.update({'status': approved ? 'Approved' : 'Rejected'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approved ? 'Return request approved.' : 'Return request rejected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to process return request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingRequestIds.remove(returnId));
      }
    }
  }
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All';
  String _selectedStatus = 'All';
  final Set<String> _processingUserIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<AdminUser>> _usersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => AdminUser.fromDoc(doc)).toList());
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFFC107);
      case 'inactive':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF1976D2);
    }
  }

  List<AdminUser> _filterUsers(List<AdminUser> users) {
    final search = _searchController.text.trim().toLowerCase();
    return users.where((user) {
      final matchesSearch = search.isEmpty ||
          user.name.toLowerCase().contains(search) ||
          user.email.toLowerCase().contains(search) ||
          user.username.toLowerCase().contains(search);
      final matchesRole = _selectedRole == 'All' || user.role.toLowerCase() == _selectedRole.toLowerCase();
      final matchesStatus = _selectedStatus == 'All' ||
          user.status.toLowerCase() == _selectedStatus.toLowerCase();
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  Future<void> _showEditUserDialog(BuildContext context, AdminUser user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final employeeIdController = TextEditingController(text: user.employeeId);
    final phoneController = TextEditingController(text: user.phone);
    final usernameController = TextEditingController(text: user.username);
    String role = user.role.isEmpty ? 'User' : user.role;
    String status = user.status.isEmpty ? 'Pending' : user.status;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a full name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => (value == null || value.trim().isEmpty || !value.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a username' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: employeeIdController,
                    decoration: const InputDecoration(labelText: 'Employee ID'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'User', child: Text('User')),
                      DropdownMenuItem(value: 'Service Provider', child: Text('Service Provider')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    ],
                    onChanged: (value) => setDialogState(() => role = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) => setDialogState(() => status = value!),
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
                await _updateUserDetails(
                  user: user,
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  employeeId: employeeIdController.text.trim(),
                  phone: phoneController.text.trim(),
                  username: usernameController.text.trim(),
                  role: role,
                  status: status,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserDetails({
    required AdminUser user,
    required String name,
    required String email,
    required String employeeId,
    required String phone,
    required String username,
    required String role,
    required String status,
  }) async {
    if (_processingUserIds.contains(user.uid)) return;

    setState(() {
      _processingUserIds.add(user.uid);
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
        'employeeId': employeeId,
        'phone': phone,
        'username': username,
        'role': role,
        'status': status,
        'approved': status.toLowerCase() == 'active' || status.toLowerCase() == 'pending' ? user.approved : false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User details updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update user: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(user.uid);
        });
      }
    }
  }

  Future<void> _toggleAccountStatus(AdminUser user, {required bool activate}) async {
    if (_processingUserIds.contains(user.uid)) return;

    setState(() {
      _processingUserIds.add(user.uid);
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'status': activate ? 'Active' : 'Inactive',
        'approved': activate ? true : user.approved,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(activate ? 'Account activated.' : 'Account deactivated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update account status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(user.uid);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const AdminPageHeader(
          title: 'Users',
          subtitle: 'Search, filter, and manage registered users.',
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search by name, email, or username',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Roles'),
                selected: _selectedRole == 'All',
                onSelected: (_) => setState(() => _selectedRole = 'All'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Admin'),
                selected: _selectedRole == 'Admin',
                onSelected: (_) => setState(() => _selectedRole = 'Admin'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('User'),
                selected: _selectedRole == 'User',
                onSelected: (_) => setState(() => _selectedRole = 'User'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Service Provider'),
                selected: _selectedRole == 'Service Provider',
                onSelected: (_) => setState(() => _selectedRole = 'Service Provider'),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('All Statuses'),
                selected: _selectedStatus == 'All',
                onSelected: (_) => setState(() => _selectedStatus = 'All'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Active'),
                selected: _selectedStatus == 'Active',
                onSelected: (_) => setState(() => _selectedStatus = 'Active'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Inactive'),
                selected: _selectedStatus == 'Inactive',
                onSelected: (_) => setState(() => _selectedStatus = 'Inactive'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Pending'),
                selected: _selectedStatus == 'Pending',
                onSelected: (_) => setState(() => _selectedStatus = 'Pending'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        StreamBuilder<List<AdminUser>>(
          stream: _usersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _EmptyRequestPanel(message: 'Unable to load users from Firestore.');
            }

            final users = _filterUsers(snapshot.data ?? []);
            if (users.isEmpty) {
              return const _EmptyRequestPanel(message: 'No users match the current filters.');
            }

            return Column(
              children: users.map((user) {
                final isProcessing = _processingUserIds.contains(user.uid);
                final normalizedStatus = user.status.isEmpty ? 'Pending' : user.status;
                final isActive = normalizedStatus.toLowerCase() == 'active';

                return AdminManagementCard(
                  icon: Icons.account_circle_outlined,
                  title: user.name.isEmpty ? user.email : user.name,
                  subtitle: '${user.email}${user.role.isNotEmpty ? ' - $user.role' : ''}',
                  status: normalizedStatus,
                  statusColor: _statusColor(normalizedStatus),
                  actions: [
                    AdminActionButton(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF1976D2),
                      onPressed: isProcessing ? () {} : () => _showEditUserDialog(context, user),
                    ),
                    if (!user.approved)
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Approve',
                        icon: Icons.check,
                        color: const Color(0xFF2E7D32),
                        onPressed: isProcessing ? () {} : () => _toggleAccountStatus(user, activate: true),
                      ),
                    if (!user.approved)
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Reject',
                        icon: Icons.close,
                        color: const Color(0xFFE53935),
                        onPressed: isProcessing ? () {} : () => _toggleAccountStatus(user, activate: false),
                      ),
                    if (user.approved && isActive)
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Deactivate',
                        icon: Icons.person_off_outlined,
                        color: const Color(0xFFE53935),
                        onPressed: isProcessing ? () {} : () => _toggleAccountStatus(user, activate: false),
                      ),
                    if (user.approved && !isActive)
                      AdminActionButton(
                        label: isProcessing ? 'Working...' : 'Activate',
                        icon: Icons.person_add_alt_1,
                        color: const Color(0xFF2E7D32),
                        onPressed: isProcessing ? () {} : () => _toggleAccountStatus(user, activate: true),
                      ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  Future<void> _exportReport(BuildContext context, Future<String?> Function() exportFunction, String reportName) async {
    try {
      final filePath = await exportFunction();
      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$reportName exported successfully to:\n$filePath'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export report.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const AdminPageHeader(
          title: 'Reports',
          subtitle: 'Quick status reports for assets, users, and requests.',
        ),
        const SizedBox(height: 18),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('assets').snapshots(),
              builder: (context, assetsSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('assetRequests').snapshots(),
                  builder: (context, requestsSnapshot) {
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('allocations').snapshots(),
                      builder: (context, allocationsSnapshot) {
                        if (usersSnapshot.connectionState == ConnectionState.waiting ||
                            assetsSnapshot.connectionState == ConnectionState.waiting ||
                            requestsSnapshot.connectionState == ConnectionState.waiting ||
                            allocationsSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (usersSnapshot.hasError || assetsSnapshot.hasError || requestsSnapshot.hasError || allocationsSnapshot.hasError) {
                          return const _EmptyRequestPanel(message: 'Unable to load reports data.');
                        }

                        final users = usersSnapshot.data?.docs ?? [];
                        final assets = assetsSnapshot.data?.docs ?? [];
                        final requests = requestsSnapshot.data?.docs ?? [];
                        final allocations = allocationsSnapshot.data?.docs ?? [];

                        final totalUsers = users.length;
                        final activeUsers = users.where((doc) {
                          final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
                          return status == 'active';
                        }).length;
                        final pendingUsers = users.where((doc) {
                          final status = (doc.data()['status'] ?? 'Pending').toString().trim().toLowerCase();
                          return status == 'pending' || doc.data()['approved'] != true;
                        }).length;

                        final totalAssets = assets.fold<int>(0, (sum, doc) {
                          final quantity = int.tryParse((doc.data()['quantity'] ?? '0').toString()) ?? 0;
                          return sum + quantity;
                        });
                        final availableAssets = assets.where((doc) {
                          final quantity = int.tryParse((doc.data()['quantity'] ?? '0').toString()) ?? 0;
                          return quantity > 0;
                        }).fold<int>(0, (sum, doc) {
                          final quantity = int.tryParse((doc.data()['quantity'] ?? '0').toString()) ?? 0;
                          return sum + quantity;
                        });
                        final allocatedAssets = assets.where((doc) {
                          final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
                          return status == 'allocated';
                        }).length;
                        final underMaintenanceAssets = assets.where((doc) {
                          final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
                          return status == 'under maintenance' || status == 'maintenance';
                        }).length;

                        final totalAllocations = allocations.length;
                        final pendingAssetRequests = requests.where((doc) {
                          final status = (doc.data()['status'] ?? 'Pending').toString().trim().toLowerCase();
                          final type = (doc.data()['requestType'] ?? doc.data()['type'] ?? '').toString().trim().toLowerCase();
                          return status == 'pending' && type != 'maintenance';
                        }).length;
                        final pendingMaintenanceRequests = requests.where((doc) {
                          final status = (doc.data()['status'] ?? 'Pending').toString().trim().toLowerCase();
                          final type = (doc.data()['requestType'] ?? doc.data()['type'] ?? '').toString().trim().toLowerCase();
                          return status == 'pending' && (type == 'maintenance' || type == 'maintenance request');
                        }).length;

                        final assetUsagePercentage = totalAssets > 0 ? ((allocatedAssets + underMaintenanceAssets) / totalAssets * 100).round() : 0;

                        return Column(
                          children: [
                            AdminOverviewGrid(
                              children: [
                                AdminOverviewCard(
                                  title: 'Asset Usage',
                                  value: '$assetUsagePercentage%',
                                  icon: Icons.pie_chart_outline,
                                  color: const Color(0xFFE8F6FF),
                                ),
                                AdminOverviewCard(
                                  title: 'Open Requests',
                                  value: (pendingAssetRequests + pendingMaintenanceRequests).toString(),
                                  icon: Icons.pending_actions_outlined,
                                  color: const Color(0xFFFFEFEE),
                                ),
                                AdminOverviewCard(
                                  title: 'Active Users',
                                  value: activeUsers.toString(),
                                  icon: Icons.verified_user_outlined,
                                  color: const Color(0xFFE8F7ED),
                                ),
                                AdminOverviewCard(
                                  title: 'Total Allocations',
                                  value: totalAllocations.toString(),
                                  icon: Icons.assignment_turned_in_outlined,
                                  color: const Color(0xFFFFF2E8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _ReportTileWithDownload(
                              title: 'Monthly Asset Allocation',
                              value: '$allocatedAssets allocated assets',
                              icon: Icons.timeline,
                              onDownload: () => _exportReport(context, ExcelExportService.exportAssetsReport, 'Assets report'),
                            ),
                            const SizedBox(height: 12),
                            // _ReportTileWithDownload(
                            //   title: 'Registration Review',
                            //   value: '$pendingUsers users waiting for approval',
                            //   icon: Icons.how_to_reg_outlined,
                            //   onDownload: () => _exportReport(context, ExcelExportService.exportUsersReport, 'Users report'),
                            // ),
                            const SizedBox(height: 12),
                            _ReportTileWithDownload(
                              title: 'Maintenance Summary',
                              value: '$underMaintenanceAssets assets under maintenance',
                              icon: Icons.handyman_outlined,
                              onDownload: () => _exportReport(context, ExcelExportService.exportMaintenanceReport, 'Maintenance report'),
                            ),
                            const SizedBox(height: 12),
                            _ReportTileWithDownload(
                              title: 'Available Assets',
                              value: '$availableAssets assets available for allocation',
                              icon: Icons.check_circle_outline,
                              onDownload: () => _exportReport(context, ExcelExportService.exportAssetsReport, 'Assets report'),
                            ),
                            const SizedBox(height: 12),
                            // _ReportTileWithDownload(
                            //   title: 'Total Asset Requests',
                            //   value: '$pendingAssetRequests pending asset requests',
                            //   icon: Icons.assignment_outlined,
                            //   onDownload: () => _exportReport(context, ExcelExportService.exportAssetRequestsReport, 'Asset requests report'),
                            // ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ReportTileWithDownload extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onDownload;

  const _ReportTileWithDownload({
    required this.title,
    required this.value,
    required this.icon,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: adminPanelDecoration(),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1976D2), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, color: Color(0xFF1976D2)),
            tooltip: 'Download Report',
          ),
        ],
      ),
    );
  }
}

class _EmptyRequestPanel extends StatelessWidget {
  final String message;

  const _EmptyRequestPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: adminPanelDecoration(),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}