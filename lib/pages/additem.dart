import 'dart:io';
import '/database.dart';
import '/util/camera.dart';
import '/util/parent.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AddItemPage extends StatefulWidget {
  final String? addingType;
  final ParentParams parent;

  const AddItemPage({super.key, this.addingType, required this.parent});

  @override
  AddItemPageState createState() => AddItemPageState();
}

class AddItemPageState extends State<AddItemPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController houseController = TextEditingController();
  TextEditingController roomController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  List<House> houses = [];
  List<Location> locations = [];
  List<Room> rooms = [];

  House? selectedHouse;
  Room? selectedRoom;
  Location? selectedLocation;

  bool houseSectionVisible = false;
  bool roomSectionVisible = false;
  bool locationSectionVisible = false;

  bool houseRequired = false;
  bool roomRequired = false;
  bool locationRequired = false;

  XFile? _image;

  late String singularType;

  @override
  void initState() {
    singularType = widget.addingType!.isNotEmpty
        ? widget.addingType!.substring(0, widget.addingType!.length - 1)
        : '';
    setRequirements();
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final db = Provider.of<Database>(context, listen: false);

    if (widget.parent.isNull) {
      final allHouses = await db.getAllHouses();
      setState(() {
        houses = allHouses;
        if (houses.length == 1) {
          selectedHouse = houses.first;
          _loadRoomsForHouse(selectedHouse!.id);
        }
      });
    } else {
      switch (widget.parent.type) {
        case "house":
          _loadRoomsForHouse(widget.parent.id!);
          break;
        case "room":
          _loadLocationsForRoom(widget.parent.id!);
          break;
        case "location":
          break;
      }
    }
  }

  Future<void> _loadRoomsForHouse(int houseId) async {
    final db = Provider.of<Database>(context, listen: false);
    final houseRooms = await db.getRoomsInHouse(houseId);
    setState(() {
      rooms = houseRooms;
      if (rooms.length == 1) {
        selectedRoom = rooms.first;
        _loadLocationsForRoom(selectedRoom!.id);
      }
    });
  }

  Future<void> _loadLocationsForRoom(int roomId) async {
    final db = Provider.of<Database>(context, listen: false);
    final roomLocations = await db.getLocationsInRoom(roomId);
    setState(() {
      locations = roomLocations;
      if (locations.length == 1) {
        selectedLocation = locations.first;
      }
    });
  }

  bool canSubmit() {
    bool isSectionValid(TextEditingController controller, dynamic selectedItem,
        bool sectionVisible, bool sectionRequired) {
      if (sectionRequired) {
        return selectedItem != null ||
            (sectionVisible && controller.text.isNotEmpty);
      }
      return true;
    }

    bool isNameValid = nameController.text.isNotEmpty;

    bool isHouseValid = isSectionValid(
        houseController, selectedHouse, houseSectionVisible, houseRequired);
    bool isRoomValid = isSectionValid(
        roomController, selectedRoom, roomSectionVisible, roomRequired);
    bool isLocationValid = isSectionValid(locationController, selectedLocation,
        locationSectionVisible, locationRequired);

    return isNameValid && isHouseValid && isRoomValid && isLocationValid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text("Add new $singularType")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
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
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "$singularType name",
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            ...buildSections(context),
            ElevatedButton(
              onPressed: canSubmit() ? submitData : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  minimumSize: const Size(double.infinity, 50)),
              child: Text("Add $singularType"),
            ),
          ],
        ),
      ),
    );
  }

  void setRequirements() {
    if (widget.addingType == "houses") {
      return;
    }

    if (widget.parent.isNull) {
      if ({"rooms", "locations", "items"}.contains(widget.addingType)) {
        houseRequired = true;
      }

      if ({"locations", "items"}.contains(widget.addingType)) {
        roomRequired = true;
      }

      if ({"items"}.contains(widget.addingType)) {
        locationRequired = true;
      }
    } else {
      // special cases for when we have a parent, but dont know the room/location
      if (widget.addingType == "locations" && widget.parent.type == "house") {
        roomRequired = true;
      }
      if (widget.addingType == "items" && widget.parent.type == "room") {
        locationRequired = true;
      }
      if (widget.addingType == "items" && widget.parent.type == "house") {
        roomRequired = true;
        locationRequired = true;
      }
    }
  }

  // this has to be illegal somewhere
  List<Widget> buildSections(BuildContext context) {
    List<Widget> list = [];

    if (widget.addingType == "houses") {
      return list;
    }

    if (houseRequired) {
      list.add(const SizedBox(height: 20));
      list.add(buildSection("Choose an inventory", "house", houses,
          selectedHouse, houseSectionVisible, houseController));
    }

    if (roomRequired) {
      list.add(const SizedBox(height: 20));
      list.add(buildSection("Choose a room", "room", rooms, selectedRoom,
          roomSectionVisible, roomController));
    }

    if (locationRequired) {
      list.add(const SizedBox(height: 20));
      list.add(buildSection("Choose a location", "location", locations,
          selectedLocation, locationSectionVisible, locationController));
    }

    list.add(const SizedBox(height: 20));
    return list;
  }

  Widget buildSection(String header, String type, List<dynamic> items,
      dynamic selectedItem, bool isAdding, TextEditingController controller) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(header, style: Theme.of(context).textTheme.titleLarge),
        Wrap(
          spacing: 8.0,
          children: items
                  .map<Widget>((item) => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: selectedItem == item
                                ? theme.colorScheme.primaryContainer
                                : Colors.black),
                        child: Text(item.name),
                        onPressed: () => selectItem(item, type),
                      ))
                  .toList() +
              [if (!isAdding) buildAddNewButton(type)],
        ),
        if (isAdding)
          TextField(
            controller: controller,
            decoration: InputDecoration(labelText: "New $type name"),
            onChanged: (_) => setState(() {}),
          ),
      ],
    );
  }

  // this is disgusting lol
  void selectItem(dynamic item, String sectionName) {
    setState(() {
      switch (sectionName) {
        case "house":
          selectedHouse = item;
          houseSectionVisible = false;
          roomSectionVisible = false;
          locationSectionVisible = false;
          rooms = [];
          locations = [];
          _loadRoomsForHouse(item.id);
          break;
        case "room":
          selectedRoom = item;
          roomSectionVisible = false;
          locationSectionVisible = false;
          locations = [];
          _loadLocationsForRoom(item.id);
          break;
        case "location":
          selectedLocation = item;
          locationSectionVisible = false;
          break;
      }
    });
  }

  Widget buildAddNewButton(String type) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
        onPressed: () {
          setState(() {
            switch (type) {
              case "house":
                houseSectionVisible = true;
                selectedHouse = null;
                rooms = [];
                locations = [];
                roomSectionVisible = true;
                locationSectionVisible = true;
                break;
              case "room":
                roomSectionVisible = true;
                selectedRoom = null;
                locations = [];
                locationSectionVisible = true;
                break;
              case "location":
                locationSectionVisible = true;
                selectedLocation = null;
                break;
            }
          });
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer),
        icon: const Icon(Icons.add),
        label: const Text("New"));
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext _) {
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
                      });
                    }),
              ],
            ),
          );
        });
  }

  void submitData() async {
    if (!canSubmit()) {
      return;
    }

    final db = Provider.of<Database>(context, listen: false);
    String? imagePath = _image?.path;

    // todo, submit the correct one and only the required ones

    try {
      int houseId = selectedHouse?.id ?? 0;
      int roomId = selectedRoom?.id ?? 0;
      int locationId = selectedLocation?.id ?? 0;

      if (!widget.parent.isNull) {
        switch (widget.parent.type) {
          case "house":
            houseId = widget.parent.id!;
            break;
          case "room":
            roomId = widget.parent.id!;
            break;
          case "location":
            locationId = widget.parent.id!;
            break;
        }
      }

      if (houseRequired) {
        if (houseController.text.isNotEmpty) {
          houseId = await db.addHouse(houseController.text, null);
        }
      }

      if (roomRequired) {
        if (roomController.text.isNotEmpty) {
          roomId = await db.addRoom(roomController.text, houseId, null);
        }
      }

      if (locationRequired) {
        if (locationController.text.isNotEmpty) {
          locationId =
              await db.addLocation(locationController.text, roomId, null);
        }
      }

      switch (widget.addingType) {
        case "houses":
          await db.addHouse(nameController.text, imagePath);
          break;
        case "rooms":
          await db.addRoom(nameController.text, houseId, imagePath);
          break;
        case "locations":
          await db.addLocation(nameController.text, roomId, imagePath);
          break;
        case "items":
          await db.addItem(nameController.text, locationId, imagePath);
          break;
      }

      context.go('/');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$singularType added successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }
}
