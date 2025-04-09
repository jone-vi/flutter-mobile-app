import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  WarehousePageState createState() => WarehousePageState();
}

class WarehousePageState extends State<WarehousePage> {
  void _navigateToDetail(String type) {
    context.go('/warehouselist',
        extra: {'type': type, 'parentType': null, 'parentId': null});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavigationButton(
                title: 'INVENTORIES',
                onTap: () => _navigateToDetail('houses'),
              ),
              const SizedBox(height: 10),
              _buildNavigationButton(
                title: 'ROOMS',
                onTap: () => _navigateToDetail('rooms'),
              ),
              const SizedBox(height: 10),
              _buildNavigationButton(
                title: 'LOCATIONS',
                onTap: () => _navigateToDetail('locations'),
              ),
              const SizedBox(height: 10),
              _buildNavigationButton(
                title: 'ITEMS',
                onTap: () => _navigateToDetail('items'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          padding: const EdgeInsets.all(16.0),
          textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }
}
