import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../widgets/user_widgets.dart';

class UserAsset {
  final String id;
  final String name;
  final String category;
  final int available;
  final String status;

  const UserAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.available,
    required this.status,
  });

  factory UserAsset.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final quantity = int.tryParse((data['quantity'] ?? '0').toString()) ?? 0;
    return UserAsset(
      id: doc.id,
      name: (data['name'] ?? '').toString().trim(),
      category: (data['category'] ?? '').toString().trim(),
      available: quantity,
      status: quantity > 0 ? 'Available' : 'Unavailable',
    );
  }
}

// ---------------------------------------------------------------------------
// User Dashboard Page
// ---------------------------------------------------------------------------

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final _auth = FirebaseAuth.instance;
  final Set<String> _requestingAssetIds = <String>{};
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;
    setState(() {
      _userName = (doc.data()?['name'] ?? '').toString().trim().isEmpty ? 'User' : doc.data()?['name'];
    });
  }

  Future<void> _requestAsset(BuildContext context, UserAsset asset) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (currentUser == null) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Please sign in to request an asset.')));
      return;
    }

    if (_requestingAssetIds.contains(asset.id)) return;
    
    // Show quantity selection dialog
    final quantity = await _showQuantityDialog(context, asset.available);
    if (quantity == null || quantity <= 0) return;
    
    setState(() => _requestingAssetIds.add(asset.id));

    try {
      final existing = await FirebaseFirestore.instance
          .collection('assetRequests')
          .where('userId', isEqualTo: currentUser.uid)
          .where('assetId', isEqualTo: asset.id)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('You already have a pending request for this asset.')));
        return;
      }

      if (asset.available < quantity) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('Only ${asset.available} units available.')));
        return;
      }

      await FirebaseFirestore.instance.collection('assetRequests').add({
        'assetId': asset.id,
        'assetName': asset.name,
        'category': asset.category,
        'userId': currentUser.uid,
        'status': 'Pending',
        'quantity': quantity,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Request placed for $quantity ${asset.name}(s)')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Unable to request asset: $e')));
    } finally {
      if (mounted) {
        setState(() => _requestingAssetIds.remove(asset.id));
      }
    }
  }

  Future<int?> _showQuantityDialog(BuildContext context, int maxQuantity) async {
    int selectedQuantity = 1;
    
    return await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available: $maxQuantity units', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedQuantity > 1 ? () => setState(() => selectedQuantity--) : null,
                    icon: const Icon(Icons.remove_circle),
                  ),
                  Text(
                    selectedQuantity.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: selectedQuantity < maxQuantity ? () => setState(() => selectedQuantity++) : null,
                    icon: const Icon(Icons.add_circle),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedQuantity),
              child: const Text('Request'),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text(
          'ShaTechx - AMS',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('assets').snapshots(),
              builder: (context, assetsSnapshot) {
                if (assetsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (assetsSnapshot.hasError) {
                  return const _EmptyState(message: 'Unable to load asset statistics.');
                }

                final assets = assetsSnapshot.data?.docs ?? [];
                final totalAssets = assets.fold<int>(0, (sum, doc) {
                  final quantity = int.tryParse((doc.data()['quantity'] ?? '0').toString()) ?? 0;
                  return sum + quantity;
                });
                final availableAssets = assets.where((doc) {
                  final data = doc.data();
                  final quantity = int.tryParse((data['quantity'] ?? '0').toString()) ?? 0;
                  final status = (data['status'] ?? '').toString().trim().toLowerCase();
                  return quantity > 0 && status != 'allocated' && status != 'under maintenance' && status != 'maintenance';
                }).fold<int>(0, (sum, doc) {
                  final quantity = int.tryParse((doc.data()['quantity'] ?? '0').toString()) ?? 0;
                  return sum + quantity;
                });

                return Row(
                  children: [
                    Expanded(
                      child: UserSummaryCard(
                        title: 'Total Assets',
                        value: totalAssets.toString(),
                        icon: Icons.inventory_2,
                        backgroundColor: const Color(0xFFE7EEFF),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: UserSummaryCard(
                        title: 'Available Assets',
                        value: availableAssets.toString(),
                        icon: Icons.check_circle_outline,
                        backgroundColor: const Color(0xFFE8F7ED),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('allocations')
                  .snapshots(),
              builder: (context, allocationSnapshot) {
                if (allocationSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (allocationSnapshot.hasError) {
                  return const _EmptyState(message: 'Unable to load your owned assets.');
                }

                final uid = _auth.currentUser?.uid;
                if (uid == null) {
                  return const _EmptyState(message: 'Please sign in to view your assets.');
                }

                final allocations = (allocationSnapshot.data?.docs ?? [])
                    .where((doc) {
                      final data = doc.data();
                      final status = (data['status'] ?? '').toString().trim().toLowerCase();
                      return (data['userId'] ?? '') == uid &&
                          (status == 'allocated' || status == 'active' || status == 'approved' || status == 'maintenance' || status == 'under maintenance');
                    })
                    .toList();

                final inUseAssets = allocations.where((doc) {
                  final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
                  return status == 'allocated' || status == 'active' || status == 'approved';
                }).length;
                final underMaintenanceAssets = allocations.where((doc) {
                  final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
                  return status == 'maintenance' || status == 'under maintenance';
                }).length;
                final totalOwned = inUseAssets + underMaintenanceAssets;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2, color: Color(0xFF2555FF), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Owned Assets',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                                ),
                                Text(
                                  totalOwned.toString(),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                                    const Icon(Icons.assignment_turned_in_outlined, size: 18, color: Color(0xFF2555FF)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'In Use',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  inUseAssets.toString(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.black.withAlpha(20),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Under Maintenance',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.build_circle_outlined, size: 18, color: Color(0xFF2555FF)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  underMaintenanceAssets.toString(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            UserSectionHeader(
              title: 'Available Assets',
              actionLabel: 'View All',
              onAction: () => AppRoutes.go(context, AppRoutes.userAssets),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('assets').snapshots(),
              builder: (context, assetSnapshot) {
                if (assetSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!assetSnapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final assets = assetSnapshot.data!.docs.map((doc) => UserAsset.fromDoc(doc)).where((asset) => asset.available > 0).toList();
                if (assets.isEmpty) {
                  return const _EmptyState(message: 'No available assets right now.');
                }
                return Column(
                  children: assets.take(3).map((asset) => UserAssetTile(
                        title: asset.name,
                        category: asset.category,
                        available: asset.available,
                        status: asset.status,
                        isRequesting: _requestingAssetIds.contains(asset.id),
                        onRequest: () => _requestAsset(context, asset),
                      )).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            UserSectionHeader(
              title: 'Recent Requests',
              actionLabel: 'View All',
              onAction: () => AppRoutes.go(context, AppRoutes.userRequests),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('assetRequests')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .limit(10)
                  .snapshots(),
              builder: (context, requestSnapshot) {
                if (requestSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!requestSnapshot.hasData || requestSnapshot.data!.docs.isEmpty) {
                  return const _EmptyState(message: 'No recent requests.');
                }

                // Sort by createdAt (newest first) and take only the first 3
                var requests = requestSnapshot.data!.docs.toList();
                requests.sort((a, b) {
                  final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate();
                  final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate();
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });
                requests = requests.take(3).toList();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: requests.map((doc) {
                      final data = doc.data();
                      final status = (data['status'] ?? 'Pending').toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RequestRow(
                          id: doc.id.substring(0, 6).toUpperCase(),
                          asset: (data['assetName'] ?? 'Asset').toString(),
                          status: status,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const UserBottomNavigation(selectedRoute: AppRoutes.userDashboard),
    );
  }
}

// ---------------------------------------------------------------------------
// User Assets Page (Available Assets)
// ---------------------------------------------------------------------------

class UserAssetsPage extends StatefulWidget {
  const UserAssetsPage({super.key});

  @override
  State<UserAssetsPage> createState() => _UserAssetsPageState();
}

class _UserAssetsPageState extends State<UserAssetsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _requestingAssetIds = <String>{};

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestAsset(BuildContext context, UserAsset asset) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (currentUser == null) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Please sign in to request an asset.')));
      return;
    }

    if (_requestingAssetIds.contains(asset.id)) return;
    
    // Show quantity selection dialog
    final quantity = await _showQuantityDialog(context, asset.available);
    if (quantity == null || quantity <= 0) return;
    
    setState(() => _requestingAssetIds.add(asset.id));

    try {
      final existing = await FirebaseFirestore.instance
          .collection('assetRequests')
          .where('userId', isEqualTo: currentUser.uid)
          .where('assetId', isEqualTo: asset.id)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('You already have a pending request for this asset.')));
        return;
      }

      if (asset.available < quantity) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('Only ${asset.available} units available.')));
        return;
      }

      await FirebaseFirestore.instance.collection('assetRequests').add({
        'assetId': asset.id,
        'assetName': asset.name,
        'category': asset.category,
        'userId': currentUser.uid,
        'status': 'Pending',
        'quantity': quantity,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Request placed for $quantity ${asset.name}(s)')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Unable to request asset: $e')));
    } finally {
      if (mounted) {
        setState(() => _requestingAssetIds.remove(asset.id));
      }
    }
  }

  Future<int?> _showQuantityDialog(BuildContext context, int maxQuantity) async {
    int selectedQuantity = 1;
    
    return await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available: $maxQuantity units', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedQuantity > 1 ? () => setState(() => selectedQuantity--) : null,
                    icon: const Icon(Icons.remove_circle),
                  ),
                  Text(
                    selectedQuantity.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: selectedQuantity < maxQuantity ? () => setState(() => selectedQuantity++) : null,
                    icon: const Icon(Icons.add_circle),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedQuantity),
              child: const Text('Request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text(
          'ShaTechx - AMS',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              UserSearchField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('assets').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const _EmptyState(message: 'No assets found.');
                  }

                  final assets = snapshot.data!.docs.map((doc) => UserAsset.fromDoc(doc)).where((asset) {
                    final query = _searchController.text.toLowerCase();
                    return query.isEmpty ||
                        asset.name.toLowerCase().contains(query) ||
                        asset.category.toLowerCase().contains(query);
                  }).toList();

                  if (assets.isEmpty) {
                    return const _EmptyState(message: 'No assets found.');
                  }

                  return Column(
                    children: assets.map((asset) => UserAssetTile(
                          title: asset.name,
                          category: asset.category,
                          available: asset.available,
                          status: asset.status,
                          isRequesting: _requestingAssetIds.contains(asset.id),
                          buttonLabel: asset.available > 0 ? 'Request' : 'Unavailable',
                          onRequest: asset.available > 0 ? () => _requestAsset(context, asset) : () {},
                        )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          const UserBottomNavigation(selectedRoute: AppRoutes.userAssets),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helper widget
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final String id;
  final String asset;
  final String status;

  const _RequestRow({required this.id, required this.asset, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        status == 'Pending' ? const Color(0xFFFFA726) : const Color(0xFF42A5F5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(id,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(asset,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color.lerp(statusColor, Colors.white, 0.86),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            status,
            style: TextStyle(
                color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// User Settings Page
// ---------------------------------------------------------------------------

class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

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
                  subtitle: const Text('Manage push and email alerts'),
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
                  subtitle: const Text('Update your account password'),
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
                  title: const Text('About'),
                  subtitle: const Text('App version and information'),
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
          const SizedBox(height: 24),
          Text(
            'Account',
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
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(Icons.logout_outlined,
                    color: Color(0xFFE53935), size: 20),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                    color: Color(0xFFE53935), fontWeight: FontWeight.w700),
              ),
              onTap: () => AppRoutes.logout(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          const UserBottomNavigation(selectedRoute: AppRoutes.userSettings),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be available soon.')),
    );
  }
}

