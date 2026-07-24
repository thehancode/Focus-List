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
  String get newSubtask => 'Nueva subtarea';

  @override
  String get collapseSubtasks => 'Ocultar subtareas';

  @override
  String get expandSubtasks => 'Mostrar subtareas';

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
  String get deleteTaskBody =>
      'Se eliminarán esta tarea y todas sus subtareas. Esta acción no se puede deshacer.';

  @override
  String deleteListBody(Object listName) {
    return '¿Eliminar \"$listName\" y todas sus tareas?';
  }

  @override
  String get keyboardShortcuts => 'Atajos';

  @override
  String get keyboardShortcutsHelp =>
      '↑/↓ o J/K   Mover selección\n←/→   Cambiar listas\nEspacio y F   Avanzar estado\nEspacio y Espacio   Completar árbol\nEspacio y ↑/↓   Reordenar tarea\nN / Tab / E / D / X   Crear, subtarea, editar, duplicar, eliminar\nH   Contraer / expandir subtareas\nW / Mayús+W   Cambiar etiquetas\nCtrl+C   Copiar título\nCtrl+Mayús+C   Copiar sección\nCtrl+F o /   Buscar\nCtrl+Z   Deshacer\nCtrl+A   Vista múltiple\nCtrl+N   Nueva lista\nF2 / Ctrl+R   Renombrar lista\nCtrl+X   Eliminar lista\nC   Enfoque en curso\nV   Historial completado\nG   Ajustes\nS   Sonido\nQ   Salir';

  @override
  String get couldNotLoad => 'No se pudo cargar la lista de enfoque';

  @override
  String get dragWindow => 'Arrastrar ventana';

  @override
  String get newTaskTooltip => 'Nueva tarea (N)';

  @override
  String get newListTooltip => 'Nueva lista (Ctrl+N)';

  @override
  String get listActions => 'Lista';

  @override
  String get appActions => 'Menú';

  @override
  String get newList => 'Nueva lista';

  @override
  String get renameList => 'Renombrar lista';

  @override
  String get toggleMultiView => 'Multivista';

  @override
  String get settings => 'Ajustes';

  @override
  String taskList(Object listName) {
    return 'Lista de tareas $listName';
  }

  @override
  String get listView => 'LISTA';

  @override
  String get doingFocus => 'EN CURSO';

  @override
  String get completed => 'HECHAS';

  @override
  String get multiView => 'MULTIVISTA';

  @override
  String get pending => 'Pendiente';

  @override
  String get doing => 'En curso';

  @override
  String get done => 'Hecha';

  @override
  String get archived => 'Archived';

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
  String get advanceTask => 'Avanzar';

  @override
  String get taskActions => 'Tarea';

  @override
  String get reopenInDoing => 'Restaurar pendiente';

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
  String get taskTitle => 'Título';

  @override
  String get dailyTask => 'Diaria';

  @override
  String get listName => 'Lista';

  @override
  String get tagNamesCannotBeEmpty =>
      'Los nombres de etiquetas no pueden estar vacíos';

  @override
  String marqueeSpeed(int milliseconds) {
    return 'Velocidad de desplazamiento: $milliseconds ms';
  }

  @override
  String get wrapLongTitles => 'Ajustar títulos';

  @override
  String desktopFontSize(int points) {
    return 'Tamaño de fuente de escritorio: $points pt';
  }

  @override
  String get tagNames => 'Etiquetas';

  @override
  String get saveTagNames => 'Guardar etiquetas';

  @override
  String get language => 'Idioma';

  @override
  String languageValue(Object language) {
    return 'Idioma: $language';
  }

  @override
  String get showTips => 'Mostrar consejos al inicio';

  @override
  String get rewardDuration => 'Duración de recompensa';

  @override
  String get tipsTitle => 'Consejos';

  @override
  String get tipNavigation => 'Usa izquierda y derecha para cambiar de lista.';

  @override
  String get tipReorder =>
      'Pulsa Espacio y después arriba o abajo para reordenar una tarea.';

  @override
  String get tipSubtasks =>
      'Pulsa Tab para añadir una subtarea a la tarea seleccionada.';

  @override
  String get tipSearch => 'Pulsa Ctrl+F o / para buscar tareas.';

  @override
  String get tipCopy =>
      'Ctrl+C copia un título; Ctrl+Mayús+C copia su sección.';

  @override
  String get rewardGreatWork => '¡Gran trabajo!';

  @override
  String get rewardNicelyDone => '¡Bien hecho!';

  @override
  String get rewardKeepGoing => '¡Sigue así!';

  @override
  String get rewardMomentum => '¡Buen ritmo!';

  @override
  String get rewardTaskCleared => '¡Tarea completada!';

  @override
  String get rewardExcellent => '¡Excelente!';

  @override
  String get search => 'Buscar';

  @override
  String get previousMatch => 'Coincidencia anterior';

  @override
  String get nextMatch => 'Coincidencia siguiente';

  @override
  String get closeSearch => 'Cerrar búsqueda';

  @override
  String get typeToSearch => 'Escribe para buscar';

  @override
  String get noSearchMatches => 'Sin coincidencias';

  @override
  String get longTitleMode => 'Modo de títulos largos';

  @override
  String get wrapSelected => 'Ajustar seleccionado';

  @override
  String get wrapAll => 'Ajustar todos';

  @override
  String get marquee => 'Marquesina';

  @override
  String get shortDuration => 'Corta';

  @override
  String get mediumDuration => 'Media';

  @override
  String get longDuration => 'Larga';

  @override
  String get backgroundImage => 'Imagen de fondo';

  @override
  String get backgroundOpacity => 'Opacidad del color de fondo';

  @override
  String get backgroundFit => 'Ajuste de imagen';

  @override
  String get cover => 'Cubrir';

  @override
  String get contain => 'Contener';

  @override
  String get noImageSelected => 'Sin imagen seleccionada';

  @override
  String get none => 'Ninguna';

  @override
  String get clear => 'Quitar';

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
  String get newSubtask => 'Nueva subtarea';

  @override
  String get collapseSubtasks => 'Ocultar subtareas';

  @override
  String get expandSubtasks => 'Mostrar subtareas';

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
  String get deleteTaskBody =>
      'Se eliminarán esta tarea y todas sus subtareas. Esta acción no se puede deshacer.';

  @override
  String deleteListBody(Object listName) {
    return '¿Eliminar \"$listName\" y todas sus tareas?';
  }

  @override
  String get keyboardShortcuts => 'Atajos';

  @override
  String get keyboardShortcutsHelp =>
      '↑/↓ o J/K   Mover selección\n←/→   Cambiar listas\nEspacio y F   Avanzar estado\nEspacio y Espacio   Completar árbol\nEspacio y ↑/↓   Reordenar tarea\nN / Tab / E / D / X   Crear, subtarea, editar, duplicar, eliminar\nH   Contraer / expandir subtareas\nW / Mayús+W   Cambiar etiquetas\nCtrl+C   Copiar título\nCtrl+Mayús+C   Copiar sección\nCtrl+F o /   Buscar\nCtrl+Z   Deshacer\nCtrl+A   Vista múltiple\nCtrl+N   Nueva lista\nF2 / Ctrl+R   Renombrar lista\nCtrl+X   Eliminar lista\nC   Enfoque en curso\nV   Historial completado\nG   Configuración\nS   Sonido\nQ   Salir';

  @override
  String get couldNotLoad => 'No se pudo cargar Focus List';

  @override
  String get dragWindow => 'Arrastrar ventana';

  @override
  String get newTaskTooltip => 'Nueva tarea (N)';

  @override
  String get newListTooltip => 'Nueva lista (Ctrl+N)';

  @override
  String get listActions => 'Lista';

  @override
  String get appActions => 'Menú';

  @override
  String get newList => 'Nueva lista';

  @override
  String get renameList => 'Renombrar lista';

  @override
  String get toggleMultiView => 'Multivista';

  @override
  String get settings => 'Ajustes';

  @override
  String taskList(Object listName) {
    return 'Lista de tareas $listName';
  }

  @override
  String get listView => 'LISTA';

  @override
  String get doingFocus => 'EN CURSO';

  @override
  String get completed => 'HECHAS';

  @override
  String get multiView => 'MULTIVISTA';

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
  String get advanceTask => 'Avanzar';

  @override
  String get taskActions => 'Tarea';

  @override
  String get reopenInDoing => 'Restaurar pendiente';

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
  String get taskTitle => 'Título';

  @override
  String get dailyTask => 'Diaria';

  @override
  String get listName => 'Lista';

  @override
  String get tagNamesCannotBeEmpty =>
      'Los nombres de las etiquetas no pueden estar vacíos';

  @override
  String marqueeSpeed(int milliseconds) {
    return 'Velocidad de desplazamiento: $milliseconds ms';
  }

  @override
  String get wrapLongTitles => 'Ajustar títulos';

  @override
  String desktopFontSize(int points) {
    return 'Tamaño de fuente en escritorio: $points pt';
  }

  @override
  String get tagNames => 'Etiquetas';

  @override
  String get saveTagNames => 'Guardar etiquetas';

  @override
  String get language => 'Idioma';

  @override
  String languageValue(Object language) {
    return 'Idioma: $language';
  }

  @override
  String get showTips => 'Mostrar consejos al inicio';

  @override
  String get rewardDuration => 'Duración de recompensa';

  @override
  String get tipsTitle => 'Consejos';

  @override
  String get tipNavigation => 'Usa izquierda y derecha para cambiar de lista.';

  @override
  String get tipReorder =>
      'Presiona Espacio y luego arriba o abajo para reordenar una tarea.';

  @override
  String get tipSubtasks =>
      'Presiona Tab para agregar una subtarea a la tarea seleccionada.';

  @override
  String get tipSearch => 'Presiona Ctrl+F o / para buscar tareas.';

  @override
  String get tipCopy =>
      'Ctrl+C copia un título; Ctrl+Mayús+C copia su sección.';

  @override
  String get rewardGreatWork => '¡Gran trabajo!';

  @override
  String get rewardNicelyDone => '¡Bien hecho!';

  @override
  String get rewardKeepGoing => '¡Sigue así!';

  @override
  String get rewardMomentum => '¡Buen ritmo!';

  @override
  String get rewardTaskCleared => '¡Tarea completada!';

  @override
  String get rewardExcellent => '¡Excelente!';

  @override
  String get search => 'Buscar';

  @override
  String get previousMatch => 'Coincidencia anterior';

  @override
  String get nextMatch => 'Coincidencia siguiente';

  @override
  String get closeSearch => 'Cerrar búsqueda';

  @override
  String get typeToSearch => 'Escribe para buscar';

  @override
  String get noSearchMatches => 'Sin coincidencias';

  @override
  String get longTitleMode => 'Modo de títulos largos';

  @override
  String get wrapSelected => 'Ajustar seleccionado';

  @override
  String get wrapAll => 'Ajustar todos';

  @override
  String get marquee => 'Marquesina';

  @override
  String get shortDuration => 'Corta';

  @override
  String get mediumDuration => 'Media';

  @override
  String get longDuration => 'Larga';

  @override
  String get backgroundImage => 'Imagen de fondo';

  @override
  String get backgroundOpacity => 'Opacidad del color de fondo';

  @override
  String get backgroundFit => 'Ajuste de imagen';

  @override
  String get cover => 'Cubrir';

  @override
  String get contain => 'Contener';

  @override
  String get noImageSelected => 'Sin imagen seleccionada';

  @override
  String get none => 'Ninguna';

  @override
  String get clear => 'Quitar';

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
  String get newSubtask => 'Nueva subtarea';

  @override
  String get collapseSubtasks => 'Ocultar subtareas';

  @override
  String get expandSubtasks => 'Mostrar subtareas';

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
  String get deleteTaskBody =>
      'Se eliminarán esta tarea y todas sus subtareas. Esta acción no se puede deshacer.';

  @override
  String deleteListBody(Object listName) {
    return '¿Eliminar \"$listName\" y todas sus tareas?';
  }

  @override
  String get keyboardShortcuts => 'Atajos';

  @override
  String get keyboardShortcutsHelp =>
      '↑/↓ o J/K   Mover selección\n←/→   Cambiar listas\nEspacio y F   Avanzar estado\nEspacio y Espacio   Completar árbol\nEspacio y ↑/↓   Reordenar tarea\nN / Tab / E / D / X   Crear, subtarea, editar, duplicar, eliminar\nH   Contraer / expandir subtareas\nW / Mayús+W   Cambiar etiquetas\nCtrl+C   Copiar título\nCtrl+Mayús+C   Copiar sección\nCtrl+F o /   Buscar\nCtrl+Z   Deshacer\nCtrl+A   Vista múltiple\nCtrl+N   Nueva lista\nF2 / Ctrl+R   Renombrar lista\nCtrl+X   Eliminar lista\nC   Enfoque en curso\nV   Historial completado\nG   Ajustes\nS   Sonido\nQ   Salir';

  @override
  String get couldNotLoad => 'No se pudo cargar Focus List';

  @override
  String get dragWindow => 'Arrastrar ventana';

  @override
  String get newTaskTooltip => 'Nueva tarea (N)';

  @override
  String get newListTooltip => 'Nueva lista (Ctrl+N)';

  @override
  String get listActions => 'Lista';

  @override
  String get appActions => 'Menú';

  @override
  String get newList => 'Nueva lista';

  @override
  String get renameList => 'Renombrar lista';

  @override
  String get toggleMultiView => 'Multivista';

  @override
  String get settings => 'Ajustes';

  @override
  String taskList(Object listName) {
    return 'Lista de tareas $listName';
  }

  @override
  String get listView => 'LISTA';

  @override
  String get doingFocus => 'EN CURSO';

  @override
  String get completed => 'HECHAS';

  @override
  String get multiView => 'MULTIVISTA';

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
  String get advanceTask => 'Avanzar';

  @override
  String get taskActions => 'Tarea';

  @override
  String get reopenInDoing => 'Restaurar pendiente';

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
  String get taskTitle => 'Título';

  @override
  String get dailyTask => 'Diaria';

  @override
  String get listName => 'Lista';

  @override
  String get tagNamesCannotBeEmpty =>
      'Los nombres de etiquetas no pueden estar vacíos';

  @override
  String marqueeSpeed(int milliseconds) {
    return 'Velocidad de desplazamiento: $milliseconds ms';
  }

  @override
  String get wrapLongTitles => 'Ajustar títulos';

  @override
  String desktopFontSize(int points) {
    return 'Tamaño de fuente de escritorio: $points pt';
  }

  @override
  String get tagNames => 'Etiquetas';

  @override
  String get saveTagNames => 'Guardar etiquetas';

  @override
  String get language => 'Idioma';

  @override
  String languageValue(Object language) {
    return 'Idioma: $language';
  }

  @override
  String get showTips => 'Mostrar consejos al inicio';

  @override
  String get rewardDuration => 'Duración de recompensa';

  @override
  String get tipsTitle => 'Consejos';

  @override
  String get tipNavigation => 'Usa izquierda y derecha para cambiar de lista.';

  @override
  String get tipReorder =>
      'Pulsa Espacio y después arriba o abajo para reordenar una tarea.';

  @override
  String get tipSubtasks =>
      'Pulsa Tab para añadir una subtarea a la tarea seleccionada.';

  @override
  String get tipSearch => 'Pulsa Ctrl+F o / para buscar tareas.';

  @override
  String get tipCopy =>
      'Ctrl+C copia un título; Ctrl+Mayús+C copia su sección.';

  @override
  String get rewardGreatWork => '¡Gran trabajo!';

  @override
  String get rewardNicelyDone => '¡Bien hecho!';

  @override
  String get rewardKeepGoing => '¡Sigue así!';

  @override
  String get rewardMomentum => '¡Buen ritmo!';

  @override
  String get rewardTaskCleared => '¡Tarea completada!';

  @override
  String get rewardExcellent => '¡Excelente!';

  @override
  String get search => 'Buscar';

  @override
  String get previousMatch => 'Coincidencia anterior';

  @override
  String get nextMatch => 'Coincidencia siguiente';

  @override
  String get closeSearch => 'Cerrar búsqueda';

  @override
  String get typeToSearch => 'Escribe para buscar';

  @override
  String get noSearchMatches => 'Sin coincidencias';

  @override
  String get longTitleMode => 'Modo de títulos largos';

  @override
  String get wrapSelected => 'Ajustar seleccionado';

  @override
  String get wrapAll => 'Ajustar todos';

  @override
  String get marquee => 'Marquesina';

  @override
  String get shortDuration => 'Corta';

  @override
  String get mediumDuration => 'Media';

  @override
  String get longDuration => 'Larga';

  @override
  String get backgroundImage => 'Imagen de fondo';

  @override
  String get backgroundOpacity => 'Opacidad del color de fondo';

  @override
  String get backgroundFit => 'Ajuste de imagen';

  @override
  String get cover => 'Cubrir';

  @override
  String get contain => 'Contener';

  @override
  String get noImageSelected => 'Sin imagen seleccionada';

  @override
  String get none => 'Ninguna';

  @override
  String get clear => 'Quitar';

  @override
  String get languageName => 'Español (España)';
}
