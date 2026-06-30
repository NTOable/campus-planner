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
    String path = join(databasesPath, 'campus_planner.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE gfg_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE gfg_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        location TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        type TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        registered_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'upcoming'
      )
    ''');
    await db.execute('''
      CREATE TABLE event_registrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (event_id) REFERENCES gfg_events(id),
        FOREIGN KEY (user_id) REFERENCES gfg_users(id),
        UNIQUE(event_id, user_id)
      )
    ''');
  }

  Future<User?> login(String email, String password) async {
    Database db = await instance.db;
    final result = await db.query(
      'gfg_users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertUser(User user) async {
    Database db = await instance.db;
    return await db.insert('gfg_users', user.toMap());
  }

  Future<bool> emailExists(String email) async {
    Database db = await instance.db;
    final result = await db.query(
      'gfg_users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> queryAllUsers() async {
    Database db = await instance.db;
    return await db.query('gfg_users');
  }

  Future<int> deleteUser(int id) async {
    Database db = await instance.db;
    return await db.delete('gfg_users', where: 'id = ?', whereArgs: [id]);
  }

  bool isValidSchoolEmail(String email) {
    return email.endsWith('@ciit.edu.ph');
  }

  Future<int> insertEvent(Event event) async {
    Database db = await instance.db;
    return await db.insert('gfg_events', event.toMap());
  }

  Future<List<Event>> getEventsByType(String type) async {
    Database db = await instance.db;
    final result = await db.query(
      'gfg_events',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date ASC, time ASC',
    );
    return result.map((map) => Event.fromMap(map)).toList();
  }

  Future<List<Event>> searchEvents(String query) async {
    Database db = await instance.db;
    final result = await db.query(
      'gfg_events',
      where: 'title LIKE ? OR description LIKE ? OR location LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date ASC',
    );
    return result.map((map) => Event.fromMap(map)).toList();
  }

  Future<bool> registerForEvent(int eventId, int userId) async {
    Database db = await instance.db;
    try {
      await db.insert('event_registrations', {
        'event_id': eventId,
        'user_id': userId,
      });
      await db.rawUpdate(
        'UPDATE gfg_events SET registered_count = registered_count + 1 WHERE id = ?',
        [eventId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isUserRegistered(int eventId, int userId) async {
    Database db = await instance.db;
    final result = await db.query(
      'event_registrations',
      where: 'event_id = ? AND user_id = ?',
      whereArgs: [eventId, userId],
    );
    return result.isNotEmpty;
  }

  Future<List<Event>> getRegisteredEvents(int userId) async {
    Database db = await instance.db;
    final result = await db.rawQuery('''
      SELECT e.* FROM gfg_events e
      INNER JOIN event_registrations r ON e.id = r.event_id
      WHERE r.user_id = ?
      ORDER BY e.date ASC
    ''', [userId]);
    return result.map((map) => Event.fromMap(map)).toList();
  }

  Future<List<int>> getRegisteredEventIds(int userId) async {
    Database db = await instance.db;
    final result = await db.query(
      'event_registrations',
      columns: ['event_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.map((m) => m['event_id'] as int).toList();
  }

  Future<bool> cancelRegistration(int eventId, int userId) async {
    Database db = await instance.db;
    try {
      await db.delete(
        'event_registrations',
        where: 'event_id = ? AND user_id = ?',
        whereArgs: [eventId, userId],
      );
      await db.rawUpdate(
        'UPDATE gfg_events SET registered_count = MAX(0, registered_count - 1) WHERE id = ?',
        [eventId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Event _makeEvent({
    required String title, String description = '', required String location,
    required String date, required String time, required String type,
    required int capacity, int registeredCount = 0, String status = 'upcoming',
  }) {
    return Event(
      title: title, description: description, location: location,
      date: date, time: time, type: type, capacity: capacity,
      registeredCount: registeredCount, status: status,
    );
  }

  Future<void> seedInitialData() async {
    Database db = await instance.db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM gfg_events'),
    );
    if (count != null && count > 0) return;

    final academicEvents = [
      _makeEvent(
        title: 'Midterm Examinations',
        description: 'Midterm exams for all departments. Check your student portal for the specific schedule per course.',
        location: 'Various Rooms',
        date: '2026-03-10', time: '08:00', type: 'academic', capacity: 500,
      ),
      _makeEvent(
        title: 'Enrollment for Next Semester',
        description: 'Online and onsite enrollment for the upcoming semester. Clear all financial obligations before enrolling.',
        location: 'Registrar\'s Office / Online Portal',
        date: '2026-03-17', time: '08:00', type: 'academic', capacity: 1000,
      ),
      _makeEvent(
        title: 'Holy Week Break',
        description: 'No classes during Holy Week. Campus will be closed.',
        location: 'N/A',
        date: '2026-04-13', time: '00:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Final Examinations',
        description: 'Final exams for the semester. Check your student portal for room assignments.',
        location: 'Various Rooms',
        date: '2026-05-19', time: '08:00', type: 'academic', capacity: 500,
      ),
      _makeEvent(
        title: 'Recognition Day',
        description: 'Awarding of certificates and medals to students who excelled this semester.',
        location: 'CIIT Auditorium',
        date: '2026-06-05', time: '09:00', type: 'academic', capacity: 300,
      ),
      _makeEvent(
        title: 'Summer Classes Start',
        description: 'First day of summer classes. Check enrollment details on your student dashboard.',
        location: 'CIIT Campus',
        date: '2026-06-09', time: '07:00', type: 'academic', capacity: 200,
      ),
      _makeEvent(
        title: 'National Heroes Day',
        description: 'Regular holiday - no classes.',
        location: 'N/A',
        date: '2026-08-25', time: '00:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Semestral Break',
        description: 'Mid-semester break. No classes but campus offices remain open.',
        location: 'N/A',
        date: '2026-10-13', time: '00:00', type: 'academic', capacity: 9999,
      ),
    ];

    final campusEvents = [
      _makeEvent(
        title: 'CIIT Week',
        description: 'A week-long celebration with booths, games, live performances, and organization exhibits.',
        location: 'CIIT Campus Grounds',
        date: '2026-02-17', time: '08:00', type: 'campus', capacity: 500,
      ),
      _makeEvent(
        title: 'Tech Talk: AI in Industry',
        description: 'Industry professionals discuss the latest trends in AI and machine learning. Open to all students.',
        location: 'Auditorium A',
        date: '2026-03-05', time: '14:00', type: 'campus', capacity: 150,
      ),
      _makeEvent(
        title: 'GameDev Workshop',
        description: 'Hands-on Unity workshop. Bring your own laptop. Limited slots available.',
        location: 'Computer Lab 3',
        date: '2026-03-22', time: '10:00', type: 'campus', capacity: 40,
      ),
      _makeEvent(
        title: 'Film Showing: Student Short Films',
        description: 'Screening of the best student short films from the past semester.',
        location: 'CIIT Mini Theater',
        date: '2026-04-03', time: '17:00', type: 'campus', capacity: 100,
      ),
      _makeEvent(
        title: 'Sports Fest 2026',
        description: 'Annual sports competition. Register your team at the Student Affairs office.',
        location: 'CIIT Gymnasium',
        date: '2026-04-28', time: '07:00', type: 'campus', capacity: 300,
      ),
      _makeEvent(
        title: 'Music Jam Night',
        description: 'Open mic night featuring CIIT\'s finest musicians and bands. Sign up to perform!',
        location: 'Student Lounge',
        date: '2026-05-15', time: '18:00', type: 'campus', capacity: 120,
      ),
      _makeEvent(
        title: 'Student Org Fair',
        description: 'Explore student organizations, talk to members, and sign up for the ones that interest you.',
        location: 'CIIT Lobby',
        date: '2026-06-12', time: '09:00', type: 'campus', capacity: 400,
      ),
      _makeEvent(
        title: 'Design Thinking Workshop',
        description: 'Learn design thinking methodology and apply it to real-world challenges.',
        location: 'Room 405',
        date: '2026-07-10', time: '13:00', type: 'campus', capacity: 35,
      ),
      _makeEvent(
        title: 'Hackathon 2026',
        description: '48-hour coding competition. Form teams of 3-5 and build something amazing. Prizes for top 3 teams.',
        location: 'CIIT Innovation Hub',
        date: '2026-08-14', time: '08:00', type: 'campus', capacity: 80,
      ),
      _makeEvent(
        title: 'Thanksgiving Mass',
        description: 'Year-end thanksgiving mass. All students and staff are invited.',
        location: 'CIIT Chapel',
        date: '2026-09-18', time: '08:00', type: 'campus', capacity: 200,
      ),
    ];

    for (final event in academicEvents) {
      await db.insert('gfg_events', event.toMap());
    }
    for (final event in campusEvents) {
      await db.insert('gfg_events', event.toMap());
    }
  }
}
