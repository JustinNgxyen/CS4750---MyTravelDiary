import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/models.dart';
import '../services/firestore_service.dart';
import '../widgets/trip_card.dart';
import '../widgets/memory_card.dart';
import 'trips_details_screen.dart';
import 'memories_details_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _firestoreService = FirestoreService();

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String get _monthLabel =>
      '${_monthNames[_focusedDay.month - 1]} ${_focusedDay.year}';

  bool _sameMonth(DateTime d) =>
      d.year == _focusedDay.year && d.month == _focusedDay.month;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasTripOnDay(List<Trip> trips, DateTime day) =>
      trips.any((t) => _sameDay(t.startDate, day));

  bool _hasMemoryOnDay(List<Memory> memories, DateTime day) =>
      memories.any((m) => _sameDay(m.memoryDate, day));

  void _showMonthYearPicker() {
    int tempMonth = _focusedDay.month;
    int tempYear = _focusedDay.year;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF162033),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Select Month & Year',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => setSheetState(() => tempYear--),
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            tempYear.toString(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () => setSheetState(() => tempYear++),
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.4,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(12, (i) {
                          final isSelected = i + 1 == tempMonth;
                          return GestureDetector(
                            onTap: () => setSheetState(() => tempMonth = i + 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF22C7C7)
                                    : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  _monthNames[i].substring(0, 3),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime(tempYear, tempMonth, 1);
                              _selectedDay = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Go'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: StreamBuilder<List<Trip>>(
        stream: _firestoreService.tripsStream(),
        builder: (context, tripsSnap) {
          final allTrips = tripsSnap.data ?? [];

          return StreamBuilder<List<Memory>>(
            stream: _firestoreService.allMemoriesStream(),
            builder: (context, memoriesSnap) {
              final allMemories = memoriesSnap.data ?? [];

              final tripsThisMonth = allTrips
                  .where((t) => _sameMonth(t.startDate))
                  .toList();
              final memoriesThisMonth = allMemories
                  .where((m) => _sameMonth(m.memoryDate))
                  .toList()
                ..sort((a, b) => b.memoryDate.compareTo(a.memoryDate));

              final tripsOnDay = _selectedDay == null
                  ? <Trip>[]
                  : allTrips
                  .where(
                      (t) => _sameDay(t.startDate, _selectedDay!))
                  .toList();
              final memoriesOnDay = _selectedDay == null
                  ? <Memory>[]
                  : allMemories
                  .where(
                      (m) => _sameDay(m.memoryDate, _selectedDay!))
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Trip Calendar',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Browse your trips and memories by month.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 15),
                  ),
                  const SizedBox(height: 18),

                  // ── Month summary card ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C7C7), Color(0xFF0F7C8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Month',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _monthLabel,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${tripsThisMonth.length} trip${tripsThisMonth.length == 1 ? '' : 's'} · '
                              '${memoriesThisMonth.length} memor${memoriesThisMonth.length == 1 ? 'y' : 'ies'}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── TableCalendar ──────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF162033),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: TableCalendar(
                        firstDay: DateTime(2000),
                        lastDay: DateTime(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        selectedDayPredicate: (day) =>
                        _selectedDay != null &&
                            _sameDay(day, _selectedDay!),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                            _selectedDay = null;
                          });
                        },
                        onHeaderTapped: (_) => _showMonthYearPicker(),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          defaultTextStyle:
                          const TextStyle(color: Colors.white),
                          weekendTextStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6)),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFF22C7C7),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFF22C7C7)
                                .withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle:
                          const TextStyle(color: Colors.white),
                          markerDecoration: const BoxDecoration(
                            color: Color(0xFF22C7C7),
                            shape: BoxShape.circle,
                          ),
                          markersMaxCount: 2,
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                          leftChevronIcon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white),
                          rightChevronIcon: const Icon(
                              Icons.chevron_right,
                              color: Colors.white),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13),
                          weekendStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13),
                        ),
                        eventLoader: (day) {
                          final events = <String>[];
                          if (_hasTripOnDay(allTrips, day))
                            events.add('trip');
                          if (_hasMemoryOnDay(allMemories, day))
                            events.add('memory');
                          return events;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Selected day results ───────────────────────
                  if (_selectedDay != null &&
                      (tripsOnDay.isNotEmpty ||
                          memoriesOnDay.isNotEmpty)) ...[
                    Text(
                      '${_selectedDay!.day} ${_monthNames[_selectedDay!.month - 1]} ${_selectedDay!.year}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Container(
                        height: 3,
                        width: 40,
                        color: const Color(0xFF22C7C7)),
                    const SizedBox(height: 12),
                    ...tripsOnDay.map((trip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TripCard(
                        trip: trip,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TripDetailsScreen(trip: trip),
                          ),
                        ),
                      ),
                    )),
                    ...memoriesOnDay.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MemoryCard(
                        memory: m,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MemoryDetailScreen(memory: m),
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // ── Empty state ────────────────────────────────
                  if (tripsThisMonth.isEmpty &&
                      memoriesThisMonth.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF162033),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.luggage_outlined,
                              size: 36, color: Color(0xFF22C7C7)),
                          const SizedBox(height: 10),
                          const Text(
                            'Nothing for this month',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Navigate to another month or add a new trip.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.72)),
                          ),
                        ],
                      ),
                    ),

                  // ── Trips this month ───────────────────────────
                  if (tripsThisMonth.isNotEmpty &&
                      _selectedDay == null) ...[
                    const Text('Trips This Month',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Container(
                        height: 3,
                        width: 40,
                        color: const Color(0xFF22C7C7)),
                    const SizedBox(height: 12),
                    ...tripsThisMonth.map((trip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TripCard(
                        trip: trip,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TripDetailsScreen(trip: trip),
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // ── Memories this month ────────────────────────
                  if (memoriesThisMonth.isNotEmpty &&
                      _selectedDay == null) ...[
                    const Text('Memories This Month',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Container(
                        height: 3,
                        width: 40,
                        color: const Color(0xFF22C7C7)),
                    const SizedBox(height: 12),
                    ...memoriesThisMonth.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MemoryCard(
                        memory: m,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MemoryDetailScreen(memory: m),
                          ),
                        ),
                      ),
                    )),
                  ],

                  const SizedBox(height: 80),
                ],
              );
            },
          );
        },
      ),
    );
  }
}