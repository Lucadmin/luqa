import 'package:flutter/material.dart';

/// Cents meeting the screen.
///
/// Everything in the money tab is integer cents — a bill is only ever divided
/// by `allocate`, never by a double — so this is the one place a number turns
/// into type.

const _symbols = <String, String>{
  'EUR': '€',
  'USD': r'$',
  'GBP': '£',
  'CHF': 'CHF ',
  'SEK': 'kr ',
  'NOK': 'kr ',
  'DKK': 'kr ',
  'PLN': 'zł ',
  'JPY': '¥',
};

String currencySymbol(String currency) =>
    _symbols[currency.toUpperCase()] ?? '$currency ';

/// "€12.50". [signed] gives ledger rows an explicit + or −; [compact] drops
/// ".00" on whole amounts, which is kinder in a dense list.
String formatMoney(
  int cents,
  String currency, {
  bool signed = false,
  bool compact = false,
}) {
  final whole = cents % 100 == 0;
  final digits = compact && whole ? 0 : 2;
  final text = '${currencySymbol(currency)}${_groupedAmount(cents.abs(), digits)}';
  // A true minus sign rather than a hyphen: at display size the difference is
  // the difference between a number and a hyphenated word.
  if (cents < 0) return '−$text';
  if (signed && cents > 0) return '+$text';
  return text;
}

String _groupedAmount(int cents, int digits) {
  final units = cents ~/ 100;
  final grouped = units.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );
  if (digits == 0) return grouped;
  return '$grouped.${(cents % 100).toString().padLeft(2, '0')}';
}

/// Whatever someone types into an amount field, in cents.
///
/// Accepts "12", "12.5", "12,50", "1.234,50", "1,234.50" and a leading symbol.
/// Returns null while the text is not yet a number, so a half-typed entry can
/// be left alone rather than snapped to something the user did not mean.
///
/// The separator rule is the browser's, character for character: the rightmost
/// separator is a decimal point only when it splits off one or two digits, so
/// "1.234" is twelve hundred euros and "1.23" is one euro twenty-three. The
/// same person uses both clients, and the same keystrokes have to mean the
/// same amount in each.
int? parseAmountToCents(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^\d.,]'), '').trim();
  if (cleaned.isEmpty) return null;

  final decimalAt = [
    cleaned.lastIndexOf('.'),
    cleaned.lastIndexOf(','),
  ].reduce((a, b) => a > b ? a : b);

  final String normalized;
  if (decimalAt == -1) {
    normalized = cleaned;
  } else {
    final tail = cleaned.substring(decimalAt + 1);
    normalized = RegExp(r'^\d{1,2}$').hasMatch(tail)
        ? '${cleaned.substring(0, decimalAt).replaceAll(RegExp(r'[.,]'), '')}'
              '.$tail'
        : cleaned.replaceAll(RegExp(r'[.,]'), '');
  }

  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite) return null;
  return (value * 100).round();
}

/// "Today", "Yesterday", then a plain date. Recent days get a word because
/// that is how people talk about a bill they can still picture.
String moneyDayLabel(BuildContext context, String dateKey, DateTime now) {
  final date = DateTime.tryParse(dateKey);
  if (date == null) return dateKey;
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return MaterialLocalizations.of(context).formatMediumDate(day);
}

/// The month heading the bill feed groups under.
String moneyMonthLabel(BuildContext context, String dateKey, DateTime now) {
  final date = DateTime.tryParse(dateKey);
  if (date == null) return dateKey;
  final localizations = MaterialLocalizations.of(context);
  if (date.year == now.year && date.month == now.month) return 'This month';
  if (date.year == now.year) {
    return localizations.formatMonthYear(date).split(' ').first;
  }
  return localizations.formatMonthYear(date);
}

/// How a balance reads in a sentence. "Mira owes you €12" is the fact; the
/// number beside it is the amount.
String balanceLabel(int balanceCents, String name) {
  if (balanceCents > 0) return '$name owes you';
  if (balanceCents < 0) return 'You owe $name';
  return 'Settled up';
}
