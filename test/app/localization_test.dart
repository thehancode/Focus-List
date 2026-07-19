import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/l10n/app_localizations_en.dart';

void main() {
  test('English catalog provides parameterized UI text', () {
    final strings = AppLocalizationsEn();

    expect(
      strings.deleteListBody('Inbox'),
      'Delete "Inbox" and all its tasks?',
    );
    expect(strings.marqueeSpeed(180), 'Marquee speed: 180 ms');
  });
}
