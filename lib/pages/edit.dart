import 'dart:io';
import '/database.dart';
import '/util/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EditPage extends StatefulWidget {
  final String type;
  final int id;

  const EditPage({super.key, required this.type, required this.id});

  @override
  EditPageState createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  late Future<dynamic> itemFuture;
  TextEditingController nameController = TextEditingController();
  XFile? _image;
  bool isChanged = false;

  @override
  void initState() {
    super.initState();
    itemFuture = _fetchItem();
  }

  Future<dynamic> _fetchItem() async {
    final db = Provider.of<Database>(context, listen: false);
    dynamic item;
    switch (widget.type) {
      case 'house':
        item = await db.getHouseById(widget.id);
        break;
      case 'room':
        item = await db.getRoomById(widget.id);
        break;
      case 'location':
        item = await db.getLocationById(widget.id);
        break;
      case 'item':
        item = await db.getItemById(widget.id);
        break;
      default:
        throw Exception('Unsupported type: ${widget.type}');
    }
    nameController.text = item.name;
    return item;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.type}'),
      ),
      body: FutureBuilder<dynamic>(
        future: itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            return _buildEditForm(context, snapshot.data);
          }
          return const Center(child: Text('No data available'));
        },
      ),
    );
  }

  Widget _buildEditForm(BuildContext context, dynamic item) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showPicker(context),
            child: CircleAvatar(
              radius: 55,
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(
                        File(_image!.path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.fitHeight,
                      ),
                    )
                  : item.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(
                            File(item.imagePath),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(50)),
                          width: 100,
                          height: 100,
                          child: Icon(
                            Icons.photo_camera,
                            color: theme.colorScheme.primary,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (nameController.text != item.name) {
                setState(() {
                  isChanged = true;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isChanged ? () => _applyChanges(context, item) : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: isChanged ? Colors.blue : Colors.grey,
                minimumSize: const Size(double.infinity, 50)),
            child: const Text("Apply Changes"),
          ),
        ],
      ),
    );
  }

  void _applyChanges(BuildContext context, dynamic item) async {
    final db = Provider.of<Database>(context, listen: false);
    try {
      int nameUpdated = 0;
      int imageUpdated = 0;

      if (nameController.text != item.name) {
        nameUpdated =
            await db.setName(widget.type, widget.id, nameController.text);
      }
      if (_image != null && _image!.path != item.imagePath) {
        imageUpdated = await db.setImage(widget.type, widget.id, _image!.path);
      }

      if (nameUpdated > 0 || imageUpdated > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Changes saved successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No changes made.")),
        );
      }

      context.go("/");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply changes: ${e.toString()}')),
      );
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      final XFile? file = await imgFromGallery();
                      setState(() {
                        _image = file;
                        isChanged = true;
                      });
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? file = await imgFromCamera();
                    setState(() {
                      _image = file;
                      isChanged = true;
                    });
                  },
                ),
              ],
            ),
          );
        });
  }
}
