import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.currentIndex,
    this.title,
    this.actions,
    this.backgroundColor,
    this.appBar,
  });

  final Widget body;
  final int currentIndex;
  final String? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar ?? (title == null ? null : AppBar(title: Text(title!), actions: actions)),
      body: body,
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2CB89D),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _openQuickActions(context),
        child: const Icon(Icons.add, size: 34),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home, label: 'Dashboard', selected: currentIndex == 0, onTap: () => _to(context, '/dashboard', true)),
              _NavItem(icon: Icons.restaurant, label: 'Mahlzeiten', selected: currentIndex == 1, onTap: () => _to(context, '/meals', false)),
              const SizedBox(width: 34),
              _NavItem(icon: Icons.scale, label: 'Gewicht', selected: currentIndex == 2, onTap: () => _to(context, '/weights', false)),
              _NavItem(icon: Icons.favorite, label: 'Profil', selected: currentIndex == 3, onTap: () => _to(context, '/dogs', false)),
            ],
          ),
        ),
      ),
    );
  }

  void _to(BuildContext context, String route, bool replace) {
    if (replace) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  void _openQuickActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Schnell hinzufügen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.pets),
                title: const Text('Gewicht erfassen'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/weights/create');
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_run),
                title: const Text('Aktivität erfassen'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/activities/create');
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Mahlzeit hinzufügen'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/meals/create');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2CB89D) : const Color(0xFF6F7F8C);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
