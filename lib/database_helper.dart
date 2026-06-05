import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'user.dart';
import 'event.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _database;

  DatabaseHelper._instance();

  Future<Database> get db async {
    _database ??= await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'geeksforgeeks.db');
    // Change below to reset current database
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE gfg_users (
        id INTEGER PRIMARY KEY,
        username TEXT,
        email TEXT
      )
    ''');
  }

  //       CREATE TABLE gfg_events (
  //       id INTEGER PRIMARY KEY,
  //       title TEXT,
  //       location TEXT,
  //       head_count INT
  //       )

  Future resetDatabase() async {
    String path = join(await getDatabasesPath(), 'geeksforgeeks.db');
    await deleteDatabase(path);
  }

  Future<int> insertUser(User user) async {
    Database db = await instance.db;
    return await db.insert('gfg_users', user.toMap());
  }

  Future<int> insertEvent(Event event) async {
    Database db = await instance.db;
    return await db.insert('gfg_events', event.toMap());
  }

  Future<List<Map<String, dynamic>>> queryAllUsers() async {
    Database db = await instance.db;
    return await db.query('gfg_users');
  }

  // Future<int> updateUser(User user) async {
  //   Database db = await instance.db;
  //   return await db.update(
  //     'gfg_users',
  //     user.toMap(),
  //     where: 'id = ?',
  //     whereArgs: [user.id],
  //   );
  // }

  Future<int> deleteUser(int id) async {
    Database db = await instance.db;
    return await db.delete('gfg_users', where: 'id = ?', whereArgs: [id]);
  }

  // Future<void> initializeUsers() async {
  //   List<User> usersToAdd = [
  //     User(username: 'John', email: 'john@example.com'),
  //   ];
  //
  //   for (User user in usersToAdd) {
  //     await insertUser(user);
  //   }
  // }

  Future <void> initializeEvents() async {
    List<Event> eventsToAdd = [
      Event(title: 'Test', location: '5th Floor', headCount: 20)
    ];

    for (Event event in eventsToAdd) {
      await insertEvent(event);
    }
  }

}
