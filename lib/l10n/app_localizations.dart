import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('es', '419'),
    Locale('es', 'ES'),
  ];

  /// Application title used by Flutter.
  ///
  /// In en, this message translates to:
  /// **'Focus List'**
  String get appTitle;

  /// Reserved native window title.
  ///
  /// In en, this message translates to:
  /// **'Focus List'**
  String get windowTitle;

  /// Brand label at the workspace header.
  ///
  /// In en, this message translates to:
  /// **'FOCUS LIST'**
  String get workspaceTitle;

  /// Button that dismisses an editor or confirmation.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button that saves a task or list editor.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Destructive confirmation or task-menu action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Button that closes a dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Compact Android floating action button label.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// Action and dialog title for creating a task.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// Action and dialog title for creating a nested task.
  ///
  /// In en, this message translates to:
  /// **'New subtask'**
  String get newSubtask;

  /// Task-menu action that hides descendants.
  ///
  /// In en, this message translates to:
  /// **'Collapse subtasks'**
  String get collapseSubtasks;

  /// Task-menu action that reveals descendants.
  ///
  /// In en, this message translates to:
  /// **'Expand subtasks'**
  String get expandSubtasks;

  /// Task editor dialog title.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// Task duplication dialog title.
  ///
  /// In en, this message translates to:
  /// **'Duplicate task'**
  String get duplicateTask;

  /// Destructive task-deletion confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTaskTitle;

  /// Destructive task-list deletion confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete list?'**
  String get deleteListTitle;

  /// Task-list menu action.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get deleteList;

  /// Warning in the task-deletion confirmation.
  ///
  /// In en, this message translates to:
  /// **'This task and all its subtasks will be deleted. This cannot be undone.'**
  String get deleteTaskBody;

  /// Delete-list confirmation; listName is user-created text.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{listName}\" and all its tasks?'**
  String deleteListBody(Object listName);

  /// Title of the shortcut-reference dialog.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcuts;

  /// Multiline desktop shortcut reference. Keep key glyphs and line breaks.
  ///
  /// In en, this message translates to:
  /// **'↑/↓ or J/K   Move selection\nSpace then F   Advance status\nSpace then ↑/↓   Reorder task/subtree\nN / A / E / D / X   New, subtask, edit, duplicate, delete\nH   Collapse / expand subtasks\nT / Shift+T   Cycle first / second tag\nTab / Shift+Tab   Switch task lists\nCtrl+A   Multi view\nCtrl+N   New list\nF2 / Ctrl+R   Rename list\nCtrl+X   Delete list\nC   Doing focus\nV   Completed history\nG   Settings\nS   Sound\nQ   Quit'**
  String get keyboardShortcutsHelp;

  /// Fallback workspace loading error.
  ///
  /// In en, this message translates to:
  /// **'Could not load Focus List'**
  String get couldNotLoad;

  /// Accessibility label for Linux window drag area.
  ///
  /// In en, this message translates to:
  /// **'Drag window'**
  String get dragWindow;

  /// Tooltip for the Android new-task icon.
  ///
  /// In en, this message translates to:
  /// **'New task (N)'**
  String get newTaskTooltip;

  /// Tooltip for the Android new-list icon.
  ///
  /// In en, this message translates to:
  /// **'New list (Ctrl+N)'**
  String get newListTooltip;

  /// Tooltip for the task-list overflow menu.
  ///
  /// In en, this message translates to:
  /// **'List actions'**
  String get listActions;

  /// Tooltip for the application overflow menu.
  ///
  /// In en, this message translates to:
  /// **'App actions'**
  String get appActions;

  /// Action and dialog title for creating a task list.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get newList;

  /// Task-list menu action and editor title.
  ///
  /// In en, this message translates to:
  /// **'Rename list'**
  String get renameList;

  /// Menu action that opens or closes the multi-list view.
  ///
  /// In en, this message translates to:
  /// **'Toggle Multi view'**
  String get toggleMultiView;

  /// Application settings menu action and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Accessibility label for a task-list tab; listName is user content.
  ///
  /// In en, this message translates to:
  /// **'Task list {listName}'**
  String taskList(Object listName);

  /// Uppercase header label for the normal task-list view.
  ///
  /// In en, this message translates to:
  /// **'LIST VIEW'**
  String get listView;

  /// Uppercase header label for the active-task view.
  ///
  /// In en, this message translates to:
  /// **'DOING FOCUS'**
  String get doingFocus;

  /// Uppercase header label for completion history.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completed;

  /// Uppercase header label for the cross-list view.
  ///
  /// In en, this message translates to:
  /// **'MULTI VIEW'**
  String get multiView;

  /// Task status label.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Task status label for active work.
  ///
  /// In en, this message translates to:
  /// **'Doing'**
  String get doing;

  /// Task status label for completed work.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Empty state in the active-task view.
  ///
  /// In en, this message translates to:
  /// **'No doing tasks'**
  String get noDoingTasks;

  /// Empty state in completion history; references a keyboard shortcut.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet — finish one with Space, then F.'**
  String get noCompletedTasks;

  /// Empty state in the multi-list view.
  ///
  /// In en, this message translates to:
  /// **'No Doing or Pending tasks'**
  String get noDoingOrPendingTasks;

  /// Shown after a bullet in an empty task-status section.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get empty;

  /// Screen-reader label for a task row; title and tags are user content.
  ///
  /// In en, this message translates to:
  /// **'{status} task: {title}{tags}'**
  String taskSemantics(Object status, Object title, Object tags);

  /// No description provided for @taskTagsSemantics.
  ///
  /// In en, this message translates to:
  /// **', tags: {tags}'**
  String taskTagsSemantics(Object tags);

  /// Tooltip for the button that advances a task status.
  ///
  /// In en, this message translates to:
  /// **'Advance task'**
  String get advanceTask;

  /// Tooltip for the task overflow menu.
  ///
  /// In en, this message translates to:
  /// **'Task actions'**
  String get taskActions;

  /// Task menu action that moves a completed task to Doing.
  ///
  /// In en, this message translates to:
  /// **'Restore to Pending'**
  String get reopenInDoing;

  /// Short task menu action.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Short task menu action.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// Terminal footer status after pressing Space; preserve surrounding spaces.
  ///
  /// In en, this message translates to:
  /// **' SPACE armed — F advance, ↑↓ reorder '**
  String get spaceArmed;

  /// Terminal footer prefix before the daily-task completion glyphs.
  ///
  /// In en, this message translates to:
  /// **' Daily: {activity}'**
  String dailyActivity(Object activity);

  /// Compact non-terminal footer shortcut reference.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+A multi   Tab lists   ↑↓ move   N new   Space+F advance   Space+↑↓ sort   ? help'**
  String get keyboardHint;

  /// Screen-reader label for a terminal command shortcut.
  ///
  /// In en, this message translates to:
  /// **'{label} command ({keys})'**
  String commandSemantics(Object label, Object keys);

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'multi'**
  String get commandMulti;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'lists'**
  String get commandLists;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'move'**
  String get commandMove;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get commandNew;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'advance'**
  String get commandAdvance;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'sort'**
  String get commandSort;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'tags'**
  String get commandTags;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'new list'**
  String get commandNewList;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'rename'**
  String get commandRename;

  /// Abbreviated terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'del list'**
  String get commandDeleteList;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get commandSettings;

  /// Short terminal footer command label.
  ///
  /// In en, this message translates to:
  /// **'help'**
  String get commandHelp;

  /// Floating label for the task-title input.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitle;

  /// Toggle label marking a task as daily.
  ///
  /// In en, this message translates to:
  /// **'Daily task'**
  String get dailyTask;

  /// Floating label for the task-list name input.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listName;

  /// Validation error for custom task-tag names.
  ///
  /// In en, this message translates to:
  /// **'Tag names cannot be empty'**
  String get tagNamesCannotBeEmpty;

  /// Settings label above the task-title scrolling speed slider.
  ///
  /// In en, this message translates to:
  /// **'Marquee speed: {milliseconds} ms'**
  String marqueeSpeed(int milliseconds);

  /// Setting that wraps rather than scrolls long task titles.
  ///
  /// In en, this message translates to:
  /// **'Wrap long titles'**
  String get wrapLongTitles;

  /// Settings label above the terminal font-size slider.
  ///
  /// In en, this message translates to:
  /// **'Desktop font size: {points} pt'**
  String desktopFontSize(int points);

  /// Heading for editable task-tag names.
  ///
  /// In en, this message translates to:
  /// **'Tag names'**
  String get tagNames;

  /// Button that saves custom task-tag names.
  ///
  /// In en, this message translates to:
  /// **'Save tag names'**
  String get saveTagNames;

  /// Settings row label for the application's display language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Terminal settings control showing the selected display language.
  ///
  /// In en, this message translates to:
  /// **'Language: {language}'**
  String languageValue(Object language);

  /// Native name of this locale, shown in the language selector.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case '419':
            return AppLocalizationsEs419();
          case 'ES':
            return AppLocalizationsEsEs();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
