import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'services/firestore_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_performance/firebase_performance.dart';

part 'database.g.dart';

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get locationId => integer().references(Locations, #id)();
  TextColumn get imagePath => text().nullable()();
}

class Locations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get roomId => integer().references(Rooms, #id)();
  TextColumn get imagePath => text().nullable()();
}

class Rooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get houseId => integer().references(Houses, #id)();
  TextColumn get imagePath => text().nullable()();
}

class Houses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get imagePath => text().nullable()();
}

class Changes extends Table {
  IntColumn get id => integer().autoIncrement()(); // primary key
  DateTimeColumn get createdTime => dateTime()();
  IntColumn get houseId => integer().nullable().references(Houses, #id)();
  IntColumn get roomId => integer().nullable().references(Rooms, #id)();
  IntColumn get locationId => integer().nullable().references(Locations, #id)();
  IntColumn get itemId => integer().nullable().references(Items, #id)();
  TextColumn get action => text()(); // insert or delete
}

@DriftDatabase(tables: [Items, Locations, Rooms, Houses, Changes])
class Database extends _$Database {
  final FirestoreService firestoreService = FirestoreService();

  Database(super.e);

  @override
  int get schemaVersion => 3;

  // getAllX
  Future<List<House>> getAllHouses() async {
    return select(houses).get();
  }

  Future<List<Room>> getAllRooms() async {
    return select(rooms).get();
  }

  Future<List<Location>> getAllLocations() async {
    return select(locations).get();
  }

  Future<List<Item>> getAllItems() async {
    return select(items).get();
  }

  Future<List<Item>> getItemsSearch({String search = ""}) async {
    if (search.isEmpty) {
      return getAllItems();
    } else {
      return (select(items)
            ..where(
                (tbl) => tbl.name.lower().like("%${search.toLowerCase()}%")))
          .get();
    }
  }

  Future<Change?> getFirstChange() async {
    List<Change> result = await (select(changes)
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdTime),
            (t) => OrderingTerm.asc(t.houseId),
            (t) => OrderingTerm.asc(t.roomId),
            (t) => OrderingTerm.asc(t.locationId),
            (t) => OrderingTerm.asc(t.itemId),
          ]))
        .get();
    return result.isNotEmpty ? result.first : null;
  }

  // get by id
  Future<House> getHouseById(int id) async {
    return (select(houses)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<Room> getRoomById(int id) async {
    return (select(rooms)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<Location> getLocationById(int id) async {
    return (select(locations)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<Item> getItemById(int id) async {
    return (select(items)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  // addX
  Future<int> addHouse(String name, [String? imagePath, int? id]) async {
    final house = HousesCompanion.insert(
        id: id == null ? const Value.absent() : Value(id),
        name: name,
        imagePath: Value(imagePath));
    int houseId = await into(houses).insert(house);

    await addChange('insert', houseId: houseId);

    return houseId;
  }

  Future<int> addRoom(String name, int houseId,
      [String? imagePath, int? id]) async {
    final room = RoomsCompanion.insert(
        id: id == null ? const Value.absent() : Value(id),
        name: name,
        houseId: houseId,
        imagePath: Value(imagePath));
    int roomId = await into(rooms).insert(room);

    await addChange('insert', houseId: houseId, roomId: roomId);

    return roomId;
  }

  Future<int> addLocation(String name, int roomId,
      [String? imagePath, int? id]) async {
    final location = LocationsCompanion.insert(
        id: id == null ? const Value.absent() : Value(id),
        name: name,
        roomId: roomId,
        imagePath: Value(imagePath));
    int locationId = await into(locations).insert(location);

    Room room = await getRoomById(roomId);
    int houseId = room.houseId;

    await addChange('insert',
        houseId: houseId, roomId: roomId, locationId: locationId);
    return locationId;
  }

  Future<int> addItem(String name, int locationId,
      [String? imagePath, int? id]) async {
    Trace customTrace = FirebasePerformance.instance.newTrace('Add-Item-Trace');
    await customTrace.start();
    final item = ItemsCompanion.insert(
        id: id == null ? const Value.absent() : Value(id),
        name: name,
        locationId: locationId,
        imagePath: Value(imagePath));
    int itemId = await into(items).insert(item);

    Location location = await getLocationById(locationId);
    Room room = await getRoomById(location.roomId);
    int houseId = room.houseId;

    await addChange('insert',
        houseId: houseId,
        roomId: location.roomId,
        locationId: locationId,
        itemId: itemId);

    await customTrace.stop();

    return itemId;
  }

  Future<int> addChange(String action,
      {int? houseId, int? roomId, int? locationId, int? itemId}) {
    final change = ChangesCompanion.insert(
        action: action,
        houseId: Value(houseId),
        roomId: Value(roomId),
        locationId: Value(locationId),
        itemId: Value(itemId),
        createdTime: DateTime.now());
    return into(changes).insert(change);
  }

  // get x in y
  Future<List<Room>> getRoomsInHouse(int houseId) {
    return (select(rooms)..where((tbl) => tbl.houseId.equals(houseId))).get();
  }

  Future<List<Location>> getLocationsInRoom(int roomId) {
    return (select(locations)..where((tbl) => tbl.roomId.equals(roomId))).get();
  }

  Future<List<Item>> getItemsInLocation(int locationId) {
    return (select(items)..where((tbl) => tbl.locationId.equals(locationId)))
        .get();
  }

  Future<List<Location>> getLocationsInHouse(int houseId) {
    final query = select(locations).join([
      innerJoin(rooms, rooms.id.equalsExp(locations.roomId)),
    ])
      ..where(rooms.houseId.equals(houseId));

    return query.map((row) {
      return row.readTable(locations);
    }).get();
  }

  Future<List<Item>> getItemsInRoom(int roomId) {
    final query = select(items).join([
      innerJoin(locations, locations.id.equalsExp(items.locationId)),
      innerJoin(rooms, rooms.id.equalsExp(locations.roomId)),
    ])
      ..where(rooms.id.equals(roomId));

    return query.map((row) {
      return row.readTable(items);
    }).get();
  }

  Future<List<Item>> getItemsInHouse(int houseId) {
    final query = select(items).join([
      innerJoin(locations, locations.id.equalsExp(items.locationId)),
      innerJoin(rooms, rooms.id.equalsExp(locations.roomId)),
    ])
      ..where(rooms.houseId.equals(houseId));

    return query.map((row) {
      return row.readTable(items);
    }).get();
  }

  // cascading delete
  Future<int> deleteHouse(int houseId) async {
    return transaction(() async {
      var roomIds = await (select(rooms)
            ..where((tbl) => tbl.houseId.equals(houseId)))
          .map((m) => m.id)
          .get();
      for (var roomId in roomIds) {
        await deleteRoom(roomId);
      }

      int deletedHouse =
          await (delete(houses)..where((tbl) => tbl.id.equals(houseId))).go();

      await addChange('delete', houseId: houseId);

      return deletedHouse;
    });
  }

  Future<int> deleteRoom(int roomId) async {
    return transaction(() async {
      var locationIds = await (select(locations)
            ..where((tbl) => tbl.roomId.equals(roomId)))
          .map((m) => m.id)
          .get();
      for (var locationId in locationIds) {
        await deleteLocation(locationId);
      }

      Room room = await getRoomById(roomId);

      int deletedRoom =
          await (delete(rooms)..where((tbl) => tbl.id.equals(roomId))).go();

      await addChange('delete', houseId: room.houseId, roomId: roomId);

      return deletedRoom;
    });
  }

  Future<int> deleteLocation(int locationId) async {
    return transaction(() async {
      await (delete(items)..where((tbl) => tbl.locationId.equals(locationId)))
          .go();

      Location location = await getLocationById(locationId);
      Room room = await getRoomById(location.roomId);
      int houseId = room.houseId;

      int deletedLocation = await (delete(locations)
            ..where((tbl) => tbl.id.equals(locationId)))
          .go();

      await addChange('delete',
          houseId: houseId, roomId: room.id, locationId: locationId);
      return deletedLocation;
    });
  }

  Future<int> deleteItem(int itemId) async {
    Item item = await getItemById(itemId);
    Location location = await getLocationById(item.locationId);
    Room room = await getRoomById(location.roomId);
    int houseId = room.houseId;

    int deletedItem =
        await (delete(items)..where((tbl) => tbl.id.equals(itemId))).go();

    await addChange('delete',
        houseId: houseId,
        roomId: room.id,
        locationId: location.id,
        itemId: itemId);

    return deletedItem;
  }

  Future<void> clearLocalDatabase() async {
    if ((await getFirstChange()) != null) {
      await delete(changes).go();
    }

    if ((await getAllItems()).isNotEmpty) {
      await delete(items).go();
    }

    if ((await getAllLocations()).isNotEmpty) {
      await delete(locations).go();
    }

    if ((await getAllRooms()).isNotEmpty) {
      await delete(rooms).go();
    }

    if ((await getAllHouses()).isNotEmpty) {
      await delete(houses).go();
    }
    return;
  }

  Future<int> deleteChange(int changeId) async {
    return (delete(changes)..where((tbl) => tbl.id.equals(changeId))).go();
  }

  Future<void> syncToFirestore() async {
    Trace customTrace = FirebasePerformance.instance.newTrace('Sync-To-Firebase-Trace');
    await customTrace.start();
    Change? change = await getFirstChange();

    if (change == null) {
      return;
    }

    if (change.action == 'insert') {
      if (change.roomId == null) {
        House house = await getHouseById(change.houseId!);
        await firestoreService.addHouseToFire(change.houseId!, house.name);
      } else if (change.locationId == null) {
        Room room = await getRoomById(change.roomId!);
        String roomName = room.name;
        await firestoreService.addRoomToFire(
            change.roomId!, roomName, change.houseId!);
      } else if (change.itemId == null) {
        Location location = await getLocationById(change.locationId!);
        String locationName = location.name;
        await firestoreService.addLocationToFire(
            change.locationId!, locationName, change.roomId!, change.houseId!);
      } else {
        Item item = await getItemById(change.itemId!);
        String itemName = item.name;
        await firestoreService.addItemToFire(change.itemId!, itemName,
            change.locationId!, change.roomId!, change.houseId!);
      }
    } else if (change.action == 'delete') {
      if (change.roomId == null) {
        await firestoreService.deleteHouseFromFire(change.houseId!);
      } else if (change.locationId == null) {
        await firestoreService.deleteRoomFromFire(
            change.roomId!, change.houseId!);
      } else if (change.itemId == null) {
        await firestoreService.deleteLocationFromFire(
            change.locationId!, change.roomId!, change.houseId!);
      } else {
        await firestoreService.deleteItemFromFire(change.itemId!,
            change.locationId!, change.roomId!, change.houseId!);
      }
    }

    await deleteChange(change.id);

    await customTrace.stop();

    if (await getFirstChange() != null) {
      await syncToFirestore();
    }

    return;
  }

  Future<void> syncFromFirestore() async {
    await clearLocalDatabase();

    List<Map<String, dynamic>> houses = await firestoreService.getHouses();
    for (var house in houses) {
      int houseId = int.parse(house['id']);
      String houseName = house['name'];
      String? houseImagePath = house['imagePath'];

      await addHouse(houseName, houseImagePath, houseId);

      List<Map<String, dynamic>> rooms =
          await firestoreService.getRooms(houseId);

      for (var room in rooms) {
        int roomId = int.parse(room['id']);
        String roomName = room['name'];
        String? roomImagePath = room['imagePath'];

        await addRoom(roomName, houseId, roomImagePath, roomId);

        List<Map<String, dynamic>> locations =
            await firestoreService.getLocations(roomId, houseId);

        for (var location in locations) {
          int locationId = int.parse(location['id']);
          String locationName = location['name'];
          String? locationImagePath = location['imagePath'];

          await addLocation(
              locationName, roomId, locationImagePath, locationId);

          List<Map<String, dynamic>> items =
              await firestoreService.getItems(locationId, roomId, houseId);

          for (var item in items) {
            int itemId = int.parse(item['id']);
            String itemName = item['name'];
            String? itemImagePath = item['imagePath'];

            await addItem(itemName, locationId, itemImagePath, itemId);
          }
        }
      }
    }
  }

  // edit functions
  Future<int> setName(String type, int id, String newName) async {
    switch (type) {
      case 'house':
        int result = await (update(houses)..where((h) => h.id.equals(id)))
            .write(HousesCompanion(name: Value(newName)));
        await addChange('insert', houseId: id);
        return result;
      case 'room':
        int result = await (update(rooms)..where((r) => r.id.equals(id)))
            .write(RoomsCompanion(name: Value(newName)));
        Room room = await getRoomById(id);
        await addChange('insert', houseId: room.houseId, roomId: id);
        return result;
      case 'location':
        int result = await (update(locations)..where((l) => l.id.equals(id)))
            .write(LocationsCompanion(name: Value(newName)));
        Location location = await getLocationById(id);
        Room room = await getRoomById(location.roomId);
        await addChange('insert',
            houseId: room.houseId, roomId: room.id, locationId: id);
        return result;
      case 'item':
        int result = await (update(items)..where((i) => i.id.equals(id)))
            .write(ItemsCompanion(name: Value(newName)));
        Item item = await getItemById(id);
        Location location = await getLocationById(item.locationId);
        Room room = await getRoomById(location.roomId);
        await addChange('insert',
            houseId: room.houseId,
            roomId: room.id,
            locationId: location.id,
            itemId: id);
        return result;
      default:
        throw Exception('Unsupported type for setName: $type');
    }
  }

  Future<int> setImage(String type, int id, String newImagePath) async {
    switch (type) {
      case 'house':
        return (update(houses)..where((h) => h.id.equals(id)))
            .write(HousesCompanion(imagePath: Value(newImagePath)));
      case 'room':
        return (update(rooms)..where((r) => r.id.equals(id)))
            .write(RoomsCompanion(imagePath: Value(newImagePath)));
      case 'location':
        return (update(locations)..where((l) => l.id.equals(id)))
            .write(LocationsCompanion(imagePath: Value(newImagePath)));
      case 'item':
        return (update(items)..where((i) => i.id.equals(id)))
            .write(ItemsCompanion(imagePath: Value(newImagePath)));
      default:
        throw Exception('Unsupported type for setImage: $type');
    }
  }
}

Future<Database> openDatabase() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File('${dbFolder.path}/local.db');
  return Database(NativeDatabase(file));
}
