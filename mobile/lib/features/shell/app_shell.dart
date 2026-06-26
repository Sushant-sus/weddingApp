import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/glass.dart';
import '../events/event_providers.dart';
import '../dashboard/dashboard_screen.dart';
import '../guests/guests_screen.dart';
import '../itinerary/itinerary_screen.dart';
import '../gifts/gifts_screen.dart';
import '../more/more_screen.dart';
import 'glass_nav_bar.dart';

/// Per-event tab shell with the floating glass nav bar.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _items = [
    NavItem(Icons.home_outlined, 'Home'),
    NavItem(Icons.diversity_3_outlined, 'Guests'),
    NavItem(Icons.event_note_outlined, 'Itinerary'),
    NavItem(Icons.card_giftcard, 'Gifts'),
    NavItem(Icons.more_horiz, 'More'),
  ];

  static const _pages = [
    DashboardScreen(),
    GuestsScreen(),
    ItineraryScreen(),
    GiftsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // If no event is selected (e.g. deep link / refresh), bounce to the picker.
    if (ref.watch(selectedEventIdProvider) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/events');
      });
      return const GlassScaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GlassScaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: GlassNavBar(
        items: _items,
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
