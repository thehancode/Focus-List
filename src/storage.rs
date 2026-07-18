use std::{
    fs,
    path::{Path, PathBuf},
};

use anyhow::{Context, Result};

use crate::model::{AppConfig, TaskList};

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

    pub fn load(&self) -> Result<LoadResult> {
        fs::create_dir_all(&self.root)
            .with_context(|| format!("could not create {}", self.root.display()))?;
        let mut loaded = Vec::new();
        let mut warnings = Vec::new();
        for entry in fs::read_dir(&self.root)? {
            let path = entry?.path();
            if path.extension().and_then(|extension| extension.to_str()) != Some("json") {
                continue;
            }
            match self.read_one(&path) {
                Ok(list) => loaded.push((path, list)),
                Err(error) => warnings.push(format!("Skipped {}: {error:#}", path.display())),
            }
        }

        loaded.sort_by_key(|(path, list)| {
            (list.created_at, list.id, *path != self.path_for(list.id))
        });
        let mut lists: Vec<TaskList> = Vec::with_capacity(loaded.len());
        for (source, mut list) in loaded {
            if let Some(existing) = lists.iter().find(|existing| existing.id == list.id) {
                if source != self.path_for(list.id) && existing == &list {
                    fs::remove_file(&source).with_context(|| {
                        format!(
                            "could not remove duplicate legacy file {}",
                            source.display()
                        )
                    })?;
                } else {
                    warnings.push(format!(
                        "Skipped {}: duplicate task-list id {}",
                        source.display(),
                        list.id
                    ));
                }
                continue;
            }
            let original_name = list.name.clone();
            list.name = unique_name(&original_name, &lists);
            if list.name != original_name {
                warnings.push(format!(
                    "Renamed duplicate list {original_name:?} to {:?}",
                    list.name
                ));
            }
            let destination = self.path_for(list.id);
            if source != destination || list.name != original_name {
                self.save(&list)?;
                if source != destination {
                    fs::remove_file(&source).with_context(|| {
                        format!("could not remove migrated file {}", source.display())
                    })?;
                }
            }
            lists.push(list);
        }
        Ok(LoadResult { lists, warnings })
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
        let path = self.path_for(list.id);
        let temp = path.with_extension("json.tmp");
        let json = serde_json::to_string_pretty(list)?;
        fs::write(&temp, format!("{json}\n"))
            .with_context(|| format!("could not write {}", temp.display()))?;
        fs::rename(&temp, &path)
            .with_context(|| format!("could not replace {}", path.display()))?;
        Ok(())
    }

    pub fn delete(&self, id: uuid::Uuid) -> Result<()> {
        let path = self.path_for(id);
        fs::remove_file(&path).with_context(|| format!("could not remove {}", path.display()))
    }

    pub fn path_for(&self, id: uuid::Uuid) -> PathBuf {
        self.root.join(format!("{id}.json"))
    }
}

fn unique_name(requested: &str, existing: &[TaskList]) -> String {
    if !existing
        .iter()
        .any(|list| list.name.eq_ignore_ascii_case(requested))
    {
        return requested.to_owned();
    }
    for suffix in 2.. {
        let candidate = format!("{requested} ({suffix})");
        if !existing
            .iter()
            .any(|list| list.name.eq_ignore_ascii_case(&candidate))
        {
            return candidate;
        }
    }
    unreachable!()
}

#[cfg(test)]
mod tests {
    use std::fs;

    use tempfile::tempdir;

    use super::*;
    use crate::model::Task;

    #[test]
    fn saves_and_loads_multiple_tasklist_files() {
        let directory = tempdir().unwrap();
        let store = TaskStore::new(directory.path());
        let mut first = TaskList::named("Tasks");
        first.tasks.push(Task::new("Write tests"));
        let mut second = TaskList::named("Work");
        second.created_at = first.created_at + chrono::Duration::microseconds(1);
        store.save(&first).unwrap();
        store.save(&second).unwrap();

        let loaded = store.load().unwrap();
        assert_eq!(loaded.lists, vec![first.clone(), second.clone()]);
        assert!(store.path_for(first.id).exists());
        assert!(store.path_for(second.id).exists());
    }

    #[test]
    fn migrates_legacy_files_without_merging_lists() {
        let directory = tempdir().unwrap();
        let first_path = directory.path().join("tasklist.json");
        let second_path = directory.path().join("2026-01-01.json");
        let mut first = TaskList::named("Tasks");
        first.tasks.push(Task::new("Keep me"));
        let mut second = TaskList::named("Work");
        second.created_at = first.created_at + chrono::Duration::microseconds(1);
        fs::write(&first_path, serde_json::to_string(&first).unwrap()).unwrap();
        fs::write(&second_path, serde_json::to_string(&second).unwrap()).unwrap();

        let store = TaskStore::new(directory.path());
        let loaded = store.load().unwrap();
        assert_eq!(loaded.lists.len(), 2);
        assert_eq!(loaded.lists[0].tasks.len(), 1);
        assert!(!first_path.exists());
        assert!(!second_path.exists());
        assert!(store.path_for(first.id).exists());
        assert!(store.path_for(second.id).exists());
    }

    #[test]
    fn disambiguates_duplicate_legacy_names() {
        let directory = tempdir().unwrap();
        let first = TaskList::named("Work");
        let mut second = TaskList::named("work");
        second.created_at = first.created_at + chrono::Duration::microseconds(1);
        fs::write(
            directory.path().join("first.json"),
            serde_json::to_string(&first).unwrap(),
        )
        .unwrap();
        fs::write(
            directory.path().join("second.json"),
            serde_json::to_string(&second).unwrap(),
        )
        .unwrap();

        let loaded = TaskStore::new(directory.path()).load().unwrap();
        assert_eq!(loaded.lists[0].name, "Work");
        assert_eq!(loaded.lists[1].name, "work (2)");
        assert!(!loaded.warnings.is_empty());
    }

    #[test]
    fn deletes_only_the_requested_list() {
        let directory = tempdir().unwrap();
        let store = TaskStore::new(directory.path());
        let first = TaskList::named("Tasks");
        let second = TaskList::named("Work");
        store.save(&first).unwrap();
        store.save(&second).unwrap();

        store.delete(first.id).unwrap();
        assert!(!store.path_for(first.id).exists());
        assert!(store.path_for(second.id).exists());
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
