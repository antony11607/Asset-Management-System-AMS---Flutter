import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/user_widgets.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
      body: uid == null
          ? const Center(child: Text('Please sign in to view your profile.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Unable to load profile data: ${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile not found.'));
                }

                final data = snapshot.data!.data() ?? {};
                final name = (data['name'] ?? '').toString().trim();
                final employeeId = (data['employeeId'] ?? '').toString().trim();
                final username = (data['username'] ?? '').toString().trim();
                final email = (data['email'] ?? '').toString().trim();
                final phone = (data['phone'] ?? '').toString().trim();
                final role = (data['role'] ?? 'User').toString().trim();
                final status = (data['status'] ?? 'Pending').toString().trim();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    ProfileHeaderCard(
                      avatarIcon: Icons.person_outline,
                      name: name.isEmpty ? 'User' : name,
                      subtitle: '${employeeId.isEmpty ? 'N/A' : employeeId} · ${role.isEmpty ? 'User' : role}',
                      status: status.isEmpty ? 'Active' : status,
                    ),
                    const SizedBox(height: 16),
                    ProfileInfoCard(
                      fields: [
                        ProfileField(
                          icon: Icons.badge_outlined,
                          label: 'Employee ID',
                          value: employeeId.isEmpty ? 'Not set' : employeeId,
                        ),
                        ProfileField(
                          icon: Icons.person_outline,
                          label: 'Username',
                          value: username.isEmpty ? 'Not set' : username,
                        ),
                        ProfileField(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: email.isEmpty ? 'Not set' : email,
                        ),
                        ProfileField(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: phone.isEmpty ? 'Not set' : phone,
                        ),
                        ProfileField(
                          icon: Icons.work_outline,
                          label: 'Role',
                          value: role.isEmpty ? 'User' : role,
                        ),
                        ProfileField(
                          icon: Icons.verified_user_outlined,
                          label: 'Account Status',
                          value: status.isEmpty ? 'Active' : status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProfileActionsCard(
                      onEditProfile: () => showComingSoonSnackBar(context, 'Edit Profile'),
                      onChangePassword: () => showComingSoonSnackBar(context, 'Change Password'),
                      onLogout: () => AppRoutes.logout(context),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar:
          const UserBottomNavigation(selectedRoute: AppRoutes.userProfile),
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
