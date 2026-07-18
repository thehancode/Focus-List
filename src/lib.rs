pub mod app;
pub mod model;
pub mod storage;
pub mod ui;

use std::{env, path::PathBuf};

use anyhow::{Context, Result};

/// Returns the existing data location used by the terminal application.
///
/// Keeping this unchanged during the native proof of concept means both front
/// ends operate on the same task list. Platform-native directories are a later
/// migration with an explicit data import step.
pub fn tasklists_dir() -> Result<PathBuf> {
    let data_home = env::var_os("XDG_DATA_HOME")
        .map(PathBuf::from)
        .or_else(|| env::var_os("HOME").map(|home| PathBuf::from(home).join(".local/share")))
        .context("could not determine the user data directory")?;
    Ok(data_home.join("tui-kanban/tasklists"))
}
