import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleeptrack/logic/metrics.dart';
import 'package:sleeptrack/logic/time_utils.dart';
import 'package:sleeptrack/state/app_state.dart';
import 'package:sleeptrack/theme/app_theme.dart';
import 'package:sleeptrack/widgets/anim.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  int? _birthYear; // valid year (1900..now), null otherwise
  int? _enteredYear; // raw parsed year, may be out of range — drives the quips
  TimeOfDay _goalSleep = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _goalWake = const TimeOfDay(hour: 6, minute: 0);

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _onYearChanged(String v) {
    final now = DateTime.now().year;
    final y = int.tryParse(v.trim());
    setState(() {
      _enteredYear = y;
      _birthYear = (y != null && y >= 1900 && y <= now) ? y : null;
    });
  }

  Future<void> _pickGoal({required bool sleep}) async {
    final picked =
        await showTimePicker(context: context, initialTime: sleep ? _goalSleep : _goalWake);
    if (picked == null) return;
    setState(() {
      if (sleep) {
        _goalSleep = picked;
      } else {
        _goalWake = picked;
      }
    });
  }

  void _continue() {
    if (_birthYear == null) return;
    FocusScope.of(context).unfocus(); // drop the keyboard before the fade
    context.read<AppState>().completeOnboarding(
          _nameController.text,
          _birthYear,
          minutesOf(_goalSleep),
          minutesOf(_goalWake),
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      FadeSlideIn(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(color: p.greenSoft, shape: BoxShape.circle),
                          child: Icon(Icons.bedtime_rounded,
                              color: p.brightness == Brightness.light
                                  ? const Color(0xFF2B2C24)
                                  : const Color(0xFF14160F),
                              size: 30),
                        ),
                      ),
                      const SizedBox(height: 26),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: Text('The Sleep Journal',
                            style: AppText.heading(p.textPrimary).copyWith(fontSize: 38, height: 1.05)),
                      ),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: Text(
                          'A quiet, personal record of how you sleep — logged by the day you wake up.',
                          style: AppText.body(p.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 36),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 240),
                        child: Text('What should we call you?', style: AppText.label(p.textPrimary)),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: _field(
                          p,
                          controller: _nameController,
                          hint: 'Your name',
                          autofocus: true,
                          capitalize: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 360),
                        child: Text('Your year of birth', style: AppText.label(p.textPrimary)),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 410),
                        child: _field(
                          p,
                          controller: _yearController,
                          hint: 'e.g. 2000',
                          number: true,
                          onChanged: _onYearChanged,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 450),
                        child: _recommendation(p),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 500),
                        child: Text('Your sleep goal', style: AppText.label(p.textPrimary)),
                      ),
                      const SizedBox(height: 6),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 530),
                        child: Text('When you aim to fall asleep and wake — you can change this anytime.',
                            style: AppText.body(p.textFaint)),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 570),
                        child: Row(children: [
                          Expanded(child: _goalTile(p, 'Bedtime', _goalSleep, () => _pickGoal(sleep: true))),
                          const SizedBox(width: 14),
                          Expanded(child: _goalTile(p, 'Wake up', _goalWake, () => _pickGoal(sleep: false))),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 600),
                        child: _goalDuration(p),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 650),
                child: GestureDetector(
                  onTap: _continue,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _birthYear == null ? 0.4 : 1,
                    child: Container(
                      height: 58,
                      alignment: Alignment.center,
                      decoration:
                          BoxDecoration(color: p.island, borderRadius: BorderRadius.circular(29)),
                      child: Text('Get Started', style: AppText.button(p.islandIcon)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recommendation(AppPalette p) {
    final now = DateTime.now().year;
    // Playful nudges for impossible years (only once a full 4-digit year is in).
    if (_enteredYear != null && _enteredYear! > now) {
      return _recRow(p, Icons.rocket_launch_rounded, p.amber, 'Are you from the future?');
    }
    if (_enteredYear != null && _enteredYear! >= 1000 && _enteredYear! < 1900) {
      return _recRow(p, Icons.sentiment_very_satisfied_rounded, p.amber, 'How are you still alive?');
    }
    if (_birthYear == null) {
      return Text('We use this to tailor your healthy sleep range — and your Sleep Health score.',
          style: AppText.body(p.textFaint));
    }
    final age = now - _birthYear!;
    final r = recommendedSleepRange(age);
    return _recRow(
        p, Icons.check_circle_rounded, p.green, 'At $age, aim for ${r.lo}–${r.hi} hours a night.');
  }

  Widget _recRow(AppPalette p, IconData icon, Color color, String text) => Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppText.body(p.textSecondary))),
      ]);

  Widget _goalDuration(AppPalette p) {
    final mins = goalWindowMinutes(minutesOf(_goalSleep), minutesOf(_goalWake));
    final hours = mins / 60.0;
    var text = "That's ${durationLabel(mins)} in bed";
    var color = p.textSecondary;
    var icon = Icons.bedtime_rounded;
    if (_birthYear != null) {
      final note = goalVsRecommendation(hours, recommendedSleepRange(DateTime.now().year - _birthYear!));
      final within = note == 'within the recommended range';
      text = "That's ${durationLabel(mins)} a night · $note";
      icon = within ? Icons.check_circle_rounded : Icons.error_outline_rounded;
      color = within ? p.green : p.amber;
    }
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: AppText.body(p.textSecondary))),
    ]);
  }

  Widget _goalTile(AppPalette p, String label, TimeOfDay time, VoidCallback onTap) {
    final parts = clockParts(time);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppText.sectionLabel(p.textSecondary)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.divider),
          ),
          child: Row(children: [
            Text('${parts.time} ${parts.period}', style: AppText.label(p.textPrimary)),
            const Spacer(),
            Icon(Icons.access_time_rounded, size: 17, color: p.textSecondary),
          ]),
        ),
      ),
    ]);
  }

  Widget _field(
    AppPalette p, {
    required TextEditingController controller,
    required String hint,
    bool autofocus = false,
    bool capitalize = false,
    bool number = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLength: number ? 4 : null,
      textCapitalization: capitalize ? TextCapitalization.words : TextCapitalization.none,
      style: AppText.greeting(p.textPrimary).copyWith(fontSize: 22),
      cursorColor: p.green,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: AppText.greeting(p.textFaint).copyWith(fontSize: 22),
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: p.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: p.green, width: 1.6)),
      ),
    );
  }
}
