import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sleeptrack/screens/calendar_screen.dart';
import 'package:sleeptrack/screens/home_screen.dart';
import 'package:sleeptrack/screens/onboarding_screen.dart';
import 'package:sleeptrack/state/app_state.dart';
import 'package:sleeptrack/theme/app_theme.dart';
import 'package:sleeptrack/widgets/add_sleep_sheet.dart';
import 'package:sleeptrack/widgets/nav_island.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.init();
  runApp(SleepTrackApp(state: state));
}

class SleepTrackApp extends StatelessWidget {
  final AppState state;
  const SleepTrackApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: Consumer<AppState>(
        builder: (context, st, _) => MaterialApp(
          title: 'The Sleep Journal',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(AppPalette.light),
          darkTheme: buildTheme(AppPalette.dark),
          themeMode: st.settings.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 360),
          themeAnimationCurve: Curves.easeInOut,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 620),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(st.onboarded),
              child: st.onboarded ? const RootShell() : const OnboardingScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final st = context.watch<AppState>();
    final overlay = p.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
          statusBarColor: Colors.transparent, systemNavigationBarColor: p.bg),
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.025), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(st.pageIndex),
                child: st.pageIndex == 0 ? const HomeScreen() : const CalendarScreen(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: NavIsland(
                    activeIndex: st.pageIndex,
                    onHome: () => st.setPage(0),
                    onCalendar: () => st.setPage(1),
                    onAdd: () => showAddSleepSheet(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
