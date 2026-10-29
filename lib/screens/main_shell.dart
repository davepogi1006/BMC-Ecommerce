import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import '../widgets/tech_ui.dart';

final GlobalKey<MainShellState> mainShellKey = GlobalKey<MainShellState>();

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  MainShellState createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;

  late final _pages = [
    const HomeScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  void selectShop() {
    setState(() => _index = 0);
  }

  List<NavigationDestination> _destinations(int cartCount) => [
        const NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Shop',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: const Icon(Icons.shopping_bag),
          ),
          label: 'Cart',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().count;
    final destinations = _destinations(cartCount);
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (index) =>
                      setState(() => _index = index),
                  labelType: NavigationRailLabelType.all,
                  minWidth: 76,
                  leading: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 14, 12, 26),
                    child: Tooltip(
                      message: 'TECHNOLOGIA',
                      child: TechChipMark(),
                    ),
                  ),
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: destination.icon,
                        selectedIcon:
                            destination.selectedIcon ?? destination.icon,
                        label: Text(destination.label),
                      ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: IndexedStack(index: _index, children: _pages),
                ),
              ],
            )
          : IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: destinations,
            ),
    );
  }
}
