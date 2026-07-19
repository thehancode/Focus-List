// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Focus List';

  @override
  String get windowTitle => 'Focus List';

  @override
  String get workspaceTitle => 'Focus List';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get close => 'Cerrar';

  @override
  String get task => 'Tarea';

  @override
  String get newTask => 'Nueva tarea';

  @override
  String get editTask => 'Editar tarea';

  @override
  String get duplicateTask => 'Duplicar tarea';

  @override
  String get deleteTaskTitle => '¿Eliminar tarea?';

  @override
  String get deleteListTitle => '¿Eliminar lista?';

  @override
  String get deleteList => 'Eliminar lista';

  @override
  String get deleteTaskBody => 'Esta acción no se puede deshacer.';

  @override
  String deleteListBody(Object listName) {
    return '¿Eliminar \"$listName\" y todas sus tareas?';
  }

  @override
  String get keyboardShortcuts => 'Atajos de teclado';

  @override
  String get keyboardShortcutsHelp =>
      '↑/↓ o J/K   Mover selección\nEspacio y F   Avanzar estado\nEspacio y ↑/↓   Reordenar por estado\nN / E / D / X   Crear, editar, duplicar, eliminar tarea\nT / Mayús+T   Cambiar primera / segunda etiqueta\nTab / Mayús+Tab   Cambiar listas de tareas\nCtrl+A   Vista múltiple\nCtrl+N   Nueva lista\nF2 / Ctrl+R   Renombrar lista\nCtrl+X   Eliminar lista\nC   Enfoque en curso\nV   Historial completado\nG   Ajustes\nS   Sonido\nQ   Salir';

  @override
  String get couldNotLoad => 'No se pudo cargar la lista de enfoque';

  @override
  String get dragWindow => 'Arrastrar ventana';

  @override
  String get newTaskTooltip => 'Nueva tarea (N)';

  @override
  String get newListTooltip => 'Nueva lista (Ctrl+N)';

  @override
  String get listActions => 'Acciones de lista';

  @override
  String get appActions => 'Acciones de aplicación';

  @override
  String get newList => 'Nueva lista';

  @override
  String get renameList => 'Renombrar lista';

  @override
  String get toggleMultiView => 'Alternar vista múltiple';

  @override
  String get settings => 'Ajustes';

  @override
  String taskList(Object listName) {
    return 'Lista de tareas $listName';
  }

  @override
  String get listView => 'VISTA DE LISTA';

  @override
  String get doingFocus => 'ENFOQUE EN CURSO';

  @override
  String get completed => 'COMPLETADAS';

  @override
  String get multiView => 'VISTA MÚLTIPLE';

  @override
  String get pending => 'Pendiente';

  @override
  String get doing => 'En curso';

  @override
  String get done => 'Hecha';

  @override
  String get noDoingTasks => 'No hay tareas en curso';

  @override
  String get noCompletedTasks =>
      'Aún no hay tareas completadas; termina una con Espacio y F.';

  @override
  String get noDoingOrPendingTasks => 'No hay tareas en curso ni pendientes';

  @override
  String get empty => 'vacío';

  @override
  String taskSemantics(Object status, Object title, Object tags) {
    return 'Tarea $status: $title$tags';
  }

  @override
  String taskTagsSemantics(Object tags) {
    return ', etiquetas: $tags';
  }

  @override
  String get advanceTask => 'Avanzar tarea';

  @override
  String get taskActions => 'Acciones de tarea';

  @override
  String get reopenInDoing => 'Reabrir en curso';

  @override
  String get edit => 'Editar';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get spaceArmed => ' ESPACIO activado — F avanza, ↑↓ reordena ';

  @override
  String dailyActivity(Object activity) {
    return ' Diaria: $activity';
  }

  @override
  String get keyboardHint =>
      'Ctrl+A múltiple   Tab listas   ↑↓ mover   N nueva   Espacio+F avanzar   Espacio+↑↓ ordenar   ? ayuda';

  @override
  String commandSemantics(Object label, Object keys) {
    return 'comando $label ($keys)';
  }

  @override
  String get commandMulti => 'múltiple';

  @override
  String get commandLists => 'listas';

  @override
  String get commandMove => 'mover';

  @override
  String get commandNew => 'nueva';

  @override
  String get commandAdvance => 'avanzar';

  @override
  String get commandSort => 'ordenar';

  @override
  String get commandTags => 'etiquetas';

  @override
  String get commandNewList => 'nueva lista';

  @override
  String get commandRename => 'renombrar';

  @override
  String get commandDeleteList => 'elim. lista';

  @override
  String get commandSettings => 'ajustes';

  @override
  String get commandHelp => 'ayuda';

  @override
  String get taskTitle => 'Título de la tarea';

  @override
  String get dailyTask => 'Tarea diaria';

  @override
  String get listName => 'Nombre de la lista';

  @override
  String get tagNamesCannotBeEmpty =>
      'Los nombres de etiquetas no pueden estar vacíos';

  @override
  String marqueeSpeed(int milliseconds) {
    return 'Velocidad de desplazamiento: $milliseconds ms';
  }

  @override
  String get wrapLongTitles => 'Ajustar títulos largos';

  @override
  String desktopFontSize(int points) {
    return 'Tamaño de fuente de escritorio: $points pt';
  }

  @override
  String get tagNames => 'Nombres de etiquetas';

  @override
  String get saveTagNames => 'Guardar nombres de etiquetas';

  @override
  String get language => 'Idioma';

  @override
  String languageValue(Object language) {
    return 'Idioma: $language';
  }

  @override
  String get languageName => 'Español';
}

