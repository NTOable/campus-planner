class Event {
  final int? id;
  final String title;
  final String location;
  final int? head_count;

  Event({this.id, required this.title, required this.location, required this.head_count});

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'location': location, 'head count': head_count};
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(id: map['id'], title: map['title'], location: map['location'], head_count: map['head count']);
  }
}
