import 'package:flutter/material.dart';
import 'package:campus_planner/user.dart';
import 'package:campus_planner/event.dart';
import 'package:campus_planner/database_helper.dart';
import 'package:campus_planner/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedType = 'academic';
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await DatabaseHelper.instance.getEventsByType(_selectedType);
    if (!mounted) return;
    setState(() {
      _events = events;
      _filteredEvents = events;
    });
  }

  void _switchType(String type) {
    setState(() => _selectedType = type);
    _loadEvents();
    _searchController.clear();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = _events;
      } else {
        _filteredEvents = _events.where((e) =>
          e.title.toLowerCase().contains(query.toLowerCase()) ||
          e.description.toLowerCase().contains(query.toLowerCase()) ||
          e.location.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _showEventDetails(Event event) async {
    final isRegistered = await DatabaseHelper.instance.isUserRegistered(
      event.id!, widget.user.id!,
    );
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: _EventDetailSheet(
          event: event,
          isRegistered: isRegistered,
          userId: widget.user.id!,
          onChanged: _loadEvents,
        ),
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.username,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.user.email,
                style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showProfileMenu,
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search events...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _onSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(child: _buildToggle('academic', 'Academic')),
                const SizedBox(width: 8),
                Expanded(child: _buildToggle('campus', 'Campus Events')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _filteredEvents.isEmpty
              ? const Center(child: Text('No events found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, index) {
                    return _EventCard(
                      event: _filteredEvents[index],
                      onTap: () => _showEventDetails(_filteredEvents[index]),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String type, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => _switchType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isFull = event.registeredCount >= event.capacity;
    final bool unlimited = event.capacity >= 9999;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    event.date.length >= 10 ? event.date.substring(8, 10) : event.date,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('${event.date}  ${event.time}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    Text(event.location,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isFull)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('FULL', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  if (!unlimited)
                    Text('${event.registeredCount}/${event.capacity}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailSheet extends StatefulWidget {
  final Event event;
  final bool isRegistered;
  final int userId;
  final VoidCallback onChanged;

  const _EventDetailSheet({
    required this.event,
    required this.isRegistered,
    required this.userId,
    required this.onChanged,
  });

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  late bool _isRegistered;
  late Event _event;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.isRegistered;
    _event = widget.event;
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    final success = await DatabaseHelper.instance.registerForEvent(
      _event.id!, widget.userId,
    );
    if (!mounted) return;
    if (success) {
      final events = await DatabaseHelper.instance.getEventsByType(_event.type);
      final updated = events.firstWhere((e) => e.id == _event.id);
      setState(() {
        _isRegistered = true;
        _event = updated;
      });
      widget.onChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already registered for this event')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _cancelRegistration() async {
    setState(() => _isLoading = true);
    final success = await DatabaseHelper.instance.cancelRegistration(
      _event.id!, widget.userId,
    );
    if (!mounted) return;
    if (success) {
      final events = await DatabaseHelper.instance.getEventsByType(_event.type);
      final updated = events.firstWhere((e) => e.id == _event.id);
      setState(() {
        _isRegistered = false;
        _event = updated;
      });
      widget.onChanged();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isFull = _event.registeredCount >= _event.capacity;
    final bool unlimited = _event.capacity >= 9999;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_event.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          _infoRow(Icons.calendar_today, _event.date),
          const SizedBox(height: 8),
          _infoRow(Icons.access_time, _event.time),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on, _event.location),
          const SizedBox(height: 8),
          _infoRow(Icons.people,
            unlimited ? 'Unlimited capacity' : 'Capacity: ${_event.registeredCount}/${_event.capacity}'),
          const SizedBox(height: 12),

          if (isFull)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Event Full', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          if (_isRegistered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('You are registered', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),

          const SizedBox(height: 12),
          Text(_event.description, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_isRegistered ? _cancelRegistration : (isFull ? null : _register)),
              style: _isRegistered
                ? ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100)
                : null,
              child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isRegistered ? 'Cancel Registration' : (isFull ? 'Event Full' : 'Register')),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
