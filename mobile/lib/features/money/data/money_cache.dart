import 'dart:convert';

import 'package:luqa/features/money/data/money_json.dart';
import 'package:luqa/features/money/domain/money_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-private, user-scoped read cache for the money tab.
///
/// The overview and the most recent bills are kept on disk so the screen
/// paints from the phone: "who owes me what" is a question people ask standing
/// in a queue, and it must not depend on a round trip.
abstract interface class MoneyCache {
  Future<MoneyOverview?> readOverview();

  Future<void> writeOverview(MoneyOverview overview);

  Future<List<Expense>?> readExpenses();

  Future<void> writeExpenses(List<Expense> expenses);
}

class SharedPreferencesMoneyCache implements MoneyCache {
  SharedPreferencesMoneyCache({
    required String namespace,
    SharedPreferencesAsync? preferences,
  }) : _namespace = base64Url.encode(utf8.encode(namespace)),
       _injected = preferences;

  static const _version = 'v1';

  /// Only the head of the feed is worth keeping — enough to open the screen
  /// and recognise the last few bills. History is a request away.
  static const _expenseLimit = 60;

  final String _namespace;
  final SharedPreferencesAsync? _injected;

  // Deferred, so building the cache does not require the platform channel.
  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();

  String get _overviewKey => 'luqa.money.$_version.$_namespace.overview';
  String get _expensesKey => 'luqa.money.$_version.$_namespace.expenses';

  @override
  Future<MoneyOverview?> readOverview() async {
    final encoded = await _preferences.getString(_overviewKey);
    if (encoded == null) return null;
    try {
      return overviewFromJson(jsonDecode(encoded) as Map<String, Object?>);
    } on Object {
      await _preferences.remove(_overviewKey);
      return null;
    }
  }

  @override
  Future<void> writeOverview(MoneyOverview overview) => _preferences.setString(
    _overviewKey,
    jsonEncode(overviewToJson(overview)),
  );

  @override
  Future<List<Expense>?> readExpenses() async {
    final encoded = await _preferences.getString(_expensesKey);
    if (encoded == null) return null;
    try {
      return [
        for (final item in jsonDecode(encoded) as List<Object?>)
          expenseFromJson(item! as Map<String, Object?>),
      ];
    } on Object {
      await _preferences.remove(_expensesKey);
      return null;
    }
  }

  @override
  Future<void> writeExpenses(List<Expense> expenses) => _preferences.setString(
    _expensesKey,
    jsonEncode([
      for (final expense in expenses.take(_expenseLimit))
        expenseToJson(expense),
    ]),
  );
}

/// A cache that keeps nothing, for signed-out and test contexts.
class NullMoneyCache implements MoneyCache {
  const NullMoneyCache();

  @override
  Future<MoneyOverview?> readOverview() async => null;

  @override
  Future<void> writeOverview(MoneyOverview overview) async {}

  @override
  Future<List<Expense>?> readExpenses() async => null;

  @override
  Future<void> writeExpenses(List<Expense> expenses) async {}
}
