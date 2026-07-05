import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'widgets/profile_widgets.dart';

class ServiceProviderDashboard extends StatefulWidget {
  const ServiceProviderDashboard({super.key});

  @override
  State<ServiceProviderDashboard> createState() =>
      _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard> {
  int _selectedIndex = 0;

  static const List<String> _labels = [
    'Dashboard',
    'Tasks',
    'History',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ── Dashboard Tab ─────────────────────────────────────────────────────────

  Widget _buildDashboard(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back,',
              style: TextStyle(color: Colors.black54, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Muhammad Ali',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: currentUser != null 
                ? FirebaseFirestore.instance
                    .collection('maintenanceRequests')
                    .where('assignedTo', isEqualTo: currentUser.uid)
                    .snapshots()
                : null,
            builder: (context, snapshot) {
              int assigned = 0;
              int inProgress = 0;
              int completed = 0;
              int pending = 0;

              if (snapshot.hasData) {
                final tasks = snapshot.data!.docs;
                assigned = tasks.length;
                for (final doc in tasks) {
                  final status = (doc.data()['status'] ?? '').toString().toLowerCase();
                  if (status == 'in progress') {
                    inProgress++;
                  } else if (status == 'completed') {
                    completed++;
                  } else if (status == 'assigned') {
                    pending++;
                  }
                }
              }

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _ServiceCard(
                      label: 'Assigned',
                      value: assigned.toString(),
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFFE7EEFF)),
                  _ServiceCard(
                      label: 'In Progress',
                      value: inProgress.toString(),
                      icon: Icons.autorenew,
                      color: const Color(0xFFFFF4E5)),
                  _ServiceCard(
                      label: 'Completed',
                      value: completed.toString(),
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFFE8F6EF)),
                  _ServiceCard(
                      label: 'Pending',
                      value: pending.toString(),
                      icon: Icons.pending_actions_outlined,
                      color: const Color(0xFFEDE7FF)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Tasks',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => _onItemTapped(1),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecentTasksList(context),
        ],
      ),
    );
  }

  Widget _buildRecentTasksList(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to view tasks.'));
    }

