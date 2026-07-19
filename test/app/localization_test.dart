import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/l10n/app_localizations_en.dart';
import 'package:flutter_app/l10n/app_localizations_es.dart';

void main() {
  test('English catalog provides parameterized UI text', () {
    final strings = AppLocalizationsEn();

    expect(
      strings.deleteListBody('Inbox'),
      'Delete "Inbox" and all its tasks?',
    );
    expect(strings.marqueeSpeed(180), 'Marquee speed: 180 ms');
  });

  test('Spanish catalog translates task-list UI text', () {
    final strings = AppLocalizationsEs();

    expect(strings.newTask, 'Nueva tarea');
    expect(
      strings.deleteListBody('Bandeja'),
      '¿Eliminar "Bandeja" y todas sus tareas?',
    );
  });

  test(
    'generated locales provide their own names for the language selector',
    () {
      expect(
        AppLocalizations.supportedLocales.map((locale) => locale.toString()),
        containsAll(['en', 'es', 'es_419', 'es_ES']),
      );
      expect(
        lookupAppLocalizations(const Locale('es', '419')).languageName,
        'Español Latino',
      );
    },
  );
}
