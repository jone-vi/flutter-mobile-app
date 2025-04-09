import 'dart:io';
import '/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WarehouseItemPage extends StatelessWidget {
  final String type;
  final int id;

  const WarehouseItemPage({
    super.key,
    required this.type,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: fetchData(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Oh no! ${snapshot.error}")),
          );
        }
        if (snapshot.hasData) {
          return _buildPageWithData(context, snapshot.data);
        }
        return const Scaffold(
          body: Center(child: Text('No data :(')),
        );
      },
    );
  }

  Widget _buildPageWithData(BuildContext context, dynamic item) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.name,
          style: GoogleFonts.kumbhSans(fontSize: 28),
        ),
        centerTitle: true,
      ),
      body: _buildDetailsPage(context, item),
    );
  }

  Widget _buildDetailsPage(BuildContext context, dynamic item) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          item.imagePath != null
              ? AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.file(
                    File(item.imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: 100,
                  color: theme.colorScheme.primaryContainer,
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
          ..._buildButtons(context, item.name),
        ],
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context, String? parentName) {
    List<Widget> list = [];
    list.add(const SizedBox(height: 20));
    if (type != 'item') {
      list.add(_buildButton(context, 'Items', 'items', type, id, parentName));
    }
    if (type == 'room') {
      list.add(_buildButton(
          context, 'Locations', 'locations', type, id, parentName));
    }
    if (type == 'house') {
      list.add(_buildButton(context, 'Rooms', 'rooms', type, id, parentName));
    }
    list.add(const SizedBox(height: 20));
    list.add(_buildEditButton(context, id, type));
    list.add(const SizedBox(height: 20));
    list.add(_buildDeleteButton(context, id, type));
    return list;
  }

  Future<dynamic> fetchData(BuildContext context) {
    final db = Provider.of<Database>(context, listen: false);
    final parsedId = id;

    switch (type) {
      case 'house':
        return db.getHouseById(parsedId);
      case 'room':
        return db.getRoomById(parsedId);
      case 'location':
        return db.getLocationById(parsedId);
      case 'item':
        return db.getItemById(parsedId);
      default:
        throw Exception('unhandled @ $type');
    }
  }
}

Widget _buildButton(BuildContext context, String title, String route,
    String? parentType, int? parentId, String? parentName) {
  final theme = Theme.of(context);

  return Container(
    width: MediaQuery.of(context).size.width * 0.8,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
    child: ElevatedButton(
      onPressed: () {
        context.go('/warehouselist', extra: {
          'type': route,
          'parentType': parentType,
          'parentId': parentId,
          'parentName': parentName,
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primaryContainer,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
        foregroundColor: theme.colorScheme.primary,
        elevation: 2,
      ),
      child: Text(title),
    ),
  );
}

Widget _buildEditButton(BuildContext context, int id, String type) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.8,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
    child: ElevatedButton(
      onPressed: () {
        context.go('/edit', extra: {'type': type, 'id': id});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
        foregroundColor: Colors.blue[900],
        elevation: 2,
      ),
      child: const Text('Edit'),
    ),
  );
}

Widget _buildDeleteButton(BuildContext context, int id, String type) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.8,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
    child: ElevatedButton(
      onPressed: () => _handleDelete(context, id, type),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[400],
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
        foregroundColor: const Color.fromARGB(255, 96, 18, 13),
        elevation: 2,
      ),
      child: const Text('Delete'),
    ),
  );
}

void _handleDelete(BuildContext context, int id, String type) async {
  try {
    await _deleteItem(context, id, type);
    context.go('/');
  } catch (e) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')));
    });
  }
}

Future<int> _deleteItem(BuildContext context, int id, String type) async {
  switch (type) {
    case 'house':
      return await Provider.of<Database>(context, listen: false)
          .deleteHouse(id);
    case 'room':
      return await Provider.of<Database>(context, listen: false).deleteRoom(id);
    case 'location':
      return await Provider.of<Database>(context, listen: false)
          .deleteLocation(id);
    case 'item':
      return await Provider.of<Database>(context, listen: false).deleteItem(id);
    default:
      throw Exception('Unsupported type: $type');
  }
}