/// The translations for Spanish Castilian, as used in Latin America and the Caribbean (`es_419`).
class AppLocalizationsEs419 extends AppLocalizationsEs {
  AppLocalizationsEs419() : super('es_419');

  @override
  String get appTitle => 'Focus List';

  @override
  String get windowTitle => 'Focus List';

  @override
  String get workspaceTitle => 'Focus List';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get close => 'Cerrar';

  @override
  String get task => 'Tarea';

  @override
  String get newTask => 'Nueva tarea';

  @override
  String get editTask => 'Editar tarea';

  @override
  String get duplicateTask => 'Duplicar tarea';

  @override
  String get deleteTaskTitle => '¿Eliminar tarea?';

  @override
  String get deleteListTitle => '¿Eliminar lista?';

  @override
  String get deleteList => 'Eliminar lista';

  @override
  String get deleteTaskBody => 'Esta acción no se puede deshacer.';

  @override
  String deleteListBody(Object listName) {
    return '¿Eliminar \"$listName\" y todas sus tareas?';
  }

  @override
  String get keyboardShortcuts => 'Atajos de teclado';

  @override
  String get keyboardShortcutsHelp =>
      '↑/↓ o J/K   Mover selección\nEspacio y F   Avanzar estado\nEspacio y ↑/↓   Reordenar por estado\nN / E / D / X   Crear, editar, duplicar, eliminar tarea\nT / Mayús+T   Cambiar primera / segunda etiqueta\nTab / Mayús+Tab   Cambiar listas de tareas\nCtrl+A   Vista múltiple\nCtrl+N   Nueva lista\nF2 / Ctrl+R   Renombrar lista\nCtrl+X   Eliminar lista\nC   Enfoque en curso\nV   Historial completado\nG   Configuración\nS   Sonido\nQ   Salir';

  @override
  String get couldNotLoad => 'No se pudo cargar Focus List';

  @override
  String get dragWindow => 'Arrastrar ventana';

  @override
  String get newTaskTooltip => 'Nueva tarea (N)';

  @override
  String get newListTooltip => 'Nueva lista (Ctrl+N)';

  @override
  String get listActions => 'Acciones de lista';

  @override
  String get appActions => 'Acciones de la aplicación';

  @override
  String get newList => 'Nueva lista';

  @override
  String get renameList => 'Cambiar nombre de la lista';

  @override
  String get toggleMultiView => 'Alternar vista múltiple';

  @override
  String get settings => 'Configuración';

  @override
  String taskList(Object listName) {
    return 'Lista de tareas $listName';
  }

  @override
  String get listView => 'VISTA DE LISTA';

  @override
  String get doingFocus => 'ENFOQUE EN CURSO';

  @override
  String get completed => 'COMPLETADAS';

  @override
  String get multiView => 'VISTA MÚLTIPLE';

  @override
  String get pending => 'Pendiente';

  @override
  String get doing => 'En curso';

  @override
  String get done => 'Completada';

  @override
  String get noDoingTasks => 'No hay tareas en curso';

