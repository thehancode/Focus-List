use std::{
    io::{self, Write},
    path::PathBuf,
    time::{Duration, Instant},
};

use anyhow::Result;
use ratatui::crossterm::event::{KeyCode, KeyEvent, KeyModifiers};
use uuid::Uuid;

use crate::{
    model::{AppConfig, Status, Task, TaskList, MAX_MARQUEE_SPEED_MS, MIN_MARQUEE_SPEED_MS},
    storage::{ConfigStore, TaskStore},
};

const CHORD_TIMEOUT: Duration = Duration::from_millis(750);
pub const ANIMATION_DURATION: Duration = Duration::from_millis(220);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ViewMode {
    Kanban,
    List,
    Completed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PromptKind {
    AddTask,
    EditTask,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Overlay {
    None,
    Help,
    Prompt { kind: PromptKind, input: String },
    ConfirmDelete,
    Settings { selected: usize },
}

#[derive(Debug, Clone)]
pub struct Animation {
    pub task_id: Uuid,
    pub from: Status,
    pub to: Status,
    pub started: Instant,
}

#[derive(Debug, Clone)]
pub struct Notice {
    pub text: String,
    pub error: bool,
    expires: Instant,
}

pub struct App {
    pub store: TaskStore,
    pub config_store: ConfigStore,
    pub config: AppConfig,
    pub lists: Vec<TaskList>,
    pub current: usize,
    pub selected_task: Option<Uuid>,
    pub view: ViewMode,
    pub overlay: Overlay,
    pub bell_enabled: bool,
    pub chord_started: Option<Instant>,
    pub animation: Option<Animation>,
    pub notice: Option<Notice>,
    pub should_quit: bool,
    pub started: Instant,
}

impl App {
    pub fn load(root: PathBuf) -> Result<Self> {
        let store = TaskStore::new(root);
        let loaded = store.load()?;
        let config_store = ConfigStore::new(store.root());
        let config = config_store.load()?;
        let mut lists = loaded.lists;
        store.ensure_task_list(&mut lists)?;
        let notice = loaded.warnings.first().map(|warning| Notice {
            text: if loaded.warnings.len() == 1 {
                warning.clone()
            } else {
                format!(
                    "{} (and {} more file errors)",
                    warning,
                    loaded.warnings.len() - 1
                )
            },
            error: true,
            expires: Instant::now() + Duration::from_secs(8),
        });
        let mut app = Self {
            store,
            config_store,
            config,
            lists,
            current: 0,
            selected_task: None,
            view: ViewMode::List,
            overlay: Overlay::None,
            bell_enabled: true,
            chord_started: None,
            animation: None,
            notice,
            should_quit: false,
            started: Instant::now(),
        };
        app.select_first();
        Ok(app)
    }

    pub fn current_list(&self) -> &TaskList {
        &self.lists[self.current]
    }

    pub fn current_list_mut(&mut self) -> &mut TaskList {
        &mut self.lists[self.current]
    }

    pub fn tick(&mut self, now: Instant) {
        if self
            .chord_started
            .is_some_and(|start| now.duration_since(start) > CHORD_TIMEOUT)
        {
            self.chord_started = None;
        }
        if self
            .animation
            .as_ref()
            .is_some_and(|animation| now.duration_since(animation.started) > ANIMATION_DURATION)
        {
            self.animation = None;
        }
        if self
            .notice
            .as_ref()
            .is_some_and(|notice| now > notice.expires)
        {
            self.notice = None;
        }
    }

    pub fn handle_key(&mut self, key: KeyEvent, now: Instant) {
        match self.overlay.clone() {
            Overlay::Prompt { kind, input } => {
                self.handle_prompt(key, kind, input);
                return;
            }
            Overlay::Help => {
                if matches!(
                    key.code,
                    KeyCode::Esc | KeyCode::Char('?') | KeyCode::Char('q')
                ) {
                    self.overlay = Overlay::None;
                }
                return;
            }
            Overlay::ConfirmDelete => {
                match key.code {
                    KeyCode::Char('y') | KeyCode::Char('Y') => self.delete_selected(),
                    KeyCode::Esc | KeyCode::Char('n') | KeyCode::Char('N') => {
                        self.overlay = Overlay::None
                    }
                    _ => {}
                }
                return;
            }
            Overlay::Settings { selected } => {
                self.handle_settings(key, selected);
                return;
            }
            Overlay::None => {}
        }

        if let Some(start) = self.chord_started.take()
            && now.duration_since(start) <= CHORD_TIMEOUT
            && matches!(key.code, KeyCode::Char('f') | KeyCode::Char('F'))
        {
            self.advance_status(now);
            return;
        }

        match key.code {
            KeyCode::Char('q') => self.should_quit = true,
            KeyCode::Char('?') => self.overlay = Overlay::Help,
            KeyCode::Char('g') => self.overlay = Overlay::Settings { selected: 0 },
            KeyCode::Char('c') => {
                self.view = match self.view {
                    ViewMode::Kanban => ViewMode::List,
                    ViewMode::List => ViewMode::Completed,
                    ViewMode::Completed => ViewMode::Kanban,
                };
                self.select_first();
            }
            KeyCode::Char('s') => {
                self.bell_enabled = !self.bell_enabled;
                self.set_notice(
                    format!("Sound {}", if self.bell_enabled { "on" } else { "off" }),
                    false,
                );
            }
            KeyCode::Char('n') => {
                self.overlay = Overlay::Prompt {
                    kind: PromptKind::AddTask,
                    input: String::new(),
                }
            }
            KeyCode::Char('d') if self.selected_task.is_some() => {
                let input = self
                    .selected()
                    .map(|task| task.title.clone())
                    .unwrap_or_default();
                self.overlay = Overlay::Prompt {
                    kind: PromptKind::AddTask,
                    input,
                };
            }
            KeyCode::Char('e') if self.selected_task.is_some() => {
                let input = self
                    .selected()
                    .map(|task| task.title.clone())
                    .unwrap_or_default();
                self.overlay = Overlay::Prompt {
                    kind: PromptKind::EditTask,
                    input,
                };
            }
            KeyCode::Char('x') if self.selected_task.is_some() => {
                self.overlay = Overlay::ConfirmDelete
            }
            KeyCode::Char('r') if self.selected_task.is_some() => self.revert_completed(now),
            KeyCode::Char(' ') => self.chord_started = Some(now),
            KeyCode::Up | KeyCode::Char('k') => self.move_vertical(-1),
            KeyCode::Down | KeyCode::Char('j') => self.move_vertical(1),
            KeyCode::Left | KeyCode::Char('h') if self.view == ViewMode::Kanban => {
                self.move_column(-1)
            }
            KeyCode::Right | KeyCode::Char('l') if self.view == ViewMode::Kanban => {
                self.move_column(1)
            }
            _ => {}
        }
    }

    fn handle_prompt(&mut self, key: KeyEvent, kind: PromptKind, mut input: String) {
        match key.code {
            KeyCode::Esc => self.overlay = Overlay::None,
            KeyCode::Enter if key.modifiers.contains(KeyModifiers::SHIFT) => {
                input.push('\n');
                self.overlay = Overlay::Prompt { kind, input };
            }
            KeyCode::Enter => {
                let value = input.trim().to_owned();
                if value.is_empty() {
                    self.set_notice("A name cannot be empty".into(), true);
                    return;
                }
                self.overlay = Overlay::None;
                match kind {
                    PromptKind::AddTask => {
                        let task = Task::new(value);
                        self.selected_task = Some(task.id);
                        self.current_list_mut().tasks.push(task);
                        self.save_current("Task added");
                    }
                    PromptKind::EditTask => {
                        if let Some(id) = self.selected_task
                            && let Some(task) = self
                                .current_list_mut()
                                .tasks
                                .iter_mut()
                                .find(|task| task.id == id)
                        {
                            task.title = value;
                            task.updated_at = chrono::Utc::now();
                            self.save_current("Task updated");
                        }
                    }
                }
            }
            KeyCode::Backspace => {
                input.pop();
                self.overlay = Overlay::Prompt { kind, input };
            }
            KeyCode::Char(character) if !key.modifiers.contains(KeyModifiers::CONTROL) => {
                input.push(character);
                self.overlay = Overlay::Prompt { kind, input };
            }
            _ => {}
        }
    }

    fn handle_settings(&mut self, key: KeyEvent, selected: usize) {
        match key.code {
            KeyCode::Esc | KeyCode::Char('g') | KeyCode::Char('q') => self.overlay = Overlay::None,
            KeyCode::Up | KeyCode::Char('k') => self.overlay = Overlay::Settings {
                selected: selected.saturating_sub(1),
            },
            KeyCode::Down | KeyCode::Char('j') => self.overlay = Overlay::Settings {
                selected: selected.min(0),
            },
            KeyCode::Left | KeyCode::Char('h') => self.adjust_marquee_speed(-25),
            KeyCode::Right | KeyCode::Char('l') => self.adjust_marquee_speed(25),
            _ => {}
        }
    }

    fn adjust_marquee_speed(&mut self, delta: i64) {
        let speed = (self.config.marquee_speed_ms as i64 + delta)
            .clamp(MIN_MARQUEE_SPEED_MS as i64, MAX_MARQUEE_SPEED_MS as i64)
            as u64;
        if speed == self.config.marquee_speed_ms {
            return;
        }
        self.config.marquee_speed_ms = speed;
        match self.config_store.save(&self.config) {
            Ok(()) => self.set_notice(format!("Marquee speed: {speed} ms"), false),
            Err(error) => self.set_notice(format!("Settings save failed: {error:#}"), true),
        }
    }

    fn advance_status(&mut self, now: Instant) {
        let Some(id) = self.selected_task else { return };
        let Some(task) = self
            .current_list_mut()
            .tasks
            .iter_mut()
            .find(|task| task.id == id)
        else {
            return;
        };
        let from = task.status;
        let to = from.next();
        task.status = to;
        task.updated_at = chrono::Utc::now();
        task.completed_at = (to == Status::Done).then_some(task.updated_at);
        self.animation = Some(Animation {
            task_id: id,
            from,
            to,
            started: now,
        });
        self.save_current(&format!("{} → {}", from.label(), to.label()));
        if self.bell_enabled {
            let _ = emit_bell(&mut io::stdout());
        }
    }

    fn revert_completed(&mut self, now: Instant) {
        let Some(id) = self.selected_task else { return };
        let Some(task) = self
            .current_list_mut()
            .tasks
            .iter_mut()
            .find(|task| task.id == id && task.status == Status::Done)
        else {
            return;
        };
        task.status = Status::Doing;
        task.completed_at = None;
        task.updated_at = chrono::Utc::now();
        self.animation = Some(Animation {
            task_id: id,
            from: Status::Done,
            to: Status::Doing,
            started: now,
        });
        self.save_current("Done → Doing");
        if self.bell_enabled {
            let _ = emit_bell(&mut io::stdout());
        }
    }

    fn delete_selected(&mut self) {
        let Some(id) = self.selected_task else { return };
        self.current_list_mut().tasks.retain(|task| task.id != id);
        self.overlay = Overlay::None;
        self.select_first();
        self.save_current("Task deleted");
    }

    fn save_current(&mut self, success: &str) {
        match self.store.save(self.current_list()) {
            Ok(()) => self.set_notice(success.into(), false),
            Err(error) => self.set_notice(format!("Save failed: {error:#}"), true),
        }
    }

    fn set_notice(&mut self, text: String, error: bool) {
        self.notice = Some(Notice {
            text,
            error,
            expires: Instant::now() + Duration::from_secs(if error { 6 } else { 2 }),
        });
    }

    fn selected(&self) -> Option<&Task> {
        let id = self.selected_task?;
        self.current_list().tasks.iter().find(|task| task.id == id)
    }

    fn select_first(&mut self) {
        self.selected_task = self.visible_task_ids().first().copied();
    }

    pub fn visible_task_ids(&self) -> Vec<Uuid> {
        match self.view {
            ViewMode::Kanban => Status::ALL
                .into_iter()
                .flat_map(|status| self.tasks_for_status(status).map(|task| task.id))
                .collect(),
            ViewMode::List => Status::LIST_ORDER
                .into_iter()
                .flat_map(|status| self.tasks_for_status(status).map(|task| task.id))
                .collect(),
            ViewMode::Completed => self
                .completed_tasks()
                .into_iter()
                .map(|task| task.id)
                .collect(),
        }
    }

    pub fn completed_tasks(&self) -> Vec<&Task> {
        let mut tasks: Vec<&Task> = self
            .current_list()
            .tasks
            .iter()
            .filter(|task| task.status == Status::Done)
            .collect();
        tasks.sort_by_key(|task| std::cmp::Reverse(task.completed_at.unwrap_or(task.updated_at)));
        tasks
    }

    fn tasks_for_status(&self, status: Status) -> impl Iterator<Item = &Task> {
        self.current_list()
            .tasks
            .iter()
            .filter(move |task| task.status == status)
    }

    fn move_vertical(&mut self, delta: isize) {
        let ids: Vec<Uuid> = if self.view == ViewMode::Kanban {
            let status = self
                .selected()
                .map(|task| task.status)
                .unwrap_or(Status::Pending);
            self.tasks_for_status(status).map(|task| task.id).collect()
        } else {
            self.visible_task_ids()
        };
        if ids.is_empty() {
            return;
        }
        let position = self
            .selected_task
            .and_then(|id| ids.iter().position(|candidate| *candidate == id))
            .unwrap_or(0);
        self.selected_task = Some(ids[move_index(position, delta, ids.len())]);
    }

    fn move_column(&mut self, delta: isize) {
        if delta == 0 {
            return;
        }
        let current_status = self
            .selected()
            .map(|task| task.status)
            .unwrap_or(Status::Pending);
        let current_column = Status::ALL
            .iter()
            .position(|status| *status == current_status)
            .unwrap();
        let row = self
            .tasks_for_status(current_status)
            .position(|task| Some(task.id) == self.selected_task)
            .unwrap_or(0);

        // Keep moving in the requested direction until a populated column is
        // found. This lets navigation cross an empty Doing (or Pending) column.
        let direction = delta.signum();
        let mut target_column = current_column as isize + direction;
        while (0..Status::ALL.len() as isize).contains(&target_column) {
            let target: Vec<Uuid> = self
                .tasks_for_status(Status::ALL[target_column as usize])
                .map(|task| task.id)
                .collect();
            if let Some(id) = target.get(row.min(target.len().saturating_sub(1))) {
                self.selected_task = Some(*id);
                return;
            }
            target_column += direction;
        }
    }
}

fn move_index(index: usize, delta: isize, length: usize) -> usize {
    (index as isize + delta).clamp(0, length.saturating_sub(1) as isize) as usize
}

fn emit_bell(writer: &mut impl Write) -> io::Result<()> {
    writer.write_all(b"\x07")?;
    writer.flush()
}

#[cfg(test)]
mod tests {
    use ratatui::crossterm::event::KeyEvent;
    use tempfile::tempdir;

    use super::*;

    fn app() -> App {
        let directory = tempdir().unwrap().keep();
        App::load(directory).unwrap()
    }

    #[test]
    fn space_f_advances_and_keeps_selection() {
        let mut app = app();
        app.current_list_mut().tasks.push(Task::new("One"));
        app.select_first();
        app.bell_enabled = false;
        let id = app.selected_task.unwrap();
        let now = Instant::now();
        app.handle_key(KeyEvent::new(KeyCode::Char(' '), KeyModifiers::NONE), now);
        app.handle_key(
            KeyEvent::new(KeyCode::Char('f'), KeyModifiers::NONE),
            now + Duration::from_millis(10),
        );
        assert_eq!(app.selected_task, Some(id));
        assert_eq!(app.selected().unwrap().status, Status::Doing);
    }

    #[test]
    fn completing_a_task_records_and_clears_completion_time() {
        let mut app = app();
        app.current_list_mut().tasks.push(Task::new("One"));
        app.select_first();
        app.bell_enabled = false;
        let now = Instant::now();

        for offset in [0, 10] {
            app.handle_key(
                KeyEvent::new(KeyCode::Char(' '), KeyModifiers::NONE),
                now + Duration::from_millis(offset),
            );
            app.handle_key(
                KeyEvent::new(KeyCode::Char('f'), KeyModifiers::NONE),
                now + Duration::from_millis(offset + 1),
            );
        }
        assert_eq!(app.selected().unwrap().status, Status::Done);
        assert!(app.selected().unwrap().completed_at.is_some());

        app.handle_key(
            KeyEvent::new(KeyCode::Char(' '), KeyModifiers::NONE),
            now + Duration::from_millis(20),
        );
        app.handle_key(
            KeyEvent::new(KeyCode::Char('f'), KeyModifiers::NONE),
            now + Duration::from_millis(21),
        );
        assert_eq!(app.selected().unwrap().status, Status::Pending);
        assert!(app.selected().unwrap().completed_at.is_none());
    }

    #[test]
    fn expired_chord_does_not_change_status() {
        let mut app = app();
        app.current_list_mut().tasks.push(Task::new("One"));
        app.select_first();
        let now = Instant::now();
        app.handle_key(KeyEvent::new(KeyCode::Char(' '), KeyModifiers::NONE), now);
        app.handle_key(
            KeyEvent::new(KeyCode::Char('f'), KeyModifiers::NONE),
            now + Duration::from_secs(1),
        );
        assert_eq!(app.selected().unwrap().status, Status::Pending);
    }

    #[test]
    fn duplicate_opens_a_prefilled_new_task_prompt() {
        let mut app = app();
        app.current_list_mut().tasks.push(Task::new("Copy this"));
        app.select_first();
        app.handle_key(
            KeyEvent::new(KeyCode::Char('d'), KeyModifiers::NONE),
            Instant::now(),
        );
        assert_eq!(
            app.overlay,
            Overlay::Prompt {
                kind: PromptKind::AddTask,
                input: "Copy this".into(),
            }
        );
    }

    #[test]
    fn revert_moves_a_completed_task_back_to_doing() {
        let mut app = app();
        let mut task = Task::new("Reopen me");
        task.status = Status::Done;
        task.completed_at = Some(task.updated_at);
        app.current_list_mut().tasks.push(task);
        app.select_first();
        app.bell_enabled = false;
        app.handle_key(
            KeyEvent::new(KeyCode::Char('r'), KeyModifiers::NONE),
            Instant::now(),
        );
        assert_eq!(app.selected().unwrap().status, Status::Doing);
        assert!(app.selected().unwrap().completed_at.is_none());
    }

    #[test]
    fn c_cycles_views_and_v_has_no_view_action() {
        let mut app = app();
        let now = Instant::now();

        app.handle_key(KeyEvent::new(KeyCode::Char('c'), KeyModifiers::NONE), now);
        assert_eq!(app.view, ViewMode::Completed);
        app.handle_key(
            KeyEvent::new(KeyCode::Char('c'), KeyModifiers::NONE),
            now + Duration::from_millis(1),
        );
        assert_eq!(app.view, ViewMode::Kanban);
        app.handle_key(
            KeyEvent::new(KeyCode::Char('c'), KeyModifiers::NONE),
            now + Duration::from_millis(2),
        );
        assert_eq!(app.view, ViewMode::List);

        app.handle_key(
            KeyEvent::new(KeyCode::Char('v'), KeyModifiers::NONE),
            now + Duration::from_millis(3),
        );
        assert_eq!(app.view, ViewMode::List);
    }

    #[test]
    fn settings_menu_updates_and_persists_marquee_speed() {
        let mut app = app();
        let now = Instant::now();
        let initial_speed = app.config.marquee_speed_ms;

        app.handle_key(KeyEvent::new(KeyCode::Char('g'), KeyModifiers::NONE), now);
        assert_eq!(app.overlay, Overlay::Settings { selected: 0 });
        app.handle_key(
            KeyEvent::new(KeyCode::Char('h'), KeyModifiers::NONE),
            now + Duration::from_millis(1),
        );
        assert_eq!(app.config.marquee_speed_ms, initial_speed - 25);
        assert_eq!(app.config_store.load().unwrap().marquee_speed_ms, initial_speed - 25);
    }

    #[test]
    fn kanban_navigation_skips_an_empty_middle_column() {
        let mut app = app();
        let pending = Task::new("Pending");
        let pending_id = pending.id;
        let mut done = Task::new("Done");
        done.status = Status::Done;
        done.completed_at = Some(done.updated_at);
        let done_id = done.id;
        app.current_list_mut().tasks.extend([pending, done]);
        app.selected_task = Some(done_id);

        app.move_column(-1);
        assert_eq!(app.selected_task, Some(pending_id));
        app.move_column(1);
        assert_eq!(app.selected_task, Some(done_id));
    }

    #[test]
    fn kanban_navigation_stays_put_when_no_other_column_has_tasks() {
        let mut app = app();
        let mut done = Task::new("Only task");
        done.status = Status::Done;
        let id = done.id;
        app.current_list_mut().tasks.push(done);
        app.selected_task = Some(id);

        app.move_column(-1);
        assert_eq!(app.selected_task, Some(id));
        app.move_column(1);
        assert_eq!(app.selected_task, Some(id));
    }

    #[test]
    fn bell_writes_ascii_bel() {
        let mut output = Vec::new();
        emit_bell(&mut output).unwrap();
        assert_eq!(output, b"\x07");
    }
}
