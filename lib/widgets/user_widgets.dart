import 'package:flutter/material.dart';

import '../app_routes.dart';

class UserSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;

  const UserSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2555FF), size: 28),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }
}

class UserAssetTile extends StatelessWidget {
  final String title;
  final String category;
  final int available;
  final String status;
  final VoidCallback onRequest;
  final bool isRequesting;
  final String buttonLabel;

  const UserAssetTile({
    super.key,
    required this.title,
    required this.category,
    required this.available,
    required this.status,
    required this.onRequest,
    this.isRequesting = false,
    this.buttonLabel = 'Request',
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Available'
        ? const Color(0xFF4CAF50)
        : status == 'Unavailable'
            ? const Color(0xFFE53935)
            : const Color(0xFFFFC107);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Color.lerp(statusColor, Colors.white, 0.84), borderRadius: BorderRadius.circular(14)),
                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('Category', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54))),
              Expanded(child: Text('Available', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(category, style: Theme.of(context).textTheme.bodyMedium)),
              Expanded(child: Text(available.toString(), style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: isRequesting ? null : onRequest,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(isRequesting ? 'Working...' : buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class UserSectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const UserSectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class UserSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const UserSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Search assets...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_outlined),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}

class UserAssetFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const UserAssetFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Active', 'Maintenance'];

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return FilterChip(
            selected: isSelected,
            label: Text(filter),
            avatar: filter == 'All' ? null : const Icon(Icons.filter_list, size: 16),
            selectedColor: Theme.of(context).colorScheme.primary.withAlpha((0.14 * 255).round()),
            checkmarkColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            onSelected: (_) => onFilterChanged(filter),
          );
        }).toList(),
      ),
    );
  }
}


class UserBottomNavigation extends StatelessWidget {
  final String selectedRoute;

  const UserBottomNavigation({super.key, required this.selectedRoute});

  @override
  Widget build(BuildContext context) {
    final rawIndex = AppRoutes.userBottomIndex(selectedRoute);
    // -1 means a secondary page (e.g. Settings) not represented in the nav bar
    final currentIndex = rawIndex < 0 ? 0 : rawIndex;
    final selectedColor =
        rawIndex < 0 ? Colors.transparent : const Color(0xFF2555FF);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        AppRoutes.go(
          context,
          AppRoutes.userRouteForBottomIndex(index),
          replace: true,
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Available'),
        BottomNavigationBarItem(icon: Icon(Icons.folder_open_outlined), label: 'My Assets'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
