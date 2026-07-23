import 'package:flutter/material.dart';
import 'package:campus_planner/event.dart';

class LocationScreen extends StatelessWidget {
  final Event? event;
  final Color eventColor;

  const LocationScreen({
    super.key,
    this.event,
    this.eventColor = const Color(0xFF00BCD4),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interweave Floor Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            if (event != null) ...[
              Text(event!.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: eventColor),
                  const SizedBox(width: 4),
                  Text(event!.location,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Text('${event!.date}  ${event!.time}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
            ],

            // Floor layout
            _buildFloorPlan(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorPlan(BuildContext context) {
    return Column(
      children: [
        // 8th Floor
        _buildFloorSection('8', '8th Floor', [
          _buildRoom('8-1', 'Meeting Room 1', event?.location == 'Meeting Room 1'),
          _buildRoom('8-2', 'Meeting Room 2', event?.location == 'Meeting Room 2'),
        ]),
        const SizedBox(height: 12),

        // 7th Floor
        _buildFloorSection('7', '7th Floor', [
          _buildRoom('7-1', 'Canteen', event?.location == 'Canteen'),
          _buildRoom('7-2', 'Gym Left Wing', event?.location == 'Gym Left Wing'),
          _buildRoom('7-3', 'Gym Right Wing', event?.location == 'Gym Right Wing'),
          _buildRoom('7-4', 'Bleacher Left Wing', event?.location == 'Bleacher Left Wing'),
          _buildRoom('7-5', 'Bleacher Right Wing (Theatre)', event?.location == 'Bleacher Right Wing (Theatre)'),
        ]),
        const SizedBox(height: 12),

        // 6th Floor
        _buildFloorSection('6', '6th Floor', [
          _buildRoom('6-1', 'PC Lab 1', event?.location == 'PC Lab 1'),
          _buildRoom('6-2', 'PC Lab 2', event?.location == 'PC Lab 2'),
          _buildRoom('6-3', 'Mac Lab', event?.location == '603 Mac Lab'),
          _buildRoom('6-4', 'Lecture Room 604', event?.location == 'Lecture Room 604'),
          _buildRoom('6-5', 'Lecture Room 605', event?.location == 'Lecture Room 605'),
          _buildRoom('6-6', 'Lecture Room 606', event?.location == 'Lecture Room 606'),
        ]),
        const SizedBox(height: 12),

        // 5th Floor
        _buildFloorSection('5', '5th Floor', [
          _buildRoom('5-1', 'Pen Display Lab 1', event?.location == 'Pen Display Lab 1'),
          _buildRoom('5-2', 'Pen Display Lab 2', event?.location == 'Pen Display Lab 2'),
          _buildRoom('5-3', 'Mac Lab', event?.location == '503 Mac Lab'),
          _buildRoom('5-4', 'Lecture Room 504', event?.location == 'Lecture Room 504'),
          _buildRoom('5-5', 'Lecture Room 505', event?.location == 'Lecture Room 505'),
          _buildRoom('5-6', 'Lecture Room 506', event?.location == 'Lecture Room 506'),
        ]),
        const SizedBox(height: 12),

        // 4th Floor
        _buildFloorSection('4', '4th Floor', [
          _buildRoom('4-1', 'Lecture Room 401', event?.location == 'Lecture Room 401'),
          _buildRoom('4-2', 'Lecture Room 402', event?.location == 'Lecture Room 402'),
          _buildRoom('4-3', 'Drawing Room', event?.location == 'Drawing Room'),
          _buildRoom('4-4', 'Campus Registrar', event?.location == 'Campus Registrar'),
          _buildRoom('4-5', 'Recording Room', event?.location == 'Recording Room'),
          _buildRoom('4-6', 'Meeting Room 1', event?.location == '4th Floor Meeting Room 1'),
          _buildRoom('4-7', 'Meeting Room 2', event?.location == '4th Floor Meeting Room 2'),
          _buildRoom('4-8', 'Meeting Room 3', event?.location == '4th Floor Meeting Room 3'),
        ]),
        const SizedBox(height: 12),

        // 3rd Floor
        _buildFloorSection('3', '3rd Floor', [
          _buildRoom('3-1', 'Studio Room 301', event?.location == 'Studio Room 301'),
          _buildRoom('3-2', 'Mac Lab', event?.location == '302 Mac Lab'),
          _buildRoom('3-3', "Instructors' Office", event?.location == "Instructors' Office"),
          _buildRoom('3-4', 'Guidance Counseling', event?.location == 'Guidance Counseling'),
        ]),
        const SizedBox(height: 12),

        // 2nd Floor
        _buildFloorSection('2', '2nd Floor', [
          _buildRoom('2-1', 'Cafeteria', event?.location == 'Cafeteria'),
          _buildRoom('2-2', 'Library', event?.location == 'Library'),
          _buildRoom('2-3', 'Library Cubicle 1', event?.location == 'Library Cubicle 1'),
          _buildRoom('2-4', 'Library Cubicle 2', event?.location == 'Library Cubicle 2'),
          _buildRoom('2-5', 'Library Cubicle 3', event?.location == 'Library Cubicle 3'),
          _buildRoom('2-6', 'Campus Front Desk', event?.location == 'Campus Front Desk'),
        ]),
        const SizedBox(height: 12),

        // Ground Floor
        _buildFloorSection('G', 'Ground Floor', [
          _buildRoom('G-1', 'Main Lobby', event?.location == 'Main Lobby'),
          _buildRoom('G-2', 'Waiting Area', event?.location == 'Waiting Area'),
          _buildRoom('G-3', 'Parking Lot', event?.location == 'Parking Lot'),
        ]),
      ],
    );
  }

  Widget _buildFloorSection(String label, String title, List<Widget> rooms) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: rooms,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoom(String number, String name, bool hasEvent) {
    final isEventRoom = hasEvent && event != null;
    final color = isEventRoom ? eventColor : Colors.grey.shade200;
    final textColor = isEventRoom ? Colors.white : Colors.black87;

    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: isEventRoom ? Border.all(color: color, width: 2) : Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(number,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
              if (isEventRoom) ...[
                const Spacer(),
                Icon(Icons.auto_awesome, size: 12, color: Colors.yellowAccent),
              ],
            ],
          ),
          Text(name,
            style: TextStyle(fontSize: 11, color: textColor),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
