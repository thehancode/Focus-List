use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

pub const SCHEMA_VERSION: u8 = 1;
pub const DEFAULT_MARQUEE_SPEED_MS: u64 = 180;
pub const MIN_MARQUEE_SPEED_MS: u64 = 50;
pub const MAX_MARQUEE_SPEED_MS: u64 = 1_000;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default)]
pub struct AppConfig {
    /// Milliseconds between each marquee character shift. Lower is faster.
    pub marquee_speed_ms: u64,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            marquee_speed_ms: DEFAULT_MARQUEE_SPEED_MS,
        }
    }
}

impl AppConfig {
    pub fn validate(&self) -> anyhow::Result<()> {
        anyhow::ensure!(
            (MIN_MARQUEE_SPEED_MS..=MAX_MARQUEE_SPEED_MS).contains(&self.marquee_speed_ms),
            "marquee_speed_ms must be between {MIN_MARQUEE_SPEED_MS} and {MAX_MARQUEE_SPEED_MS}"
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
}
