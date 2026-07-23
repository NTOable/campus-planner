class Event {
  final int? id;
  final String title;
  final String description;
  final String location;
  final String date;
  final String time;
  final String type;
  final int capacity;
  final int registeredCount;
  final String status;

  Event({
    this.id,
    required this.title,
    this.description = '',
    required this.location,
    required this.date,
    required this.time,
    required this.type,
    required this.capacity,
    this.registeredCount = 0,
    this.status = 'upcoming',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'location': location,
    'date': date,
    'time': time,
    'type': type,
    'capacity': capacity,
    'registered_count': registeredCount,
    'status': status,
  };

  factory Event.fromMap(Map<String, dynamic> map) => Event(
    id: map['id'],
    title: map['title'],
    description: map['description'] ?? '',
    location: map['location'],
    date: map['date'],
    time: map['time'],
    type: map['type'],
    capacity: map['capacity'],
    registeredCount: map['registered_count'] ?? 0,
    status: map['status'] ?? 'upcoming',
  );
}