  @override
  String get noCompletedTasks =>
      'Aún no hay tareas completadas; termina una con Espacio y F.';

  @override
  String get noDoingOrPendingTasks => 'No hay tareas en curso ni pendientes';

  @override
  String get empty => 'vacío';

  @override
  String taskSemantics(Object status, Object title, Object tags) {
    return 'Tarea $status: $title$tags';
  }

  @override
  String taskTagsSemantics(Object tags) {
    return ', etiquetas: $tags';
  }

  @override
  String get advanceTask => 'Avanzar tarea';

  @override
  String get taskActions => 'Acciones de tarea';

  @override
  String get reopenInDoing => 'Reabrir en curso';

  @override
  String get edit => 'Editar';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get spaceArmed => ' ESPACIO activado — F avanza, ↑↓ reordena ';

  @override
  String dailyActivity(Object activity) {
    return ' Diaria: $activity';
  }

  @override
  String get keyboardHint =>
      'Ctrl+A múltiple   Tab listas   ↑↓ mover   N nueva   Espacio+F avanzar   Espacio+↑↓ ordenar   ? ayuda';

  @override
  String commandSemantics(Object label, Object keys) {
    return 'comando $label ($keys)';
  }

  @override
  String get commandMulti => 'múltiple';

  @override
  String get commandLists => 'listas';

  @override
  String get commandMove => 'mover';

  @override
  String get commandNew => 'nueva';

  @override
  String get commandAdvance => 'avanzar';

  @override
  String get commandSort => 'ordenar';

  @override
  String get commandTags => 'etiquetas';

  @override
  String get commandNewList => 'nueva lista';

  @override
  String get commandRename => 'cambiar nombre';

  @override
  String get commandDeleteList => 'elim. lista';

  @override
  String get commandSettings => 'config.';

  @override
  String get commandHelp => 'ayuda';

  @override
  String get taskTitle => 'Título de la tarea';

  @override
  String get dailyTask => 'Tarea diaria';

  @override
  String get listName => 'Nombre de la lista';

  @override
  String get tagNamesCannotBeEmpty =>
      'Los nombres de las etiquetas no pueden estar vacíos';

  @override
  String marqueeSpeed(int milliseconds) {
    return 'Velocidad de desplazamiento: $milliseconds ms';
  }

  @override
  String get wrapLongTitles => 'Ajustar títulos largos';

  @override
  String desktopFontSize(int points) {
    return 'Tamaño de fuente en escritorio: $points pt';
  }

  @override
  String get tagNames => 'Nombres de las etiquetas';

  @override
  String get saveTagNames => 'Guardar nombres de las etiquetas';

  @override
  String get language => 'Idioma';

  @override
  String languageValue(Object language) {
    return 'Idioma: $language';
  }

  @override
  String get languageName => 'Español Latino';
}

/// The translations for Spanish Castilian, as used in Spain (`es_ES`).
class AppLocalizationsEsEs extends AppLocalizationsEs {
  AppLocalizationsEsEs() : super('es_ES');

  @override
  String get appTitle => 'Focus List';

  @override
  String get windowTitle => 'Focus List';

  @override
  String get workspaceTitle => 'Focus List';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get close => 'Cerrar';

  @override
  String get task => 'Tarea';

  @override
  String get newTask => 'Nueva tarea';

  @override
  String get editTask => 'Editar tarea';

  @override
  String get duplicateTask => 'Duplicar tarea';

  @override
  String get deleteTaskTitle => '¿Eliminar tarea?';

  @override
  String get deleteListTitle => '¿Eliminar lista?';

  @override
  String get deleteList => 'Eliminar lista';

  @override
  String get deleteTaskBody => 'Esta acción no se puede deshacer.';

  @override
  String deleteListBody(Object listName) {
    return '¿Eliminar \"$listName\" y todas sus tareas?';
  }

  @override
  String get keyboardShortcuts => 'Atajos de teclado';

  @override
  String get keyboardShortcutsHelp =>
      '↑/↓ o J/K   Mover selección\nEspacio y F   Avanzar estado\nEspacio y ↑/↓   Reordenar por estado\nN / E / D / X   Crear, editar, duplicar, eliminar tarea\nT / Mayús+T   Cambiar primera / segunda etiqueta\nTab / Mayús+Tab   Cambiar listas de tareas\nCtrl+A   Vista múltiple\nCtrl+N   Nueva lista\nF2 / Ctrl+R   Renombrar lista\nCtrl+X   Eliminar lista\nC   Enfoque en curso\nV   Historial completado\nG   Ajustes\nS   Sonido\nQ   Salir';