    // Try without orderBy first as fallback
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('maintenanceRequests')
          .where('assignedTo', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Error loading tasks:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Troubleshooting:\n'
                    '1. Check Firebase Console → Firestore → Indexes\n'
                    '2. Wait for index to show READY (2-5 min)\n'
                    '3. Verify Firestore Rules are deployed\n'
                    '4. Ensure assignedTo field exists in documents',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final tasks = snapshot.data?.docs ?? [];
        if (tasks.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No tasks assigned yet.'),
            ),
          );
        }

        return Column(
          children: tasks.map((doc) {
            final data = doc.data();
            final status = (data['status'] ?? 'Assigned').toString();
            final assetName = (data['assetName'] ?? 'Unknown Asset').toString();
            final userName = (data['userName'] ?? 'Unknown User').toString();
            final description = (data['description'] ?? '').toString();
            
            Color statusColor;
            switch (status.toLowerCase()) {
              case 'in progress':
                statusColor = const Color(0xFF42A5F5);
                break;
              case 'completed':
                statusColor = const Color(0xFF4CAF50);
                break;
              case 'assigned':
                statusColor = const Color(0xFFFFC107);
                break;
              default:
                statusColor = const Color(0xFF1976D2);
            }

            return _TaskCard(
              task: _ServiceTask(
                id: doc.id.substring(0, 6).toUpperCase(),
                fullId: doc.id,
                title: assetName,
                assignedTo: userName,
                status: status,
                statusColor: statusColor,
                description: description,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Tasks Tab ─────────────────────────────────────────────────────────────

  Widget _buildTasks(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to view tasks.'));
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text(
            'Assigned Tasks',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('maintenanceRequests')
                .where('assignedTo', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Error loading tasks:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${snapshot.error}',
                            style: const TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Troubleshooting:\n'
                          '1. Check Firebase Console → Firestore → Indexes\n'
                          '2. Wait for index to show READY (2-5 min)\n'
                          '3. Verify Firestore Rules are deployed\n'
                          '4. Ensure assignedTo field exists in documents',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final tasks = snapshot.data?.docs ?? [];
              if (tasks.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No tasks assigned yet.'),
                  ),
                );
              }

              return Column(
                children: tasks.map((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? 'Assigned').toString();
                  final assetName = (data['assetName'] ?? 'Unknown Asset').toString();
                  final userName = (data['userName'] ?? 'Unknown User').toString();
                  final description = (data['description'] ?? '').toString();
                  final assignedAt = (data['assignedAt'] as Timestamp?)?.toDate();
                  
                  Color statusColor;
                  switch (status.toLowerCase()) {
                    case 'in progress':
                      statusColor = const Color(0xFF42A5F5);
                      break;
                    case 'completed':
                      statusColor = const Color(0xFF4CAF50);
                      break;
                    case 'assigned':
                      statusColor = const Color(0xFFFFC107);
                      break;
                    default:
                      statusColor = const Color(0xFF1976D2);
                  }

                  return _TaskCard(
                    task: _ServiceTask(
                      id: doc.id.substring(0, 6).toUpperCase(),
                      fullId: doc.id,
                      title: assetName,
                      assignedTo: userName,
                      status: status,
                      statusColor: statusColor,
                      description: description,
                      assignedDate: assignedAt != null 
                          ? '${assignedAt.day}/${assignedAt.month}/${assignedAt.year}'
                          : 'N/A',
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── History Tab ───────────────────────────────────────────────────────────

  Widget _buildHistory(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to view history.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text(
          'Maintenance History',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('maintenanceRequests')
              .where('assignedTo', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: 'Completed')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final completedTasks = snapshot.data?.docs ?? [];
            if (completedTasks.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No completed tasks yet.'),
                ),
              );
            }

            return Column(
              children: completedTasks.map((doc) {
                final data = doc.data();
                final assetName = (data['assetName'] ?? 'Unknown Asset').toString();
                final userName = (data['userName'] ?? 'Unknown User').toString();
                final serviceProviderName = (data['completedByName'] ?? currentUser.displayName ?? 'Service Provider').toString();
                final description = (data['description'] ?? 'No description').toString();
                final progressNotes = (data['progressNotes'] ?? '').toString();
                final completedAt = (data['completedAt'] as Timestamp?)?.toDate() ?? (data['updatedAt'] as Timestamp?)?.toDate();
                final dateStr = completedAt != null
                    ? '${completedAt.day}/${completedAt.month}/${completedAt.year}'
                    : 'N/A';
                final timeStr = completedAt != null
                    ? '${completedAt.hour}:${completedAt.minute.toString().padLeft(2, '0')}'
                    : '';

                return _HistoryCard(
                  item: _HistoryItem(
                    id: doc.id.substring(0, 6).toUpperCase(),
                    title: assetName,
                    status: 'Completed',
                    date: dateStr,
                    userName: userName,
                    serviceProviderName: serviceProviderName,
                    description: description,
                    progressNotes: progressNotes,
                    time: timeStr,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── Profile Tab (inline) ──────────────────────────────────────────────────

  Widget _buildProfile(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to view profile.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Unable to load profile.'),
                ),
              );
            }

            final userData = snapshot.data!.data()!;
            final name = (userData['name'] ?? 'Service Provider').toString();
            final username = (userData['username'] ?? 'N/A').toString();
            final email = (userData['email'] ?? 'N/A').toString();
            final phone = (userData['phone'] ?? 'N/A').toString();
            final role = (userData['role'] ?? 'Service Provider').toString();
            final employeeId = (userData['employeeId'] ?? 'N/A').toString();
            final status = (userData['status'] ?? 'Active').toString();

            return Column(
              children: [
                ProfileHeaderCard(
                  avatarIcon: Icons.handyman_outlined,
                  name: name,
                  subtitle: '$employeeId · $role',
                  status: status,
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('maintenanceRequests')
                      .where('assignedTo', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, taskSnapshot) {
                    int totalAssigned = 0;
                    int completed = 0;
                    int inProgress = 0;

                    if (taskSnapshot.hasData) {
                      final tasks = taskSnapshot.data!.docs;
                      totalAssigned = tasks.length;
                      for (final doc in tasks) {
                        final taskStatus = (doc.data()['status'] ?? '').toString().toLowerCase();
                        if (taskStatus == 'completed') {
                          completed++;
                        } else if (taskStatus == 'in progress') {
                          inProgress++;
                        }
                      }
                    }

                    return ProfileStatsCard(
                      stats: [
                        ProfileStat(
                          label: 'Total\nAssigned',
                          value: totalAssigned.toString(),
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFF2555FF),
                        ),
                        ProfileStat(
                          label: 'Completed',
                          value: completed.toString(),
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF4CAF50),
                        ),
                        ProfileStat(
                          label: 'Active\nTasks',
                          value: inProgress.toString(),
                          icon: Icons.autorenew,
                          color: const Color(0xFFFFA726),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                ProfileInfoCard(
                  fields: [
                    ProfileField(
                      icon: Icons.badge_outlined,
                      label: 'Service Provider ID',
                      value: employeeId,
                    ),
                    ProfileField(
                      icon: Icons.person_outline,
                      label: 'Username',
                      value: username,
                    ),
                    ProfileField(
                      icon: Icons.email_outlined,
                      label: 'Email Address',
                      value: email,
                    ),
                    ProfileField(
                      icon: Icons.phone_outlined,
                      label: 'Phone Number',
                      value: phone,
                    ),
                    ProfileField(
                      icon: Icons.build_outlined,
                      label: 'Role',
                      value: role,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ProfileActionsCard(
                  showEditProfile: false,
                  onChangePassword: () => _showComingSoon(context, 'Change Password'),
                  onLogout: () => AppRoutes.logout(context),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be available soon.')),
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

  // ── Scaffold ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_labels[_selectedIndex]),
        backgroundColor: colorScheme.surface,
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(context),
          _buildTasks(context),
          _buildHistory(context),
          _buildProfile(context),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2555FF),
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_outlined), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

// ── Drawer Item Helper ─────────────────────────────────────────────────────

class _SpDrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isDestructive;

  const _SpDrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFE53935)
        : isSelected
            ? Theme.of(context).colorScheme.primary
            : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: isSelected || isDestructive
              ? FontWeight.w700
              : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor:
          Theme.of(context).colorScheme.primary.withAlpha((0.08 * 255).round()),
      onTap: onTap,
    );
  }
}

// ── Dashboard Summary Card ─────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ServiceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 30,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2555FF)),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ── Task Data ──────────────────────────────────────────────────────────────

class _ServiceTask {
  final String id;
  final String fullId;
  final String title;
  final String assignedTo;
  final String status;
  final Color statusColor;
  final String? description;
  final String? assignedDate;

  const _ServiceTask({
    required this.id,
    required this.fullId,
    required this.title,
    required this.assignedTo,
    required this.status,
    required this.statusColor,
    this.description,
    this.assignedDate,
  });
}

class _TaskCard extends StatelessWidget {
  final _ServiceTask task;

  const _TaskCard({required this.task});

  Future<void> _showUpdateProgressDialog(BuildContext context, String taskId) async {
    final TextEditingController _progressController = TextEditingController();
    String _status = task.status;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.description != null && task.description!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(task.description!),
                    ],
                  ),
                ),
              if (task.description != null && task.description!.isNotEmpty)
                const SizedBox(height: 16),
              TextField(
                controller: _progressController,
                decoration: const InputDecoration(
                  labelText: 'Progress Notes',
                  hintText: 'Enter progress update...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'Assigned', child: Text('Assigned')),
                  DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                ],
                onChanged: (value) => setDialogState(() => _status = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (_progressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter progress notes.')),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not authenticated.')),
                      );
                    }
                    return;
                  }

                  // Use Firestore transaction for atomic updates
                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    // Get the maintenance request document
                    final maintDocRef = FirebaseFirestore.instance
                        .collection('maintenanceRequests')
                        .doc(taskId);
                    final maintDoc = await transaction.get(maintDocRef);

                    if (!maintDoc.exists) {
                      throw Exception('Maintenance request not found');
                    }

                    final maintData = maintDoc.data()!;
                    final assetId = maintData['assetId']?.toString();
                    final userId = maintData['userId']?.toString();

                    // Update maintenance request status
                    final updateData = <String, dynamic>{
                      'status': _status,
                      'updatedAt': FieldValue.serverTimestamp(),
                      'progressNotes': _progressController.text.trim(),
                    };

                    // If status is Completed, perform additional updates
                    if (_status.toLowerCase() == 'completed') {
                      updateData['completedAt'] = FieldValue.serverTimestamp();
                      updateData['completedBy'] = currentUser.uid;
                      updateData['completedByName'] = currentUser.displayName ?? 'Service Provider';

                      // Update asset status from "Under Maintenance" back to "In Use"
                      // The asset is still allocated to the same user, so it should be "In Use"
                      if (assetId != null && userId != null) {
                        final assetDocRef = FirebaseFirestore.instance
                            .collection('assets')
                            .doc(assetId);
                        
                        // Asset is still allocated to the user after maintenance, mark as "In Use"
                        transaction.update(assetDocRef, {
                          'status': 'In Use',
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        // Update allocation status back to "In Use"
                        final allocationSnapshot = await FirebaseFirestore.instance
                            .collection('allocations')
                            .where('userId', isEqualTo: userId)
                            .where('assetId', isEqualTo: assetId)
                            .limit(1)
                            .get();

                        if (allocationSnapshot.docs.isNotEmpty) {
                          final allocationDocRef = allocationSnapshot.docs.first.reference;
                          transaction.update(allocationDocRef, {
                            'status': 'In Use',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        }
                      }
                    }

                    transaction.update(maintDocRef, updateData);
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maintenance completed successfully. The Admin and User have been notified.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to update progress: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                task.id,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: task.statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  task.status,
                  style: TextStyle(
                      color: task.statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Assigned to ${task.assignedTo}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
          if (task.assignedDate != null && task.assignedDate != 'N/A') ...[
            const SizedBox(height: 4),
            Text(
              'Assigned on ${task.assignedDate}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
          ],
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _showUpdateProgressDialog(context, task.fullId),
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Update Progress'),
              ),
          ),
        ],
      ),
    );
  }
}

// ── History Data ───────────────────────────────────────────────────────────

class _HistoryItem {
  final String id;
  final String title;
  final String status;
  final String date;
  final String userName;
  final String serviceProviderName;
  final String description;
  final String progressNotes;
  final String time;

  const _HistoryItem({
    required this.id,
    required this.title,
    required this.status,
    required this.date,
    this.userName = 'Unknown User',
    this.serviceProviderName = 'Service Provider',
    this.description = 'No description',
    this.progressNotes = '',
    this.time = '',
  });
}

class _HistoryCard extends StatelessWidget {
  final _HistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${item.id}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withAlpha(38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  item.status,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Color(0xFF2555FF)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'User: ${item.userName}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.handyman_outlined, size: 16, color: Color(0xFF2555FF)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Service Provider: ${item.serviceProviderName}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (item.time.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.time,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description_outlined, size: 16, color: Color(0xFF2555FF)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maintenance Description:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.progressNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_outlined, size: 16, color: Color(0xFF2555FF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion Notes:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.progressNotes,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Service Provider Profile Page (standalone — navigated from drawer)
// ═══════════════════════════════════════════════════════════════════════════

class ServiceProviderProfilePage extends StatelessWidget {
  const ServiceProviderProfilePage({super.key});

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be available soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Provider Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Unable to load profile.'),
                  ),
                );
              }

              final userData = snapshot.data!.data()!;
              final name = (userData['name'] ?? 'Service Provider').toString();
              final username = (userData['username'] ?? 'N/A').toString();
              final email = (userData['email'] ?? 'N/A').toString();
              final phone = (userData['phone'] ?? 'N/A').toString();
              final role = (userData['role'] ?? 'Service Provider').toString();
              final employeeId = (userData['employeeId'] ?? 'N/A').toString();
              final status = (userData['status'] ?? 'Active').toString();

              return Column(
                children: [
                  ProfileHeaderCard(
                    avatarIcon: Icons.handyman_outlined,
                    name: name,
                    subtitle: '$employeeId · $role',
                    status: status,
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('maintenanceRequests')
                        .where('assignedTo', isEqualTo: currentUser.uid)
                        .snapshots(),
                    builder: (context, taskSnapshot) {
                      int totalAssigned = 0;
                      int completed = 0;
                      int inProgress = 0;

                      if (taskSnapshot.hasData) {
                        final tasks = taskSnapshot.data!.docs;
                        totalAssigned = tasks.length;
                        for (final doc in tasks) {
                          final taskStatus = (doc.data()['status'] ?? '').toString().toLowerCase();
                          if (taskStatus == 'completed') {
                            completed++;
                          } else if (taskStatus == 'in progress') {
                            inProgress++;
                          }
                        }
                      }

                      return ProfileStatsCard(
                        stats: [
                          ProfileStat(
                            label: 'Total\nAssigned',
                            value: totalAssigned.toString(),
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFF2555FF),
                          ),
                          ProfileStat(
                            label: 'Completed',
                            value: completed.toString(),
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF4CAF50),
                          ),
                          ProfileStat(
                            label: 'Active\nTasks',
                            value: inProgress.toString(),
                            icon: Icons.autorenew,
                            color: const Color(0xFFFFA726),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ProfileInfoCard(
                    fields: [
                      ProfileField(
                        icon: Icons.badge_outlined,
                        label: 'Service Provider ID',
                        value: employeeId,
                      ),
                      ProfileField(
                        icon: Icons.person_outline,
                        label: 'Username',
                        value: username,
                      ),
                      ProfileField(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: email,
                      ),
                      ProfileField(
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: phone,
                      ),
                      ProfileField(
                        icon: Icons.build_outlined,
                        label: 'Role',
                        value: role,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProfileActionsCard(
                    showEditProfile: false,
                    onChangePassword: () =>
                        _showComingSoon(context, 'Change Password'),
                    onLogout: () => AppRoutes.logout(context),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Service Provider Settings Page
// ═══════════════════════════════════════════════════════════════════════════

class ServiceProviderSettingsPage extends StatelessWidget {
  const ServiceProviderSettingsPage({super.key});

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be available soon.')),
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F0FF),
                    child: Icon(Icons.notifications_outlined,
                        color: Color(0xFF2555FF), size: 20),
                  ),
                  title: const Text('Notification Preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showComingSoon(context, 'Notification Preferences'),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F0FF),
                    child: Icon(Icons.lock_outline,
                        color: Color(0xFF2555FF), size: 20),
                  ),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon(context, 'Change Password'),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F0FF),
                    child: Icon(Icons.info_outline,
                        color: Color(0xFF2555FF), size: 20),
                  ),
                  title: const Text('About Service Provider'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Asset Management System',
                    applicationVersion: '1.0.0',
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
