import '/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  TestPageState createState() => TestPageState();
}

class TestPageState extends State<TestPage> {
  final TextEditingController _nameController = TextEditingController();
  List<House> _houses = [];

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    final db = Provider.of<Database>(context, listen: false);
    final housesList = await db.getAllHouses();
    setState(() {
      _houses = housesList;
    });
  }

  Future<void> _addHouse() async {
    if (_nameController.text.isNotEmpty) {
      final db = Provider.of<Database>(context, listen: false);
      await db.addHouse(_nameController.text);
      _nameController.clear();
      _loadHouses();
    }
  }

  Future<void> _deleteHouse(int id) async {
    await Provider.of<Database>(context, listen: false).deleteHouse(id);
    _loadHouses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'House Name',
                suffixIcon: Icon(Icons.home),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addHouse,
            child: const Text('Add House'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _houses.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_houses[index].name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteHouse(_houses[index].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
