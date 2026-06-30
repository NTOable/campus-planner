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
        title: const Text('Campus Map'),
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

            // Concept map placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.green.shade300),
                    const SizedBox(height: 8),
                    Text('CIIT Campus Map',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                    const SizedBox(height: 4),
                    Text('(Replace with actual CIIT facility map)',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Building Layout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

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
        // Roof Floor
        _buildFloorSection('R', 'Roof Deck', [
          _buildRoom('R-1', 'Roof Garden', false),
          _buildRoom('R-2', 'Open Area', false),
        ]),
        const SizedBox(height: 12),

        // Upper Floors (4-7)
        _buildFloorSection('7', '7th Floor', [
          _buildRoom('7-1', 'Computer Lab 3', event?.location == 'Computer Lab 3'),
          _buildRoom('7-2', 'Innovation Hub', event?.location == 'CIIT Innovation Hub'),
          _buildRoom('7-3', 'Studio B', false),
        ]),
        const SizedBox(height: 12),

        _buildFloorSection('6', '6th Floor', [
          _buildRoom('6-1', 'Room 601', false),
          _buildRoom('6-2', 'Room 602', false),
          _buildRoom('6-3', 'Computer Lab 2', false),
        ]),
        const SizedBox(height: 12),

        _buildFloorSection('5', '5th Floor', [
          _buildRoom('5-1', 'Room 501', false),
          _buildRoom('5-2', 'Room 405', event?.location == 'Room 405'),
          _buildRoom('5-3', 'Room 503', false),
        ]),
        const SizedBox(height: 12),

        _buildFloorSection('4', '4th Floor', [
          _buildRoom('4-1', 'Computer Lab 1', false),
          _buildRoom('4-2', 'Library', false),
          _buildRoom('4-3', 'Student Lounge', event?.location == 'Student Lounge'),
        ]),
        const SizedBox(height: 12),

        _buildFloorSection('3', '3rd Floor', [
          _buildRoom('3-1', 'Room 301', false),
          _buildRoom('3-2', 'Room 302', false),
          _buildRoom('3-3', 'Room 303', false),
        ]),
        const SizedBox(height: 12),

        _buildFloorSection('2', '2nd Floor', [
          _buildRoom('2-1', 'Auditorium A', event?.location == 'Auditorium A'),
          _buildRoom('2-2', 'Mini Theater', event?.location == 'CIIT Mini Theater'),
          _buildRoom('2-3', 'Chapel', event?.location == 'CIIT Chapel'),
        ]),
        const SizedBox(height: 12),

        // Ground Floor
        _buildFloorSection('G', 'Ground Floor', [
          _buildRoom('G-1', 'Main Lobby', event?.location == 'CIIT Lobby'),
          _buildRoom('G-2', 'Registrar', event?.location == "Registrar's Office / Online Portal"),
          _buildRoom('G-3', 'Gymnasium', event?.location == 'CIIT Gymnasium'),
          _buildRoom('G-4', 'Campus Grounds', event?.location == 'CIIT Campus Grounds'),
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
