class Event {
  final int? id;
  final String title;
  final String location;
  final int? headCount;

  Event({this.id, required this.title, required this.location, required this.headCount});

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'location': location, 'head count': headCount};
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(id: map['id'], title: map['title'], location: map['location'], headCount: map['head count']);
  }
}
