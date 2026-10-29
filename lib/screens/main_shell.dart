import 'dart:async';

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
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  void _updateSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _searchQuery = value.trim());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

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

  Widget _searchField() => TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search products, categories, or labels',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                ),
        ),
        onChanged: _updateSearch,
      );

  Widget _desktopNavigation(
    BuildContext context,
    List<NavigationDestination> destinations,
  ) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 14, 12, 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: 'TECHNOLOGIA',
                child: TechChipMark(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _searchField(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final selected = _index == index;
                return ListTile(
                  selected: selected,
                  selectedColor: colors.onPrimary,
                  selectedTileColor: colors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  leading: SizedBox(
                    width: 28,
                    child: Center(
                      child: selected
                          ? destination.selectedIcon ?? destination.icon
                          : destination.icon,
                    ),
                  ),
                  title: Text(destination.label),
                  onTap: () => setState(() => _index = index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().count;
    final destinations = _destinations(cartCount);
    final pages = [
      HomeScreen(searchQuery: _searchQuery),
      const CartScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      body: wide
          ? Row(
              children: [
                _desktopNavigation(context, destinations),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: IndexedStack(index: _index, children: pages),
                ),
              ],
            )
          : IndexedStack(index: _index, children: pages),
      bottomNavigationBar: wide
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_index == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: _searchField(),
                  ),
                NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (index) =>
                      setState(() => _index = index),
                  destinations: destinations,
                ),
              ],
            ),
    );
  }
}
