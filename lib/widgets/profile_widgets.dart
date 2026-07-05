import 'package:flutter/material.dart';

class ProfileField {
  final IconData icon;
  final String label;
  final String value;

  const ProfileField({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class ProfileStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// Header card showing avatar, name, subtitle (e.g. role/ID), and status pill.
class ProfileHeaderCard extends StatelessWidget {
  final IconData avatarIcon;
  final String name;
  final String subtitle;
  final String status;

  const ProfileHeaderCard({
    super.key,
    required this.avatarIcon,
    required this.name,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFE8F0FF),
              child: Icon(avatarIcon, color: colorScheme.primary, size: 38),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 10),
                  _StatusPill(label: status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Info card listing profile fields as ListTiles with dividers.
class ProfileInfoCard extends StatelessWidget {
  final List<ProfileField> fields;

  const ProfileInfoCard({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE8F0FF),
                child:
                    Icon(fields[i].icon, color: const Color(0xFF2555FF), size: 20),
              ),
              title: Text(fields[i].label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black54)),
              subtitle: Text(fields[i].value,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (i != fields.length - 1) const Divider(height: 1, indent: 72),
          ],
        ],
      ),
    );
  }
}

/// Stats card for showing numeric KPIs (e.g. service provider task counts).
class ProfileStatsCard extends StatelessWidget {
  final List<ProfileStat> stats;

  const ProfileStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                Container(width: 1, height: 48, color: const Color(0xFFE8ECF0)),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: stats[i].color.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(stats[i].icon,
                          color: stats[i].color, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(stats[i].value,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(stats[i].label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Action card with Edit Profile, Change Password, and Logout options.
class ProfileActionsCard extends StatelessWidget {
  final VoidCallback? onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;
  final bool showEditProfile;

  const ProfileActionsCard({
    super.key,
    this.onEditProfile,
    required this.onChangePassword,
    required this.onLogout,
    this.showEditProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          if (showEditProfile) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onEditProfile,
            ),
            const Divider(height: 1),
          ],
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onChangePassword,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_outlined,
                color: Color(0xFFE53935)),
            title: const Text('Logout',
                style: TextStyle(
                    color: Color(0xFFE53935), fontWeight: FontWeight.w700)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

void showComingSoonSnackBar(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label will be available soon.')),
  );
}

/// Dynamic status pill — color based on status string.
class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF2E7D32);
      case 'inactive':
        return const Color(0xFF9E9E9E);
      case 'pending':
        return const Color(0xFFE65100);
      case 'suspended':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
