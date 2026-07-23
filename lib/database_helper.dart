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
    return await openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
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

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS event_registrations');
    await db.execute('DROP TABLE IF EXISTS gfg_events');
    await db.execute('DROP TABLE IF EXISTS gfg_users');
    await _onCreate(db, newVersion);
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

  Future<List<Event>> getEventsByMonth(int year, int month) async {
    Database db = await instance.db;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final result = await db.query(
      'gfg_events',
      where: 'date LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'date ASC, time ASC',
    );
    return result.map((map) => Event.fromMap(map)).toList();
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
    await db.delete('event_registrations');
    await db.delete('gfg_events');

    final pastAcademicEvents = [
      _makeEvent(
        title: 'Final Examinations (Term 2)',
        description: 'Final exams for the previous term have concluded.',
        location: 'Various Rooms',
        date: '2026-06-16', time: '08:00', type: 'academic', capacity: 500, status: 'completed',
      ),
      _makeEvent(
        title: 'Quiz: React Components & State',
        description: 'Quiz on React component lifecycle, props, and state management.',
        location: 'Online',
        date: '2026-06-20', time: '10:00', type: 'academic', capacity: 9999, status: 'completed',
      ),
      _makeEvent(
        title: 'Assignment: API Integration Lab',
        description: 'Build a REST API client that fetches and displays data from a public API.',
        location: 'Online',
        date: '2026-06-23', time: '23:59', type: 'academic', capacity: 9999, status: 'completed',
      ),
      _makeEvent(
        title: 'Enrollment for Term 3',
        description: 'Online and onsite enrollment for Term 3.',
        location: 'Campus Registrar',
        date: '2026-07-10', time: '08:00', type: 'academic', capacity: 1000, status: 'completed',
      ),
    ];

    final pastCampusEvents = [
      _makeEvent(
        title: 'Student Org Fair (Term 2)',
        description: 'Student organizations showcase from last term.',
        location: 'Main Lobby',
        date: '2026-06-25', time: '09:00', type: 'campus', capacity: 400, status: 'completed',
      ),
      _makeEvent(
        title: 'Design Thinking Workshop',
        description: 'Learn design thinking methodology and apply it to real-world challenges.',
        location: 'Studio Room 301',
        date: '2026-07-05', time: '13:00', type: 'campus', capacity: 35, status: 'completed',
      ),
    ];

    final academicEvents = [
      _makeEvent(
        title: 'Start of Filing for Change of Grades',
        description: 'Students may file for change of grades through the online portal or at the Campus Registrar.',
        location: 'Campus Registrar',
        date: '2026-07-30', time: '08:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Release of Final Grades',
        description: 'Final grades for the previous term will be available on the student portal.',
        location: 'N/A',
        date: '2026-07-30', time: '00:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Midterm Examinations',
        description: 'Midterm exams for all departments. Check your student portal for specific room and schedule assignments.',
        location: 'Various Rooms',
        date: '2026-09-14', time: '08:00', type: 'academic', capacity: 500,
      ),
      _makeEvent(
        title: 'Enrollment for Next Semester',
        description: 'Online and onsite enrollment for the upcoming semester. Clear all financial obligations before enrolling.',
        location: 'Campus Registrar',
        date: '2026-10-20', time: '08:00', type: 'academic', capacity: 1000,
      ),
      _makeEvent(
        title: 'Final Examinations',
        description: 'Final exams for the semester. Check your student portal for room assignments.',
        location: 'Various Rooms',
        date: '2026-11-16', time: '08:00', type: 'academic', capacity: 500,
      ),
      _makeEvent(
        title: 'Intramurals Week',
        description: 'Annual intramurals. Represent your year level in various sports and academic competitions.',
        location: 'Gym Left Wing',
        date: '2026-09-21', time: '07:00', type: 'academic', capacity: 500,
      ),
      _makeEvent(
        title: 'Career Fair 2026',
        description: 'Connect with hiring partners and explore internship and job opportunities.',
        location: 'Gym Right Wing',
        date: '2026-10-06', time: '09:00', type: 'academic', capacity: 400,
      ),
    ];

    final campusEvents = [
      _makeEvent(
        title: 'CIIT Week',
        description: 'A week-long celebration with booths, games, live performances, and organization exhibits.',
        location: 'Gym Left Wing',
        date: '2026-08-04', time: '08:00', type: 'campus', capacity: 500, registeredCount: 350,
      ),
      _makeEvent(
        title: 'GameDev Workshop',
        description: 'Hands-on Unity workshop. Bring your own laptop. Limited slots available.',
        location: 'PC Lab 1',
        date: '2026-08-08', time: '10:00', type: 'campus', capacity: 30, registeredCount: 30,
      ),
      _makeEvent(
        title: 'Film Showing: Student Short Films',
        description: 'Screening of the best student short films from the past semester.',
        location: 'Bleacher Right Wing (Theatre)',
        date: '2026-08-22', time: '17:00', type: 'campus', capacity: 150,
      ),
      _makeEvent(
        title: 'Sports Fest 2026',
        description: 'Annual sports competition. Register your team at the Student Affairs office.',
        location: 'Gym Left Wing',
        date: '2026-09-07', time: '07:00', type: 'campus', capacity: 300,
      ),
      _makeEvent(
        title: 'Music Jam Night',
        description: 'Open mic night featuring CIIT\'s finest musicians and bands. Sign up to perform!',
        location: 'Canteen',
        date: '2026-09-25', time: '18:00', type: 'campus', capacity: 120,
      ),
      _makeEvent(
        title: 'Student Org Fair',
        description: 'Explore student organizations, talk to members, and sign up for the ones that interest you.',
        location: 'Main Lobby',
        date: '2026-10-02', time: '09:00', type: 'campus', capacity: 400,
      ),
      _makeEvent(
        title: 'Hackathon 2026',
        description: '48-hour coding competition. Form teams of 3-5 and build something amazing. Prizes for top 3 teams.',
        location: 'PC Lab 2',
        date: '2026-11-06', time: '08:00', type: 'campus', capacity: 60, registeredCount: 60,
      ),
      _makeEvent(
        title: 'Portfolio Review Day',
        description: 'Get your portfolio reviewed by industry professionals. Bring printed or digital copies.',
        location: 'Drawing Room',
        date: '2026-09-12', time: '10:00', type: 'campus', capacity: 50,
      ),
      _makeEvent(
        title: 'Digital Art Exhibit',
        description: 'Showcase of student digital artwork. Open for viewing all day.',
        location: 'Pen Display Lab 1',
        date: '2026-10-24', time: '09:00', type: 'campus', capacity: 80,
      ),
      _makeEvent(
        title: 'Band Practice: Talent Night Prep',
        description: 'Rehearsal session for bands performing at Talent Night.',
        location: 'Recording Room',
        date: '2026-11-13', time: '16:00', type: 'campus', capacity: 20,
      ),
    ];

    final assignments = [
      _makeEvent(
        title: 'Assignment: Final Project - Algorithms & Complexity',
        description: 'Implement a pathfinding algorithm comparison. Submit via Canvas before the deadline.',
        location: 'Online',
        date: '2026-07-24', time: '21:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Assignment: Group Music Video (Rizal)',
        description: 'Produce a 3-5 minute music video creatively presenting one of Rizal\'s works. Groups of 5-8 members.',
        location: 'Online',
        date: '2026-07-25', time: '11:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Assignment: Reaction Paper - Noli Me Tangere',
        description: 'Write a 2-page reaction paper on selected chapters of Noli Me Tangere. MLA format.',
        location: 'Online',
        date: '2026-08-01', time: '23:59', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Assignment: Case Study - Database Design',
        description: 'Design a normalized database schema for a given business scenario. Submit ERD and SQL scripts.',
        location: 'Online',
        date: '2026-08-07', time: '17:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Assignment: Reflection Essay - Rizal\'s Legacy',
        description: 'Write a 1-page reflection on how Rizal\'s works impact today\'s generation.',
        location: 'Online',
        date: '2026-08-14', time: '23:59', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Assignment: Programming Lab - Sorting Algorithms',
        description: 'Implement and compare bubble sort, merge sort, and quicksort. Submit source code and output screenshots.',
        location: 'Online',
        date: '2026-08-21', time: '17:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Assignment: Group Project - UI/UX Prototype',
        description: 'Create a high-fidelity Figma prototype for a mobile app of your choice. Groups of 3-4.',
        location: 'Online',
        date: '2026-09-04', time: '21:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Assignment: Research Paper Draft',
        description: 'Submit the first draft of your research paper including introduction, related studies, and methodology.',
        location: 'Online',
        date: '2026-09-18', time: '23:59', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Assignment: Art Portfolio Submission',
        description: 'Compile and submit your digital art portfolio for the semester. Minimum 10 pieces.',
        location: 'Online',
        date: '2026-09-25', time: '17:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Assignment: Final Research Paper',
        description: 'Submit the final version of your research paper with results and conclusion.',
        location: 'Online',
        date: '2026-10-16', time: '23:59', type: 'academic', capacity: 9999,
      ),
    ];

    final seminarsWorkshopsQuizzes = [
      _makeEvent(
        title: 'Seminar: AI & Machine Learning',
        description: 'Guest lecture on practical applications of AI and ML in the industry.',
        location: 'Lecture Room 604',
        date: '2026-07-28', time: '14:00', type: 'campus', capacity: 60, registeredCount: 47,
      ),
      _makeEvent(
        title: 'Workshop: UI/UX Design Fundamentals',
        description: 'Hands-on workshop covering wireframing, prototyping, and user testing. Bring your laptop.',
        location: 'Pen Display Lab 1',
        date: '2026-07-29', time: '10:00', type: 'campus', capacity: 25, registeredCount: 25,
      ),
      _makeEvent(
        title: 'Workshop: Rizal in Film',
        description: 'Analyzing cinematic adaptations of Rizal\'s works. Includes film clips and group discussion.',
        location: 'Bleacher Right Wing (Theatre)',
        date: '2026-08-02', time: '13:00', type: 'campus', capacity: 100,
      ),
      _makeEvent(
        title: 'Quiz 1',
        description: 'Quiz on Big-O notation and algorithm analysis. Online via Canvas.',
        location: 'Online',
        date: '2026-08-06', time: '10:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Quiz 1',
        description: 'Quiz on Noli Me Tangere chapters 1-10. Online via Canvas.',
        location: 'Online',
        date: '2026-08-13', time: '14:00', type: 'academic', capacity: 9999,
      ),
      _makeEvent(
        title: 'Seminar: Cybersecurity Awareness',
        description: 'Learn about common threats, phishing, and how to protect your data online.',
        location: 'Lecture Room 605',
        date: '2026-08-18', time: '13:00', type: 'campus', capacity: 60,
      ),
      _makeEvent(
        title: 'Quiz 2',
        description: 'Quiz on arrays, linked lists, and stacks. Onsite.',
        location: 'PC Lab 1',
        date: '2026-08-20', time: '10:00', type: 'academic', capacity: 30,
      ),
      _makeEvent(
        title: 'Quiz 2',
        description: 'Quiz on El Filibusterismo chapters 1-15. Onsite.',
        location: 'Lecture Room 504',
        date: '2026-08-27', time: '14:00', type: 'academic', capacity: 60,
      ),
      _makeEvent(
        title: 'Workshop: Digital Illustration',
        description: 'Hands-on session with pen display tablets. Create a digital illustration from sketch to final.',
        location: 'Pen Display Lab 2',
        date: '2026-09-01', time: '10:00', type: 'campus', capacity: 25,
      ),
      _makeEvent(
        title: 'Seminar: Cloud Computing & DevOps',
        description: 'Introduction to cloud services, CI/CD pipelines, and deployment best practices.',
        location: 'Lecture Room 606',
        date: '2026-09-08', time: '14:00', type: 'campus', capacity: 60,
      ),
      _makeEvent(
        title: 'Workshop: Game Design Essentials',
        description: 'From concept to prototype. Learn the fundamentals of game design and level planning.',
        location: 'PC Lab 2',
        date: '2026-09-15', time: '10:00', type: 'campus', capacity: 30,
      ),
      _makeEvent(
        title: 'Seminar: Machine Learning for Beginners',
        description: 'An introductory talk on supervised vs unsupervised learning with real-world examples.',
        location: 'Lecture Room 604',
        date: '2026-09-22', time: '13:00', type: 'campus', capacity: 60,
      ),
    ];

    final now = DateTime.now();
    final testNotifTime = now.add(const Duration(hours: 1));
    final testEvent = _makeEvent(
      title: 'TEST: Notification Demo Event',
      description: 'This event is for testing the notification system. It will trigger a notification in ~1 hour.',
      location: 'PC Lab 1',
      date: '${testNotifTime.year}-${testNotifTime.month.toString().padLeft(2, '0')}-${testNotifTime.day.toString().padLeft(2, '0')}',
      time: '${testNotifTime.hour.toString().padLeft(2, '0')}:${testNotifTime.minute.toString().padLeft(2, '0')}',
      type: 'campus', capacity: 30,
    );

    for (final event in pastAcademicEvents) {
      await db.insert('gfg_events', event.toMap());
    }
    for (final event in pastCampusEvents) {
      await db.insert('gfg_events', event.toMap());
    }
    for (final event in academicEvents) {
      await db.insert('gfg_events', event.toMap());
    }
    for (final event in campusEvents) {
      await db.insert('gfg_events', event.toMap());
    }
    for (final event in assignments) {
      await db.insert('gfg_events', event.toMap());
    }
    for (final event in seminarsWorkshopsQuizzes) {
      await db.insert('gfg_events', event.toMap());
    }
    await db.insert('gfg_events', testEvent.toMap());

    final demoUser = User(username: 'Demo User', email: 'demo@ciit.edu.ph', password: 'demo123');
    final existing = await db.query('gfg_users', where: 'email = ?', whereArgs: [demoUser.email]);
    if (existing.isEmpty) {
      await db.insert('gfg_users', demoUser.toMap());
    }
  }
}
