use std::{
    io::{self, Write},
    path::PathBuf,
    time::{Duration, Instant},
};

use anyhow::Result;
use ratatui::crossterm::event::{KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use uuid::Uuid;

use crate::{
    model::{
        AppConfig, MAX_MARQUEE_SPEED_MS, MAX_NATIVE_FONT_SIZE, MIN_MARQUEE_SPEED_MS,
        MIN_NATIVE_FONT_SIZE, Status, Task, TaskList,
    },
    storage::{ConfigStore, TaskStore},
};

const CHORD_TIMEOUT: Duration = Duration::from_millis(750);
pub const ANIMATION_DURATION: Duration = Duration::from_millis(220);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ViewMode {
    List,
    Focus,
    Completed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PromptKind {
    AddTask,
    EditTask,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ListPromptKind {
    Add,
    Rename,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Overlay {
    None,
    Help,
    Prompt {
        kind: PromptKind,
        input: String,
        cursor: usize,
        daily: bool,
    },
    ConfirmDelete,
    ListPrompt {
        kind: ListPromptKind,
        input: String,
        cursor: usize,
    },
    ConfirmDeleteList,
    Settings {
        selected: usize,
    },
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
    terminal_bell_enabled: bool,
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
            terminal_bell_enabled: true,
            chord_started: None,
            animation: None,
            notice,
            should_quit: false,
            started: Instant::now(),
        };
        app.select_first();
        Ok(app)
    }

    /// Prevents the terminal-only ASCII bell from being written by a non-TUI
    /// frontend. The user-facing sound preference remains intact for a future
    /// native audio implementation.
    pub fn disable_terminal_bell(&mut self) {
        self.terminal_bell_enabled = false;
    }

    pub fn current_list(&self) -> &TaskList {
        &self.lists[self.current]
    }

    pub fn current_list_mut(&mut self) -> &mut TaskList {
        &mut self.lists[self.current]
    }

    pub fn tick(&mut self, now: Instant) {
        if self.reset_daily_tasks() {
            self.save_current("Daily tasks reset");
            self.select_first();
        }
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
        if key.kind == KeyEventKind::Release {
            if key.code == KeyCode::Char(' ') {
                self.chord_started = None;
            }
            return;
        }

        match self.overlay.clone() {
            Overlay::Prompt {
                kind,
                input,
                cursor,
                daily,
            } => {
                self.handle_prompt(key, kind, input, cursor, daily);
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
            Overlay::ListPrompt {
                kind,
                input,
                cursor,
            } => {
                self.handle_list_prompt(key, kind, input, cursor);
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
            Overlay::ConfirmDeleteList => {
                match key.code {
                    KeyCode::Char('y') | KeyCode::Char('Y') => self.delete_current_list(),
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

        if key.modifiers.contains(KeyModifiers::CONTROL) {
            match key.code {
                KeyCode::Char('c') | KeyCode::Char('C') => self.should_quit = true,
                KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Char('\u{0e}') => {
                    self.open_add_list()
                }
                KeyCode::Char('r') | KeyCode::Char('R') | KeyCode::Char('\u{12}') => {
                    self.open_rename_list()
                }
                KeyCode::Char('x') | KeyCode::Char('X') | KeyCode::Char('\u{18}') => {
                    self.confirm_delete_current_list()
                }
                _ => {}
            }
            return;
        }

        // Some terminals encode Ctrl+letter directly as an ASCII control
        // character instead of retaining the CONTROL modifier.
        match key.code {
            KeyCode::Char('\u{18}') => {
                self.confirm_delete_current_list();
                return;
            }
            KeyCode::Char('\u{12}') => {
                self.open_rename_list();
                return;
            }
            KeyCode::Char('\u{0e}') => {
                self.open_add_list();
                return;
            }
            _ => {}
        }

        match key.code {
            KeyCode::F(2) => {
                self.open_rename_list();
                return;
            }
            KeyCode::BackTab => {
                self.switch_list(-1);
                return;
            }
            KeyCode::Tab => {
                self.switch_list(if key.modifiers.contains(KeyModifiers::SHIFT) {
                    -1
                } else {
                    1
                });
                return;
            }
            _ => {}
        }

        if key.code == KeyCode::Char(' ') {
            self.chord_started = Some(now);
            return;
        }

        if let Some(start) = self.chord_started
            && now.duration_since(start) <= CHORD_TIMEOUT
        {
            match key.code {
                KeyCode::Char('f') | KeyCode::Char('F') => {
                    self.chord_started = None;
                    self.advance_status(now);
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    self.reorder_selected(-1);
                    self.chord_started = Some(now);
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    self.reorder_selected(1);
                    self.chord_started = Some(now);
                }
                _ => self.chord_started = None,
            }
            return;
        }

        match key.code {
            KeyCode::Char('q') => self.should_quit = true,
            KeyCode::Char('?') => self.overlay = Overlay::Help,
            KeyCode::Char('g') => self.overlay = Overlay::Settings { selected: 0 },
            KeyCode::Char('c') => {
                self.view = if self.view == ViewMode::Focus {
                    ViewMode::List
                } else if self.tasks_for_status(Status::Doing).next().is_some() {
                    ViewMode::Focus
                } else {
                    self.set_notice("No Doing tasks to focus".into(), false);
                    return;
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
            KeyCode::Char('v') => {
                self.view = if self.view == ViewMode::Completed {
                    ViewMode::List
                } else {
                    ViewMode::Completed
                };
                self.select_first();
            }
            KeyCode::Char('n') => {
                self.overlay = Overlay::Prompt {
                    kind: PromptKind::AddTask,
                    input: String::new(),
                    cursor: 0,
                    daily: false,
                }
            }
            KeyCode::Char('d') if self.selected_task.is_some() => {
                let input = self
                    .selected()
                    .map(|task| task.title.clone())
                    .unwrap_or_default();
                let daily = self.selected().is_some_and(|task| task.daily);
                self.overlay = Overlay::Prompt {
                    kind: PromptKind::AddTask,
                    cursor: input.len(),
                    input,
                    daily,
                };
            }
            KeyCode::Char('e') if self.selected_task.is_some() => {
                let input = self
                    .selected()
                    .map(|task| task.title.clone())
                    .unwrap_or_default();
                let daily = self.selected().is_some_and(|task| task.daily);
                self.overlay = Overlay::Prompt {
                    kind: PromptKind::EditTask,
                    cursor: input.len(),
                    input,
                    daily,
                };
            }
            KeyCode::Char('x') if self.selected_task.is_some() => {
                self.overlay = Overlay::ConfirmDelete
            }
            KeyCode::Char('r') if self.selected_task.is_some() => self.revert_completed(now),
            KeyCode::Up | KeyCode::Char('k') => self.move_vertical(-1),
            KeyCode::Down | KeyCode::Char('j') => self.move_vertical(1),
            _ => {}
        }
    }

    fn handle_prompt(
        &mut self,
        key: KeyEvent,
        kind: PromptKind,
        mut input: String,
        mut cursor: usize,
        daily: bool,
    ) {
        match key.code {
            KeyCode::Esc => self.overlay = Overlay::None,
            KeyCode::Enter => self.save_prompt(kind, input, daily),
            KeyCode::Tab => {
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily: !daily,
                }
            }
            KeyCode::Backspace => {
                if let Some(start) = previous_char_boundary(&input, cursor) {
                    input.drain(start..cursor);
                    cursor = start;
                }
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily,
                };
            }
            KeyCode::Delete => {
                if let Some(end) = next_char_boundary(&input, cursor) {
                    input.drain(cursor..end);
                }
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily,
                };
            }
            KeyCode::Left => {
                cursor = previous_char_boundary(&input, cursor).unwrap_or(cursor);
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily,
                };
            }
            KeyCode::Right => {
                cursor = next_char_boundary(&input, cursor).unwrap_or(cursor);
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily,
                };
            }
            KeyCode::Home => {
                cursor = line_start(&input, cursor);
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily,
                };
            }
            KeyCode::End => {
                cursor = line_end(&input, cursor);
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily,
                };
            }
            KeyCode::Up => {
                cursor = move_cursor_line(&input, cursor, -1);
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily,
                };
            }
            KeyCode::Down => {
                cursor = move_cursor_line(&input, cursor, 1);
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily,
                };
            }
            KeyCode::Char(character) if !key.modifiers.contains(KeyModifiers::CONTROL) => {
                input.insert(cursor, character);
                cursor += character.len_utf8();
                self.overlay = Overlay::Prompt {
                    kind,
                    input,
                    cursor,
                    daily,
                };
            }
            _ => {}
        }
    }

    fn handle_list_prompt(
        &mut self,
        key: KeyEvent,
        kind: ListPromptKind,
        mut input: String,
        mut cursor: usize,
    ) {
        match key.code {
            KeyCode::Esc => self.overlay = Overlay::None,
            KeyCode::Enter => self.save_list_prompt(kind, input),
            KeyCode::Backspace => {
                if let Some(start) = previous_char_boundary(&input, cursor) {
                    input.drain(start..cursor);
                    cursor = start;
                }
                self.overlay = Overlay::ListPrompt {
                    kind,
                    input,
                    cursor,
                };
            }
            KeyCode::Delete => {
                if let Some(end) = next_char_boundary(&input, cursor) {
                    input.drain(cursor..end);
                }
                self.overlay = Overlay::ListPrompt {
                    kind,
                    input,
                    cursor,
                };
            }
            KeyCode::Left => {
                cursor = previous_char_boundary(&input, cursor).unwrap_or(cursor);
                self.overlay = Overlay::ListPrompt {
                    kind,
                    input,
                    cursor,
                };
            }
            KeyCode::Right => {
                cursor = next_char_boundary(&input, cursor).unwrap_or(cursor);
                self.overlay = Overlay::ListPrompt {
                    kind,
                    input,
                    cursor,
                };
            }
            KeyCode::Home | KeyCode::Up => {
                cursor = 0;
                self.overlay = Overlay::ListPrompt {
                    kind,
                    input,
                    cursor,
                };
            }
            KeyCode::End | KeyCode::Down => {
                cursor = input.len();
                self.overlay = Overlay::ListPrompt {
                    kind,
                    input,
                    cursor,
                };
            }
            KeyCode::Char(character) if !key.modifiers.contains(KeyModifiers::CONTROL) => {
                input.insert(cursor, character);
                cursor += character.len_utf8();
                self.overlay = Overlay::ListPrompt {
                    kind,
                    input,
                    cursor,
                };
            }
            _ => {}
        }
    }

    fn save_list_prompt(&mut self, kind: ListPromptKind, input: String) {
        let name = normalize_name(&input);
        if name.is_empty() {
            self.set_notice("A list name cannot be empty".into(), true);
            return;
        }
        let duplicate = self.lists.iter().enumerate().any(|(index, list)| {
            (kind == ListPromptKind::Add || index != self.current)
                && list.name.eq_ignore_ascii_case(&name)
        });
        if duplicate {
            self.set_notice("A list with that name already exists".into(), true);
            return;
        }
        match kind {
            ListPromptKind::Add => {
                let list = TaskList::named(name);
                match self.store.save(&list) {
                    Ok(()) => {
                        self.lists.push(list);
                        self.current = self.lists.len() - 1;
                        self.overlay = Overlay::None;
                        self.reset_after_list_switch();
                        self.set_notice("List created".into(), false);
                    }
                    Err(error) => self.set_notice(format!("List save failed: {error:#}"), true),
                }
            }
            ListPromptKind::Rename => {
                let old_name = std::mem::replace(&mut self.lists[self.current].name, name);
                match self.store.save(self.current_list()) {
                    Ok(()) => {
                        self.overlay = Overlay::None;
                        self.set_notice("List renamed".into(), false);
                    }
                    Err(error) => {
                        self.lists[self.current].name = old_name;
                        self.set_notice(format!("List save failed: {error:#}"), true);
                    }
                }
            }
        }
    }

    fn open_add_list(&mut self) {
        self.overlay = Overlay::ListPrompt {
            kind: ListPromptKind::Add,
            input: String::new(),
            cursor: 0,
        };
    }

    fn open_rename_list(&mut self) {
        let input = self.current_list().name.clone();
        self.overlay = Overlay::ListPrompt {
            kind: ListPromptKind::Rename,
            cursor: input.len(),
            input,
        };
    }

    fn confirm_delete_current_list(&mut self) {
        if self.lists.len() == 1 {
            self.set_notice("The last list cannot be deleted".into(), true);
        } else {
            self.overlay = Overlay::ConfirmDeleteList;
        }
    }

    fn delete_current_list(&mut self) {
        let id = self.current_list().id;
        match self.store.delete(id) {
            Ok(()) => {
                self.lists.remove(self.current);
                self.current = self.current.min(self.lists.len() - 1);
                self.overlay = Overlay::None;
                self.reset_after_list_switch();
                self.set_notice("List deleted".into(), false);
            }
            Err(error) => self.set_notice(format!("List delete failed: {error:#}"), true),
        }
    }

    fn switch_list(&mut self, direction: isize) {
        if self.lists.len() < 2 {
            return;
        }
        self.current = if direction < 0 {
            self.current.checked_sub(1).unwrap_or(self.lists.len() - 1)
        } else {
            (self.current + 1) % self.lists.len()
        };
        self.reset_after_list_switch();
    }

    pub fn select_list(&mut self, index: usize) {
        if index >= self.lists.len() || index == self.current {
            return;
        }
        self.current = index;
        self.reset_after_list_switch();
    }

    fn reset_after_list_switch(&mut self) {
        self.view = ViewMode::List;
        self.chord_started = None;
        self.animation = None;
        self.select_first();
    }

    fn save_prompt(&mut self, kind: PromptKind, input: String, daily: bool) {
        let value = input.split_whitespace().collect::<Vec<_>>().join(" ");
        if value.is_empty() {
            self.set_notice("A name cannot be empty".into(), true);
            return;
        }
        self.overlay = Overlay::None;
        match kind {
            PromptKind::AddTask => {
                let mut task = Task::new(value);
                task.daily = daily;
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
                    task.daily = daily;
                    task.updated_at = chrono::Utc::now();
                    self.save_current("Task updated");
                }
            }
        }
    }

    fn handle_settings(&mut self, key: KeyEvent, selected: usize) {
        match key.code {
            KeyCode::Esc | KeyCode::Char('g') | KeyCode::Char('q') => self.overlay = Overlay::None,
            KeyCode::Up | KeyCode::Char('k') => {
                self.overlay = Overlay::Settings {
                    selected: selected.saturating_sub(1),
                }
            }
            KeyCode::Down | KeyCode::Char('j') => {
                self.overlay = Overlay::Settings {
                    selected: (selected + 1).min(2),
                }
            }
            KeyCode::Left | KeyCode::Char('h') => match selected {
                0 => self.adjust_marquee_speed(-25),
                1 => self.toggle_long_title_display(),
                2 => self.adjust_native_font_size(-1),
                _ => {}
            },
            KeyCode::Right | KeyCode::Char('l') => match selected {
                0 => self.adjust_marquee_speed(25),
                1 => self.toggle_long_title_display(),
                2 => self.adjust_native_font_size(1),
                _ => {}
            },
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

    fn toggle_long_title_display(&mut self) {
        self.config.long_title_display = self.config.long_title_display.toggle();
        match self.config_store.save(&self.config) {
            Ok(()) => self.set_notice(
                format!("Long titles: {}", self.config.long_title_display.label()),
                false,
            ),
            Err(error) => self.set_notice(format!("Settings save failed: {error:#}"), true),
        }
    }

    fn adjust_native_font_size(&mut self, delta: i16) {
        let size = (self.config.native_font_size as i16 + delta)
            .clamp(MIN_NATIVE_FONT_SIZE as i16, MAX_NATIVE_FONT_SIZE as i16)
            as u16;
        if size == self.config.native_font_size {
            return;
        }
        self.config.native_font_size = size;
        match self.config_store.save(&self.config) {
            Ok(()) => self.set_notice(format!("Native font: {size} pt"), false),
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
        if to == Status::Done && task.daily {
            task.completion_history.push(task.updated_at);
        }
        if to == Status::Pending && task.daily {
            let today = chrono::Local::now().date_naive();
            task.completion_history.retain(|completed_at| {
                completed_at.with_timezone(&chrono::Local).date_naive() != today
            });
        }
        if to == Status::Doing {
            self.view = ViewMode::Focus;
        } else if from == Status::Doing
            && to == Status::Done
            && self.tasks_for_status(Status::Doing).next().is_none()
        {
            self.view = ViewMode::List;
        }
        self.animation = Some(Animation {
            task_id: id,
            from,
            to,
            started: now,
        });
        self.save_current(&format!("{} → {}", from.label(), to.label()));
        if self.bell_enabled && self.terminal_bell_enabled {
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
        self.view = ViewMode::Focus;
        self.animation = Some(Animation {
            task_id: id,
            from: Status::Done,
            to: Status::Doing,
            started: now,
        });
        self.save_current("Done → Doing");
        if self.bell_enabled && self.terminal_bell_enabled {
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

    pub fn selected(&self) -> Option<&Task> {
        let id = self.selected_task?;
        self.current_list().tasks.iter().find(|task| task.id == id)
    }

    fn select_first(&mut self) {
        self.selected_task = self.visible_task_ids().first().copied();
    }

    pub fn visible_task_ids(&self) -> Vec<Uuid> {
        match self.view {
            ViewMode::List => Status::LIST_ORDER
                .into_iter()
                .flat_map(|status| self.tasks_for_status(status).map(|task| task.id))
                .collect(),
            ViewMode::Focus => self
                .tasks_for_status(Status::Doing)
                .map(|task| task.id)
                .collect(),
            ViewMode::Completed => self
                .completion_entries()
                .into_iter()
                .map(|(task, _)| task.id)
                .collect(),
        }
    }

    pub fn completion_entries(&self) -> Vec<(&Task, chrono::DateTime<chrono::Utc>)> {
        let mut entries: Vec<_> = self
            .current_list()
            .tasks
            .iter()
            .flat_map(|task| {
                if task.daily {
                    task.completion_history
                        .iter()
                        .copied()
                        .map(move |completed_at| (task, completed_at))
                        .collect::<Vec<_>>()
                } else {
                    task.completed_at
                        .map(|completed_at| vec![(task, completed_at)])
                        .unwrap_or_default()
                }
            })
            .collect();
        entries.sort_by_key(|(_, completed_at)| std::cmp::Reverse(*completed_at));
        entries
    }

    fn tasks_for_status(&self, status: Status) -> impl Iterator<Item = &Task> {
        self.current_list()
            .tasks
            .iter()
            .filter(move |task| task.status == status)
    }

    fn reset_daily_tasks(&mut self) -> bool {
        let today = chrono::Local::now().date_naive();
        let mut changed = false;
        for task in &mut self.current_list_mut().tasks {
            if task.daily
                && task.status != Status::Pending
                && task.updated_at.with_timezone(&chrono::Local).date_naive() < today
            {
                task.status = Status::Pending;
                task.completed_at = None;
                task.updated_at = chrono::Utc::now();
                changed = true;
            }
        }
        changed
    }

    fn reorder_selected(&mut self, direction: isize) {
        if self.view == ViewMode::Completed || direction == 0 {
            return;
        }
        let Some(id) = self.selected_task else { return };
        let Some(status) = self.selected().map(|task| task.status) else {
            return;
        };
        let positions: Vec<usize> = self
            .current_list()
            .tasks
            .iter()
            .enumerate()
            .filter_map(|(index, task)| (task.status == status).then_some(index))
            .collect();
        let Some(current) = positions
            .iter()
            .position(|index| self.current_list().tasks[*index].id == id)
        else {
            return;
        };
        let target = (current as isize + direction).clamp(0, positions.len() as isize - 1) as usize;
        if target == current {
            return;
        }
        self.current_list_mut()
            .tasks
            .swap(positions[current], positions[target]);
        self.save_current("Task reordered");
    }

    fn move_vertical(&mut self, delta: isize) {
        let ids = self.visible_task_ids();
        if ids.is_empty() {
            return;
        }
        let position = self
            .selected_task
            .and_then(|id| ids.iter().position(|candidate| *candidate == id))
            .unwrap_or(0);
        self.selected_task = Some(ids[move_index(position, delta, ids.len())]);
    }
}

fn move_index(index: usize, delta: isize, length: usize) -> usize {
    (index as isize + delta).clamp(0, length.saturating_sub(1) as isize) as usize
}

fn normalize_name(value: &str) -> String {
    value.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn previous_char_boundary(value: &str, cursor: usize) -> Option<usize> {
    value[..cursor]
        .char_indices()
        .next_back()
        .map(|(index, _)| index)
}

fn next_char_boundary(value: &str, cursor: usize) -> Option<usize> {
    value[cursor..]
        .chars()
        .next()
        .map(|character| cursor + character.len_utf8())
}

fn line_start(value: &str, cursor: usize) -> usize {
    value[..cursor].rfind('\n').map_or(0, |index| index + 1)
}

fn line_end(value: &str, cursor: usize) -> usize {
    value[cursor..]
        .find('\n')
        .map_or(value.len(), |index| cursor + index)
}

fn move_cursor_line(value: &str, cursor: usize, direction: isize) -> usize {
    let starts: Vec<usize> = std::iter::once(0)
        .chain(value.match_indices('\n').map(|(index, _)| index + 1))
        .collect();
    let current_line = starts
        .iter()
        .rposition(|start| *start <= cursor)
        .unwrap_or(0);
    let target_line =
        (current_line as isize + direction).clamp(0, starts.len() as isize - 1) as usize;
    let column = value[line_start(value, cursor)..cursor].chars().count();
    let target_start = starts[target_line];
    let target_end = line_end(value, target_start);
    let target_offset = value[target_start..target_end]
        .char_indices()
        .nth(column)
        .map_or(target_end, |(index, _)| target_start + index);
    target_offset
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
        assert_eq!(app.view, ViewMode::Focus);
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
        assert_eq!(app.view, ViewMode::List);

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
                cursor: "Copy this".len(),
                daily: false,
            }
        );
    }

    #[test]
    fn prompt_edits_at_the_cursor_and_saves_with_enter() {
        let mut app = app();
        let now = Instant::now();
        app.handle_key(KeyEvent::new(KeyCode::Char('n'), KeyModifiers::NONE), now);
        for (offset, key) in [
            KeyCode::Char('a'),
            KeyCode::Char('c'),
            KeyCode::Left,
            KeyCode::Char('b'),
            KeyCode::Enter,
        ]
        .into_iter()
        .enumerate()
        {
            app.handle_key(
                KeyEvent::new(key, KeyModifiers::NONE),
                now + Duration::from_millis(offset as u64 + 1),
            );
        }
        assert_eq!(app.current_list().tasks[0].title, "abc");
    }

    #[test]
    fn daily_completion_is_retained_and_resets_the_next_day() {
        let mut app = app();
        let mut task = Task::new("Daily standup");
        task.daily = true;
        let id = task.id;
        app.current_list_mut().tasks.push(task);
        app.selected_task = Some(id);
        app.bell_enabled = false;
        let now = Instant::now();
        app.advance_status(now);
        app.advance_status(now + Duration::from_millis(1));
        let task = app.selected().unwrap();
        assert_eq!(task.status, Status::Done);
        assert_eq!(task.completion_history.len(), 1);
        assert_eq!(app.completion_entries().len(), 1);

        app.advance_status(now + Duration::from_millis(2));
        assert_eq!(app.selected().unwrap().status, Status::Pending);
        assert!(app.selected().unwrap().completion_history.is_empty());

        app.advance_status(now + Duration::from_millis(3));
        app.advance_status(now + Duration::from_millis(4));
        assert_eq!(app.selected().unwrap().completion_history.len(), 1);

        let task = app.current_list_mut().tasks.first_mut().unwrap();
        task.updated_at = chrono::Utc::now() - chrono::Duration::days(1);
        app.tick(now + Duration::from_secs(1));
        let task = app.selected().unwrap();
        assert_eq!(task.status, Status::Pending);
        assert_eq!(task.completion_history.len(), 1);
    }

    #[test]
    fn c_toggles_doing_focus_view() {
        let mut app = app();
        let mut task = Task::new("Current work");
        task.status = Status::Doing;
        app.current_list_mut().tasks.push(task);
        let now = Instant::now();
        app.handle_key(KeyEvent::new(KeyCode::Char('c'), KeyModifiers::NONE), now);
        assert_eq!(app.view, ViewMode::Focus);
        app.handle_key(
            KeyEvent::new(KeyCode::Char('c'), KeyModifiers::NONE),
            now + Duration::from_millis(1),
        );
        assert_eq!(app.view, ViewMode::List);
    }

    #[test]
    fn c_keeps_the_list_view_when_no_task_is_doing() {
        let mut app = app();
        app.handle_key(
            KeyEvent::new(KeyCode::Char('c'), KeyModifiers::NONE),
            Instant::now(),
        );
        assert_eq!(app.view, ViewMode::List);
    }

    #[test]
    fn space_arrow_reorders_tasks_with_the_same_status() {
        let mut app = app();
        let first = Task::new("First");
        let first_id = first.id;
        let second = Task::new("Second");
        let second_id = second.id;
        app.current_list_mut().tasks.extend([first, second]);
        app.selected_task = Some(second_id);
        let now = Instant::now();
        app.handle_key(KeyEvent::new(KeyCode::Char(' '), KeyModifiers::NONE), now);
        app.handle_key(
            KeyEvent::new(KeyCode::Up, KeyModifiers::NONE),
            now + Duration::from_millis(1),
        );
        assert_eq!(app.current_list().tasks[0].id, second_id);
        assert_eq!(app.current_list().tasks[1].id, first_id);
        assert_eq!(app.selected_task, Some(second_id));
    }

    #[test]
    fn repeated_space_keeps_reorder_mode_active() {
        let mut app = app();
        let first = Task::new("First");
        let second = Task::new("Second");
        let third = Task::new("Third");
        let third_id = third.id;
        app.current_list_mut().tasks.extend([first, second, third]);
        app.selected_task = Some(third_id);
        let now = Instant::now();

        app.handle_key(KeyEvent::new(KeyCode::Char(' '), KeyModifiers::NONE), now);
        app.handle_key(
            KeyEvent::new(KeyCode::Up, KeyModifiers::NONE),
            now + Duration::from_millis(1),
        );
        // A held Space key generates repeat events; each one refreshes the reorder chord.
        app.handle_key(
            KeyEvent::new(KeyCode::Char(' '), KeyModifiers::NONE),
            now + Duration::from_millis(2),
        );
        app.handle_key(
            KeyEvent::new(KeyCode::Up, KeyModifiers::NONE),
            now + Duration::from_millis(3),
        );

        assert_eq!(app.current_list().tasks[0].id, third_id);
        assert_eq!(app.selected_task, Some(third_id));
    }

    #[test]
    fn each_reorder_refreshes_the_grab_timeout() {
        let mut app = app();
        let tasks: Vec<_> = (1..=5)
            .map(|number| Task::new(format!("Task {number}")))
            .collect();
        let grabbed_id = tasks[4].id;
        app.current_list_mut().tasks.extend(tasks);
        app.selected_task = Some(grabbed_id);
        let now = Instant::now();

        app.handle_key(KeyEvent::new(KeyCode::Char(' '), KeyModifiers::NONE), now);
        for offset in [500, 1_000, 1_500, 2_000] {
            let event_time = now + Duration::from_millis(offset);
            app.tick(event_time);
            app.handle_key(KeyEvent::new(KeyCode::Up, KeyModifiers::NONE), event_time);
        }

        assert_eq!(app.current_list().tasks[0].id, grabbed_id);
        assert_eq!(app.selected_task, Some(grabbed_id));
    }

    #[test]
    fn releasing_space_stops_reordering() {
        let mut app = app();
        let first = Task::new("First");
        let first_id = first.id;
        let second = Task::new("Second");
        let second_id = second.id;
        app.current_list_mut().tasks.extend([first, second]);
        app.selected_task = Some(second_id);
        let now = Instant::now();

        app.handle_key(KeyEvent::new(KeyCode::Char(' '), KeyModifiers::NONE), now);
        app.handle_key(
            KeyEvent::new_with_kind(
                KeyCode::Char(' '),
                KeyModifiers::NONE,
                KeyEventKind::Release,
            ),
            now + Duration::from_millis(1),
        );
        app.handle_key(
            KeyEvent::new(KeyCode::Up, KeyModifiers::NONE),
            now + Duration::from_millis(2),
        );

        assert_eq!(app.current_list().tasks[1].id, second_id);
        assert_eq!(app.selected_task, Some(first_id));
        assert!(app.chord_started.is_none());
    }

    #[test]
    fn control_n_creates_and_activates_a_list() {
        let mut app = app();
        let now = Instant::now();
        app.handle_key(
            KeyEvent::new(KeyCode::Char('n'), KeyModifiers::CONTROL),
            now,
        );
        assert!(matches!(
            app.overlay,
            Overlay::ListPrompt {
                kind: ListPromptKind::Add,
                ..
            }
        ));
        app.save_list_prompt(ListPromptKind::Add, "  Personal   Tasks ".into());

        assert_eq!(app.lists.len(), 2);
        assert_eq!(app.current, 1);
        assert_eq!(app.current_list().name, "Personal Tasks");
        assert!(app.store.path_for(app.current_list().id).exists());
    }

    #[test]
    fn list_names_are_unique_ignoring_case() {
        let mut app = app();
        app.save_list_prompt(ListPromptKind::Add, "tasks".into());

        assert_eq!(app.lists.len(), 1);
        assert!(app.notice.as_ref().unwrap().error);
    }

    #[test]
    fn tab_and_backtab_cycle_lists_and_reset_the_view() {
        let mut app = app();
        app.save_list_prompt(ListPromptKind::Add, "Work".into());
        app.view = ViewMode::Completed;
        let now = Instant::now();

        app.handle_key(KeyEvent::new(KeyCode::Tab, KeyModifiers::NONE), now);
        assert_eq!(app.current, 0);
        assert_eq!(app.view, ViewMode::List);
        app.handle_key(
            KeyEvent::new(KeyCode::BackTab, KeyModifiers::SHIFT),
            now + Duration::from_millis(1),
        );
        assert_eq!(app.current, 1);
    }

    #[test]
    fn f2_and_control_r_open_the_rename_prompt() {
        let mut app = app();
        let now = Instant::now();
        for key in [
            KeyEvent::new(KeyCode::F(2), KeyModifiers::NONE),
            KeyEvent::new(KeyCode::Char('r'), KeyModifiers::CONTROL),
        ] {
            app.overlay = Overlay::None;
            app.handle_key(key, now);
            assert_eq!(
                app.overlay,
                Overlay::ListPrompt {
                    kind: ListPromptKind::Rename,
                    input: "Tasks".into(),
                    cursor: 5,
                }
            );
        }
    }

    #[test]
    fn renaming_a_list_is_persisted() {
        let mut app = app();
        let id = app.current_list().id;
        app.save_list_prompt(ListPromptKind::Rename, "  Main   Tasks ".into());

        let saved = app.store.load().unwrap();
        assert_eq!(app.current_list().name, "Main Tasks");
        assert_eq!(
            saved.lists.iter().find(|list| list.id == id).unwrap().name,
            "Main Tasks"
        );
    }

    #[test]
    fn confirmed_list_deletion_removes_its_file_and_selects_a_neighbor() {
        let mut app = app();
        app.save_list_prompt(ListPromptKind::Add, "Work".into());
        let deleted_id = app.current_list().id;
        let now = Instant::now();
        app.handle_key(
            KeyEvent::new(KeyCode::Char('x'), KeyModifiers::CONTROL),
            now,
        );
        assert_eq!(app.overlay, Overlay::ConfirmDeleteList);
        app.handle_key(
            KeyEvent::new(KeyCode::Char('y'), KeyModifiers::NONE),
            now + Duration::from_millis(1),
        );

        assert_eq!(app.lists.len(), 1);
        assert_eq!(app.current_list().name, "Tasks");
        assert!(!app.store.path_for(deleted_id).exists());
    }

    #[test]
    fn the_last_list_cannot_be_deleted() {
        let mut app = app();
        app.handle_key(
            KeyEvent::new(KeyCode::Char('x'), KeyModifiers::CONTROL),
            Instant::now(),
        );
        assert_eq!(app.overlay, Overlay::None);
        assert_eq!(app.lists.len(), 1);
        assert!(app.notice.as_ref().unwrap().error);
    }

    #[test]
    fn terminal_control_character_opens_list_deletion() {
        let mut app = app();
        app.save_list_prompt(ListPromptKind::Add, "Work".into());
        app.handle_key(
            KeyEvent::new(KeyCode::Char('\u{18}'), KeyModifiers::NONE),
            Instant::now(),
        );
        assert_eq!(app.overlay, Overlay::ConfirmDeleteList);
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
    fn v_toggles_completed_view_and_c_has_no_view_action_without_doing_tasks() {
        let mut app = app();
        let now = Instant::now();

        app.handle_key(KeyEvent::new(KeyCode::Char('v'), KeyModifiers::NONE), now);
        assert_eq!(app.view, ViewMode::Completed);
        app.handle_key(
            KeyEvent::new(KeyCode::Char('v'), KeyModifiers::NONE),
            now + Duration::from_millis(1),
        );
        assert_eq!(app.view, ViewMode::List);

        app.handle_key(
            KeyEvent::new(KeyCode::Char('c'), KeyModifiers::NONE),
            now + Duration::from_millis(2),
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
        assert_eq!(
            app.config_store.load().unwrap().marquee_speed_ms,
            initial_speed - 25
        );
    }

    #[test]
    fn settings_menu_toggles_long_title_display() {
        let mut app = app();
        let now = Instant::now();
        app.handle_key(KeyEvent::new(KeyCode::Char('g'), KeyModifiers::NONE), now);
        app.handle_key(
            KeyEvent::new(KeyCode::Down, KeyModifiers::NONE),
            now + Duration::from_millis(1),
        );
        app.handle_key(
            KeyEvent::new(KeyCode::Right, KeyModifiers::NONE),
            now + Duration::from_millis(2),
        );
        assert_eq!(app.config.long_title_display.label(), "Wrap");
        assert_eq!(
            app.config_store.load().unwrap().long_title_display.label(),
            "Wrap"
        );
    }

    #[test]
    fn settings_menu_updates_and_persists_native_font_size() {
        let mut app = app();
        let now = Instant::now();
        let initial_size = app.config.native_font_size;
        app.handle_key(KeyEvent::new(KeyCode::Char('g'), KeyModifiers::NONE), now);
        app.handle_key(
            KeyEvent::new(KeyCode::Down, KeyModifiers::NONE),
            now + Duration::from_millis(1),
        );
        app.handle_key(
            KeyEvent::new(KeyCode::Down, KeyModifiers::NONE),
            now + Duration::from_millis(2),
        );
        assert_eq!(app.overlay, Overlay::Settings { selected: 2 });
        app.handle_key(
            KeyEvent::new(KeyCode::Right, KeyModifiers::NONE),
            now + Duration::from_millis(3),
        );
        assert_eq!(app.config.native_font_size, initial_size + 1);
        assert_eq!(
            app.config_store.load().unwrap().native_font_size,
            initial_size + 1
        );
    }

    #[test]
    fn bell_writes_ascii_bel() {
        let mut output = Vec::new();
        emit_bell(&mut output).unwrap();
        assert_eq!(output, b"\x07");
    }
}
