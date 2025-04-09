import 'dart:io';
import '/database.dart';
import '/util/parent.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late Future<List<dynamic>> _itemsFuture;
  String _searchTerm = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchData(context);
  }

  Future<List<dynamic>> _fetchData(BuildContext context) async {
    final database = Provider.of<Database>(context, listen: false);
    return database.getItemsSearch(search: _searchTerm);
  }

  Future<Map<String, dynamic>> _getItemPosition(int itemId) async {
    final database = Provider.of<Database>(context, listen: false);
    final item = await database.getItemById(itemId);
    final location = await database.getLocationById(item.locationId);
    final room = await database.getRoomById(location.roomId);
    final house = await database.getHouseById(room.houseId);
    return {
      'item': item,
      'location': location.name,
      'room': room.name,
      'house': house.name,
    };
  }

  void _showItemPos(int itemId) async {
    final details = await _getItemPosition(itemId);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(details['item'].name, textAlign: TextAlign.center),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                details['location'],
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                details['room'],
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                details['house'],
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void updateSearchTerm(String value) {
    setState(() {
      _searchTerm = value;
      _itemsFuture = _fetchData(context);
    });
  }

  void _toggleSearchVisibility() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Image(
                image: AssetImage('assets/images/ic_launcher.png'),
                height: 60,
              ),
            ),
            Text(
              "lookt",
              style: GoogleFonts.kumbhSans(fontSize: 28),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isSearchVisible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(fontSize: 16),
                  filled: true,
                  fillColor: theme.colorScheme.primaryContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  suffixIcon: Icon(Icons.search,
                      color: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor),
                ),
                style: const TextStyle(fontSize: 18, height: 1),
                onChanged: updateSearchTerm,
              ),
            ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    padding: const EdgeInsets.all(8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];
                      return InkWell(
                          onTap: () => _showItemPos(item.id),
                          child: Container(
                            decoration: BoxDecoration(
                              color: item.imagePath == null
                                  ? theme.colorScheme.primaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              image: item.imagePath != null
                                  ? DecorationImage(
                                      image: FileImage(File(item.imagePath)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: item.imagePath != null
                                ? Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.primaryContainer
                                            .withOpacity(0.65),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: Text(
                                        item.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        item.name,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                  ),
                          ));
                    },
                  );
                } else {
                  return const Center(child: Text('No data :('));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _toggleSearchVisibility,
            heroTag: '1',
            child: const Icon(Icons.search),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              context.go('/additem', extra: {
                'type': "items",
                'parent': ParentParams(type: null, id: null, name: null),
              });
            },
            heroTag: '2',
            child: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
