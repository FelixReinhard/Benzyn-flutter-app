import 'dart:async';
import 'dart:math';

import 'package:benzyn/main.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Model
class Entry {
  Entry({
    required this.id,
    required this.refuelAmount,
    required this.currentMileage,
    required this.payedPrice,
    required this.date,
    required this.bestPrice,
  });

  int id;
  Price payedPrice;
  Price bestPrice;
  double refuelAmount;
  int currentMileage;
  DateTime date;

  Map<String, dynamic> toMap() {
    final dateString = DateFormat('yyyy-MM-dd HH:mm').format(date);

    return {
      'id': id,
      'payedPriceEuro': payedPrice.euro,
      'payedPriceCent': payedPrice.cent,
      'bestPriceEuro': bestPrice.euro,
      'bestPriceCent': bestPrice.cent,
      'refuelAmount': refuelAmount,
      'currentMileage': currentMileage,
      'date': dateString,
    };
  }

  String getEfficiency() {
    // Consider the milagediffrence.
    return "10 l";
  }

  String getPricePerLiter() {
    return Price.fromDouble(payedPrice.toDouble() / refuelAmount).format();
  }

  static Entry fromMap(Map<String, dynamic> map) {
    return Entry(
        id: int.parse(map['id'] as String),
        refuelAmount: map['refuelAmount'] as double,
        currentMileage: map['currentMileage'] as int,
        payedPrice: Price(
            euro: map['payedPriceEuro'] as int,
            cent: map['payedPriceCent'] as int),
        date: DateTime.parse(map['date'] as String),
        bestPrice: Price(
            euro: map['bestPriceEuro'] as int,
            cent: map['bestPriceCent'] as int));
  }

  String dayMonth() {
    return DateFormat("dd.MM").format(date);
  }

  String time() {
    return DateFormat("HH:mm").format(date);
  }
}

class Price {
  Price({required this.euro, required this.cent});

  int euro, cent;

  String format() {
    return "$euro,$cent €";
  }

  double toDouble() {
    return euro + cent * 0.01;
  }

  static Price fromDouble(double value) {
    return Price(
        euro: value.truncate(),
        cent: ((value - value.truncate().toDouble()) * 100).truncate());
  }
}

class DatabaseInterface {
  late Future<Database> database;
  bool hasInited = false;

  Future<void> databaseSetup() async {
    // Avoid errors caused by flutter upgrade.
    // Importing 'package:flutter/widgets.dart' is required.
    WidgetsFlutterBinding.ensureInitialized();
    // Open the database and store the reference.
    //databaseFactory.deleteDatabase(join(await getDatabasesPath(), 'benzyn.db'));
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'benzyn.db'),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE entries(id TEXT PRIMARY KEY, payedPriceEuro INTEGER, payedPriceCent INTEGER, bestPriceEuro INTEGER, bestPriceCent INTEGER, refuelAmount REAL, currentMileage INTEGER, date DATETIME)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    hasInited = true;
  }

  Future<void> insertEntry(Entry entry) async {
    final db = await database;

    await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Entry>> entries(int maxAmount) async {
    if (!hasInited) await databaseSetup();
    final db = await database;

    final maps =
        await db.query('entries', limit: maxAmount, orderBy: "id DESC");

    return List.generate(maps.length, (i) {
      return Entry.fromMap(maps[i]);
    });
  }

  Future<List<Map<String, dynamic>>> getEfficiencyChartData() async {
    final entryList = await entries(50);
    var ret = <Map<String,dynamic>>[];
    //for (int i = 0; i < entries.length; i++) {
    //ret.add(EntryCard.fromEntry(entries[i], entries[min(entries.length - 1, i+1)]));

    if (entryList.isEmpty) return [];

    var minId = entryList[0].id; 
    var maxId = entryList[0].id;

    for (int i = 1; i < entryList.length; i++) {
      if (entryList[i].id > maxId) maxId = entryList[i].id;
      if (entryList[i].id < minId) minId = entryList[i].id;
    }

    for (int i = 0; i < entryList.length; i++) {
      ret.add({
        "x" : entryList[i].id.toDouble(),
        "y" : getEfficiencyAsList(entryList[i], entryList[min(entryList.length - 1, i+1)])[0],
        "min" : minId.toDouble(),
        "max" : maxId.toDouble(),
      });
    }
    return ret;
  }

  Future<void> delete(Entry entry) async {
    if (!hasInited) await databaseSetup();
    final db = await database;

    await db.delete('entries', where: "id = ?", whereArgs: [entry.id]);
  }

  // get Entry before the argument or 0
  Future<Entry?> before(Entry entry) async {
    if (!hasInited) await databaseSetup();
    final db = await database;

    final maps =
        await db.query('entries', where: 'id = ?', whereArgs: [entry.id - 1]);
    if (maps.isEmpty) {
      return null;
    } else {
      return Entry.fromMap(maps[0]);
    }
  }
}
