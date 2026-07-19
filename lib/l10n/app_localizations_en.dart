// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Focus List';

  @override
  String get windowTitle => 'TUI Kanban';

  @override
  String get workspaceTitle => 'FOCUS LIST';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get task => 'Task';

  @override
  String get newTask => 'New task';

  @override
  String get editTask => 'Edit task';

  @override
  String get duplicateTask => 'Duplicate task';

  @override
  String get deleteTaskTitle => 'Delete task?';

  @override
  String get deleteListTitle => 'Delete list?';

  @override
  String get deleteList => 'Delete list';

  @override
  String get deleteTaskBody => 'This cannot be undone.';

  @override
  String deleteListBody(Object listName) {
    return 'Delete \"$listName\" and all its tasks?';
  }

  @override
  String get keyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get keyboardShortcutsHelp =>
      '↑/↓ or J/K   Move selection\\nSpace then F   Advance status\\nSpace then ↑/↓   Reorder in status\\nN / E / D / X   New, edit, duplicate, delete task\\nT / Shift+T   Cycle first / second tag\\nTab / Shift+Tab   Switch task lists\\nCtrl+A   Multi view\\nCtrl+N   New list\\nF2 / Ctrl+R   Rename list\\nCtrl+X   Delete list\\nC   Doing focus\\nV   Completed history\\nG   Settings\\nS   Sound\\nQ   Quit';

  @override
  String get couldNotLoad => 'Could not load Focus List';

  @override
  String get dragWindow => 'Drag window';

  @override
  String get newTaskTooltip => 'New task (N)';

  @override
  String get newListTooltip => 'New list (Ctrl+N)';

  @override
  String get listActions => 'List actions';

  @override
  String get appActions => 'App actions';

  @override
  String get newList => 'New list';

  @override
  String get renameList => 'Rename list';

  @override
  String get toggleMultiView => 'Toggle Multi view';

  @override
  String get settings => 'Settings';

  @override
  String taskList(Object listName) {
    return 'Task list $listName';
  }

  @override
  String get listView => 'LIST VIEW';

  @override
  String get doingFocus => 'DOING FOCUS';

  @override
  String get completed => 'COMPLETED';

  @override
  String get multiView => 'MULTI VIEW';

  @override
  String get pending => 'Pending';

  @override
  String get doing => 'Doing';

  @override
  String get done => 'Done';

  @override
  String get noDoingTasks => 'No doing tasks';

  @override
  String get noCompletedTasks =>
      'No completed tasks yet — finish one with Space, then F.';

  @override
  String get noDoingOrPendingTasks => 'No Doing or Pending tasks';

  @override
  String get empty => 'empty';

  @override
  String taskSemantics(Object status, Object title, Object tags) {
    return '$status task: $title$tags';
  }

  @override
  String taskTagsSemantics(Object tags) {
    return ', tags: $tags';
  }

  @override
  String get advanceTask => 'Advance task';

  @override
  String get taskActions => 'Task actions';

  @override
  String get reopenInDoing => 'Reopen in Doing';

  @override
  String get edit => 'Edit';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get spaceArmed => ' SPACE armed — F advance, ↑↓ reorder ';

  @override
  String dailyActivity(Object activity) {
    return ' Daily: $activity';
  }

  @override
  String get keyboardHint =>
      'Ctrl+A multi   Tab lists   ↑↓ move   N new   Space+F advance   Space+↑↓ sort   ? help';

  @override
  String commandSemantics(Object label, Object keys) {
    return '$label command ($keys)';
  }

  @override
  String get commandMulti => 'multi';

  @override
  String get commandLists => 'lists';

  @override
  String get commandMove => 'move';

  @override
  String get commandNew => 'new';

  @override
  String get commandAdvance => 'advance';

  @override
  String get commandSort => 'sort';

  @override
  String get commandTags => 'tags';

  @override
  String get commandNewList => 'new list';

  @override
  String get commandRename => 'rename';

  @override
  String get commandDeleteList => 'del list';

  @override
  String get commandSettings => 'settings';

  @override
  String get commandHelp => 'help';

  @override
  String get taskTitle => 'Task title';

  @override
  String get dailyTask => 'Daily task';

  @override
  String get listName => 'List name';

  @override
  String get tagNamesCannotBeEmpty => 'Tag names cannot be empty';

  @override
  String marqueeSpeed(int milliseconds) {
    return 'Marquee speed: $milliseconds ms';
  }

  @override
  String get wrapLongTitles => 'Wrap long titles';

  @override
  String desktopFontSize(int points) {
    return 'Desktop font size: $points pt';
  }

  @override
  String get tagNames => 'Tag names';

  @override
  String get saveTagNames => 'Save tag names';
}
