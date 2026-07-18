use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

pub const SCHEMA_VERSION: u8 = 1;
pub const DEFAULT_MARQUEE_SPEED_MS: u64 = 180;
pub const MIN_MARQUEE_SPEED_MS: u64 = 50;
pub const MAX_MARQUEE_SPEED_MS: u64 = 1_000;
pub const DEFAULT_NATIVE_FONT_SIZE: u16 = 16;
pub const MIN_NATIVE_FONT_SIZE: u16 = 10;
pub const MAX_NATIVE_FONT_SIZE: u16 = 28;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LongTitleDisplay {
    Marquee,
    Wrap,
}

impl LongTitleDisplay {
    pub fn toggle(self) -> Self {
        match self {
            Self::Marquee => Self::Wrap,
            Self::Wrap => Self::Marquee,
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            Self::Marquee => "Marquee",
            Self::Wrap => "Wrap",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default)]
pub struct AppConfig {
    /// Milliseconds between each marquee character shift. Lower is faster.
    pub marquee_speed_ms: u64,
    /// How long task titles are displayed when they exceed the available width.
    pub long_title_display: LongTitleDisplay,
    /// Point size used by the standalone native window renderer.
    pub native_font_size: u16,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            marquee_speed_ms: DEFAULT_MARQUEE_SPEED_MS,
            long_title_display: LongTitleDisplay::Marquee,
            native_font_size: DEFAULT_NATIVE_FONT_SIZE,
        }
    }
}

impl AppConfig {
    pub fn validate(&self) -> anyhow::Result<()> {
        anyhow::ensure!(
            (MIN_MARQUEE_SPEED_MS..=MAX_MARQUEE_SPEED_MS).contains(&self.marquee_speed_ms),
            "marquee_speed_ms must be between {MIN_MARQUEE_SPEED_MS} and {MAX_MARQUEE_SPEED_MS}"
        );
        anyhow::ensure!(
            (MIN_NATIVE_FONT_SIZE..=MAX_NATIVE_FONT_SIZE).contains(&self.native_font_size),
            "native_font_size must be between {MIN_NATIVE_FONT_SIZE} and {MAX_NATIVE_FONT_SIZE}"
        );
        Ok(())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Status {
    Pending,
    Doing,
    Done,
}

impl Status {
    pub const ALL: [Self; 3] = [Self::Pending, Self::Doing, Self::Done];
    pub const LIST_ORDER: [Self; 3] = [Self::Doing, Self::Pending, Self::Done];

    pub fn next(self) -> Self {
        match self {
            Self::Pending => Self::Doing,
            Self::Doing => Self::Done,
            Self::Done => Self::Pending,
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            Self::Pending => "Pending",
            Self::Doing => "Doing",
            Self::Done => "Done",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Task {
    pub id: Uuid,
    pub title: String,
    pub status: Status,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    /// Set only while a task is in Done, so completion history can be ordered accurately.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub completed_at: Option<DateTime<Utc>>,
    /// Daily tasks return to Pending on a new local calendar day.
    #[serde(default, skip_serializing_if = "std::ops::Not::not")]
    pub daily: bool,
    /// Every completion of a daily task, retained for history and activity views.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub completion_history: Vec<DateTime<Utc>>,
}

impl Task {
    pub fn new(title: impl Into<String>) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            title: title.into(),
            status: Status::Pending,
            created_at: now,
            updated_at: now,
            completed_at: None,
            daily: false,
            completion_history: Vec::new(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TaskList {
    pub schema_version: u8,
    pub id: Uuid,
    pub name: String,
    pub created_at: DateTime<Utc>,
    pub tasks: Vec<Task>,
}

impl TaskList {
    pub fn named(name: impl Into<String>) -> Self {
        Self {
            schema_version: SCHEMA_VERSION,
            id: Uuid::new_v4(),
            name: name.into(),
            created_at: Utc::now(),
            tasks: Vec::new(),
        }
    }

    pub fn validate(&self) -> anyhow::Result<()> {
        anyhow::ensure!(
            self.schema_version == SCHEMA_VERSION,
            "unsupported schema version {}",
            self.schema_version
        );
        anyhow::ensure!(!self.name.trim().is_empty(), "task-list name is empty");
        anyhow::ensure!(
            self.tasks.iter().all(|task| !task.title.trim().is_empty()),
            "task title is empty"
        );
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn status_wraps() {
        assert_eq!(Status::Pending.next(), Status::Doing);
        assert_eq!(Status::Doing.next(), Status::Done);
        assert_eq!(Status::Done.next(), Status::Pending);
    }

    #[test]
    fn model_round_trips_through_json() {
        let mut list = TaskList::named("Launch");
        list.tasks.push(Task::new("Ship it"));
        let json = serde_json::to_string(&list).unwrap();
        let decoded: TaskList = serde_json::from_str(&json).unwrap();
        assert_eq!(list, decoded);
    }

    #[test]
    fn default_config_has_a_valid_marquee_speed() {
        AppConfig::default().validate().unwrap();
    }

    #[test]
    fn native_font_size_must_be_in_range() {
        let mut config = AppConfig::default();
        config.native_font_size = MIN_NATIVE_FONT_SIZE - 1;
        assert!(config.validate().is_err());
        config.native_font_size = MAX_NATIVE_FONT_SIZE + 1;
        assert!(config.validate().is_err());
    }
}