  @override
  String get couldNotLoad => 'No se pudo cargar Focus List';

  @override
  String get dragWindow => 'Arrastrar ventana';

  @override
  String get newTaskTooltip => 'Nueva tarea (N)';

  @override
  String get newListTooltip => 'Nueva lista (Ctrl+N)';

  @override
  String get listActions => 'Acciones de lista';

  @override
  String get appActions => 'Acciones de aplicación';

  @override
  String get newList => 'Nueva lista';

  @override
  String get renameList => 'Renombrar lista';

  @override
  String get toggleMultiView => 'Alternar vista múltiple';

  @override
  String get settings => 'Ajustes';

  @override
  String taskList(Object listName) {
    return 'Lista de tareas $listName';
  }

  @override
  String get listView => 'VISTA DE LISTA';

  @override
  String get doingFocus => 'ENFOQUE EN CURSO';

  @override
  String get completed => 'COMPLETADAS';

  @override
  String get multiView => 'VISTA MÚLTIPLE';

  @override
  String get pending => 'Pendiente';

  @override
  String get doing => 'En curso';

  @override
  String get done => 'Hecha';

  @override
  String get noDoingTasks => 'No hay tareas en curso';

  @override
  String get noCompletedTasks =>
      'Aún no hay tareas completadas; termina una con Espacio y F.';

  @override
  String get noDoingOrPendingTasks => 'No hay tareas en curso ni pendientes';

  @override
  String get empty => 'vacío';

  @override
  String taskSemantics(Object status, Object title, Object tags) {
    return 'Tarea $status: $title$tags';
  }

  @override
  String taskTagsSemantics(Object tags) {
    return ', etiquetas: $tags';
  }

  @override
  String get advanceTask => 'Avanzar tarea';

  @override
  String get taskActions => 'Acciones de tarea';

  @override
  String get reopenInDoing => 'Reabrir en curso';

  @override
  String get edit => 'Editar';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get spaceArmed => ' ESPACIO activado — F avanza, ↑↓ reordena ';

  @override
  String dailyActivity(Object activity) {
    return ' Diaria: $activity';
  }

  @override
  String get keyboardHint =>
      'Ctrl+A múltiple   Tab listas   ↑↓ mover   N nueva   Espacio+F avanzar   Espacio+↑↓ ordenar   ? ayuda';

  @override
  String commandSemantics(Object label, Object keys) {
    return 'comando $label ($keys)';
  }

  @override
  String get commandMulti => 'múltiple';

  @override
  String get commandLists => 'listas';

  @override
  String get commandMove => 'mover';

  @override
  String get commandNew => 'nueva';

  @override
  String get commandAdvance => 'avanzar';

  @override
  String get commandSort => 'ordenar';

  @override
  String get commandTags => 'etiquetas';

  @override
  String get commandNewList => 'nueva lista';

  @override
  String get commandRename => 'renombrar';

  @override
  String get commandDeleteList => 'elim. lista';

  @override
  String get commandSettings => 'ajustes';

  @override
  String get commandHelp => 'ayuda';

  @override
  String get taskTitle => 'Título de la tarea';

  @override
  String get dailyTask => 'Tarea diaria';

  @override
  String get listName => 'Nombre de la lista';

  @override
  String get tagNamesCannotBeEmpty =>
      'Los nombres de etiquetas no pueden estar vacíos';

  @override
  String marqueeSpeed(int milliseconds) {
    return 'Velocidad de desplazamiento: $milliseconds ms';
  }

  @override
  String get wrapLongTitles => 'Ajustar títulos largos';

  @override
  String desktopFontSize(int points) {
    return 'Tamaño de fuente de escritorio: $points pt';
  }

  @override
  String get tagNames => 'Nombres de etiquetas';

  @override
  String get saveTagNames => 'Guardar nombres de etiquetas';

  @override
  String get language => 'Idioma';

  @override
  String languageValue(Object language) {
    return 'Idioma: $language';
  }

  @override
  String get languageName => 'Español (España)';
}
