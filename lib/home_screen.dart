import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:campus_planner/user.dart';
import 'package:campus_planner/event.dart';
import 'package:campus_planner/database_helper.dart';
import 'package:campus_planner/login_screen.dart';
import 'package:campus_planner/location_screen.dart';

const Color academicColor = Color(0xFF00BCD4);
const Color campusColor = Color(0xFFE91E63);
const Color calendarOutline = Color(0xFFB3E5FC);
const Color dateNumberColor = Color(0xFFE91E63);

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCalendarView = true;
  late DateTime _currentMonth;
  List<Event> _allMonthEvents = [];
  List<Event> _filteredEvents = [];
  Event? _selectedEvent;
  bool _isRegistered = false;
  final TextEditingController _searchController = TextEditingController();
  List<Event> _notifiedEvents = [];
  final Map<int, String> _dismissedNotifications = {};
  Timer? _notificationTimer;

  static const _monthNames = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];
  static const _weekdays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(2026, 7);
    _loadMonthEvents();
    _initNotificationChecker();
  }

  Future<void> _loadMonthEvents() async {
    final events = await DatabaseHelper.instance.getEventsByMonth(
      _currentMonth.year, _currentMonth.month,
    );
    if (!mounted) return;
    setState(() { _allMonthEvents = events; _applyFilter(); });
  }

  Future<void> _applyFilter() async {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filteredEvents = List.from(_allMonthEvents);
      });
    } else {
      final results = await DatabaseHelper.instance.searchEvents(q);
      if (!mounted) return;
      setState(() {
        _filteredEvents = results;
      });
    }
    if (_selectedEvent != null &&
        !_filteredEvents.any((e) => e.id == _selectedEvent!.id)) {
      setState(() { _selectedEvent = null; });
    }
  }

  void _initNotificationChecker() {
    _checkUpcomingEvents();
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkUpcomingEvents();
    });
  }

  Future<void> _checkUpcomingEvents() async {
    final registeredEvents = await DatabaseHelper.instance.getRegisteredEvents(widget.user.id!);
    if (!mounted) return;
    final now = DateTime.now();
    final upcoming = <Event>[];
    for (final event in registeredEvents) {
      final dt = DateTime.tryParse('${event.date} ${event.time}');
      if (dt == null) continue;
      final diff = dt.difference(now);
      final mins = diff.inMinutes;
      final String? dismissedTier = _dismissedNotifications[event.id];
      if (mins >= 55 && mins <= 65 && dismissedTier != '1hour') {
        upcoming.add(event);
      } else if (mins >= 10 && mins <= 20 && dismissedTier != '15min') {
        upcoming.add(event);
      }
    }
    if (upcoming.isNotEmpty) {
      setState(() { _notifiedEvents = upcoming; });
    }
  }

  void _dismissNotification(Event event) {
    final now = DateTime.now();
    final dt = DateTime.tryParse('${event.date} ${event.time}');
    final mins = dt != null ? dt.difference(now).inMinutes : 0;
    final tier = (mins >= 55 && mins <= 65) ? '1hour' : '15min';
    setState(() {
      _dismissedNotifications[event.id!] = tier;
      _notifiedEvents.removeWhere((e) => e.id == event.id);
    });
  }

  void _previousMonth() {
    setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1); _selectedEvent = null; });
    _loadMonthEvents();
  }

  void _nextMonth() {
    setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1); _selectedEvent = null; });
    _loadMonthEvents();
  }

  Color _eventColor(Event e) => e.type == 'academic' ? academicColor : campusColor;
  Color _contrastColor(String t) => t == 'academic' ? campusColor : academicColor;

  bool _isPastEvent(Event e) {
    final dt = DateTime.tryParse('${e.date} ${e.time}');
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  bool _isReminder(Event e) {
    final t = e.title.toLowerCase();
    return t.startsWith('assignment') || t.startsWith('quiz') || t.contains('examination') || t.startsWith('release of');
  }

  Future<void> _selectEvent(Event event) async {
    final reg = await DatabaseHelper.instance.isUserRegistered(event.id!, widget.user.id!);
    if (!mounted) return;
    setState(() { _selectedEvent = event; _isRegistered = reg; });
  }

  Future<void> _registerForEvent() async {
    if (_selectedEvent == null) return;
    final ok = await DatabaseHelper.instance.registerForEvent(_selectedEvent!.id!, widget.user.id!);
    if (ok) {
      await _loadMonthEvents();
      final updated = _allMonthEvents.firstWhere((e) => e.id == _selectedEvent!.id);
      if (!mounted) return;
      setState(() { _isRegistered = true; _selectedEvent = updated; });
      _showEmailOption(_selectedEvent!);
    }
  }

  Future<void> _showEmailOption(Event event) async {
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Text('You registered for "${event.title}".\n\nWould you like to email yourself the event details?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send via Email')),
        ],
      ),
    );
    if (send == true) {
      final subject = 'Event Registration: ${event.title}';
      final body = 'You have registered for:\n\n'
          '${event.title}\n'
          'Date: ${_formatDate(event.date)}\n'
          'Time: ${_formatTime(event.time)}\n'
          'Location: ${event.location}\n'
          'Description: ${event.description}';
      final uri = Uri(
        scheme: 'mailto',
        path: widget.user.email,
        queryParameters: {'subject': subject, 'body': body},
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _cancelRegistration() async {
    if (_selectedEvent == null) return;
    await DatabaseHelper.instance.cancelRegistration(_selectedEvent!.id!, widget.user.id!);
    await _loadMonthEvents();
    final updated = _allMonthEvents.firstWhere((e) => e.id == _selectedEvent!.id);
    if (!mounted) return;
    setState(() { _isRegistered = false; _selectedEvent = updated; });
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
              Text(widget.user.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.user.email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CIIT Campus Scheduler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Floor Plan',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const LocationScreen(),
              ));
            },
          ),
          IconButton(icon: const Icon(Icons.account_circle), onPressed: _showProfileMenu, tooltip: 'Profile'),
        ],
      ),
      body: Column(
        children: [
          _buildNotificationBanners(),
          _buildHeader(),
          _buildSearchBar(),
          Expanded(flex: 4, child: _buildMainContent()),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          Expanded(flex: 2, child: _buildDetailsPanel()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
          Expanded(
            child: Text(
              '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
            tooltip: _isCalendarView ? 'List view' : 'Calendar view',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: TextField(
        controller: _searchController, 
        decoration: InputDecoration(
          hintText: 'Search events...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (_) async { await _applyFilter(); if (mounted) setState(() {}); },
      ),
    );
  }

  Widget _buildMainContent() {
    if (_searchController.text.trim().isNotEmpty) {
      if (_filteredEvents.isNotEmpty) return _buildSearchResults();
      return const Center(child: Text('No events match your search'));
    }
    return _isCalendarView ? _buildCalendarView() : _buildEventList();
  }

  Widget _buildNotificationBanners() {
    if (_notifiedEvents.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _notifiedEvents.map((e) {
        final dt = DateTime.tryParse('${e.date} ${e.time}');
        final mins = dt != null ? dt.difference(DateTime.now()).inMinutes : 0;
        final label = (mins >= 55 && mins <= 65) ? 'in ~1 hour' : 'in ~15 min';
        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: const Icon(Icons.notifications_active, color: Colors.orange),
          backgroundColor: Colors.orange.shade50,
          content: Text(
            'Upcoming ($label): ${e.title}\n${e.location.isNotEmpty ? "${e.location} @ " : ""}${_formatTime(e.time)}',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => _dismissNotification(e),
              child: const Text('DISMISS'),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, i) {
        final event = _filteredEvents[i];
        final color = _eventColor(event);
        final isSelected = _selectedEvent?.id == event.id;
        final dt = DateTime.tryParse(event.date);
        final weekday = dt != null ? _weekdays[dt.weekday % 7] : '';
        final day = event.date.length >= 10 ? event.date.substring(8, 10) : event.date;
        final month = event.date.length >= 7 ? event.date.substring(5, 7) : '';
        final year = event.date.length >= 4 ? event.date.substring(0, 4) : '';
        return GestureDetector(
          onTap: () => _selectEvent(event),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: color, width: 1) : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Text(day, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dateNumberColor)),
                      Text('$month/$year', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(weekday, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(event.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.type == 'campus')
                          const Icon(Icons.auto_awesome, size: 14, color: Colors.yellowAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── CALENDAR VIEW ──────────────────────────────────────────────

  Widget _buildCalendarView() {
    if (_filteredEvents.isEmpty && _allMonthEvents.isNotEmpty) {
      return const Center(child: Text('No events match your search'));
    }
    final year = _currentMonth.year, month = _currentMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startOffset = DateTime(year, month, 1).weekday % 7;

    final eventsByDay = <int, List<Event>>{};
    final maxCols = _allMonthEvents.isEmpty ? 1 : 2;
    for (final e in _allMonthEvents) {
      final parts = e.date.split('-');
      if (parts.length == 3) {
        final d = int.tryParse(parts[2]) ?? 0;
        if (d >= 1 && d <= daysInMonth) {
          eventsByDay.putIfAbsent(d, () => []).add(e);
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Day-of-week headers
          Row(
            children: List.generate(7, (i) => Expanded(
              child: Center(
                child: Text(_weekdays[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              ),
            )),
          ),
          const SizedBox(height: 2),
          // Calendar grid
          ..._buildCalendarRows(daysInMonth, startOffset, eventsByDay, maxCols),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarRows(int daysInMonth, int startOffset, Map<int, List<Event>> eventsByDay, int maxCols) {
    final rows = <Widget>[];
    int day = 1;
    for (int row = 0; row < 6 && day <= daysInMonth; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if ((row == 0 && col < startOffset) || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 76, width: 0)));
        } else {
          cells.add(Expanded(child: _buildDayCell(day, eventsByDay[day] ?? [], maxCols)));
          day++;
        }
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: Row(children: cells),
      ));
    }
    return rows;
  }

  Widget _buildDayCell(int day, List<Event> dayEvents, int maxCols) {
    final displayEvents = dayEvents.take(maxCols).toList();
    final hasMore = dayEvents.length > maxCols;
    return Container(
      height: 76,
      decoration: BoxDecoration(
        border: Border.all(color: calendarOutline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3, top: 2),
            child: Text('$day', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dateNumberColor)),
          ),
          if (displayEvents.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  children: [
                    ...displayEvents.map((e) => _buildEventBox(e)),
                    if (hasMore)
                      Text('+${dayEvents.length - maxCols}', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventBox(Event event) {
    final color = _eventColor(event);
    return GestureDetector(
      onTap: () => _selectEvent(event),
      child: Container(
        height: 22,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Row(
            children: [
              Flexible(
                flex: 1,
                fit: FlexFit.loose,
                child: Text(
                  event.title,
                  style: const TextStyle(color: Colors.white, fontSize: 9, height: 2.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (event.type == 'campus')
                const Icon(Icons.auto_awesome, size: 10, color: Colors.yellowAccent),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LIST VIEW ──────────────────────────────────────────────────

  Widget _buildEventList() {
    if (_filteredEvents.isEmpty) {
      return Center(child: Text(_allMonthEvents.isEmpty ? 'No events this month' : 'No events match your search'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, i) => _buildListEntry(_filteredEvents[i]),
    );
  }

  Widget _buildListEntry(Event event) {
    final color = _eventColor(event);
    final isSelected = _selectedEvent?.id == event.id;
    final dt = DateTime.tryParse(event.date);
    final weekday = dt != null ? _weekdays[dt.weekday % 7] : '';
    final day = event.date.length >= 10 ? event.date.substring(8, 10) : event.date;
    final month = event.date.length >= 7 ? event.date.substring(5, 7) : '';

    return GestureDetector(
      onTap: () => _selectEvent(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 1) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Text(day, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dateNumberColor)),
                  Text(month, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(weekday, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(event.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (event.type == 'campus')
                      const Icon(Icons.auto_awesome, size: 14, color: Colors.yellowAccent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DETAILS PANEL ──────────────────────────────────────────────

  Widget _buildDetailsPanel() {
    if (_selectedEvent == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text('Select an event to view details', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    final e = _selectedEvent!;
    final color = _eventColor(e);
    final contrast = _contrastColor(e.type);
    final isFull = e.registeredCount >= e.capacity;
    final unlimited = e.capacity >= 9999;
    final isPast = _isPastEvent(e);
    final isReminder = _isReminder(e);
    final canRegister = !isPast && !isReminder && !isFull;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge + title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(e.type == 'academic' ? 'Academic' : 'Campus',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isPast) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Completed', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
                if (isReminder && !isPast) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Reminder', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Info rows
            _infoRow(Icons.calendar_today, _formatDate(e.date)),
            const SizedBox(height: 4),
            _infoRow(Icons.access_time, _formatTime(e.time)),
            const SizedBox(height: 4),
            if (e.location.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LocationScreen(event: e, eventColor: color),
                  ));
                },
                child: _infoRow(Icons.location_on, e.location, action: 'Map'),
              ),
            if (e.location.isEmpty)
              _infoRow(Icons.location_off, 'No room assigned (Online)'),
            const SizedBox(height: 4),

            // Capacity bar
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(unlimited ? 'Unlimited capacity' : '${e.registeredCount}/${e.capacity} registered',
                  style: const TextStyle(fontSize: 13),
                ),
                const Spacer(),
                if (isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                    child: const Text('FULL', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                if (_isRegistered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                    child: const Text('REGISTERED', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Description
            if (e.description.isNotEmpty)
              Text(e.description, style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87)),

            const SizedBox(height: 8),

            // Register button
            if (!isReminder && !isPast)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRegistered
                      ? _cancelRegistration
                      : (canRegister ? _registerForEvent : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRegistered ? Colors.grey.shade300 : contrast,
                    foregroundColor: _isRegistered ? Colors.black87 : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    _isRegistered ? 'Cancel Registration'
                        : isFull ? 'Event Full'
                        : 'Register',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (isPast)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black54,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('This event has ended', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {String? action}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        if (action != null)
          Text(action, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    final m = int.tryParse(parts[1]) ?? 0;
    final d = int.tryParse(parts[2]) ?? 0;
    return '${_monthNames[m - 1]} $d, ${parts[0]}';
  }

  String _formatTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$min $ampm';
  }
}
