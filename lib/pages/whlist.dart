import 'dart:io';
import '/database.dart';
import '/util/parent.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WarehouseListPage extends StatelessWidget {
  final String type;
  final ParentParams parent;

  const WarehouseListPage(
      {super.key, required this.type, required this.parent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            type.toUpperCase() +
                (parent.name != null ? ' in ${parent.name}' : ''),
            style: GoogleFonts.kumbhSans(fontSize: 28),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _fetchData(context, type, parent.type, parent.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error.toString()}'));
            } else {
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                padding: const EdgeInsets.all(8),
                itemCount: snapshot.data!.length + 1,
                itemBuilder: (context, index) {
                  if (index == snapshot.data!.length) {
                    return _buildAddItemButton(context);
                  }
                  final item = snapshot.data![index];
                  return _buildItemBox(context, item);
                },
              );
            }
          },
        ));
  }

  Widget _buildItemBox(BuildContext context, dynamic item) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        // this is mega stupid
        String modifiedType =
            type.endsWith('s') ? type.substring(0, type.length - 1) : type;
        context.go('/warehouseitem', extra: {
          'type': modifiedType,
          'id': item.id.toString(),
        });
      },
      child: item.imagePath != null
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: FileImage(File(item.imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.65),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
    );
  }

  Widget _buildAddItemButton(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        context.go('/additem', extra: {
          'type': type,
          'parent': parent,
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: CircleAvatar(
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
          radius: 24,
          child: const Icon(Icons.add, size: 24),
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchData(BuildContext context, String type,
      String? parentType, int? parentId) async {
    final database = Provider.of<Database>(context, listen: false);
    if (parentType != null && parentId != null) {
      switch (parentType) {
        case 'house':
          switch (type) {
            case 'rooms':
              return database.getRoomsInHouse(parentId);
            case 'locations':
              return database.getLocationsInHouse(parentId);
            case 'items':
              return database.getItemsInHouse(parentId);
            default:
              throw Exception('house error @ $type');
          }
        case 'room':
          switch (type) {
            case 'locations':
              return database.getLocationsInRoom(parentId);
            case 'items':
              return database.getItemsInRoom(parentId);
            default:
              throw Exception('room error @ $type');
          }
        case 'location':
          if (type == 'items') {
            return database.getItemsInLocation(parentId);
          } else {
            throw Exception('location error @ $type');
          }
        default:
          throw Exception('unhandled @ $parentType');
      }
    } else {
      switch (type) {
        case 'items':
          return database.getAllItems();
        case 'locations':
          return database.getAllLocations();
        case 'rooms':
          return database.getAllRooms();
        case 'houses':
          return database.getAllHouses();
        default:
          throw Exception('unhandled @ $type');
      }
    }
  }
}
