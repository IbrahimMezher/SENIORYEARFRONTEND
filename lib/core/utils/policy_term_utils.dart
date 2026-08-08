class PolicyTermUtils {
  const PolicyTermUtils._();

  static bool isAccepted(dynamic tx) {
    final map = _asMap(tx);
    return (map?['brokerStatus']?.toString().toUpperCase() ?? '') == 'ACCEPTED';
  }

  static bool isExpired(dynamic tx, {DateTime? now}) {
    final days = daysUntilExpiry(tx, now: now);
    return days != null && days < 0;
  }

  static bool isInForce(dynamic tx, {DateTime? now}) {
    return isAccepted(tx) && !hasDeliveryFailure(tx) && !isExpired(tx, now: now);
  }

  static bool isCoverageLive(dynamic tx, {DateTime? now}) {
    if (!isAccepted(tx) || hasDeliveryFailure(tx)) return false;
    final map = _asMap(tx);
    if ((map?['paymentStatus']?.toString().toUpperCase() ?? '') != 'PAID') {
      return false;
    }
    final activeDate = policyActiveDate(tx);
    if (activeDate == null) return false;
    final current = now ?? DateTime.now();
    return !current.isBefore(activeDate) && !isExpired(tx, now: current);
  }

  static bool hasDeliveryFailure(dynamic tx) {
    final map = _asMap(tx);
    final delivery = map?['deliveryStatus']?.toString().toUpperCase() ?? '';
    return delivery == 'NOT_RECEIVED' || delivery == 'REJECTED_BY_BROKER';
  }

  static bool renewsWithin(dynamic tx, {int days = 30, DateTime? now}) {
    if (!isCoverageLive(tx, now: now)) return false;
    final daysLeft = daysUntilExpiry(tx, now: now);
    return daysLeft != null && daysLeft >= 0 && daysLeft <= days;
  }

  static DateTime? policyActiveDate(dynamic tx) {
    final map = _asMap(tx);
    final raw = _stringValue(map, 'policyActiveDate');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static DateTime? startDate(dynamic tx) {
    final map = _asMap(tx);
    final raw = _stringValue(map, 'policyActiveDate') ??
        _stringValue(map, 'purchaseDate');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static DateTime? expiryDate(dynamic tx) {
    final start = startDate(tx);
    if (start == null) return null;
    final months = durationMonthsForPolicy(_asMap(tx)?['policy']);
    return DateTime(
      start.year,
      start.month + months,
      start.day,
      start.hour,
      start.minute,
      start.second,
      start.millisecond,
      start.microsecond,
    );
  }

  static int? daysUntilExpiry(dynamic tx, {DateTime? now}) {
    final expiry = expiryDate(tx);
    if (expiry == null) return null;
    return expiry.difference(now ?? DateTime.now()).inDays;
  }

  static double annualizedPremium(dynamic tx) {
    final map = _asMap(tx);
    final tier = _asMap(map?['coverageTier']);
    final price = _moneyValue(tier?['premiumPrice']) ??
        _moneyValue(map?['amountPaid']) ??
        0.0;
    final months = durationMonthsForPolicy(map?['policy']);
    return months > 0 ? price * 12 / months : price;
  }

  static int durationMonthsForPolicy(dynamic policy) {
    final policyMap = _asMap(policy);
    final durationMap = _asMap(policyMap?['policyDuration']);
    return durationMonths(
      duration: _stringValue(durationMap, 'duration'),
      label: _stringValue(durationMap, 'label'),
    );
  }

  static int durationMonths({String? duration, String? label}) {
    for (final raw in [duration, label]) {
      final parsed = _parseDuration(raw);
      if (parsed != null) return parsed;
    }
    return 12;
  }

  static int? _parseDuration(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;

    final key = text.toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
    switch (key) {
      case 'MONTHLY':
      case 'MONTH':
      case 'ONE_MONTH':
        return 1;
      case 'QUARTERLY':
      case 'QUARTER':
      case 'THREE_MONTHS':
        return 3;
      case 'SEMI_ANNUAL':
      case 'SEMIANNUAL':
      case 'SIX_MONTHS':
        return 6;
      case 'ANNUAL':
      case 'YEARLY':
      case 'YEAR':
      case 'ONE_YEAR':
        return 12;
      case 'TWO_YEARS':
      case 'TWO_YEAR':
        return 24;
      case 'THREE_YEARS':
      case 'THREE_YEAR':
        return 36;
    }

    final match =
        RegExp(r'(\d+)\s*(month|months|year|years)', caseSensitive: false)
            .firstMatch(text);
    if (match != null) {
      final count = int.tryParse(match.group(1)!) ?? 1;
      final unit = match.group(2)!.toLowerCase();
      return unit.startsWith('year') ? count * 12 : count;
    }

    final lower = text.toLowerCase();
    if (lower.contains('quarter')) return 3;
    if (lower.contains('semi')) return 6;
    if (lower.contains('month')) return 1;
    if (lower.contains('year') || lower.contains('annual')) return 12;
    return null;
  }

  static Map? _asMap(dynamic value) => value is Map ? value : null;

  static String? _stringValue(Map? map, String key) {
    final value = map?[key];
    return value == null ? null : value.toString();
  }

  static double? _moneyValue(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
  }
}
