const trialDuration = Duration(days: 7);

int trialDaysRemaining(DateTime firstSeenAt, [DateTime? now]) {
  final current = (now ?? DateTime.now()).toUtc();
  final start = firstSeenAt.toUtc();
  if (current.isBefore(start)) return 0;
  final remaining = trialDuration - current.difference(start);
  if (remaining <= Duration.zero) return 0;
  return (remaining.inSeconds / Duration.secondsPerDay).ceil();
}

bool trialIsActive(DateTime firstSeenAt, [DateTime? now]) =>
    trialDaysRemaining(firstSeenAt, now) > 0;
