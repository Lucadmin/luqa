import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/features/money/presentation/money_formatters.dart';

void main() {
  group('formatMoney', () {
    test('shows cents by default and drops them only when asked', () {
      expect(formatMoney(4800, 'EUR'), '€48.00');
      expect(formatMoney(4800, 'EUR', compact: true), '€48');
      // Compact never hides a real fraction — that would be a lie about the
      // amount, not a tidier one.
      expect(formatMoney(4850, 'EUR', compact: true), '€48.50');
    });

    test('groups thousands', () {
      expect(formatMoney(123456, 'EUR'), '€1,234.56');
      expect(formatMoney(100000000, 'EUR', compact: true), '€1,000,000');
    });

    test('a negative amount takes a true minus sign, not a hyphen', () {
      expect(formatMoney(-1250, 'EUR'), '−€12.50');
    });

    test('signed marks the direction on a ledger row', () {
      expect(formatMoney(1250, 'EUR', signed: true), '+€12.50');
      expect(formatMoney(-1250, 'EUR', signed: true), '−€12.50');
      expect(formatMoney(0, 'EUR', signed: true), '€0.00');
    });

    test('an unknown currency falls back to its code rather than a wrong sign', () {
      expect(formatMoney(500, 'HUF'), 'HUF 5.00');
      expect(currencySymbol('USD'), r'$');
    });
  });

  group('parseAmountToCents', () {
    test('reads the ways people actually type an amount', () {
      expect(parseAmountToCents('12'), 1200);
      expect(parseAmountToCents('12.5'), 1250);
      expect(parseAmountToCents('12,50'), 1250);
      expect(parseAmountToCents('1.234,50'), 123450);
      expect(parseAmountToCents('1,234.50'), 123450);
      expect(parseAmountToCents('€42'), 4200);
    });

    test('a bare group of three is thousands, not a fraction', () {
      // "1.234" is twelve hundred euros, not one euro twenty-three.
      expect(parseAmountToCents('1.234'), 123400);
      expect(parseAmountToCents('1,234'), 123400);
    });

    test('a half-typed amount is left alone rather than snapped', () {
      expect(parseAmountToCents(''), isNull);
      expect(parseAmountToCents('abc'), isNull);
      // Still mid-keystroke: the separator is there but the cents are not.
      expect(parseAmountToCents('12,'), 1200);
    });

    test('a separator splitting off more than two digits is thousands', () {
      // The same rule the browser applies, so the same keystrokes mean the
      // same amount on both clients. "12.999" is not twelve euros ninety-nine.
      expect(parseAmountToCents('12.999'), 1299900);
      expect(parseAmountToCents('12.3456'), 12345600);
    });
  });

  group('balanceLabel', () {
    test('states the direction in words, so colour is never the only signal', () {
      expect(balanceLabel(1200, 'Mira'), 'Mira owes you');
      expect(balanceLabel(-1200, 'Mira'), 'You owe Mira');
      expect(balanceLabel(0, 'Mira'), 'Settled up');
    });
  });
}
