use std::{
    fs,
    path::{Path, PathBuf},
};

use anyhow::{Context, Result};

use crate::model::{AppConfig, TaskList};

const TASK_LIST_FILE: &str = "tasklist.json";
const CONFIG_FILE: &str = "config/settings.json";

#[derive(Debug)]
pub struct LoadResult {
    pub lists: Vec<TaskList>,
    pub warnings: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct TaskStore {
    root: PathBuf,
}

#[derive(Debug, Clone)]
pub struct ConfigStore {
    root: PathBuf,
}

impl ConfigStore {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    pub fn load(&self) -> Result<AppConfig> {
        let path = self.path();
        if !path.exists() {
            let config = AppConfig::default();
            self.save(&config)?;
            return Ok(config);
        }
        let contents = fs::read_to_string(&path)
            .with_context(|| format!("could not read {}", path.display()))?;
        let config: AppConfig = serde_json::from_str(&contents)
            .with_context(|| format!("invalid JSON in {}", path.display()))?;
        config.validate()?;
        Ok(config)
    }

    pub fn save(&self, config: &AppConfig) -> Result<()> {
        config.validate()?;
        let path = self.path();
        let parent = path.parent().expect("config path has a parent");
        fs::create_dir_all(parent)
            .with_context(|| format!("could not create {}", parent.display()))?;
        let temp = path.with_extension("json.tmp");
        let json = serde_json::to_string_pretty(config)?;
        fs::write(&temp, format!("{json}\n"))
            .with_context(|| format!("could not write {}", temp.display()))?;
        fs::rename(&temp, &path)
            .with_context(|| format!("could not replace {}", path.display()))?;
        Ok(())
    }

    pub fn path(&self) -> PathBuf {
        self.root.join(CONFIG_FILE)
    }
}

impl TaskStore {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    pub fn root(&self) -> &Path {
        &self.root
    }

    /// Loads the single canonical task-list file. Older versions created one
    /// file per list; on first launch those files are consolidated here.
    pub fn load(&self) -> Result<LoadResult> {
        fs::create_dir_all(&self.root)
            .with_context(|| format!("could not create {}", self.root.display()))?;
        let path = self.path();
        if path.exists() {
            return self
                .read_one(&path)
                .map(|list| LoadResult {
                    lists: vec![list],
                    warnings: Vec::new(),
                })
                .map_err(|error| anyhow::anyhow!("could not load {}: {error:#}", path.display()));
        }

        self.migrate_legacy_lists()
    }

    fn migrate_legacy_lists(&self) -> Result<LoadResult> {
        let mut legacy_paths = Vec::new();
        let mut tasks = Vec::new();
        let mut warnings = Vec::new();
        for entry in fs::read_dir(&self.root)? {
            let path = entry?.path();
            if path.extension().and_then(|extension| extension.to_str()) != Some("json") {
                continue;
            }
            match self.read_one(&path) {
                Ok(list) => {
                    legacy_paths.push(path);
                    tasks.extend(list.tasks);
                }
                Err(error) => warnings.push(format!("Skipped {}: {error:#}", path.display())),
            }
        }
        if legacy_paths.is_empty() {
            return Ok(LoadResult {
                lists: Vec::new(),
                warnings,
            });
        }

        let mut list = TaskList::named("Tasks");
        list.tasks = tasks;
        self.save(&list)?;
        for path in legacy_paths {
            fs::remove_file(&path)
                .with_context(|| format!("could not remove migrated file {}", path.display()))?;
        }
        warnings.push("Migrated older task-list files into tasklist.json".into());
        Ok(LoadResult {
            lists: vec![list],
            warnings,
        })
    }

    fn read_one(&self, path: &Path) -> Result<TaskList> {
        let contents = fs::read_to_string(path).context("could not read file")?;
        let list: TaskList = serde_json::from_str(&contents).context("invalid JSON")?;
        list.validate().context("invalid task list")?;
        Ok(list)
    }

    pub fn ensure_task_list(&self, lists: &mut Vec<TaskList>) -> Result<()> {
        if lists.is_empty() {
            let list = TaskList::named("Tasks");
            self.save(&list)?;
            lists.push(list);
        }
        Ok(())
    }

    pub fn save(&self, list: &TaskList) -> Result<()> {
        list.validate()?;
        fs::create_dir_all(&self.root)?;
        let path = self.path();
        let temp = path.with_extension("json.tmp");
        let json = serde_json::to_string_pretty(list)?;
        fs::write(&temp, format!("{json}\n"))
            .with_context(|| format!("could not write {}", temp.display()))?;
        fs::rename(&temp, &path)
            .with_context(|| format!("could not replace {}", path.display()))?;
        Ok(())
    }

    fn path(&self) -> PathBuf {
        self.root.join(TASK_LIST_FILE)
    }
}

#[cfg(test)]
mod tests {
    use std::fs;

    use tempfile::tempdir;

    use super::*;
    use crate::model::Task;

    #[test]
    fn saves_and_loads_one_tasklist_file() {
        let directory = tempdir().unwrap();
        let store = TaskStore::new(directory.path());
        let mut list = TaskList::named("Tasks");
        list.tasks.push(Task::new("Write tests"));
        store.save(&list).unwrap();

        let loaded = store.load().unwrap();
        assert_eq!(loaded.lists, vec![list]);
        assert_eq!(fs::read_dir(directory.path()).unwrap().count(), 1);
        assert!(directory.path().join(TASK_LIST_FILE).exists());
    }

    #[test]
    fn migrates_older_json_files_into_one_tasklist() {
        let directory = tempdir().unwrap();
        let old_path = directory.path().join("2026-01-01.json");
        let mut old_list = TaskList::named("Old tasks");
        old_list.tasks.push(Task::new("Keep me"));
        fs::write(&old_path, serde_json::to_string(&old_list).unwrap()).unwrap();

        let loaded = TaskStore::new(directory.path()).load().unwrap();
        assert_eq!(loaded.lists[0].tasks.len(), 1);
        assert!(!old_path.exists());
        assert!(directory.path().join(TASK_LIST_FILE).exists());
    }

    #[test]
    fn creates_one_empty_tasklist() {
        let directory = tempdir().unwrap();
        let store = TaskStore::new(directory.path());
        let mut lists = Vec::new();
        store.ensure_task_list(&mut lists).unwrap();
        store.ensure_task_list(&mut lists).unwrap();
        assert_eq!(lists.len(), 1);
    }

    #[test]
    fn saves_default_config() {
        let directory = tempdir().unwrap();
        let store = ConfigStore::new(directory.path());
        let config = store.load().unwrap();
        assert_eq!(config, AppConfig::default());
        assert!(store.path().exists());
    }
}
