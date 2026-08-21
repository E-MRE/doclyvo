part of '../compress_screen.dart';

/// Simulated progress for the [ToolProgressIndicator], mirroring `apps/web`'s
/// `useFakeProgress` hook (see `apps/web/lib/hooks/use-fake-progress.ts`):
/// ticks up to 92% while the compress call is in flight, then the caller
/// snaps it to 100 once the result lands. `pdf_manipulator`'s `compress`
/// exposes no progress callback (per the P0-11 Decisions log entry — every
/// operation is a `PdfTask<T>`, a plain future plus `cancel()`), so this is
/// UI-only and never reflects real engine progress.
final class _FakeProgressTicker {
  _FakeProgressTicker({required this.onTick});

  final ValueChanged<double> onTick;

  static const double _maxWhileActive = 92;
  static const Duration _tickInterval = Duration(milliseconds: 220);

  Timer? _timer;
  double _value = 0;

  void start() {
    _value = 0;
    onTick(_value);
    _timer = Timer.periodic(_tickInterval, (_) {
      final increment = 6 + math.Random().nextDouble() * 8;
      _value = math.min(_maxWhileActive, _value + increment);
      onTick(_value);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
