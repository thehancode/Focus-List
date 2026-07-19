import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus List'**
  String get appTitle;

  /// No description provided for @windowTitle.
  ///
  /// In en, this message translates to:
  /// **'TUI Kanban'**
  String get windowTitle;

  /// No description provided for @workspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'FOCUS LIST'**
  String get workspaceTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @duplicateTask.
  ///
  /// In en, this message translates to:
  /// **'Duplicate task'**
  String get duplicateTask;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTaskTitle;

  /// No description provided for @deleteListTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete list?'**
  String get deleteListTitle;

  /// No description provided for @deleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get deleteList;

  /// No description provided for @deleteTaskBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteTaskBody;

  /// No description provided for @deleteListBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{listName}\" and all its tasks?'**
  String deleteListBody(Object listName);

  /// No description provided for @keyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcuts;

  /// No description provided for @keyboardShortcutsHelp.
  ///
  /// In en, this message translates to:
  /// **'↑/↓ or J/K   Move selection\\nSpace then F   Advance status\\nSpace then ↑/↓   Reorder in status\\nN / E / D / X   New, edit, duplicate, delete task\\nT / Shift+T   Cycle first / second tag\\nTab / Shift+Tab   Switch task lists\\nCtrl+A   Multi view\\nCtrl+N   New list\\nF2 / Ctrl+R   Rename list\\nCtrl+X   Delete list\\nC   Doing focus\\nV   Completed history\\nG   Settings\\nS   Sound\\nQ   Quit'**
  String get keyboardShortcutsHelp;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load Focus List'**
  String get couldNotLoad;

  /// No description provided for @dragWindow.
  ///
  /// In en, this message translates to:
  /// **'Drag window'**
  String get dragWindow;

  /// No description provided for @newTaskTooltip.
  ///
  /// In en, this message translates to:
  /// **'New task (N)'**
  String get newTaskTooltip;

  /// No description provided for @newListTooltip.
  ///
  /// In en, this message translates to:
  /// **'New list (Ctrl+N)'**
  String get newListTooltip;

  /// No description provided for @listActions.
  ///
  /// In en, this message translates to:
  /// **'List actions'**
  String get listActions;

  /// No description provided for @appActions.
  ///
  /// In en, this message translates to:
  /// **'App actions'**
  String get appActions;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get newList;

  /// No description provided for @renameList.
  ///
  /// In en, this message translates to:
  /// **'Rename list'**
  String get renameList;

  /// No description provided for @toggleMultiView.
  ///
  /// In en, this message translates to:
  /// **'Toggle Multi view'**
  String get toggleMultiView;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @taskList.
  ///
  /// In en, this message translates to:
  /// **'Task list {listName}'**
  String taskList(Object listName);

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'LIST VIEW'**
  String get listView;

  /// No description provided for @doingFocus.
  ///
  /// In en, this message translates to:
  /// **'DOING FOCUS'**
  String get doingFocus;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completed;

  /// No description provided for @multiView.
  ///
  /// In en, this message translates to:
  /// **'MULTI VIEW'**
  String get multiView;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @doing.
  ///
  /// In en, this message translates to:
  /// **'Doing'**
  String get doing;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @noDoingTasks.
  ///
  /// In en, this message translates to:
  /// **'No doing tasks'**
  String get noDoingTasks;

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet — finish one with Space, then F.'**
  String get noCompletedTasks;

  /// No description provided for @noDoingOrPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'No Doing or Pending tasks'**
  String get noDoingOrPendingTasks;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get empty;

  /// No description provided for @taskSemantics.
  ///
  /// In en, this message translates to:
  /// **'{status} task: {title}{tags}'**
  String taskSemantics(Object status, Object title, Object tags);

  /// No description provided for @taskTagsSemantics.
  ///
  /// In en, this message translates to:
  /// **', tags: {tags}'**
  String taskTagsSemantics(Object tags);

  /// No description provided for @advanceTask.
  ///
  /// In en, this message translates to:
  /// **'Advance task'**
  String get advanceTask;

  /// No description provided for @taskActions.
  ///
  /// In en, this message translates to:
  /// **'Task actions'**
  String get taskActions;

  /// No description provided for @reopenInDoing.
  ///
  /// In en, this message translates to:
  /// **'Reopen in Doing'**
  String get reopenInDoing;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @spaceArmed.
  ///
  /// In en, this message translates to:
  /// **' SPACE armed — F advance, ↑↓ reorder '**
  String get spaceArmed;

  /// No description provided for @dailyActivity.
  ///
  /// In en, this message translates to:
  /// **' Daily: {activity}'**
  String dailyActivity(Object activity);

  /// No description provided for @keyboardHint.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+A multi   Tab lists   ↑↓ move   N new   Space+F advance   Space+↑↓ sort   ? help'**
  String get keyboardHint;

  /// No description provided for @commandSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} command ({keys})'**
  String commandSemantics(Object label, Object keys);

  /// No description provided for @commandMulti.
  ///
  /// In en, this message translates to:
  /// **'multi'**
  String get commandMulti;

  /// No description provided for @commandLists.
  ///
  /// In en, this message translates to:
  /// **'lists'**
  String get commandLists;

  /// No description provided for @commandMove.
  ///
  /// In en, this message translates to:
  /// **'move'**
  String get commandMove;

  /// No description provided for @commandNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get commandNew;

  /// No description provided for @commandAdvance.
  ///
  /// In en, this message translates to:
  /// **'advance'**
  String get commandAdvance;

  /// No description provided for @commandSort.
  ///
  /// In en, this message translates to:
  /// **'sort'**
  String get commandSort;

  /// No description provided for @commandTags.
  ///
  /// In en, this message translates to:
  /// **'tags'**
  String get commandTags;

  /// No description provided for @commandNewList.
  ///
  /// In en, this message translates to:
  /// **'new list'**
  String get commandNewList;

  /// No description provided for @commandRename.
  ///
  /// In en, this message translates to:
  /// **'rename'**
  String get commandRename;

  /// No description provided for @commandDeleteList.
  ///
  /// In en, this message translates to:
  /// **'del list'**
  String get commandDeleteList;

  /// No description provided for @commandSettings.
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get commandSettings;

  /// No description provided for @commandHelp.
  ///
  /// In en, this message translates to:
  /// **'help'**
  String get commandHelp;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitle;

  /// No description provided for @dailyTask.
  ///
  /// In en, this message translates to:
  /// **'Daily task'**
  String get dailyTask;

  /// No description provided for @listName.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listName;

  /// No description provided for @tagNamesCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tag names cannot be empty'**
  String get tagNamesCannotBeEmpty;

  /// No description provided for @marqueeSpeed.
  ///
  /// In en, this message translates to:
  /// **'Marquee speed: {milliseconds} ms'**
  String marqueeSpeed(int milliseconds);

  /// No description provided for @wrapLongTitles.
  ///
  /// In en, this message translates to:
  /// **'Wrap long titles'**
  String get wrapLongTitles;

  /// No description provided for @desktopFontSize.
  ///
  /// In en, this message translates to:
  /// **'Desktop font size: {points} pt'**
  String desktopFontSize(int points);

  /// No description provided for @tagNames.
  ///
  /// In en, this message translates to:
  /// **'Tag names'**
  String get tagNames;

  /// No description provided for @saveTagNames.
  ///
  /// In en, this message translates to:
  /// **'Save tag names'**
  String get saveTagNames;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
